//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Aktive Workouts                                                  /
// Datei . . . . : ActiveWorkoutStatus.swift                                        /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 05.01.2026                                                       /
// Beschreibung  : Status-Header (Timer/Volumen/Saetze + Balken + Live-Chips)       /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// Watch-Verbindungsstatus für den ⌚-Indikator in der Status-Bar
enum WatchConnectionState {
    case hidden         // Kein Icon (Watch-Tracking nicht aktiv)
    case connected      // Verbunden (Akzent)
    case activeTracking // Aktives HR-Tracking (Erfolg)
    case disconnected   // Verbindung unterbrochen (grau)
}

// MARK: - ActiveWorkoutStatus (Calm 2026 · §4.1)

/// Status-Header: drei Spalten (Timer · Volumen · Sätze), einfarbiger Fortschritts-
/// balken und Live-Health-Chip-Zeile (HR · Kalorien · Watch-LIVE).
struct ActiveWorkoutStatus: View {
    let isPaused: Bool
    let formattedElapsedTime: String
    let completedSets: Int
    let totalSets: Int
    let progress: Double
    let sessionVolume: Double
    var currentHR: Double = 0
    var activeCalories: Double = 0
    let planTitle: String?
    var watchConnectionState: WatchConnectionState = .hidden

    // Große Zahlen: SF Pro Rounded Bold 22, tabular (§2).
    private let metricFont = Font.system(size: 22, weight: .bold, design: .rounded)

    private var showLiveChips: Bool {
        currentHR > 0 || activeCalories > 0 || watchConnectionState != .hidden
    }

    var body: some View {
        VStack(spacing: Space.s3) {
            metricRow
            progressBar
            if showLiveChips { liveChipsRow }
        }
        .padding(.top, Space.s1)
        .padding(.horizontal, Space.s5)
        .padding(.bottom, Space.s4)
        .background(Theme.surfaceApp)
    }

    // MARK: - Metrik-Zeile (3 Spalten)

    private var metricRow: some View {
        HStack(alignment: .top) {
            // Timer (links)
            VStack(alignment: .leading, spacing: Space.s1) {
                HStack(spacing: Space.s1) {
                    Image(systemName: isPaused ? "pause.circle.fill" : "clock.fill")
                        .foregroundStyle(isPaused ? Theme.warning : Theme.accent)
                    Text(formattedElapsedTime)
                        .font(metricFont)
                        .monospacedDigit()
                        .foregroundStyle(Theme.textPrimary)
                }
                if let eyebrow = timerEyebrow {
                    Text(eyebrow)
                        .font(AppFont.eyebrow)
                        .textCase(.uppercase)
                        .tracking(0.6)
                        .foregroundStyle(isPaused ? Theme.warning : Theme.textTertiary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Volumen (Mitte) — nur > 0
            if sessionVolume > 0 {
                VStack(spacing: Space.s1) {
                    Text(formattedVolume)
                        .font(metricFont)
                        .monospacedDigit()
                        .foregroundStyle(Theme.textPrimary)
                    eyebrow("Volumen")
                }
                .frame(maxWidth: .infinity)
                .transition(.scale.combined(with: .opacity))
            }

            // Sätze (rechts)
            VStack(spacing: Space.s1) {
                Text("\(completedSets)/\(totalSets)")
                    .font(metricFont)
                    .monospacedDigit()
                    .foregroundStyle(Theme.textPrimary)
                eyebrow("Sätze")
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .animation(.easeInOut(duration: 0.24), value: sessionVolume > 0)
    }

    private var timerEyebrow: String? {
        if isPaused { return "Pausiert" }
        return planTitle
    }

    private func eyebrow(_ text: String) -> some View {
        Text(text)
            .font(AppFont.eyebrow)
            .textCase(.uppercase)
            .tracking(0.6)
            .foregroundStyle(Theme.textTertiary)
    }

    // MARK: - Fortschrittsbalken (einfarbig, kein Gradient)

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.surfaceSunken).frame(height: 6)
                Capsule()
                    .fill(Theme.accent)
                    .frame(width: geo.size.width * max(0, min(1, progress)), height: 6)
                    .animation(.easeOut(duration: 0.36), value: progress)
            }
        }
        .frame(height: 6)
    }

    // MARK: - Live-Health-Chips

    private var liveChipsRow: some View {
        HStack(spacing: Space.s2) {
            if currentHR > 0 {
                metricPill(icon: "heart.fill", iconColor: Theme.danger,
                           value: "\(Int(currentHR))", unit: "bpm")
            }
            if activeCalories > 0 {
                metricPill(icon: "flame.fill", iconColor: Theme.warning,
                           value: "\(Int(activeCalories))", unit: "kcal")
            }
            Spacer()
            watchLivePill
        }
    }

    private func metricPill(icon: String, iconColor: Color, value: String, unit: String) -> some View {
        HStack(spacing: Space.s1) {
            Image(systemName: icon)
                .font(AppFont.caption)
                .foregroundStyle(iconColor)
            Text(value)
                .font(AppFont.callout)
                .fontWeight(.semibold)
                .monospacedDigit()
                .foregroundStyle(Theme.textPrimary)
            Text(unit)
                .font(AppFont.caption)
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(.horizontal, Space.s3)
        .frame(height: 30)
        .background(Capsule().fill(Theme.surfaceCard))
        .overlay(Capsule().stroke(Theme.line, lineWidth: 1))
    }

    @ViewBuilder
    private var watchLivePill: some View {
        switch watchConnectionState {
        case .hidden:
            EmptyView()
        case .activeTracking:
            watchPill(text: "Live", color: Theme.success)
        case .connected:
            watchPill(text: "Watch", color: Theme.accent)
        case .disconnected:
            watchPill(text: "Watch", color: Theme.textTertiary)
        }
    }

    private func watchPill(text: String, color: Color) -> some View {
        HStack(spacing: Space.s1) {
            Image(systemName: "applewatch")
                .font(AppFont.caption)
            Text(text)
                .font(AppFont.eyebrow)
                .textCase(.uppercase)
                .tracking(0.6)
        }
        .foregroundStyle(color)
        .padding(.horizontal, Space.s3)
        .frame(height: 30)
        .background(Capsule().fill(color.opacity(0.12)))
    }

    // MARK: - Formatierung

    private var formattedVolume: String {
        if sessionVolume >= 1000 {
            return String(format: "%.1f t", sessionVolume / 1000)
        } else {
            return String(format: "%.0f kg", sessionVolume)
        }
    }
}

// MARK: - Preview

#Preview("Mit Plan + Live") {
    ActiveWorkoutStatus(
        isPaused: false,
        formattedElapsedTime: "24:18",
        completedSets: 6,
        totalSets: 14,
        progress: 6.0 / 14.0,
        sessionVolume: 4300,
        currentHR: 138,
        activeCalories: 214,
        planTitle: "Push Day A",
        watchConnectionState: .activeTracking
    )
    .background(Theme.surfaceApp)
}

#Preview("Pausiert / ohne Live") {
    ActiveWorkoutStatus(
        isPaused: true,
        formattedElapsedTime: "05:00",
        completedSets: 1,
        totalSets: 4,
        progress: 0.25,
        sessionVolume: 0,
        planTitle: nil
    )
    .background(Theme.surfaceApp)
}
