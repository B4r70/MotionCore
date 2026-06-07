//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Aktive Workouts                                                  /
// Datei . . . . : ActiveWorkoutSmartFillViewModel.swift                            /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 18.04.2026                                                       /
// Beschreibung  : ViewModel für Smart-Fill: Engine-Aufruf, Cache, Prefill          /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation
import SwiftData

// MARK: - ActiveWorkoutSmartFillViewModel

/// Koordiniert ProgressionCalcEngine-Aufrufe für das aktive Training.
/// Hält einen Output-Cache pro exerciseGroupKey; Invalidierung bei Satz-Abschluss.
/// @MainActor: alle Writes erfolgen synchron auf dem Main Thread (SwiftData-Anforderung).
@MainActor
@Observable
final class ActiveWorkoutSmartFillViewModel {

    // MARK: - Cache

    /// Gecachter Engine-Output pro exerciseGroupKey (idempotenter Prefill)
    private(set) var cachedOutputs: [String: ProgressionCalcEngine.Output] = [:]

    /// In-Memory Suggestion-Flags pro setUUID.uuidString — kein SwiftData-Feld nötig
    private(set) var suggestionFlags: [String: Bool] = [:]

    // MARK: - Abhängigkeiten

    private let context: ModelContext
    private let repository: ProgressionStateProviding

    // MARK: - Init

    init(context: ModelContext, repository: ProgressionStateProviding) {
        self.context = context
        self.repository = repository
    }

    // MARK: - Prefill

    /// Befüllt offene Work-Sets einer Übung mit Engine-Empfehlungen.
    /// Idempotent: läuft nur einmal pro exerciseGroupKey pro Session-Öffnung (Cache-Guard).
    func prefillSuggestion(
        exerciseGroupKey: String,
        exercise: Exercise?,
        session: StrengthSession,
        lastCompletedSession: StrengthSession?,
        equipmentByID: [UUID: StudioEquipment],
        readinessModifier: Double = 1.0
    ) {
        // Idempotent: nur einmal pro Übung pro Session-Öffnung
        guard cachedOutputs[exerciseGroupKey] == nil else { return }
        guard let exercise else { return }

        // Progressions-Zustand laden — fehlt er, gibt es keine Suggestion (neue Übung ohne Historie)
        guard let progressionState = repository.fetch(exerciseGroupKey: exerciseGroupKey) else { return }

        // Letzte abgeschlossene Session-Sätze für diese Übung
        let lastSessionSets = lastCompletedSession?.safeExerciseSets
            .filter { $0.groupKey == exerciseGroupKey } ?? []

        // Bereits abgeschlossene Sätze der laufenden Session (für "folge vorherigem Satz"-Pfad)
        let currentSessionPrev = session.safeExerciseSets
            .filter { $0.groupKey == exerciseGroupKey }

        // Equipment-Lookup über studioEquipmentID der Übung
        let studioEquipment = exercise.studioEquipmentID.flatMap { equipmentByID[$0] }

        // Aktueller Satz-Index (Anzahl abgeschlossener Work-Sets in dieser Session)
        let currentIdx = currentSessionPrev.filter { $0.isCompleted }.count

        let input = ProgressionCalcEngine.Input(
            progressionState: progressionState,
            lastSessionSets: lastSessionSets,
            studioEquipment: studioEquipment,
            exerciseFallbackStep: exercise.progressionStep,
            readinessModifier: readinessModifier,
            currentSessionSetIndex: currentIdx,
            currentSessionPreviousSets: currentSessionPrev
        )

        let output = ProgressionCalcEngine.calculate(input: input)
        cachedOutputs[exerciseGroupKey] = output

        // Prefill: nur uncompleted Work-Sets befüllen
        let targets = currentSessionPrev
            .filter { !$0.isCompleted && $0.setKindRaw == "work" }
            .sorted { $0.sortOrder < $1.sortOrder }

        for set in targets {
            // Überschreibe nur wenn Template-Default ODER bereits eine eigene Engine-Suggestion
            let isTemplateDefault = set.weight == 0 && set.reps <= 1
            let isPreviousSuggestion = suggestionFlags[set.setUUID.uuidString] == true
            if isTemplateDefault || isPreviousSuggestion {
                set.weight = output.suggestedWeight
                set.reps = output.suggestedReps
                suggestionFlags[set.setUUID.uuidString] = true
            }
        }

        try? context.save()
    }

    // MARK: - Post-Complete

    /// Räumt den Cache-Eintrag einer abgeschlossenen Übung auf und legt lazy den
    /// ExerciseProgressionState an (Erstaufruf nach dem ersten Work-Set).
    func recordSetCompletion(completedSet: ExerciseSet, exercise: Exercise?) {
        // Cache verwerfen → nächster Prefill aktiviert "folge vorherigem Satz"-Pfad
        cachedOutputs.removeValue(forKey: completedSet.groupKey)

        // Suggestion-Flag räumen — Satz abgeschlossen, Suggestion nicht mehr aktiv
        suggestionFlags[completedSet.setUUID.uuidString] = false

        // Lazy-State-Creation: nur für Weight-Work-Sets und nur wenn Exercise bekannt
        guard let exercise, completedSet.setKindRaw == "work", !completedSet.isTimeBased else { return }
        repository.createIfMissing(
            exerciseGroupKey: completedSet.groupKey,
            workingWeight: completedSet.weight,
            exercise: exercise
        )
    }

    // MARK: - User-Confirmation (SetEditSheet)

    /// Markiert einen Satz als vom User bestätigt (Suggestion-Flag löschen).
    /// Wird aufgerufen wenn der User den SetEditSheet öffnet.
    func markUserConfirmed(set: ExerciseSet) {
        suggestionFlags[set.setUUID.uuidString] = false
    }

    // MARK: - UI-Hilfsmethoden

    /// Gibt zurück ob für den gegebenen Satz eine Engine-Suggestion aktiv ist.
    func isSuggestionActive(for set: ExerciseSet) -> Bool {
        suggestionFlags[set.setUUID.uuidString] == true
    }

    /// Gibt zurück ob der gecachte Engine-Output für den Satz auf .readinessReduced lautet.
    /// Wird von ReadinessReducedBadge genutzt um das Badge sichtbar zu schalten.
    func isReadinessReduced(for set: ExerciseSet) -> Bool {
        cachedOutputs[set.groupKey]?.reasoning == .readinessReduced
    }
}
