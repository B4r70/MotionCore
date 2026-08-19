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

    // Eingefroren beim Öffnen: ob zu diesem Zeitpunkt ein Rest-Timer lief.
    // Bewusst kein Live-Prädikat auf restTimerManager.isResting — RestTimerManager.stop()
    // setzt isResting bei Ablauf auf false, ein Live-Wert würde die RIR-Buttons mitten in
    // der Auswahl nach oben springen lassen. .sheet(item:) erzeugt pro Präsentation eine
    // frische View-Identity, daher gibt es keinen Reuse-Pfad mit veraltetem Wert.
    @State private var showsRestTimer: Bool

    private let haptic = UIImpactFeedbackGenerator(style: .light)

    init(
        restTimerManager: RestTimerManager,
        targetSeconds: Int,
        onAdjustRest: @escaping (Int) -> Void,
        onSelectRIR: @escaping (Int) -> Void,
        onSkip: @escaping () -> Void
    ) {
        self.restTimerManager = restTimerManager
        self.targetSeconds = targetSeconds
        self.onAdjustRest = onAdjustRest
        self.onSelectRIR = onSelectRIR
        self.onSkip = onSkip
        self._showsRestTimer = State(initialValue: restTimerManager.isResting)
    }

    var body: some View {
        VStack(spacing: 20) {
            // Kompakter Rest-Timer oben — nur wenn beim Öffnen tatsächlich einer lief
            // (sonst zeigt CompactRestTimerView einen vollen Theme.danger-Ring mit "0s")
            if showsRestTimer {
                CompactRestTimerView(
                    restTimerManager: restTimerManager,
                    targetSeconds: targetSeconds,
                    onAdjust: onAdjustRest
                )
            }

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
            Button("Ohne RIR fortfahren") {
                onSkip()
                dismiss()
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .presentationDetents([.fraction(showsRestTimer ? 0.45 : 0.3)])
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
