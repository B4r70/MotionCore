//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Übungsbibliothek                                                 /
// Datei . . . . : ExerciseAPIView.swift                                            /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 09.01.2026                                                       /
// Beschreibung  : Anzeige der Felder aus der ExerciseDB                            /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI
import AVKit

struct ExerciseAPIView: View {
    let exercise: Exercise
    @State private var showVideoPlayer = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "cloud.fill")
                    .foregroundStyle(.blue)

                Text("API-Informationen")
                    .font(.headline)

                Spacer()

                // Provider Badge
                if let provider = exercise.apiProvider {
                    ProviderBadge(provider: provider)
                }
            }

            Divider()

            // Video Player Button
            if let path = exercise.videoPath,
               let url = SupabaseStorageURLBuilder.publicURL(bucket: .exerciseVideos, path: path) {
                Button {
                    showVideoPlayer = true
                } label: {
                    HStack {
                        Image(systemName: "play.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.purple)

                        VStack(alignment: .leading) {
                            Text("Video abspielen")
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                            Text("MP4")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color.purple.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .sheet(isPresented: $showVideoPlayer) {
                    VideoPlayerSheet(url: url, title: exercise.name)
                }
            }

            // Overview (ausführliche Beschreibung)
            if let overview = exercise.apiOverview, !overview.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Beschreibung", systemImage: "text.alignleft")
                        .font(.subheadline.bold())
                        .foregroundStyle(.secondary)

                    Text(overview)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }
            }

            // Exercise Tips
            if let tips = exercise.apiExerciseTips, !tips.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Trainingstipps", systemImage: "lightbulb.fill")
                        .font(.subheadline.bold())
                        .foregroundStyle(.orange)

                    ForEach(tips, id: \.self) { tip in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                            Text(tip)
                                .font(.caption)
                        }
                    }
                }
            }

            // Variations
            if let variations = exercise.apiVariations, !variations.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Variationen", systemImage: "arrow.triangle.branch")
                        .font(.subheadline.bold())
                        .foregroundStyle(.blue)

                    ForEach(variations, id: \.self) { variation in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 6))
                                .foregroundStyle(.secondary)
                                .padding(.top, 6)
                            Text(variation)
                                .font(.caption)
                        }
                    }
                }
            }

            // API Details
            VStack(alignment: .leading, spacing: 4) {
                Label("API Details", systemImage: "info.circle")
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)

                if let apiID = exercise.apiID {
                    DetailRow(label: "ID", value: apiID.uuidString)
                }
                if let bodyPart = exercise.apiBodyPart {
                    DetailRow(label: "Körperteil", value: bodyPart)
                }
                if let target = exercise.apiTarget {
                    DetailRow(label: "Zielmuskel", value: target)
                }
                if let equipment = exercise.apiEquipment {
                    DetailRow(label: "Equipment", value: equipment)
                }
            }
        }
    }
}

// MARK: - Provider Badge
private struct ProviderBadge: View {
    let provider: String

    var body: some View {
        let label: String
        let bg: Color
        let fg: Color

        switch provider {
        case "exercisedb_v2":
            label = "ExerciseDB v2"
            bg = Color.purple.opacity(0.2)
            fg = .purple
        case "rapidapi":
            label = "RapidAPI"
            bg = Color.blue.opacity(0.2)
            fg = .blue
        case "supabase":
            label = "Supabase"
            bg = Color.green.opacity(0.2)
            fg = .green
        default:
            label = provider
            bg = Color.gray.opacity(0.2)
            fg = .secondary
        }

        return Text(label)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(bg)
            .foregroundStyle(fg)
            .clipShape(Capsule())
    }
}

// MARK: - Detail Row
private struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
        }
    }
}

// MARK: - Video Player Sheet
struct VideoPlayerSheet: View {
    let url: URL
    let title: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VideoPlayer(player: AVPlayer(url: url))
                .ignoresSafeArea()
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Schließen") {
                            dismiss()
                        }
                    }
                }
        }
    }
}
