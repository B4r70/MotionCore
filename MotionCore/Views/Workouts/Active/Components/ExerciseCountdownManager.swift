//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Aktive Workouts                                                  /
// Datei . . . . : ExerciseCountdownManager.swift                                   /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 06.06.2026                                                       /
// Beschreibung  : Verwaltet den Übungs-Countdown (zeitbasierte Sätze) als          /
//                 eigene Klasse – getrennt vom RestTimerManager, damit beide        /
//                 Manager nie kollidieren. Unterstützt echtes Pause/Resume via      /
//                 Date-Anker (hintergrundsicher).                                   /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Combine
import Foundation

// MARK: - Snapshot (für SessionResumeStore)

/// Kodierbare Momentaufnahme des Countdown-Zustands — wird in Phase E2 persistiert.
struct ExerciseCountdownSnapshot: Codable {
    let targetSeconds: Int
    /// nil = pausiert (kein laufender Date-Anker)
    let endDate: Date?
    let isPaused: Bool
    let remainingSeconds: Int
    let setUUID: UUID
}

// MARK: - ExerciseCountdownManager

/// Übungs-Countdown für zeitbasierte Sätze.
///
/// - Trennung von RestTimerManager: vermeidet State-Kollision zwischen Pause-Timer
///   und Übungs-Timer.
/// - Date-Anker-Loop: Timer feuert auf RunLoop.main/.common → hintergrundsicher.
/// - Swift 6 / @MainActor: Timer-Closure nutzt `MainActor.assumeIsolated`,
///   da Timer-Closures non-isolated @Sendable sind, der RunLoop aber main ist.
@MainActor
final class ExerciseCountdownManager: ObservableObject {

    // MARK: - Published State

    @Published private(set) var remainingSeconds: Int = 0
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var isPaused: Bool = false
    @Published private(set) var isFinished: Bool = false
    /// Absolutes Enddatum — nil wenn pausiert oder idle
    @Published private(set) var endDate: Date?

    // MARK: - Nicht-published State

    /// Zieldauer des aktuellen Satzes
    private(set) var targetSeconds: Int = 0
    /// UUID des aktuellen Satzes — wird in start(seconds:setUUID:) gesetzt
    private(set) var currentSetUUID: UUID = UUID()

    // MARK: - Callback

    /// Wird aufgerufen wenn der Countdown abläuft. Haptik-Trigger liegt in Phase D (ActiveWorkoutView).
    var onFinished: (() -> Void)?

    // MARK: - Private

    private var timer: Timer?

    // MARK: - Berechnete Properties

    /// Tatsächlich abgelaufene Zeit in Sekunden — für Rückschreiben in set.duration
    var elapsedSeconds: Int { max(0, targetSeconds - remainingSeconds) }

    // MARK: - Öffentliche Methoden

    /// Startet den Countdown neu für einen Satz.
    /// - Parameters:
    ///   - seconds: Zieldauer in Sekunden
    ///   - setUUID: UUID des Satzes (für Snapshot-Abgleich in Phase E2)
    func start(seconds: Int, setUUID: UUID) {
        guard seconds > 0 else { return }

        timer?.invalidate()
        timer = nil

        targetSeconds = seconds
        currentSetUUID = setUUID
        remainingSeconds = seconds
        isPaused = false
        isFinished = false

        let end = Date().addingTimeInterval(Double(seconds))
        endDate = end
        isRunning = true

        startTimerLoop(endDate: end)
    }

    /// Friert den aktuellen Reststand ein — Timer wird gestoppt, State bleibt resumierbar.
    func pause() {
        guard isRunning, !isPaused else { return }

        // Restzeit aus aktuellem Date-Anker berechnen
        if let end = endDate {
            remainingSeconds = max(0, Int(end.timeIntervalSinceNow.rounded()))
        }

        timer?.invalidate()
        timer = nil
        endDate = nil

        isRunning = false
        isPaused = true
    }

    /// Setzt den Countdown mit dem eingefrorenen Reststand fort.
    func resume() {
        guard isPaused, remainingSeconds > 0 else { return }

        let end = Date().addingTimeInterval(Double(remainingSeconds))
        endDate = end

        isPaused = false
        isRunning = true

        startTimerLoop(endDate: end)
    }

    /// Setzt alle States zurück und konfiguriert den Manager für den nächsten Satz.
    /// Kein Auto-Start — Start erfolgt nur auf expliziten Button-Tap.
    /// - Parameters:
    ///   - seconds: Neue Zieldauer
    ///   - setUUID: UUID des neuen Satzes
    func reset(to seconds: Int, setUUID: UUID) {
        timer?.invalidate()
        timer = nil

        targetSeconds = seconds
        currentSetUUID = setUUID
        remainingSeconds = seconds
        endDate = nil
        isRunning = false
        isPaused = false
        isFinished = false
    }

    /// Neuauswertung nach Vordergrund-Rückkehr — analog RestTimerManager.
    func handleForegroundReturn() {
        guard isRunning, let end = endDate else { return }

        let remaining = max(0, Int(end.timeIntervalSinceNow.rounded()))

        if remaining > 0 {
            remainingSeconds = remaining
            startTimerLoop(endDate: end)
        } else {
            // Countdown ist während App-Pause abgelaufen
            finishCountdown()
        }
    }

    /// Invalidiert den Timer (z. B. bei onDisappear oder App-Beenden).
    func cleanup() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Snapshot / Restore

    /// Gibt nil zurück wenn der Manager idle ist (weder running noch paused).
    func snapshot() -> ExerciseCountdownSnapshot? {
        guard isRunning || isPaused else { return nil }
        return ExerciseCountdownSnapshot(
            targetSeconds: targetSeconds,
            endDate: endDate,
            isPaused: isPaused,
            remainingSeconds: remainingSeconds,
            setUUID: currentSetUUID
        )
    }

    /// Stellt den Manager aus einem Snapshot wieder her.
    /// Wenn endDate in der Vergangenheit liegt, wird direkt isFinished gesetzt.
    func restore(from snapshot: ExerciseCountdownSnapshot) {
        timer?.invalidate()
        timer = nil

        targetSeconds = snapshot.targetSeconds
        currentSetUUID = snapshot.setUUID
        remainingSeconds = snapshot.remainingSeconds

        if snapshot.isPaused {
            // Pausiert — kein Timer-Loop nötig
            endDate = nil
            isRunning = false
            isPaused = true
            isFinished = false
        } else if let savedEnd = snapshot.endDate {
            let remaining = Int(savedEnd.timeIntervalSinceNow.rounded())
            if remaining > 0 {
                // Timer läuft noch
                endDate = savedEnd
                remainingSeconds = remaining
                isRunning = true
                isPaused = false
                isFinished = false
                startTimerLoop(endDate: savedEnd)
            } else {
                // Abgelaufen während App nicht aktiv war
                remainingSeconds = 0
                endDate = nil
                isRunning = false
                isPaused = false
                isFinished = true
                // Kein onFinished-Aufruf beim Restore — kein nachträglicher Haptik-Burst
            }
        }
    }

    // MARK: - Private Methoden

    private func startTimerLoop(endDate end: Date) {
        timer?.invalidate()

        let newTimer = Timer(timeInterval: 1.0, repeats: true) { [weak self] t in
            // Timer-Closures sind non-isolated @Sendable; RunLoop feuert auf main.
            MainActor.assumeIsolated {
                guard let self else {
                    t.invalidate()
                    return
                }
                // Identitätscheck: veraltete Timer ignorieren
                guard t === self.timer else {
                    t.invalidate()
                    return
                }

                let remaining = Int(end.timeIntervalSinceNow.rounded())

                if remaining > 0 {
                    self.remainingSeconds = remaining
                } else {
                    self.finishCountdown()
                }
            }
        }
        RunLoop.main.add(newTimer, forMode: .common)
        timer = newTimer
    }

    /// Setzt den finalen Zustand und ruft onFinished auf.
    private func finishCountdown() {
        timer?.invalidate()
        timer = nil
        remainingSeconds = 0
        endDate = nil
        isRunning = false
        isPaused = false
        isFinished = true
        onFinished?()
    }
}
