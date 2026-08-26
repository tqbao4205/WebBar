import Foundation
import WebKit
import AppKit

public final class WebKitCoordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
    public var parent: WebKitView
    public var lastNavigationTrigger: UUID?
    public var lastReloadTrigger: UUID?
    public var lastBackTrigger: UUID?
    public var lastForwardTrigger: UUID?
    public var lastPauseMediaTrigger: UUID?
    private var progressObservation: NSKeyValueObservation?
    private var isLoading: Bool = false
    
    public init(_ parent: WebKitView) {
        self.parent = parent
        self.lastNavigationTrigger = parent.appState.navigationTrigger
        super.init()
    }
    
    deinit {
        progressObservation?.invalidate()
    }
    
    public func setupProgressObserver(for webView: WKWebView) {
        progressObservation = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] webView, _ in
            DispatchQueue.main.async {
                if self?.parent.appState.selectedTabId == self?.parent.tab.id {
                    self?.parent.appState.currentProgress = webView.estimatedProgress
                }
            }
        }
    }
    
    // MARK: - WKScriptMessageHandler
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "notificationHandler", let dict = message.body as? [String: Any] {
            let title = dict["title"] as? String ?? ""
            let body = dict["body"] as? String ?? ""
            
            NotificationManager.shared.sendWebNotification(
                title: title,
                body: body,
                tabTitle: parent.tab.title,
                tabId: parent.tab.id
            )
            
            DispatchQueue.main.async {
                self.parent.appState.setUnreadCount(for: self.parent.tab.id, count: max(1, self.parent.tab.unreadCount + 1))
            }
        } else if message.name == "badgeHandler", let dict = message.body as? [String: Any] {
            let count = dict["count"] as? Int ?? 0
            DispatchQueue.main.async {
                self.parent.appState.setUnreadCount(for: self.parent.tab.id, count: count)
            }
        }
    }
    
    // MARK: - WKNavigationDelegate
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        isLoading = true
        DispatchQueue.main.async {
            if self.parent.appState.selectedTabId == self.parent.tab.id {
                self.parent.appState.currentIsLoading = true
                if let currentUrl = webView.url?.absoluteString, !currentUrl.isEmpty {
                    self.parent.appState.urlInputText = currentUrl
                }
            }
        }
    }
    
    public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        DispatchQueue.main.async {
            if self.parent.appState.selectedTabId == self.parent.tab.id {
                self.parent.appState.currentCanGoBack = webView.canGoBack
                self.parent.appState.currentCanGoForward = webView.canGoForward
            }
        }
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isLoading = false
        let title = webView.title ?? self.parent.tab.title
        let urlString = webView.url?.absoluteString ?? self.parent.tab.urlString
        
        DispatchQueue.main.async {
            if self.parent.appState.selectedTabId == self.parent.tab.id {
                self.parent.appState.currentIsLoading = false
                self.parent.appState.currentCanGoBack = webView.canGoBack
                self.parent.appState.currentCanGoForward = webView.canGoForward
                self.parent.appState.urlInputText = urlString
            }
            
            // Extract favicon from DOM
            webView.evaluateJavaScript(WebKitScripts.extractFavicon) { [weak self] result, _ in
                let faviconUrl = result as? String
                self?.parent.appState.updateTab(id: self?.parent.tab.id ?? UUID(), url: urlString, title: title, favicon: faviconUrl)
            }
        }
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        isLoading = false
        let failedUrl = webView.url?.absoluteString ?? self.parent.tab.urlString
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
            return
        }
        DispatchQueue.main.async {
            if self.parent.appState.selectedTabId == self.parent.tab.id {
                self.parent.appState.currentIsLoading = false
            }
            self.parent.appState.reportNavigationFailed(for: self.parent.tab.id, failedUrl: failedUrl, error: error)
        }
    }
    
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        isLoading = false
        let failedUrl = webView.url?.absoluteString ?? self.parent.tab.urlString
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
            return
        }
        DispatchQueue.main.async {
            if self.parent.appState.selectedTabId == self.parent.tab.id {
                self.parent.appState.currentIsLoading = false
            }
            self.parent.appState.reportNavigationFailed(for: self.parent.tab.id, failedUrl: failedUrl, error: error)
        }
    }
    
    public func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }
    
    // MARK: - WKUIDelegate Popups & OAuth
    public func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        let urlStr = navigationAction.request.url?.absoluteString.lowercased() ?? ""
        
        let isOAuthPopup = urlStr.contains("accounts.google.com/o/oauth") ||
                           urlStr.contains("accounts.google.com/signin/oauth") ||
                           urlStr.contains("accounts.google.com/v3/signin") ||
                           urlStr.contains("dialog/oauth") ||
                           urlStr.contains("appleid.apple.com/auth/authorize") ||
                           urlStr.contains("tiktok.com/login") ||
                           (urlStr.contains("oauth") && !urlStr.contains("google.com/search"))
        
        if isOAuthPopup {
            let popupConfig = configuration
            let securityShimScript = WKUserScript(
                source: WebKitScripts.googleOAuthSecurityShim,
                injectionTime: .atDocumentStart,
                forMainFrameOnly: false
            )
            popupConfig.userContentController.addUserScript(securityShimScript)
            
            let popupWebView = WKWebView(frame: NSRect(x: 0, y: 0, width: 520, height: 680), configuration: popupConfig)
            popupWebView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Safari/605.1.15"
            popupWebView.uiDelegate = self
            popupWebView.navigationDelegate = self
            
            let popupWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 520, height: 680),
                styleMask: [.titled, .closable, .resizable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            popupWindow.title = "Đăng nhập tài khoản"
            popupWindow.isReleasedWhenClosed = false
            popupWindow.center()
            popupWindow.contentView = popupWebView
            popupWindow.level = .floating
            popupWindow.makeKeyAndOrderFront(nil)
            
            return popupWebView
        }
        
        return nil
    }
    
    public func webViewDidClose(_ webView: WKWebView) {
        if let window = webView.window {
            window.close()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.parent.appState.reloadActiveTab()
        }
    }
    
    public func webView(
        _ webView: WKWebView,
        runOpenPanelWith parameters: WKOpenPanelParameters,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping ([URL]?) -> Void
    ) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = parameters.allowsMultipleSelection
        openPanel.begin { result in
            completionHandler(result == .OK ? openPanel.urls : nil)
        }
    }
    
    public func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping () -> Void
    ) {
        let alert = NSAlert()
        alert.messageText = "Thông báo"
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.runModal()
        completionHandler()
    }
    
    public func webView(
        _ webView: WKWebView,
        runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (Bool) -> Void
    ) {
        let alert = NSAlert()
        alert.messageText = "Xác nhận"
        alert.informativeText = message
        alert.addButton(withTitle: "Đồng ý")
        alert.addButton(withTitle: "Hủy")
        let result = alert.runModal()
        completionHandler(result == .alertFirstButtonReturn)
    }
    
    @available(macOS 12.0, *)
    public func webView(
        _ webView: WKWebView,
        requestMediaCapturePermissionFor origin: WKSecurityOrigin,
        initiatedByFrame frame: WKFrameInfo,
        type: WKMediaCaptureType,
        decisionHandler: @escaping (WKPermissionDecision) -> Void
    ) {
        decisionHandler(.grant)
    }
}
