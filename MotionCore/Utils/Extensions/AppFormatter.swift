//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Hilftools                                                        /
// Datei . . . . : AppFormatter.swift                                               /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 18.11.2025                                                       /
// Beschreibung  : Formatierung für Datum, Uhrzeit, Zahlen, etc.                    /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation
import SwiftUI

enum AppFormatters {
    // MARK: - Dates

    /// Datumsformat: DD.MM.YYYY
    static let dateGermanShort: Date.FormatStyle = {
        Date.FormatStyle
            .dateTime
            .day(.twoDigits)
            .month(.twoDigits)
            .year()
            .locale(Locale(identifier: "de_DE"))
    }()

    /// 17. November 2025
    static let dateGermanLong: Date.FormatStyle = {
        Date.FormatStyle
            .dateTime
            .day(.twoDigits)
            .month(.wide)
            .year()
            .locale(Locale(identifier: "de_DE"))
    }()

    /// Montag, 17. November 2025
    static let dateWithWeekday: Date.FormatStyle = {
        Date.FormatStyle
            .dateTime
            .weekday(.wide)
            .day(.twoDigits)
            .month(.wide)
            .year()
            .locale(Locale(identifier: "de_DE"))
    }()

    /// 17.11.2025 – 2:35 PM
    static let timeGermanShort: Date.FormatStyle = {
        Date.FormatStyle
            .dateTime
            .hour(.twoDigits(amPM: .omitted))
            .minute(.twoDigits)
            .locale(Locale(identifier: "de_DE"))
    }()

        /// 17.11.2025 – 14:32
        static let timeGermanLong: Date.FormatStyle = {
            Date.FormatStyle
                .dateTime
                .hour(.twoDigits(amPM: .abbreviated))
                .minute(.twoDigits)
                .locale(Locale(identifier: "de_DE"))
        }()
}
