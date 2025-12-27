//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Workout                                                          /
// Datei . . . . : ActiveWorkoutView.swift                                          /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 27.12.2025                                                       /
// Beschreibung  : Live-Tracking View während eines Krafttrainings                  /
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
    
    @Bindable var session: StrengthSession
    
    // Timer
    @State private var elapsedSeconds: Int = 0
    @State private var timer: Timer?
    @State private var isTimerRunning = true
    
    // UI States
    @State private var showFinishAlert = false
    @State private var showCancelAlert = false
    @State private var selectedSetForEdit: ExerciseSet?
    
    // Aktueller Satz
    private var currentSet: ExerciseSet? {
        session.nextUncompletedSet
    }
    
    private var currentExerciseIndex: Int {
        guard let current = currentSet else { return 0 }
        let grouped = session.groupedSets
        return grouped.firstIndex { group in
            group.contains { $0.id == current.id }
        } ?? 0
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
                        // Aktueller Satz (groß)
                        if let current = currentSet {
                            currentSetCard(current)
                        } else {
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
                    showCancelAlert = true
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .onAppear { startTimer() }
        .onDisappear { stopTimer() }
        .alert("Training abbrechen?", isPresented: $showCancelAlert) {
            Button("Weiter trainieren", role: .cancel) {}
            Button("Abbrechen", role: .destructive) {
                cancelWorkout()
            }
        } message: {
            Text("Dein Fortschritt geht verloren.")
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
            SetEditSheet(set: set)
                .environmentObject(appSettings)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            // Timer und Fortschritt
            HStack {
                // Timer
                HStack(spacing: 8) {
                    Image(systemName: "clock.fill")
                        .foregroundStyle(.blue)
                    
                    Text(formatTime(elapsedSeconds))
                        .font(.title2.bold().monospacedDigit())
                        .foregroundStyle(.primary)
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
                    if set.isWarmup {
                        Text("AUFWÄRMEN")
                            .font(.caption.bold())
                            .foregroundStyle(.orange)
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
                    Text(set.weight > 0 ? String(format: "%.1f", set.weight) : "–")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    
                    Text("kg")
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
    
    private var setsForCurrentExercise: Int {
        guard let current = currentSet else { return 0 }
        return session.exerciseSets.filter { $0.exerciseName == current.exerciseName }.count
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
            
            ForEach(Array(session.groupedSets.enumerated()), id: \.offset) { index, sets in
                if let firstSet = sets.first {
                    exerciseOverviewRow(
                        name: firstSet.exerciseName,
                        sets: sets,
                        index: index + 1,
                        isCurrentExercise: index == currentExerciseIndex
                    )
                }
            }
        }
        .glassCard()
    }
    
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
                            if set.isWarmup {
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
    }
    
    // MARK: - Bottom Action Bar
    
    private var bottomActionBar: some View {
        HStack(spacing: 16) {
            // Pause/Play Button
            Button {
                toggleTimer()
            } label: {
                Image(systemName: isTimerRunning ? "pause.fill" : "play.fill")
                    .font(.title2)
                    .foregroundStyle(.primary)
                    .frame(width: 56, height: 56)
                    .background(.ultraThinMaterial, in: Circle())
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
    
    // MARK: - Timer Funktionen
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if isTimerRunning {
                elapsedSeconds += 1
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func toggleTimer() {
        isTimerRunning.toggle()
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
    
    // MARK: - Aktionen
    
    private func completeSet(_ set: ExerciseSet) {
        withAnimation(.easeInOut) {
            set.isCompleted = true
        }
        try? context.save()
        
        // Haptic Feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    private func finishWorkout() {
        session.complete()
        session.duration = elapsedSeconds / 60
        try? context.save()
        dismiss()
    }
    
    private func cancelWorkout() {
        context.delete(session)
        try? context.save()
        dismiss()
    }
}

// MARK: - Set Edit Sheet

struct SetEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appSettings: AppSettings
    
    @Bindable var set: ExerciseSet
    
    @State private var weight: Double
    @State private var reps: Int
    
    init(set: ExerciseSet) {
        self.set = set
        _weight = State(initialValue: set.weight)
        _reps = State(initialValue: set.reps)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)
                
                VStack(spacing: 24) {
                    // Übungs-Info
                    HStack {
                        ExerciseGifView(assetName: set.exerciseGifAssetName, size: 60)
                        
                        VStack(alignment: .leading) {
                            Text(set.exerciseName)
                                .font(.headline)
                            Text("Satz \(set.setNumber)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    .glassCard()
                    
                    // Gewicht
                    VStack(spacing: 12) {
                        Text("Gewicht (kg)")
                            .font(.headline)
                        
                        HStack {
                            Button {
                                if weight >= 2.5 { weight -= 2.5 }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title)
                                    .foregroundStyle(.blue)
                            }
                            
                            Text(String(format: "%.1f", weight))
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .frame(width: 150)
                            
                            Button {
                                weight += 2.5
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title)
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    .glassCard()
                    
                    // Wiederholungen
                    VStack(spacing: 12) {
                        Text("Wiederholungen")
                            .font(.headline)
                        
                        HStack {
                            Button {
                                if reps > 1 { reps -= 1 }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title)
                                    .foregroundStyle(.blue)
                            }
                            
                            Text("\(reps)")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .frame(width: 150)
                            
                            Button {
                                reps += 1
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title)
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    .glassCard()
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Satz anpassen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        set.weight = weight
                        set.reps = reps
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Active Workout View") {
    NavigationStack {
        ActiveWorkoutView(session: {
            let session = StrengthSession(workoutType: .push)
            session.start()
            
            let set1 = ExerciseSet(exerciseName: "Bankdrücken", setNumber: 1, weight: 60, reps: 10, isWarmup: true)
            let set2 = ExerciseSet(exerciseName: "Bankdrücken", setNumber: 2, weight: 80, reps: 8)
            let set3 = ExerciseSet(exerciseName: "Bankdrücken", setNumber: 3, weight: 80, reps: 8)
            let set4 = ExerciseSet(exerciseName: "Schrägbank", setNumber: 4, weight: 60, reps: 10)
            let set5 = ExerciseSet(exerciseName: "Schrägbank", setNumber: 5, weight: 60, reps: 10)
            
            session.exerciseSets = [set1, set2, set3, set4, set5]
            return session
        }())
    }
    .environmentObject(AppSettings.shared)
}
