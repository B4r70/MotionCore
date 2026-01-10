//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Workout                                                          /
// Datei . . . . : RestTimerCard.swift                                              /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 01.01.2026                                                       /
// Beschreibung  : Großer Pause-Timer zwischen Sätzen                               /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct RestTimerCard: View {
    @EnvironmentObject private var appSettings: AppSettings
    
    let remainingSeconds: Int
    let targetSeconds: Int
    let onSkip: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            // "Pause" Label
            Text("Pause")
                .font(.title2.bold())
                .foregroundStyle(.secondary)
            
            // Großer Pausen-Timer (damit die Zeit vom Boden lesbar ist!)
            Text(formatRestTime(remainingSeconds))
                .font(.system(size: 96, weight: .bold, design: .rounded))
                .foregroundStyle(remainingSeconds > 10 ? Color.primary : Color.orange)
                .monospacedDigit()
                .contentTransition(.numericText())
            
            // Fortschrittsbalken
            progressBar
            
            // Info-Text
            Text("Nächster Satz bereit in \(remainingSeconds) Sekunden")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            // Skip Button
            Button {
                onSkip()
            } label: {
                HStack {
                    Image(systemName: "forward.fill")
                    Text("Pause überspringen")
                        .font(.headline)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(.blue, in: RoundedRectangle(cornerRadius: 16))
            }
        }
        .glassCard()
        .scrollViewContentPadding()
    }
    
    // MARK: - Fortschrittsbalken
    
    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Hintergrund
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.primary.opacity(0.1))
                    .frame(height: 12)
                
                // Fortschritt (läuft von voll nach leer)
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: progressGradientColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(
                        width: geo.size.width * progress,
                        height: 12
                    )
                    .animation(.linear(duration: 1.0), value: remainingSeconds)
            }
        }
        .frame(height: 12)
    }
    
    // MARK: - Berechnete Properties
    
    private var progress: Double {
        guard targetSeconds > 0 else { return 0 }
        return Double(remainingSeconds) / Double(targetSeconds)
    }
    
    // Farbverlauf ändert sich je nach verbleibender Zeit
    private var progressGradientColors: [Color] {
        if remainingSeconds > 30 {
            return [.blue, .green]
        } else if remainingSeconds > 10 {
            return [.green, .orange]
        } else {
            return [.orange, .red]
        }
    }
    
    // MARK: - Hilfsfunktionen
    
    private func formatRestTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

// MARK: - Preview

#Preview("Rest Timer Card") {
    ZStack {
        AnimatedBackground(showAnimatedBlob: true)
        
        VStack(spacing: 20) {
            // 90 Sekunden
            RestTimerCard(
                remainingSeconds: 90,
                targetSeconds: 90,
                onSkip: {}
            )
            
            // 30 Sekunden
            RestTimerCard(
                remainingSeconds: 30,
                targetSeconds: 90,
                onSkip: {}
            )
            
            // 5 Sekunden (kritisch)
            RestTimerCard(
                remainingSeconds: 5,
                targetSeconds: 90,
                onSkip: {}
            )
        }
        .padding()
    }
    .environmentObject(AppSettings.shared)
}
