//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Extensions Daten-Modell                                          /
// Datei . . . . : MuscleGroupMapper.swift                                          /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 17.12.2025                                                       /
// Beschreibung  : Vorübergehender Helper als Ersatz für die Exercise-Bibliothek    /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

struct MuscleGroupMapper {

        // Primäre Muskelgruppe für eine Übung
    static func primaryMuscle(for exerciseName: String) -> MuscleGroup? {
        let name = exerciseName.lowercased()

            // Brust
        if name.contains("Bankdrücken") || name.contains("bench press") ||
            name.contains("Fliegende") || name.contains("fly") ||
            name.contains("Dips") {
            return .chest
        }

            // Rücken
        if name.contains("Klimmzug") || name.contains("pull") ||
            name.contains("Rudern") || name.contains("row") ||
            name.contains("Latzug") || name.contains("lat pulldown") ||
            name.contains("Kreuzheben") || name.contains("deadlift") {
            return .back
        }

            // Schultern
        if name.contains("Schulter") || name.contains("shoulder") ||
            name.contains("Military Press") || name.contains("overhead") ||
            name.contains("seitheben") || name.contains("lateral raise") {
            return .shoulders
        }

            // Arme
        if name.contains("bizeps") || name.contains("curl") ||
            name.contains("trizeps") || name.contains("tricep") {
            return .arms
        }

            // Beine
        if name.contains("kniebeuge") || name.contains("squat") ||
            name.contains("beinpresse") || name.contains("leg press") ||
            name.contains("ausfallschritt") || name.contains("lunge") {
            return .legs
        }

            // Core
        if name.contains("plank") || name.contains("crunch") ||
            name.contains("sit-up") || name.contains("bauch") {
            return .core
        }

        return nil
    }

        // Sekundäre Muskelgruppen für eine Übung
    static func secondaryMuscles(for exerciseName: String) -> [MuscleGroup] {
        let name = exerciseName.lowercased()
        var secondary: [MuscleGroup] = []

            // Bankdrücken
        if name.contains("bankdrücken") || name.contains("bench press") {
            secondary = [.shoulders, .arms]
        }

            // Klimmzüge
        if name.contains("klimmzug") || name.contains("pull up") {
            secondary = [.arms, .core]
        }

            // Kniebeugen
        if name.contains("kniebeuge") || name.contains("squat") {
            secondary = [.glutes, .core]
        }

            // Kreuzheben
        if name.contains("kreuzheben") || name.contains("deadlift") {
            secondary = [.glutes, .legs, .core]
        }

            // Schulterdrücken
        if name.contains("schulterdrücken") || name.contains("shoulder press") {
            secondary = [.arms, .core]
        }

        return secondary
    }
}

extension MuscleGroupMapper {
    /// Konvertiert Supabase Muskelgruppen-Strings zu MotionCore MuscleGroup-Enum
    /// - Parameter supabaseValue: Der Muskelgruppen-String aus Supabase (z.B. "chest", "biceps")
    /// - Returns: MuscleGroup Enum oder nil wenn nicht gemappt werden kann
    static func map(supabaseValue: String) -> MuscleGroup? {
        let lowercased = supabaseValue.lowercased()

        // Spezielle Mappings für Untergruppen (detailliert)
        switch lowercased {
        // Bauch/Core Untergruppen
        case "abs_lower", "abs_upper", "abs_obliques":
            return .core

        // Brust Untergruppen
        case "chest_upper", "chest_lower", "chest_middle":
            return .chest

        // Rücken Untergruppen
        case "back_lats", "back_lower", "back_upper", "back_middle":
            return .back

        // Schultern Untergruppen
        case "shoulders_front", "shoulders_side", "shoulders_rear":
            return .shoulders

        // Beine Untergruppen
        case "legs_quads", "legs_hamstrings", "legs_calves":
            return .legs

        // Arme Untergruppen
        case "arms_biceps", "arms_triceps", "arms_forearms":
            return .arms

        // Standard-Mappings (Hauptgruppen)
        // Brust
        case "chest", "pectorals", "pectoralis major", "pectoralis minor":
            return .chest

        // Rücken
        case "back", "lats", "latissimus dorsi", "upper back", "middle back",
             "lower back", "traps", "trapezius", "rhomboids", "erector spinae":
            return .back

        // Schultern
        case "shoulders", "delts", "deltoids", "deltoid",
             "deltoid anterior", "deltoid posterior", "deltoid lateral":
            return .shoulders

        // Arme
        case "biceps", "biceps brachii", "triceps", "triceps brachii",
             "forearms", "brachialis", "brachioradialis":
            return .arms

        // Beine
        case "legs", "quadriceps", "quads", "hamstrings", "calves",
             "tibialis anterior", "gastrocnemius", "soleus",
             "adductors", "abductors":
            return .legs

        // Gesäß
        case "glutes", "gluteus maximus", "gluteus medius", "gluteus minimus":
            return .glutes

        // Core/Bauch
        case "core", "abs", "abdominals", "rectus abdominis", "obliques",
             "transverse abdominis", "serratus anterior":
            return .core

        // Ganzkörper
        case "full body", "total body", "whole body":
            return .fullBody

        // Nacken
        case "neck", "levator scapulae", "sternocleidomastoid":
            return .other

        // Hüfte
        case "hip flexors", "hip", "iliopsoas":
            return .legs

        // Nicht zuordenbar
        default:
            print("⚠️ Unbekannte Muskelgruppe aus Supabase: '\(supabaseValue)' → Fallback: nil")
            return nil
        }
    }
}
