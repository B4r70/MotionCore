//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Einstellungen                                                    /
// Datei . . . . : StudioSetupView.swift                                            /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 18.04.2026                                                       /
// Beschreibung  : Studio-Konfigurations-View mit Equipment-Liste                   /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI
import SwiftData

struct StudioSetupView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appSettings: AppSettings

    // MARK: - Query

    @Query(filter: #Predicate<Studio> { $0.isPrimary == true })
    private var primaryStudios: [Studio]

    // MARK: - State

    @State private var editingEquipment: StudioEquipment?
    @State private var addSheetStudio: Studio?
    @State private var equipmentPendingDelete: StudioEquipment?

    // MARK: - Computed Properties

    private var primaryStudio: Studio? { primaryStudios.first }

    private var equipmentList: [StudioEquipment] {
        (primaryStudio?.safeEquipment ?? []).sorted { $0.name < $1.name }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)

            if equipmentList.isEmpty {
                EmptyState(
                    icon: "dumbbell.fill",
                    title: "Kein Gerät",
                    message: "Füge dein erstes Studio-Gerät hinzu"
                )
            } else {
                List {
                    ForEach(equipmentList) { eq in
                        Button {
                            editingEquipment = eq
                        } label: {
                            StudioEquipmentRow(equipment: eq)
                        }
                        .buttonStyle(.plain)
                        .card()
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                    .onDelete { indices in
                        if let idx = indices.first {
                            equipmentPendingDelete = equipmentList[idx]
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Studio einrichten")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if let studio = primaryStudio {
                        addSheetStudio = studio
                    }
                } label: {
                    Image(systemName: "plus")
                }
                .disabled(primaryStudio == nil)
            }
        }

        // MARK: - Sheets (item-basiert gemäß Sheet-Pattern)

        .sheet(item: $editingEquipment) { eq in
            StudioEquipmentEditSheet(studio: eq.studio ?? primaryStudio!, existing: eq)
        }
        .sheet(item: $addSheetStudio) { studio in
            StudioEquipmentEditSheet(studio: studio, existing: nil)
        }

        // MARK: - Delete-Confirm-Alert

        .alert(
            "Gerät löschen?",
            isPresented: Binding(
                get: { equipmentPendingDelete != nil },
                set: { if !$0 { equipmentPendingDelete = nil } }
            ),
            presenting: equipmentPendingDelete
        ) { eq in
            Button("Löschen", role: .destructive) {
                modelContext.delete(eq)
                try? modelContext.save()
                equipmentPendingDelete = nil
            }
            Button("Abbrechen", role: .cancel) {
                equipmentPendingDelete = nil
            }
        } message: { eq in
            Text("\(eq.name) wird dauerhaft entfernt.")
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        StudioSetupView()
            .modelContainer(PreviewData.sharedContainer)
            .environmentObject(AppSettings.shared)
    }
}
