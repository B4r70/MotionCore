//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : UI-Elemente                                                      /
// Datei . . . . : ExerciseVideoView.swift                                          /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 06.01.2026                                                       /
// Beschreibung  : Darstellung der Krafttrainingübung als MP4 (lokal + remote)      /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI
import AVKit
import UIKit

struct ExerciseVideoView: View {
    @EnvironmentObject private var appSettings: AppSettings

    // Unterstützt sowohl assetName als auch Exercise-Objekt
    let assetName: String
    let remoteVideoPath: String?
    var size: CGFloat = 120

    // Main player (small thumbnail)
    @State private var player: AVQueuePlayer?
    @State private var looper: AVPlayerLooper?

    // Preview overlay player (large)
    @State private var isPreviewing = false
    @State private var previewPlayer: AVQueuePlayer?
    @State private var previewLooper: AVPlayerLooper?
    @State private var statusObservation: NSKeyValueObservation?

        // Loading State für Remote Videos
    @State private var isLoadingRemote = false

    private enum DisplayState: Equatable {
        case disabled
        case placeholder
        case loading
        case playing
        case previewing
    }

    private var hasLocalAsset: Bool { !assetName.isEmpty }
    private var hasRemoteVideo: Bool { remoteVideoPath != nil && !(remoteVideoPath?.isEmpty ?? true) }
    private var hasAnyVideo: Bool { hasLocalAsset || hasRemoteVideo }

    private var canPreview: Bool {
        appSettings.showExerciseVideos && hasAnyVideo
    }

    private var displayState: DisplayState {
        if !appSettings.showExerciseVideos { return .disabled }
        if !hasAnyVideo { return .placeholder }
        if isPreviewing { return .previewing }
        if isLoadingRemote { return .loading }
        if player != nil { return .playing }
        return .placeholder
    }

    // MARK: - Initializers

    // Bestehender Init (kompatibel mit bestehendem Code)
    // → nur lokal (Asset), kein Remote
    init(assetName: String, size: CGFloat = 120) {
        self.assetName = assetName
        self.remoteVideoPath = nil
        self.size = size
    }

    // Init mit Exercise-Objekt
    init(exercise: Exercise, size: CGFloat = 120) {
        self.assetName = exercise.mediaAssetName
        self.remoteVideoPath = exercise.videoPath
        self.size = size
    }

    // Direkter Init mit Remote-PATH (vormals Remote-URL)
    // (Ich nenne den Parameter bewusst "remoteVideoPath", damit du nicht wieder URL/Path verwechselst.)
    init(assetName: String = "", remoteVideoPath: String?, size: CGFloat = 120) {
        self.assetName = assetName
        self.remoteVideoPath = remoteVideoPath
        self.size = size
    }

    var body: some View {
        ZStack {
            mainContent
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .contentShape(RoundedRectangle(cornerRadius: 12))
                .onAppear { setupMainIfNeeded() }
                .onChange(of: appSettings.showExerciseVideos) { _, newValue in
                    if !newValue {
                        teardownAll()
                    } else {
                        setupMainIfNeeded()
                    }
                }
                .onDisappear {
                    player?.pause()
                    previewPlayer?.pause()
                    isPreviewing = false
                }
                // High priority because ActiveWorkout screens often have competing gestures (ScrollView, buttons)
                .highPriorityGesture(
                    LongPressGesture(minimumDuration: 0.15, maximumDistance: 40)
                        .onChanged { _ in
                            guard canPreview else { return }
                            guard !isPreviewing else { return }

                            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                                isPreviewing = true
                            }
                            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                            startPreview()
                        }
                        .onEnded { _ in
                            guard canPreview else { return }
                            stopPreview()
                        }
                )

            if displayState == .previewing && canPreview {
                previewOverlay.transition(.opacity)
            }
        }
    }

    private func teardownAll() {
        player?.pause()
        previewPlayer?.pause()

        statusObservation?.invalidate()
        statusObservation = nil

        player = nil
        looper = nil
        previewPlayer = nil
        previewLooper = nil
        isPreviewing = false
        isLoadingRemote = false
    }

    // MARK: - Main Content

    @ViewBuilder
    private var mainContent: some View {
        switch displayState {
            case .disabled, .placeholder:
                placeholder

            case .loading:
                loadingView

            case .playing, .previewing:
                if let player {
                    LoopingPlayerLayerView(player: player)
                        .frame(width: size, height: size)
                        .clipped()
                        .allowsHitTesting(false)
                } else {
                    placeholder
                }
        }
    }

    private var placeholder: some View {
        Image(systemName: "figure.strengthtraining.traditional")
            .font(.system(size: size * 0.5))
            .foregroundStyle(.secondary)
            .frame(width: size, height: size)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // Loading Indicator
    private var loadingView: some View {
        ZStack {
            placeholder

            ProgressView()
                .tint(.white)
                .scaleEffect(0.8)
        }
    }

    private func setupMainIfNeeded() {
        guard appSettings.showExerciseVideos else { return }
        guard player == nil else { return }

            // Priorität: Erst lokales Asset, dann Remote
        if hasLocalAsset, let localURL = mediaURL(for: assetName) {
            setupLocalPlayer(with: localURL)
        } else if hasRemoteVideo,
                  let path = remoteVideoPath,
                  let remoteURL = SupabaseStorageURLBuilder.publicURL(bucket: .exerciseVideos, path: path) {

              print("🎬 Remote video path:", path)
              print("🎬 Remote video url :", remoteURL.absoluteString)
              setupRemotePlayer(with: remoteURL)
          }
    }

    // Setup für lokale Videos
    private func setupLocalPlayer(with url: URL) {
        let item = AVPlayerItem(url: url)
        let q = AVQueuePlayer()
        q.isMuted = true

        looper = AVPlayerLooper(player: q, templateItem: item)
        player = q
        q.play()
    }

    // Setup für Remote-Videos
    private func setupRemotePlayer(with url: URL) {
        isLoadingRemote = true

        let item = AVPlayerItem(url: url)
        let q = AVQueuePlayer()
        q.isMuted = true

        statusObservation = item.observe(\.status, options: [.new]) { item, _ in
            DispatchQueue.main.async {
                switch item.status {
                case .readyToPlay:
                    isLoadingRemote = false
                case .failed:
                    isLoadingRemote = false
                    print("⚠️ Remote Video konnte nicht geladen werden: \(url)")
                default:
                    break
                }
            }
        }

        looper = AVPlayerLooper(player: q, templateItem: item)
        player = q
        q.play()
    }

        // MARK: - Preview Overlay

    private var previewOverlay: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture { stopPreview() }

            Group {
                if appSettings.showExerciseVideos, let previewPlayer {
                    LoopingPlayerLayerView(player: previewPlayer)
                        .allowsHitTesting(false)
                } else if isLoadingRemote {
                    loadingView
                } else {
                    placeholder
                }
            }
            .frame(maxWidth: 420)
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(radius: 20)
            .padding(24)
        }
    }

    private func startPreview() {
        guard canPreview else { return }
        player?.pause()
        guard appSettings.showExerciseVideos else { return }

        if let previewPlayer {
            previewPlayer.play()
            return
        }

            // Priorität: Lokales Asset, dann Remote
        var resolvedURL: URL?

        if hasLocalAsset {
            resolvedURL = mediaURL(for: assetName)
        } else if hasRemoteVideo, let path = remoteVideoPath {
            resolvedURL = SupabaseStorageURLBuilder.publicURL(bucket: .exerciseVideos, path: path)
        }

        guard let url = resolvedURL else { return }

        let item = AVPlayerItem(url: url)
        let q = AVQueuePlayer()
        q.isMuted = true

        previewLooper = AVPlayerLooper(player: q, templateItem: item)
        previewPlayer = q
        q.play()
    }

    private func stopPreview() {
        player?.play()
        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
            isPreviewing = false
        }
        previewPlayer?.pause()
    }

        // MARK: - Helpers

    private func mediaURL(for name: String) -> URL? {
        Bundle.main.url(forResource: name, withExtension: "mp4")
        ?? Bundle.main.url(forResource: name, withExtension: "mov")
    }
}

    // MARK: - Convenience Extensions

    // ✅ Best effort for an ExerciseSet snapshot (Active Workout, Templates, etc.)
extension ExerciseVideoView {

    /// ✅ Für Screens, die ein Exercise haben (Library, Picker, Cards)
    static func forExercise(_ exercise: Exercise, size: CGFloat = 80) -> ExerciseVideoView {
        ExerciseVideoView(
            assetName: exercise.mediaAssetName,
            remoteVideoPath: exercise.videoPath,
            size: size
        )
    }

    /// ✅ Für Screens, die nur Snapshots aus einem Set haben (Active Workout)
    static func forSet(_ set: ExerciseSet, size: CGFloat = 80) -> ExerciseVideoView {
        let asset = set.exerciseMediaAssetName
        let uuid = set.exerciseUUIDSnapshot

        // Wir bauen remotePath aus Snapshot, ohne set.exercise zu anfassen
        let remotePath: String? = {
            guard let _ = UUID(uuidString: uuid) else { return nil }
            return "\(uuid).mp4"
        }()

        return ExerciseVideoView(assetName: asset, remoteVideoPath: remotePath, size: size)
    }
    
        // ✅ Legacy/local-only usage
    static func forAsset(_ assetName: String, size: CGFloat = 80) -> ExerciseVideoView {
        ExerciseVideoView(assetName: assetName, size: size)
    }
}
