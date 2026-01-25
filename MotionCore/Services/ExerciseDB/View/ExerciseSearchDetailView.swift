//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Views/Exercise                                                   /
// Datei . . . . : ExerciseSearchDetailView.swift                                   /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 25.01.2026                                                       /
// Beschreibung  : DetailView für Übungen-Vorschau vor Import aus Supabase          /
// ---------------------------------------------------------------------------------/
// FIXED V2: Layout komplett neu strukturiert - Tags nur unten!                     /
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
                    // 1. Video/Poster Preview
                    videoPreviewCard

                    // 2. Quick Info (Category, Difficulty, Force) - KOMPAKT
                    quickInfoCard

                    // 3. Instructions
                    if let description = searchResult.description, !description.isEmpty {
                        instructionsCard(description)
                    }

                    // 4. Equipment & Muscles - NUR HIER!
                    equipmentAndMusclesCard

                    // 5. Import Status
                    if isImported {
                        importedBadge
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
            .scrollIndicators(.hidden)

            // Floating Import Button
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

    // MARK: - 1. Video Preview Card

    @ViewBuilder
    private var videoPreviewCard: some View {
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
                        videoPlaceholder
                    @unknown default:
                        EmptyView()
                    }
                }
                .overlay(alignment: .center) {
                    if searchResult.videoPath != nil {
                        playButton
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
            videoPlaceholder
        }
    }

    private var videoPlaceholder: some View {
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

    private var playButton: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 60, height: 60)

            Image(systemName: "play.fill")
                .font(.title)
                .foregroundStyle(.white)
        }
    }

    // MARK: - 2. Quick Info Card (KOMPAKT!)

    private var quickInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header mit Difficulty Stars
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

            // Kompakte Grid mit allen Infos
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {

                if let category = searchResult.category {
                    InfoBubble(
                        icon: "tag.fill",
                        label: "Kategorie",
                        value: category.capitalized
                    )
                }

                if let difficulty = searchResult.difficulty {
                    InfoBubble(
                        icon: "chart.bar.fill",
                        label: "Schwierigkeit",
                        value: difficulty.capitalized
                    )
                }

                if let forceType = searchResult.forceType {
                    InfoBubble(
                        icon: "arrow.up.arrow.down",
                        label: "Krafttyp",
                        value: forceType.capitalized
                    )
                }

                if let mechanicType = searchResult.mechanicType {
                    InfoBubble(
                        icon: "gearshape.fill",
                        label: "Mechanik",
                        value: mechanicType.capitalized
                    )
                }
            }
        }
        .glassCard()
    }

    // MARK: - 3. Instructions Card

    @ViewBuilder
    private func instructionsCard(_ description: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "list.bullet.clipboard")
                    .foregroundStyle(.green)

                Text("Anleitung")
                    .font(.headline)
            }

            GlassDivider()

            // Parse Steps
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

    // MARK: - 4. Equipment & Muscles Card - NUR HIER WERDEN TAGS GERENDERT!

    private var equipmentAndMusclesCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "chart.bar.doc.horizontal")
                    .foregroundStyle(.orange)

                Text("Equipment & Muskelgruppen")
                    .font(.headline)
            }

            GlassDivider()

            // Equipment Section
            if !searchResult.equipment.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: "dumbbell.fill")
                            .font(.caption)
                            .foregroundStyle(.blue)

                        Text("Equipment")
                            .font(.subheadline.bold())
                            .foregroundStyle(.secondary)
                    }

                    // Equipment Tags
                    FlowLayout(spacing: 8) {
                        ForEach(searchResult.equipment, id: \.self) { equipment in
                            TagView(text: equipment, color: .blue)
                        }
                    }
                }
            }

            // Divider zwischen Equipment und Muscles
            if !searchResult.equipment.isEmpty && !searchResult.muscles.isEmpty {
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 1)
                    .padding(.vertical, 4)
            }

            // Muscles Section
            if !searchResult.muscles.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.caption)
                            .foregroundStyle(.green)

                        Text("Muskelgruppen")
                            .font(.subheadline.bold())
                            .foregroundStyle(.secondary)
                    }

                    // Muscle Tags - NUR HIER!
                    FlowLayout(spacing: 8) {
                        ForEach(searchResult.muscles, id: \.self) { muscle in
                            TagView(text: muscle, color: .green)
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

// MARK: - Tag Component (für Equipment & Muscles)

private struct TagView: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - Info Bubble (für Quick Info Grid)

private struct InfoBubble: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Flow Layout (für Tags)

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
            let p = result.positions[index]
            subview.place(
                at: CGPoint(x: bounds.minX + p.x, y: bounds.minY + p.y),
                proposal: .unspecified
            )
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
                name: "Bankdrücken",
                description: "Lege dich auf eine Bank mit flachen Füßen.\n\nHalte die Hantel auf Brusthöhe.\n\nDrücke explosiv nach oben.",
                equipment: ["Langhantel", "Flachbank"],
                muscles: ["Mittlere Brust", "Vordere Schulter", "Trizeps (Langer Kopf)", "Trizeps (Lateraler Kopf)", "Trizeps (Medialer Kopf)"],
                difficulty: "intermediate",
                videoPath: nil,
                posterPath: nil,
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
