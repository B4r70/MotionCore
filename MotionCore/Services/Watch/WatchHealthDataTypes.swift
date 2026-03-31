//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Watch-Kommunikation                                              /
// Datei . . . . : WatchHealthDataTypes.swift                                       /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 31.03.2026                                                       /
// Beschreibung  : Message-Keys für Health-Kommunikation zwischen Watch und iPhone   /
//                 IDENTISCH in beiden Targets — Änderungen synchron pflegen        /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

// MARK: - Health Data Keys (Watch → iPhone, Live-Updates)

/// Keys für Live-Gesundheitsdaten von der Watch
enum WatchHealthKey {
    static let healthUpdate    = "healthUpdate"
    static let currentHR       = "currentHR"
    static let averageHR       = "averageHR"
    static let maxHR           = "maxHR"
    static let activeCalories  = "activeCalories"
    static let isWorkoutActive = "isWorkoutActive"
}

// MARK: - Exercise Snapshot Keys (Watch → iPhone, bei Set-Completion)

/// Keys für Übungs-Snapshots nach jedem Satz
enum WatchExerciseSnapshotKey {
    static let exerciseSnapshot = "exerciseSnapshot"
    static let snapshotAvgHR    = "snapshotAvgHR"
    static let snapshotMinHR    = "snapshotMinHR"
    static let snapshotMaxHR    = "snapshotMaxHR"
    static let snapshotCalories = "snapshotCalories"
    static let snapshotDuration = "snapshotDuration"
}

// MARK: - Workout Lifecycle Keys (iPhone → Watch)

/// Keys für Workout-Lifecycle-Steuerung vom iPhone zur Watch
enum WatchWorkoutLifecycleKey {
    static let startHealthTracking   = "startHealthTracking"
    static let stopHealthTracking    = "stopHealthTracking"
    static let discardHealthTracking = "discardHealthTracking"
    static let pauseHealthTracking   = "pauseHealthTracking"
    static let resumeHealthTracking  = "resumeHealthTracking"
    static let exerciseTransition    = "exerciseTransition"
    static let requestSnapshot       = "requestHealthSnapshot"
}

// MARK: - Heartbeat Keys

/// Keys für den optionalen 60-Sekunden-Heartbeat-Timer
enum WatchHeartbeatKey {
    /// iPhone sendet diesen Key um den 60-Sek-Timer auf der Watch zu aktivieren/deaktivieren
    static let enableHeartbeat = "enableHeartbeat"
}
