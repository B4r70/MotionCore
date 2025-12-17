//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Extensions Daten-Modell                                          /
// Datei . . . . : AppSettingsUserDefaults.swift                                    /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 23.11.2025                                                       /
// Beschreibung  : Extensions für die Userdefaults in AppSettings                   /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

extension AppSettings {
    
    static func loadInitialBirthdayDate() -> Date {
        // 1. Abrufen des gespeicherten Datums
        let storedBirthdayDate = UserDefaults.standard.object(forKey: "user.userBirthdayDate") as? Date

        // 2. Standard-Fallback-Datum festlegen (z.B. 01.01.2000)
        let defaultDate = {
            var components = DateComponents()
            components.year = 2000
            components.month = 1
            components.day = 1
            return Calendar.current.date(from: components)!
        }()

        // 3. Verwenden des gespeicherten Datums, ansonsten des Standarddatums
        return storedBirthdayDate ?? defaultDate
    }
}
