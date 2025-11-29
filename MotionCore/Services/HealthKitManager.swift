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

class HealthKitManager: ObservableObject {

        // Singleton für globalen Zugriff
    static let shared = HealthKitManager()

        // Der HealthStore ist das "Tor" zu HealthKit
    private let healthStore = HKHealthStore()

        // Status der Berechtigung
    @Published var isAuthorized = false

    // MARK: Daten aus Apple HealthKit

    // Letzte gemessene Herzfrequenz
    @Published var latestHeartRate: Double?

    // Schrittzähler
    @Published var latestStepCount: Int?

    private init() {}

        // Prüft, ob HealthKit auf diesem Gerät verfügbar ist
    var isHealthKitAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

        // Berechtigungsfreigabe des Benutzers anfragen für HealthKit-Werte
    private var typesToRead: Set<HKObjectType> {
        let types: Set<HKObjectType?> = [
            HKObjectType.quantityType(forIdentifier: .heartRate),
            HKObjectType.quantityType(forIdentifier: .stepCount),
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)
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

        // Schritte
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
}
