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
                    Text(provider == "exercisedb_v2" ? "v2" : "RapidAPI")
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(provider == "exercisedb_v2" ? Color.purple.opacity(0.2) : Color.blue.opacity(0.2))
                        .foregroundStyle(provider == "exercisedb_v2" ? .purple : .blue)
                        .clipShape(Capsule())
                }
            }
            
            Divider()
            
            // Video Player Button
            if let videoURL = exercise.videoURL, let url = URL(string: videoURL) {
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
                            Text("MP4 von ExerciseDB")
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
                    DetailRow(label: "ID", value: apiID)
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
