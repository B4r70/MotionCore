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
