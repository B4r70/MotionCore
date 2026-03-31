//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Datenmodell                                                      /
// Datei . . . . : ExerciseMetrics.swift                                            /
// Erstellt am . : 31.03.2026                                                       /
// Beschreibung  : SwiftData-Model für pro-Übung Health-Metriken                    /
//                 (HR, Kalorien, Dauer) — gespeichert bei Exercise-Transition      /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation
import SwiftData

@Model
final class ExerciseMetrics {
    var exerciseGroupKey: String = ""
    var exerciseNameSnapshot: String = ""
    var avgHeartRate: Double = 0
    var minHeartRate: Double = 0
    var maxHeartRate: Double = 0
    var activeCalories: Double = 0
    var durationSeconds: Int = 0

    @Relationship(deleteRule: .nullify)
    var session: StrengthSession?

    init(
        exerciseGroupKey: String = "",
        exerciseNameSnapshot: String = "",
        avgHeartRate: Double = 0,
        minHeartRate: Double = 0,
        maxHeartRate: Double = 0,
        activeCalories: Double = 0,
        durationSeconds: Int = 0
    ) {
        self.exerciseGroupKey = exerciseGroupKey
        self.exerciseNameSnapshot = exerciseNameSnapshot
        self.avgHeartRate = avgHeartRate
        self.minHeartRate = minHeartRate
        self.maxHeartRate = maxHeartRate
        self.activeCalories = activeCalories
        self.durationSeconds = durationSeconds
    }
}
