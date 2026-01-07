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
import UIKit
import ImageIO
import AVFoundation

struct ExerciseGifView: View {
    let assetName: String          // example: "ShoulderPress_SeatedDumbbell" (WITHOUT .gif)
    var size: CGFloat = 120

    var body: some View {
        if assetName.isEmpty {
            placeholder
        } else {
            GifImageView(gifName: assetName)
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

private struct GifImageView: UIViewRepresentable {
    let gifName: String

    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.backgroundColor = .clear
        return imageView
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {
        uiView.image = UIImage.animatedGIF(named: gifName)
    }
}

private extension UIImage {
    static func animatedGIF(named name: String) -> UIImage? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "gif"),
              let data = try? Data(contentsOf: url) else {
            print("GIF not found in bundle: \(name).gif")
            return nil
        }
        return animatedGIF(data: data)
    }

    static func animatedGIF(data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let count = CGImageSourceGetCount(source)
        guard count > 0 else { return nil }

        var images: [UIImage] = []
        images.reserveCapacity(count)

        var duration: TimeInterval = 0

        for i in 0..<count {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) else { continue }
            images.append(UIImage(cgImage: cgImage))

            duration += frameDuration(at: i, source: source)
        }

        if duration <= 0 { duration = Double(count) * 0.1 } // Fallback
        return animatedImageScaled(images: images, duration: duration)
    }

    static func frameDuration(at index: Int, source: CGImageSource) -> TimeInterval {
        let defaultFrameDuration = 0.1

        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any],
              let gif = properties[kCGImagePropertyGIFDictionary] as? [CFString: Any] else {
            return defaultFrameDuration
        }

        // bevorzugt: unclamped delay
        let unclamped = gif[kCGImagePropertyGIFUnclampedDelayTime] as? TimeInterval
        let clamped = gif[kCGImagePropertyGIFDelayTime] as? TimeInterval
        let delay = unclamped ?? clamped ?? defaultFrameDuration

        // GIFs haben manchmal 0 -> das killt Animationen
        return delay < 0.02 ? defaultFrameDuration : delay
    }

    // Skalierung des GIF damit dieses ins Frame passt
    private static func animatedImageScaled(
        images: [UIImage],
        duration: TimeInterval
    ) -> UIImage? {

        guard let maxSize = images.map({ $0.size }).max(by: {
            $0.width * $0.height < $1.width * $1.height
        }) else { return nil }

        let renderer = UIGraphicsImageRenderer(size: maxSize)

        let scaledImages = images.map { image in
            renderer.image { _ in
                let rect = AVMakeRect(
                    aspectRatio: image.size,
                    insideRect: CGRect(origin: .zero, size: maxSize)
                )
                image.draw(in: rect)
            }
        }

        return UIImage.animatedImage(with: scaledImages, duration: duration)
    }
}
