//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : UI-Elemente                                                      /
// Datei . . . . : LoopingPlayerView.swift                                          /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 06.01.2026                                                       /
// Beschreibung  : Darstellung der Krafttrainingübung als MP4 (lokal + remote)      /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI
import AVFoundation
import UIKit

struct LoopingPlayerView: UIViewRepresentable {
    let player: AVQueuePlayer
    var cornerRadius: CGFloat = 12

    func makeUIView(context: Context) -> PlayerContainerView {
        let v = PlayerContainerView()
        v.isOpaque = false
        v.backgroundColor = .clear

        v.playerLayer.player = player
        v.playerLayer.videoGravity = .resizeAspectFill

        // ✅ Wichtig: Masking auf *beiden* Ebenen
        v.layer.masksToBounds = true
        v.layer.cornerRadius = cornerRadius

        v.playerLayer.masksToBounds = true
        v.playerLayer.cornerRadius = cornerRadius

        return v
    }

    func updateUIView(_ uiView: PlayerContainerView, context: Context) {
        uiView.playerLayer.player = player

        // ✅ SwiftUI kann Bounds ändern → erneut setzen
        uiView.layer.cornerRadius = cornerRadius
        uiView.layer.masksToBounds = true

        uiView.playerLayer.cornerRadius = cornerRadius
        uiView.playerLayer.masksToBounds = true

        uiView.playerLayer.frame = uiView.bounds
    }
}

final class PlayerContainerView: UIView {
    override static var layerClass: AnyClass { AVPlayerLayer.self }
    
    // Safe force cast: layerClass is overridden to return AVPlayerLayer.self,
    // so the layer is guaranteed to be an AVPlayerLayer instance
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}
