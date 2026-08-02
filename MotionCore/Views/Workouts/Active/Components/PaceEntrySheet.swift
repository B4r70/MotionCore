//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Aktive Workouts                                                  /
// Datei . . . . : PaceEntrySheet.swift                                             /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 02.08.2026                                                       /
// Beschreibung  : Sheet zur Pace-Eingabe nach Abschluss einer zeitbasierten        /
//                 Übung (mm:ss pro 500 m/km bzw. km/h, je nach Übungs-Config).     /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI
import UIKit

// MARK: - Pace Entry Sheet

/// Erscheint nach dem letzten Time-Satz einer Übung mit aktivierter Pace-Erfassung.
/// Eingabe je nach Einheit: mm:ss-Wheels (min/500m, min/km) oder km/h-Wheel.
struct PaceEntrySheet: View {
    @Environment(\.dismiss) private var dismiss

    let exerciseName: String
    let unit: SetPaceUnit
    let initialValue: Double        // 0 = noch kein Pace erfasst
    let onSave: (Double) -> Void
    let onSkip: () -> Void

    // mm:ss-Eingabe (isTimePerDistance)
    @State private var minutes: Int = 2
    @State private var seconds: Int = 30

    // km/h-Eingabe (in 0.5er-Schritten, intern als Double)
    @State private var speedKmh: Double = 8.0

    private let haptic = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        VStack(spacing: 20) {
            // Kopf: Titel + Übungsname
            VStack(spacing: 4) {
                Text("Pace erfassen")
                    .font(AppFont.headline)
                    .foregroundStyle(Theme.textPrimary)
                Text(exerciseName)
                    .font(AppFont.callout)
                    .foregroundStyle(Theme.textSecondary)
            }

            // Einheiten-abhängige Eingabe
            if unit.isTimePerDistance {
                timePickerRow
            } else {
                speedPickerRow
            }

            // Speichern — 0:00 nicht erlaubt (0 = Sentinel für „nicht erfasst")
            Button {
                haptic.impactOccurred()
                onSave(currentValue)
                dismiss()
            } label: {
                Label("Speichern", systemImage: "checkmark")
            }
            .buttonStyle(.mcPrimary)
            .disabled(currentValue <= 0)

            // Skip-Link (analog RIRInputSheet)
            Button("Ohne Pace fortfahren") {
                onSkip()
                dismiss()
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .presentationDetents([.fraction(0.5)])
        .presentationDragIndicator(.visible)
        .onAppear { bootstrapFromInitialValue() }
    }

    // MARK: - Eingabe-Rows

    /// mm:ss-Wheels für min/500m und min/km
    private var timePickerRow: some View {
        HStack(spacing: 0) {
            Picker("Minuten", selection: $minutes) {
                ForEach(0...20, id: \.self) { m in
                    Text("\(m)").tag(m)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 70)

            Text(":")
                .font(.title2.bold())
                .foregroundStyle(Theme.textPrimary)

            Picker("Sekunden", selection: $seconds) {
                ForEach(0...59, id: \.self) { s in
                    Text(String(format: "%02d", s)).tag(s)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 70)

            Text(unit == .minPer500m ? "/500 m" : "/km")
                .font(AppFont.callout)
                .foregroundStyle(Theme.textSecondary)
                .padding(.leading, 8)
        }
        .frame(height: 130)
    }

    /// km/h-Wheel in 0.5er-Schritten
    private var speedPickerRow: some View {
        HStack(spacing: 8) {
            Picker("km/h", selection: $speedKmh) {
                ForEach(Array(stride(from: 1.0, through: 40.0, by: 0.5)), id: \.self) { v in
                    Text(String(format: "%.1f", v)).tag(v)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 100)

            Text("km/h")
                .font(AppFont.callout)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(height: 130)
    }

    // MARK: - Werte-Mapping

    /// Aktueller Eingabewert im Speicherformat (Sekunden bzw. km/h)
    private var currentValue: Double {
        if unit.isTimePerDistance {
            return Double(minutes * 60 + seconds)
        }
        return speedKmh
    }

    /// Startwert aus vorhandenem Pace bzw. Einheiten-Default ableiten
    private func bootstrapFromInitialValue() {
        let value = initialValue > 0 ? initialValue : unit.defaultValue
        if unit.isTimePerDistance {
            // Auf Wheel-Bereich clampen (max 20:59), sonst zeigt der Picker inkonsistente Werte
            let total = min(Int(value.rounded()), 20 * 60 + 59)
            minutes = total / 60
            seconds = total % 60
        } else {
            // Auf 0.5er-Raster runden, damit der Wheel-Tag matcht
            speedKmh = min(max((value * 2).rounded() / 2, 1.0), 40.0)
        }
    }
}

// MARK: - Preview

#Preview("Pace min/500m") {
    PaceEntrySheet(
        exerciseName: "Ruderergometer",
        unit: .minPer500m,
        initialValue: 0,
        onSave: { _ in },
        onSkip: { }
    )
}

#Preview("Pace km/h") {
    PaceEntrySheet(
        exerciseName: "Cross-Trainer",
        unit: .kmh,
        initialValue: 8.5,
        onSave: { _ in },
        onSkip: { }
    )
}
