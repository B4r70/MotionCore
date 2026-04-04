//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Übungen                                                          /
// Datei . . . . : ExerciseAdvancedFilterSheet.swift                                /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 20.01.2026                                                       /
// Beschreibung  : Erweiterte Filter für Exercise Search (Equipment, MuscleGroups)  /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct ExerciseFilterSheet: View {
    @Environment(\.dismiss) private var dismiss

    // Filter States
    @Binding var selectedEquipment: BundledEquipmentItem?
    @Binding var selectedPrimaryMuscle: MuscleGroup?
    @Binding var selectedSubMuscle: DetailedMuscle?

    // Equipment-Daten aus dem Bundle (werden vom Aufrufer durchgereicht)
    let equipmentItems: [BundledEquipmentItem]

    // Muskelgruppen direkt aus den Enums — kein Parameter nötig
    // Gefilterte Muskelgruppen: nur jene mit DetailedMuscle-Kindern
    private let muscleGroups: [MuscleGroup] = MuscleGroup.allCases.filter { group in
        DetailedMuscle.allCases.contains { $0.parentGroup == group }
    }

    // Local State
    @State private var expandedMuscleGroup: MuscleGroup? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBackground(showAnimatedBlob: true)

                ScrollView {
                    VStack(spacing: 20) {
                        activeFiltersCard
                        equipmentSection
                        muscleGroupSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Erweiterte Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("Zurücksetzen") {
                        resetFilters()
                    }
                    .disabled(!hasActiveFilters)
                }
            }
        }
    }

    // MARK: - Active Filters Card

    @ViewBuilder
    private var activeFiltersCard: some View {
        if hasActiveFilters {
            VStack(alignment: .leading, spacing: 12) {
                Text("Aktive Filter")
                    .font(.headline)
                    .foregroundStyle(.primary)

                VStack(spacing: 8) {
                    if let equipment = selectedEquipment {
                        HStack(spacing: 6) {
                            Image(systemName: "dumbbell.fill")
                                .font(.caption2)
                            Text(equipment.name)
                                .font(.caption)
                            Button {
                                selectedEquipment = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay(Capsule().stroke(Color.blue, lineWidth: 1))
                    }

                    if let primary = selectedPrimaryMuscle {
                        HStack(spacing: 6) {
                            Image(systemName: "figure.arms.open")
                                .font(.caption2)
                            Text(primary.rawValue)
                                .font(.caption)
                            Button {
                                selectedPrimaryMuscle = nil
                                selectedSubMuscle = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay(Capsule().stroke(Color.green, lineWidth: 1))
                    }

                    if let sub = selectedSubMuscle {
                        HStack(spacing: 6) {
                            Image(systemName: "scope")
                                .font(.caption2)
                            Text(sub.displayName)
                                .font(.caption)
                            Button {
                                selectedSubMuscle = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay(Capsule().stroke(Color.green.opacity(0.6), lineWidth: 1))
                    }
                }
            }
            .glassCard()
        }
    }

    // MARK: - Equipment Section

    private var equipmentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "dumbbell.fill")
                    .foregroundStyle(Color.blue)
                Text("Equipment")
                    .font(.title3.bold())
            }

            if equipmentItems.isEmpty {
                Text("Keine Equipment-Daten verfügbar")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                    ForEach(equipmentItems) { equipment in
                        EquipmentButton(
                            equipment: equipment,
                            isSelected: selectedEquipment?.id == equipment.id,
                            onTap: {
                                if selectedEquipment?.id == equipment.id {
                                    selectedEquipment = nil
                                } else {
                                    selectedEquipment = equipment
                                }
                            }
                        )
                    }
                }
            }
        }
        .glassCard()
    }

    // MARK: - Muscle Group Section

    private var muscleGroupSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "figure.arms.open")
                    .foregroundStyle(Color.green)
                Text("Muskelgruppen")
                    .font(.title3.bold())
            }

            if muscleGroups.isEmpty {
                Text("Keine Muskelgruppen verfügbar")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                VStack(spacing: 8) {
                    ForEach(muscleGroups) { group in
                        MuscleGroupRow(
                            group: group,
                            subgroups: DetailedMuscle.allCases.filter { $0.parentGroup == group },
                            selectedPrimary: $selectedPrimaryMuscle,
                            selectedSub: $selectedSubMuscle,
                            isExpanded: expandedMuscleGroup == group,
                            onToggleExpand: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    if expandedMuscleGroup == group {
                                        expandedMuscleGroup = nil
                                    } else {
                                        expandedMuscleGroup = group
                                    }
                                }
                            }
                        )
                    }
                }
            }
        }
        .glassCard()
    }

    // MARK: - Helpers

    private var hasActiveFilters: Bool {
        selectedEquipment != nil || selectedPrimaryMuscle != nil || selectedSubMuscle != nil
    }

    private func resetFilters() {
        selectedEquipment = nil
        selectedPrimaryMuscle = nil
        selectedSubMuscle = nil
    }
}

// MARK: - Equipment Button

private struct EquipmentButton: View {
    let equipment: BundledEquipmentItem
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(equipment.name)
                .font(.subheadline)
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.blue : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.blue : Color.white.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

// MARK: - Muscle Group Row (Hierarchisch)

private struct MuscleGroupRow: View {
    let group: MuscleGroup
    let subgroups: [DetailedMuscle]
    @Binding var selectedPrimary: MuscleGroup?
    @Binding var selectedSub: DetailedMuscle?
    let isExpanded: Bool
    let onToggleExpand: () -> Void

    private var isPrimarySelected: Bool {
        selectedPrimary == group
    }

    var body: some View {
        VStack(spacing: 0) {
            // Primary Group Button
            Button {
                if isPrimarySelected {
                    selectedPrimary = nil
                    selectedSub = nil
                } else {
                    selectedPrimary = group
                    selectedSub = nil
                }
            } label: {
                HStack {
                    Text(group.rawValue)
                        .font(.subheadline.bold())
                        .foregroundStyle(isPrimarySelected ? .white : .primary)

                    Spacer()

                    // Expand Button (nur wenn Subgroups existieren)
                    if !subgroups.isEmpty {
                        Button {
                            onToggleExpand()
                        } label: {
                            Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }

                    if isPrimarySelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.white)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isPrimarySelected ? Color.green : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isPrimarySelected ? Color.green : Color.white.opacity(0.3), lineWidth: 1)
                )
            }

            // Subgroups (expandable)
            if isExpanded && !subgroups.isEmpty {
                VStack(spacing: 6) {
                    ForEach(subgroups) { sub in
                        SubgroupButton(
                            subgroup: sub,
                            isSelected: selectedSub == sub,
                            onTap: {
                                if selectedSub == sub {
                                    selectedSub = nil
                                } else {
                                    selectedPrimary = group
                                    selectedSub = sub
                                }
                            }
                        )
                    }
                }
                .padding(.top, 8)
                .padding(.leading, 16)
            }
        }
    }
}

// MARK: - Subgroup Button

private struct SubgroupButton: View {
    let subgroup: DetailedMuscle
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(subgroup.displayName)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .white : .secondary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(Color.white)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.green.opacity(0.8) : Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.green : Color.white.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

// MARK: - Preview

#Preview {
    ExerciseFilterSheet(
        selectedEquipment: .constant(nil),
        selectedPrimaryMuscle: .constant(nil),
        selectedSubMuscle: .constant(nil),
        equipmentItems: BundledEquipmentService.loadAll()
    )
}
