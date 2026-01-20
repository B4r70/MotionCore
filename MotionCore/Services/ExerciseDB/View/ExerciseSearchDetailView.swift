//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Views/Exercise                                                   /
// Datei . . . . : ExerciseSearchDetailView.swift                                   /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 21.01.2026                                                       /
// Beschreibung  : DetailView für Übungen-Vorschau vor Import aus Supabase         /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI
import SwiftData
import AVKit

struct ExerciseSearchDetailView: View {
    let searchResult: SupabaseExerciseSearchResult
    let isImported: Bool
    let onImport: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appSettings: AppSettings
    
    @State private var showVideoPlayer = false
    
    var body: some View {
        ZStack {
            AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)
            
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Video/Poster Preview
                    videoPreviewSection
                    
                    // MARK: - Basic Info Card
                    basicInfoCard
                    
                    // MARK: - Instructions Card
                    instructionsCard
                    
                    // MARK: - Equipment & Muscles Card
                    detailsCard
                    
                    // MARK: - Import Status
                    if isImported {
                        importedBadge
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
            .scrollIndicators(.hidden)
            
            // MARK: - Floating Import Button
            if !isImported {
                VStack {
                    Spacer()
                    importButton
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                }
            }
        }
        .navigationTitle(searchResult.name)
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showVideoPlayer) {
            if let videoPath = searchResult.videoPath,
               let url = SupabaseStorageURLBuilder.publicURL(bucket: .exerciseVideos, path: videoPath) {
                VideoPlayerSheet(url: url, title: searchResult.name)
            }
        }
    }
    
    // MARK: - Video Preview Section
    
    @ViewBuilder
    private var videoPreviewSection: some View {
        if let posterPath = searchResult.posterPath,
           let posterURL = SupabaseStorageURLBuilder.publicURL(bucket: .exercisePosters, path: posterPath) {
            
            Button {
                if searchResult.videoPath != nil {
                    showVideoPlayer = true
                }
            } label: {
                AsyncImage(url: posterURL) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(height: 200)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 200)
                            .clipped()
                    case .failure:
                        Image(systemName: "photo.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                            .frame(height: 200)
                    @unknown default:
                        EmptyView()
                    }
                }
                .overlay(alignment: .center) {
                    if searchResult.videoPath != nil {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: "play.fill")
                                .font(.title)
                                .foregroundStyle(.white)
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        } else {
            // Placeholder wenn kein Poster vorhanden
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .frame(height: 200)
                
                VStack(spacing: 12) {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.blue)
                    
                    Text("Keine Vorschau verfügbar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    // MARK: - Basic Info Card
    
    private var basicInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.blue)
                
                Text("Übersicht")
                    .font(.headline)
                
                Spacer()
                
                // Difficulty Stars
                if let difficulty = searchResult.difficulty {
                    HStack(spacing: 4) {
                        ForEach(0..<difficultyStars(difficulty), id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundStyle(difficultyColor(difficulty))
                        }
                    }
                }
            }
            
            GlassDivider()
            
            // Category & Force Type
            if let category = searchResult.category {
                DetailRow(
                    icon: "tag.fill",
                    label: "Kategorie",
                    value: category.capitalized
                )
            }
            
            if let forceType = searchResult.forceType {
                DetailRow(
                    icon: "arrow.up.arrow.down",
                    label: "Krafttyp",
                    value: forceType.capitalized
                )
            }
            
            if let mechanicType = searchResult.mechanicType {
                DetailRow(
                    icon: "gearshape.fill",
                    label: "Mechanik",
                    value: mechanicType.capitalized
                )
            }
            
            if let difficulty = searchResult.difficulty {
                DetailRow(
                    icon: "chart.bar.fill",
                    label: "Schwierigkeit",
                    value: difficulty.capitalized
                )
            }
        }
        .glassCard()
    }
    
    // MARK: - Instructions Card
    
    @ViewBuilder
    private var instructionsCard: some View {
        if let description = searchResult.description, !description.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "list.bullet.clipboard")
                        .foregroundStyle(.green)
                    
                    Text("Anleitung")
                        .font(.headline)
                }
                
                GlassDivider()
                
                // Parse Steps (split by double newline)
                let steps = description
                    .components(separatedBy: "\n\n")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                
                if steps.count > 1 {
                    // Numbered Steps
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(index + 1)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .frame(width: 24, height: 24)
                                .background(Circle().fill(Color.green.gradient))
                            
                            Text(step)
                                .font(.body)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                } else {
                    // Single paragraph
                    Text(description)
                        .font(.body)
                }
            }
            .glassCard()
        }
    }
    
    // MARK: - Details Card (Equipment & Muscles)
    
    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.doc.horizontal")
                    .foregroundStyle(.orange)
                
                Text("Details")
                    .font(.headline)
            }
            
            GlassDivider()
            
            // Equipment
            if !searchResult.equipment.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Equipment", systemImage: "dumbbell.fill")
                        .font(.subheadline.bold())
                        .foregroundStyle(.secondary)
                    
                    FlowLayout(spacing: 8) {
                        ForEach(searchResult.equipment, id: \.self) { eq in
                            Text(eq)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.blue.opacity(0.2))
                                .foregroundStyle(.blue)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            
            // Muscles
            if !searchResult.muscles.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Muskelgruppen", systemImage: "figure.strengthtraining.traditional")
                        .font(.subheadline.bold())
                        .foregroundStyle(.secondary)
                    
                    FlowLayout(spacing: 8) {
                        ForEach(searchResult.muscles, id: \.self) { muscle in
                            Text(muscle)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.green.opacity(0.2))
                                .foregroundStyle(.green)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .glassCard()
    }
    
    // MARK: - Import Button
    
    private var importButton: some View {
        Button {
            onImport()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                
                Text("Übung importieren")
                    .font(.headline)
                
                Spacer()
                
                Image(systemName: "arrow.down.circle")
                    .font(.title3)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [.blue, .blue.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .blue.opacity(0.4), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Imported Badge
    
    private var importedBadge: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(.green)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Bereits importiert")
                    .font(.headline)
                
                Text("Diese Übung ist bereits in deiner Bibliothek")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Helpers
    
    private func difficultyStars(_ difficulty: String) -> Int {
        switch difficulty.lowercased() {
        case "beginner": return 1
        case "intermediate": return 2
        case "advanced", "expert": return 3
        default: return 2
        }
    }
    
    private func difficultyColor(_ difficulty: String) -> Color {
        switch difficulty.lowercased() {
        case "beginner": return .green
        case "intermediate": return .orange
        case "advanced", "expert": return .red
        default: return .orange
        }
    }
}

// MARK: - Detail Row Component

private struct DetailRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(.primary)
        }
    }
}

// MARK: - Flow Layout for Tags

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: result.positions[index], proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ExerciseSearchDetailView(
            searchResult: SupabaseExerciseSearchResult(
                id: UUID(),
                name: "Schrägbank Kurzhantel Drücken",
                description: "Lege dich auf eine Schrägbank.\n\nHalte die Kurzhanteln auf Brusthöhe.\n\nDrücke explosiv nach oben.",
                equipment: ["Kurzhantel", "Schrägbank"],
                muscles: ["Obere Brust", "Vordere Schulter", "Trizeps"],
                difficulty: "intermediate",
                videoPath: "test.mp4",
                posterPath: "test.jpg",
                category: "strength",
                forceType: "push",
                mechanicType: "compound"
            ),
            isImported: false,
            onImport: {
                print("Import triggered")
            }
        )
        .environmentObject(AppSettings.shared)
    }
}
