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

// MARK: - Tracking-Modus eines Satzes (Gewicht vs. Zeit)

enum SetTrackingMode: String, Codable, CaseIterable, Identifiable {
    case weight = "weight"  // Standard: Gewicht × Wiederholungen
    case time   = "time"    // Zeitbasiert: Dauer in Sekunden

    var id: String { rawValue }

    /// Deutsches Anzeigelabel
    var description: String {
        switch self {
        case .weight: return "Gewicht"
        case .time:   return "Zeit"
        }
    }
}

// MARK: - Subjektive Qualitätsbewertung pro Übung

enum ExerciseQualityRating: String, Codable, CaseIterable, Identifiable {
    case poor    = "poor"    // Schlecht — Technik oder Gefühl war nicht gut
    case neutral = "neutral" // Mittel — Durchschnittliche Ausführung
    case good    = "good"    // Gut — Sauber, kraftvoll, kontroliert

    var id: Self { self }

    // SF Symbol-Name für jede Bewertungsstufe
    var icon: String {
        switch self {
        case .poor:    return "hand.thumbsdown.fill"
        case .neutral: return "hand.point.right.fill"
        case .good:    return "hand.thumbsup.fill"
        }
    }

    // Deutsches Kurzlabel
    var label: String {
        switch self {
        case .poor:    return "Schlecht"
        case .neutral: return "Mittel"
        case .good:    return "Gut"
        }
    }
}

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

// MARK: - Detailed Muscles (Feingranulare Muskel-Definition — 1:1 mit Supabase)

enum DetailedMuscle: String, CaseIterable, Identifiable, Codable {
    // Brust (5)
    case chestUpper = "chest_upper"
    case chestMiddle = "chest_middle"
    case chestLower = "chest_lower"
    case chestInner = "chest_inner"
    case chestOuter = "chest_outer"

    // Rücken (7)
    case backLats = "back_lats"
    case backTrapsUpper = "back_traps_upper"
    case backTrapsMiddle = "back_traps_middle"
    case backTrapsLower = "back_traps_lower"
    case backRhomboids = "back_rhomboids"
    case backErectorSpinae = "back_erector_spinae"
    case backTeres = "back_teres"

    // Schultern (3)
    case shouldersFront = "shoulders_front"
    case shouldersSide = "shoulders_side"
    case shouldersRear = "shoulders_rear"

    // Arme — Bizeps (2)
    case bicepsLong = "biceps_long"
    case bicepsShort = "biceps_short"

    // Arme — Trizeps (3)
    case tricepsLong = "triceps_long"
    case tricepsLateral = "triceps_lateral"
    case tricepsMedial = "triceps_medial"

    // Arme — Unterarme (2)
    case forearmFlexors = "forearms_flexors"
    case forearmExtensors = "forearms_extensors"

    // Beine — Quads (4)
    case quadsVastusLateralis = "quads_vastus_lateralis"
    case quadsVastusMedialis = "quads_vastus_medialis"
    case quadsVastusIntermedius = "quads_vastus_intermedius"
    case quadsRectusFemoris = "quads_rectus_femoris"

    // Beine — Hamstrings (3)
    case hamstringsBicepsFemoris = "hamstrings_biceps_femoris"
    case hamstringsSemitendinosus = "hamstrings_semitendinosus"
    case hamstringsSemimembranosus = "hamstrings_semimembranosus"

    // Beine — Glutes (3)
    case glutesMaximus = "glutes_maximus"
    case glutesMedius = "glutes_medius"
    case glutesMinimus = "glutes_minimus"

    // Beine — Waden (2)
    case calvesGastrocnemius = "calves_gastrocnemius"
    case calvesSoleus = "calves_soleus"

    // Beine — Hüfte (2)
    case adductors = "adductors"
    case abductors = "abductors"

    // Core (5)
    case absUpper = "abs_upper"
    case absLower = "abs_lower"
    case absObliques = "abs_obliques"
    case absTransverse = "abs_transverse"
    case lowerBack = "lower_back"

    // SVG-only — kein Supabase-Pendant (1)
    case neck = "neck"

    var id: String { rawValue }

    var description: String { displayName }
}

// MARK: - DetailedMuscle Computed Properties

extension DetailedMuscle {

    // Supabase-Identifier — identisch mit rawValue für alle außer .neck
    var supabaseIdentifier: String? {
        self == .neck ? nil : rawValue
    }

    // SVG-Element-ID für die Muskel-Heatmap
    // nil für absTransverse (tiefe Muskulatur, kein sichtbares SVG-Element)
    var svgRegionId: String? {
        switch self {
        // Brust
        case .chestUpper: return "upper_pecs"
        case .chestMiddle, .chestInner, .chestOuter: return "middle_pecs"
        case .chestLower: return "lower_pecs"
        // Rücken
        case .backLats, .backTeres: return "lats"
        case .backTrapsUpper: return "upper_traps"
        case .backTrapsMiddle, .backTrapsLower: return "lower_traps"
        case .backRhomboids: return "rhomboids"
        case .backErectorSpinae: return "lower_back"
        // Schultern
        case .shouldersFront: return "front_delts"
        case .shouldersSide: return "side_delts"
        case .shouldersRear: return "rear_delts"
        // Arme
        case .bicepsLong, .bicepsShort: return "biceps"
        case .tricepsLong, .tricepsLateral, .tricepsMedial: return "triceps"
        case .forearmFlexors, .forearmExtensors: return "forearms"
        // Beine
        case .quadsVastusLateralis, .quadsVastusMedialis,
             .quadsVastusIntermedius, .quadsRectusFemoris: return "quads"
        case .hamstringsBicepsFemoris, .hamstringsSemitendinosus,
             .hamstringsSemimembranosus: return "hamstrings"
        case .glutesMaximus, .glutesMedius, .glutesMinimus: return "glutes"
        case .calvesGastrocnemius, .calvesSoleus: return "calves"
        case .adductors: return "hip_adductor"
        case .abductors: return "hip_abductor"
        // Core
        case .absUpper: return "upper_abs"
        case .absLower: return "lower_abs"
        case .absObliques: return "obliques"
        case .absTransverse: return nil
        case .lowerBack: return "lower_back"
        // SVG-only
        case .neck: return "neck"
        }
    }

    /// Übergeordnete Hauptmuskelgruppe (Rückwärtskompatibilität)
    var parentGroup: MuscleGroup {
        switch self {
        case .chestUpper, .chestMiddle, .chestLower, .chestInner, .chestOuter:
            return .chest
        case .backLats, .backTrapsUpper, .backTrapsMiddle, .backTrapsLower,
             .backRhomboids, .backErectorSpinae, .backTeres:
            return .back
        case .shouldersFront, .shouldersSide, .shouldersRear:
            return .shoulders
        case .bicepsLong, .bicepsShort, .tricepsLong, .tricepsLateral,
             .tricepsMedial, .forearmFlexors, .forearmExtensors:
            return .arms
        case .quadsVastusLateralis, .quadsVastusMedialis, .quadsVastusIntermedius,
             .quadsRectusFemoris, .hamstringsBicepsFemoris, .hamstringsSemitendinosus,
             .hamstringsSemimembranosus, .calvesGastrocnemius, .calvesSoleus,
             .adductors, .abductors:
            return .legs
        case .glutesMaximus, .glutesMedius, .glutesMinimus:
            return .glutes
        case .absUpper, .absLower, .absObliques, .absTransverse, .lowerBack:
            return .core
        case .neck:
            return .other
        }
    }

    /// Deutscher Anzeigename
    var displayName: String {
        switch self {
        case .chestUpper: return "Obere Brust"
        case .chestMiddle: return "Mittlere Brust"
        case .chestLower: return "Untere Brust"
        case .chestInner: return "Innere Brust"
        case .chestOuter: return "Äußere Brust"
        case .backLats: return "Latissimus"
        case .backTrapsUpper: return "Oberer Trapez"
        case .backTrapsMiddle: return "Mittlerer Trapez"
        case .backTrapsLower: return "Unterer Trapez"
        case .backRhomboids: return "Rhomboideus"
        case .backErectorSpinae: return "Rückenstrecker"
        case .backTeres: return "Teres"
        case .shouldersFront: return "Vordere Schulter"
        case .shouldersSide: return "Seitliche Schulter"
        case .shouldersRear: return "Hintere Schulter"
        case .bicepsLong: return "Bizeps (Langer Kopf)"
        case .bicepsShort: return "Bizeps (Kurzer Kopf)"
        case .tricepsLong: return "Trizeps (Langer Kopf)"
        case .tricepsLateral: return "Trizeps (Lateraler Kopf)"
        case .tricepsMedial: return "Trizeps (Medialer Kopf)"
        case .forearmFlexors: return "Unterarm-Beuger"
        case .forearmExtensors: return "Unterarm-Strecker"
        case .quadsVastusLateralis: return "Vastus Lateralis"
        case .quadsVastusMedialis: return "Vastus Medialis"
        case .quadsVastusIntermedius: return "Vastus Intermedius"
        case .quadsRectusFemoris: return "Rectus Femoris"
        case .hamstringsBicepsFemoris: return "Beinbizeps"
        case .hamstringsSemitendinosus: return "Semitendinosus"
        case .hamstringsSemimembranosus: return "Semimembranosus"
        case .glutesMaximus: return "Gluteus Maximus"
        case .glutesMedius: return "Gluteus Medius"
        case .glutesMinimus: return "Gluteus Minimus"
        case .calvesGastrocnemius: return "Gastrocnemius"
        case .calvesSoleus: return "Soleus"
        case .adductors: return "Adduktoren"
        case .abductors: return "Abduktoren"
        case .absUpper: return "Obere Bauchmuskeln"
        case .absLower: return "Untere Bauchmuskeln"
        case .absObliques: return "Seitliche Bauchmuskeln"
        case .absTransverse: return "Quere Bauchmuskeln"
        case .lowerBack: return "Unterer Rücken"
        case .neck: return "Nacken"
        }
    }
}
