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
