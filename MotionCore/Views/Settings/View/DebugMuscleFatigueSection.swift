//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Einstellungen                                                    /
// Datei . . . . : DebugMuscleFatigueSection.swift                                  /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 09.06.2026                                                       /
// Beschreibung  : Debug-Sektion: Roh-Fatigue pro Muskel (read-only),               /
//                 Grundlage für Konstanten-Kalibrierung (nur im DEBUG-Build)       /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
#if DEBUG
import SwiftUI
import SwiftData

struct DebugMuscleFatigueSection: View {

    // MARK: - Daten

    @Query(sort: \StrengthSession.date, order: .reverse)
    private var sessions: [StrengthSession]

    // MARK: - Computed

    private var fatigueScores: [DetailedMuscleRecovery] {
        let analysis = MuscleRecoveryCalcEngine.analyze(sessions: sessions)
        return analysis.detailedScores
            .sorted { $0.totalFatigueScore > $1.totalFatigueScore }
    }

    // MARK: - Body

    var body: some View {
        let scores = fatigueScores
        Section {
            if scores.isEmpty {
                Text("Kein Training in den letzten 14 Tagen.")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            } else {
                ForEach(scores) { score in
                    HStack {
                        Text(score.muscle.displayName)
                            .font(.caption)
                        Spacer()
                        Text(String(format: "%.2f", score.totalFatigueScore))
                            .foregroundStyle(.secondary)
                            .font(.caption.monospacedDigit())
                    }
                }
            }
        } header: {
            Label("Debug — Muskel-Fatigue", systemImage: "ant")
                .foregroundStyle(.orange)
        } footer: {
            Text("Roh-Fatigue pro Muskel (letzte 14 Tage, expon. Decay). Kalibrierungsgrundlage für fatigueSaturation/volumeSaturation. Harte Sessions sollten ≥ \(String(format: "%.0f", MuscleRecoveryCalcEngine.fatigueSaturation)) erreichen.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        List {
            DebugMuscleFatigueSection()
        }
        .navigationTitle("Debug")
    }
    .modelContainer(PreviewData.sharedContainer)
    .environmentObject(AppSettings.shared)
}
#endif
