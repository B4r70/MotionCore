//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Rekorde                                                          /
// Datei . . . . : RecordCalcEngine.swift                                           /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 17.11.2025                                                       /
// Beschreibung  : Zentrale Berechnungen für die Rekordanzeige                      /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
// Hinweis  . . : Gemeinsame Berechnungen (bodyWeight, calories, duration) werden   /
//                an CoreSessionCalcEngine delegiert. Cardio-spezifische Rekorde    /
//                (distance, cardioDevice, averageSpeed) bleiben hier.              /
// ---------------------------------------------------------------------------------/
//
import Foundation
import SwiftData

struct RecordCalcEngine {

    // MARK: - Input

    // Alle Workouts, die als Datenquelle für die Rekorde verwendet werden.
    let allWorkouts: [CardioSession]

    // MARK: - NEU: CoreSessionCalcEngine für gemeinsame Berechnungen

    // Delegiert gemeinsame Berechnungen an die generische CoreSessionCalcEngine.
    private var coreCalc: CoreSessionCalcEngine<CardioSession> {
        CoreSessionCalcEngine(sessions: allWorkouts)
    }

    // MARK: - Initializer

    init(workouts: [CardioSession]) {
        self.allWorkouts = workouts
    }

    // MARK: - Gerätespezifische Rekorde (Cardio-spezifisch)

    // Bestes Ergometer Workout mit der längsten Distanz
    // BLEIBT: Cardio-spezifisch (cardioDevice, distance sind nicht in CoreSession)
    var bestErgometerWorkout: CardioSession? {
        allWorkouts
            .filter { $0.cardioDevice == .ergometer }
            .max(by: { $0.distance < $1.distance })
    }

    // Bestes Crosstrainer Workout mit der längsten Distanz
    // BLEIBT: Cardio-spezifisch (cardioDevice, distance sind nicht in CoreSession)
    var bestCrosstrainerWorkout: CardioSession? {
        allWorkouts
            .filter { $0.cardioDevice == .crosstrainer }
            .max(by: { $0.distance < $1.distance })
    }

    // Bestes Workout mit der höchsten Durchschnittsgeschwindigkeit (gerätespezifisch)
    // BLEIBT: Cardio-spezifisch (cardioDevice, averageSpeed sind nicht in CoreSession)
    func fastestCardioDevice(for device: CardioDevice) -> CardioSession? {
        allWorkouts
            .filter { $0.cardioDevice == device }
            .filter { $0.averageSpeed > 0.0 }
            .max(by: { $0.averageSpeed < $1.averageSpeed })
    }

    // MARK: - Geräteübergreifende Rekorde (NEU: Delegiert an CoreSessionCalcEngine)

    // Niedrigstes Körpergewicht
    // NEU: Delegiert an coreCalc.lowestBodyWeightSession
    var lowestBodyWeight: CardioSession? {
        coreCalc.lowestBodyWeightSession
    }

    // Höchstes Körpergewicht
    // NEU: Delegiert an coreCalc.highestBodyWeightSession
    var highestBodyWeight: CardioSession? {
        coreCalc.highestBodyWeightSession
    }

    // Höchster Kalorienverbrauch im Workout
    // NEU: Delegiert an coreCalc.highestCaloriesSession
    var highestBurnedCaloriesWorkout: CardioSession? {
        coreCalc.highestCaloriesSession
    }

    // Bestes Workout mit der längsten Distanz (geräteübergreifend)
    // BLEIBT: Cardio-spezifisch (distance ist nicht in CoreSession)
    var longestDistanceWorkout: CardioSession? {
        allWorkouts
            .max(by: { $0.distance < $1.distance })
    }

    // Bestes Workout mit der längsten Dauer (geräteübergreifend)
    // NEU: Delegiert an coreCalc.longestDurationSession
    var longestDurationWorkout: CardioSession? {
        coreCalc.longestDurationSession
    }

    // MARK: - NEU: Zusätzliche Rekorde aus CoreSessionCalcEngine

    // Session mit der höchsten maximalen Herzfrequenz
    var highestMaxHeartRateWorkout: CardioSession? {
        coreCalc.highestHeartRateSession
    }

    // Session mit der höchsten durchschnittlichen Herzfrequenz
    var highestAverageHeartRateWorkout: CardioSession? {
        coreCalc.highestAverageHeartRateSession
    }

    // MARK: - NEU: Convenience für zeitbasierte Rekorde

    // Rekorde dieser Woche
    var thisWeekRecords: RecordCalcEngine {
        RecordCalcEngine(workouts: coreCalc.sessionsThisWeek)
    }

    // Rekorde dieses Monats
    var thisMonthRecords: RecordCalcEngine {
        RecordCalcEngine(workouts: coreCalc.sessionsThisMonth)
    }

    // Rekorde dieses Jahres
    var thisYearRecords: RecordCalcEngine {
        RecordCalcEngine(workouts: coreCalc.sessionsThisYear)
    }

    // Rekorde der letzten N Tage
    func recordsLastDays(_ days: Int) -> RecordCalcEngine {
        RecordCalcEngine(workouts: coreCalc.sessions(lastDays: days))
    }
}
