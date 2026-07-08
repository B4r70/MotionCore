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
        VStack(alignment: .leading, spacing: Space.s3) {
            HStack {
                Image(systemName: "stopwatch")
                    .foregroundStyle(Theme.accent)

                Text("Übungsdauer")
                    .font(AppFont.headline)
                    .foregroundStyle(Theme.textPrimary)

                Spacer()

                Text(formatDuration(durationSeconds))
                    .font(AppFont.headline.monospacedDigit())
                    .foregroundStyle(Theme.accent)
            }

            // Preset-Buttons in 3-Spalten-Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Space.s2), count: 3), spacing: Space.s2) {
                ForEach(presets, id: \.self) { seconds in
                    Button {
                        durationSeconds = seconds
                    } label: {
                        Text(formatDuration(seconds))
                            .font(AppFont.callout)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: Radius.sm)
                                    .fill(durationSeconds == seconds ? Theme.accentSoft : Theme.surfaceSunken)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: Radius.sm)
                                    .stroke(durationSeconds == seconds ? Theme.accent : Theme.line, lineWidth: 1)
                            )
                    }
                    .foregroundStyle(durationSeconds == seconds ? Theme.accent : Theme.textPrimary)
                }
            }

            // Feineinstellung ±15 Sekunden
            HStack {
                Button {
                    if durationSeconds >= 15 { durationSeconds -= 15 }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Theme.accent)
                }

                Spacer()

                Text("±15 Sek.")
                    .font(AppFont.caption)
                    .foregroundStyle(Theme.textSecondary)

                Spacer()

                Button {
                    if durationSeconds < 3600 { durationSeconds += 15 }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Theme.accent)
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
