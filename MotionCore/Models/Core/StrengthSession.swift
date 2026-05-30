//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Daten-Modell                                                     /
// Datei . . . . : StrengthWorkoutSession.swift                                     /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 17.12.2025                                                       /
// Beschreibung  : Datenmodell für Krafttrainings                                   /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
// Hinweis  . . : Enums für dieses Model findet man im File StrengthTypes.swift     /
//                Die UI-Ausgabe dieser Enums im File TypesUI.swift                 /
//                Die formatierten Werte aus dem Model sind in SessionUI            /
// ---------------------------------------------------------------------------------/
//
import Foundation
import SwiftData

@Model
final class StrengthSession {
    // MARK: Identifikation

    // Stabile UUID für Session-Tracking (überlebt App-Neustarts)
    var sessionUUID: UUID = UUID()

    // MARK: - Grunddaten

    var date: Date = Date()
    var duration: Int = 0 // Gesamtdauer in Minuten
    var calories: Int = 0 // Geschätzte Kalorien
    var notes: String = "" // Session-Notizen

    // MARK: - Körperdaten

    var bodyWeight: Double = 0.0 // Körpergewicht in kg
    var heartRate: Int = 0 // Durchschnittliche Herzfrequenz
    var maxHeartRate: Int = 0 // Maximale Herzfrequenz

    // MARK: - Beziehungen

    @Relationship(deleteRule: .cascade, inverse: \ExerciseSet.session)
    var exerciseSets: [ExerciseSet]? = []

    // MARK: - Health-Metriken (pro Übung)
    @Relationship(deleteRule: .cascade, inverse: \ExerciseMetrics.session)
    var exerciseMetrics: [ExerciseMetrics]? = []

    var safeExerciseMetrics: [ExerciseMetrics] { exerciseMetrics ?? [] }

    // MARK: - Übungsbewertungen (subjektiv, pro Übung)
    @Relationship(deleteRule: .cascade, inverse: \ExerciseRating.session)
    var exerciseRatings: [ExerciseRating]? = []

    var safeExerciseRatings: [ExerciseRating] { exerciseRatings ?? [] }

    // Referenz zum Trainingsplan (Template)
    @Relationship(deleteRule: .nullify)
    var sourceTrainingPlan: TrainingPlan?

    // MARK: - Session-Status

    var isCompleted: Bool = false // Training abgeschlossen?
    var isLiveSession: Bool = false // Live getrackt vs. manuell eingetragen
    /// Wurde diese Session bereits zu Supabase hochgeladen?
    var syncedToSupabase: Bool = false
    /// Wurde die Session nach erstem Supabase-Upload lokal geändert?
    /// true → ResyncService soll beim nächsten App-Start/Foreground hochladen.
    var needsSupabaseResync: Bool = false
    var startedAt: Date? // Wann gestartet?
    var completedAt: Date? // Wann beendet?

    // MARK: - Subjektive Bewertung für ML (NEU)

    var perceivedExertion: Int? // RPE 1-10 (Rate of Perceived Exertion)
    var energyLevelBefore: Int? // Energielevel vor Training (1-5)

    // MARK: - Smart-Progression (v1.1)

    /// 0–100, berechnet durch SessionQualityCalcEngine (Schritt 1.21)
    var sessionQualityScore: Int? = nil

    /// Soft-Link auf SessionReadiness.id (Phase 2)
    var sessionReadinessID: UUID? = nil

    // MARK: - HealthKit-Integration (NEU)

    var healthKitWorkoutUUID: UUID? // Verknüpfung zur HKWorkout
    var deviceSource: String = "manual" // "iPhone", "AppleWatch", "manual"

    // MARK: - Persistente ENUM-Rohwerte

    var workoutTypeRaw: String = "fullBody"
    var intensityRaw: Int = 0

    // MARK: - Typisierte ENUM-Properties

    var workoutType: StrengthWorkoutType {
        get { StrengthWorkoutType(rawValue: workoutTypeRaw) ?? .fullBody }
        set { workoutTypeRaw = newValue.rawValue }
    }

    var intensity: Intensity {
        get { Intensity(rawValue: intensityRaw) ?? .none }
        set { intensityRaw = newValue.rawValue }
    }

    // MARK: - Berechnete Werte

    // Anzahl der Sets in dieser Session
    var totalSets: Int {
        safeExerciseSets.count
    }

    var exercisesPerformed: Int {
        Set(safeExerciseSets.map { $0.groupKey }).count
    }

    var totalVolume: Double {
        safeExerciseSets.reduce(0.0) { sum, set in
            sum + (set.weight * Double(set.reps))
        }
    }

    // Trainierte Muskelgruppe
    var trainedMuscleGroups: [MuscleGroup] {
        var groups = Set<MuscleGroup>()

        for set in safeExerciseSets {
            // Später: Aus Exercise-Bibliothek holen
            // Jetzt: Mapping über exerciseName
            if let primary = set.primaryMuscleGroup {
                groups.insert(primary)
            }
        }

        return Array(groups).sorted { $0.rawValue < $1.rawValue }
    }

    // Fortschritt der Session

    // Anzahl abgeschlossener Sätze
    var completedSets: Int {
        safeExerciseSets.filter { $0.isCompleted }.count
    }

    // Fortschritt in Prozent (0.0 - 1.0)
    var progress: Double {
        guard totalSets > 0 else { return 0 }
        return Double(completedSets) / Double(totalSets)
    }

    // Alle Sätze erledigt?
    var allSetsCompleted: Bool {
        !safeExerciseSets.isEmpty && safeExerciseSets.allSatisfy { $0.isCompleted }
    }

    // Tatsächliche Trainingsdauer in Minuten (berechnet)
    var actualDuration: Int? {
        guard let start = startedAt, let end = completedAt else { return nil }
        return Calendar.current.dateComponents([.minute], from: start, to: end).minute
    }

    // Name des Trainingsplans (falls vorhanden)
    var planName: String? {
        sourceTrainingPlan?.title
    }

    // Gruppierte Sets nach Übungsname
    // Stabile Sortierung in zwei Schritten:
    // 1. Primär: nach der kleinsten setNumber in jeder Gruppe
    // 2. Sekundär: nach Übungsname für absolute Stabilität
    var groupedSets: [[ExerciseSet]] {
        let grouped = Dictionary(grouping: safeExerciseSets) { $0.groupKey }

        return grouped.values
            .map { sets in sets.sorted { $0.setNumber < $1.setNumber } }
            .sorted { group1, group2 in
                let sortOrder1 = group1.first?.sortOrder ?? Int.max
                let sortOrder2 = group2.first?.sortOrder ?? Int.max

                if sortOrder1 != sortOrder2 { return sortOrder1 < sortOrder2 }

                let minSet1 = group1.min(by: { $0.setNumber < $1.setNumber })?.setNumber ?? Int.max
                let minSet2 = group2.min(by: { $0.setNumber < $1.setNumber })?.setNumber ?? Int.max
                if minSet1 != minSet2 { return minSet1 < minSet2 }

                let name1 = group1.first?.exerciseNameSnapshot.isEmpty == false
                    ? group1.first!.exerciseNameSnapshot
                    : (group1.first?.exerciseName ?? "")

                let name2 = group2.first?.exerciseNameSnapshot.isEmpty == false
                    ? group2.first!.exerciseNameSnapshot
                    : (group2.first?.exerciseName ?? "")

                return name1 < name2
            }
    }

    // MARK: - Initialisierung

    init(
        date: Date = Date(),
        duration: Int = 0,
        calories: Int = 0,
        notes: String = "",
        bodyWeight: Double = 0.0,
        heartRate: Int = 0,
        maxHeartRate: Int = 0,
        isCompleted: Bool = false,
        isLiveSession: Bool = false,
        startedAt: Date? = nil,
        completedAt: Date? = nil,
        perceivedExertion: Int? = nil,
        energyLevelBefore: Int? = nil,
        healthKitWorkoutUUID: UUID? = nil,
        deviceSource: String = "manual",
        sessionQualityScore: Int? = nil,
        sessionReadinessID: UUID? = nil,
        workoutType: StrengthWorkoutType = .fullBody,
        intensity: Intensity = .none
    ) {
        self.date = date
        self.duration = max(duration, 0)
        self.calories = max(calories, 0)
        self.notes = notes
        self.bodyWeight = bodyWeight
        self.heartRate = heartRate
        self.maxHeartRate = maxHeartRate
        self.isCompleted = isCompleted
        self.isLiveSession = isLiveSession
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.perceivedExertion = perceivedExertion
        self.energyLevelBefore = energyLevelBefore
        self.healthKitWorkoutUUID = healthKitWorkoutUUID
        self.deviceSource = deviceSource
        self.sessionQualityScore = sessionQualityScore
        self.sessionReadinessID = sessionReadinessID
        self.workoutTypeRaw = workoutType.rawValue
        self.intensityRaw = intensity.rawValue
    }

    // Nächster unerledigter Satz
    var nextUncompletedSet: ExerciseSet? {
        safeExerciseSets
            .sorted {
                // Primär nach sortOrder
                if $0.sortOrder != $1.sortOrder {
                    return $0.sortOrder < $1.sortOrder
                }
                // Sekundär nach setNumber
                return $0.setNumber < $1.setNumber
            }
            .first { !$0.isCompleted }
    }
}
extension StrengthSession {
    var safeExerciseSets: [ExerciseSet] { exerciseSets ?? [] }

    func ensureExerciseSets() {
        if exerciseSets == nil { exerciseSets = [] }
    }

    func addSet(_ set: ExerciseSet) {
        ensureExerciseSets()
        set.session = self
        set.trainingPlan = nil
        exerciseSets?.append(set)
    }

    func removeSet(_ set: ExerciseSet) {
        ensureExerciseSets()
        exerciseSets?.removeAll { $0.persistentModelID == set.persistentModelID }
        set.session = nil
    }

    func removeSets(where predicate: (ExerciseSet) -> Bool) {
        ensureExerciseSets()
        exerciseSets?.removeAll(where: predicate)
    }
}

// MARK: - Superset-API

extension StrengthSession {

    /// Erstellt ein neues Superset aus den übergebenen groupKeys.
    /// Voraussetzungen:
    ///   - Mindestens 2, maximal 5 Keys
    ///   - Alle Keys lückenlos aufeinanderfolgend in groupedSets
    ///   - Keine der gewählten Übungen hat completed Sets oder bestehendes Superset
    /// Passt restSeconds an: alle Übungen außer der letzten bekommen restSeconds = 0.
    /// Kein context.save() — übernimmt der Aufrufer.
    func createSuperset(fromGroupKeys keys: [String]) {
        let groups = groupedSets
        // groupKey-Lookup: stabile Identität statt fragile Int-Indizes
        let sorted = keys.compactMap { key in
            groups.firstIndex { $0.first?.groupKey == key }
        }.sorted()

        // Vorbedingungen prüfen
        guard sorted.count == keys.count else { return }        // alle Keys gefunden
        guard sorted.count >= 2, sorted.count <= 5 else { return }

        // Keine bereits bestehenden Supersets in den gewählten Gruppen
        guard sorted.allSatisfy({ groups[$0].allSatisfy { $0.supersetGroupId == nil } }) else { return }

        // Lückenlosigkeit
        let isContiguous = zip(sorted, sorted.dropFirst()).allSatisfy { $1 - $0 == 1 }
        guard isContiguous else { return }

        // Eligibility: keine completed Sets in den gewählten Gruppen
        let allEligible = sorted.allSatisfy { idx in
            groups[idx].allSatisfy { !$0.isCompleted }
        }
        guard allEligible else { return }

        let newGroupId = UUID().uuidString

        // supersetGroupId für alle gewählten Übungen setzen
        for idx in sorted {
            groups[idx].forEach { $0.supersetGroupId = newGroupId }
        }

        // Pausenzeiten anpassen:
        // Alle Übungen außer der letzten Übung pro Runde bekommen restSeconds = 0.
        // Die letzte Übung (letzter Index) behält ihre Originalzeiten.
        let lastGroupIndex = sorted.last!
        for idx in sorted where idx != lastGroupIndex {
            groups[idx].forEach { $0.restSeconds = 0 }
        }
    }

    /// Entfernt eine einzelne Übung (Gruppe an Gruppen-Index) aus ihrem
    /// Superset. Falls danach nur noch eine Übung in der Gruppe verbleibt,
    /// wird das gesamte Superset aufgelöst.
    /// restSeconds bleiben unverändert — der User kann sie manuell anpassen.
    /// Kein context.save() — übernimmt der Aufrufer.
    func removeFromSuperset(groupAt index: Int) {
        let groups = groupedSets
        guard index >= 0, index < groups.count else { return }
        let targetGroup = groups[index]

        guard let groupId = targetGroup.first?.supersetGroupId else { return }

        // Diese Übung aus dem Superset entfernen
        targetGroup.forEach { $0.supersetGroupId = nil }

        // Prüfen ob die verbleibende Gruppe noch ≥ 2 Übungen hat
        let remaining = safeExerciseSets.filter { $0.supersetGroupId == groupId }
        let remainingExerciseCount = Set(remaining.map { $0.groupKey }).count

        if remainingExerciseCount < 2 {
            remaining.forEach { $0.supersetGroupId = nil }
        }
    }
}
