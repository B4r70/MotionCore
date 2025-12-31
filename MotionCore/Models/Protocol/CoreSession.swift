//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Protokolle                                                       /
// Datei . . . . : CoreSession.swift                                                /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 31.12.2025                                                       /
// Beschreibung  : Gemeinsames Protokoll für alle Workout-Session-Typen             /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
// Hinweis  . . : Dieses Protokoll definiert die gemeinsamen Eigenschaften und      /
//                Methoden für CardioSession, StrengthSession und OutdoorSession.   /
//                Ermöglicht polymorphe Verarbeitung aller Session-Typen.           /
// ---------------------------------------------------------------------------------/
//
import Foundation

// MARK: - CoreSession Protocol

// Gemeinsames Protokoll für alle Workout-Session-Typen.
// Definiert die Basis-Eigenschaften, die jede Session haben muss.
protocol CoreSession: AnyObject {

    // MARK: - Zeitliche Daten

    // Datum der Session (für Anzeige/Sortierung)
    var date: Date { get set }

    // Exakter Startzeitpunkt (für Timer/HealthKit)
    var startedAt: Date? { get set }

    // Exakter Endzeitpunkt (für Timer/HealthKit)
    var completedAt: Date? { get set }

    // Dauer in Minuten
    var duration: Int { get set }

    // MARK: - Session-Status

    // Ist die Session abgeschlossen?
    var isCompleted: Bool { get set }

    // Wurde die Session live getrackt (vs. manuell eingetragen)?
    var isLiveSession: Bool { get set }

    // MARK: - Körper & Gesundheit

    // Körpergewicht in kg
    var bodyWeight: Double { get set }

    // Durchschnittliche Herzfrequenz
    var heartRate: Int { get set }

    // Maximale Herzfrequenz
    var maxHeartRate: Int { get set }

    // Verbrannte Kalorien
    var calories: Int { get set }

    // MARK: - Intensität

    // Intensität als Raw-Wert (für SwiftData-Persistenz)
    var intensityRaw: Int { get set }

    // RPE 1-10 (Rate of Perceived Exertion) - subjektive Anstrengung
    var perceivedExertion: Int? { get set }

    // Energielevel vor dem Training (1-5)
    var energyLevelBefore: Int? { get set }

    // MARK: - HealthKit-Integration

    // Verknüpfung zur HKWorkout-UUID
    var healthKitWorkoutUUID: UUID? { get set }

    // Quelle der Session: "iPhone", "AppleWatch", "manual"
    var deviceSource: String { get set }

    // MARK: - Notizen

    // Freitext-Notizen zur Session
    var notes: String { get set }

    // MARK: - Berechnete Eigenschaften

    // Tatsächliche Trainingsdauer in Minuten (berechnet aus startedAt/completedAt)
    var actualDuration: Int? { get }

    // MARK: - Session-Steuerung

    // Training starten
    func start()

    // Training beenden
    func complete()
}

// MARK: - Default Implementations

extension CoreSession {

    // Typisierte Intensity-Property (basierend auf intensityRaw)
    var intensity: Intensity {
        get { Intensity(rawValue: intensityRaw) ?? .none }
        set { intensityRaw = newValue.rawValue }
    }

    // Standardimplementierung für actualDuration
    var actualDuration: Int? {
        guard let start = startedAt, let end = completedAt else { return nil }
        return Calendar.current.dateComponents([.minute], from: start, to: end).minute
    }

    // Standardimplementierung für start()
    func start() {
        startedAt = Date()
        isCompleted = false
        isLiveSession = true
    }

    // Standardimplementierung für complete()
    func complete() {
        completedAt = Date()
        isCompleted = true

        // Dauer berechnen und speichern
        if let minutes = actualDuration {
            duration = minutes
        }
    }

    // Ist die Session gerade aktiv (gestartet aber nicht beendet)?
    var isActive: Bool {
        startedAt != nil && !isCompleted
    }

    // Formatierte Dauer als String (z.B. "45 Min" oder "1:30 Std")
    var formattedDuration: String {
        if duration < 60 {
            return "\(duration) Min"
        } else {
            let hours = duration / 60
            let minutes = duration % 60
            if minutes == 0 {
                return "\(hours) Std"
            } else {
                return "\(hours):\(String(format: "%02d", minutes)) Std"
            }
        }
    }

    // Prüft ob die Session Herzfrequenz-Daten hat
    var hasHeartRateData: Bool {
        heartRate > 0 || maxHeartRate > 0
    }

    // Prüft ob die Session HealthKit-verknüpft ist
    var isLinkedToHealthKit: Bool {
        healthKitWorkoutUUID != nil
    }

    // Prüft ob subjektive Bewertung vorhanden ist
    var hasSubjectiveRating: Bool {
        perceivedExertion != nil || energyLevelBefore != nil
    }
}

// MARK: - CoreSessionIdentifiable

// Erweiterung für Typ-Identifikation (nutzt bestehendes WorkoutType aus TrainingTypes)
protocol CoreSessionIdentifiable: CoreSession {
    // Der Typ dieser Workout-Session
    static var workoutType: WorkoutType { get }
}

// MARK: - Conformance für bestehende Sessions

extension CardioSession: CoreSession, CoreSessionIdentifiable {
    static var workoutType: WorkoutType { .cardio }
}

extension StrengthSession: CoreSession, CoreSessionIdentifiable {
    static var workoutType: WorkoutType { .strength }
}

extension OutdoorSession: CoreSession, CoreSessionIdentifiable {
    static var workoutType: WorkoutType { .outdoor }
}
