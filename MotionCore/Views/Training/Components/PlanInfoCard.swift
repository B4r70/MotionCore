//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Trainingsplan                                                    /
// Datei . . . . : PlanInfoCard.swift                                               /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 27.12.2025                                                       /
// Beschreibung  : Header-Card mit Plan-Info für Detailansicht                      /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct PlanInfoCard: View {
    let plan: TrainingPlan
    
    private var accentColor: Color {
        switch plan.planType {
        case .cardio: return .blue
        case .strength: return .orange
        case .outdoor: return .green
        case .mixed: return .purple
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header mit Icon und Status
            headerSection
            
            // Beschreibung (falls vorhanden)
            if !plan.planDescription.isEmpty {
                Text(plan.planDescription)
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            }
            
            Divider()
            
            // Datum-Informationen
            dateSection
        }
        .glassCard()
    }
    
    // MARK: - Subviews
    
    private var headerSection: some View {
        HStack {
            // Icon
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 50, height: 50)

                IconType(
                    icon: .system(plan.planType.icon),
                    color: accentColor,
                    size: 24
                )
            }

            // Titel und Typ
            VStack(alignment: .leading, spacing: 4) {
                Text(plan.title)
                    .font(.title3.bold())
                    .foregroundStyle(.primary)

                Text(plan.planType.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Status-Badge
            statusBadge
        }
    }
    
    private var statusBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: plan.isActive ? "checkmark.circle.fill" : "pause.circle.fill")
                .foregroundStyle(plan.isActive ? .green : .secondary)
            Text(plan.isActive ? "Aktiv" : "Inaktiv")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
        }
    }
    
    private var dateSection: some View {
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
                
                // Verbleibende Tage
                if let daysRemaining = daysUntilEnd(end) {
                    HStack {
                        Text("Verbleibend")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(daysRemaining > 0 ? "\(daysRemaining) Tage" : "Abgelaufen")
                            .foregroundStyle(daysRemaining > 0 ? Color.primary : Color.red)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
    }
    
    // MARK: - Hilfsfunktionen
    
    private func daysUntilEnd(_ endDate: Date) -> Int? {
        Calendar.current.dateComponents([.day], from: Date(), to: endDate).day
    }
}

// MARK: - Preview

#Preview("Plan Info Card") {
    ZStack {
        AnimatedBackground(showAnimatedBlob: true)
        
        VStack(spacing: 16) {
            PlanInfoCard(plan: TrainingPlan(
                title: "Push Day A",
                planDescription: "Brust, Schultern und Trizeps Training",
                endDate: Calendar.current.date(byAdding: .day, value: 14, to: Date()),
                planType: .strength
            ))
            
            PlanInfoCard(plan: TrainingPlan(
                title: "Cardio Woche",
                planType: .cardio,
                isActive: false
            ))
        }
        .padding()
    }
    .environmentObject(AppSettings.shared)
}
