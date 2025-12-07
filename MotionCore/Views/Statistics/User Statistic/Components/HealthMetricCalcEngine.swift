//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Gesundheitsdaten                                                 /
// Datei . . . . : HealthMetricsCalcEngine.swift                                    /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 17.11.2025                                                       /
// Beschreibung  : Zentrale Berechnungen benutzerspezifische Gesundheitsdaten       /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation
import Combine
import SwiftUI

class HealthMetricCalcEngine: ObservableObject {

    // Die dynamischen Daten (Workouts) kommen als Input in den Initializer
    let allWorkouts: [WorkoutSession]

    // Statische Werte direkt speichern (nicht @EnvironmentObject!)
    private let userBirthdayDate: Date
    private let userAge: Int
    private let userGender: Gender
    private let userBodyHeight: Int
    private let userActivityLevel: UserActivityLevel

    // MARK: - Initializer
    init(workouts: [WorkoutSession], settings: AppSettings) {
        self.allWorkouts = workouts
            // Werte beim Init kopieren
        self.userBirthdayDate = settings.userBirthdayDate
        self.userAge = settings.userAge
        self.userGender = settings.userGender
        self.userBodyHeight = settings.userBodyHeight
        self.userActivityLevel = settings.userActivityLevel
    }

    // MARK: Statische Daten direkt aus gespeicherten Werten

    // Geburtsdatum des Benutzers
    var userBirthday: Date {
        return userBirthdayDate
    }

    // Berechnung: Letztes erfasstes Körpergewicht in kg
    var userBodyWeight: Double? {
        return allWorkouts
            .filter { $0.bodyWeight > 0.0 }
            .sorted(by: { $0.date > $1.date })
            .first?.bodyWeight
    }

    // Berechnung: Body-Mass-Index (BMI)
    var userBodyMassIndex: Double? {
        guard let userWeight = userBodyWeight else {
            return nil
        }
        let userHeightInMeters = Double(userBodyHeight) / 100.0
        guard userHeightInMeters > 0.0 else {
            return nil
        }
        let userBMI = userWeight / (userHeightInMeters * userHeightInMeters)
        let userBMIRounded = (userBMI * 100).rounded() / 100

        return userBMIRounded
    }

    // Berechnung: Kalorien Grundumsatz nach Mifflin St. Jeor
    var userCalorieMetabolicRate: Double? {
        guard let userWeight = userBodyWeight, userWeight > 0.0,
              userBodyHeight > 0,
              userAge > 0
        else {
            return nil
        }

        let weightTerm = 10.0 * userWeight
        let heightTerm = 6.25 * Double(userBodyHeight)
        let ageTerm = 5.0 * Double(userAge)

        var bmr = weightTerm + heightTerm - ageTerm

        switch userGender {
            case .male:
                bmr += 5.0
            case .female:
                bmr -= 161.0
            case .other:
                bmr += 5.0
        }

        return bmr.rounded()
    }

    // Berechnung des TDEE
    var userTotalDailyEnergyExpenditure: Double? {
        guard let bmr = userCalorieMetabolicRate else { return nil }
        return bmr * userActivityLevel.rawValue
    }

    // Berechnung: Kalorienbilanz aus HealthKit
    func calculateTodayCalorieBalance(from healthKit: HealthKitManager) -> CalorieBalance? {
        // NEU: Guard-Statement prüft alle notwendigen HealthKit-Werte
        guard let consumed = healthKit.dietaryConsumedCalories,
              let basal = healthKit.basalBurnedCalories,
              let active = healthKit.activeBurnedCalories else {
            return nil
        }

        // NEU: Berechnungen durchführen
        let totalBurned = basal + active
        let balance = totalBurned - consumed
        let isDeficit = balance > 0

        let percentage: Double
        if totalBurned > 0 {
            percentage = min(Double(consumed) / Double(totalBurned), 1.0)
        } else {
            percentage = 0.0
        }

        // NEU: Jetzt mit allen berechneten Werten
        return CalorieBalance(
            consumedCalories: consumed,
            basalEnergy: basal,
            activeEnergy: active,
            totalBurned: totalBurned,
            balance: balance,
            isDeficit: isDeficit,
            consumedPercentage: percentage
        )
    }
}

// MARK: Berechnung der Kalorienbilanz
// Anhand der aufgenommenen und verbrannten Kalorien wird ein Defizit berechnet
struct CalorieBalance {
    let consumedCalories: Int
    let basalEnergy: Int
    let activeEnergy: Int
    let totalBurned: Int
    let balance: Int
    let isDeficit: Bool
    let consumedPercentage: Double

    // Formatiert die Bilanz als String mit Vorzeichen
    var balanceFormatted: String {
        let sign = isDeficit ? "+" : ""
        return "\(sign)\(abs(balance)) kcal"
    }

    // Gibt den Status als Text zurück
    var statusText: String {
        isDeficit ? "Kaloriendefizit" : "Kalorienüberschuss"
    }

    // Farbe für die Bilanz-Anzeige
    var statusColor: Color {
        isDeficit ? .green : .red
    }
}
