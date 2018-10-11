import UIKit
import PlaygroundSupport

import WebKit

class MyViewController : UIViewController {
    private lazy var sharedProcessPool: WKProcessPool = WKProcessPool()
    private var webView: WKWebView!

    override func loadView() {
        let view = UIView(frame: .zero)
        view.backgroundColor = UIColor.white
        self.view = view

        let configuration = WKWebViewConfiguration()

        // add javascript interface
        let controller = WKUserContentController()
        controller.add(self, name: "sendMessage")
        configuration.userContentController = controller

        configuration.processPool = sharedProcessPool
        configuration.applicationNameForUserAgent = "Sample-iOS-App/v1.0.0"

        // set cookie for javascript
        let cookieScript = WKUserScript(source: "document.cookie = 'jsCookie=sample1;path=/';",
                                        injectionTime: .atDocumentStart,
                                        forMainFrameOnly: true)
        controller.addUserScript(cookieScript)

        webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 320, height: 400), configuration: configuration)
        webView.navigationDelegate = self
        view.addSubview(webView)

        let button = UIButton(frame: CGRect(x: 0, y: 400, width: 200, height: 44))
        button.setTitle("exec", for: .normal)
        button.backgroundColor = UIColor.black
        button.addTarget(self, action:#selector(self.buttonClicked), for: .touchUpInside)
        view.addSubview(button)
    }

    override func viewDidLoad() {
        let url = URL(string: "https://noboru-i.github.io/sample-html/webview.html")
        var request = URLRequest(url: url!)
        request.cachePolicy = .reloadIgnoringCacheData
        request.httpShouldHandleCookies = false

        // header is set, but cannot load by javascript
        request.addValue("requestKey=sample", forHTTPHeaderField: "Cookie")

        webView.load(request)
    }

    @objc func buttonClicked() {
        print("Button Clicked")
        webView.evaluateJavaScript("document.cookie = 'native_cookie=xyz;max-age=3600;path=/';", completionHandler: nil)
        webView.evaluateJavaScript("printCookie();", completionHandler: nil)
    }
}

extension MyViewController : WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case "sendMessage":
            guard let contentBody = message.body as? String else {
                return
            }
            print("message is received. message: " + contentBody)
        default:
            fatalError()
        }
    }
}

extension MyViewController : WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let url = navigationAction.request.url!
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies {
            print($0)
        }
        if(url.absoluteString == "sample://update_cookie") {
            decisionHandler(.cancel)
            return
        }
        if(url.host! == "noboru-i.github.io") {
            decisionHandler(.allow)
            return
        }

        print("open by safari.")
        decisionHandler(.cancel)
        UIApplication.shared.open(url)
    }

    // use charles
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
        completionHandler(.useCredential, credential)
    }
}

// Present the view controller in the Live View window
PlaygroundPage.current.liveView = MyViewController()
