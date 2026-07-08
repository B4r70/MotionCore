//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Übungen                                                          /
// Datei . . . . : ExerciseFilterSheet.swift                                /
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
    @Binding var selectedCategory: ExerciseCategory?

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
                // Calm-2026: einheitlicher App-Hintergrund statt AnimatedBackground
                Theme.surfaceApp.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        activeFiltersCard
                        categorySection
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
                    .foregroundStyle(Theme.textPrimary)

                VStack(spacing: 8) {
                    if let equipment = selectedEquipment {
                        // Equipment-Badge: accentSoft-Fläche + accent-Text (aktiver Badge)
                        HStack(spacing: 6) {
                            Image(systemName: "dumbbell.fill")
                                .font(.caption2)
                                .foregroundStyle(Theme.accent)
                            Text(equipment.name)
                                .font(.caption)
                                .foregroundStyle(Theme.accent)
                            Button {
                                selectedEquipment = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(Theme.accent)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Theme.accentSoft))
                        .overlay(Capsule().stroke(Theme.line, lineWidth: 1))
                    }

                    if let primary = selectedPrimaryMuscle {
                        // Muskelgruppen-Badge: accentSoft-Fläche + accent-Text
                        HStack(spacing: 6) {
                            Image(systemName: "figure.arms.open")
                                .font(.caption2)
                                .foregroundStyle(Theme.accent)
                            Text(primary.rawValue)
                                .font(.caption)
                                .foregroundStyle(Theme.accent)
                            Button {
                                selectedPrimaryMuscle = nil
                                selectedSubMuscle = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(Theme.accent)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Theme.accentSoft))
                        .overlay(Capsule().stroke(Theme.line, lineWidth: 1))
                    }

                    if let sub = selectedSubMuscle {
                        // Untermuskel-Badge: accentSoft-Fläche + accent-Text
                        HStack(spacing: 6) {
                            Image(systemName: "scope")
                                .font(.caption2)
                                .foregroundStyle(Theme.accent)
                            Text(sub.displayName)
                                .font(.caption)
                                .foregroundStyle(Theme.accent)
                            Button {
                                selectedSubMuscle = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(Theme.accent)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Theme.accentSoft))
                        .overlay(Capsule().stroke(Theme.line, lineWidth: 1))
                    }

                    if let cat = selectedCategory {
                        // Kategorie-Badge: accentSoft-Fläche + accent-Text
                        HStack(spacing: 6) {
                            Image(systemName: "tag.fill")
                                .font(.caption2)
                                .foregroundStyle(Theme.accent)
                            Text(cat.description)
                                .font(.caption)
                                .foregroundStyle(Theme.accent)
                            Button {
                                selectedCategory = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(Theme.accent)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Theme.accentSoft))
                        .overlay(Capsule().stroke(Theme.line, lineWidth: 1))
                    }
                }
            }
            .card()
        }
    }

    // MARK: - Category Section

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Kategorie-Icon: neutraler Akzent statt rohes purple
                Image(systemName: "tag.fill")
                    .foregroundStyle(Theme.accent)
                Text("Kategorie")
                    .font(.title3.bold())
                    .foregroundStyle(Theme.textPrimary)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                ForEach(ExerciseCategory.allCases) { category in
                    let isSelected = selectedCategory == category
                    Button {
                        if isSelected {
                            selectedCategory = nil
                        } else {
                            selectedCategory = category
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: category.icon)
                                .font(.title3)
                                .foregroundStyle(isSelected ? Color.white : Theme.textSecondary)
                            Text(category.description)
                                .font(.caption)
                                .foregroundStyle(isSelected ? Color.white : Theme.textPrimary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 8)
                        .background(
                            RoundedRectangle(cornerRadius: Radius.md)
                                .fill(isSelected ? Theme.accent : Color.clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.md)
                                .stroke(isSelected ? Theme.accent : Theme.line, lineWidth: 1)
                        )
                    }
                }
            }
        }
        .card()
    }

    // MARK: - Equipment Section

    private var equipmentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Equipment-Icon: neutraler Akzent statt rohes blue
                Image(systemName: "dumbbell.fill")
                    .foregroundStyle(Theme.accent)
                Text("Equipment")
                    .font(.title3.bold())
                    .foregroundStyle(Theme.textPrimary)
            }

            if equipmentItems.isEmpty {
                Text("Keine Equipment-Daten verfügbar")
                    .foregroundStyle(Theme.textSecondary)
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
        .card()
    }

    // MARK: - Muscle Group Section

    private var muscleGroupSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Muskelgruppen-Icon: neutraler Akzent statt rohes green
                Image(systemName: "figure.arms.open")
                    .foregroundStyle(Theme.accent)
                Text("Muskelgruppen")
                    .font(.title3.bold())
                    .foregroundStyle(Theme.textPrimary)
            }

            if muscleGroups.isEmpty {
                Text("Keine Muskelgruppen verfügbar")
                    .foregroundStyle(Theme.textSecondary)
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
        .card()
    }

    // MARK: - Helpers

    private var hasActiveFilters: Bool {
        selectedEquipment != nil || selectedPrimaryMuscle != nil || selectedSubMuscle != nil || selectedCategory != nil
    }

    private func resetFilters() {
        selectedEquipment = nil
        selectedPrimaryMuscle = nil
        selectedSubMuscle = nil
        selectedCategory = nil
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
                // Ausgewählt: weiße Schrift auf Akzent; inaktiv: textPrimary
                .foregroundStyle(isSelected ? Color.white : Theme.textPrimary)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: Radius.md)
                        .fill(isSelected ? Theme.accent : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md)
                        // Ausgewählt: Akzent-Rahmen; inaktiv: Hairline
                        .stroke(isSelected ? Theme.accent : Theme.line, lineWidth: 1)
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
                        // Ausgewählt: weiße Schrift; inaktiv: textPrimary
                        .foregroundStyle(isPrimarySelected ? Color.white : Theme.textPrimary)

                    Spacer()

                    // Expand Button (nur wenn Subgroups existieren)
                    if !subgroups.isEmpty {
                        Button {
                            onToggleExpand()
                        } label: {
                            Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                                .foregroundStyle(isPrimarySelected ? Color.white : Theme.textSecondary)
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
                    RoundedRectangle(cornerRadius: Radius.md)
                        // Ausgewählt: Akzent-Fläche; inaktiv: transparent
                        .fill(isPrimarySelected ? Theme.accent : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md)
                        // Ausgewählt: Akzent-Rahmen; inaktiv: Hairline
                        .stroke(isPrimarySelected ? Theme.accent : Theme.line, lineWidth: 1)
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
                    // Ausgewählt: weiße Schrift; inaktiv: textSecondary
                    .foregroundStyle(isSelected ? Color.white : Theme.textSecondary)

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
                RoundedRectangle(cornerRadius: Radius.sm)
                    // Ausgewählt: Akzent-Fläche; inaktiv: Sunken-Fläche (Kontrast zur Karte)
                    .fill(isSelected ? Theme.accent : Theme.surfaceSunken)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.sm)
                    // Ausgewählt: Akzent-Rahmen; inaktiv: Hairline
                    .stroke(isSelected ? Theme.accent : Theme.line, lineWidth: 1)
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
        selectedCategory: .constant(nil),
        equipmentItems: BundledEquipmentService.loadAll()
    )
}
