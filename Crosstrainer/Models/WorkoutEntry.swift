//
//  WorkoutEntry.swift
//  Crosstrainer
//
//  Created by Barto on 21.10.25.
//
import Foundation
import SwiftData

@Model
final class WorkoutEntry {
    var date: Date
    var duration: Int // Minuten
    var distance: Double // Kilometer
    var calories: Int // kcal
    var intensity: Int // 0-5
    
    init(date: Date = Date(), duration: Int, distance: Double, calories: Int, intensity: Int) {
        self.date = date
        self.duration = duration
        self.distance = distance
        self.calories = calories
        self.intensity = intensity
    }
}
