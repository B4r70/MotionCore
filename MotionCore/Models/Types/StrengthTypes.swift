//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Daten-Modell                                                     /
// Datei . . . . : StrengthTypes.swift                                              /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 17.12.2025                                                       /
// Beschreibung  : Enumerationen für die Krafttraining-Klasse                       /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

// MARK: Workout-Typen für Krafttrainings

enum StrengthWorkoutType: String, Codable, CaseIterable, Identifiable {
    case fullBody       // Ganzkörper
    case upper          // Oberkörper
    case lower          // Unterkörper
    case push           // Push (Druck-Übungen)
    case pull           // Pull (Zug-Übungen)
    case legs           // Beine
    case core           // Core/Bauch
    case custom         // Individuell

    var id: Self { self }
}

// MARK: - Muscle Groups (Grobe Einteilung)

enum MuscleGroup: String, CaseIterable, Identifiable, Codable {
        // Oberkörper
    case chest = "Brust"
    case back = "Rücken"
    case shoulders = "Schultern"
    case arms = "Arme"
    case core = "Core"

        // Unterkörper
    case legs = "Beine"
    case glutes = "Gesäß"

        // Sonstiges
    case fullBody = "Ganzkörper"
    case other = "Sonstiges"

    var id: String { rawValue }

    var description: String { rawValue }
}

// MARK: - Detailed Muscles (Feine Unterteilung)

enum DetailedMuscle: String, CaseIterable, Identifiable, Codable {
        // Brust
    case chestUpper = "Obere Brust"
    case chestMiddle = "Mittlere Brust"
    case chestLower = "Untere Brust"

        // Rücken
    case lats = "Latissimus (Breiter Rücken)"
    case trapsUpper = "Oberer Trapezius (Nacken)"
    case trapsMid = "Mittlerer Trapezius"
    case lowerBack = "Unterer Rücken"
    case rhomboids = "Rhomboid (Rautenmuskeln)"

        // Schultern
    case deltFront = "Vordere Schulter"
    case deltSide = "Seitliche Schulter"
    case deltRear = "Hintere Schulter"

        // Arme
    case biceps = "Bizeps"
    case triceps = "Trizeps"
    case forearms = "Unterarme"

        // Beine
    case quads = "Quadrizeps (Oberschenkel vorne)"
    case hamstrings = "Beinbeuger (Oberschenkel hinten)"
    case calves = "Waden"
    case glutes = "Gesäß"
    case hipFlexors = "Hüftbeuger"

        // Core
    case abs = "Bauch (Rectus Abdominis)"
    case obliques = "Seitliche Bauchmuskeln"
    case lowerAbs = "Untere Bauchmuskeln"
    case transverse = "Tiefe Rumpfmuskulatur"

    var id: String { rawValue }

    var description: String { rawValue }

        // Zuordnung zu Hauptmuskelgruppe
    var parentGroup: MuscleGroup {
        switch self {
            case .chestUpper, .chestMiddle, .chestLower:
                return .chest

            case .lats, .trapsUpper, .trapsMid, .lowerBack, .rhomboids:
                return .back

            case .deltFront, .deltSide, .deltRear:
                return .shoulders

            case .biceps, .triceps, .forearms:
                return .arms

            case .quads, .hamstrings, .calves, .hipFlexors:
                return .legs

            case .glutes:
                return .glutes

            case .abs, .obliques, .lowerAbs, .transverse:
                return .core
        }
    }
}
