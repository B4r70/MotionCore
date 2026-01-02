//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Workout                                                          /
// Datei . . . . : ActiveWorkoutView.swift                                          /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 27.12.2025                                                       /
// Beschreibung  : Live-Tracking View während eines Krafttrainings                 /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftData
import SwiftUI

struct ActiveWorkoutView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appSettings: AppSettings
    @EnvironmentObject private var sessionManager: ActiveSessionManager // Session-Manager

    @Bindable var session: StrengthSession

    // Timer - Verwendet den SessionManager
    // Lokaler State nur noch für UI-Updates
    @State private var localTimer: Timer?

    // UI States
    @State private var showFinishAlert = false
    @State private var showCancelAlert = false
    @State private var selectedSetForEdit: ExerciseSet?
    @State private var selectedExerciseIndex: Int? = nil  // Manuell ausgewählte Übung

    // Pause-Timer States
    @State private var restTimerSeconds: Int = 0
    @State private var restTimer: Timer?
    @State private var isResting: Bool = false

    private let hapticGenerator = UIImpactFeedbackGenerator(style: .light)

    // Aktueller Satz
    // Falls eine Übung manuell ausgewählt wurde, verwende diese!
    // Ansonsten automatisch den nächsten unerledigten Satz
    private var currentSet: ExerciseSet? {
        if let selectedIndex = selectedExerciseIndex {
            let grouped = session.groupedSets
            guard selectedIndex < grouped.count else { return nil }
            return grouped[selectedIndex].first { !$0.isCompleted }
        }
        return session.nextUncompletedSet
    }

    // Index der aktuellen Übung für Highlighting
    private var currentExerciseIndex: Int {
        if let selectedIndex = selectedExerciseIndex {
            return selectedIndex
        }

        guard let current = session.nextUncompletedSet else { return 0 }
        let grouped = session.groupedSets
        return grouped.firstIndex { group in
            group.contains { $0.id == current.id }
        } ?? 0
    }

    // Zuletzt abgeschlossener Satz (für Rest-Timer)
    private var lastCompletedSet: ExerciseSet? {
        // Finde den zuletzt abgeschlossenen Satz (für die Pausenzeit)
        return session.exerciseSets
            .filter { $0.isCompleted }
            .last
    }

    var body: some View {
        ZStack {
            AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)

            VStack(spacing: 0) {
                // Header mit Timer und Fortschritt
                headerSection

                // Hauptinhalt
                ScrollView {
                    VStack(spacing: 20) {
                        // Unterscheide zwischen Pause, aktuellem Satz und Training komplett
                        if isResting, let completedSet = lastCompletedSet {
                            RestTimerCard(
                                remainingSeconds: restTimerSeconds,
                                targetSeconds: completedSet.restSeconds,
                                onSkip: skipRest
                            )
                        } else if let current = currentSet {
                            currentSetCard(current)
                        } else if isSelectedExerciseComplete, !session.allSetsCompleted {
                            // Einzelne Übung ist komplett, aber Training noch nicht
                            exerciseCompletedCard
                        } else {
                            // Komplettes Training ist fertig
                            allCompletedCard
                        }

                        // Übungen-Übersicht
                        exercisesOverview
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .padding(.bottom, 100)
                }
                .scrollIndicators(.hidden)
            }

            // Bottom Action Bar
            VStack {
                Spacer()
                bottomActionBar
            }
        }
        .navigationTitle(session.planName ?? "Training")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    // Prüfen ob Timer läuft
                    if sessionManager.isPaused {
                        // Timer pausiert â†’ Direkt zurück ohne Alert
                        handlePausedExit()
                    } else {
                        // Timer läuft â†’ Alert zeigen
                        showCancelAlert = true
                    }
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .onAppear {
            setupSession()
            hapticGenerator.prepare()
        }
        .onChange(of: selectedExerciseIndex) { oldValue, newValue in
            // Speichere den Index im SessionManager
            sessionManager.setSelectedExerciseIndex(newValue)
        }
        .onDisappear {
            cleanupTimer()
        }
        .alert("Training läuft noch", isPresented: $showCancelAlert) {
            Button("Pausieren") {
                handlePauseAndExit()
            }
            Button("Verwerfen", role: .destructive) {
                cancelWorkout()
            }
            Button("Abbrechen", role: .cancel) {
                    // Bleibt in ActiveWorkoutView - nichts tun
            }
        } message: {
            Text("Möchtest du das Training pausieren oder verwerfen?")
        }
        .alert("Training beenden?", isPresented: $showFinishAlert) {
            Button("Weiter trainieren", role: .cancel) {}
            Button("Beenden", role: .none) {
                finishWorkout()
            }
        } message: {
            Text("Du hast \(session.completedSets) von \(session.totalSets) Sätzen abgeschlossen.")
        }
        .sheet(item: $selectedSetForEdit) { set in
            SetEditSheet(set: set, session: session)
                .environmentObject(appSettings)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            // Timer und Fortschritt
            HStack {
                // Timer - Verwendet SessionManager
                HStack(spacing: 8) {
                    Image(systemName: sessionManager.isPaused ? "pause.circle.fill" : "clock.fill")
                        .foregroundStyle(sessionManager.isPaused ? .orange : .blue)

                    Text(sessionManager.formattedElapsedTime)
                        .font(.title2.bold().monospacedDigit())
                        .foregroundStyle(.primary)

                    // Pausiert-Indikator
                    if sessionManager.isPaused {
                        Text("(Pausiert)")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }

                Spacer()

                // Fortschritt
                HStack(spacing: 8) {
                    Text("\(session.completedSets)/\(session.totalSets)")
                        .font(.title2.bold())
                        .foregroundStyle(.primary)

                    Text("Sätze")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            // Fortschrittsbalken
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.primary.opacity(0.1))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .green],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * session.progress, height: 8)
                        .animation(.easeInOut, value: session.progress)
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    // MARK: - Aktueller Satz Card

    private func currentSetCard(_ set: ExerciseSet) -> some View {
        VStack(spacing: 20) {
            // Übungs-Info
            HStack(spacing: 16) {
                ExerciseGifView(assetName: set.exerciseGifAssetName, size: 80)

                VStack(alignment: .leading, spacing: 4) {
                    // SetKind Badge (falls nicht Arbeitssatz)
                    if set.setKind != .work {
                        Text(set.setKind.description.uppercased())
                            .font(.caption.bold())
                            .foregroundStyle(set.setKind.color)
                    }

                    Text(set.exerciseName)
                        .font(.title2.bold())
                        .foregroundStyle(.primary)

                    Text("Satz \(set.setNumber) von \(setsForCurrentExercise)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            .glassDivider()

            // Zielwerte
            HStack(spacing: 24) {
                // Gewicht
                VStack(spacing: 4) {
                    Text(set.weight > 0 ? String(format: "%.1f", set.weight) : "0.0")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(set.weight > 0 ? .primary : .secondary)

                    Text(set.weight > 0 ? "kg" : "Körpergewicht")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                // Trennlinie
                Rectangle()
                    .fill(Color.primary.opacity(0.2))
                    .frame(width: 1, height: 50)

                // Wiederholungen
                VStack(spacing: 4) {
                    Text("\(set.reps)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text("Wdh.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }

            // Bearbeiten Button
            Button {
                selectedSetForEdit = set
            } label: {
                Label("Anpassen", systemImage: "pencil")
                    .font(.subheadline)
                    .foregroundStyle(.blue)
            }

            .glassDivider()

            // Satz abschließen Button
            Button {
                completeSet(set)
            } label: {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Satz abschließen")
                        .font(.headline)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(.green, in: RoundedRectangle(cornerRadius: 16))
            }
        }
        .glassCard()
    }

    // Anzahl der Sets für die jeweilige Übung
    private var setsForCurrentExercise: Int {
        guard let current = currentSet else { return 0 }
        return session.exerciseSets.filter { $0.exerciseName == current.exerciseName }.count
    }

    // Prüft ob die aktuell ausgewählte Übung komplett ist
    private var isSelectedExerciseComplete: Bool {
        guard let selectedIndex = selectedExerciseIndex else { return false }
        let grouped = session.groupedSets
        guard selectedIndex < grouped.count else { return false }
        return grouped[selectedIndex].allSatisfy { $0.isCompleted }
    }

    // Name der aktuell ausgewählten Übung (falls komplett)
    private var selectedExerciseName: String? {
        guard let selectedIndex = selectedExerciseIndex else { return nil }
        let grouped = session.groupedSets
        guard selectedIndex < grouped.count else { return nil }
        return grouped[selectedIndex].first?.exerciseName
    }

    // MARK: - Einzelne Übung abgeschlossen

    private var exerciseCompletedCard: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)

            if let exerciseName = selectedExerciseName {
                Text("Übung \"\(exerciseName)\" abgeschlossen!")
                    .font(.title2.bold())
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
            }

            Text("Wähle die nächste Übung aus der Liste unten.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                // Zurück zum automatischen Modus
                withAnimation(.easeInOut) {
                    selectedExerciseIndex = nil
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.right.circle.fill")
                    Text("Nächste Übung")
                        .font(.headline)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(.blue, in: RoundedRectangle(cornerRadius: 16))
            }
        }
        .glassCard()
    }

    // MARK: - Alle Sätze abgeschlossen

    private var allCompletedCard: some View {
        VStack(spacing: 20) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 60))
                .foregroundStyle(.yellow)

            Text("Alle Sätze abgeschlossen!")
                .font(.title2.bold())
                .foregroundStyle(.primary)

            Text("Großartige Arbeit! Du kannst das Training jetzt beenden.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                finishWorkout()
            } label: {
                HStack {
                    Image(systemName: "flag.checkered")
                    Text("Training beenden")
                        .font(.headline)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(.green, in: RoundedRectangle(cornerRadius: 16))
            }
        }
        .glassCard()
    }

    // MARK: - Übungen-Übersicht

    private var exercisesOverview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Übersicht")
                .font(.title3.bold())
                .foregroundStyle(.primary)

            // Verwende firstSet.id als stabile ID statt .offset
            // Dies verhindert das Springen der Liste bei Timer-Updates
            ForEach(Array(session.groupedSets.enumerated()), id: \.element.first!.id) { index, sets in
                if let firstSet = sets.first {
                    exerciseOverviewRow(
                        name: firstSet.exerciseName,
                        sets: sets,
                        index: index + 1,
                        isCurrentExercise: index == currentExerciseIndex
                    )
                    // Tap-Geste zur manuellen Übungsauswahl
                    .onTapGesture {
                        selectExercise(at: index)
                    }
                }
            }
        }
        .glassCard()
    }

    // Aufbau der Übungsübersicht
    private func exerciseOverviewRow(name: String, sets: [ExerciseSet], index: Int, isCurrentExercise: Bool) -> some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Text("\(index). \(name)")
                    .font(.subheadline.bold())
                    .foregroundStyle(isCurrentExercise ? .blue : .primary)

                Spacer()

                let completed = sets.filter { $0.isCompleted }.count
                if completed == sets.count {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Text("\(completed)/\(sets.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Sets als kleine Kreise
            HStack(spacing: 6) {
                ForEach(sets, id: \.id) { set in
                    Circle()
                        .fill(set.isCompleted ? Color.green : Color.primary.opacity(0.2))
                        .frame(width: 12, height: 12)
                        .overlay {
                            if set.setKind == .warmup {
                                Circle()
                                    .stroke(Color.orange, lineWidth: 2)
                            }
                        }
                }

                Spacer()
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCurrentExercise ? Color.blue.opacity(0.1) : Color.clear)
        )
        // contentShape macht die gesamte Row tappbar, nicht nur den Text
        .contentShape(Rectangle())
    }

    // MARK: - Bottom Action Bar

    private var bottomActionBar: some View {
        HStack(spacing: 16) {
            // Pause/Play Button - Verwendet SessionManager
            Button {
                toggleTimer()
            } label: {
                Image(systemName: sessionManager.isPaused ? "play.fill" : "pause.fill")
                    .font(.title2)
                    .foregroundStyle(.primary)
                    .frame(width: 56, height: 56)
                    .background(
                        sessionManager.isPaused ? Color.green.opacity(0.2) : Color.primary.opacity(0.1),
                        in: Circle()
                    )
                    .overlay(
                        Circle()
                            .stroke(sessionManager.isPaused ? Color.green : Color.clear, lineWidth: 2)
                    )
            }

            Spacer()

            // Training beenden
            Button {
                if session.allSetsCompleted {
                    finishWorkout()
                } else {
                    showFinishAlert = true
                }
            } label: {
                HStack {
                    Image(systemName: "flag.checkered")
                    Text("Beenden")
                        .font(.headline)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(
                    session.allSetsCompleted ? Color.green : Color.orange,
                    in: Capsule()
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    // MARK: - Session Setup

    // Initialisiert die Session beim Erscheinen der View
    private func setupSession() {
        let sessionID = session.sessionUUID.uuidString
        let activeID = sessionManager.getActiveSessionID()

        // Prüfen ob diese Session bereits im Manager aktiv ist
        if let activeID = activeID, activeID == sessionID {
          // Diese Session ist bereits im Manager registriert
        } else if sessionManager.hasActiveSession {
                // Eine ANDERE Session ist aktiv
            sessionManager.discardSession()
            startNewSession(sessionID: sessionID)
        } else {
            // Keine aktive Session - neue starten
            startNewSession(sessionID: sessionID)
        }

        // Stelle den gespeicherten Übungs-Index wieder her
        if let savedIndex = sessionManager.getSelectedExerciseIndex() {
            selectedExerciseIndex = savedIndex
        }
    }

    // Startet eine neue Session im Manager
    private func startNewSession(sessionID: String) {
        sessionManager.startSession(sessionID: sessionID, workoutType: .strength)

        // Session in SwiftData als gestartet markieren
        session.start()
        try? context.save()
    }

    // Räumt den lokalen Timer auf (falls vorhanden)
    private func cleanupTimer() {
        localTimer?.invalidate()
        localTimer = nil
    }

    // MARK: - Timer Funktionen (Delegiert an SessionManager)

    private func toggleTimer() {
        if sessionManager.isPaused {
            sessionManager.resumeSession()
        } else {
            sessionManager.pauseSession()
        }

        // Haptic Feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    // MARK: - Aktionen

    // Übung manuell auswählen
    private func selectExercise(at index: Int) {
        withAnimation(.easeInOut) {
            selectedExerciseIndex = index
        }

        // Haptic Feedback
        hapticGenerator.impactOccurred()
    }

    private func completeSet(_ set: ExerciseSet) {
        withAnimation(.easeInOut) {
            set.isCompleted = true
        }
        try? context.save()

        // Wenn noch kein Index ausgewählt ist, wähle automatisch die aktuelle Übung
        // damit wir bei dieser Übung bleiben (kein Zirkeltraining)
        if selectedExerciseIndex == nil {
            let grouped = session.groupedSets
            if let currentIndex = grouped.firstIndex(where: { group in
                group.contains { $0.id == set.id }
            }) {
                selectedExerciseIndex = currentIndex
            }
        }

        // Wenn alle Sätze der aktuellen Übung erledigt sind,
        // setze selectedExerciseIndex zurück für automatische Fortsetzung zur nächsten Übung
        if let selectedIndex = selectedExerciseIndex {
            let grouped = session.groupedSets
            guard selectedIndex < grouped.count else { return }
            let allSetsComplete = grouped[selectedIndex].allSatisfy { $0.isCompleted }

            if allSetsComplete {
                withAnimation(.easeInOut) {
                    selectedExerciseIndex = nil
                }
            }
        }

        // Haptic Feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()


        // Pause-Timer nur starten wenn noch weitere Sätze der GLEICHEN Übung übrig sind
        let remainingSetsForExercise = session.exerciseSets.filter {
            $0.exerciseName == set.exerciseName && !$0.isCompleted
        }

        if !remainingSetsForExercise.isEmpty {
            // Es gibt noch Sätze dieser Übung → Pause-Timer starten
            startRestTimer(for: set)
        }
        // Ansonsten: Kein Pause-Timer, weil die Übung fertig ist
    }

    private func finishWorkout() {
        // Session über Manager beenden und Dauer holen
        let finalSeconds = sessionManager.endSession()

        // Session-Daten aktualisieren
        session.complete()
        session.duration = finalSeconds / 60

        try? context.save()
        dismiss()
    }

    private func cancelWorkout() {
        // Session im Manager verwerfen
        sessionManager.discardSession()

        // Session aus SwiftData löschen
        context.delete(session)
        try? context.save()
        dismiss()
    }

    // Wird aufgerufen wenn Timer bereits pausiert ist
    private func handlePausedExit() {
        // Training ist bereits pausiert - Einfach zurück zur ListView
        // State bleibt im SessionManager erhalten für spätere Wiederaufnahme
        dismiss()
    }

    // Pausiert das Training und kehrt zur ListView zurück
    private func handlePauseAndExit() {
        // Timer pausieren (speichert automatisch in UserDefaults)
        sessionManager.pauseSession()

        // Session in SwiftData bleibt erhalten (nicht löschen!)
        // Benutzer kann später fortsetzen

        dismiss()
    }

    // MARK: - Rest Timer Functions

    // Startet den Pause-Timer nach Satz-Abschluss
    private func startRestTimer(for set: ExerciseSet) {
            // Pausenzeit aus dem Set nehmen
        let restTime = set.restSeconds

        // Falls restSeconds 0 ist, keinen Timer starten
        guard restTime > 0 else { return }

        restTimerSeconds = restTime

        withAnimation(.easeInOut) {
            isResting = true
        }

        // Timer starten
        restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if self.restTimerSeconds > 0 {
                self.restTimerSeconds -= 1
            } else {
                // Pause vorbei
                self.endRestTimer()

                // Haptic Feedback wenn in Settings aktiviert
                if self.appSettings.enableRestTimerHaptic {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
            }
        }
    }

    // Beendet den Pause-Timer
    private func endRestTimer() {
        restTimer?.invalidate()
        restTimer = nil

        withAnimation(.easeInOut) {
            isResting = false
        }

        restTimerSeconds = 0
    }

    // Überspringt die Pause
    private func skipRest() {
        endRestTimer()

        // Haptic Feedback
        hapticGenerator.impactOccurred()
    }
}

// MARK: - Preview

#Preview("Active Workout View") {
    NavigationStack {
        ActiveWorkoutView(session: {
            let session = StrengthSession(workoutType: .push)
            session.start()

            let set1 = ExerciseSet(exerciseName: "Bankdrücken", setNumber: 1, weight: 60, reps: 10, setKind: .warmup)
            let set2 = ExerciseSet(exerciseName: "Bankdrücken", setNumber: 2, weight: 80, reps: 8, setKind: .work)
            let set3 = ExerciseSet(exerciseName: "Bankdrücken", setNumber: 3, weight: 80, reps: 8, setKind: .work)
            let set4 = ExerciseSet(exerciseName: "Schrägbank", setNumber: 4, weight: 60, reps: 10, setKind: .work)
            let set5 = ExerciseSet(exerciseName: "Schrägbank", setNumber: 5, weight: 60, reps: 10, setKind: .work)

            session.exerciseSets = [set1, set2, set3, set4, set5]
            return session
        }())
    }
    .environmentObject(AppSettings.shared)
    .environmentObject(ActiveSessionManager.shared)
}
