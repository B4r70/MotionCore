//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Hilftools                                                        /
// Datei . . . . : VersionBundle.swift                                              /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 19.12.2025                                                       /
// Beschreibung  : Bundle Extension für App-Versionierung                           /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

// Bundle Extension für automatische App-Versionierung
extension Bundle {
    // Öffentliche Version (z.B. "1.0.0")
    var appVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unbekannt"
    }

    // Interne Build-Nummer (z.B. "42")
    var buildNumber: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "Unbekannt"
    }

    // Kombinierte Version für Anzeige (z.B. "1.0.0 (42)")
    var fullVersion: String {
        "\(appVersion) (\(buildNumber))"
    }
}
