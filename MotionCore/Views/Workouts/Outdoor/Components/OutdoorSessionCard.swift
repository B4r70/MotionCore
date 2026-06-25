//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Workout-Liste                                                    /
// Datei . . . . : OutdoorSessionCard.swift                                         /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 30.03.2026                                                       /
// Beschreibung  : Card fuer Outdoor-Sessions in der ListView                       /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct OutdoorSessionCard: View {
    let session: OutdoorSession

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // MARK: - Header
            HStack(spacing: 12) {
                // Aktivitaets-Icon
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 44, height: 44)

                    Image(systemName: session.outdoorActivity.icon)
                        .font(.title3)
                        .foregroundStyle(session.outdoorActivity.tint)
                }

                // Datum und Routenname
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.date.formatted(AppFormatters.dateGermanLong))
                        .font(.headline)
                        .foregroundStyle(.primary)

                    if !session.routeName.isEmpty {
                        Text(session.routeName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    } else {
                        Text(session.date.formatted(AppFormatters.timeGermanLong))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Wetter-Icon (wenn bekannt)
                if session.weatherCondition != .unknown {
                    Image(systemName: session.weatherCondition.icon)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
            .glassDivider(paddingTop: 4, paddingBottom: 2)

            // MARK: - Metriken-Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                // Dauer
                StatBubble(
                    icon: .system("clock.fill"),
                    value: "\(session.duration) min",
                    color: .blue
                )

                // Distanz
                StatBubble(
                    icon: .system("arrow.left.and.right"),
                    value: String(format: "%.1f km", session.distance),
                    color: Color.green
                )

                // Durchschnittsgeschwindigkeit (nur wenn vorhanden)
                if session.averageSpeed > 0 {
                    StatBubble(
                        icon: .system("speedometer"),
                        value: String(format: "%.1f km/h", session.averageSpeed),
                        color: Color.orange
                    )
                }

                // Hoehenmeter (nur wenn vorhanden)
                if session.elevationGain > 0 {
                    StatBubble(
                        icon: .system("mountain.2"),
                        value: "\(Int(session.elevationGain)) m",
                        color: Color.mint
                    )
                }
            }

            // MARK: - Route-Zeile (nur wenn Start oder Ziel vorhanden)
            if !session.startLocation.isEmpty || !session.endLocation.isEmpty {
                GlassDivider.tight

                HStack(spacing: 6) {
                    Image(systemName: "mappin")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Group {
                        if !session.startLocation.isEmpty && !session.endLocation.isEmpty {
                            Text("\(session.startLocation) → \(session.endLocation)")
                        } else if !session.startLocation.isEmpty {
                            Text(session.startLocation)
                        } else {
                            Text(session.endLocation)
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                }
            }

            // MARK: - Intensitaets-Stars (nur wenn gesetzt)
            if session.intensity != .none {
                GlassDivider.tight

                HStack(spacing: 4) {
                    Text("Belastung:")
                        .font(.caption2)
                        .foregroundStyle(.primary)

                    ForEach(0..<5) { index in
                        Image(systemName: index < session.intensity.rawValue ? "star.fill" : "star")
                            .font(.caption2)
                            .foregroundStyle(
                                index < session.intensity.rawValue
                                ? session.intensity.color
                                : Color.gray.opacity(0.3)
                            )
                    }

                    Spacer()
                }
            }
        }
        .card()
    }
}

// MARK: - Preview

#Preview {
    let session = OutdoorSession(
        duration: 95,
        distance: 42.3,
        calories: 1200,
        elevationGain: 580,
        averageSpeed: 26.7,
        routeName: "Rheinufer-Runde",
        startLocation: "Köln Altstadt",
        endLocation: "Bonn Hauptbahnhof",
        isCompleted: true,
        intensity: .medium,
        weatherCondition: .sunny
    )
    return OutdoorSessionCard(session: session)
        .padding()
        .background(Color(.systemGroupedBackground))
}
