//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Berechnung                                                       /
// Datei . . . . : GreetingCalcEngine.swift                                         /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 26.04.2026                                                       /
// Beschreibung  : Erzeugt tageszeit-abhängige, zufällige Begrüßungen               /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/

import Foundation

enum DaytimeBucket {
    case earlyMorning   //  4:00 – 09:59
    case morning        // 10:00 – 11:59
    case afternoon      // 12:00 – 17:59
    case evening        // 18:00 – 22:59
    case night          // 23:00 – 03:59
}

struct GreetingCalcEngine {

    /// Liefert eine zufällige Begrüßung passend zur aktuellen Uhrzeit.
    /// - Parameters:
    ///   - name: Vorname. Wenn leer, wird die Begrüßung ohne Namen formatiert.
    ///   - date: Referenzzeit (Default: jetzt).
    /// - Returns: Fertig formatierter String, z.B. "Guten Abend, Barto".
    static func greeting(for name: String, at date: Date = Date()) -> String {
        let bucket = bucket(for: date)
        let template = templates(for: bucket).randomElement() ?? "Hallo"
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            return template
        }
        return "\(template), \(trimmed)"
    }

    static func bucket(for date: Date) -> DaytimeBucket {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 4..<10:   return .earlyMorning
        case 10..<12:  return .morning
        case 12..<18:  return .afternoon
        case 18..<23:  return .evening
        default:       return .night
        }
    }

    private static func templates(for bucket: DaytimeBucket) -> [String] {
        switch bucket {
        case .earlyMorning:
            return [
                "Guten Morgen",
                "Moin",
                "Hey, schon wach",
                "Schönen Morgen",
                "Frischer Tag"
            ]
        case .morning:
            return [
                "Guten Morgen",
                "Hallo",
                "Hey",
                "Schön, dich zu sehen",
                "Bereit für heute"
            ]
        case .afternoon:
            return [
                "Hallo",
                "Hey",
                "Guten Tag",
                "Schön, dich zu sehen",
                "Mittendrin"
            ]
        case .evening:
            return [
                "Guten Abend",
                "Hey",
                "Hallo",
                "Feierabend",
                "Schön, dich zu sehen"
            ]
        case .night:
            return [
                "Noch wach",
                "Späte Stunde",
                "Hallo",
                "Hey",
                "Eine ruhige Nacht"
            ]
        }
    }
}

// MARK: - Preview

#if DEBUG
import SwiftUI

private struct GreetingPreviewRow: View {
    let bucket: DaytimeBucket
    let label: String
    let hour: Int

    var body: some View {
        // Feste Referenzzeit für den jeweiligen Bucket
        let calendar = Calendar.current
        let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        let greeting = GreetingCalcEngine.greeting(for: "Barto", at: date)
        return HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 110, alignment: .leading)
            Text(greeting)
                .font(.body)
        }
    }
}

#Preview("GreetingCalcEngine – alle Buckets") {
    VStack(alignment: .leading, spacing: 12) {
        GreetingPreviewRow(bucket: .earlyMorning, label: "earlyMorning (06h)", hour: 6)
        GreetingPreviewRow(bucket: .morning,      label: "morning (10h)",      hour: 10)
        GreetingPreviewRow(bucket: .afternoon,    label: "afternoon (14h)",    hour: 14)
        GreetingPreviewRow(bucket: .evening,      label: "evening (20h)",      hour: 20)
        GreetingPreviewRow(bucket: .night,        label: "night (01h)",        hour: 1)
    }
    .padding()
}
#endif
