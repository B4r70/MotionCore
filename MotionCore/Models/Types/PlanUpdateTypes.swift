//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Daten-Modell                                                     /
// Datei . . . . : PlanUpdateTypes.swift                                            /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 21.03.2026                                                       /
// Beschreibung  : Typen für das Smart Plan-Update Feature                          /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

// MARK: - ExerciseSet-Snapshot (schlanke Kopie ohne SwiftData-Abhängigkeit)

struct ExerciseSetSnapshot: Codable {
    var exerciseName: String
    var exerciseNameSnapshot: String
    var exerciseUUIDSnapshot: String
    var exerciseMediaAssetName: String
    var isUnilateralSnapshot: Bool
    var setNumber: Int
    var weight: Double
    var weightPerSide: Double
    var reps: Int
    var targetRepsMin: Int
    var targetRepsMax: Int
    var targetRIR: Int
    var setKind: SetKind
    var restSeconds: Int
    var sortOrder: Int
    var groupId: String
    var supersetGroupId: String?
}

// MARK: - Plan-Update Änderungstyp

enum PlanUpdateChangeType {
    case weightUpdate(from: Double, to: Double)
    case setCountUpdate(from: Int, to: Int)
    case exerciseAdded(sets: [ExerciseSetSnapshot])
    case exerciseSkipped(timesSkipped: Int, outOf: Int)
    /// Übung aus dem Plan entfernen (aus Option-A Session-Sync; standardmäßig NICHT vorselektiert)
    case exerciseRemoved
}

// MARK: - Metadaten für Änderungs-Hinweistexte

struct PlanUpdateChangeMetadata {
    /// Anzahl Sessions, in denen diese Übung vorkam
    var sessionOccurrences: Int
    /// Gesamtzahl der analysierten Sessions
    var sessionsAnalyzed: Int
}

// MARK: - Einzelne Änderung

struct PlanUpdateChange: Identifiable {
    var id: UUID = UUID()
    var exerciseGroupKey: String
    var exerciseName: String
    var changeType: PlanUpdateChangeType
    var isSelected: Bool = true
    /// Optionale Metadaten für Hinweistexte (z.B. "In X von Y Sessions trainiert")
    var metadata: PlanUpdateChangeMetadata? = nil
}

// MARK: - Gesamtvorschlag

struct PlanUpdateProposal: Identifiable {
    var id: String { plan.planUUID.uuidString }
    var plan: TrainingPlan
    var changes: [PlanUpdateChange]
    var analyzedSessionCount: Int
    var analyzedSessionDates: [Date]
    /// UUID (als String) der Session, die diesen Vorschlag ausgelöst hat
    var sourceSessionUUID: String?

    var hasChanges: Bool {
        !changes.isEmpty
    }

    var selectedChanges: [PlanUpdateChange] {
        changes.filter { $0.isSelected }
    }
}
