//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Statistik                                                        /
// Datei . . . . : StatisticDeviceCard.swift                                        /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 11.11.2025                                                       /
// Beschreibung  : Darstellung von Cards für Gerätetypen im Bereich Statistik       /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct StatisticDeviceCard: View {
    let allWorkouts: [CardioSession]

    private var calcStatistics: StatisticCalcEngine {
        StatisticCalcEngine(workouts: allWorkouts)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Workouts je Gerätetyp")
                .font(.headline)
                .padding(.horizontal, 4)

            VStack(spacing: 8) {
                ForEach([CardioDevice.crosstrainer, .ergometer], id: \.self) { device in
                    StatisticDeviceRow(
                        device: device,
                        count: calcStatistics.workoutCountDevice(for: device),
                        total: calcStatistics.totalWorkouts
                    )
                }
                .padding(.vertical, 5)
            }
        }
        .glassCard()
    }
}

#Preview {
    StatisticDeviceCard(
        allWorkouts: [])
}
