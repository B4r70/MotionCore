//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Trainingsplan                                                    /
// Datei . . . . : TrainingPlanDetailView.swift                                     /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 26.12.2025                                                       /
// Beschreibung  : Detailansicht für Trainingspläne                                 /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftData
import SwiftUI

struct TrainingPlanDetailView: View {

    @EnvironmentObject private var appSettings: AppSettings
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Bindable var plan: TrainingPlan

    @State private var showDeleteAlert = false

    private var planAccent: Color {
        switch plan.planType {
        case .cardio: return .blue
        case .strength: return .orange
        default: return .primary
        }
    }

    var body: some View {
        ZStack {
            AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)

            ScrollView {
                VStack(spacing: 20) {

                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 50, height: 50)

                                IconType(
                                    icon: .system(plan.planType.icon),
                                    color: planAccent,
                                    size: 24
                                )
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(plan.title)
                                    .font(.title3.bold())
                                    .foregroundStyle(.primary)

                                Text(plan.planType.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            HStack(spacing: 6) {
                                Image(systemName: plan.isActive ? "checkmark.circle.fill" : "pause.circle.fill")
                                    .foregroundStyle(plan.isActive ? .green : .secondary)
                                Text(plan.isActive ? "Aktiv" : "Inaktiv")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                            }
                        }

                        if !plan.planDescription.isEmpty {
                            Text(plan.planDescription)
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                        }

                        Divider()

                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Startdatum")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(plan.startDate, style: .date)
                                    .foregroundStyle(.primary)
                                    .fontWeight(.semibold)
                            }

                            if let end = plan.endDate {
                                HStack {
                                    Text("Enddatum")
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text(end, style: .date)
                                        .foregroundStyle(.primary)
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                    }
                    .glassCard()
                    .padding(.horizontal)
                    .padding(.top, 16)

                    // Aktionen
                    VStack(spacing: 12) {

                        NavigationLink {
                            TrainingPlanFormView(mode: .edit, plan: plan)
                        } label: {
                            HStack {
                                Image(systemName: "pencil")
                                Text("Plan bearbeiten")
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.subheadline.weight(.semibold))
                            }
                            .padding(.vertical, 14)
                            .padding(.horizontal, 14)
                            .background(planAccent.opacity(0.15))
                            .foregroundStyle(planAccent)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)

                        Button(role: .destructive) {
                            showDeleteAlert = true
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Plan löschen")
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
                    .padding(.horizontal)
                }
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Plan Details")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Plan löschen?", isPresented: $showDeleteAlert) {
            Button("Abbrechen", role: .cancel) {}
            Button("Löschen", role: .destructive) {
                deletePlan()
            }
        } message: {
            Text("Dieser Trainingsplan wird unwiderruflich gelöscht.")
        }
    }

    private func deletePlan() {
        context.delete(plan)
        try? context.save()
        dismiss()
    }
}
