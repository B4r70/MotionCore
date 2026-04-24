//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Workout                                                          /
// Datei . . . . : RIRRetroSheet.swift                                              /
// Autor . . . . : Bartosz Stryjewski                                               //
// Erstellt am . : 24.04.2026                                                       /
// Beschreibung  : Vereinfachtes RIR-Sheet ohne RestTimer — fuer nachtraegliche     /
//                 RIR-Eingabe wenn der letzte Satz durch Loeschen wechselte.       /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI
import UIKit

struct RIRRetroSheet: View {
    @Environment(\.dismiss) private var dismiss

    let onSelectRIR: (Int) -> Void
    let onSkip: () -> Void

    private let haptic = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        VStack(spacing: 20) {
            Text("RIR für letzten Satz nachtragen")
                .font(.headline)
                .multilineTextAlignment(.center)

            VStack(spacing: 10) {
                Text("Wie viele Reps wären noch drin gewesen?")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

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

            Button("Ohne RIR fortfahren") {
                onSkip()
                dismiss()
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .presentationDetents([.fraction(0.35)])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Preview

#Preview {
    RIRRetroSheet(
        onSelectRIR: { _ in },
        onSkip: { }
    )
}
