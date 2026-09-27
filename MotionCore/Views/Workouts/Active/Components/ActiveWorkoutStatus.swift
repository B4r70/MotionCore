//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Aktive Workouts                                                  /
// Datei . . . . : ActiveWorkoutStatus.swift                                        /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 05.01.2026                                                       /
// Beschreibung  : Status-Header (Timer/Volumen/Saetze/Puls/Kcal + Balken)          /
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

/// Status-Header: Timer · Volumen · Sätze · Puls · Kcal in einer Metrik-Zeile,
/// darunter der einfarbige Fortschrittsbalken. Puls/Kcal blenden dynamisch ein,
/// sobald Live-Health-Daten vorliegen; Watch-Status hängt an der jeweils letzten
/// sichtbaren Spalte rechts.
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

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Große Zahlen: SF Pro Rounded Bold 22, tabular (§2).
    private let metricFont = Font.system(size: 22, weight: .bold, design: .rounded)

    private var hrVisible: Bool { currentHR > 0 }
    private var kcalVisible: Bool { activeCalories > 0 }

    /// Sätze wandert bei aktiver Watch (HR + Kcal sichtbar) als zweite Zeile in die
    /// Timer-Spalte, damit Volumen/HR/Kcal genug Breite behalten (Gate-Entscheidung: Option A).
    private var mergeTimerAndSets: Bool {
        hrVisible && kcalVisible
    }

    var body: some View {
        VStack(spacing: Space.s3) {
            metricRow
            progressBar
        }
        .padding(.top, Space.s1)
        .padding(.horizontal, Space.s5)
        .padding(.bottom, Space.s4)
        .background(Theme.surfaceApp)
    }

    // MARK: - Metrik-Zeile (Timer · Volumen · Sätze · Puls · Kcal)

    private var metricRow: some View {
        HStack(alignment: .top) {
            timerColumn

            if sessionVolume > 0 {
                volumeColumn
            }

            if !mergeTimerAndSets {
                setsColumn
            }

            if hrVisible {
                hrColumn
            }

            if kcalVisible {
                kcalColumn
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.24), value: sessionVolume > 0)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.24), value: hrVisible)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.24), value: kcalVisible)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.24), value: mergeTimerAndSets)
    }

    private var timerColumn: some View {
        VStack(alignment: .leading, spacing: Space.s1) {
            HStack(spacing: Space.s1) {
                Image(systemName: isPaused ? "pause.circle.fill" : "clock.fill")
                    .foregroundStyle(isPaused ? Theme.warning : Theme.accent)
                Text(formattedElapsedTime)
                    .font(metricFont)
                    .monospacedDigit()
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            if let eyebrowText = timerEyebrow {
                Text(eyebrowText)
                    .font(AppFont.eyebrow)
                    .textCase(.uppercase)
                    .tracking(0.6)
                    .foregroundStyle(isPaused ? Theme.warning : Theme.textTertiary)
                    .lineLimit(1)
            }
            if mergeTimerAndSets {
                eyebrow("\(completedSets)/\(totalSets) Sätze")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var volumeColumn: some View {
        VStack(spacing: Space.s1) {
            Text(formattedVolume)
                .font(metricFont)
                .monospacedDigit()
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            eyebrow("Volumen")
        }
        .frame(maxWidth: .infinity)
        .transition(.scale.combined(with: .opacity))
    }

    private var setsColumn: some View {
        VStack(spacing: Space.s1) {
            Text("\(completedSets)/\(totalSets)")
                .font(metricFont)
                .monospacedDigit()
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            eyebrow("Sätze")
            if !hrVisible && !kcalVisible {
                watchBadge
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private var hrColumn: some View {
        VStack(spacing: Space.s1) {
            HStack(spacing: Space.s1) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.danger)
                Text("\(Int(currentHR))")
                    .font(metricFont)
                    .monospacedDigit()
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            eyebrow("BPM")
            if !kcalVisible {
                watchBadge
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .transition(.scale.combined(with: .opacity))
    }

    private var kcalColumn: some View {
        VStack(spacing: Space.s1) {
            HStack(spacing: Space.s1) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.warning)
                Text("\(Int(activeCalories))")
                    .font(metricFont)
                    .monospacedDigit()
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            eyebrow("KCAL")
            watchBadge
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Watch-Badge (Anker: jeweils letzte sichtbare Spalte rechts)

    @ViewBuilder
    private var watchBadge: some View {
        if watchConnectionState != .hidden {
            HStack(spacing: Space.s1) {
                Image(systemName: "applewatch")
                    .font(.system(size: 10))
                Text(watchStatusText)
                    .font(AppFont.eyebrow)
                    .textCase(.uppercase)
                    .tracking(0.6)
            }
            .foregroundStyle(watchStatusColor)
        }
    }

    private var watchStatusText: String {
        switch watchConnectionState {
        case .hidden: return ""
        case .activeTracking: return "Live"
        case .connected, .disconnected: return "Watch"
        }
    }

    private var watchStatusColor: Color {
        switch watchConnectionState {
        case .hidden: return .clear
        case .activeTracking: return Theme.success
        case .connected: return Theme.accent
        case .disconnected: return Theme.textTertiary
        }
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
            .lineLimit(1)
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
                    .animation(reduceMotion ? nil : .easeOut(duration: 0.36), value: progress)
            }
        }
        .frame(height: 6)
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

#Preview("Mit Plan + Live — iPhone SE Breite (320pt)") {
    // .frame(width:) statt .previewLayout(.fixed(...)) — Letzteres ist die alte
    // PreviewProvider-API und wird vom #Preview-Macro nicht zuverlässig ausgewertet.
    ActiveWorkoutStatus(
        isPaused: false,
        formattedElapsedTime: "1:05:23",
        completedSets: 6,
        totalSets: 14,
        progress: 6.0 / 14.0,
        sessionVolume: 4300,
        currentHR: 138,
        activeCalories: 214,
        planTitle: "Push Day A",
        watchConnectionState: .activeTracking
    )
    .frame(width: 320)
    .background(Theme.surfaceApp)
}

#Preview("Nur HR (Kcal noch 0)") {
    ActiveWorkoutStatus(
        isPaused: false,
        formattedElapsedTime: "02:10",
        completedSets: 1,
        totalSets: 14,
        progress: 1.0 / 14.0,
        sessionVolume: 0,
        currentHR: 96,
        activeCalories: 0,
        planTitle: "Push Day A",
        watchConnectionState: .connected
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
