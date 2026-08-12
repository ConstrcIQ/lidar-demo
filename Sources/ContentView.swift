import SwiftUI
import WebKit

/// Appen er en tynd skal om den webgrænseflade, der allerede er bygget.
///
/// Valget er bevidst: grænsefladen skal kunne rettes på et sekund i en browser
/// i stedet for et kvarter gennem Apples byggeserver. Først når udtrykket og
/// algoritmen står fast, giver det mening at oversætte til rigtig Swift.
///
/// Filerne ligger inde i appen, og `mock.js` efterligner serveren — så alle
/// skærme kan gennemgås uden PC, uden netværk og uden kamera.
struct ContentView: View {
    var body: some View {
        WebShell()
            .ignoresSafeArea()
            .background(Color.black)
    }
}

private struct WebShell: UIViewRepresentable {

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        // Uden dette hopper hele grænsefladen, når man ruller i en tabel —
        // og en app, der gynger, føles som en hjemmeside.
        webView.scrollView.bounces = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.allowsBackForwardNavigationGestures = false

        load(into: webView)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    private func load(into webView: WKWebView) {
        guard let index = Bundle.main.url(forResource: "index",
                                          withExtension: "html",
                                          subdirectory: "web") else {
            webView.loadHTMLString(missingResources, baseURL: nil)
            return
        }
        webView.loadFileURL(index, allowingReadAccessTo: index.deletingLastPathComponent())
    }

    /// Sker det, er webmappen ikke kommet med i bygningen. Bedre at sige det
    /// end at vise en tom, hvid skærm uden forklaring.
    private var missingResources: String {
        """
        <meta name="viewport" content="width=device-width,initial-scale=1">
        <div style="font:600 15px -apple-system;padding:40px;color:#111">
        Webfilerne mangler i bygningen.<br><br>
        <span style="font-weight:400;color:#666">
        Mappen <code>Resources/web</code> kom ikke med som ressource.</span></div>
        """
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        /// Alt uden for appen åbnes i Safari frem for at overtage skallen.
        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url,
               url.scheme == "http" || url.scheme == "https" {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }
    }
}
