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
    let assetName: String
    var size: CGFloat = 120

    // Main player (small thumbnail)
    @State private var player: AVQueuePlayer?
    @State private var looper: AVPlayerLooper?

    // Preview overlay player (large)
    @State private var isPreviewing = false
    @State private var previewPlayer: AVQueuePlayer?
    @State private var previewLooper: AVPlayerLooper?

    var body: some View {
        ZStack {
            mainContent
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .contentShape(RoundedRectangle(cornerRadius: 12))
                .onAppear { setupMainIfNeeded() }
                .onDisappear {
                    player?.pause()
                    previewPlayer?.pause()
                    isPreviewing = false
                }
                // High priority because ActiveWorkout screens often have competing gestures (ScrollView, buttons)
                .highPriorityGesture(
                    LongPressGesture(minimumDuration: 0.15, maximumDistance: 40)
                        .onChanged { _ in
                            // Fire once when entering preview
                            if !isPreviewing {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                                    isPreviewing = true
                                }
                                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                                startPreview()
                            }
                        }
                        .onEnded { _ in
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                                isPreviewing = false
                            }
                            previewPlayer?.pause()

                            // Optional cleanup (uncomment if you want to fully release resources after each press)
                            // previewPlayer = nil
                            // previewLooper = nil
                        }
                )

            if isPreviewing {
                previewOverlay
                    .transition(.opacity)
            }
        }
    }

    // MARK: - Main Content

    @ViewBuilder
    private var mainContent: some View {
        if assetName.isEmpty {
            placeholder
        } else if let player {
            VideoPlayer(player: player)
                .disabled(true)
                // Critical: AVKit can swallow touches; ensure SwiftUI wrapper receives gestures.
                .allowsHitTesting(false)
        } else {
            placeholder
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
        guard player == nil, !assetName.isEmpty else { return }
        guard let url = mediaURL(for: assetName) else { return }

        let item = AVPlayerItem(url: url)
        let q = AVQueuePlayer()
        q.isMuted = true

        // Hold looper strongly (State) – otherwise it stops looping
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
                if let previewPlayer {
                    VideoPlayer(player: previewPlayer)
                        .disabled(true)
                        // NOTE: Do NOT set allowsHitTesting(false) here, otherwise taps may "pass through".
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
        guard !assetName.isEmpty else { return }

        // If already created, just resume playback
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
