//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Aktive Workouts / ViewModel                                      /
// Datei . . . . : SetManager.swift                                                 /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 22.05.2026                                                       /
// Beschreibung  : Verwaltet Set/Superset-Logik, Caches und Combine-Publishers      /
//                 während eines aktiven Trainings. Enthält kein context.save.      /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Combine
import Foundation
import SwiftUI

// MARK: - SetManager

/// Zentrale Koordinationsklasse für aktives Training.
/// Property-Mutationen auf @Model-Objekten (set.isCompleted etc.) sind erlaubt.
/// context.insert / context.delete / context.save MUSS in der View bleiben.
@MainActor
@Observable
final class SetManager {

    // MARK: - Caches

    private(set) var cachedGroupedSets: [[ExerciseSet]] = []
    private(set) var cachedSessionVolume: Double = 0
    private(set) var cachedCurrentSet: ExerciseSet?
    private(set) var cachedLastCompletedSet: ExerciseSet?
    private(set) var cachedCurrentExerciseIndex: Int = 0
    private(set) var cachedLastSessionReferences: [String: [Int: LastSessionReferenceCalcEngine.Reference]] = [:]

    // MARK: - Publishers

    @ObservationIgnored let setCompleted = PassthroughSubject<ExerciseSet, Never>()
    @ObservationIgnored let exerciseKeyChanged = PassthroughSubject<String, Never>()   // Superset-Rotation
    @ObservationIgnored let restShouldStart = PassthroughSubject<Int, Never>()         // seconds
    @ObservationIgnored let rirSheetShouldShow = PassthroughSubject<ExerciseSet, Never>()
    @ObservationIgnored let prDetected = PassthroughSubject<(ExerciseSet, String, Double), Never>()

    // MARK: - Private

    @ObservationIgnored private var session: StrengthSession?
    @ObservationIgnored private var historicalSessionsProvider: (() -> [StrengthSession])?
    @ObservationIgnored private var selectedKeyProvider: (() -> String?)?
    @ObservationIgnored private var selectedKeySetter: ((String?) -> Void)?
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init() {}

    // MARK: - Configure

    func configure(
        session: StrengthSession,
        historicalSessionsProvider: @escaping () -> [StrengthSession],
        selectedKeyProvider: @escaping () -> String?,
        selectedKeySetter: @escaping (String?) -> Void
    ) {
        self.session = session
        self.historicalSessionsProvider = historicalSessionsProvider
        self.selectedKeyProvider = selectedKeyProvider
        self.selectedKeySetter = selectedKeySetter

        rebuildGroupedCaches()
        refreshSetCaches()
        recomputeSessionVolume()
    }

    // MARK: - Cache-Aufbau

    func rebuildGroupedCaches() {
        guard let session else { return }
        cachedGroupedSets = session.groupedSets
    }

    func refreshSetCaches() {
        guard let session else { return }
        let safeSets = session.safeExerciseSets
        let selectedKey = selectedKeyProvider?()

        // lastCompletedSet: letzter abgeschlossener Satz
        cachedLastCompletedSet = safeSets.last { $0.isCompleted }

        // currentSet: nächster offener Satz (nach selectedExerciseKey oder global)
        if let key = selectedKey {
            cachedCurrentSet = safeSets
                .filter { $0.groupKey == key }
                .sorted { $0.setNumber < $1.setNumber }
                .first { !$0.isCompleted }
        } else {
            cachedCurrentSet = session.nextUncompletedSet
        }

        // currentExerciseIndex: Position der aktuellen Übung in cachedGroupedSets
        if let key = selectedKey,
           let idx = cachedGroupedSets.firstIndex(where: { $0.first?.groupKey == key }) {
            cachedCurrentExerciseIndex = idx
        } else if let current = cachedCurrentSet {
            cachedCurrentExerciseIndex = cachedGroupedSets.firstIndex(where: { group in
                group.contains { $0.id == current.id }
            }) ?? 0
        } else {
            cachedCurrentExerciseIndex = 0
        }
    }

    func recomputeSessionVolume() {
        guard let session else { return }
        // Zeitbasierte Sätze (weight=0, reps=0) aus Volumen-Berechnung ausschließen
        cachedSessionVolume = session.safeExerciseSets
            .filter { $0.isCompleted && !$0.isTimeBased }
            .reduce(0.0) { $0 + ($1.weight * Double($1.reps)) }
    }

    // MARK: - Set abschließen

    /// Schließt einen Satz ab und sendet relevante Events via Publisher.
    /// Kein context.save — die View reagiert via onReceive(setCompleted) auf context.save.
    func completeSet(_ set: ExerciseSet) {
        guard let session else { return }

        withAnimation(.easeInOut) {
            set.isCompleted = true
        }

        // Cache sofort aktualisieren
        cachedGroupedSets = session.groupedSets

        // Smart-Progression: Flag für letzten Work-Set setzen (NACH Cache-Update, NACH isCompleted = true)
        if isLastWorkSet(of: set) {
            set.isLastSetOfExercise = true
        }

        // setCompleted publizieren — View spart context.save, WatchBridge + LiveActivityCtrl subscriben
        setCompleted.send(set)

        // selectedKey setzen wenn noch nil
        let currentKey = selectedKeyProvider?()
        if currentKey == nil {
            if let key = cachedGroupedSets
                .first(where: { group in group.contains(where: { $0.id == set.id }) })?
                .first?.groupKey {
                selectedKeySetter?(key)
            }
        }
        if selectedKeyProvider?() == nil {
            selectedKeySetter?(set.groupKey)
        }

        // PR-Prüfung asynchron
        let sessions = historicalSessionsProvider?() ?? []
        let exerciseName = set.exerciseName
        Task { @MainActor [weak self] in
            guard let self else { return }
            let prService = PRDetectionService(historicalSessions: sessions)
            if prService.isNewPR(set: set) {
                let oneRM = prService.calculatedOneRM(for: set)
                self.prDetected.send((set, exerciseName, oneRM))
            }
        }

        // Superset-Rotation hat Vorrang vor normalem Rest-Timer-Handling
        if let groupId = set.supersetGroupId {
            handleSupersetRotation(completedSet: set, supersetGroupId: groupId)
            return
        }

        // Letzter Satz des gesamten Trainings → kein Timer, kein RIR-Sheet
        if session.allSetsCompleted {
            return
        }

        // Rest-Timer starten
        restShouldStart.send(set.restSeconds)

        // RIR-Sheet beim letzten Work-Set
        if set.isLastSetOfExercise {
            rirSheetShouldShow.send(set)
        }
    }

    // MARK: - Superset-Rotation

    /// Steuert die Rotation innerhalb eines Supersets.
    func handleSupersetRotation(completedSet: ExerciseSet, supersetGroupId: String) {
        guard let session else { return }

        // Alle Übungs-Keys in der Superset-Gruppe, sortiert nach sortOrder
        let supersetKeys: [String] = cachedGroupedSets
            .filter { $0.first?.supersetGroupId == supersetGroupId }
            .sorted { ($0.first?.sortOrder ?? 0) < ($1.first?.sortOrder ?? 0) }
            .compactMap { $0.first?.groupKey }

        guard !supersetKeys.isEmpty else { return }

        let currentIndex = supersetKeys.firstIndex(of: completedSet.groupKey) ?? 0

        // Nächste Übung in der aktuellen Runde
        let nextInRound = Array(supersetKeys.dropFirst(currentIndex + 1)).first { key in
            session.safeExerciseSets.contains { $0.groupKey == key && !$0.isCompleted }
        }

        if let nextKey = nextInRound {
            // Noch nicht am Ende der Runde → direkt weiter, KEIN Rest-Timer
            exerciseKeyChanged.send(nextKey)
            return
        }

        // Runde ist komplett — prüfen ob weitere Runden im Superset existieren
        let anyOpenInGroup = supersetKeys.contains { key in
            session.safeExerciseSets.contains { $0.groupKey == key && !$0.isCompleted }
        }

        if anyOpenInGroup {
            // Weitere Runden vorhanden → Rest-Timer + zur ersten offenen Übung der Gruppe
            restShouldStart.send(completedSet.restSeconds)
            if let firstOpenKey = supersetKeys.first(where: { key in
                session.safeExerciseSets.contains { $0.groupKey == key && !$0.isCompleted }
            }) {
                exerciseKeyChanged.send(firstOpenKey)
            }
        } else {
            // Gesamtes Superset abgeschlossen → zur nächsten Nicht-Superset-Übung wechseln
            let supersetGroupKeys = Set(supersetKeys)
            let nextExerciseKey = cachedGroupedSets
                .sorted { ($0.first?.sortOrder ?? 0) < ($1.first?.sortOrder ?? 0) }
                .first { group in
                    guard let key = group.first?.groupKey,
                          let firstSet = group.first else { return false }
                    return !supersetGroupKeys.contains(key)
                        && firstSet.supersetGroupId != supersetGroupId
                        && group.contains { !$0.isCompleted }
                }?
                .first?.groupKey

            if let key = nextExerciseKey {
                exerciseKeyChanged.send(key)
            }
        }
    }

    // MARK: - Smart-Progression Helpers

    func isLastWorkSet(of set: ExerciseSet) -> Bool {
        // Zeitbasierte Sätze brauchen kein RIR-Flag — Guard verhindert ungewolltes Sheet
        guard !set.isTimeBased else { return false }
        guard set.setKind == .work, let session else { return false }
        let workSets = session.safeExerciseSets.filter {
            $0.groupKey == set.groupKey && $0.setKind == .work
        }
        return workSets.allSatisfy { $0.isCompleted }
    }

    /// Hält isLastSetOfExercise-Flag nach Add/Delete/Reorder konsistent.
    /// Property-Mutationen auf @Model — kein context.save (liegt bei View).
    func cleanupLastSetFlag(for groupKey: String) {
        guard let session else { return }
        ExerciseSetFlagUpdater.updateLastSetFlags(forExerciseGroup: groupKey, in: session)
    }

    func retroRIRCandidate(for selectedKey: String?) -> ExerciseSet? {
        guard let currentKey = selectedKey, let session else { return nil }
        let workSets = session.safeExerciseSets
            .filter { $0.groupKey == currentKey && $0.setKind == .work && $0.isCompleted }
            .sorted { $0.setNumber < $1.setNumber }
        guard let lastSet = workSets.last,
              lastSet.isLastSetOfExercise,
              !lastSet.rpeRecorded else { return nil }
        return lastSet
    }

    // MARK: - Letzte-Session-Referenz

    func refreshLastSessionReference(for groupKey: String) {
        guard let session else { return }

        // Plan-Template-Sets für diese Übung
        let planSets = session.sourceTrainingPlan?.safeTemplateSets.filter {
            $0.groupKey == groupKey
        } ?? []

        guard !planSets.isEmpty else {
            cachedLastSessionReferences[groupKey] = [:]
            return
        }

        let lastSets = lastCompletedSession(for: groupKey)?.safeExerciseSets.filter {
            $0.groupKey == groupKey
        } ?? []

        guard !lastSets.isEmpty else {
            cachedLastSessionReferences[groupKey] = [:]
            return
        }

        let workSetNumbers = planSets.filter { $0.setKind == .work }.map { $0.setNumber }
        var references: [Int: LastSessionReferenceCalcEngine.Reference] = [:]
        for setNumber in workSetNumbers {
            let input = LastSessionReferenceCalcEngine.Input(
                activeSetNumber: setNumber,
                lastSessionSets: lastSets,
                planTemplateSets: planSets
            )
            if let ref = LastSessionReferenceCalcEngine.resolve(input: input) {
                references[setNumber] = ref
            }
        }
        cachedLastSessionReferences[groupKey] = references
    }

    func lastSessionReference(for set: ExerciseSet) -> LastSessionReferenceCalcEngine.Reference? {
        cachedLastSessionReferences[set.groupKey]?[set.setNumber]
    }

    // MARK: - Hilfsmethoden

    func resolveExercise(for groupKey: String) -> Exercise? {
        session?.safeExerciseSets.first(where: { $0.groupKey == groupKey })?.exercise
    }

    func lastCompletedSession(for groupKey: String) -> StrengthSession? {
        historicalSessionsProvider?().first { s in
            s.safeExerciseSets.contains { $0.groupKey == groupKey }
        }
    }

    // MARK: - Superset Display Context

    struct SupersetDisplayContext {
        let exerciseNames: [String]
        let currentIndex: Int
        let currentRound: Int
        let totalRounds: Int
    }

    func supersetDisplayContext(for set: ExerciseSet) -> SupersetDisplayContext? {
        guard let groupId = set.supersetGroupId, let session else { return nil }

        let groups = cachedGroupedSets
            .filter { $0.first?.supersetGroupId == groupId }
            .sorted { ($0.first?.sortOrder ?? 0) < ($1.first?.sortOrder ?? 0) }

        guard groups.count >= 2 else { return nil }

        let names = groups.compactMap { group -> String? in
            guard let first = group.first else { return nil }
            return first.exerciseNameSnapshot.isEmpty ? first.exerciseName : first.exerciseNameSnapshot
        }

        let keys = groups.compactMap { $0.first?.groupKey }
        let currentIndex = keys.firstIndex(of: set.groupKey) ?? 0

        let firstKey = keys.first ?? ""
        let completedRounds = session.safeExerciseSets
            .filter { $0.groupKey == firstKey && $0.isCompleted }
            .count
        let currentRound = completedRounds + 1

        let totalRounds = keys.map { key in
            session.safeExerciseSets.filter { $0.groupKey == key }.count
        }.max() ?? 1

        return SupersetDisplayContext(
            exerciseNames: names,
            currentIndex: currentIndex,
            currentRound: currentRound,
            totalRounds: totalRounds
        )
    }

    func supersetNextRoundNames(for set: ExerciseSet) -> [String]? {
        guard let groupId = set.supersetGroupId else { return nil }
        let groups = cachedGroupedSets
            .filter { $0.first?.supersetGroupId == groupId }
            .sorted { ($0.first?.sortOrder ?? 0) < ($1.first?.sortOrder ?? 0) }
        let names = groups.compactMap { group -> String? in
            guard group.contains(where: { !$0.isCompleted }) else { return nil }
            let first = group.first
            return first?.exerciseNameSnapshot.isEmpty == false
                ? first?.exerciseNameSnapshot
                : first?.exerciseName
        }
        return names.isEmpty ? nil : names
    }
}
