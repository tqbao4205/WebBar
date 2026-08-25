import SwiftUI
import WebKit
import Combine

public struct WebKitView: NSViewRepresentable {
    @ObservedObject var appState: AppState
    let tab: TabItem
    
    public init(appState: AppState, tab: TabItem) {
        self.appState = appState
        self.tab = tab
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let contentController = WKUserContentController()
        
        // Ensure persistent cookies, local storage & indexedDB across sessions (Zalo, Facebook, etc.)
        config.websiteDataStore = WKWebsiteDataStore.default()
        
        // 1. Inject HTML5 Notification bridge script
        let notificationScript = WKUserScript(
            source: NotificationManager.shared.notificationBridgeScript,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
        contentController.addUserScript(notificationScript)
        contentController.add(context.coordinator, name: "notificationHandler")
        
        // 1b. Inject Real-Time Unread Badge detector script (Zalo, Messenger, Facebook)
        let badgeScript = WKUserScript(
            source: NotificationManager.shared.unreadBadgeDetectorScript,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        contentController.addUserScript(badgeScript)
        contentController.add(context.coordinator, name: "badgeHandler")
        
        // 2. Inject Mobile Viewport script if needed
        if tab.viewport.isMobile {
            let viewportScript = WKUserScript(
                source: AdBlockManager.shared.mobileViewportFixScript,
                injectionTime: .atDocumentEnd,
                forMainFrameOnly: true
            )
            contentController.addUserScript(viewportScript)
        }
        
        // 3. Inject Adblock rules
        if tab.isAdBlockEnabled {
            contentController.addUserScript(AdBlockManager.shared.createAdBlockUserScript())
        }
        
        // 4. Inject Dark Mode script if enabled
        if tab.isDarkModeInjected {
            contentController.addUserScript(AdBlockManager.shared.createDarkModeUserScript())
        }
        
        config.userContentController = contentController
        config.preferences.javaScriptCanOpenWindowsAutomatically = true
        config.preferences.isElementFullscreenEnabled = true
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.customUserAgent = effectiveUserAgent
        webView.setValue(false, forKey: "drawsBackground")
        
        // Setup KVO for progress
        context.coordinator.setupProgressObserver(for: webView)
        context.coordinator.lastNavigationTrigger = appState.navigationTrigger
        
        if let url = URL(string: tab.urlString), !tab.urlString.isEmpty {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        
        return webView
    }
    
    private var effectiveUserAgent: String {
        if tab.urlString.contains("zalo.me") ||
           tab.urlString.contains("messenger.com") ||
           tab.urlString.contains("facebook.com/messages") ||
           tab.urlString.contains("tiktok.com") {
            // Desktop macOS User-Agent allows Zalo Web, Messenger Web, and TikTok to load full video player & chat without "Open Mobile App" blocks
            return "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Safari/605.1.15"
        } else if tab.urlString.contains("accounts.google") {
            // Authentic macOS Chrome User-Agent allows Google OAuth / "Sign in with Google" without "disallowed_useragent" 403 error
            return "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36"
        }
        return tab.viewport.userAgent
    }
    
    public func updateNSView(_ webView: WKWebView, context: Context) {
        // Hide inactive webviews so they don't intercept AppKit events
        let isCurrentActive = (appState.selectedTabId == tab.id)
        webView.isHidden = !isCurrentActive
        
        // Update user agent if viewport changed
        let expectedUA = effectiveUserAgent
        if webView.customUserAgent != expectedUA {
            webView.customUserAgent = expectedUA
        }
        
        // Update page zoom smoothly
        if abs(webView.pageZoom - CGFloat(tab.zoomFactor)) > 0.001 {
            webView.pageZoom = CGFloat(tab.zoomFactor)
        }
        
        // Handle URL change from explicit user navigation (address bar / new tab / search / quick apps)
        if context.coordinator.lastNavigationTrigger != appState.navigationTrigger {
            context.coordinator.lastNavigationTrigger = appState.navigationTrigger
            if isCurrentActive, let targetUrl = URL(string: tab.urlString), !tab.urlString.isEmpty {
                let request = URLRequest(url: targetUrl)
                webView.load(request)
            }
        }
        
        // Safety Fallback: If webview is empty/nil but tab has a destination URL, load it immediately
        if webView.url == nil && !tab.urlString.isEmpty, let targetUrl = URL(string: tab.urlString) {
            let request = URLRequest(url: targetUrl)
            webView.load(request)
        }
        
        // Handle reload trigger
        if context.coordinator.lastReloadTrigger != appState.reloadTrigger {
            context.coordinator.lastReloadTrigger = appState.reloadTrigger
            if isCurrentActive {
                webView.reload()
            }
        }
        
        // Handle back trigger
        if context.coordinator.lastBackTrigger != appState.backTrigger {
            context.coordinator.lastBackTrigger = appState.backTrigger
            if isCurrentActive && webView.canGoBack {
                webView.goBack()
            }
        }
        
        // Handle forward trigger
        if context.coordinator.lastForwardTrigger != appState.forwardTrigger {
            context.coordinator.lastForwardTrigger = appState.forwardTrigger
            if isCurrentActive && webView.canGoForward {
                webView.goForward()
            }
        }
        
        // Handle auto-pause media trigger when window is hidden or unfocused
        if context.coordinator.lastPauseMediaTrigger != appState.pauseMediaTrigger {
            context.coordinator.lastPauseMediaTrigger = appState.pauseMediaTrigger
            let pauseScript = """
            (function() {
                try {
                    var media = document.querySelectorAll('video, audio');
                    for (var i = 0; i < media.length; i++) {
                        media[i].pause();
                    }
                    var iframes = document.querySelectorAll('iframe');
                    for (var j = 0; j < iframes.length; j++) {
                        if (iframes[j].contentWindow) {
                            iframes[j].contentWindow.postMessage('{"event":"command","func":"pauseVideo","args":""}', '*');
                        }
                    }
                } catch (e) {}
            })();
            """
            webView.evaluateJavaScript(pauseScript, completionHandler: nil)
        }
    }
    
    // MARK: - Coordinator & WebKit Delegates
    
    public final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        var parent: WebKitView
        var lastNavigationTrigger: UUID?
        var lastReloadTrigger: UUID?
        var lastBackTrigger: UUID?
        var lastForwardTrigger: UUID?
        var lastPauseMediaTrigger: UUID?
        private var progressObservation: NSKeyValueObservation?
        private var isLoading: Bool = false
        
        init(_ parent: WebKitView) {
            self.parent = parent
            self.lastNavigationTrigger = parent.appState.navigationTrigger
            super.init()
        }
        
        deinit {
            progressObservation?.invalidate()
        }
        
        func setupProgressObserver(for webView: WKWebView) {
            progressObservation = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] webView, _ in
                DispatchQueue.main.async {
                    if self?.parent.appState.selectedTabId == self?.parent.tab.id {
                        self?.parent.appState.currentProgress = webView.estimatedProgress
                    }
                }
            }
        }
        
        // MARK: - WKNavigationDelegate
        
        // Handle incoming Web Notification messages and Unread Badge updates from JavaScript
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
                
                // Extract direct real favicon URL from webpage DOM
                let js = """
                (function() {
                    var el = document.querySelector("link[rel*='icon'], link[rel='apple-touch-icon'], link[rel='shortcut icon']");
                    return el ? el.href : (window.location.origin + '/favicon.ico');
                })();
                """
                webView.evaluateJavaScript(js) { [weak self] result, _ in
                    let faviconUrl = result as? String
                    self?.parent.appState.updateTab(id: self?.parent.tab.id ?? UUID(), url: urlString, title: title, favicon: faviconUrl)
                }
            }
        }
        
        public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            isLoading = false
            DispatchQueue.main.async {
                if self.parent.appState.selectedTabId == self.parent.tab.id {
                    self.parent.appState.currentIsLoading = false
                }
            }
        }
        
        public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            isLoading = false
            DispatchQueue.main.async {
                if self.parent.appState.selectedTabId == self.parent.tab.id {
                    self.parent.appState.currentIsLoading = false
                }
            }
        }
        
        // Handle Navigation Actions (Allows clicking links on Google, search results, target="_blank", etc. just like MenuBarX / Safari)
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
        
        // Handle window.open Popups (Sign in with Google, Apple, Facebook OAuth, etc.)
        public func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            let urlStr = navigationAction.request.url?.absoluteString.lowercased() ?? ""
            
            // Only open separate popup window for explicit Authentication/OAuth popups
            let isOAuthPopup = urlStr.contains("accounts.google.com/o/oauth") ||
                               urlStr.contains("accounts.google.com/signin/oauth") ||
                               urlStr.contains("accounts.google.com/v3/signin") ||
                               urlStr.contains("dialog/oauth") ||
                               urlStr.contains("appleid.apple.com/auth/authorize") ||
                               urlStr.contains("tiktok.com/login") ||
                               (urlStr.contains("oauth") && !urlStr.contains("google.com/search"))
            
            if isOAuthPopup {
                let popupConfig = configuration
                
                // Inject window.chrome and security shims so Google OAuth recognizes it as genuine desktop browser
                let securityShimScript = WKUserScript(
                    source: """
                    (function() {
                        try {
                            if (!window.chrome) {
                                window.chrome = { runtime: {}, app: {}, csi: function(){}, loadTimes: function(){} };
                            }
                            Object.defineProperty(navigator, 'webdriver', { get: () => undefined });
                        } catch(e) {}
                    })();
                    """,
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
            
            // For standard links requesting new window/tab, returning nil lets decidePolicyFor handle loading in current tab without conflict
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
        
        // Handle File Upload Pickers (Photos / Documents in Zalo, Messenger, etc.)
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
                if result == .OK {
                    completionHandler(openPanel.urls)
                } else {
                    completionHandler(nil)
                }
            }
        }
        
        // Handle JavaScript Alert Popups
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
        
        // Handle JavaScript Confirm Dialogs
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
        
        // Handle Microphone / Camera capture permission for Zalo Voice / Video
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
}
