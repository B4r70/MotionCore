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

    @State private var showDeleteAlert = false
    @State private var showEditSheet = false

    var body: some View {
        ZStack {
            AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)

            ScrollView {
                VStack(spacing: 20) {
                    // Header Card
                    headerCard

                    // Statistiken
                    statisticsCard

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
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Training Details")
        .navigationBarTitleDisplayMode(.inline)
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
                        .foregroundStyle(.orange)
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
                        .foregroundStyle(.green)
                    Text("Abgeschlossen")
                        .font(.caption.bold())
                        .foregroundStyle(.green)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.green.opacity(0.15), in: Capsule())
            }

            // Plan-Name (falls vorhanden)
            if let planName = session.planName {
                HStack(spacing: 8) {
                    Image(systemName: "doc.text.fill")
                        .foregroundStyle(.blue)
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
                        .foregroundStyle(.orange)
                }

                Spacer()

                if session.duration > 0 {
                    Label {
                        Text(formatDuration(session.duration))
                            .foregroundStyle(.primary)
                    } icon: {
                        Image(systemName: "clock.fill")
                            .foregroundStyle(.blue)
                    }
                }
            }
            .font(.subheadline)
        }
        .glassCard()
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
                    color: .orange
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
                    color: .green
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
                    color: .red
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
                                : .gray.opacity(0.3)
                            )
                    }

                    Text(session.intensity.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)
                }
            }
        }
        .glassCard()
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
        session.exerciseSets.reduce(0) { $0 + $1.reps }
    }

    // MARK: - Übungen Details Section

    private var exercisesDetailSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Übungen")
                .font(.title3.bold())
                .foregroundStyle(.primary)

            ForEach(Array(session.groupedSets.enumerated()), id: \.offset) { index, sets in
                if let firstSet = sets.first {
                    exerciseDetailCard(
                        name: firstSet.exerciseName,
                        gifAssetName: firstSet.exerciseGifAssetName,
                        sets: sets,
                        index: index + 1
                    )
                }
            }
        }
        .glassCard()
    }

    private func exerciseDetailCard(name: String, gifAssetName: String, sets: [ExerciseSet], index: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 12) {
                Text("\(index)")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(.blue))

                ExerciseGifView(assetName: gifAssetName, size: 44)

                Text(name)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()

                // Zusammenfassung
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(sets.count) Sätze")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(formatVolume(exerciseVolume(sets)))
                        .font(.caption.bold())
                        .foregroundStyle(.green)
                }
            }

            // Satz-Details
            VStack(spacing: 6) {
                ForEach(sets, id: \.id) { set in
                    HStack {
                        // Satz-Nummer
                        Text("Satz \(set.setNumber)")
                            .font(.caption)
                            .foregroundStyle(set.setKind == .warmup ? .orange : .secondary)
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

                        // Gewicht × Reps
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

                        // RPE (falls vorhanden)
                        if set.rpe > 0 {
                            Text("RPE \(set.rpe)")
                                .font(.caption2)
                                .foregroundStyle(.white)
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
        sets.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
    }

    private func rpeColor(_ rpe: Int) -> Color {
        switch rpe {
        case 1...5: return .green
        case 6...7: return .yellow
        case 8...9: return .orange
        case 10: return .red
        default: return .gray
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
        .glassCard()
    }

    // MARK: - Aktionen Section

    private var actionsSection: some View {
        VStack(spacing: 12) {
            // Bearbeiten
            Button {
                showEditSheet = true
            } label: {
                HStack {
                    Image(systemName: "pencil")
                    Text("Training bearbeiten")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 14)
                .background(Color.blue.opacity(0.15))
                .foregroundStyle(.blue)
                .clipShape(RoundedRectangle(cornerRadius: 14))
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
                    .foregroundStyle(.green)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }

            // Löschen
            Button(role: .destructive) {
                showDeleteAlert = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("Training löschen")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 14)
                .background(Color.red.opacity(0.12))
                .foregroundStyle(.red)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    // MARK: - Hilfsfunktionen

    private func formatDuration(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) Min"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
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

            session.exerciseSets = [set1, set2, set3, set4, set5]
            return session
        }())
        .environmentObject(AppSettings.shared)
    }
}
