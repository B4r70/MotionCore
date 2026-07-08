//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Zusammenfassung                                                  /
// Datei . . . . : SummaryWeekStrip.swift                                           /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-04-02                                                       /
// Beschreibung  : 7-Tage-Aktivitäts-Strip mit Tap-Erweiterung zum Kalender         /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - Summary Week Strip

/// Kompakte 7-Tage-Aktivitäts-Ansicht. Tap-Chevron expandiert zum Monatskalender.
struct SummaryWeekStrip: View {

    let days: [ActivityDay]
    @Binding var showCalendar: Bool

    // MARK: - Body

    var body: some View {
        VStack(spacing: Space.s2) {
            // Wochentag-Labels und Tages-Kreise
            HStack(spacing: Space.s2) {
                ForEach(days) { day in
                    DayCircle(day: day)
                }

                Spacer()

                // Kalender-Toggle-Button
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showCalendar.toggle()
                    }
                } label: {
                    Image(systemName: showCalendar ? "chevron.up" : "chevron.down")
                        .font(AppFont.caption)
                        .foregroundStyle(Theme.textSecondary)
                        .padding(6)
                }
            }
        }
        .card()
    }
}

// MARK: - Day Circle

private struct DayCircle: View {

    let day: ActivityDay

    @State private var pulsing: Bool = false

    private var weekdayLetter: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "EEEEE"         // Einbuchstabiger Wochentag
        return formatter.string(from: day.date)
    }

    private var fillColor: Color {
        switch day.workoutCount {
        case 0:  return Theme.surfaceSunken
        case 1:  return Theme.accent.opacity(0.30)
        case 2:  return Theme.accent.opacity(0.60)
        default: return Theme.accent
        }
    }

    var body: some View {
        VStack(spacing: Space.s1) {
            Text(weekdayLetter)
                .font(AppFont.eyebrow)
                .foregroundStyle(Theme.textTertiary)

            ZStack {
                // Hintergrund-Kreis
                Circle()
                    .fill(fillColor)
                    .frame(width: 32, height: 32)

                // Pulsierender Rand für heute
                if day.isToday {
                    Circle()
                        .stroke(Theme.accent, lineWidth: 2)
                        .frame(width: 32, height: 32)
                        .scaleEffect(pulsing ? 1.2 : 1.0)
                        .opacity(pulsing ? 0.0 : 1.0)
                }

                // Workouts-Text (nur wenn > 0)
                if day.workoutCount > 0 {
                    Text("\(day.workoutCount)")
                        .font(AppFont.caption)
                        .fontWeight(.bold)
                        .monospacedDigit()
                        .foregroundStyle(day.workoutCount >= 2 ? Color.white : Theme.accentPress)
                }
            }
        }
        .task {
            guard day.isToday else { return }
            // Einmaliger Puls-Effekt beim Erscheinen
            withAnimation(.easeOut(duration: 0.8)) {
                pulsing = true
            }
        }
    }
}

// MARK: - Preview

#Preview("SummaryWeekStrip") {
    WeekStripPreviewWrapper()
        .environmentObject(AppSettings.shared)
}

private struct WeekStripPreviewWrapper: View {
    @State private var showCalendar = false

    var body: some View {
        let calendar = Calendar.current
        let today = Date()

        let days: [ActivityDay] = (0..<7).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let count = [0, 1, 2, 3, 0, 1, 0][offset % 7]
            var types: [WorkoutType] = []
            if count > 0 { types.append(.strength) }
            if count > 1 { types.append(.cardio) }
            return ActivityDay(
                id: date,
                date: date,
                workoutTypes: types,
                workoutCount: count,
                isToday: offset == 0
            )
        }

        return SummaryWeekStrip(days: days, showCalendar: $showCalendar)
            .padding()
    }
}
