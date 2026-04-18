//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Workout                                                          /
// Datei . . . . : FineTuneChipsView.swift                                          /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 18.04.2026                                                       /
// Beschreibung  : Feintuning-Chips fuer Zwischengewichte bei StudioEquipment mit  /
//                 intermediateIncrements — +/- Capsules zur feinkoernigen Anpassung/
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - Fine Tune Chips View

struct FineTuneChipsView: View {
    let increments: [Double]
    let onAdjust: (Double) -> Void

    // Nur positive Werte, aufsteigend sortiert
    private var sortedIncrements: [Double] {
        increments.filter { $0 > 0 }.sorted()
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text("Feintuning")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // Minus-Chips absteigend (groesster Wert links)
                    ForEach(sortedIncrements.reversed(), id: \.self) { value in
                        chip(label: "−\(format(value))") {
                            onAdjust(-value)
                        }
                    }
                    // Plus-Chips aufsteigend
                    ForEach(sortedIncrements, id: \.self) { value in
                        chip(label: "+\(format(value))") {
                            onAdjust(value)
                        }
                    }
                }
            }
        }
    }

    private func chip(label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.secondary.opacity(0.15))
                )
        }
        .buttonStyle(.plain)
    }

    // kg-Format: 0.625 statt 0.625000, glatte Ganzzahlen ohne Dezimalstellen
    private func format(_ value: Double) -> String {
        if value == value.rounded() {
            return String(format: "%.0f", value)
        }
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 3
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        FineTuneChipsView(
            increments: [0.625, 1.25],
            onAdjust: { print("Adjust: \($0)") }
        )
        .padding()

        FineTuneChipsView(
            increments: [3.5],
            onAdjust: { print("Adjust: \($0)") }
        )
        .padding()
    }
}
