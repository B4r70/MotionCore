//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Statistik                                                        /
// Datei . . . . : StatisticDeviceRow.swift                                         /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 11.11.2025                                                       /
// Beschreibung  : Darstellung von Zeilen für Workouts je Gerätetyp                 /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct StatisticDeviceRow: View {
    let device: CardioDevice
    let count: Int
    let total: Int

    private var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(count) / Double(total)
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: device.symbol)
                    .foregroundStyle(device.tint)
                Text(device.description)
                    .font(AppFont.body)
                Spacer()
                Text("\(count)")
                    .font(AppFont.body.bold())
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Theme.surfaceSunken)

                    Capsule()
                        .fill(device.tint)
                        .frame(width: geo.size.width * percentage)
                }
            }
            .frame(height: 8)
        }
    }
}

#Preview {
    StatisticDeviceRow(
        device: .crosstrainer,
        count: 12,
        total: 20
    );
    StatisticDeviceRow(
        device: .ergometer,
        count: 5,
        total: 20
    );
}
