//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : UI-Elemente                                                      /
// Datei . . . . : ExerciseGifView.swift                                            /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 17.12.2025                                                       /
// Beschreibung  : Darstellung der Krafttrainingübung als GIF                       /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI
import WebKit

struct ExerciseGifView: View {
    let assetName: String          // example: "ShoulderPress_SeatedDumbbell" (WITHOUT .gif)
    var size: CGFloat = 120

    var body: some View {
        if assetName.isEmpty {
            placeholder
        } else {
            GifWebView(gifName: assetName)
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var placeholder: some View {
        Image(systemName: "figure.strengthtraining.traditional")
            .font(.system(size: size * 0.5))
            .foregroundStyle(.secondary)
            .frame(width: size, height: size)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct GifWebView: UIViewRepresentable {
    let gifName: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .clear
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard let url = Bundle.main.url(forResource: gifName, withExtension: "gif") else {
            print("GIF not found in bundle: \(gifName).gif")
            return
        }

        let data = (try? Data(contentsOf: url)) ?? Data()
        uiView.load(
            data,
            mimeType: "image/gif",
            characterEncodingName: "UTF-8",
            baseURL: url.deletingLastPathComponent()
        )
    }
}
