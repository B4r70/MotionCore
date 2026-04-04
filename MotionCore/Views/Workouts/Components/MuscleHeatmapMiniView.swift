//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Workout                                                          /
// Datei . . . . : MuscleHeatmapMiniView.swift                                      /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 26.03.2026                                                       /
// Beschreibung  : Kompakte Session-Heatmap für StrengthDetailView (nicht-interakt. /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftData
import SwiftUI
import WebKit

struct MuscleHeatmapMiniView: View {

    let session: StrengthSession

    // Gecachte Berechnung — nur einmal pro Session berechnen
    @State private var trainedRegionIds: Set<String> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundStyle(Color.orange)
                Text("Trainierte Muskeln")
                    .font(.headline)
                Spacer()
            }

            MuscleHeatmapMiniSVGView(trainedRegionIds: trainedRegionIds)
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding()
        .glassCard()
        .task(id: session.persistentModelID) {
            trainedRegionIds = computeTrainedRegionIds()
        }
    }

    /// Berechnet alle SVG-Regionen, die in dieser Session trainiert wurden
    private func computeTrainedRegionIds() -> Set<String> {
        var regionIds = Set<String>()
        for set in session.safeExerciseSets where set.isCompleted {
            // Feingranulare Muskeln bevorzugen, sonst Fallback auf MuscleGroup
            if let exercise = set.exercise {
                let detailed = exercise.detailedPrimaryMuscles.isEmpty
                    ? DetailedMuscle.allCases.filter { exercise.primaryMuscles.contains($0.parentGroup) }
                    : exercise.detailedPrimaryMuscles
                detailed.compactMap { $0.svgRegionId }.forEach { regionIds.insert($0) }
            } else if let group = set.primaryMuscleGroup {
                DetailedMuscle.allCases
                    .filter { $0.parentGroup == group }
                    .compactMap { $0.svgRegionId }
                    .forEach { regionIds.insert($0) }
            }
        }
        return regionIds
    }
}

// MARK: - Mini SVG WebView (nicht-interaktiv)

// Access-Level auf internal geändert damit SummaryMuscleHeatmapCard diesen View nutzen kann
struct MuscleHeatmapMiniSVGView: UIViewRepresentable {

    // Variante 1: Einfache trainierte Regionen (gelbe Einfärbung)
    private let trainedRegionIds: Set<String>?
    // Variante 2: Vollständige CSS-Styles aus MuscleHeatmapAnalysis (Heatmap-Farbskala)
    private let svgStylesCSS: String?

    // Initializer für einfache binäre Einfärbung (bestehend)
    init(trainedRegionIds: Set<String>) {
        self.trainedRegionIds = trainedRegionIds
        self.svgStylesCSS = nil
    }

    // Initializer für volle Heatmap-CSS aus MuscleHeatmapAnalysis
    init(svgStylesCSS: String) {
        self.trainedRegionIds = nil
        self.svgStylesCSS = svgStylesCSS
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.scrollView.backgroundColor = .clear
        loadContent(in: webView)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        loadContent(in: webView)
    }

    private func loadContent(in webView: WKWebView) {
        guard
            let svgURL = Bundle.main.url(forResource: "Muscles_Heatmap", withExtension: "svg"),
            let svgContent = try? String(contentsOf: svgURL, encoding: .utf8)
        else { return }

        let html = buildHTML(svgContent: svgContent)
        webView.loadHTMLString(html, baseURL: nil)
    }

    private func buildHTML(svgContent: String) -> String {
        // CSS aus übergebenem String oder aus trainedRegionIds generieren
        let css: String
        if let styles = svgStylesCSS {
            css = styles
        } else if let regions = trainedRegionIds {
            css = regions.map { regionId in
                "#\(regionId) path { fill: #F59E0B !important; }"
            }.joined(separator: "\n")
        } else {
            css = ""
        }

        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
        <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        html, body { width: 100%; height: 100%; background: transparent; }
        svg { width: 100%; height: 100%; display: block; }
        svg path { fill: #374151; }
        #front_borders path, #rear_borders path { fill: none !important; stroke: #666666; stroke-width: 0.8px; }
        @media (prefers-color-scheme: dark) {
            svg path { fill: #4B5563; }
            #front_borders path, #rear_borders path { stroke: #AAAAAA; }
        }
        \(css)
        </style>
        </head>
        <body>
        \(svgContent)
        </body>
        </html>
        """
    }
}
