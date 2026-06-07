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
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.ultraThinMaterial, in: Capsule())
            }

            GlassDivider()

            // Primär-Toggle: Start / Pause / Fortsetzen
            countdownToggleButton

            // Satz abschließen — aktiv nur wenn Countdown pausiert oder abgelaufen
            Button {
                set.duration = countdown.elapsedSeconds
                onComplete(set)
            } label: {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Satz abschließen")
                        .font(.headline)
                }
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    canComplete ? Color.green : Color.green.opacity(0.4),
                    in: RoundedRectangle(cornerRadius: 16)
                )
            }
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
                .font(.subheadline.bold())
                .foregroundStyle(Color.secondary)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.secondary.opacity(0.1), in: Capsule())
        } else if !countdown.isRunning && !countdown.isPaused {
            // Idle → Start
            Button {
                countdown.start(seconds: set.duration, setUUID: set.setUUID)
            } label: {
                Label("Start", systemImage: "play.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.green)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.green.opacity(0.15), in: Capsule())
            }
        } else if countdown.isRunning {
            // Läuft → Pause
            Button {
                countdown.pause()
            } label: {
                Label("Pause", systemImage: "pause.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.orange)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.orange.opacity(0.15), in: Capsule())
            }
        } else if countdown.isPaused {
            // Pausiert → Fortsetzen
            Button {
                countdown.resume()
            } label: {
                Label("Fortsetzen", systemImage: "play.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.blue)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue.opacity(0.15), in: Capsule())
            }
        }
    }
}
