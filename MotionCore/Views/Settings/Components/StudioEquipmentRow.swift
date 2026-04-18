//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Einstellungen / Komponenten                                      /
// Datei . . . . : StudioEquipmentRow.swift                                         /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 18.04.2026                                                       /
// Beschreibung  : Listenzeile fuer ein Studio-Geraet (Icon, Gewichtsbereich, Badge)/
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct StudioEquipmentRow: View {

    let equipment: StudioEquipment

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {

            // Gerätetyp-Icon
            Image(systemName: equipment.equipmentType.iconName)
                .font(.system(size: 22))
                .foregroundStyle(.secondary)
                .frame(width: 28)

            // Name + Gewichtsbereich
            VStack(alignment: .leading, spacing: 2) {
                Text(equipment.name)
                    .font(.body)

                Text(weightRangeText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Feintuning-Badge — nur wenn Zwischengewichte vorhanden
            if !equipment.intermediateIncrements.isEmpty {
                Text("Feintuning")
                    .font(.caption2.bold())
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.accentColor.opacity(0.15)))
                    .foregroundStyle(Color.accentColor)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Hilfsmethoden

    /// Formatiert den Gewichtsbereich als lesbaren String
    private var weightRangeText: String {
        var text = "Ab \(formatted(equipment.startWeight)) kg · +\(formatted(equipment.increment))"
        if let max = equipment.maxWeight {
            text += " · max \(formatted(max))"
        }
        return text
    }

    /// Formatiert einen Double mit bis zu 3 Dezimalstellen (entfernt trailing zeros)
    private func formatted(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 3
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}

// MARK: - StudioEquipmentType Extensions

extension StudioEquipmentType {

    /// Lesbarer Anzeigename für den Gerätetyp
    var displayName: String {
        switch self {
        case .machine:    return "Maschine"
        case .cable:      return "Kabelzug"
        case .dumbbell:   return "Kurzhantel"
        case .barbell:    return "Langhantel"
        case .bodyweight: return "Körpergewicht"
        case .other:      return "Sonstiges"
        }
    }

    /// SF-Symbol-Name für den Gerätetyp
    var iconName: String {
        switch self {
        case .machine:    return "gear"
        case .cable:      return "arrow.up.and.down"
        case .dumbbell:   return "dumbbell.fill"
        case .barbell:    return "figure.strengthtraining.traditional"
        case .bodyweight: return "figure.stand"
        case .other:      return "questionmark.circle"
        }
    }
}
