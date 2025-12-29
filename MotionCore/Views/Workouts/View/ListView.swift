//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Workout-Liste                                                    /
// Datei . . . . : ListView.swift                                                   /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 22.10.2025                                                       /
// Beschreibung  : Darstellung aller erfassten Workouts                             /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftData
import SwiftUI

// MARK: - Workout-Typ Filter

enum WorkoutTypeFilter: String, CaseIterable, Identifiable {
    case all = "Alle"
    case cardio = "Cardio"
    case strength = "Kraft"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .all: return "list.bullet"
        case .cardio: return "heart.fill"
        case .strength: return "dumbbell.fill"
        }
    }
}

// MARK: - ListView

struct ListView: View {
    @Environment(\.modelContext) private var modelContext

    // Cardio Sessions
    @Query(sort: \CardioSession.date, order: .reverse)
    private var allCardioWorkouts: [CardioSession]

    // Strength Sessions
    @Query(sort: \StrengthSession.date, order: .reverse)
    private var allStrengthWorkouts: [StrengthSession]

    @State private var exportURL: URL?

    // Filter-States
    @Binding var selectedDeviceFilter: CardioDevice
    @Binding var selectedTimeFilter: TimeFilter

    // Workout-Typ Filter
    @State private var selectedWorkoutType: WorkoutTypeFilter = .all

    @EnvironmentObject private var appSettings: AppSettings

    // MARK: - Gefilterte Workouts

    // Cardio-Filter
    var filteredCardioWorkouts: [CardioSession] {
        var workouts = allCardioWorkouts

        if selectedDeviceFilter != .none {
            workouts = workouts.filter { $0.cardioDevice == selectedDeviceFilter }
        }

        if let dateRange = selectedTimeFilter.dateRange() {
            workouts = workouts.filter {
                $0.date >= dateRange.start && $0.date <= dateRange.end
            }
        }

        return workouts
    }

    // Strength-Filter
    var filteredStrengthWorkouts: [StrengthSession] {
        var workouts = allStrengthWorkouts

        // Nur abgeschlossene Sessions anzeigen
        workouts = workouts.filter { $0.isCompleted }

        if let dateRange = selectedTimeFilter.dateRange() {
            workouts = workouts.filter {
                $0.date >= dateRange.start && $0.date <= dateRange.end
            }
        }

        return workouts
    }

    // Aktive (laufende) Workouts
    var activeStrengthWorkouts: [StrengthSession] {
        allStrengthWorkouts.filter { !$0.isCompleted }
    }

    // Prüfen ob Liste leer ist
    var isListEmpty: Bool {
        switch selectedWorkoutType {
        case .all:
            return filteredCardioWorkouts.isEmpty && filteredStrengthWorkouts.isEmpty
        case .cardio:
            return filteredCardioWorkouts.isEmpty
        case .strength:
            return filteredStrengthWorkouts.isEmpty
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)

            VStack(spacing: 0) {
                // Workout-Typ Segmented Control
                workoutTypeSelector
                    .padding(.horizontal)
                    .padding(.top, 8)

                // Workout-Liste
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Aktive Workouts (wenn vorhanden)
                        if !activeStrengthWorkouts.isEmpty && selectedWorkoutType != .cardio {
                            activeWorkoutsSection
                        }

                        // Abgeschlossene Workouts
                        completedWorkoutsSection
                    }
                    .scrollViewContentPadding()
                }
                .scrollIndicators(.hidden)
            }
        }
        .overlay {
            if isListEmpty && activeStrengthWorkouts.isEmpty {
                EmptyState()
            }
        }
    }

    // MARK: - Workout-Typ Selector

    private var workoutTypeSelector: some View {
        HStack(spacing: 8) {
            ForEach(WorkoutTypeFilter.allCases) { type in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedWorkoutType = type
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: type.icon)
                            .font(.caption)

                        Text(type.rawValue)
                            .font(.subheadline.weight(.medium))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(
                        selectedWorkoutType == type
                        ? Color.blue.opacity(0.2)
                        : Color.clear
                    )
                    .foregroundStyle(
                        selectedWorkoutType == type
                        ? .blue
                        : .secondary
                    )
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.3), lineWidth: 0.8)
        )
    }

    // MARK: - Aktive Workouts Section

    private var activeWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Circle()
                    .fill(.orange)
                    .frame(width: 8, height: 8)

                Text("Laufende Trainings")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()
            }
            .padding(.horizontal)

            // Aktive Sessions
            ForEach(activeStrengthWorkouts) { session in
                NavigationLink {
                    ActiveWorkoutView(session: session)
                } label: {
                    StrengthSessionCard(session: session)
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        deleteStrengthSession(session)
                    } label: {
                        Label("Löschen", systemImage: "trash")
                    }
                }
            }
        }
    }

    // MARK: - Abgeschlossene Workouts Section

    @ViewBuilder
    private var completedWorkoutsSection: some View {
        switch selectedWorkoutType {
        case .all:
            // Alle Workouts gemischt nach Datum
            mixedWorkoutsList

        case .cardio:
            // Nur Cardio
            ForEach(filteredCardioWorkouts) { workout in
                NavigationLink {
                    FormView(mode: .edit, workout: workout)
                } label: {
                    WorkoutCard(allWorkouts: workout)
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        deleteCardioSession(workout)
                    } label: {
                        Label("Löschen", systemImage: "trash")
                    }
                }
            }

        case .strength:
            // Nur Strength
            ForEach(filteredStrengthWorkouts) { session in
                NavigationLink {
                    StrengthDetailView(session: session)
                } label: {
                    StrengthSessionCard(session: session)
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        deleteStrengthSession(session)
                    } label: {
                        Label("Löschen", systemImage: "trash")
                    }
                }
            }
        }
    }

    // MARK: - Gemischte Workout-Liste (nach Datum sortiert)

    private var mixedWorkoutsList: some View {
        let mixedWorkouts = createMixedWorkoutList()

        return ForEach(mixedWorkouts, id: \.id) { item in
            switch item {
            case .cardio(let workout):
                NavigationLink {
                    FormView(mode: .edit, workout: workout)
                } label: {
                    WorkoutCard(allWorkouts: workout)
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        deleteCardioSession(workout)
                    } label: {
                        Label("Löschen", systemImage: "trash")
                    }
                }

            case .strength(let session):
                NavigationLink {
                    StrengthDetailView(session: session)
                } label: {
                    StrengthSessionCard(session: session)
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        deleteStrengthSession(session)
                    } label: {
                        Label("Löschen", systemImage: "trash")
                    }
                }
            }
        }
    }

    // MARK: - Lösch-Funktionen

    private func deleteCardioSession(_ session: CardioSession) {
        withAnimation {
            modelContext.delete(session)
            try? modelContext.save()
        }
    }

    private func deleteStrengthSession(_ session: StrengthSession) {
        withAnimation {
            modelContext.delete(session)
            try? modelContext.save()
        }
    }

    // MARK: - Hilfsfunktionen

    private func createMixedWorkoutList() -> [MixedWorkoutItem] {
        var items: [MixedWorkoutItem] = []

        // Cardio hinzufügen
        for workout in filteredCardioWorkouts {
            items.append(.cardio(workout))
        }

        // Strength hinzufügen
        for session in filteredStrengthWorkouts {
            items.append(.strength(session))
        }

        // Nach Datum sortieren (neueste zuerst)
        items.sort { $0.date > $1.date }

        return items
    }
}

// MARK: - Mixed Workout Item (für gemischte Liste)

enum MixedWorkoutItem {
    case cardio(CardioSession)
    case strength(StrengthSession)

    var id: String {
        switch self {
        case .cardio(let workout):
            return "cardio-\(workout.id)"
        case .strength(let session):
            return "strength-\(session.id)"
        }
    }

    var date: Date {
        switch self {
        case .cardio(let workout):
            return workout.date
        case .strength(let session):
            return session.date
        }
    }
}
