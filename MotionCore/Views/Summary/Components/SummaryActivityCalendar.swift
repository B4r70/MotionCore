//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Zusammenfassung                                                  /
// Datei . . . . : SummaryActivityCalendar.swift                                    /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-04-02                                                       /
// Beschreibung  : Expandierbarer Monats-Kalender mit farbcodierten Trainingstagen  /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - Summary Activity Calendar

struct SummaryActivityCalendar: View {

    let monthGrid: [[ActivityDay?]]
    @Binding var displayedMonth: Date
    let stats: (trainingDays: Int, averagePerWeek: Double)

    // MARK: - Body

    var body: some View {
        VStack(spacing: Space.s3) {
            // Monats-Navigation
            monthNavigation

            // Wochentag-Header (Mo–So)
            weekdayHeader

            // Kalender-Grid
            calendarGrid

            // Statistik-Zeile
            statsRow
        }
        .card()
    }

    // MARK: - Monats-Navigation

    private var monthNavigation: some View {
        HStack {
            Button {
                changeMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer()

            Text(displayedMonth, format: .dateTime.month(.wide).year())
                .font(AppFont.headline)
                .foregroundStyle(Theme.textPrimary)

            Spacer()

            Button {
                changeMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .foregroundStyle(Theme.textSecondary)
            }
            .disabled(isCurrentMonth)
        }
    }

    // MARK: - Wochentag-Header

    private let weekdayNames = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(weekdayNames, id: \.self) { name in
                Text(name)
                    .font(AppFont.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Kalender-Grid

    private var calendarGrid: some View {
        VStack(spacing: 4) {
            ForEach(monthGrid.indices, id: \.self) { rowIndex in
                HStack(spacing: 4) {
                    ForEach(0..<7, id: \.self) { colIndex in
                        if let day = monthGrid[rowIndex][safe: colIndex] ?? nil {
                            CalendarDayCell(day: day)
                        } else {
                            // Leere Zelle
                            Color.clear
                                .frame(maxWidth: .infinity, minHeight: 28, maxHeight: 28)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Statistik-Zeile

    private var statsRow: some View {
        HStack(spacing: 16) {
            statItem(
                value: "\(stats.trainingDays)",
                label: "Trainingstage"
            )

            Divider()
                .frame(height: 30)

            statItem(
                value: String(format: "%.1f", stats.averagePerWeek),
                label: "Ø/Woche"
            )
        }
        .padding(.top, 4)
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Theme.textPrimary)
            Text(label)
                .font(AppFont.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Hilfsmethoden

    private var isCurrentMonth: Bool {
        let calendar = Calendar.current
        return calendar.isDate(displayedMonth, equalTo: Date(), toGranularity: .month)
    }

    private func changeMonth(by offset: Int) {
        let calendar = Calendar.current
        if let newDate = calendar.date(byAdding: .month, value: offset, to: displayedMonth) {
            withAnimation(.easeInOut(duration: 0.2)) {
                displayedMonth = newDate
            }
        }
    }
}

// MARK: - Kalender-Tages-Zelle

private struct CalendarDayCell: View {
    let day: ActivityDay

    private var backgroundColor: Color {
        switch day.workoutCount {
        case 0:  return .clear
        case 1:  return Theme.accent.opacity(0.30)
        case 2:  return Theme.accent.opacity(0.60)
        default: return Theme.accent
        }
    }

    private var textColor: Color {
        day.workoutCount >= 2 ? Color.white : Theme.accentPress
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(backgroundColor)
                .frame(maxWidth: .infinity, minHeight: 28, maxHeight: 28)

            if day.isToday {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Theme.accent, lineWidth: 1.5)
                    .frame(maxWidth: .infinity, minHeight: 28, maxHeight: 28)
            }

            Text("\(Calendar.current.component(.day, from: day.date))")
                .font(.system(size: 11, weight: day.isToday ? .bold : .regular))
                .monospacedDigit()
                .foregroundStyle(day.workoutCount > 0 ? textColor : Theme.textSecondary)
        }
    }
}

// MARK: - Safe Subscript für Array

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Preview

#Preview("SummaryActivityCalendar") {
    ActivityCalendarPreviewWrapper()
        .environmentObject(AppSettings.shared)
}

private struct ActivityCalendarPreviewWrapper: View {
    @State private var displayedMonth = Date()

    var body: some View {
        let engine = ActivityGridCalcEngine(cardioSessions: [], strengthSessions: [], outdoorSessions: [])
        let grid = engine.monthGrid(for: displayedMonth)
        let stats = engine.monthStats(for: displayedMonth)

        return SummaryActivityCalendar(
            monthGrid: grid,
            displayedMonth: $displayedMonth,
            stats: stats
        )
        .padding()
    }
}
