//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : ViewModels                                                       /
// Datei . . . . : StatisticsViewModel.swift                                        /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-03-18                                                       /
// Beschreibung  : Gecachte Statistik-Daten — berechnet bei Daten- oder Timeframe- /
//                 Änderung, cached alle KPIs und Chart-Daten.                      /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation
import Observation

@Observable
final class StatisticsViewModel {

    // MARK: - Gecachte KPIs (timeframe-gefiltert)

    private(set) var totalWorkoutsAll: Int = 0
    private(set) var totalCaloriesAll: Int = 0
    private(set) var totalStrengthVolume: Double = 0
    private(set) var averageHeartRateAll: Int = 0
    private(set) var totalStrengthSets: Int = 0
    private(set) var averageStrengthVolumePerSession: Double = 0
    private(set) var averageDurationAll: Int = 0
    private(set) var averageMETS: Double = 0
    private(set) var totalDistanceAll: Double = 0

    // MARK: - Gecachte Chart-Daten (timeframe-gefiltert)

    private(set) var trendHeartRate: [TrendPoint] = []
    private(set) var trendCalories: [TrendPoint] = []
    private(set) var strengthVolumeTrend: [TrendPoint] = []

    // MARK: - Gecachte Cardio-KPIs (timeframe-gefiltert)

    private(set) var averageIntensity: Double = 0
    private(set) var averageCaloricDensity: Double = 0
    private(set) var allCardioSessions: [CardioSession] = []

    // MARK: - Gecachte Kraft-Chart-Engine (timeframe-gefiltert)
    // Wird direkt an StrengthOneRMChart übergeben — interaktive Übungs-Auswahl benötigt die Engine.

    private(set) var strengthChartCalc: StrengthStatisticCalcEngine = StrengthStatisticCalcEngine(sessions: [])
    private(set) var allStrengthSessions: [StrengthSession] = []

    // MARK: - Leerprüfungen

    private(set) var allSessionsEmpty: Bool = true

    // MARK: - Neuberechnung

    /// Berechnet alle gecachten Werte für den gewählten Zeitraum neu.
    /// Aufrufen bei Änderung der Session-Arrays oder des Timeframes.
    func recalculate(
        cardio: [CardioSession],
        strength: [StrengthSession],
        outdoor: [OutdoorSession],
        timeframe: SummaryTimeframe
    ) {
        self.allSessionsEmpty = cardio.isEmpty && strength.isEmpty && outdoor.isEmpty

        // Gefilterte Engine einmal erstellen
        let calc = StatisticCalcEngine(
            cardioSessions: cardio,
            strengthSessions: strength,
            outdoorSessions: outdoor
        ).filtered(by: timeframe)

        // KPIs cachen
        self.totalWorkoutsAll = calc.totalWorkoutsAll
        self.totalCaloriesAll = calc.totalCaloriesAll
        self.totalStrengthVolume = calc.totalStrengthVolume
        self.averageHeartRateAll = calc.averageHeartRateAll
        self.totalStrengthSets = calc.totalStrengthSets
        self.averageStrengthVolumePerSession = calc.averageStrengthVolumePerSession
        self.averageDurationAll = calc.averageDurationAll
        self.averageMETS = calc.averageMETS
        self.totalDistanceAll = calc.totalDistanceAll

        // Chart-Daten cachen
        self.trendHeartRate = calc.trendHeartRate
        self.trendCalories = calc.trendCalories
        self.allCardioSessions = calc.allCardioSessions
        self.allStrengthSessions = calc.allStrengthSessions

        // Cardio-KPIs cachen
        self.averageIntensity = calc.averageIntensity
        self.averageCaloricDensity = calc.averageCaloricDensity

        // StrengthChart-Engine für interaktiven 1RM-Chart (Übung wird vom User gewählt)
        let chartCalc = StrengthStatisticCalcEngine(sessions: calc.allStrengthSessions)
        self.strengthVolumeTrend = chartCalc.volumeTrend
        self.strengthChartCalc = chartCalc
    }
}
