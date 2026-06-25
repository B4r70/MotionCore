//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Workout                                                          /
// Datei . . . . : StrengthDetailView.swift                                         /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 27.12.2025                                                       /
// Beschreibung  : Detailansicht für abgeschlossene Krafttraining-Sessions          /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftData
import SwiftUI

struct StrengthDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appSettings: AppSettings

    @Bindable var session: StrengthSession

    @Query private var progressionStates: [ExerciseProgressionState]

    @State private var showDeleteAlert = false
    @State private var showEditSheet = false
    @State private var exerciseToEdit: Exercise? = nil
    @State private var rollbackCandidate: ExerciseProgressionState? = nil
    /// Kontext für Session→Plan-Sync-Sheet (Option A) — nil = Sheet geschlossen
    @State private var syncContext: SessionPlanSyncContext? = nil

    var body: some View {
        ZStack {
            AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)

            ScrollView {
                VStack(spacing: 20) {
                    // Header Card
                    headerCard

                    // Statistiken
                    statisticsCard

                    // Trainierte Muskeln
                    MuscleHeatmapMiniView(session: session)

                    // Übungen Details
                    exercisesDetailSection

                    // Notizen (falls vorhanden)
                    if !session.notes.isEmpty {
                        notesCard
                    }

                    // Aktionen
                    actionsSection
                }
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 40)
                // Inhalt fest auf die Viewport-Breite klemmen (äußerster Modifier) —
                // verhindert, dass die LazyVGrid (statisticsCard) den ScrollView-Inhalt
                // breiter als den Screen aufzieht und so horizontales Scrollen entsteht.
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Training Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                // Bearbeiten-Button
                Button {
                    showEditSheet = true
                } label: {
                    Image(systemName: "square.and.pencil")
                }

                // Löschen-Button
                Button {
                    showDeleteAlert = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(Color.red)
                }
            }
        }
        .alert("Training löschen?", isPresented: $showDeleteAlert) {
            Button("Abbrechen", role: .cancel) {}
            Button("Löschen", role: .destructive) {
                deleteSession()
            }
        } message: {
            Text("Dieses Training wird unwiderruflich gelöscht.")
        }
        .sheet(isPresented: $showEditSheet) {
            StrengthEditView(session: session)
                .environmentObject(appSettings)
        }
        .sheet(item: $exerciseToEdit) { exercise in
            NavigationStack {
                ExerciseFormView(mode: .edit, exercise: exercise, showDeleteButton: false)
                    .environmentObject(appSettings)
            }
        }
        .confirmationDialog(
            "Arbeitsgewicht zurücksetzen?",
            isPresented: Binding(
                get: { rollbackCandidate != nil },
                set: { if !$0 { rollbackCandidate = nil } }
            ),
            titleVisibility: .visible,
            presenting: rollbackCandidate
        ) { state in
            Button(
                "Zurück auf \(formatWeight(state.previousWorkingWeight ?? 0)) kg",
                role: .destructive
            ) {
                ProgressionRollbackService.manualRollback(state: state, in: context)
                rollbackCandidate = nil
            }
            Button("Abbrechen", role: .cancel) {
                rollbackCandidate = nil
            }
        } message: { state in
            Text(
                "Aktuell: \(formatWeight(state.workingWeight)) kg → Rollback auf \(formatWeight(state.previousWorkingWeight ?? 0)) kg"
            )
        }
    }

    // MARK: - Header Card

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Datum und Status
            HStack {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 50, height: 50)

                    Image(systemName: "dumbbell.fill")
                        .font(.title3)
                        .foregroundStyle(Color.orange)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(session.date.formatted(AppFormatters.dateGermanLong))
                        .font(.title3.bold())
                        .foregroundStyle(.primary)

                    Text(session.date.formatted(AppFormatters.timeGermanLong))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Status Badge
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.green)
                    Text("Abgeschlossen")
                        .font(.caption.bold())
                        .foregroundStyle(Color.green)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.green.opacity(0.15), in: Capsule())
            }

            // Plan-Name (falls vorhanden)
            if let planName = session.planName {
                HStack(spacing: 8) {
                    Image(systemName: "doc.text.fill")
                        .foregroundStyle(Color.blue)
                    Text(planName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Divider()

            // Workout-Typ und Dauer
            HStack {
                Label {
                    Text(session.workoutType.displayName)
                        .foregroundStyle(.primary)
                } icon: {
                    Image(systemName: session.workoutType.icon)
                        .foregroundStyle(Color.orange)
                }

                Spacer()

                if session.duration > 0 {
                    Label {
                        Text(formatDuration(session.duration))
                            .foregroundStyle(.primary)
                    } icon: {
                        Image(systemName: "clock.fill")
                            .foregroundStyle(Color.blue)
                    }
                }
            }
            .font(.subheadline)
        }
        .card()
    }

    // MARK: - Statistiken Card

    private var statisticsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Statistiken")
                .font(.title3.bold())
                .foregroundStyle(.primary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                // Übungen
                statisticItem(
                    value: "\(session.exercisesPerformed)",
                    label: "Übungen",
                    icon: "dumbbell.fill",
                    color: Color.orange
                )

                // Sätze
                statisticItem(
                    value: "\(session.totalSets)",
                    label: "Sätze",
                    icon: "number.circle.fill",
                    color: .purple
                )

                // Volumen
                statisticItem(
                    value: formatVolume(session.totalVolume),
                    label: "Volumen",
                    icon: "scalemass.fill",
                    color: Color.green
                )

                // Wiederholungen
                statisticItem(
                    value: "\(totalReps)",
                    label: "Wdh. gesamt",
                    icon: "repeat.circle.fill",
                    color: .blue
                )

                // Kalorien
                statisticItem(
                    value: session.calories > 0 ? "\(session.calories)" : "–",
                    label: "kcal",
                    icon: "flame.fill",
                    color: Color.red
                )

                // Herzfrequenz
                statisticItem(
                    value: session.heartRate > 0 ? "\(session.heartRate)" : "–",
                    label: "Ø bpm",
                    icon: "heart.fill",
                    color: .pink
                )
            }

            // Intensität
            .glassDivider()

            HStack {
                Text("Belastung")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                HStack(spacing: 4) {
                    ForEach(0..<5) { index in
                        Image(systemName: index < session.intensity.rawValue ? "star.fill" : "star")
                            .font(.caption)
                            .foregroundStyle(
                                index < session.intensity.rawValue
                                ? session.intensity.color
                                : Color.gray.opacity(0.3)
                            )
                    }

                    Text(session.intensity.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)
                }
            }

            // Bewertungs-Verteilung (nur anzeigen wenn mindestens eine Übung bewertet wurde)
            if !session.safeExerciseRatings.isEmpty {
                Divider()

                HStack {
                    Text("Bewertungen")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()

                    HStack(spacing: 12) {
                        ForEach(ExerciseQualityRating.allCases) { rating in
                            let count = session.safeExerciseRatings.filter { $0.rating == rating }.count
                            if count > 0 {
                                HStack(spacing: 4) {
                                    Image(systemName: rating.icon)
                                        .font(.caption)
                                        .foregroundStyle(rating.color)
                                    Text("\(count)")
                                        .font(.caption.bold())
                                        .foregroundStyle(rating.color)
                                }
                            }
                        }
                    }
                }
            }

            // Session-Qualitaetsscore (nur anzeigen wenn berechnet)
            if let score = session.sessionQualityScore {
                Divider()

                HStack(spacing: 6) {
                    Image(systemName: "chart.bar.doc.horizontal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Session-Qualität: \(score)/100")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .card()
    }

    private func statisticItem(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            Text(value)
                .font(.title2.bold())
                .foregroundStyle(.primary)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var totalReps: Int {
        session.safeExerciseSets.reduce(0) { $0 + $1.reps }
    }

    // MARK: - Übungen Details Section

    private var exercisesDetailSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Übungen")
                .font(.title3.bold())
                .foregroundStyle(.primary)

            ForEach(Array(session.groupedSets.enumerated()), id: \.offset) { index, sets in
                if let firstSet = sets.first {
                    // Bewertung für diese Übungsgruppe suchen
                    let groupRating = session.safeExerciseRatings
                        .first { $0.exerciseGroupKey == firstSet.groupKey }
                    exerciseDetailCard(
                        name: firstSet.exerciseNameSnapshot.isEmpty ? firstSet.exerciseName : firstSet.exerciseNameSnapshot,
                        mediaAssetName: firstSet.exerciseMediaAssetName,
                        sets: sets,
                        index: index + 1,
                        exercise: firstSet.exercise,
                        rating: groupRating?.rating
                    )
                }
            }
        }
        .card()
    }

    private func exerciseDetailCard(name: String, mediaAssetName: String, sets: [ExerciseSet], index: Int, exercise: Exercise?, rating: ExerciseQualityRating?) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 12) {
                Text("\(index)")
                    .font(.caption.bold())
                    .foregroundStyle(Color.white)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(Color.blue))

                if let exercise {
                    ExerciseVideoView.forExercise(exercise, size: 44)
                } else {
                    ExerciseVideoView(assetName: mediaAssetName, size: 44)
                }

                Text(name)
                    .font(.headline)
                    .foregroundStyle(.primary)

                // Bewertungs-Badge (falls vorhanden)
                if let rating {
                    ExerciseRatingBadge(rating: rating)
                }

                Spacer()

                // Zusammenfassung
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(sets.count) Sätze")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    // Volumen nur anzeigen wenn mindestens ein Weight-Satz vorhanden
                    if !sets.allSatisfy(\.isTimeBased) {
                        Text(formatVolume(exerciseVolume(sets)))
                            .font(.caption.bold())
                            .foregroundStyle(Color.green)
                    }
                }

                // Rollback-Button (nur wenn vorheriges Arbeitsgewicht bekannt)
                if let groupKey = sets.first?.groupKey,
                   let state = progressionState(for: groupKey),
                   state.previousWorkingWeight != nil {
                    Button {
                        rollbackCandidate = state
                    } label: {
                        Image(systemName: "arrow.uturn.backward.circle")
                            .font(.title3)
                            .foregroundStyle(.orange)
                    }
                    .accessibilityLabel("Arbeitsgewicht zurücksetzen")
                }

                // Übung bearbeiten (nur wenn Exercise-Referenz vorhanden)
                if let exercise {
                    Button {
                        exerciseToEdit = exercise
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Satz-Details
            VStack(spacing: 6) {
                ForEach(sets, id: \.persistentModelID) { set in
                    HStack {
                        // Satz-Nummer
                        Text("Satz \(set.setNumber)")
                            .font(.caption)
                            .foregroundStyle(set.setKind == .warmup ? Color.orange : .secondary)
                            .frame(width: 60, alignment: .leading)

                        // SetKind Badge
                        if set.setKind != .work {
                            Text(set.setKind.description)
                                .font(.caption2)
                                .foregroundStyle(set.setKind.color)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(set.setKind.color.opacity(0.2), in: Capsule())
                        }

                        Spacer()

                        // Gewicht × Reps (Weight) oder Ist-Zeit (Time)
                        if set.isTimeBased {
                            Text(formatSetDuration(set.duration))
                                .font(.subheadline.bold())
                        } else {
                            HStack(spacing: 4) {
                                if set.weight > 0 {
                                    Text(String(format: "%.1f kg", set.weight))
                                        .font(.subheadline.bold())

                                    Text("×")
                                        .foregroundStyle(.secondary)
                                }

                                Text("\(set.reps) Wdh.")
                                    .font(.subheadline.bold())
                            }
                        }

                        // RPE (falls vorhanden)
                        if set.rpe > 0 {
                            Text("RPE \(set.rpe)")
                                .font(.caption2)
                                .foregroundStyle(Color.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(rpeColor(set.rpe), in: Capsule())
                        }
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.primary.opacity(0.03))
                    )
                }
            }
        }
        .padding(.vertical, 8)
    }

    private func exerciseVolume(_ sets: [ExerciseSet]) -> Double {
        // Time-Sätze tragen kein Volumen bei (weight=0, reps=0)
        sets.filter { !$0.isTimeBased }.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
    }

    private func rpeColor(_ rpe: Int) -> Color {
        switch rpe {
        case 1...5: return Color.green
        case 6...7: return Color.yellow
        case 8...9: return Color.orange
        case 10: return Color.red
        default: return Color.gray
        }
    }

    // MARK: - Notizen Card

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Notizen", systemImage: "note.text")
                .font(.title3.bold())
                .foregroundStyle(.primary)

            Text(session.notes)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    // MARK: - Aktionen Section

    private var actionsSection: some View {
        VStack(spacing: 12) {

            // Plan aus Session aktualisieren (Option A — nur für abgeschlossene Sessions mit Plan)
            if let plan = session.sourceTrainingPlan, session.isCompleted {
                Button {
                    syncContext = SessionPlanSyncContext(session: session, plan: plan)
                } label: {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Plan aus Session aktualisieren")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 14)
                    .background(Color.purple.opacity(0.15))
                    .foregroundStyle(Color.purple)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }

            // Plan bearbeiten (nur sichtbar wenn Session einem Plan zugeordnet ist)
            if let plan = session.sourceTrainingPlan {
                NavigationLink {
                    TrainingDetailView(plan: plan)
                } label: {
                    HStack {
                        Image(systemName: "doc.text")
                        Text("Plan bearbeiten")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 14)
                    .background(Color.blue.opacity(0.15))
                    .foregroundStyle(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }

            // Wiederholen (neues Training aus diesem Template)
            if session.sourceTrainingPlan != nil {
                Button {
                    repeatWorkout()
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Training wiederholen")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 14)
                    .background(Color.green.opacity(0.15))
                    .foregroundStyle(Color.green)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
        .sheet(item: $syncContext) { ctx in
            SessionPlanSyncSheet(session: ctx.session, plan: ctx.plan)
        }
    }

    // MARK: - Hilfsfunktionen

    /// Progressions-State für einen gegebenen groupKey suchen
    private func progressionState(for groupKey: String) -> ExerciseProgressionState? {
        progressionStates.first { $0.exerciseGroupKey == groupKey }
    }

    private func formatWeight(_ w: Double) -> String {
        if w == w.rounded() {
            return String(format: "%.0f", w)
        }
        return String(format: "%.1f", w)
    }

    private func formatDuration(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) Min"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
    }

    /// Formatiert Ist-Zeit eines Time-Satzes in Sekunden als mm:ss Min
    private func formatSetDuration(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return s == 0 ? "\(m):00 Min" : String(format: "%d:%02d Min", m, s)
    }

    private func formatVolume(_ volume: Double) -> String {
        if volume <= 0 {
            return "–"
        } else if volume >= 1000 {
            return String(format: "%.1fk kg", volume / 1000)
        } else {
            return String(format: "%.0f kg", volume)
        }
    }

    private func deleteSession() {
        context.delete(session)
        try? context.save()
        dismiss()
    }

    private func repeatWorkout() {
        guard let plan = session.sourceTrainingPlan else { return }
        let newSession = plan.createSession()
        context.insert(newSession)
        try? context.save()
        // TODO: Navigation zur ActiveWorkoutView
    }
}

// MARK: - Preview

#Preview("Strength Session Detail") {
    NavigationStack {
        StrengthDetailView(session: {
            let session = StrengthSession(
                date: Date(),
                duration: 52,
                calories: 320,
                notes: "Gutes Training heute! Bankdrücken lief super.",
                workoutType: .push,
                intensity: .medium
            )
            session.isCompleted = true

            let set1 = ExerciseSet(exerciseName: "Bankdrücken", setNumber: 1, weight: 60, reps: 10, setKind: .warmup)
            set1.isCompleted = true
            let set2 = ExerciseSet(exerciseName: "Bankdrücken", setNumber: 2, weight: 80, reps: 8, setKind: .work)
            set2.isCompleted = true
            set2.rpe = 8
            let set3 = ExerciseSet(exerciseName: "Bankdrücken", setNumber: 3, weight: 80, reps: 7, setKind: .work)
            set3.isCompleted = true
            set3.rpe = 9
            let set4 = ExerciseSet(exerciseName: "Schrägbank KH", setNumber: 4, weight: 26, reps: 12, setKind: .work)
            set4.isCompleted = true
            let set5 = ExerciseSet(exerciseName: "Schrägbank KH", setNumber: 5, weight: 26, reps: 10, setKind: .work)
            set5.isCompleted = true

            // CloudKit-ready: relationship is optional
            session.exerciseSets = [set1, set2, set3, set4, set5]
            return session
        }())
        .environmentObject(AppSettings.shared)
    }
}
