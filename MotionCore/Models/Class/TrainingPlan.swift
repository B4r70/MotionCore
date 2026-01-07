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
import SwiftUI

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

    // Anzahl der geplanten Trainings
    var totalEntries: Int {
        entries.count
    }

    // Anzahl der abgeschlossenen Trainings
    var completedEntries: Int {
        entries.filter { $0.isCompleted }.count
    }

    // Fortschritt in Prozent (0.0 - 1.0)
    var progress: Double {
        guard totalEntries > 0 else { return 0 }
        return Double(completedEntries) / Double(totalEntries)
    }

    // Anzahl verpasster Trainings
    var missedEntries: Int {
        entries.filter { $0.isMissed }.count
    }

    // Noch ausstehende Trainings
    var remainingEntries: Int {
        entries.filter { !$0.isCompleted && !$0.isMissed }.count
    }

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

    // Nächstes anstehendes Training
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
        session.start()  // Direkt starten

        // Template-Sets kopieren (sortiert nach sortOrder)
        for templateSet in templateSets.sorted(by: { $0.sortOrder < $1.sortOrder }) {
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
                sortOrder: templateSet.sortOrder  // NEU: Sortierung uebernehmen
            )
            newSet.exercise = templateSet.exercise
            session.exerciseSets.append(newSet)
        }

        return session
    }

    // Gruppierte Template-Sets, sortiert nach sortOrder
    var groupedTemplateSets: [[ExerciseSet]] {
        let grouped = Dictionary(grouping: templateSets) { $0.exerciseName }
        return grouped.values.sorted { group1, group2 in
            let order1 = group1.first?.sortOrder ?? Int.max
            let order2 = group2.first?.sortOrder ?? Int.max
            return order1 < order2
        }
    }

    // Naechste verfuegbare sortOrder fuer neue Uebungen
    var nextSortOrder: Int {
        let maxOrder = templateSets.map { $0.sortOrder }.max() ?? -1
        return maxOrder + 1
    }

    // MARK: Uebungs-Sortierung

    // Uebungen manuell neu sortieren (fuer Drag & Drop)
    // - Parameters:
    //   - source: IndexSet mit dem Quell-Index
    //   - destination: Ziel-Index (Position nach dem Move)
    func reorderExercises(fromOffsets source: IndexSet, toOffset destination: Int) {
        // Aktuelle Gruppen holen
        var groups = groupedTemplateSets

        // Move durchfuehren
        groups.move(fromOffsets: source, toOffset: destination)

        // Neue sortOrder fuer alle Sets setzen
        for (index, group) in groups.enumerated() {
            for set in group {
                set.sortOrder = index
            }
        }
    }

    // Alternative Methode fuer direktes Reordering mit from/to Index
    func reorderExercise(from sourceIndex: Int, to destinationIndex: Int) {
        var groups = groupedTemplateSets
        guard sourceIndex != destinationIndex,
              sourceIndex >= 0, sourceIndex < groups.count,
              destinationIndex >= 0, destinationIndex < groups.count else { return }

        // Element entfernen und an neuer Position einfuegen
        let movedGroup = groups.remove(at: sourceIndex)
        groups.insert(movedGroup, at: destinationIndex)

        // Neue sortOrder fuer alle Sets setzen
        for (index, group) in groups.enumerated() {
            for set in group {
                set.sortOrder = index
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

            // Neue sortOrder zuweisen
        for (index, group) in groups.enumerated() {
            for set in group {
                set.sortOrder = index
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
