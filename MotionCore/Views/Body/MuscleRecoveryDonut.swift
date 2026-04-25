//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Views / Body                                                     /
// Datei . . . . : MuscleRecoveryDonut.swift                                        /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 25.04.2026                                                       /
// Beschreibung  : Donut-Visualisierung des Muskelgruppen-Erholungs-Scores          /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - MuscleRecoveryDonut

/// Kreisring-Visualisierung für einen einzelnen Muskelgruppen-Erholungs-Score.
/// Trainierte Muskeln zeigen farbigen Fortschrittsring (rot → grün via recoveryColor).
/// Untrainierte Muskeln zeigen einen grauen vollen Ring.
struct MuscleRecoveryDonut: View {

    /// Erholungsprozent 0–100
    let percent: Double
    /// Ob die Muskelgruppe im Analysezeitraum trainiert wurde
    let wasTrained: Bool
    /// Kurzname der Muskelgruppe für die innere Beschriftung
    let label: String
    /// Außendurchmesser des Donuts in Points
    let size: CGFloat

    // Linienstärke relativ zur Größe
    private var lineWidth: CGFloat { size * 0.13 }

    // Trimm-Endpunkt: 0.0–1.0
    private var trimEnd: CGFloat { CGFloat(min(max(percent / 100.0, 0.0), 1.0)) }

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                // Hintergrundring (immer voller Kreis)
                Circle()
                    .stroke(
                        Color.secondary.opacity(wasTrained ? 0.2 : 0.3),
                        lineWidth: lineWidth
                    )

                // Vordergrundring (nur bei trainierten Muskeln farbig)
                if wasTrained {
                    Circle()
                        .trim(from: 0, to: trimEnd)
                        .stroke(
                            recoveryColor(percent: percent),
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                        )
                        // Startpunkt oben (–90°)
                        .rotationEffect(.degrees(-90))
                }

                // Innere Beschriftung
                VStack(spacing: 1) {
                    Text("\(Int(percent.rounded()))")
                        .font(.system(size: size * 0.22, weight: .bold, design: .rounded))
                        .foregroundStyle(wasTrained ? recoveryColor(percent: percent) : .secondary)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)

                    Text(label)
                        .font(.system(size: size * 0.14))
                        .foregroundStyle(.secondary)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }
            }
            .frame(width: size, height: size)
        }
    }
}

// MARK: - Preview

#Preview("MuscleRecoveryDonut") {
    HStack(spacing: 16) {
        // Trainiert, gut erholt
        MuscleRecoveryDonut(percent: 85, wasTrained: true, label: "Brust", size: 80)
        // Trainiert, wenig erholt
        MuscleRecoveryDonut(percent: 32, wasTrained: true, label: "Rücken", size: 80)
        // Nicht trainiert
        MuscleRecoveryDonut(percent: 100, wasTrained: false, label: "Arme", size: 80)
        // Klein (compact style)
        MuscleRecoveryDonut(percent: 61, wasTrained: true, label: "Beine", size: 60)
    }
    .padding()
    .environmentObject(AppSettings.shared)
}
