//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Views / Shared / Redesign                                        /
// Datei . . . . : ProgressRing.swift                                               /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 25.06.2026                                                       /
// Beschreibung  : Calm-2026 Fortschritts-Ring (Hero+Mini vereint)                  /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - ProgressRing (DESIGN.md §9)

/// Konfigurierbarer Fortschritts-Ring — ersetzt MCHeroRing + MCMiniRing.
/// Track `surfaceSunken`, Füllung `tint` (Default `accent`, einfarbig, kein
/// Gradient), animierte Füllung. Optionaler Zentrumstext (Wert/Label/SubText).
struct ProgressRing: View {
    let progress: Double          // 0…1
    var size: CGFloat = 170
    var stroke: CGFloat = 13
    var tint: Color = Theme.accent
    var centerValue: String? = nil
    var centerLabel: String? = nil
    var centerSubText: String? = nil

    @State private var animatedProgress: Double = 0

    private var hasCenter: Bool {
        centerValue != nil || centerLabel != nil || centerSubText != nil
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.surfaceSunken, lineWidth: stroke)

            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(tint, style: StrokeStyle(lineWidth: stroke, lineCap: .round))
                .rotationEffect(.degrees(-90))

            if hasCenter {
                VStack(spacing: Space.s1) {
                    if let centerValue {
                        Text(centerValue)
                            .font(.system(size: size * 0.28, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(tint)
                    }
                    if let centerLabel {
                        Text(centerLabel)
                            .font(.system(size: size * 0.10, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    if let centerSubText {
                        Text(centerSubText)
                            .font(.system(size: size * 0.09))
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.easeOut(duration: 0.36)) {
                animatedProgress = max(0, min(1, progress))
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.easeInOut(duration: 0.24)) {
                animatedProgress = max(0, min(1, newValue))
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: Space.s8) {
        ProgressRing(progress: 0.78, tint: Theme.success,
                     centerValue: "78", centerLabel: "Bereit", centerSubText: "Erholung")

        HStack(spacing: Space.s5) {
            ProgressRing(progress: 0.0, size: 62, stroke: 6, centerValue: "0", centerLabel: "Brust")
            ProgressRing(progress: 0.55, size: 62, stroke: 6, tint: Theme.success, centerValue: "55", centerLabel: "Rücken")
            ProgressRing(progress: 0.92, size: 62, stroke: 6, tint: Theme.warning, centerValue: "92", centerLabel: "Beine")
        }
    }
    .padding()
    .background(Theme.surfaceApp)
}
