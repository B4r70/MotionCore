//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : UI Extensions                                                    /
// Datei . . . . : NumberFormatting.swift                                           /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 03.01.2026                                                       /
// Beschreibung  : Formatierungs-Helper für Zahlen (kg, Wiederholungen, Zeiten)     /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

// MARK: - Double Formatting

extension Double {

    /// "22.0 kg" (one decimal)
    var kg1: String {
        String(format: "%.1f kg", self)
    }

    /// "22 kg" (no decimals)
    var kg0: String {
        String(format: "%.0f kg", self)
    }

    /// "22.5" (one decimal, no unit)
    var oneDecimal: String {
        String(format: "%.1f", self)
    }

    /// "22" (no decimals, no unit)
    var noDecimals: String {
        String(format: "%.0f", self)
    }

    /// Returns "-" if value is <= 0, otherwise formatted with one decimal and "kg".
    var kg1OrDash: String {
        self > 0 ? kg1 : "-"
    }

    /// Returns "0.0 kg" style only if > 0, else empty string (useful for optional labels).
    var kg1OrEmpty: String {
        self > 0 ? kg1 : ""
    }
}

// MARK: - Int Time Formatting

extension Int {

    /// Formats seconds to "m:ss" (e.g. 90 -> "1:30")
    var mmss: String {
        let mins = self / 60
        let secs = self % 60
        return "\(mins):\(String(format: "%02d", secs))"
    }

    /// Formats seconds to motioncore style:
    ///  - 75 -> "1:15 Pause"
    ///  - 120 -> "2 Min Pause"
    ///  - 30 -> "30 Sek Pause"
    var restText: String {
        let mins = self / 60
        let secs = self % 60

        if mins > 0 && secs > 0 {
            return "\(mins):\(String(format: "%02d", secs)) Pause"
        } else if mins > 0 {
            return "\(mins) Min Pause"
        } else {
            return "\(secs) Sek Pause"
        }
    }
}

// MARK: - Reps / Sets Formatting

extension Collection {

    /// "3 × 10" (e.g. setsCount x reps)
    func setsRepsText(reps: Int) -> String {
        "\(count) × \(reps)"
    }
}
