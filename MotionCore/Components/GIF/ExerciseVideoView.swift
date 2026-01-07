//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : UI-Elemente                                                      /
// Datei . . . . : ExerciseVideoView.swift                                          /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 06.01.2026                                                       /
// Beschreibung  : Darstellung der Krafttrainingübung als MP4                       /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI
import AVKit
import UIKit

struct ExerciseVideoView: View {
    @EnvironmentObject private var appSettings: AppSettings
    let assetName: String
    var size: CGFloat = 120

    // Main player (small thumbnail)
    @State private var player: AVQueuePlayer?
    @State private var looper: AVPlayerLooper?

    // Preview overlay player (large)
    @State private var isPreviewing = false
    @State private var previewPlayer: AVQueuePlayer?
    @State private var previewLooper: AVPlayerLooper?

    private enum DisplayState: Equatable {
        case disabled
        case placeholder
        case playing
        case previewing
    }

    private var hasAsset: Bool { !assetName.isEmpty }

    private var canPreview: Bool {
        appSettings.showExerciseVideos && hasAsset
    }

    private var displayState: DisplayState {
        if !appSettings.showExerciseVideos { return .disabled }
        if !hasAsset { return .placeholder }
        if isPreviewing { return .previewing }
        if player != nil { return .playing }
        return .placeholder
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

        player = nil
        looper = nil
        previewPlayer = nil
        previewLooper = nil
        isPreviewing = false
    }

    // MARK: - Main Content

    @ViewBuilder
    private var mainContent: some View {
        switch displayState {
        case .disabled, .placeholder:
            placeholder

        case .playing, .previewing:
            if let player {
                VideoPlayer(player: player)
                    .disabled(true)
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

    private func setupMainIfNeeded() {
        guard appSettings.showExerciseVideos else { return }
        guard player == nil, !assetName.isEmpty else { return }
        guard let url = mediaURL(for: assetName) else { return }

        let item = AVPlayerItem(url: url)
        let q = AVQueuePlayer()
        q.isMuted = true

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
                    VideoPlayer(player: previewPlayer)
                        .disabled(true)
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
        guard !assetName.isEmpty else { return }

        if let previewPlayer {
            previewPlayer.play()
            return
        }

        guard let url = mediaURL(for: assetName) else { return }

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
