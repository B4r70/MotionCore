//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Daten-Modell                                                     /
// Datei . . . . : TrainingPlan.swift                                               /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 23.12.2025                                                       /
// Beschreibung  : Trainingsplan als Template für Workouts                          /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation
import SwiftData
import SwiftUI

@Model
final class TrainingPlan {
    // MARK: - Identifikation

    // Stabile UUID für Supabase-Sync (überlebt App-Neustarts)
    var planUUID: UUID = UUID()

    // MARK: - Grunddaten

    var title: String = ""                  // Name des Plans
    var planDescription: String = ""        // Beschreibung/Ziel
    var startDate: Date = Date()            // Startdatum
    var endDate: Date?                      // Optional: Enddatum
    var isActive: Bool = true               // Aktiver Plan?
    /// Wurde dieser Plan bereits zu Supabase hochgeladen?
    var syncedToSupabase: Bool = false
    var createdAt: Date = Date()            // Erstellungsdatum

    // MARK: - Persistente ENUM-Rohwerte

    var planTypeRaw: String = "cardio"      // "cardio", "strength", "outdoor", "mixed"

    // MARK: - Typisierte ENUM-Property

    var planType: PlanType {
        get { PlanType(rawValue: planTypeRaw) ?? .mixed }
        set { planTypeRaw = newValue.rawValue }
    }

    // MARK: - Plan-Update Tracking

    // Zeitpunkt des letzten automatischen Plan-Updates
    var lastUpdatedFromSession: Date? = nil

    // UUID-String der Session, die den letzten Update ausgelöst hat (String? für CloudKit-Kompatibilität)
    var lastUpdateSourceSessionUUID: String? = nil

    // MARK: - Beziehungen

    @Relationship(deleteRule: .cascade, inverse: \ExerciseSet.trainingPlan)
    var templateSets: [ExerciseSet]? = []

    @Relationship(deleteRule: .nullify, inverse: \StrengthSession.sourceTrainingPlan)
    var derivedSessions: [StrengthSession]? = []

    // MARK: - Berechnete Werte

    // Plan ist abgelaufen?
    var isExpired: Bool {
        guard let end = endDate else { return false }
        return end < Date()
    }

    // Anzahl Tage im Plan
    var durationInDays: Int? {
        guard let end = endDate else { return nil }
        return Calendar.current.dateComponents([.day], from: startDate, to: end).day
    }

    // Erstellt eine neue StrengthSession basierend auf diesem Template
    func createSession() -> StrengthSession {
        let session = StrengthSession(
            date: Date(),
            workoutType: .custom
        )

        // Referenz zum Template setzen
        session.sourceTrainingPlan = self
        session.start()  // Direkt starten

        // Template-Sets kopieren (sortiert nach sortOrder)
        for templateSet in safeTemplateSets.sorted(by: { $0.sortOrder < $1.sortOrder }) {
            let newSet = ExerciseSet(
                exerciseName: templateSet.exerciseName,
                exerciseNameSnapshot: templateSet.exerciseNameSnapshot,
                exerciseUUIDSnapshot: templateSet.exerciseUUIDSnapshot,
                exerciseMediaAssetName: templateSet.exerciseMediaAssetName,
                setNumber: templateSet.setNumber,
                weight: templateSet.weight,
                weightPerSide: templateSet.weightPerSide,
                reps: templateSet.reps,
                duration: templateSet.duration,
                distance: templateSet.distance,
                restSeconds: templateSet.restSeconds,
                setKind: templateSet.setKind,
                isCompleted: false,
                rpe: 0,
                notes: "",
                targetRepsMin: templateSet.targetRepsMin,
                targetRepsMax: templateSet.targetRepsMax,
                targetRIR: templateSet.targetRIR,
                groupId: templateSet.groupId,
                sortOrder: templateSet.sortOrder,  // NEU: Sortierung uebernehmen
                supersetGroupId: templateSet.supersetGroupId
            )
            newSet.exercise = templateSet.exercise
            session.addSet(newSet)
        }
        return session
    }

    // Gruppierte Template-Sets, sortiert nach sortOrder (Superset-kompatibel)
    var groupedTemplateSets: [[ExerciseSet]] {
        let sets = safeTemplateSets

        // Gruppieren nach groupKey (UUID-Snapshot oder Name) — identisch zu StrengthSession.groupedSets
        let grouped = Dictionary(grouping: sets) { $0.groupKey }

        // Gruppen nach sortOrder der ersten Übung sortieren; bei Gleichstand alphabetisch
        return grouped.values
            .map { $0.sorted { $0.setNumber < $1.setNumber } }
            .sorted { group1, group2 in
                let s1 = group1.first?.sortOrder ?? Int.max
                let s2 = group2.first?.sortOrder ?? Int.max
                if s1 != s2 { return s1 < s2 }
                let name1 = group1.first?.exerciseNameSnapshot ?? group1.first?.exerciseName ?? ""
                let name2 = group2.first?.exerciseNameSnapshot ?? group2.first?.exerciseName ?? ""
                return name1 < name2
            }
    }

    // Naechste verfuegbare sortOrder fuer neue Uebungen
    var nextSortOrder: Int {
        let maxOrder = safeTemplateSets.map(\.sortOrder).max() ?? 0
        return max(maxOrder + 1, 1)
    }

    // MARK: Uebungs-Sortierung

    // Uebungen manuell neu sortieren (fuer Drag & Drop)
    // - Parameters:
    //   - source: IndexSet mit dem Quell-Index
    //   - destination: Ziel-Index (Position nach dem Move)
    func reorderExercises(fromOffsets source: IndexSet, toOffset destination: Int) {
        var groups = groupedTemplateSets
        groups.move(fromOffsets: source, toOffset: destination)

        for (index, group) in groups.enumerated() {
            let newOrder = index + 1          // ✅ 1-basiert
            for set in group {
                set.sortOrder = newOrder
            }
        }
    }

    // Alternative Methode fuer direktes Reordering mit from/to Index
    func reorderExercise(from sourceIndex: Int, to destinationIndex: Int) {
        var groups = groupedTemplateSets
        guard sourceIndex != destinationIndex,
              sourceIndex >= 0, sourceIndex < groups.count,
              destinationIndex >= 0, destinationIndex < groups.count else { return }

        let movedGroup = groups.remove(at: sourceIndex)
        groups.insert(movedGroup, at: destinationIndex)

        for (index, group) in groups.enumerated() {
            let newOrder = index + 1          // ✅ 1-basiert
            for set in group {
                set.sortOrder = newOrder
            }
        }
    }

    // Sortierkriterien fuer automatische Sortierung
    enum SortCriterion {
        case manual              // Benutzerdefiniert (keine Aenderung)
        case alphabetical        // A-Z nach Uebungsname
        case muscleGroup         // Nach Muskelgruppe
        case intensityDesc       // Hoechste Intensitaet zuerst (Gewicht x Reps)
        case intensityAsc        // Niedrigste Intensitaet zuerst
    }

    // Automatische Sortierung nach Kriterium
    func sortExercises(by criterion: SortCriterion) {
        var groups = groupedTemplateSets

        switch criterion {
            case .manual:
                return // Keine Aenderung

            case .alphabetical:
                groups.sort { ($0.first?.exerciseName ?? "") < ($1.first?.exerciseName ?? "") }

            case .muscleGroup:
                groups.sort { group1, group2 in
                    let muscle1 = group1.first?.primaryMuscleGroup?.rawValue ?? "zzz"
                    let muscle2 = group2.first?.primaryMuscleGroup?.rawValue ?? "zzz"
                    return muscle1 < muscle2
                }

            case .intensityDesc:
                groups.sort { group1, group2 in
                    let intensity1 = self.calculateGroupIntensity(group1)
                    let intensity2 = self.calculateGroupIntensity(group2)
                    return intensity1 > intensity2
                }

            case .intensityAsc:
                groups.sort { group1, group2 in
                    let intensity1 = self.calculateGroupIntensity(group1)
                    let intensity2 = self.calculateGroupIntensity(group2)
                    return intensity1 < intensity2
                }
        }

            // Neue sortOrder zuweisen (1-basiert, konsistent mit reorderExercises)
        for (index, group) in groups.enumerated() {
            for set in group {
                set.sortOrder = index + 1
            }
        }
    }

    // Berechnet die durchschnittliche Intensitaet einer Uebungsgruppe
    private func calculateGroupIntensity(_ sets: [ExerciseSet]) -> Double {
        let workingSets = sets.filter { $0.setKind == .work }
        guard !workingSets.isEmpty else { return 0 }

        let totalVolume = workingSets.reduce(0.0) { $0 + ($1.weight * Double($1.reps)) }
        return totalVolume / Double(workingSets.count)
    }

    /// Verbindet Übung an `index` mit der nächsten Übung als Superset.
    /// Falls die Übung bereits in einem Superset ist, wird das gesamte Superset aufgelöst.
    @available(*, deprecated, renamed: "createSuperset(fromGroupIndices:)")
    func toggleSuperset(forGroupAt index: Int) {
        let groups = groupedTemplateSets
        guard index < groups.count else { return }
        let currentGroup = groups[index]

        if let existingGroupId = currentGroup.first?.supersetGroupId {
            // Superset auflösen: alle Sets dieser Gruppe
            safeTemplateSets
                .filter { $0.supersetGroupId == existingGroupId }
                .forEach { $0.supersetGroupId = nil }
        } else {
            // Mit nächster Übung verbinden
            guard index + 1 < groups.count else { return }
            let nextGroup = groups[index + 1]
            // Falls die nächste Gruppe bereits ein Superset hat, in diese Gruppe eingliedern
            let groupId = nextGroup.first?.supersetGroupId ?? UUID().uuidString
            currentGroup.forEach { $0.supersetGroupId = groupId }
            nextGroup.forEach { $0.supersetGroupId = groupId }
        }
    }

    /// Erstellt ein neues Superset aus den übergebenen Gruppen-Indizes (0-basiert, bezogen auf groupedTemplateSets).
    /// Passt sortOrder an, sodass die gewählten Übungen aufeinanderfolgend stehen.
    /// Maximal 5 Übungen pro Superset.
    func createSuperset(fromGroupIndices indices: [Int]) {
        let groups = groupedTemplateSets
        let validIndices = indices.filter { $0 < groups.count }.sorted()
        guard validIndices.count >= 2, validIndices.count <= 5 else { return }

        let newGroupId = UUID().uuidString

        // Alle ausgewählten Übungen bekommen die neue supersetGroupId
        for index in validIndices {
            groups[index].forEach { $0.supersetGroupId = newGroupId }
        }

        // sortOrder: Erste ausgewählte Übung bleibt an ihrer Position,
        // die anderen rücken direkt dahinter (fortlaufend)
        let anchorOrder = groups[validIndices[0]].first?.sortOrder ?? 1
        for (offset, index) in validIndices.enumerated() {
            groups[index].forEach { $0.sortOrder = anchorOrder + offset }
        }

        // Alle sortOrder-Werte lückenlos neu vergeben
        reindexSortOrders()
    }

    /// Entfernt eine einzelne Übung (Gruppe an Gruppen-Index) aus ihrem Superset.
    /// Falls danach nur noch eine Übung in der Gruppe verbleibt, wird das gesamte Superset aufgelöst.
    func removeFromSuperset(groupAt index: Int) {
        let groups = groupedTemplateSets
        guard index < groups.count else { return }
        let targetGroup = groups[index]

        guard let groupId = targetGroup.first?.supersetGroupId else { return }

        // Diese Übung aus dem Superset entfernen
        targetGroup.forEach { $0.supersetGroupId = nil }

        // Prüfen ob die verbleibende Gruppe noch ≥ 2 Übungen hat
        let remaining = safeTemplateSets.filter { $0.supersetGroupId == groupId }
        let remainingExerciseCount = Set(remaining.map { $0.groupKey }).count

        if remainingExerciseCount < 2 {
            remaining.forEach { $0.supersetGroupId = nil }
        }
    }

    /// Nummeriert alle sortOrder-Werte lückenlos neu (1-basiert, pro Übungsgruppe).
    /// Behält die relative Reihenfolge der Gruppen bei.
    private func reindexSortOrders() {
        let allGroups = groupedTemplateSets
        for (index, group) in allGroups.enumerated() {
            group.forEach { $0.sortOrder = index + 1 }
        }
    }

    // MARK: - Initialisierung

    init(
        title: String = "",
        planDescription: String = "",
        startDate: Date = Date(),
        endDate: Date? = nil,
        planType: PlanType = .mixed,
        isActive: Bool = true
    ) {
        self.title = title
        self.planDescription = planDescription
        self.startDate = startDate
        self.endDate = endDate
        self.planTypeRaw = planType.rawValue
        self.isActive = isActive
        self.createdAt = Date()
    }
}

extension TrainingPlan {
    var safeTemplateSets: [ExerciseSet] { templateSets ?? [] }

    func ensureTemplateSets() {
        if templateSets == nil { templateSets = [] }
    }

    func addTemplateSet(_ set: ExerciseSet) {
        ensureTemplateSets()
        set.trainingPlan = self
        set.session = nil
        templateSets?.append(set)
    }

    func removeTemplateSets(where predicate: (ExerciseSet) -> Bool) {
        ensureTemplateSets()
        templateSets?.removeAll(where: predicate)
    }
}
