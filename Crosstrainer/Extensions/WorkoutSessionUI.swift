//---------------------------------------------------------------------------------/
//  # CrossStats                                                                   /
//---------------------------------------------------------------------------------/
// Filename . . : WorkoutSessionUI.swift                                           /
// Author . . . : Bartosz Stryjewski                                               /
// Created on . : 22.10.2025                                                       /
// Function . . : Formatierte Werte für die Ausgabe aus @Model WorkoutSession      /
//---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                             /
//---------------------------------------------------------------------------------/
//
import Foundation

extension WorkoutSession {
    // MARK: - Formatierte Werte für UI aus @Model WorkoutSession

    var distanceFormatted: String {
        String(format: "%.2f km", distance)
    }

    var durationFormatted: String {
        "\(duration) min"
    }

    var caloriesFormatted: String {
        "\(calories) kcal"
    }

    var heartRateFormatted: String {
        "\(heartRate) bpm"
    }

    var bodyWeightFormatted: String {
        "\(bodyWeight) kg"
    }

    var metsFormatted: String {
        String(format: "%.1f METs", mets)
    }

    var averageSpeedFormatted: String {
        String(format: "%.0f m/min", averageSpeed)
    }

    // MARK: - Kompakte Zusammenfassung für UI-Elemente
    var summaryLine: String {
        "\(distanceFormatted) • \(durationFormatted) • \(caloriesFormatted)"
    }

    var extendedSummaryLine: String {
        "\(summaryLine) • \(averageSpeedFormatted) • \(metsFormatted)"
    }
}
