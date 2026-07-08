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
        VStack(spacing: 8) {
            // Wochentag-Labels und Tages-Kreise
            HStack(spacing: 8) {
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
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
        case 0:  return Color.secondary.opacity(0.12)
        case 1:  return Color(hex: "#C9E6FF")
        case 2:  return Color(hex: "#9BD2FF")
        default: return Color(hex: "#3B82F6")
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(weekdayLetter)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)

            ZStack {
                // Hintergrund-Kreis
                Circle()
                    .fill(fillColor)
                    .frame(width: 32, height: 32)

                // Pulsierender Rand für heute
                if day.isToday {
                    Circle()
                        .stroke(Color.blue, lineWidth: 2)
                        .frame(width: 32, height: 32)
                        .scaleEffect(pulsing ? 1.2 : 1.0)
                        .opacity(pulsing ? 0.0 : 1.0)
                }

                // Workouts-Text (nur wenn > 0)
                if day.workoutCount > 0 {
                    Text("\(day.workoutCount)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(day.workoutCount >= 2 ? .white : Color(hex: "#1D4ED8"))
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
