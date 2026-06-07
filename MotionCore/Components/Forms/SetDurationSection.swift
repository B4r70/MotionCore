//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : UI-Elemente                                                      /
// Datei . . . . : SetDurationSection.swift                                         /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 06.06.2026                                                       /
// Beschreibung  : Form-Section zur Konfiguration der Übungsdauer (zeitbasierte     /
//                 Sätze): Preset-Buttons, Feineinstellung, mm:ss-Anzeige           /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
import SwiftUI

// MARK: - Set Duration Section

/// Konfiguriert die Dauer eines zeitbasierten Satzes in Sekunden.
/// Analoger Aufbau zu `SetRestTimeSection`: Preset-Buttons + ±15-s-Feineinstellung.
struct SetDurationSection: View {
    @Binding var durationSeconds: Int

    // Preset-Werte in Sekunden: 30 s / 1 Min / 2 Min / 3 Min / 5 Min
    private let presets = [30, 60, 120, 180, 300]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "stopwatch")
                    .foregroundStyle(Color.blue)

                Text("Übungsdauer")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()

                Text(formatDuration(durationSeconds))
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(Color.blue)
            }

            // Preset-Buttons in 3-Spalten-Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(presets, id: \.self) { seconds in
                    Button {
                        durationSeconds = seconds
                    } label: {
                        Text(formatDuration(seconds))
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(durationSeconds == seconds ? Color.blue.opacity(0.2) : Color.clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(durationSeconds == seconds ? Color.blue : Color.white.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .foregroundStyle(durationSeconds == seconds ? .blue : .primary)
                }
            }

            // Feineinstellung ±15 Sekunden
            HStack {
                Button {
                    if durationSeconds >= 15 { durationSeconds -= 15 }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.blue)
                }

                Spacer()

                Text("±15 Sek.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    if durationSeconds < 3600 { durationSeconds += 15 }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.blue)
                }
            }
        }
    }

    /// Formatiert Sekunden als mm:ss (z. B. 300 → „5:00 Min", 90 → „1:30 Min", 30 → „0:30 Min")
    private func formatDuration(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        if secs == 0 {
            return String(format: "%d:%02d Min", mins, secs)
        } else {
            return String(format: "%d:%02d Min", mins, secs)
        }
    }
}
