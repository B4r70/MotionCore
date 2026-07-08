//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Aktive Workouts                                                  /
// Datei . . . . : ActiveTimeSetContent.swift                                       /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 06.06.2026                                                       /
// Beschreibung  : Card-Inhalt für zeitbasierte Sätze (Time-Zweig von              /
//                 ActiveSetCard). Ausgelagert damit ActiveSetCard unter            /
//                 400 Zeilen bleibt.                                               /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - ActiveTimeSetContent

/// Inhalt des Time-Zweigs: Ring-Countdown, Pace-Chip und Steuerbuttons.
/// Wird von `ActiveSetCard.timeBasedContent` eingebettet.
struct ActiveTimeSetContent: View {
    let set: ExerciseSet
    @ObservedObject var countdown: ExerciseCountdownManager
    let onComplete: (ExerciseSet) -> Void

    /// Abschließen nur wenn pausiert oder abgelaufen — nicht im Idle und nicht bei laufendem Countdown
    private var canComplete: Bool {
        countdown.isPaused || countdown.isFinished
    }

    var body: some View {
        Group {
            // Ring + Mono-Ziffern — Countdown-State für Label und Farblogik übergeben
            ExerciseCountdownTimerView(
                remainingSeconds: countdown.remainingSeconds,
                targetSeconds: countdown.targetSeconds,
                isRunning: countdown.isRunning,
                isPaused: countdown.isPaused
            )

            // Pace-Chip aus set.notes (nur sichtbar wenn vorhanden)
            if !set.notes.isEmpty {
                Text(set.notes)
                    .font(AppFont.callout)
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.horizontal, Space.s3)
                    .padding(.vertical, Space.s1)
                    .background(Theme.surfaceSunken, in: Capsule())
            }

            Rectangle()
                .fill(Theme.lineSoft)
                .frame(height: 1)

            // Primär-Toggle: Start / Pause / Fortsetzen
            countdownToggleButton

            // Satz abschließen — aktiv nur wenn Countdown pausiert oder abgelaufen
            Button {
                set.duration = countdown.elapsedSeconds
                onComplete(set)
            } label: {
                Label("Satz abschließen", systemImage: "checkmark")
            }
            .buttonStyle(.mcPrimary)
            .disabled(!canComplete)
        }
    }

    // MARK: - Primär-Toggle

    /// Wechselt zwischen Start / Pause / Fortsetzen.
    /// Nach Ablauf (isFinished): zeigt Start (Neustart), „Satz abschließen" ist aktiv.
    @ViewBuilder
    private var countdownToggleButton: some View {
        if countdown.isFinished {
            // Abgelaufen → „Fertig", kein Neustart möglich
            Label("Fertig", systemImage: "checkmark.circle")
                .font(AppFont.callout)
                .fontWeight(.bold)
                .foregroundStyle(Theme.textSecondary)
                .padding(.horizontal, Space.s5)
                .padding(.vertical, Space.s2)
                .background(Theme.surfaceSunken, in: Capsule())
        } else if !countdown.isRunning && !countdown.isPaused {
            // Idle → Start
            Button {
                countdown.start(seconds: set.duration, setUUID: set.setUUID)
            } label: {
                Label("Start", systemImage: "play.fill")
                    .font(AppFont.callout)
                    .fontWeight(.bold)
                    .foregroundStyle(Theme.success)
                    .padding(.horizontal, Space.s5)
                    .padding(.vertical, Space.s2)
                    .background(Theme.success.opacity(0.15), in: Capsule())
            }
        } else if countdown.isRunning {
            // Läuft → Pause
            Button {
                countdown.pause()
            } label: {
                Label("Pause", systemImage: "pause.fill")
                    .font(AppFont.callout)
                    .fontWeight(.bold)
                    .foregroundStyle(Theme.warning)
                    .padding(.horizontal, Space.s5)
                    .padding(.vertical, Space.s2)
                    .background(Theme.warning.opacity(0.15), in: Capsule())
            }
        } else if countdown.isPaused {
            // Pausiert → Fortsetzen
            Button {
                countdown.resume()
            } label: {
                Label("Fortsetzen", systemImage: "play.fill")
                    .font(AppFont.callout)
                    .fontWeight(.bold)
                    .foregroundStyle(Theme.accent)
                    .padding(.horizontal, Space.s5)
                    .padding(.vertical, Space.s2)
                    .background(Theme.accent.opacity(0.15), in: Capsule())
            }
        }
    }
}
