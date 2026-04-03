//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Zusammenfassung                                                  /
// Datei . . . . : CountUpText.swift                                                /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-04-02                                                       /
// Beschreibung  : Animierter Zähler-Text von 0 bis Zielwert                        /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - CountUp-Text

/// Animierter Text, der beim Erscheinen von 0 auf targetValue hochzählt.
/// Animation startet nur einmal pro View-Lebenszyklus.
struct CountUpText: View {

    // MARK: - Parameter

    let targetValue: Int
    var duration: Double = 0.8
    var font: Font = .system(size: 26, weight: .bold, design: .rounded)
    var suffix: String = ""

    // MARK: - State

    @State private var displayValue: Int = 0

    // MARK: - Body

    var body: some View {
        Text("\(displayValue)\(suffix)")
            .font(font)
            .contentTransition(.numericText(value: Double(displayValue)))
            .task(id: targetValue) {
                // Animation neu starten wenn sich der Zielwert ändert
                await animateCountUp()
            }
    }

    // MARK: - Animation

    /// Zählt displayValue von Startwert auf targetValue hoch.
    /// Werte > 10.000: Animation startet bei 80% des Zielwerts.
    private func animateCountUp() async {
        guard targetValue > 0 else {
            displayValue = targetValue
            return
        }

        let startValue = targetValue > 10_000 ? Int(Double(targetValue) * 0.8) : 0
        displayValue = startValue

        // Animationsdauer in 30 Schritte aufteilen
        let steps = min(30, targetValue - startValue)
        guard steps > 0 else {
            displayValue = targetValue
            return
        }

        let stepDuration = duration / Double(steps)
        let increment = max(1, (targetValue - startValue) / steps)

        for step in 0..<steps {
            // Kurze Pause zwischen jedem Schritt
            try? await Task.sleep(nanoseconds: UInt64(stepDuration * 1_000_000_000))

            let nextValue: Int
            if step == steps - 1 {
                // Letzter Schritt: immer exakt auf Zielwert
                nextValue = targetValue
            } else {
                nextValue = min(targetValue, startValue + (step + 1) * increment)
            }

            await MainActor.run {
                withAnimation(.easeOut(duration: stepDuration * 0.8)) {
                    displayValue = nextValue
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("CountUpText") {
    VStack(spacing: 24) {
        // Kleine Zahl
        CountUpText(targetValue: 42, suffix: " min")

        // Mittlere Zahl
        CountUpText(targetValue: 1_250, suffix: " kcal")

        // Große Zahl (> 10.000 → startet bei 80%)
        CountUpText(targetValue: 45_320, suffix: " kg")

        // Null
        CountUpText(targetValue: 0, suffix: "")
    }
    .padding()
}
