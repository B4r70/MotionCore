// ---------------------------------------------------------------------------------/
//  # MotionCore                                                                    /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Training / PlanImport                                            /
// Datei . . . . : PlanImportPreviewSheet.swift                                    /
// Autor . . . . : Bartosz Stryjewski                                               //
// Erstellt am . : 27.04.2026                                                       /
// Beschreibung  : Preview-Sheet für einen einzelnen Plan-Import                   /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI
import SwiftData

// MARK: - Preview Sheet

struct PlanImportPreviewSheet: View {

    let dto: SupabasePendingPlanImportDTO
    let onAccept: () -> Void
    let onReject: () -> Void
    let onLater: () -> Void

    // MARK: - Berechnete Hilfswerte

    private var planType: PlanType {
        PlanType(rawValue: dto.planType) ?? .mixed
    }

    /// Eindeutige Exercise-Namen aus dem Payload (für die Subliste)
    private var exerciseNames: [String] {
        var seen = Set<String>()
        var result: [String] = []
        for exercise in dto.planData.exercises {
            if seen.insert(exercise.exerciseName).inserted {
                result.append(exercise.exerciseName)
            }
        }
        return result
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Plan-Type-Badge + Herkunft
                    HStack(spacing: 8) {
                        Label(planType.description, systemImage: planType.icon)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(planType.calmTint)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(planType.calmTileBackground, in: Capsule())

                        Spacer()

                        Text("Quelle: \(dto.source)")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }

                    // Beschreibung
                    if !dto.planDescription.isEmpty {
                        Text(dto.planDescription)
                            .font(.body)
                            .foregroundStyle(Theme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // Übungen · Sätze Badge-Zeile
                    HStack(spacing: 16) {
                        Label("\(dto.exerciseCount) Übungen", systemImage: "dumbbell.fill")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary)

                        Label("\(dto.setCount) Sätze", systemImage: "number.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary)
                    }

                    // Exercise-Name-Subliste (kompakt)
                    if !exerciseNames.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Übungen")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Theme.textSecondary)
                                .padding(.bottom, 2)

                            ForEach(exerciseNames, id: \.self) { name in
                                HStack(spacing: 8) {
                                    Image(systemName: "circle.fill")
                                        .font(.system(size: 5))
                                        .foregroundStyle(planType.calmTint)
                                    Text(name)
                                        .font(.subheadline)
                                        .foregroundStyle(Theme.textPrimary)
                                }
                            }
                        }
                        .padding()
                        .background(Theme.surfaceSunken, in: RoundedRectangle(cornerRadius: Radius.md))
                    }

                    // Buttons
                    VStack(spacing: 12) {
                        // Primär: Übernehmen
                        Button(action: onAccept) {
                            Label("Übernehmen", systemImage: "checkmark.circle.fill")
                        }
                        .buttonStyle(.mcPrimary)

                        // Sekundär: Ablehnen
                        Button(action: onReject) {
                            Label("Ablehnen", systemImage: "xmark.circle")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Theme.danger.opacity(0.12), in: RoundedRectangle(cornerRadius: Radius.md))
                                .foregroundStyle(Theme.danger)
                        }

                        // Tertiär: Später
                        Button(action: onLater) {
                            Text("Später")
                                .font(.subheadline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(dto.title)
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Preview

private extension PlanImportPreviewSheet {
    /// Erstellt einen minimalen Preview-DTO für Xcode-Previews ohne Netzwerk.
    static func previewDTO() -> SupabasePendingPlanImportDTO {
        let sets = [
            PlanImportSetDTO(setNumber: 1, setKind: "warmup", weight: 60, weightPerSide: false, reps: 8, duration: 0, distance: 0, restSeconds: 90, targetRepsMin: 8, targetRepsMax: 10, targetRir: 3, notes: ""),
            PlanImportSetDTO(setNumber: 2, setKind: "work", weight: 80, weightPerSide: false, reps: 8, duration: 0, distance: 0, restSeconds: 120, targetRepsMin: 6, targetRepsMax: 8, targetRir: 2, notes: "")
        ]
        let exercises = [
            PlanImportExerciseDTO(sortOrder: 1, groupId: "bench", supersetGroupId: nil, exerciseUuid: "00000000-0000-0000-0000-000000000001", exerciseName: "Bankdrücken", exerciseMediaAssetName: "bench_press", sets: sets),
            PlanImportExerciseDTO(sortOrder: 2, groupId: "ohp", supersetGroupId: nil, exerciseUuid: "00000000-0000-0000-0000-000000000002", exerciseName: "Schulterdrücken", exerciseMediaAssetName: "ohp", sets: [sets[1]])
        ]
        let payload = PlanImportPayloadDTO(
            schemaVersion: 1,
            title: "Push/Pull/Legs A",
            description: "4 Tage, fokussiert auf Hypertrophie",
            planType: "strength",
            startDate: "2026-04-28",
            endDate: nil,
            exercises: exercises
        )
        return SupabasePendingPlanImportDTO(
            id: UUID(),
            createdAt: Date(),
            updatedAt: Date(),
            schemaVersion: 1,
            source: "web",
            title: "Push/Pull/Legs A",
            planDescription: "4 Tage, fokussiert auf Hypertrophie",
            planType: "strength",
            exerciseCount: 2,
            setCount: 3,
            planData: payload,
            status: "pending",
            acceptedAt: nil,
            rejectedAt: nil,
            acceptedPlanId: nil,
            expiresAt: nil
        )
    }
}

#Preview("Plan Import Preview Sheet") {
    PlanImportPreviewSheet(
        dto: PlanImportPreviewSheet.previewDTO(),
        onAccept: { print("Akzeptiert") },
        onReject: { print("Abgelehnt") },
        onLater: { print("Später") }
    )
}
