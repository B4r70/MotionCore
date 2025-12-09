//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : HealthKit                                                        /
// Datei . . . . : HealthKitManager.swift                                           /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 29.11.2025                                                       /
// Beschreibung  : Zentraler Manager für HealthKit-Anfragen                         /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation
import Combine
import HealthKit

/* Das sind die HealthKit Identifier:
    .activeEnergyBurned        // "Aktive Energie"
    .dietaryEnergyConsumed     // "Nahrungsenergie"
    .basalEnergyBurned         // "Ruhenergie" (Grundumsatz)
*/
class HealthKitManager: ObservableObject {

    // Singleton für globalen Zugriff
    static let shared = HealthKitManager()

    // HealthStore
    private let healthStore = HKHealthStore()

    // Status der Berechtigung
    @Published var isAuthorized = false

    // MARK: Properties aus Apple HealthKit
    @Published var latestHeartRate: Double?
    @Published var restingHeartRate: Double?
    @Published var latestStepCount: Int?
    @Published var exerciseMinutesToday: Int?
    // Aktiv
    @Published var activeBurnedCalories: Int?
    @Published var dietaryConsumedCalories: Int?
    @Published var basalBurnedCalories: Int?

    // NEU: Schlafzusammenfassung für die letzte Nacht / letzten 24h
    @Published var todaySleepSummary: SleepSummary?    // NEU

    private init() {}

    // Prüft, ob HealthKit auf diesem Gerät verfügbar ist
    var isHealthKitAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    // Berechtigungsfreigabe des Benutzers anfragen für HealthKit-Werte
    private var typesToRead: Set<HKObjectType> {
        let types: Set<HKObjectType?> = [
            HKObjectType.quantityType(forIdentifier: .heartRate),
            HKObjectType.quantityType(forIdentifier: .restingHeartRate),
            HKObjectType.quantityType(forIdentifier: .stepCount),
            HKObjectType.quantityType(forIdentifier: .appleExerciseTime),
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
            HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed),
            HKObjectType.quantityType(forIdentifier: .basalEnergyBurned),
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)
        ]
        return Set(types.compactMap { $0 })
    }

    // Dialog: Berechtigungen beim Benutzer anfragen
    func requestAuthorization() async -> Bool {
        // Prüfen, ob HealthKit verfügbar ist
        guard isHealthKitAvailable else {
            print("HealthKit ist auf diesem Gerät nicht verfügbar")
            return false
        }
        do {
            // Dialog anzeigen
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            // Auf dem Main-Thread Status aktualiseren
            await MainActor.run {
                self.isAuthorized = true
            }
            return true
        } catch {
            print("Fehler bei der HealthKit-Berechtigung: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: Daten aus Apple HealthKit laden

    // Letzte gemessene Herzfrequenz abrufen
    func fetchLatestHeartRate() async {
            // 1. Datentyp definieren
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            return
        }
        // 2. Nur Daten von heute
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        // 3. Sortierung: Neueste zuerst
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        // 4. Query erstellen
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in

                if let error = error {
                    print("Fehler beim Abrufen der Herzfrequenz: \(error.localizedDescription)")
                    continuation.resume()
                    return
                }

                // 5. Ergebnis auslesen
                if let sample = samples?.first as? HKQuantitySample {
                    let heartRateUnit = HKUnit.count().unitDivided(by: .minute())
                    let value = sample.quantity.doubleValue(for: heartRateUnit)

                    // 6. Auf Main-Thread aktualisieren
                    Task { @MainActor in
                        self.latestHeartRate = value
                    }
                }
                continuation.resume()
            }
            // 7. Query ausführen
            healthStore.execute(query)
        }
    }

    // Abrufen des Tagesschrittzählers (tagesweise)
    func fetchTodayStepCount() async {
        guard let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return
        }

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepCountType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in

                if let error = error {
                    print("Fehler beim Abrufen der Schritte: \(error.localizedDescription)")
                    continuation.resume()
                    return
                }

                if let sum = result?.sumQuantity() {
                    let value = sum.doubleValue(for: .count())
                    print("Schritte heute: \(value)")

                    Task { @MainActor in
                        self.latestStepCount = Int(value)
                    }
                } else {
                    print("Keine Schritte-Daten gefunden")
                }

                continuation.resume()
            }
            healthStore.execute(query)
        }
    }

    func fetchTodayBurnedCalories() async {
        // KORRIGIERT: .activeEnergyBurned statt .stepCount
        guard let burnedCaloriesType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            return
        }

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: burnedCaloriesType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in

                if let error = error {
                    print("Fehler beim Abrufen der verbrannten Kalorien: \(error.localizedDescription)")
                    continuation.resume()
                    return
                }

                if let sum = result?.sumQuantity() {
                    let value = sum.doubleValue(for: .kilocalorie())
                    print("Aktiver Kalorienverbrauch heute: \(value) kcal")

                    Task { @MainActor in
                        self.activeBurnedCalories = Int(value)
                    }
                } else {
                    print("Keine Kalorien-Daten gefunden")
                }

                continuation.resume()
            }
            healthStore.execute(query)
        }
    }

    func fetchTodayConsumedCalories() async {
        // KORRIGIERT: .activeEnergyBurned statt .stepCount
        guard let consumedCaloriesType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed) else {
            return
        }

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: consumedCaloriesType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in

                if let error = error {
                    print("Fehler beim Abrufen der eingenommenen Kalorien: \(error.localizedDescription)")
                    continuation.resume()
                    return
                }

                if let sum = result?.sumQuantity() {
                    let value = sum.doubleValue(for: .kilocalorie())
                    print("Aktuelle Kalorienaufnahme heute: \(value) kcal")

                    Task { @MainActor in
                        self.dietaryConsumedCalories = Int(value)
                    }
                } else {
                    print("Keine Kalorien-Daten gefunden")
                }
                continuation.resume()
            }
            healthStore.execute(query)
        }
    }

    func fetchTodayBasalBurnedCalories() async {
        // KORRIGIERT: .activeEnergyBurned statt .stepCount
        guard let basalBurnedCaloriesType = HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned) else {
            return
        }

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: basalBurnedCaloriesType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in

                if let error = error {
                    print("Fehler beim Abrufen des Gesamtumsatzes: \(error.localizedDescription)")
                    continuation.resume()
                    return
                }

                if let sum = result?.sumQuantity() {
                    let value = sum.doubleValue(for: .kilocalorie())
                    print("Kalorien-Gesamtumsatz heute: \(value) kcal")

                    Task { @MainActor in
                        self.basalBurnedCalories = Int(value)
                    }
                } else {
                    print("Keine Kalorien-Daten gefunden")
                }
                continuation.resume()
            }
            healthStore.execute(query)
        }
    }
        // NEU: Schlafdaten für die letzten 24 Stunden abrufen
    func fetchTodaySleepSummary() async {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return
        }

        let now = Date()
            // Fenster: letzte 24 Stunden (typischer "letzte Nacht"-Usecase)
        guard let start = Calendar.current.date(byAdding: .day, value: -1, to: now) else {
            return
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: start,
            end: now,
            options: .strictStartDate
        )

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in

                if let error = error {
                    print("Fehler beim Abrufen der Schlafdaten: \(error.localizedDescription)")
                    Task { @MainActor in
                        self.todaySleepSummary = nil
                    }
                    continuation.resume()
                    return
                }

                guard let samples = samples as? [HKCategorySample], !samples.isEmpty else {
                    print("Keine Schlafdaten in den letzten 24 Stunden gefunden")
                    Task { @MainActor in
                        self.todaySleepSummary = nil
                    }
                    continuation.resume()
                    return
                }

                    // Sekunden-Zähler für Gesamt-Schlaf und "im Bett"
                var totalSleepSeconds: TimeInterval = 0
                var inBedSeconds: TimeInterval = 0

                    // Buckets für Phasen
                var phaseBuckets: [HKCategoryValueSleepAnalysis: TimeInterval] = [:]

                for sample in samples {
                    guard let value = HKCategoryValueSleepAnalysis(rawValue: sample.value) else {
                        continue
                    }

                    let duration = sample.endDate.timeIntervalSince(sample.startDate)

                    switch value {
                        case .inBed:
                                // Zeit im Bett separat sammeln
                            inBedSeconds += duration

                        case .awake:
                                // Wachphasen nicht in den Gesamtschlaf zählen
                            continue

                        default:
                                // Alles andere zählt als Schlaf (REM/Core/Deep/unspezifiziert)
                            totalSleepSeconds += duration
                            phaseBuckets[value, default: 0] += duration
                    }
                }

                let totalMinutes = Int(totalSleepSeconds / 60)
                let inBedMinutes: Int? = inBedSeconds > 0 ? Int(inBedSeconds / 60) : nil

                    // Falls keine Schlafminuten vorhanden sind
                guard totalMinutes > 0 else {
                    print("Keine relevante Schlafdauer gefunden")
                    Task { @MainActor in
                        self.todaySleepSummary = nil
                    }
                    continuation.resume()
                    return
                }

                    // Aus den Buckets SleepPhaseBreakdown erzeugen
                var phases: [SleepPhaseBreakdown] = []

                for (value, seconds) in phaseBuckets {
                    let minutes = Int(seconds / 60)
                    let (name, icon) = Self.sleepPhaseMeta(for: value)
                    let phase = SleepPhaseBreakdown(
                        name: name,
                        systemIcon: icon,
                        minutes: minutes
                    )
                    phases.append(phase)
                }

                    // Feste Reihenfolge: Tiefschlaf, Core, REM, sonstige
                let sortedPhases = phases.sorted { lhs, rhs in
                    Self.phaseOrderIndex(for: lhs.name) < Self.phaseOrderIndex(for: rhs.name)
                }

                let summary = SleepSummary(
                    date: now,
                    totalMinutes: totalMinutes,
                    inBedMinutes: inBedMinutes,
                    phases: sortedPhases
                )

                Task { @MainActor in
                    self.todaySleepSummary = summary
                }

                continuation.resume()
            }

            self.healthStore.execute(query)
        }
    }

        // MARK: - Hilfsfunktionen für Schlafphasen (NEU)

    private static func sleepPhaseMeta(for value: HKCategoryValueSleepAnalysis) -> (String, String) {
        switch value {
            case .asleepREM:
                return ("REM", "brain.head.profile")
            case .asleepDeep:
                return ("Tiefschlaf", "waveform.path.ecg")
            case .asleepCore:
                return ("Kernschlaf", "moonphase.waning.gibbous")
            case .asleepUnspecified, .asleep:
                return ("Schlaf", "moon.zzz.fill")
            case .inBed:
                return ("Im Bett", "bed.double.fill")
            case .awake:
                return ("Wach", "eye.circle")
            @unknown default:
                return ("Unbekannt", "questionmark.circle")
        }
    }

    private static func phaseOrderIndex(for name: String) -> Int {
        switch name.lowercased() {
            case "tiefschlaf": return 0
            case "kernschlaf", "core": return 1
            case "rem": return 2
            case "schlaf": return 3
            case "wach": return 4
            default: return 99
        }
    }
}
