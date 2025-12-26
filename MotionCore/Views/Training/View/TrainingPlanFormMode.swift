//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Trainingsplan                                                    /
// Datei . . . . : TrainingPlanFormView.swift                                       /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 26.12.2025                                                       /
// Beschreibung  : Formular zum Erstellen/Bearbeiten von Trainingsplänen            /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftData
import SwiftUI

enum TrainingPlanFormMode { case add, edit }

struct TrainingPlanFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let mode: TrainingPlanFormMode

    @Bindable var plan: TrainingPlan
    @EnvironmentObject private var appSettings: AppSettings

    // Lösch-Bestätigung
    @State private var showDeleteAlert = false

    var body: some View {
        ZStack {
            // Hintergrund
            AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)
                .hideKeyboardOnTap()

            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 24) {
                        // Titel
                        Text("Trainingsplan-Daten")
                            .font(.title3.bold())
                            .foregroundStyle(.primary)

                        // MARK: Plan-Titel
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Titel")
                                .font(.headline)
                                .foregroundStyle(.primary)

                            TextField("z.B. Cardio Plan", text: $plan.title)
                                .textFieldStyle(.plain)
                                .padding(12)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 0.8)
                                )
                        }

                        // MARK: Beschreibung
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Beschreibung (optional)")
                                .font(.headline)
                                .foregroundStyle(.primary)

                            TextField("Ziele, Details...", text: $plan.planDescription, axis: .vertical)
                                .textFieldStyle(.plain)
                                .lineLimit(3...6)
                                .padding(12)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 0.8)
                                )
                        }

                        // MARK: Plan-Typ
                        HStack {
                            Text("Plan-Typ")
                                .foregroundStyle(.primary)

                            Spacer()

                            Menu {
                                Picker("", selection: $plan.planType) {
                                    ForEach(PlanType.allCases) { type in
                                        Label(type.description, systemImage: type.icon)
                                            .tag(type)
                                    }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Text(plan.planType.description)
                                        .foregroundStyle(.primary)

                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.caption2)
                                        .foregroundStyle(.primary)
                                }
                            }
                        }

                        // MARK: Startdatum
                        DatePicker(
                            "Startdatum",
                            selection: $plan.startDate,
                            displayedComponents: [.date]
                        )
                        .environment(\.locale, Locale(identifier: "de_DE"))
                        .tint(.primary)

                        // MARK: Enddatum (Optional)
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle(isOn: Binding(
                                get: { plan.endDate != nil },
                                set: { hasEndDate in
                                    if hasEndDate {
                                        plan.endDate = Calendar.current.date(byAdding: .day, value: 30, to: plan.startDate)
                                    } else {
                                        plan.endDate = nil
                                    }
                                }
                            )) {
                                Text("Enddatum festlegen")
                                    .foregroundStyle(.primary)
                            }
                            .tint(.blue)

                            if plan.endDate != nil {
                                DatePicker(
                                    "Enddatum",
                                    selection: Binding(
                                        get: { plan.endDate ?? Date() },
                                        set: { plan.endDate = $0 }
                                    ),
                                    displayedComponents: [.date]
                                )
                                .environment(\.locale, Locale(identifier: "de_DE"))
                                .tint(.primary)
                            }
                        }

                        // MARK: Aktiv-Status
                        Toggle(isOn: $plan.isActive) {
                            HStack(spacing: 8) {
                                Image(systemName: plan.isActive ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(plan.isActive ? .green : .secondary)

                                Text("Plan ist aktiv")
                                    .foregroundStyle(.primary)
                            }
                        }
                        .tint(.green)
                    }
                    .glassCard()
                    .padding(.horizontal)
                    .padding(.top, 16)
                }
                .padding(.bottom, 80)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle(mode == .add ? "Neuer Plan" : "Plan bearbeiten")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Speichern
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    dismissKeyboard()
                    if mode == .add {
                        context.insert(plan)
                    }
                    try? context.save()
                    dismiss()
                } label: {
                    IconType(icon: .system("checkmark"), color: .blue, size: 16)
                        .glassButton(size: 36, accentColor: .blue)
                }
                .disabled(plan.title.isEmpty)
            }

            // Löschen im Edit-Modus
            if mode == .edit {
                ToolbarItem(placement: .destructiveAction) {
                    Button(role: .destructive) {
                        dismissKeyboard()
                        showDeleteAlert = true
                    } label: {
                        IconType(icon: .system("trash"), color: .red, size: 16)
                            .glassButton(size: 36, accentColor: .red)
                    }
                }
            }
        }
        .alert("Plan löschen?", isPresented: $showDeleteAlert) {
            Button("Abbrechen", role: .cancel) {}
            Button("Löschen", role: .destructive) {
                deletePlan()
            }
        } message: {
            Text("Dieser Trainingsplan wird unwiderruflich gelöscht.")
        }
    }

    // MARK: - Hilfsfunktionen

    private func deletePlan() {
        context.delete(plan)
        try? context.save()
        dismiss()
    }
}

// MARK: - Preview

#Preview("Training Plan Form - Add") {
    NavigationStack {
        TrainingPlanFormView(mode: .add, plan: TrainingPlan())
            .environmentObject(AppSettings.shared)
    }
}
