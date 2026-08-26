import SwiftUI
import WebKit

public struct WebKitView: NSViewRepresentable {
    @ObservedObject var appState: AppState
    let tab: TabItem
    
    public init(appState: AppState, tab: TabItem) {
        self.appState = appState
        self.tab = tab
    }
    
    public func makeCoordinator() -> WebKitCoordinator {
        WebKitCoordinator(self)
    }
    
    public func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let contentController = WKUserContentController()
        
        config.websiteDataStore = WKWebsiteDataStore.default()
        
        // 1. Inject HTML5 Notification bridge script
        let notificationScript = WKUserScript(
            source: NotificationManager.shared.notificationBridgeScript,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
        contentController.addUserScript(notificationScript)
        contentController.add(context.coordinator, name: "notificationHandler")
        
        // 2. Inject Real-Time Unread Badge detector script
        let badgeScript = WKUserScript(
            source: NotificationManager.shared.unreadBadgeDetectorScript,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        contentController.addUserScript(badgeScript)
        contentController.add(context.coordinator, name: "badgeHandler")
        
        // 3. Inject Mobile Viewport script if needed
        if tab.viewport.isMobile {
            let viewportScript = WKUserScript(
                source: AdBlockManager.shared.mobileViewportFixScript,
                injectionTime: .atDocumentEnd,
                forMainFrameOnly: true
            )
            contentController.addUserScript(viewportScript)
        }
        
        // 4. Inject Adblock rules
        if tab.isAdBlockEnabled {
            contentController.addUserScript(AdBlockManager.shared.createAdBlockUserScript())
        }
        
        // 5. Inject Dark Mode script if enabled
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
        
        context.coordinator.setupProgressObserver(for: webView)
        context.coordinator.lastNavigationTrigger = appState.navigationTrigger
        
        webView.pageZoom = CGFloat(tab.zoomFactor)
        
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
            return "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Safari/605.1.15"
        } else if tab.urlString.contains("accounts.google") {
            return "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36"
        }
        return tab.viewport.userAgent
    }
    
    public func updateNSView(_ webView: WKWebView, context: Context) {
        guard let currentTab = appState.tabs.first(where: { $0.id == tab.id }) else { return }
        let isCurrentActive = currentTab.isPinned || (appState.selectedTabId == currentTab.id)
        
        let expectedUA = effectiveUserAgent
        if webView.customUserAgent != expectedUA {
            webView.customUserAgent = expectedUA
        }
        
        // Synchronize page zoom with high precision
        let targetZoom = CGFloat(currentTab.zoomFactor)
        if abs(webView.pageZoom - targetZoom) > 0.001 {
            webView.pageZoom = targetZoom
        }
        
        // Handle URL change
        if context.coordinator.lastNavigationTrigger != appState.navigationTrigger {
            context.coordinator.lastNavigationTrigger = appState.navigationTrigger
            if (tab.isPinned || isCurrentActive), let targetUrl = URL(string: tab.urlString), !tab.urlString.isEmpty {
                let request = URLRequest(url: targetUrl)
                webView.load(request)
            }
        }
        
        // Safety Fallback
        if webView.url == nil && !tab.urlString.isEmpty, let targetUrl = URL(string: tab.urlString) {
            let request = URLRequest(url: targetUrl)
            webView.load(request)
        }
        
        // Reload trigger
        if context.coordinator.lastReloadTrigger != appState.reloadTrigger {
            context.coordinator.lastReloadTrigger = appState.reloadTrigger
            if isCurrentActive {
                webView.reload()
            }
        }
        
        // Back trigger
        if context.coordinator.lastBackTrigger != appState.backTrigger {
            context.coordinator.lastBackTrigger = appState.backTrigger
            if isCurrentActive && webView.canGoBack {
                webView.goBack()
            }
        }
        
        // Forward trigger
        if context.coordinator.lastForwardTrigger != appState.forwardTrigger {
            context.coordinator.lastForwardTrigger = appState.forwardTrigger
            if isCurrentActive && webView.canGoForward {
                webView.goForward()
            }
        }
        
        // Pause media trigger
        if context.coordinator.lastPauseMediaTrigger != appState.pauseMediaTrigger {
            context.coordinator.lastPauseMediaTrigger = appState.pauseMediaTrigger
            webView.evaluateJavaScript(WebKitScripts.pauseAllMedia, completionHandler: nil)
        }
    }
}
