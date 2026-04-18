//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Workout                                                          /
// Datei . . . . : RIRInputSheet.swift                                              /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 18.04.2026                                                       /
// Beschreibung  : Kompaktes Sheet am letzten Work-Set einer Uebung — erfasst RIR  /
//                 (Reps in Reserve) via 5 Buttons, parallel zum RestTimer.         /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI
import UIKit

struct RIRInputSheet: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var restTimerManager: RestTimerManager
    let targetSeconds: Int
    let onAdjustRest: (Int) -> Void
    let onSelectRIR: (Int) -> Void   // 0..4, 4 = "4+"
    let onSkip: () -> Void

    private let haptic = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        VStack(spacing: 20) {
            // Kompakter Rest-Timer oben
            CompactRestTimerView(
                restTimerManager: restTimerManager,
                targetSeconds: targetSeconds,
                onAdjust: onAdjustRest
            )

            // RIR-Abfrage
            VStack(spacing: 10) {
                Text("Wie viele Reps wären noch drin gewesen?")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                // 5 gleich breite RIR-Buttons: 0, 1, 2, 3, 4+
                HStack(spacing: 8) {
                    ForEach(0..<5, id: \.self) { idx in
                        Button {
                            haptic.impactOccurred()
                            onSelectRIR(idx)
                            dismiss()
                        } label: {
                            Text(idx == 4 ? "4+" : "\(idx)")
                                .font(.headline)
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity, minHeight: 48)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.secondary.opacity(0.12))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Skip-Link
            Button("Überspringen") {
                onSkip()
                dismiss()
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .presentationDetents([.fraction(0.45)])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Preview

#Preview {
    RIRInputSheet(
        restTimerManager: RestTimerManager(),
        targetSeconds: 90,
        onAdjustRest: { _ in },
        onSelectRIR: { _ in },
        onSkip: { }
    )
}
