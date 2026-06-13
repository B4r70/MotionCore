//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : HealthKit                                                        /
// Datei . . . . : HealthBaselineUpdateService.swift                                /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 24.04.2026                                                       /
// Beschreibung  : Aktualisiert HealthBaseline-Einträge täglich (Phase 2)           /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation
import SwiftData

@MainActor
final class HealthBaselineUpdateService {

    private let healthKit: HealthKitManager
    private let context: ModelContext

    init(healthKit: HealthKitManager, context: ModelContext) {
        self.healthKit = healthKit
        self.context = context
    }

    /// Aktualisiert alle Baselines — überspringt wenn letztes Update heute war.
    func updateIfNeeded(takesCardioMedication: Bool) async {
        let baselines = (try? context.fetch(FetchDescriptor<HealthBaseline>())) ?? []
        // Wenn alle 4 Metriken heute schon aktualisiert wurden → skip
        let allUpToDate = HealthMetricType.allCases.allSatisfy { type in
            baselines.first(where: { $0.metricType == type }).map {
                Calendar.current.isDateInToday($0.lastUpdated)
            } ?? false
        }
        guard !allUpToDate else { return }
        await performUpdate(takesCardioMedication: takesCardioMedication)
    }

    /// Erzwingt Aktualisierung (für Debug / manuellen Trigger).
    func forceUpdate(takesCardioMedication: Bool) async {
        await performUpdate(takesCardioMedication: takesCardioMedication)
    }

    // MARK: - Privat

    private func performUpdate(takesCardioMedication: Bool) async {
        _ = await healthKit.requestAuthorization()
        let windowDays = takesCardioMedication ? 42 : 28

        // HRV und RHR: Tagesmittel 00:00–10:00 Ortszeit — identische Fenster-Logik wie Messwert
        await updateWindowedMetric(.hrv, windowDays: windowDays) { date in
            try await self.healthKit.windowedHRV(forDate: date)
        }
        await updateWindowedMetric(.restingHR, windowDays: windowDays) { date in
            try await self.healthKit.windowedRestingHR(forDate: date)
        }
        await updateMetric(.activity) {
            // Aktive Energie: Tagessummen über windowDays aufsammeln
            var result: [Date: Double] = [:]
            let cal = Calendar.current
            for offset in 1...windowDays {
                guard let day = cal.date(byAdding: .day, value: -offset, to: cal.startOfDay(for: Date())) else { continue }
                if let kcal = try? await self.healthKit.activeEnergy(forDate: day) {
                    result[day] = kcal
                }
            }
            return result
        }
        await updateSleepMetric(windowDays: windowDays)

        try? context.save()
    }

    private func updateMetric(_ type: HealthMetricType, fetch: () async throws -> [Date: Double]) async {
        guard let values = try? await fetch(), !values.isEmpty else { return }
        let arr = Array(values.values)
        let (mean, stdDev) = statistics(arr)
        guard mean.isFinite, stdDev.isFinite else { return }
        let baseline = fetchOrCreate(type)
        baseline.rollingMean = mean
        baseline.rollingStdDev = stdDev
        baseline.sampleCount = arr.count
        baseline.lastUpdated = Date()
    }

    /// Berechnet Baseline aus tagesweise gefensterten Werten (ein Wert pro Tag über windowDays Tage).
    /// Stellt sicher dass Messwert-Fenster und Baseline-Fenster identisch sind.
    private func updateWindowedMetric(
        _ type: HealthMetricType,
        windowDays: Int,
        fetchDay: (Date) async throws -> Double?
    ) async {
        let cal = Calendar.current
        var values: [Double] = []
        for offset in 1...windowDays {
            guard let day = cal.date(byAdding: .day, value: -offset, to: cal.startOfDay(for: Date())) else { continue }
            if let value = try? await fetchDay(day) {
                values.append(value)
            }
        }
        guard !values.isEmpty else { return }
        let (mean, stdDev) = statistics(values)
        guard mean.isFinite, stdDev.isFinite else { return }
        let baseline = fetchOrCreate(type)
        baseline.rollingMean = mean
        baseline.rollingStdDev = stdDev
        baseline.sampleCount = values.count
        baseline.lastUpdated = Date()
    }

    private func updateSleepMetric(windowDays: Int) async {
        var durations: [Double] = []
        let cal = Calendar.current
        for offset in 1...windowDays {
            guard let day = cal.date(byAdding: .day, value: -offset, to: Date()) else { continue }
            if let hours = try? await healthKit.sleepDuration(forNightEnding: day) {
                durations.append(hours)
            }
        }
        guard !durations.isEmpty else { return }
        let (mean, stdDev) = statistics(durations)
        guard mean.isFinite, stdDev.isFinite else { return }
        let baseline = fetchOrCreate(.sleep)
        baseline.rollingMean = mean
        baseline.rollingStdDev = stdDev
        baseline.sampleCount = durations.count
        baseline.lastUpdated = Date()
    }

    private func fetchOrCreate(_ type: HealthMetricType) -> HealthBaseline {
        let raw = type.rawValue
        if let existing = (try? context.fetch(FetchDescriptor<HealthBaseline>()))?.first(where: { $0.metricTypeRaw == raw }) {
            return existing
        }
        let baseline = HealthBaseline(metricType: type)
        context.insert(baseline)
        return baseline
    }

    private func statistics(_ values: [Double]) -> (mean: Double, stdDev: Double) {
        guard !values.isEmpty else { return (0, 0) }
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        return (mean, sqrt(variance))
    }
}
