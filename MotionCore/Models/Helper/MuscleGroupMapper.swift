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

        /// Primäre Muskelgruppe für eine Übung
    static func primaryMuscle(for exerciseName: String) -> MuscleGroup? {
        let name = exerciseName.lowercased()

            // Brust
        if name.contains("bankdrücken") || name.contains("bench press") ||
            name.contains("fliegende") || name.contains("fly") ||
            name.contains("dips") {
            return .chest
        }

            // Rücken
        if name.contains("klimmzug") || name.contains("pull") ||
            name.contains("rudern") || name.contains("row") ||
            name.contains("latzug") || name.contains("lat pulldown") ||
            name.contains("kreuzheben") || name.contains("deadlift") {
            return .back
        }

            // Schultern
        if name.contains("schulter") || name.contains("shoulder") ||
            name.contains("military press") || name.contains("overhead") ||
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

        /// Sekundäre Muskelgruppen für eine Übung
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
