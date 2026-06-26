//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Workout-Liste                                                    /
// Datei . . . . : StrengthSessionCard.swift                                        /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 27.12.2025                                                       /
// Beschreibung  : Card-Komponente für Krafttraining-Sessions in ListView           /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct StrengthSessionCard: View {
    @EnvironmentObject private var sessionManager: ActiveSessionManager

    let session: StrengthSession

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            headerSection

            .glassDivider()

            // Statistiken
            statsGrid

            .glassDivider()

            // Übungen-Übersicht
            exercisesPreview

            // Footer mit Intensität
            footerSection
        }
        .card()
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            // Führendes Icon-Tile (einheitlicher Typ-Ton via WorkoutTypeIconTile)
            WorkoutTypeIconTile(type: .strength, systemImage: "dumbbell.fill")

            // Datum und Plan-Name
            VStack(alignment: .leading, spacing: 2) {
                Text(session.date.formatted(AppFormatters.dateGermanLong))
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)

                if let planName = session.planName {
                    Text(planName)
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                } else {
                    Text(session.workoutType.displayName)
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
            }

            Spacer()

            // Status-Badge
            statusBadge
        }
    }

    // Status-Badge der Krafttraining Card (statischer Indikator, kein Endlos-Loop)
    private var statusBadge: some View {
        Group {
            if session.isCompleted {
                // Abgeschlossen
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Theme.success)
            } else {
                // Prüfen ob pausiert (Logik bleibt unverändert)
                let isPaused = sessionManager.getActiveSessionID() == session.sessionUUID.uuidString
                && sessionManager.isPaused

                // Statischer Indikator: Amber wenn pausiert, Grün wenn laufend
                let dotColor: Color = isPaused ? Theme.warning : Theme.success

                HStack(spacing: 4) {
                    Circle()
                        .fill(dotColor)
                        .frame(width: 8, height: 8)

                    Text("\(Int(session.progress * 100))%")
                        .font(.caption.bold())
                        .foregroundStyle(dotColor)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(dotColor.opacity(0.12), in: Capsule())
            }
        }
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            // Dauer → neutrale Metrik → series[0]
            StatBubble(
                icon: .system("clock.fill"),
                value: formatDuration(session.duration),
                color: Theme.series[0]
            )

            // Übungen → neutrale Metrik → series[0]
            StatBubble(
                icon: .system("dumbbell.fill"),
                value: "\(session.exercisesPerformed)",
                color: Theme.series[0]
            )

            // Sätze → neutrale Metrik → series[0]
            StatBubble(
                icon: .system("number.circle.fill"),
                value: "\(session.completedSets)/\(session.totalSets)",
                color: Theme.series[0]
            )

            // Volumen → neutrale Metrik → series[0]
            StatBubble(
                icon: .system("scalemass.fill"),
                value: formatVolume(session.totalVolume),
                color: Theme.series[0]
            )

            // Kalorien → warning (Amber)
            StatBubble(
                icon: .system("flame.fill"),
                value: session.calories > 0 ? "\(session.calories)" : "–",
                color: Theme.warning
            )

            // Herzfrequenz → danger (Puls)
            StatBubble(
                icon: .system("heart.fill"),
                value: session.heartRate > 0 ? "\(session.heartRate)" : "–",
                color: Theme.danger
            )
        }
    }

    // MARK: - Übungen-Vorschau

    private var exercisesPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Übungen")
                .font(.caption.bold())
                .foregroundStyle(Theme.textSecondary)

            // Erste 3 Übungen anzeigen
            let groupedSets = session.groupedSets
            let displayedExercises = groupedSets.prefix(3)

            ForEach(Array(displayedExercises.enumerated()), id: \.offset) { index, sets in
                if let firstSet = sets.first {
                    exerciseRow(
                        name: firstSet.exerciseName,
                        sets: sets,
                        index: index + 1
                    )
                }
            }

            // "Und X weitere..." wenn mehr als 3 Übungen
            if groupedSets.count > 3 {
                Text("+ \(groupedSets.count - 3) weitere Übungen")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.top, 4)
            }
        }
    }

    private func exerciseRow(name: String, sets: [ExerciseSet], index: Int) -> some View {
        HStack(spacing: 8) {
            // Nummer (Color.white ist erlaubt — strukturell auf farbigem Kreis)
            Text("\(index)")
                .font(.caption2.bold())
                .foregroundStyle(Color.white)
                .frame(width: 18, height: 18)
                .background(Circle().fill(Theme.accent))

            // Name
            Text(name)
                .font(.subheadline)
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)

            Spacer()

            // Sätze-Info
            let completedCount = sets.filter { $0.isCompleted }.count
            Text("\(completedCount)/\(sets.count)")
                .font(.caption)
                .foregroundStyle(completedCount == sets.count ? Theme.success : Theme.textSecondary)

            // Checkmark wenn alle erledigt
            if completedCount == sets.count {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(Theme.success)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.primary.opacity(0.05))
        )
    }

    // MARK: - Footer

    private var footerSection: some View {
        HStack(spacing: 4) {
            Text("Belastung:")
                .font(.caption2)
                .foregroundStyle(Theme.textPrimary)

            // Sterne neutral (eine Leitfarbe pro Karte, keine Ampel)
            ForEach(0..<5) { index in
                Image(systemName: index < session.intensity.rawValue ? "star.fill" : "star")
                    .font(.caption2)
                    .foregroundStyle(
                        index < session.intensity.rawValue
                        ? Theme.textSecondary
                        : Theme.line
                    )
            }

            Spacer()

            // Trainierte Muskelgruppen
            if !session.trainedMuscleGroups.isEmpty {
                HStack(spacing: 4) {
                    ForEach(session.trainedMuscleGroups.prefix(3), id: \.self) { muscle in
                        Text(muscle.description)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.accentSoft)
                            .foregroundStyle(Theme.accent)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    // MARK: - Hilfsfunktionen

    private func formatDuration(_ minutes: Int) -> String {
        if minutes <= 0 {
            return "–"
        } else if minutes < 60 {
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
            return String(format: "%.1fk", volume / 1000)
        } else {
            return String(format: "%.0f", volume)
        }
    }
}

// MARK: - StrengthWorkoutType UI Extension

extension StrengthWorkoutType {
    var displayName: String {
        switch self {
        case .fullBody: return "Ganzkörper"
        case .upper: return "Oberkörper"
        case .lower: return "Unterkörper"
        case .push: return "Push"
        case .pull: return "Pull"
        case .legs: return "Beine"
        case .core: return "Core"
        case .custom: return "Individuell"
        }
    }

    var icon: String {
        switch self {
        case .fullBody: return "figure.strengthtraining.traditional"
        case .upper: return "figure.arms.open"
        case .lower: return "figure.walk"
        case .push: return "arrow.up.circle.fill"
        case .pull: return "arrow.down.circle.fill"
        case .legs: return "figure.walk"
        case .core: return "figure.core.training"
        case .custom: return "slider.horizontal.3"
        }
    }
}

// MARK: - Preview

#Preview("Strength Session Card - Completed") {
    ScrollView {
        VStack(spacing: 16) {
            // Abgeschlossene Session
            StrengthSessionCard(session: {
                let session = StrengthSession(
                    date: Date(),
                    duration: 52,
                    calories: 320,
                    workoutType: .push,
                    intensity: .medium
                )
                session.isCompleted = true

                // Beispiel-Sets hinzufügen
                let set1 = ExerciseSet(exerciseName: "Bankdrücken", setNumber: 1, weight: 80, reps: 10)
                set1.isCompleted = true
                let set2 = ExerciseSet(exerciseName: "Bankdrücken", setNumber: 2, weight: 80, reps: 10)
                set2.isCompleted = true
                let set3 = ExerciseSet(exerciseName: "Schrägbank", setNumber: 3, weight: 60, reps: 12)
                set3.isCompleted = true

                session.exerciseSets = [set1, set2, set3]
                return session
            }())

            // Laufende Session
            StrengthSessionCard(session: {
                let session = StrengthSession(
                    date: Date(),
                    duration: 25,
                    workoutType: .pull
                )
                session.isCompleted = false

                let set1 = ExerciseSet(exerciseName: "Klimmzüge", setNumber: 1, weight: 0, reps: 8)
                set1.isCompleted = true
                let set2 = ExerciseSet(exerciseName: "Klimmzüge", setNumber: 2, weight: 0, reps: 8)
                set2.isCompleted = false
                let set3 = ExerciseSet(exerciseName: "Rudern", setNumber: 3, weight: 70, reps: 10)
                set3.isCompleted = false

                session.exerciseSets = [set1, set2, set3]
                return session
            }())
        }
        .padding()
    }
    .background(Theme.surfaceApp)
    .environmentObject(ActiveSessionManager.shared)
    .environmentObject(AppSettings.shared)
}
