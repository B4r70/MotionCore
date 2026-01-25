//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Zusammenfassung                                                  /
// Datei . . . . : SummaryCalcEngine.swift                                          /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 07.01.2026                                                       /
// Beschreibung  : Berechnungen für die kombinierte Übersicht aller Workout-Typen   /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
// Hinweis  . . : Diese Engine kombiniert CardioSession, StrengthSession und        /
//                OutdoorSession mithilfe des CoreSession-Protokolls.               /
//                Ermöglicht aggregierte Statistiken über alle Trainingsarten.      /
// ---------------------------------------------------------------------------------/
//
import Foundation

// MARK: - Summary Calculation Engine

// Kombiniert alle Session-Typen für aggregierte Statistiken.
// Nutzt das CoreSession-Protokoll für typ-übergreifende Berechnungen.
struct SummaryCalcEngine {

    // MARK: - Input (typisierte Arrays)

    let cardioSessions: [CardioSession]
    let strengthSessions: [StrengthSession]
    let outdoorSessions: [OutdoorSession]

    // MARK: - Individuelle CoreSessionCalcEngines

    // CalcEngine für Cardio-Sessions
    var cardioCalc: CoreSessionCalcEngine<CardioSession> {
        CoreSessionCalcEngine(sessions: cardioSessions)
    }

    // CalcEngine für Strength-Sessions
    var strengthCalc: CoreSessionCalcEngine<StrengthSession> {
        CoreSessionCalcEngine(sessions: strengthSessions)
    }

    // CalcEngine für Outdoor-Sessions
    var outdoorCalc: CoreSessionCalcEngine<OutdoorSession> {
        CoreSessionCalcEngine(sessions: outdoorSessions)
    }

    // MARK: - Initializer

    init(
        cardio: [CardioSession],
        strength: [StrengthSession],
        outdoor: [OutdoorSession]
    ) {
        self.cardioSessions = cardio
        self.strengthSessions = strength
        self.outdoorSessions = outdoor
    }

    // MARK: - Kombinierte Basis-Statistiken

    // Gesamtanzahl aller Workouts (alle Typen)
    var totalWorkouts: Int {
        cardioCalc.totalSessions + strengthCalc.totalSessions + outdoorCalc.totalSessions
    }

    // Gesamtkalorien aller Workouts
    var totalCalories: Int {
        cardioCalc.totalCalories + strengthCalc.totalCalories + outdoorCalc.totalCalories
    }

    // Gesamte Trainingsdauer in Minuten
    var totalDuration: Int {
        cardioCalc.totalDuration + strengthCalc.totalDuration + outdoorCalc.totalDuration
    }

    // Formatierte Gesamtdauer
    var formattedTotalDuration: String {
        if totalDuration < 60 {
            return "\(totalDuration) Min"
        } else {
            let hours = totalDuration / 60
            let minutes = totalDuration % 60
            if minutes == 0 {
                return "\(hours) Std"
            } else {
                return "\(hours):\(String(format: "%02d", minutes)) Std"
            }
        }
    }

    // MARK: - Durchschnittswerte (gewichtet nach Anzahl)

    // Durchschnittliche Herzfrequenz über alle Typen (gewichtet)
    var averageHeartRate: Int {
        let cardioHR = cardioCalc.averageHeartRate
        let strengthHR = strengthCalc.averageHeartRate
        let outdoorHR = outdoorCalc.averageHeartRate

        let cardioCount = cardioSessions.filter { $0.heartRate > 0 }.count
        let strengthCount = strengthSessions.filter { $0.heartRate > 0 }.count
        let outdoorCount = outdoorSessions.filter { $0.heartRate > 0 }.count

        let totalCount = cardioCount + strengthCount + outdoorCount
        guard totalCount > 0 else { return 0 }

        let weightedSum = (cardioHR * cardioCount) + (strengthHR * strengthCount) + (outdoorHR * outdoorCount)
        return weightedSum / totalCount
    }

    // Durchschnittliche Trainingsdauer
    var averageDuration: Int {
        guard totalWorkouts > 0 else { return 0 }
        return totalDuration / totalWorkouts
    }

    // Durchschnittlicher Kalorienverbrauch pro Workout
    var averageCalories: Int {
        guard totalWorkouts > 0 else { return 0 }
        return totalCalories / totalWorkouts
    }

    // MARK: - Verteilung nach Workout-Typ

    // Zusammenfassung pro Workout-Typ
    struct WorkoutTypeSummary: Identifiable {
        let id = UUID()
        let workoutType: WorkoutType
        let count: Int
        let calories: Int
        let duration: Int
        let percentage: Double
    }

    // Verteilung der Workouts nach Typ
    var workoutTypeDistribution: [WorkoutTypeSummary] {
        let total = totalWorkouts
        guard total > 0 else { return [] }

        return [
            WorkoutTypeSummary(
                workoutType: .cardio,
                count: cardioCalc.totalSessions,
                calories: cardioCalc.totalCalories,
                duration: cardioCalc.totalDuration,
                percentage: Double(cardioCalc.totalSessions) / Double(total) * 100
            ),
            WorkoutTypeSummary(
                workoutType: .strength,
                count: strengthCalc.totalSessions,
                calories: strengthCalc.totalCalories,
                duration: strengthCalc.totalDuration,
                percentage: Double(strengthCalc.totalSessions) / Double(total) * 100
            ),
            WorkoutTypeSummary(
                workoutType: .outdoor,
                count: outdoorCalc.totalSessions,
                calories: outdoorCalc.totalCalories,
                duration: outdoorCalc.totalDuration,
                percentage: Double(outdoorCalc.totalSessions) / Double(total) * 100
            )
        ].filter { $0.count > 0 }
    }

    // Daten für Donut-Chart (Workout-Verteilung)
    var workoutTypeChartData: [DonutChartData] {
        workoutTypeDistribution.map { summary in
            DonutChartData(
                label: summary.workoutType.description,
                value: summary.count
            )
        }
    }

    // MARK: - Zeitbasierte Statistiken

    // Dashboard für diese Woche
    var thisWeek: SummaryCalcEngine {
        SummaryCalcEngine(
            cardio: cardioCalc.sessionsThisWeek,
            strength: strengthCalc.sessionsThisWeek,
            outdoor: outdoorCalc.sessionsThisWeek
        )
    }

    // Dashboard für diesen Monat
    var thisMonth: SummaryCalcEngine {
        SummaryCalcEngine(
            cardio: cardioCalc.sessionsThisMonth,
            strength: strengthCalc.sessionsThisMonth,
            outdoor: outdoorCalc.sessionsThisMonth
        )
    }

    // Dashboard für dieses Jahr
    var thisYear: SummaryCalcEngine {
        SummaryCalcEngine(
            cardio: cardioCalc.sessionsThisYear,
            strength: strengthCalc.sessionsThisYear,
            outdoor: outdoorCalc.sessionsThisYear
        )
    }

    // Dashboard für die letzten N Tage
    func lastDays(_ days: Int) -> SummaryCalcEngine {
        SummaryCalcEngine(
            cardio: cardioCalc.sessions(lastDays: days),
            strength: strengthCalc.sessions(lastDays: days),
            outdoor: outdoorCalc.sessions(lastDays: days)
        )
    }

    // MARK: - Rekorde (typ-übergreifend)

    // Höchster Kalorienverbrauch (alle Typen)
    var highestCaloriesBurn: (session: any CoreSession, type: WorkoutType)? {
        let candidates: [(any CoreSession, WorkoutType)] = [
            cardioCalc.highestCaloriesSession.map { ($0, WorkoutType.cardio) },
            strengthCalc.highestCaloriesSession.map { ($0, WorkoutType.strength) },
            outdoorCalc.highestCaloriesSession.map { ($0, WorkoutType.outdoor) }
        ].compactMap { $0 }

        return candidates.max { $0.0.calories < $1.0.calories }
    }

    // Längstes Workout (alle Typen)
    var longestWorkout: (session: any CoreSession, type: WorkoutType)? {
        let candidates: [(any CoreSession, WorkoutType)] = [
            cardioCalc.longestDurationSession.map { ($0, WorkoutType.cardio) },
            strengthCalc.longestDurationSession.map { ($0, WorkoutType.strength) },
            outdoorCalc.longestDurationSession.map { ($0, WorkoutType.outdoor) }
        ].compactMap { $0 }

        return candidates.max { $0.0.duration < $1.0.duration }
    }

    // MARK: - Streak-Berechnung

    // Alle Trainingstage als sortiertes Set (neueste zuerst)
    private var allTrainingDays: [Date] {
        let calendar = Calendar.current
        let allDates = (
            cardioSessions.map { $0.date } +
            strengthSessions.map { $0.date } +
            outdoorSessions.map { $0.date }
        )

        // Einzigartige Tage extrahieren und sortieren (neueste zuerst)
        return Set(allDates.map { calendar.startOfDay(for: $0) })
            .sorted(by: >)
    }

    // Aktuelle Trainings-Streak (aufeinanderfolgende Tage mit Training)
    // Zählt auch wenn das letzte Training gestern war (Streak noch aktiv)
    var currentStreak: Int {
        let uniqueDays = allTrainingDays

        guard !uniqueDays.isEmpty else {
            return 0
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        // Prüfen ob das letzte Training heute oder gestern war
        // Wenn nicht, ist die Streak unterbrochen
        guard let lastTrainingDay = uniqueDays.first,
              lastTrainingDay == today || lastTrainingDay == yesterday else {
            return 0
        }

        // Streak zählen, beginnend vom letzten Trainingstag
        var streak = 0
        var expectedDate = lastTrainingDay

        for day in uniqueDays {
            if day == expectedDate {
                streak += 1
                expectedDate = calendar.date(byAdding: .day, value: -1, to: expectedDate)!
            } else if day < expectedDate {
                // Lücke gefunden - Streak beenden
                break
            }
        }

        return streak
    }

    // Längste Trainings-Streak aller Zeiten
    var longestStreak: Int {
        let uniqueDays = allTrainingDays.sorted() // Älteste zuerst für diese Berechnung
        guard !uniqueDays.isEmpty else { return 0 }

        let calendar = Calendar.current
        var maxStreak = 1
        var currentStreakCount = 1

        for i in 1..<uniqueDays.count {
            let daysBetween = calendar.dateComponents([.day], from: uniqueDays[i-1], to: uniqueDays[i]).day ?? 0

            if daysBetween == 1 {
                currentStreakCount += 1
                maxStreak = max(maxStreak, currentStreakCount)
            } else {
                currentStreakCount = 1
            }
        }

        return maxStreak
    }

    // MARK: - Trainingsfrequenz

    // Durchschnittliche Workouts pro Woche (letzte 4 Wochen)
    var averageWorkoutsPerWeek: Double {
        let last28Days = lastDays(28)
        return Double(last28Days.totalWorkouts) / 4.0
    }

    // Workouts diese Woche
    var workoutsThisWeek: Int {
        thisWeek.totalWorkouts
    }

    // MARK: - Letzte Aktivität

    // Datum des letzten Workouts
    var lastWorkoutDate: Date? {
        allTrainingDays.first
    }

    // Tage seit dem letzten Workout
    var daysSinceLastWorkout: Int? {
        guard let lastDate = lastWorkoutDate else { return nil }
        return Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day
    }
}
