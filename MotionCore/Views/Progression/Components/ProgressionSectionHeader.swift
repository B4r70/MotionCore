//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Progressions-Analyse                                             /
// Datei . . . . : ProgressionSectionHeader.swift                                   /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-03-28                                                       /
// Beschreibung  : Sektions-Header für Trend-Gruppen in der Progressions-Übersicht  /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct ProgressionSectionHeader: View {

    // MARK: - Parameter

    let trend: PerformanceTrend
    let count: Int

    // MARK: - Computed

    /// Deutsch-Label je nach Trend-Kategorie
    private var label: String {
        switch trend {
        case .improving:    return "Aufwärtstrend"
        case .stable:       return "Stabil"
        case .declining:    return "Rückgang"
        case .volatile:     return "Stabil"
        case .insufficient: return "Zu wenig Daten"
        }
    }

    /// Farbe aus dem bestehenden Trend-Farbsystem
    private var trendColor: Color {
        switch trend {
        case .improving:    return Color.green
        case .stable:       return .blue
        case .declining:    return Color.orange
        case .volatile:     return .blue
        case .insufficient: return Color.gray
        }
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 8) {
            // Trend-Icon
            Image(systemName: trend.icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(trendColor)

            // Bezeichnung
            Text(label)
                .font(.headline)
                .foregroundStyle(.primary)

            Spacer()

            // Count-Badge
            Text("\(count)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(.quaternary, in: Capsule())
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Preview

#Preview("Sektions-Header") {
    VStack(spacing: 16) {
        ProgressionSectionHeader(trend: .improving, count: 5)
        ProgressionSectionHeader(trend: .stable, count: 3)
        ProgressionSectionHeader(trend: .declining, count: 2)
        ProgressionSectionHeader(trend: .insufficient, count: 1)
    }
    .padding()
}
