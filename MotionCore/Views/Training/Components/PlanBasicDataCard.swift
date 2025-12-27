//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Trainingsplan                                                    /
// Datei . . . . : PlanBasicDataCard.swift                                          /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 27.12.2025                                                       /
// Beschreibung  : Formular-Card für Grunddaten eines Trainingsplans                /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct PlanBasicDataCard: View {
    @Bindable var plan: TrainingPlan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Titel
            Text("Trainingsplan-Daten")
                .font(.title3.bold())
                .foregroundStyle(.primary)

            // Plan-Titel
            titleField
            
            // Beschreibung
            descriptionField
            
            // Plan-Typ
            planTypePicker
            
            // Startdatum
            startDatePicker
            
            // Enddatum (Optional)
            endDateSection
            
            // Aktiv-Status
            activeToggle
        }
        .glassCard()
    }
    
    // MARK: - Subviews
    
    private var titleField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Titel")
                .font(.headline)
                .foregroundStyle(.primary)

            TextField("z.B. Push Day A", text: $plan.title)
                .textFieldStyle(.plain)
                .padding(12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.3), lineWidth: 0.8)
                )
        }
    }
    
    private var descriptionField: some View {
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
    }
    
    private var planTypePicker: some View {
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
    }
    
    private var startDatePicker: some View {
        DatePicker(
            "Startdatum",
            selection: $plan.startDate,
            displayedComponents: [.date]
        )
        .environment(\.locale, Locale(identifier: "de_DE"))
        .tint(.primary)
    }
    
    private var endDateSection: some View {
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
    }
    
    private var activeToggle: some View {
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
}

// MARK: - Preview

#Preview("Plan Basic Data Card") {
    ZStack {
        AnimatedBackground(showAnimatedBlob: true)
        
        ScrollView {
            PlanBasicDataCard(plan: TrainingPlan(title: "Push Day A"))
                .padding()
        }
    }
    .environmentObject(AppSettings.shared)
}
