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
    var maxHeartRate: Int = 0 // NEU: Maximale Herzfrequenz

    // MARK: - Beziehungen

    @Relationship(deleteRule: .cascade)
    var exerciseSets: [ExerciseSet] = [] // Alle Sets dieser Session

    // Referenz zum Trainingsplan (Template)
    @Relationship(deleteRule: .nullify)
    var sourceTrainingPlan: TrainingPlan?

    // MARK: - Session-Status

    var isCompleted: Bool = false // Training abgeschlossen?
    var isLiveSession: Bool = false // NEU: Live getrackt vs. manuell eingetragen
    var startedAt: Date? // Wann gestartet?
    var completedAt: Date? // Wann beendet?

    // MARK: - Subjektive Bewertung für ML (NEU)

    var perceivedExertion: Int? // RPE 1-10 (Rate of Perceived Exertion)
    var energyLevelBefore: Int? // Energielevel vor Training (1-5)

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
        exerciseSets.count
    }

    // Anzahl der verschiedenen Übungen
    var exercisesPerformed: Int {
        Set(exerciseSets.map { $0.exerciseName }).count
    }

    // Gesamtes Trainingsvolumen (Summe: Gewicht × Reps)
    var totalVolume: Double {
        exerciseSets.reduce(0.0) { sum, set in
            sum + (set.weight * Double(set.reps))
        }
    }

    // Trainierte Muskelgruppe
    var trainedMuscleGroups: [MuscleGroup] {
        var groups = Set<MuscleGroup>()

        for set in exerciseSets {
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
        exerciseSets.filter { $0.isCompleted }.count
    }

    // Fortschritt in Prozent (0.0 - 1.0)
    var progress: Double {
        guard totalSets > 0 else { return 0 }
        return Double(completedSets) / Double(totalSets)
    }

    // Alle Sätze erledigt?
    var allSetsCompleted: Bool {
        !exerciseSets.isEmpty && exerciseSets.allSatisfy { $0.isCompleted }
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
        let grouped = Dictionary(grouping: exerciseSets) { $0.exerciseName }
        return grouped.values
            .map { sets in sets.sorted { $0.setNumber < $1.setNumber } }
            .sorted { group1, group2 in
                let minSet1 = group1.min(by: { $0.setNumber < $1.setNumber })?.setNumber ?? Int.max
                let minSet2 = group2.min(by: { $0.setNumber < $1.setNumber })?.setNumber ?? Int.max

                // Primär nach setNumber sortieren
                if minSet1 != minSet2 {
                    return minSet1 < minSet2
                }

                // Sekundär nach Übungsname für Stabilität
                let name1 = group1.first?.exerciseName ?? ""
                let name2 = group2.first?.exerciseName ?? ""
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
        self.workoutTypeRaw = workoutType.rawValue
        self.intensityRaw = intensity.rawValue
    }

    // MARK: - Session-Steuerung

    // Training starten
    func start() {
        startedAt = Date()
        isCompleted = false
        isLiveSession = true // NEU: Markiert als Live-Session
    }

    // Training beenden
    func complete() {
        completedAt = Date()
        isCompleted = true

        // Dauer berechnen und speichern
        if let minutes = actualDuration {
            duration = minutes
        }
    }

    // Nächster unerledigter Satz
    var nextUncompletedSet: ExerciseSet? {
        exerciseSets
            .sorted { $0.setNumber < $1.setNumber }
            .first { !$0.isCompleted }
    }
}






