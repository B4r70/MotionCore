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
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(Color.blue)

                Text("Übungsdaten")
                    .font(.headline)

                Spacer()

                // System Badge
                if exercise.isSystemExercise {
                    SystemBadge()
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
                        .foregroundStyle(Color.orange)

                    ForEach(tips, id: \.self) { tip in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(Color.green)
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
                        .foregroundStyle(Color.blue)

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

            // Kenndaten
            VStack(alignment: .leading, spacing: 4) {
                Label("Kenndaten", systemImage: "info.circle")
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)

                DetailRow(label: "Kategorie", value: exercise.category.description)
                DetailRow(label: "Equipment", value: exercise.equipment.description)
                DetailRow(label: "Schwierigkeit", value: exercise.difficulty.description)
                if let apiID = exercise.apiID {
                    DetailRow(label: "ID", value: apiID.uuidString)
                }
            }
        }
    }
}

// MARK: - System Badge
private struct SystemBadge: View {
    var body: some View {
        Text("System-Übung")
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.15))
            .foregroundStyle(.blue)
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
