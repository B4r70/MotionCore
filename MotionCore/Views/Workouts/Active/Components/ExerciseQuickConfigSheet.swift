//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Aktive Workouts                                                  /
// Datei . . . . : ExerciseQuickConfigSheet.swift                                   /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 18.04.2026                                                       /
// Beschreibung  : Quick-Config-Sheet fuer eine Uebung im aktiven Training.         /
//                 Zeigt Uebersicht + NavigationLink zur ExerciseFormView-           /
//                 Bearbeitung (Studio-Geraet, Ziel-Reps, Modus, Notiz).            /
//----------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
//----------------------------------------------------------------------------------/
//
import SwiftData
import SwiftUI

struct ExerciseQuickConfigSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appSettings: AppSettings

    @Bindable var exercise: Exercise
    @Query(sort: \StudioEquipment.name) private var equipments: [StudioEquipment]

    // Anzeigename des verknüpften Studio-Geräts (oder "—" falls keines gesetzt)
    private var equipmentName: String {
        guard let id = exercise.studioEquipmentID,
              let eq = equipments.first(where: { $0.id == id }) else {
            return "—"
        }
        return eq.name
    }

    // Formatierte Anzeige der Ziel-Reps (Custom oder Rep-Range)
    private var repRangeDisplay: String {
        if let custom = exercise.customTargetReps {
            return "\(custom) (überschrieben)"
        }
        if exercise.repRangeMin > 0 && exercise.repRangeMax > 0 {
            return "\(exercise.repRangeMin)–\(exercise.repRangeMax)"
        }
        return "—"
    }

    // Lokalisierer Label für den aktuellen Progressionsmodus
    private var modeLabel: String {
        switch exercise.progressionMode {
        case .smart: return "Smart"
        case .advanced: return "Advanced"
        case .off: return "Aus"
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)
                ScrollView {
                    VStack(spacing: 20) {
                        summaryCard
                        editLink
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Quick-Config")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Übersichtskarte

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(exercise.name)
                .font(.title3.bold())

            infoRow(label: "Studio-Gerät", value: equipmentName)
            infoRow(label: "Ziel-Reps", value: repRangeDisplay)
            infoRow(label: "Modus", value: modeLabel)

            if !exercise.configNotes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notiz")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(exercise.configNotes)
                        .font(.body)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassCard()
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .foregroundStyle(.primary)
        }
    }

    // MARK: - Link zur vollständigen Bearbeitung

    private var editLink: some View {
        NavigationLink {
            ExerciseFormView(
                mode: .edit,
                exercise: exercise,
                showDeleteButton: false
            )
            .environmentObject(appSettings)
        } label: {
            HStack {
                Image(systemName: "square.and.pencil")
                Text("Zur Übung bearbeiten")
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .glassCard()
        }
        .buttonStyle(.plain)
    }
}
