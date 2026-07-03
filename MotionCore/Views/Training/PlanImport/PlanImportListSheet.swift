// ---------------------------------------------------------------------------------/
//  # MotionCore                                                                    /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Training / PlanImport                                            /
// Datei . . . . : PlanImportListSheet.swift                                       /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 27.04.2026                                                       /
// Beschreibung  : Liste aller wartenden Plan-Imports (≥2 Einträge)                /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - List Sheet

struct PlanImportListSheet: View {

    @EnvironmentObject private var planImportManager: PlanImportManager

    var body: some View {
        NavigationStack {
            List(planImportManager.pendingImports) { dto in
                Button {
                    // Tap: Preview-Sheet über List-Sheet öffnen
                    planImportManager.activeImport = dto
                } label: {
                    PlanImportListRow(dto: dto)
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .navigationTitle("Neue Trainingspläne")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Schließen") {
                        planImportManager.listTrigger = nil
                    }
                }
            }
        }
    }
}

// MARK: - Row

private struct PlanImportListRow: View {

    let dto: SupabasePendingPlanImportDTO

    private var planType: PlanType {
        PlanType(rawValue: dto.planType) ?? .mixed
    }

    var body: some View {
        HStack(spacing: 12) {
            // Plan-Type Icon
            ZStack {
                Circle()
                    .fill(planType.calmTileBackground)
                    .frame(width: 44, height: 44)
                Image(systemName: planType.icon)
                    .font(.title3)
                    .foregroundStyle(planType.calmTint)
            }

            // Texte
            VStack(alignment: .leading, spacing: 4) {
                Text(dto.title)
                    .font(AppFont.headline)
                    .foregroundStyle(Theme.textPrimary)

                // Plan-Type Badge + Übungen/Sätze
                HStack(spacing: 8) {
                    Text(planType.description)
                        .font(AppFont.caption.weight(.semibold))
                        .foregroundStyle(planType.calmTint)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(planType.calmTileBackground, in: Capsule())

                    Text("\(dto.exerciseCount) Übungen · \(dto.setCount) Sätze")
                        .font(AppFont.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .card(padding: 0)
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview("Plan Import List Sheet") {
    let manager = PlanImportManager()

    // Preview mit zwei Dummy-DTOs
    let sets = [
        PlanImportSetDTO(setNumber: 1, setKind: "work", weight: 80, weightPerSide: false, reps: 8, duration: 0, distance: 0, restSeconds: 90, targetRepsMin: 6, targetRepsMax: 8, targetRir: 2, notes: "")
    ]
    let exercises = [
        PlanImportExerciseDTO(sortOrder: 1, groupId: nil, supersetGroupId: nil, exerciseUuid: "00000000-0000-0000-0000-000000000001", exerciseName: "Bankdrücken", exerciseMediaAssetName: "bench", sets: sets)
    ]
    let payload1 = PlanImportPayloadDTO(schemaVersion: 1, title: "Push Day", description: "", planType: "strength", startDate: "2026-05-01", endDate: nil, exercises: exercises)
    let payload2 = PlanImportPayloadDTO(schemaVersion: 1, title: "Cardio-Woche", description: "Leichter Einstieg", planType: "cardio", startDate: "2026-05-01", endDate: nil, exercises: [])

    manager.pendingImports = [
        SupabasePendingPlanImportDTO(id: UUID(), createdAt: Date(), updatedAt: Date(), schemaVersion: 1, source: "web", title: "Push Day", planDescription: "", planType: "strength", exerciseCount: 3, setCount: 9, planData: payload1, status: "pending", acceptedAt: nil, rejectedAt: nil, acceptedPlanId: nil, expiresAt: nil),
        SupabasePendingPlanImportDTO(id: UUID(), createdAt: Date(), updatedAt: Date(), schemaVersion: 1, source: "web", title: "Cardio-Woche", planDescription: "Leichter Einstieg", planType: "cardio", exerciseCount: 2, setCount: 6, planData: payload2, status: "pending", acceptedAt: nil, rejectedAt: nil, acceptedPlanId: nil, expiresAt: nil)
    ]
    manager.listTrigger = ListSheetTrigger()

    return PlanImportListSheet()
        .environmentObject(manager)
        .background(Theme.surfaceApp.ignoresSafeArea())
}
