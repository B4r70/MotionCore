//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Session-Management                                               /
// Datei . . . . : RestTimerManager.swift                                           /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 12.03.2026                                                       /
// Beschreibung  : Verwaltet den Pause-Timer zwischen Sätzen als Klasse,            /
//                 damit Timer-Closures zuverlässig auf den State zugreifen –       /
//                 auch nach SwiftUI-Redraws und Hintergrund-Rückkehr.              /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation
import SwiftUI
import Combine

// MARK: - Rest Timer Manager

/// Kapselt die Rest-Timer-Logik in einer Klasse statt in @State-Properties
/// eines SwiftUI-Structs. Timer-Closures in Structs capturen eine eingefrorene
/// Kopie von `self` – in einer Klasse zeigt `self` immer auf dasselbe Objekt.
///
/// WICHTIG: Dieser Manager feuert KEINE Live-Activity-Updates selbst.
/// Die View nutzt einen Debounce-Mechanismus für Activity-Updates.
class RestTimerManager: ObservableObject {

    // MARK: - Published Properties (für UI-Binding)

    /// Verbleibende Sekunden – treibt die Anzeige in RestTimerCard
    @Published private(set) var remainingSeconds: Int = 0

    /// Ist gerade ein Rest-Timer aktiv?
    @Published private(set) var isResting: Bool = false

    /// Absoluter Zeitpunkt, wann der Rest-Timer endet (für Live Activity)
    @Published private(set) var restEndDate: Date?
    @Published private(set) var restStartDate: Date?

    // MARK: - Callback

    /// Wird aufgerufen wenn der Timer abläuft (für Haptic Feedback etc.)
    var onTimerFinished: (() -> Void)?

    // MARK: - Private

    private var timer: Timer?

    // MARK: - Public Methods

    /// Startet den Rest-Timer mit der angegebenen Dauer in Sekunden
    func start(seconds: Int) {
        guard seconds > 0 else { return }

        let end = Date().addingTimeInterval(Double(seconds))
        restStartDate = Date()
        restEndDate = end
        remainingSeconds = seconds
        // isResting wird ZULETZT gesetzt, damit restEndDate bereits steht
        // wenn onChange(of: isResting) in der View feuert und den
        // finalen Live-Activity-State zusammenbaut.
        isResting = true

        startTimerLoop(endDate: end)
    }

    /// Stoppt den Rest-Timer und setzt alles zurück
    func stop() {
        timer?.invalidate()
        timer = nil
        remainingSeconds = 0
        restStartDate = nil
        restEndDate = nil
        isResting = false
    }

    /// Überspringt den Rest-Timer
    func skip() {
        stop()
    }

    /// Passt die verbleibende Zeit um delta Sekunden an (+/-)
    func adjust(delta: Int) {
        guard let currentEnd = restEndDate else { return }

        let newEnd = currentEnd.addingTimeInterval(Double(delta))
        let clampedRemaining = max(5, min(300, Int(newEnd.timeIntervalSinceNow)))
        let adjustedEnd = Date().addingTimeInterval(Double(clampedRemaining))

        restEndDate = adjustedEnd
        remainingSeconds = clampedRemaining

        // Timer neu starten mit neuem Enddatum
        startTimerLoop(endDate: adjustedEnd)
    }

    /// Stellt den Timer nach App-Start oder Hintergrund-Rückkehr wieder her
    func restore(endDate: Date) {
        let remaining = max(0, Int(endDate.timeIntervalSinceNow.rounded()))

        if remaining > 0 {
            restEndDate = endDate
            remainingSeconds = remaining
            isResting = true
            startTimerLoop(endDate: endDate)
        } else {
            stop()
        }
    }

    /// Wird aufgerufen wenn die App in den Vordergrund zurückkehrt
    func handleForegroundReturn() {
        guard isResting, let end = restEndDate else { return }

        let remaining = max(0, Int(end.timeIntervalSinceNow.rounded()))

        if remaining > 0 {
            remainingSeconds = remaining
            startTimerLoop(endDate: end)
        } else {
            stop()
            onTimerFinished?()
        }
    }

    /// Räumt den Timer auf (z.B. bei onDisappear)
    func cleanup() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Private Methods

    private func startTimerLoop(endDate end: Date) {
        timer?.invalidate()

        let newTimer = Timer(timeInterval: 1.0, repeats: true) { [weak self] t in
            guard let self else {
                t.invalidate()
                return
            }

            guard t === self.timer else {
                t.invalidate()
                return
            }

            let remaining = Int(end.timeIntervalSinceNow.rounded())

            if remaining > 0 {
                self.remainingSeconds = remaining
            } else {
                self.stop()
                self.onTimerFinished?()
            }
        }
        RunLoop.main.add(newTimer, forMode: .common)
        timer = newTimer
    }
}
