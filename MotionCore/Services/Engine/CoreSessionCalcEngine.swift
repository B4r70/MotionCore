//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Berechnung                                                       /
// Datei . . . . : CoreSessionCalcEngine.swift                                      /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 07.01.2026                                                       /
// Beschreibung  : Generische Berechnungen für alle CoreSession-Typen               /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
// Hinweis  . . : Diese Engine arbeitet mit dem CoreSession-Protokoll und kann      /
//                für CardioSession, StrengthSession und OutdoorSession verwendet   /
//                werden. Typ-spezifische Berechnungen bleiben in den jeweiligen    /
//                spezialisierten CalcEngines (StatisticCalcEngine, etc.)           /
// ---------------------------------------------------------------------------------/
//
import Foundation

// MARK: - Core Session Calculation Engine

/// Generische Berechnungslogik für alle Session-Typen, die CoreSession implementieren.
/// Nutzt Swift Generics für typsichere Berechnungen.
struct CoreSessionCalcEngine<T: CoreSession> {

    // MARK: - Input

    /// Alle Sessions als Datenquelle für die Berechnungen
    let sessions: [T]

    // MARK: - Initializer

    init(sessions: [T]) {
        self.sessions = sessions
    }

    // MARK: - Basis-Statistiken (Summen)

    /// Anzahl aller Sessions
    var totalSessions: Int {
        sessions.count
    }

    /// Summe aller verbrannten Kalorien
    var totalCalories: Int {
        sessions.reduce(0) { $0 + $1.calories }
    }

    /// Gesamte Trainingsdauer in Minuten
    var totalDuration: Int {
        sessions.reduce(0) { $0 + $1.duration }
    }

    /// Gesamte Trainingsdauer formatiert (z.B. "12:30 Std" oder "45 Min")
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

    // MARK: - Durchschnittswerte

    /// Durchschnittliche Herzfrequenz (nur Sessions mit gültigen Werten)
    var averageHeartRate: Int {
        let valid = sessions.filter { $0.heartRate > 0 }
        guard !valid.isEmpty else { return 0 }
        return valid.reduce(0) { $0 + $1.heartRate } / valid.count
    }

    /// Durchschnittliche maximale Herzfrequenz
    var averageMaxHeartRate: Int {
        let valid = sessions.filter { $0.maxHeartRate > 0 }
        guard !valid.isEmpty else { return 0 }
        return valid.reduce(0) { $0 + $1.maxHeartRate } / valid.count
    }

    /// Durchschnittliche Trainingsdauer in Minuten
    var averageDuration: Int {
        guard !sessions.isEmpty else { return 0 }
        let valid = sessions.filter { $0.duration > 0 }
        guard !valid.isEmpty else { return 0 }
        return valid.reduce(0) { $0 + $1.duration } / valid.count
    }

    /// Durchschnittlicher Kalorienverbrauch pro Session
    var averageCalories: Int {
        guard !sessions.isEmpty else { return 0 }
        let valid = sessions.filter { $0.calories > 0 }
        guard !valid.isEmpty else { return 0 }
        return valid.reduce(0) { $0 + $1.calories } / valid.count
    }

    /// Durchschnittliche Intensität (als Double für Stern-Ratings)
    var averageIntensity: Double {
        let valid = sessions.filter { $0.intensityRaw > 0 }
        guard !valid.isEmpty else { return 0.0 }
        let total = valid.reduce(0) { $0 + $1.intensityRaw }
        return Double(total) / Double(valid.count)
    }

    /// Durchschnittliches Körpergewicht
    var averageBodyWeight: Double {
        let valid = sessions.filter { $0.bodyWeight > 0 }
        guard !valid.isEmpty else { return 0.0 }
        return valid.reduce(0.0) { $0 + $1.bodyWeight } / Double(valid.count)
    }

    // MARK: - Rekorde (Extremwerte)

    /// Session mit dem niedrigsten Körpergewicht
    var lowestBodyWeightSession: T? {
        sessions
            .filter { $0.bodyWeight > 0 }
            .min { $0.bodyWeight < $1.bodyWeight }
    }

    /// Session mit dem höchsten Körpergewicht
    var highestBodyWeightSession: T? {
        sessions
            .filter { $0.bodyWeight > 0 }
            .max { $0.bodyWeight < $1.bodyWeight }
    }

    /// Session mit dem höchsten Kalorienverbrauch
    var highestCaloriesSession: T? {
        sessions.max { $0.calories < $1.calories }
    }

    /// Session mit der längsten Dauer
    var longestDurationSession: T? {
        sessions.max { $0.duration < $1.duration }
    }

    /// Session mit der höchsten Herzfrequenz
    var highestHeartRateSession: T? {
        sessions
            .filter { $0.maxHeartRate > 0 }
            .max { $0.maxHeartRate < $1.maxHeartRate }
    }

    /// Session mit der höchsten durchschnittlichen Herzfrequenz
    var highestAverageHeartRateSession: T? {
        sessions
            .filter { $0.heartRate > 0 }
            .max { $0.heartRate < $1.heartRate }
    }

    // MARK: - Zeitbasierte Filter (mit lokaler Zeitzone)

    /// Sessions der letzten N Tage
    func sessions(lastDays days: Int) -> [T] {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let cutoff = calendar.date(byAdding: .day, value: -days, to: startOfToday) ?? startOfToday
        return sessions.filter { $0.date >= cutoff }
    }

    /// Sessions dieser Woche (lokale Zeitzone)
    var sessionsThisWeek: [T] {
        let calendar = Calendar.current
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: Date()) else {
            return []
        }
        return sessions.filter { date in
            date.date >= weekInterval.start && date.date < weekInterval.end
        }
    }

    /// Sessions dieses Monats (lokale Zeitzone)
    var sessionsThisMonth: [T] {
        let calendar = Calendar.current
        let now = Date()

        guard let monthInterval = calendar.dateInterval(of: .month, for: now) else {
            print("❌ Kein Month-Interval")
            return []
        }

        print("📅 Now: \(now)")
        print("📅 Month Start: \(monthInterval.start)")
        print("📅 Month End: \(monthInterval.end)")
        print("📅 Calendar TimeZone: \(calendar.timeZone)")

        for session in sessions {
            let inRange = session.date >= monthInterval.start && session.date < monthInterval.end
            print("📅 Session: \(session.date) | inRange: \(inRange)")
        }

        return sessions.filter { session in
            session.date >= monthInterval.start && session.date < monthInterval.end
        }
    }

    /// Sessions dieses Jahres (lokale Zeitzone)
    var sessionsThisYear: [T] {
        let calendar = Calendar.current
        guard let yearInterval = calendar.dateInterval(of: .year, for: Date()) else {
            return []
        }
        return sessions.filter { session in
            session.date >= yearInterval.start && session.date < yearInterval.end
        }
    }

    // MARK: - Intensitäts-Analyse

    /// Anzahl Sessions pro Intensitätsstufe
    func sessionCount(for intensity: Intensity) -> Int {
        sessions.filter { $0.intensity == intensity }.count
    }

    /// Verteilung der Intensitäten als Dictionary
    var intensityDistribution: [Intensity: Int] {
        Dictionary(grouping: sessions) { $0.intensity }
            .mapValues { $0.count }
    }

    // MARK: - Trend-Daten für Charts

    /// Herzfrequenz-Trend über Zeit
    var heartRateTrend: [TrendPoint] {
        sessions
            .filter { $0.heartRate > 0 }
            .sorted { $0.date < $1.date }
            .map { TrendPoint(trendDate: $0.date, trendValue: Double($0.heartRate)) }
    }

    /// Kalorien-Trend über Zeit
    var caloriesTrend: [TrendPoint] {
        sessions
            .filter { $0.calories > 0 }
            .sorted { $0.date < $1.date }
            .map { TrendPoint(trendDate: $0.date, trendValue: Double($0.calories)) }
    }

    /// Körpergewicht-Trend über Zeit
    var bodyWeightTrend: [TrendPoint] {
        sessions
            .filter { $0.bodyWeight > 0 }
            .sorted { $0.date < $1.date }
            .map { TrendPoint(trendDate: $0.date, trendValue: $0.bodyWeight) }
    }

    /// Dauer-Trend über Zeit
    var durationTrend: [TrendPoint] {
        sessions
            .filter { $0.duration > 0 }
            .sorted { $0.date < $1.date }
            .map { TrendPoint(trendDate: $0.date, trendValue: Double($0.duration)) }
    }

    // MARK: - Geräte/Quellen-Analyse

    /// Sessions gruppiert nach Geräte-Quelle (iPhone, AppleWatch, manual)
    var sessionsByDeviceSource: [String: [T]] {
        Dictionary(grouping: sessions) { $0.deviceSource }
    }

    /// Anzahl Sessions pro Geräte-Quelle
    var deviceSourceCounts: [String: Int] {
        sessionsByDeviceSource.mapValues { $0.count }
    }

    // MARK: - Live vs. Manuell

    /// Anzahl der Live-Sessions
    var liveSessionCount: Int {
        sessions.filter { $0.isLiveSession }.count
    }

    /// Anzahl der manuell eingetragenen Sessions
    var manualSessionCount: Int {
        sessions.filter { !$0.isLiveSession }.count
    }

    /// Prozentsatz der Live-Sessions
    var liveSessionPercentage: Double {
        guard !sessions.isEmpty else { return 0 }
        return Double(liveSessionCount) / Double(sessions.count) * 100
    }

    // MARK: - HealthKit-Integration

    /// Sessions mit HealthKit-Verknüpfung
    var healthKitLinkedSessions: [T] {
        sessions.filter { $0.isLinkedToHealthKit }
    }

    /// Prozentsatz der HealthKit-verknüpften Sessions
    var healthKitLinkedPercentage: Double {
        guard !sessions.isEmpty else { return 0 }
        return Double(healthKitLinkedSessions.count) / Double(sessions.count) * 100
    }
}

// MARK: - Convenience Extensions

extension CoreSessionCalcEngine {

    /// Erstellt eine neue Engine mit gefilterten Sessions
    func filtered(_ predicate: (T) -> Bool) -> CoreSessionCalcEngine<T> {
        CoreSessionCalcEngine(sessions: sessions.filter(predicate))
    }

    /// Erstellt eine neue Engine mit Sessions der letzten N Tage
    func lastDays(_ days: Int) -> CoreSessionCalcEngine<T> {
        CoreSessionCalcEngine(sessions: sessions(lastDays: days))
    }

    /// Erstellt eine neue Engine mit Sessions dieser Woche
    var thisWeek: CoreSessionCalcEngine<T> {
        CoreSessionCalcEngine(sessions: sessionsThisWeek)
    }

    /// Erstellt eine neue Engine mit Sessions dieses Monats
    var thisMonth: CoreSessionCalcEngine<T> {
        CoreSessionCalcEngine(sessions: sessionsThisMonth)
    }
}
