//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Muskel-Heatmap                                                   /
// Datei . . . . : MuscleHeatmapSVGView.swift                                       /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 26.03.2026                                                       /
// Beschreibung  : SVG-Heatmap via WKWebView mit dynamischer CSS-Injection          /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI
import WebKit

struct MuscleHeatmapSVGView: UIViewRepresentable {

    let analysis: MuscleHeatmapAnalysis
    var onRegionTap: ((String) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(onRegionTap: onRegionTap)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.userContentController.add(context.coordinator, name: "regionTap")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.scrollView.backgroundColor = .clear

        loadContent(in: webView)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.onRegionTap = onRegionTap
        loadContent(in: webView)
    }

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        uiView.configuration.userContentController.removeScriptMessageHandler(forName: "regionTap")
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
        """
        <!DOCTYPE html>
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
        <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        html, body { width: 100%; height: 100%; background: transparent; }
        svg { width: 100%; height: 100%; display: block; }
        g[id] { cursor: pointer; }
        svg path { 
            fill: #A6A9AD !important;
            stroke: none !important; 
        }
        #front_borders path, #rear_borders path {
            fill: none !important; 
            stroke: #666666; 
            stroke-width: 0.8px; 
        }
        @media (prefers-color-scheme: dark) {
            #front_borders path, #rear_borders path { stroke: #AAAAAA; }
        }
        \(analysis.svgStylesCSS)
        </style>
        </head>
        <body>
        \(svgContent)
        <script>
        document.querySelectorAll('g[id]').forEach(function(g) {
            var id = g.id;
            if (id === 'front_borders' || id === 'rear_borders') return;
            g.addEventListener('click', function(e) {
                e.stopPropagation();
                window.webkit.messageHandlers.regionTap.postMessage(id);
            });
        });
        </script>
        </body>
        </html>
        """
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, WKScriptMessageHandler {
        var onRegionTap: ((String) -> Void)?

        init(onRegionTap: ((String) -> Void)?) {
            self.onRegionTap = onRegionTap
        }

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            guard message.name == "regionTap", let regionId = message.body as? String else { return }
            DispatchQueue.main.async {
                self.onRegionTap?(regionId)
            }
        }
    }
}
