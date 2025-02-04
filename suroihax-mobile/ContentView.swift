import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        //inject script here
        let contentController = WKUserContentController()
        let scriptSource = """
        (function() {
            function injectScript() {
                var script = document.createElement('script');
                script.src = 'https://suroihax.glitch.me/script.user.js';
                script.async = false;
                document.body.appendChild(script);
            }
            if (document.readyState === 'loading') {
                document.addEventListener('DOMContentLoaded', injectScript);
            } else {
                injectScript();
            }
        })();
        """
        let userScript = WKUserScript(source: scriptSource, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        contentController.addUserScript(userScript)
        
        //block suroi's main js script
        
        
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = contentController
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.navigationDelegate = context.coordinator

        let ruleListJSON = """
        [{
            "trigger": {
                "url-filter": "^https://suroi\\\\.io/scripts/main.*",
                "resource-type": ["script"]
            },
            "action": {
                "type": "block"
            }
        }]
        """

        // Compile the rule list asynchronously.
        WKContentRuleListStore.default().compileContentRuleList(
                forIdentifier: "BlockMainScript",
                encodedContentRuleList: ruleListJSON
        ) { ruleList, error in
                if let error = error {
                        print("Error compiling rule list: \(error.localizedDescription)")
                }
                if let ruleList = ruleList {
                        contentController.add(ruleList)
                }
                // Now that our rule list is in place, load the URL on the main thread.
                DispatchQueue.main.async {
                        let request = URLRequest(url: self.url)
                        webView.load(request)
                }
        }

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) { }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView

        init(_ parent: WebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("Finished loading.")
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("Navigation error: \(error.localizedDescription)")
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("Provisional navigation error: \(error.localizedDescription)")
        }
    }
}

struct ContentView: View {
    var body: some View {
        WebView(url: URL(string: "https://suroi.io/")!)
            .edgesIgnoringSafeArea(.all)
    }
}
