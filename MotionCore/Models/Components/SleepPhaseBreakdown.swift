//----------------------------------------------------------------------------------/
// # MotionCore
//----------------------------------------------------------------------------------/
// Abschnitt . . : Daten-Modell
// Datei . . . . : SleepTypes.swift
// Autor  . . . : Bartosz Stryjewski
// Erstellt am . : 09.12.2025
// Beschreibung  : Datentypen für Schlafauswertung
//----------------------------------------------------------------------------------/

import Foundation

/// Einzelne Schlafphase (z. B. REM, Tiefschlaf, Kernschlaf, Wach)
struct SleepPhaseBreakdown: Identifiable {
    let id = UUID()
    let name: String              // z. B. "REM", "Tiefschlaf"
    let systemIcon: String        // SF Symbol, z. B. "brain.head.profile"
    let minutes: Int              // Dauer in Minuten

    var formattedDuration: String {
        let h = minutes / 60
        let m = minutes % 60
        if h > 0 {
            return String(format: "%dh %02dmin", h, m)
        } else {
            return String(format: "%dmin", m)
        }
    }
    
    /// Wird relativ zur Gesamtschlafzeit in der Card genutzt
    func percentage(of totalMinutes: Int) -> Double {
        guard totalMinutes > 0 else { return 0 }
        return Double(minutes) / Double(totalMinutes)
    }
}

/// Gesamtübersicht einer Nacht
struct SleepSummary {
    let date: Date               // Nacht/Tag
    let totalMinutes: Int        // Gesamtschlafzeit (nur „schlafend“)
    let inBedMinutes: Int?       // Optional: Zeit im Bett
    let phases: [SleepPhaseBreakdown]  // REM/Core/Deep/Wach/etc.

    var formattedTotal: String {
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        return String(format: "%dh %02dmin", h, m)
    }
}
