// ---------------------------------------------------------------------------------/
//  # MotionCore                                                                    /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Hauptprogramm                                                    /
// Datei . . . . : AppSchema.swift                                                  /
// Autor . . . . : Bartosz Stryjewski                                               //
// Erstellt am . : 14.05.2026                                                       /
// Beschreibung  : Einzige Quelle des SwiftData-Schemas — geteilt von App und      /
//                 Preview. Alle SwiftData-Modelltypen werden hier zentral          /
//                 registriert.                                                     /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftData

/// Zentrales SwiftData-Schema für App und Preview.
/// Änderungen hier wirken sofort auf beide Konsumenten.
let appSchema = Schema([
    CardioSession.self,
    StrengthSession.self,
    OutdoorSession.self,
    ExerciseSet.self,
    ExerciseMetrics.self,
    ExerciseRating.self,
    Exercise.self,
    TrainingPlan.self,
    Studio.self,
    StudioEquipment.self,
    ExerciseProgressionState.self,
    SessionReadiness.self,
    HealthBaseline.self,
    BodyMeasurement.self
])
