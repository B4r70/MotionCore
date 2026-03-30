//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Basisdarstellung                                                 /
// Datei . . . . : OutdoorDetailView.swift                                          /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 30.03.2026                                                       /
// Beschreibung  : Detailansicht fuer abgeschlossene Outdoor-Sessions               /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftData
import SwiftUI

struct OutdoorDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appSettings: AppSettings

    @Bindable var session: OutdoorSession

    @State private var showDeleteAlert = false
    @State private var showEditSheet = false

    // MARK: - Body

    var body: some View {
        ZStack {
            AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)

            ScrollView {
                VStack(spacing: 20) {
                    routeCard
                    performanceCard

                    // Bewertungs-Card nur wenn mindestens ein Wert vorhanden
                    if session.perceivedExertion != nil
                        || session.energyLevelBefore != nil
                        || session.intensity != .none {
                        ratingCard
                    }

                    // Notizen-Card nur wenn Inhalt vorhanden
                    if !session.notes.isEmpty {
                        notesCard
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Tour Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                // Bearbeiten-Button
                Button {
                    showEditSheet = true
                } label: {
                    Image(systemName: "square.and.pencil")
                }

                // Loeschen-Button
                Button {
                    showDeleteAlert = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
            }
        }
        .alert("Tour löschen?", isPresented: $showDeleteAlert) {
            Button("Abbrechen", role: .cancel) {}
            Button("Löschen", role: .destructive) {
                deleteSession()
            }
        } message: {
            Text("Diese Tour wird unwiderruflich gelöscht.")
        }
        .sheet(isPresented: $showEditSheet) {
            NavigationStack {
                OutdoorFormView(mode: .edit, session: session)
            }
            .environmentObject(appSettings)
        }
    }

    // MARK: - Route & Wetter Card

    private var routeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Datum-Header mit Aktivitaets-Icon
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 50, height: 50)

                    Image(systemName: session.outdoorActivity.icon)
                        .font(.title3)
                        .foregroundStyle(session.outdoorActivity.tint)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(session.date.formatted(AppFormatters.dateWithWeekday))
                        .font(.title3.bold())
                        .foregroundStyle(.primary)

                    Text(session.outdoorActivity.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            // Routenname (wenn vorhanden)
            if !session.routeName.isEmpty {
                GlassDivider.tight

                HStack(spacing: 8) {
                    Image(systemName: "road.lanes")
                        .foregroundStyle(.blue)
                        .font(.subheadline)
                    Text(session.routeName)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }
            }

            // Startadresse (wenn vorhanden)
            if !session.startLocation.isEmpty {
                GlassDivider.tight

                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "mappin")
                        .foregroundStyle(.green)
                        .font(.subheadline)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Start")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(session.startLocation)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    }
                }
            }

            // Zieladresse (wenn vorhanden)
            if !session.endLocation.isEmpty {
                GlassDivider.tight

                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundStyle(.red)
                        .font(.subheadline)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Ziel")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(session.endLocation)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    }
                }
            }

            // Wetter (wenn bekannt)
            if session.weatherCondition != .unknown {
                GlassDivider.tight

                HStack(spacing: 8) {
                    Image(systemName: session.weatherCondition.icon)
                        .foregroundStyle(.orange)
                        .font(.subheadline)
                    Text(session.weatherCondition.description)
                        .font(.subheadline)
                        .foregroundStyle(.primary)

                    if let temp = session.temperature {
                        Text("·")
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.0f °C", temp))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .glassCard()
    }

    // MARK: - Leistungsdaten Card

    private var performanceCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Leistungsdaten")
                .font(.title3.bold())
                .foregroundStyle(.primary)

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
                    color: .green
                )

                // Kalorien
                StatBubble(
                    icon: .system("flame.fill"),
                    value: "\(session.calories) kcal",
                    color: .orange
                )

                // Hoehenmeter
                StatBubble(
                    icon: .system("mountain.2"),
                    value: "\(Int(session.elevationGain)) m",
                    color: .mint
                )

                // Geschwindigkeit
                StatBubble(
                    icon: .system("speedometer"),
                    value: String(format: "%.1f km/h", session.averageSpeed),
                    color: .purple
                )

                // Herzfrequenz (nur wenn vorhanden)
                if session.heartRate > 0 {
                    StatBubble(
                        icon: .system("heart.fill"),
                        value: "\(session.heartRate) bpm",
                        color: .red
                    )
                }
            }
        }
        .glassCard()
    }

    // MARK: - Bewertungs-Card

    private var ratingCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Bewertung")
                .font(.title3.bold())
                .foregroundStyle(.primary)

            // RPE
            if let rpe = session.perceivedExertion {
                HStack {
                    Label("RPE", systemImage: "gauge.with.dots.needle.67percent")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(rpe) / 10")
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                }
                GlassDivider.tight
            }

            // Energielevel
            if let energy = session.energyLevelBefore {
                HStack {
                    Label("Energie vor Tour", systemImage: "bolt.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(energy) / 5")
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                }
                GlassDivider.tight
            }

            // Intensitaets-Stars
            if session.intensity != .none {
                HStack(spacing: 4) {
                    Text("Belastung")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()

                    HStack(spacing: 4) {
                        ForEach(0..<5) { index in
                            Image(systemName: index < session.intensity.rawValue ? "star.fill" : "star")
                                .font(.caption)
                                .foregroundStyle(
                                    index < session.intensity.rawValue
                                    ? session.intensity.color
                                    : .gray.opacity(0.3)
                                )
                        }
                    }
                }
            }
        }
        .glassCard()
    }

    // MARK: - Notizen-Card

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notizen")
                .font(.title3.bold())
                .foregroundStyle(.primary)

            Text(session.notes)
                .font(.body)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .glassCard()
    }

    // MARK: - Loeschen

    private func deleteSession() {
        context.delete(session)
        try? context.save()
        dismiss()
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
        heartRate: 148,
        routeName: "Rheinufer-Runde",
        startLocation: "Köln Altstadt",
        endLocation: "Bonn Hauptbahnhof",
        notes: "Tolle Tour, leichter Gegenwind auf der Rückfahrt.",
        temperature: 18.0,
        isCompleted: true,
        perceivedExertion: 7,
        energyLevelBefore: 4,
        outdoorActivity: .eBike,
        intensity: .medium,
        weatherCondition: .sunny
    )
    return NavigationStack {
        OutdoorDetailView(session: session)
            .modelContainer(PreviewData.sharedContainer)
            .environmentObject(AppSettings.shared)
    }
}
