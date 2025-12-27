//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Daten-Modell                                                     /
// Datei . . . . : TrainingPlan.swift                                               /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 23.12.2025                                                       /
// Beschreibung  : Trainingsplan mit mehreren TrainingEntries                       /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation
import SwiftData

@Model
final class TrainingPlan {
    // MARK: - Grunddaten

    var title: String = ""                  // Name des Plans
    var planDescription: String = ""        // Beschreibung/Ziel
    var startDate: Date = Date()            // Startdatum
    var endDate: Date?                      // Optional: Enddatum
    var isActive: Bool = true               // Aktiver Plan?
    var createdAt: Date = Date()            // Erstellungsdatum

    // MARK: - Persistente ENUM-Rohwerte

    var planTypeRaw: String = "cardio"      // "cardio", "strength", "outdoor", "mixed"

    // MARK: - Typisierte ENUM-Property

    var planType: PlanType {
        get { PlanType(rawValue: planTypeRaw) ?? .mixed }
        set { planTypeRaw = newValue.rawValue }
    }

    // MARK: - Beziehungen

    @Relationship(deleteRule: .cascade)
    var entries: [TrainingEntry] = []       // Alle Einträge in diesem Plan

    @Relationship(deleteRule: .cascade, inverse: \ExerciseSet.trainingPlan)
    var templateSets: [ExerciseSet] = []

    // MARK: - Berechnete Werte

    /// Anzahl der geplanten Trainings
    var totalEntries: Int {
        entries.count
    }

    /// Anzahl der abgeschlossenen Trainings
    var completedEntries: Int {
        entries.filter { $0.isCompleted }.count
    }

    /// Fortschritt in Prozent (0.0 - 1.0)
    var progress: Double {
        guard totalEntries > 0 else { return 0 }
        return Double(completedEntries) / Double(totalEntries)
    }

    /// Anzahl verpasster Trainings
    var missedEntries: Int {
        entries.filter { $0.isMissed }.count
    }

    /// Noch ausstehende Trainings
    var remainingEntries: Int {
        entries.filter { !$0.isCompleted && !$0.isMissed }.count
    }

    /// Plan ist abgelaufen?
    var isExpired: Bool {
        guard let end = endDate else { return false }
        return end < Date()
    }

    /// Anzahl Tage im Plan
    var durationInDays: Int? {
        guard let end = endDate else { return nil }
        return Calendar.current.dateComponents([.day], from: startDate, to: end).day
    }

    /// Nächstes anstehendes Training
    var nextEntry: TrainingEntry? {
        entries
            .filter { !$0.isCompleted }
            .sorted { $0.scheduledDate < $1.scheduledDate }
            .first
    }
    // Erstellt eine neue StrengthSession basierend auf diesem Template
    func createSession() -> StrengthSession {
        let session = StrengthSession(
            date: Date(),
            workoutType: .custom
        )

        // Referenz zum Template setzen
        session.sourceTrainingPlan = self
        session.start()  // NEU: Direkt starten

        // Template-Sets kopieren
        for templateSet in templateSets {
            let newSet = ExerciseSet(
                exerciseName: templateSet.exerciseName,
                exerciseId: templateSet.exerciseId,
                exerciseGifAssetName: templateSet.exerciseGifAssetName,
                setNumber: templateSet.setNumber,
                weight: templateSet.weight,
                reps: templateSet.reps,
                duration: templateSet.duration,
                distance: templateSet.distance,
                isWarmup: templateSet.isWarmup,
                isCompleted: false,
                rpe: 0,
                notes: ""
            )
            newSet.exercise = templateSet.exercise
            session.exerciseSets.append(newSet)
        }

        return session
    }

    // Gruppierte Template-Sets nach Übungsname
    var groupedTemplateSets: [[ExerciseSet]] {
        let grouped = Dictionary(grouping: templateSets) { $0.exerciseName }
        return grouped.values.sorted { ($0.first?.exerciseName ?? "") < ($1.first?.exerciseName ?? "") }
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
