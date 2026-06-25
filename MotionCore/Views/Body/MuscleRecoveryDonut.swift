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

// MARK: - recoveryTint

/// Theme-Token-Erholungsfarbe: grün (≥85 %), amber (≥50 %), rot (<50 %).
/// Liegt in dieser Datei zur Wahrung des Datei-Scopes; idealerweise neben
/// `recoveryColor` in MuscleRecoveryUI.swift.
func recoveryTint(_ p: Double) -> Color {
    if p >= 85 { return Theme.success }
    if p >= 50 { return Theme.warning }
    return Theme.danger
}

// MARK: - MuscleRecoveryDonut

/// Kreisring-Visualisierung für einen einzelnen Muskelgruppen-Erholungs-Score.
/// Trainierte Muskeln zeigen farbigen Fortschrittsring (recoveryTint, Theme-Tokens).
/// Untrainierte Muskeln zeigen einen gedämpften Ring (Theme.textTertiary).
/// Init-Signatur (percent/wasTrained/label/size) unverändert.
struct MuscleRecoveryDonut: View {

    /// Erholungsprozent 0–100
    let percent: Double
    /// Ob die Muskelgruppe im Analysezeitraum trainiert wurde
    let wasTrained: Bool
    /// Kurzname der Muskelgruppe für die innere Beschriftung
    let label: String
    /// Außendurchmesser des Donuts in Points
    let size: CGFloat

    // Linienstärke relativ zur Größe (an ProgressRing stroke: weitergegeben)
    private var lineWidth: CGFloat { size * 0.13 }

    var body: some View {
        ProgressRing(
            progress: percent / 100.0,
            size: size,
            stroke: lineWidth,
            tint: wasTrained ? recoveryTint(percent) : Theme.textTertiary,
            centerValue: "\(Int(percent.rounded()))",
            centerLabel: label
        )
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
