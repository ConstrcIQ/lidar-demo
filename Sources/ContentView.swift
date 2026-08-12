import SwiftUI
import WebKit

/// Appen er en tynd skal om den webgrænseflade, der allerede er bygget.
///
/// Valget er bevidst: grænsefladen skal kunne rettes på et sekund i en browser
/// i stedet for et kvarter gennem Apples byggeserver. Først når udtrykket og
/// algoritmen står fast, giver det mening at oversætte til rigtig Swift.
struct ContentView: View {
    var body: some View {
        WebShell()
            .ignoresSafeArea()
    }
}

private struct WebShell: UIViewRepresentable {

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        // HELE POINTEN MED DET EGNE SKEMA:
        // Grænsefladen består af ES-moduler, og WebKit nægter at indlæse moduler
        // fra `file://`, fordi filadresser ikke har et rigtigt ophav. Resultatet
        // er, at intet JavaScript kører, og skærmen bliver tom og sort.
        // Et selvbetjent skema giver siden et ægte ophav, og så virker moduler.
        config.setURLSchemeHandler(context.coordinator, forURLScheme: BundleScheme.name)

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        // Uden dette gynger hele grænsefladen, når man ruller i en tabel —
        // og en app, der gynger, føles som en hjemmeside.
        webView.scrollView.bounces = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.allowsBackForwardNavigationGestures = false
        #if DEBUG
        if #available(iOS 16.4, *) { webView.isInspectable = true }
        #endif

        webView.load(URLRequest(url: BundleScheme.entry))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, WKNavigationDelegate, WKURLSchemeHandler {

        // MARK: Filer ud af app-pakken

        func webView(_ webView: WKWebView, start task: WKURLSchemeTask) {
            guard let url = task.request.url else {
                task.didFailWithError(BundleScheme.failure("ingen adresse"))
                return
            }

            var path = url.path
            if path.isEmpty || path == "/" { path = "/index.html" }

            guard let root = Bundle.main.resourceURL else {
                task.didFailWithError(BundleScheme.failure("ingen ressourcemappe"))
                return
            }
            let file = root.appendingPathComponent("web").appendingPathComponent(path)

            guard let data = try? Data(contentsOf: file) else {
                task.didFailWithError(BundleScheme.failure("mangler: \(path)"))
                return
            }

            // Uden korrekt medietype på .js afviser WebKit modulet, og vi er
            // lige vidt. Det er ikke en detalje — det er hele forskellen.
            let response = URLResponse(url: url,
                                       mimeType: BundleScheme.mime(for: file.pathExtension),
                                       expectedContentLength: data.count,
                                       textEncodingName: "utf-8")
            task.didReceive(response)
            task.didReceive(data)
            task.didFinish()
        }

        func webView(_ webView: WKWebView, stop task: WKURLSchemeTask) {}

        // MARK: Navigation

        /// Alt uden for appen åbnes i Safari frem for at overtage skallen.
        func webView(_ webView: WKWebView,
                     decidePolicyFor action: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = action.request.url, url.scheme == "http" || url.scheme == "https" {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }

        /// Går indlæsningen galt, skal det stå på skærmen. En tom sort flade
        /// fortæller ingenting, og appen har ingen anden måde at sige det på.
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            show(error, in: webView)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            show(error, in: webView)
        }

        private func show(_ error: Error, in webView: WKWebView) {
            let message = error.localizedDescription
            webView.loadHTMLString("""
            <meta name="viewport" content="width=device-width,initial-scale=1">
            <div style="font:600 15px -apple-system;padding:44px 24px;color:#111;background:#fff;
                        min-height:100vh;margin:0">
              Grænsefladen kunne ikke indlæses.<br><br>
              <span style="font-weight:400;color:#666;font:400 13px ui-monospace,monospace">
              \(message)</span>
            </div>
            """, baseURL: nil)
        }
    }
}

private enum BundleScheme {
    static let name = "reps"
    static let entry = URL(string: "reps://app/index.html")!

    static func mime(for ext: String) -> String {
        switch ext.lowercased() {
        case "html": return "text/html"
        case "css": return "text/css"
        case "js", "mjs": return "text/javascript"
        case "json": return "application/json"
        case "svg": return "image/svg+xml"
        case "png": return "image/png"
        default: return "application/octet-stream"
        }
    }

    static func failure(_ reason: String) -> NSError {
        NSError(domain: "dk.reps.bundle", code: 404,
                userInfo: [NSLocalizedDescriptionKey: reason])
    }
}
