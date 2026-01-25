//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : UI-Elemente                                                      /
// Datei . . . . : ExerciseVideoView.swift                                          /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 06.01.2026                                                       /
// Beschreibung  : Darstellung der Krafttrainingsübung mit Poster + Video           /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI
import AVKit
import UIKit

struct ExerciseVideoView: View {
    @EnvironmentObject private var appSettings: AppSettings

    // Media Assets
    let assetName: String
    let posterPath: String?
    let videoPath: String?
    var size: CGFloat = 120

    // States
    @State private var isPlayingVideo = false
    @State private var isShowingPreview = false  // NEU: Fullscreen Preview
    @State private var player: AVQueuePlayer?
    @State private var looper: AVPlayerLooper?
    @State private var previewPlayer: AVQueuePlayer?  // NEU: Separater Player für Preview
    @State private var previewLooper: AVPlayerLooper?  // NEU
    @State private var isLoadingVideo = false
    @State private var posterImage: UIImage?
    @State private var isLoadingPoster = false

    // Display Logic
    private var hasLocalAsset: Bool { !assetName.isEmpty }
    private var hasRemoteVideo: Bool { videoPath != nil && !(videoPath?.isEmpty ?? true) }
    private var hasRemotePoster: Bool { posterPath != nil && !(posterPath?.isEmpty ?? true) }
    private var hasAnyVideo: Bool { hasLocalAsset || hasRemoteVideo }

    // MARK: - Initializers

    init(assetName: String = "", posterPath: String? = nil, videoPath: String? = nil, size: CGFloat = 120) {
        self.assetName = assetName
        self.posterPath = posterPath
        self.videoPath = videoPath
        self.size = size
    }

    init(exercise: Exercise, size: CGFloat = 120) {
        self.assetName = exercise.mediaAssetName
        self.posterPath = exercise.posterPath
        self.videoPath = exercise.videoPath
        self.size = size
    }

    var body: some View {
        ZStack {
            // Thumbnail View
            thumbnailView
                .onTapGesture {
                    if hasAnyVideo && appSettings.showExerciseVideos {
                        showPreview()
                    }
                }

            // Fullscreen Preview Overlay
            if isShowingPreview {
                previewOverlay
                    .transition(.opacity)
            }
        }
    }

    // MARK: - Thumbnail View

    private var thumbnailView: some View {
        ZStack {
            // Base: Poster oder Placeholder
            posterView
                .frame(width: size, height: size)

            // Loading Indicator
            if isLoadingPoster {
                loadingOverlay
            }

            // Play Button Overlay (nur wenn Video verfügbar)
            if hasAnyVideo && appSettings.showExerciseVideos {
                playButtonOverlay
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .onAppear {
            loadPosterIfNeeded()
        }
        .onDisappear {
            stopVideo()
            stopPreview()
        }
        .onChange(of: posterPath) { _, _ in
            posterImage = nil
            loadPosterIfNeeded()
        }
    }

    // MARK: - Poster View

    @ViewBuilder
    private var posterView: some View {
        if let posterImage {
            // Remote Poster geladen
            Image(uiImage: posterImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size, height: size)
        } else if hasLocalAsset, let localURL = mediaURL(for: assetName, extension: "jpg") ?? mediaURL(for: assetName, extension: "png") {
            // Lokales Poster
            AsyncImage(url: localURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size, height: size)
                case .failure, .empty:
                    placeholder
                @unknown default:
                    placeholder
                }
            }
        } else {
            // Fallback Placeholder
            placeholder
        }
    }

    private var placeholder: some View {
        Image(systemName: "figure.strengthtraining.traditional")
            .font(.system(size: size * 0.4))
            .foregroundStyle(.secondary)
            .frame(width: size, height: size)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Play Button Overlay

    private var playButtonOverlay: some View {
        ZStack {
            Circle()
                .fill(.black.opacity(0.6))
                .frame(width: size * 0.35, height: size * 0.35)

            Image(systemName: "play.fill")
                .font(.system(size: size * 0.15))
                .foregroundStyle(.white)
        }
    }

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
            ProgressView()
                .tint(.white)
                .scaleEffect(0.8)
        }
    }

    // MARK: - Preview Overlay (Fullscreen)

    private var previewOverlay: some View {
        ZStack {
            // Dimmed Background
            Color.black.opacity(0.75)
                .ignoresSafeArea()
                .onTapGesture {
                    stopPreview()
                }

            // Video Player (doppelte Größe)
            VStack {
                if let previewPlayer {
                    LoopingPlayerView(player: previewPlayer, cornerRadius: 20)
                        .frame(width: size * 2, height: size * 2)
                        .shadow(color: .black.opacity(0.3), radius: 20)
                        .onTapGesture {
                            stopPreview()  // ✅ Tap auf Video schließt Preview
                        }
                } else if isLoadingVideo {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                            .frame(width: size * 2, height: size * 2)

                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.5)
                    }
                    .onTapGesture {
                        stopPreview()  // ✅ Tap während Loading schließt auch
                    }
                } else {
                    // Fallback Poster in Preview Size
                    posterView
                        .frame(width: size * 2, height: size * 2)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.3), radius: 20)
                        .onTapGesture {
                            stopPreview()  // ✅ Tap auf Poster schließt auch
                        }
                }
            }
        }
    }

    // MARK: - Poster Loading

    private func loadPosterIfNeeded() {
        guard hasRemotePoster, posterImage == nil else { return }
        guard let path = posterPath else { return }
        guard let url = SupabaseStorageURLBuilder.publicURL(bucket: .exercisePosters, path: path) else { return }

        isLoadingPoster = true

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                await MainActor.run {
                    posterImage = UIImage(data: data)
                    isLoadingPoster = false
                }
            } catch {
                print("⚠️ Failed to load poster: \(error)")
                await MainActor.run {
                    isLoadingPoster = false
                }
            }
        }
    }

    // MARK: - Video Control

    private func showPreview() {
        guard appSettings.showExerciseVideos else { return }
        guard hasAnyVideo else { return }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            isShowingPreview = true
        }

        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        startPreviewVideo()
    }

    private func stopPreview() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
            isShowingPreview = false
        }

        previewPlayer?.pause()
        previewPlayer = nil
        previewLooper = nil
        isLoadingVideo = false
    }

    private func startPreviewVideo() {
        guard appSettings.showExerciseVideos else { return }
        guard previewPlayer == nil else {
            previewPlayer?.play()
            return
        }

        var videoURL: URL?

        // Priorität: Lokales Asset, dann Remote
        if hasLocalAsset, let localURL = mediaURL(for: assetName, extension: "mp4") ?? mediaURL(for: assetName, extension: "mov") {
            videoURL = localURL
        } else if hasRemoteVideo, let path = videoPath {
            videoURL = SupabaseStorageURLBuilder.publicURL(bucket: .exerciseVideos, path: path)
            isLoadingVideo = true
        }

        guard let url = videoURL else { return }

        let item = AVPlayerItem(url: url)
        let q = AVQueuePlayer()
        q.isMuted = true

        // Observe loading status für remote videos
        if hasRemoteVideo {
            _ = item.observe(\.status, options: [.new]) { item, _ in
                DispatchQueue.main.async {
                    switch item.status {
                    case .readyToPlay:
                        isLoadingVideo = false
                    case .failed:
                        isLoadingVideo = false
                        print("⚠️ Remote Video failed to load: \(url)")
                        stopPreview()
                    default:
                        break
                    }
                }
            }
        }

        previewLooper = AVPlayerLooper(player: q, templateItem: item)
        previewPlayer = q
        q.play()
    }

    private func toggleVideo() {
        guard appSettings.showExerciseVideos else { return }
        guard hasAnyVideo else { return }

        if isPlayingVideo {
            stopVideo()
        } else {
            startVideo()
        }

        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    private func startVideo() {
        guard appSettings.showExerciseVideos else { return }
        guard player == nil else {
            withAnimation(.easeInOut(duration: 0.3)) {
                isPlayingVideo = true
            }
            player?.play()
            return
        }

        var videoURL: URL?

        // Priorität: Lokales Asset, dann Remote
        if hasLocalAsset, let localURL = mediaURL(for: assetName, extension: "mp4") ?? mediaURL(for: assetName, extension: "mov") {
            videoURL = localURL
        } else if hasRemoteVideo, let path = videoPath {
            videoURL = SupabaseStorageURLBuilder.publicURL(bucket: .exerciseVideos, path: path)
            isLoadingVideo = true
        }

        guard let url = videoURL else { return }

        let item = AVPlayerItem(url: url)
        let q = AVQueuePlayer()
        q.isMuted = true

        // Observe loading status für remote videos
        if hasRemoteVideo {
            _ = item.observe(\.status, options: [.new]) { item, _ in
                DispatchQueue.main.async {
                    switch item.status {
                    case .readyToPlay:
                        isLoadingVideo = false
                    case .failed:
                        isLoadingVideo = false
                        print("⚠️ Remote Video failed to load: \(url)")
                        stopVideo()
                    default:
                        break
                    }
                }
            }
        }

        looper = AVPlayerLooper(player: q, templateItem: item)
        player = q

        withAnimation(.easeInOut(duration: 0.3)) {
            isPlayingVideo = true
        }

        q.play()
    }

    private func stopVideo() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isPlayingVideo = false
        }

        player?.pause()
        player = nil
        looper = nil
        isLoadingVideo = false
    }

    // MARK: - Helpers

    private func mediaURL(for name: String, extension ext: String) -> URL? {
        Bundle.main.url(forResource: name, withExtension: ext)
    }
}

// MARK: - Convenience Extensions

extension ExerciseVideoView {
    /// Für Screens mit Exercise-Objekt (Library, Picker, Cards)
    static func forExercise(_ exercise: Exercise, size: CGFloat = 80) -> ExerciseVideoView {
        ExerciseVideoView(exercise: exercise, size: size)
    }

    /// Für Screens mit nur Snapshots aus einem Set (Active Workout)
    static func forSet(_ set: ExerciseSet, size: CGFloat = 80) -> ExerciseVideoView {
        let asset = set.exerciseMediaAssetName
        let uuid = set.exerciseUUIDSnapshot

        let remotePoster: String? = {
            guard UUID(uuidString: uuid) != nil else { return nil }
            return "\(uuid.lowercased()).jpg"
        }()

        let remoteVideo: String? = {
            guard UUID(uuidString: uuid) != nil else { return nil }
            return "\(uuid.lowercased()).mp4"
        }()

        return ExerciseVideoView(
            assetName: asset,
            posterPath: remotePoster,
            videoPath: remoteVideo,
            size: size
        )
    }

    /// Legacy/local-only usage
    static func forAsset(_ assetName: String, size: CGFloat = 80) -> ExerciseVideoView {
        ExerciseVideoView(assetName: assetName, size: size)
    }
}
