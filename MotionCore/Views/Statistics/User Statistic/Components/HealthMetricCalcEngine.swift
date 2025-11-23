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

    // Die statischen Benutzerdaten kommen von hier (Singleton)
    @ObservedObject private var appSettings = AppSettings.shared

    // Die dynamischen Daten (Workouts) kommen als Input in den Initializer
    let allWorkouts: [WorkoutSession] // Angenommen, das ist eine SwiftData/Model-Collection

    // MARK: - Initializer
    init(workouts: [WorkoutSession]) {
        self.allWorkouts = workouts
    }

    // MARK: Statische Daten direkt aus AppSettings

    // Geburtsdatum des Benutzers
    var userBirthday: Date {
        return appSettings.userBirthdayDate
    }

    // Alter des Benutzers
    var userAge: Int {
        return appSettings.userAge
    }

    // Geschlecht des Benutzers
    var userGender: Gender {
        return appSettings.userGender
    }

    var userBodyHeight: Int {
        return appSettings.userBodyHeight
    }

        // Berechnung: Letztes erfasstes Körpergewicht
    var userBodyWeight: Double? {
        return allWorkouts.sorted(by: { $0.date > $1.date })
            .filter { $0.bodyWeight > 0.0 }
            .sorted(by: { $0.date > $1.date })
            .first?.bodyWeight
    }

        /// Berechnung: Body-Mass-Index (BMI)
    var userBodyMassIndex: Double? {
            // 1. Gewicht in Kilogramm (muss existieren)
        guard let userWeight = userBodyWeight else {
            return nil // Kein Gewicht gefunden
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

        // 1. Vorabprüfung der notwendigen Daten
        guard let userWeight = userBodyWeight, userWeight > 0.0,
              userBodyHeight > 0,
              userAge > 0
        else {
                // Rückgabe von nil, falls notwendige Eingaben fehlen
            return nil
        }
        // Mifflin St. Jeor Formel:
        // BMR = (10 * Gewicht [kg]) + (6.25 * Größe [cm]) - (5 * Alter [Jahre]) + Gender-Faktor
        let weightTerm = 10.0 * userWeight
        let heightTerm = 6.25 * Double(userBodyHeight) // cm zu Double
        let ageTerm = 5.0 * Double(userAge) // Alter zu Double

        var bmr = weightTerm + heightTerm - ageTerm

        // 2. Addition des Gender-Faktors
        switch userGender {
            case .male:
                bmr += 5.0 // Männer: +5
            case .female:
                bmr -= 161.0 // Frauen: -161
            case .other:
                    // Für den Fall "Divers" wird standardmäßig der männliche Wert (+5)
                    // oder der Durchschnitt (0) verwendet. Wir wählen hier +5.
                bmr += 5.0
        }
            // 3. Rundung und Rückgabe
            // Der Grundumsatz wird üblicherweise auf ganze Kalorien gerundet
        return bmr.rounded()
    }
}

