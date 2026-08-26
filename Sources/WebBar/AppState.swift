import Foundation
import SwiftUI
import Combine

public final class AppState: ObservableObject {
    @Published public var tabs: [TabItem] = []
    @Published public var selectedTabId: UUID = UUID()
    @Published public var isPinned: Bool = false
    @Published public var windowOpacity: Double = 1.0
    @Published public var isSettingsOpen: Bool = false
    @Published public var urlInputText: String = ""
    @Published public var isOmniboxFocused: Bool = false
    @Published public var isAdBlockEnabledGlobally: Bool = true
    @Published public var defaultSearchEngine: SearchEngine = .duckduckgo
    @Published public var customWidth: CGFloat = 393
    @Published public var customHeight: CGFloat = 750
    @Published public var arrowOffsetX: CGFloat = 196
    @Published public var isTopBarHidden: Bool = true
    @Published public var isFloatingURLBarOpen: Bool = false
    @Published public var launchAtLogin: Bool = false
    @Published public var zoomToastText: String? = nil
    private var zoomToastTimer: Timer?
    
    // Per-tab webview navigation triggers
    @Published public var navigationTrigger: UUID = UUID()
    @Published public var reloadTrigger: UUID = UUID()
    @Published public var backTrigger: UUID = UUID()
    @Published public var forwardTrigger: UUID = UUID()
    @Published public var pauseMediaTrigger: UUID = UUID()
    
    // Current active tab status
    @Published public var currentCanGoBack: Bool = false
    @Published public var currentCanGoForward: Bool = false
    @Published public var currentIsLoading: Bool = false
    @Published public var currentProgress: Double = 0.0
    
    // Auto-refresh timer storage
    private var refreshTimers: [UUID: Timer] = [:]
    
    private let userDefaultsKey = "WebBarSavedTabs"
    private let settingsDefaultsKey = "WebBarSavedSettings"
    
    public init() {
        loadState()
        self.launchAtLogin = LaunchAtLoginManager.shared.isEnabled
        if tabs.isEmpty {
            // Initialize with default AI launcher tab
            let initialTab = TabItem(
                title: "AI Launcher",
                urlString: "",
                viewport: .iphonePro,
                isPinned: false
            )
            tabs = [initialTab]
            selectedTabId = initialTab.id
        }
    }
    
    public var activeTab: TabItem? {
        tabs.first(where: { $0.id == selectedTabId }) ?? tabs.first
    }
    
    @Published public var tabIsDarkMap: [UUID: Bool] = [:]
    
    public var currentWindowBackgroundColor: Color {
        return Color(nsColor: .windowBackgroundColor)
    }
    
    public var currentWindowSize: CGSize {
        guard let tab = activeTab else { return ViewportMode.iphonePro.size }
        return tab.currentSize
    }
    
    // MARK: - Tab Management
    
    public func addNewTab(
        url: String = "",
        title: String = "New Tab",
        viewport: ViewportMode = .iphonePro
    ) {
        // Clean up any previous abandoned empty/blank tabs first
        if url.isEmpty {
            cleanUpUnusedBlankTabs()
        }
        
        let newTab = TabItem(
            title: title.isEmpty ? "New Tab" : title,
            urlString: url,
            viewport: viewport,
            isAdBlockEnabled: isAdBlockEnabledGlobally
        )
        tabs.append(newTab)
        selectedTabId = newTab.id
        urlInputText = url
        saveState()
        
        // Immediately update layout so status item length is applied
        MenuBarController.shared.capsuleView?.updateCapsuleLayout()
        MenuBarController.shared.positionPanelUnderStatusBar(for: newTab.id)
    }
    
    public func closeActiveTabIfBlank() {
        guard let active = activeTab, active.isBlank, tabs.count > 1 else { return }
        closeTab(id: active.id)
    }
    
    public func cleanUpUnusedBlankTabs(except tabId: UUID? = nil) {
        let blankTabs = tabs.filter { $0.isBlank && (tabId == nil || $0.id != tabId) }
        guard !blankTabs.isEmpty, tabs.count > blankTabs.count else { return }
        for tab in blankTabs {
            if let idx = tabs.firstIndex(where: { $0.id == tab.id }), tabs.count > 1 {
                tabs.remove(at: idx)
            }
        }
    }
    
    public func closeTab(id: UUID) {
        // Stop timer if any
        refreshTimers[id]?.invalidate()
        refreshTimers.removeValue(forKey: id)
        
        guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }
        tabs.remove(at: index)
        
        if tabs.isEmpty {
            addNewTab()
        } else if selectedTabId == id {
            let nextIndex = min(index, tabs.count - 1)
            selectedTabId = tabs[nextIndex].id
            urlInputText = tabs[nextIndex].urlString
        }
        saveState()
        DispatchQueue.main.async {
            MenuBarController.shared.syncStatusItems()
            MenuBarController.shared.updatePanelFrame()
        }
    }
    
    public func selectTab(id: UUID) {
        // If switching from an empty/blank tab to another tab, remove the unused blank tab
        if let current = activeTab, current.isBlank, current.id != id, tabs.count > 1 {
            closeTab(id: current.id)
        }
        
        guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }
        selectedTabId = id
        urlInputText = tabs[index].urlString
        
        // Clear unread count when user views the tab
        if tabs[index].unreadCount > 0 {
            tabs[index].unreadCount = 0
            saveState()
            MenuBarController.shared.syncStatusItems()
        }
        
        MenuBarController.shared.updatePanelFrame(animated: true)
    }
    
    public func setUnreadCount(for tabId: UUID, count: Int) {
        guard let index = tabs.firstIndex(where: { $0.id == tabId }) else { return }
        
        // If tab is currently active and panel is visible to user, mark as read
        if tabId == selectedTabId && MenuBarController.shared.panel?.isVisible == true {
            if tabs[index].unreadCount != 0 {
                tabs[index].unreadCount = 0
                saveState()
                DispatchQueue.main.async {
                    MenuBarController.shared.syncStatusItems()
                }
            }
            return
        }
        
        let newCount = max(0, count)
        if tabs[index].unreadCount != newCount {
            tabs[index].unreadCount = newCount
            saveState()
            DispatchQueue.main.async {
                MenuBarController.shared.syncStatusItems()
            }
        }
    }
    
    public func moveTab(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex >= 0 && sourceIndex < tabs.count,
              destinationIndex >= 0 && destinationIndex < tabs.count,
              sourceIndex != destinationIndex else { return }
        
        let tab = tabs.remove(at: sourceIndex)
        tabs.insert(tab, at: destinationIndex)
        saveState()
        DispatchQueue.main.async {
            MenuBarController.shared.syncStatusItems()
        }
    }
    
    public func selectTabAtIndex(_ index: Int) {
        guard index >= 0 && index < tabs.count else { return }
        selectTab(id: tabs[index].id)
    }
    
    public func updateTab(
        id: UUID,
        url: String? = nil,
        title: String? = nil,
        favicon: String? = nil
    ) {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }
        if let url = url {
            tabs[index].urlString = url
            if id == selectedTabId {
                urlInputText = url
            }
        }
        if let title = title, !title.isEmpty {
            tabs[index].title = title
        }
        if let favicon = favicon {
            tabs[index].faviconUrl = favicon
        }
        saveState()
    }
    
    public func updateActiveTab(
        url: String? = nil,
        title: String? = nil,
        favicon: String? = nil
    ) {
        updateTab(id: selectedTabId, url: url, title: title, favicon: favicon)
    }
    
    // MARK: - Viewport & Sizing (Independent Per-Tab)
    
    public func setViewport(_ mode: ViewportMode, for tabId: UUID? = nil) {
        let targetId = tabId ?? selectedTabId
        guard let index = tabs.firstIndex(where: { $0.id == targetId }) else { return }
        tabs[index].viewport = mode
        saveState()
        DispatchQueue.main.async {
            MenuBarController.shared.updatePanelFrame()
        }
    }
    
    public func setCustomDimensions(width: CGFloat, height: CGFloat, for tabId: UUID? = nil) {
        let targetId = tabId ?? selectedTabId
        guard let index = tabs.firstIndex(where: { $0.id == targetId }) else { return }
        tabs[index].customWidth = width
        tabs[index].customHeight = height
        tabs[index].viewport = .custom
        saveState()
        objectWillChange.send()
        DispatchQueue.main.async {
            MenuBarController.shared.updatePanelFrame()
        }
    }
    
    // MARK: - Quick Apps & Navigation
    
    public func loadQuickApp(_ app: QuickApp) {
        if let active = activeTab, active.isBlank {
            // Replace blank active tab
            guard let index = tabs.firstIndex(where: { $0.id == active.id }) else { return }
            tabs[index].title = app.name
            tabs[index].urlString = app.urlString
            tabs[index].viewport = app.defaultViewport
            tabs[index].customIcon = app.iconSymbol
            urlInputText = app.urlString
        } else {
            // Open in new tab
            let newTab = TabItem(
                title: app.name,
                urlString: app.urlString,
                viewport: app.defaultViewport,
                customIcon: app.iconSymbol
            )
            tabs.append(newTab)
            selectedTabId = newTab.id
            urlInputText = app.urlString
        }
        navigationTrigger = UUID()
        saveState()
        DispatchQueue.main.async {
            MenuBarController.shared.syncStatusItems()
            MenuBarController.shared.updatePanelFrame()
        }
    }
    
    // URL Error Message (When an invalid link is entered/pasted)
    @Published public var urlErrorMessage: String? = nil
    
    public func validateAndFormatURL(input: String) -> String? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        
        let lower = trimmed.lowercased()
        
        // Recognized web services & popular shortcuts
        if lower == "zalo" || lower == "zalo.me" || lower == "chat.zalo.me" {
            return "https://chat.zalo.me"
        } else if lower == "google" || lower == "gg" || lower == "google.com" {
            return "https://www.google.com"
        } else if lower == "tiktok" || lower == "tiktok.com" {
            return "https://www.tiktok.com/explore"
        } else if lower == "fb" || lower == "facebook" || lower == "facebook.com" {
            return "https://www.facebook.com"
        } else if lower == "messenger" || lower == "messenger.com" {
            return "https://www.messenger.com"
        } else if lower == "youtube" || lower == "yt" || lower == "youtube.com" {
            return "https://www.youtube.com"
        } else if lower == "chatgpt" || lower == "gpt" {
            return "https://chatgpt.com"
        } else if lower == "gemini" {
            return "https://gemini.google.com"
        } else if lower == "claude" {
            return "https://claude.ai"
        } else if lower == "github" || lower == "github.com" {
            return "https://github.com"
        } else if lower == "notion" || lower == "notion.so" {
            return "https://notion.so"
        } else if lower == "telegram" || lower == "telegram.org" {
            return "https://web.telegram.org"
        } else if lower == "instagram" || lower == "instagram.com" {
            return "https://www.instagram.com"
        }
        
        // Complete URL with explicit http/https scheme
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            if let url = URL(string: trimmed), let host = url.host, !host.isEmpty, !host.contains(" ") {
                return trimmed
            }
            return nil
        }
        
        // Domain with TLD (e.g. "vnexpress.net", "sub.domain.vn/path", "localhost:3000")
        if !trimmed.contains(" ") && (trimmed.contains(".") || trimmed.hasPrefix("localhost")) {
            let candidate = "https://" + trimmed
            if let url = URL(string: candidate), let host = url.host, !host.isEmpty, (host.contains(".") || host == "localhost") {
                return candidate
            }
        }
        
        // Invalid link or raw search query -> Do not open Google Search, return nil
        return nil
    }
    
    public func navigateTo(input: String) {
        let cleanInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanInput.isEmpty else { return }
        
        guard let destinationUrl = validateAndFormatURL(input: cleanInput) else {
            // Report invalid URL error immediately instead of opening search engine
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                self.urlErrorMessage = "Đường dẫn không hợp lệ! Vui lòng nhập link website (ví dụ: https://... hoặc domain.com)"
            }
            
            // Auto-dismiss error alert after 4.5s
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) { [weak self] in
                withAnimation {
                    self?.urlErrorMessage = nil
                }
            }
            return
        }
        
        // Clear any previous error
        self.urlErrorMessage = nil
        
        guard let index = tabs.firstIndex(where: { $0.id == selectedTabId }) else { return }
        tabs[index].urlString = destinationUrl
        tabs[index].title = cleanInput
        
        urlInputText = destinationUrl
        navigationTrigger = UUID()
        saveState()
    }
    
    public func reportNavigationFailed(for tabId: UUID, failedUrl: String, error: Error) {
        let nsError = error as NSError
        // Ignore user cancellation
        if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
            return
        }
        
        guard let index = tabs.firstIndex(where: { $0.id == tabId }) else { return }
        
        // Reset tab to blank so the Paste Link screen is displayed
        tabs[index].urlString = ""
        tabs[index].title = "New Tab"
        
        urlInputText = failedUrl
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            self.urlErrorMessage = "Không thể mở \"\(failedUrl)\". Vui lòng kiểm tra lại đường link hoặc kết nối mạng."
        }
        
        saveState()
        MenuBarController.shared.syncStatusItems()
    }
    
    public func reloadActiveTab() {
        reloadTrigger = UUID()
    }
    
    public func goBack() {
        backTrigger = UUID()
    }
    
    public func goForward() {
        forwardTrigger = UUID()
    }
    
    public func togglePin() {
        isPinned.toggle()
        saveState()
    }
    
    public func toggleTopBar() {
        isTopBarHidden.toggle()
    }
    
    public func openFloatingURLBar() {
        if let active = activeTab, !active.isBlank {
            urlInputText = active.urlString
        } else {
            urlInputText = ""
        }
        withAnimation(.spring(response: 0.25, dampingFraction: 0.82)) {
            isFloatingURLBarOpen = true
        }
    }
    
    public func setLaunchAtLogin(_ enable: Bool) {
        LaunchAtLoginManager.shared.setEnabled(enable)
        launchAtLogin = LaunchAtLoginManager.shared.isEnabled
    }
    
    // Pre-defined browser standard zoom levels
    private static let zoomSteps: [Double] = [
        0.50, 0.67, 0.75, 0.80, 0.90, 1.00, 1.10, 1.25, 1.50, 1.75, 2.00, 2.50, 3.00
    ]
    
    public func zoomIn() {
        guard let index = tabs.firstIndex(where: { $0.id == selectedTabId }) else { return }
        let current = tabs[index].zoomFactor
        if let nextStep = Self.zoomSteps.first(where: { $0 > current + 0.02 }) {
            tabs[index].zoomFactor = nextStep
        } else {
            tabs[index].zoomFactor = min(3.0, current + 0.1)
        }
        showZoomToast(text: "\(Int(round(tabs[index].zoomFactor * 100)))%")
        saveState()
    }
    
    public func zoomOut() {
        guard let index = tabs.firstIndex(where: { $0.id == selectedTabId }) else { return }
        let current = tabs[index].zoomFactor
        if let prevStep = Self.zoomSteps.last(where: { $0 < current - 0.02 }) {
            tabs[index].zoomFactor = prevStep
        } else {
            tabs[index].zoomFactor = max(0.5, current - 0.1)
        }
        showZoomToast(text: "\(Int(round(tabs[index].zoomFactor * 100)))%")
        saveState()
    }
    
    public func resetZoom() {
        guard let index = tabs.firstIndex(where: { $0.id == selectedTabId }) else { return }
        tabs[index].zoomFactor = 1.0
        showZoomToast(text: "100%")
        saveState()
    }
    
    private func showZoomToast(text: String) {
        zoomToastTimer?.invalidate()
        zoomToastText = text
        zoomToastTimer = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: false) { [weak self] _ in
            withAnimation(.easeOut(duration: 0.2)) {
                self?.zoomToastText = nil
            }
        }
    }
    
    public func pauseAllMedia() {
        pauseMediaTrigger = UUID()
    }
    
    public func toggleDarkModeForActiveTab() {
        guard let index = tabs.firstIndex(where: { $0.id == selectedTabId }) else { return }
        tabs[index].isDarkModeInjected.toggle()
        reloadActiveTab()
    }
    
    public func setAutoRefresh(seconds: Int) {
        guard let index = tabs.firstIndex(where: { $0.id == selectedTabId }) else { return }
        let tabId = tabs[index].id
        tabs[index].autoRefreshSeconds = seconds
        
        refreshTimers[tabId]?.invalidate()
        refreshTimers.removeValue(forKey: tabId)
        
        if seconds > 0 {
            let timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(seconds), repeats: true) { [weak self] _ in
                guard let self = self, self.selectedTabId == tabId else { return }
                self.reloadActiveTab()
            }
            refreshTimers[tabId] = timer
        }
    }
    
    // MARK: - Persistence
    
    private func saveState() {
        do {
            let encoded = try JSONEncoder().encode(tabs)
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
            
            let settings: [String: Any] = [
                "isPinned": isPinned,
                "windowOpacity": windowOpacity,
                "isAdBlockEnabledGlobally": isAdBlockEnabledGlobally,
                "customWidth": customWidth,
                "customHeight": customHeight
            ]
            UserDefaults.standard.set(settings, forKey: settingsDefaultsKey)
        } catch {
            print("Failed to save AppState: \(error)")
        }
    }
    
    private func loadState() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let savedTabs = try? JSONDecoder().decode([TabItem].self, from: data),
           !savedTabs.isEmpty {
            self.tabs = savedTabs
            self.selectedTabId = savedTabs.first?.id ?? UUID()
        }
        
        if let settings = UserDefaults.standard.dictionary(forKey: settingsDefaultsKey) {
            self.isPinned = settings["isPinned"] as? Bool ?? false
            self.windowOpacity = settings["windowOpacity"] as? Double ?? 1.0
            self.isAdBlockEnabledGlobally = settings["isAdBlockEnabledGlobally"] as? Bool ?? true
            self.customWidth = settings["customWidth"] as? CGFloat ?? 393
            self.customHeight = settings["customHeight"] as? CGFloat ?? 750
            if let engineRaw = settings["defaultSearchEngine"] as? String,
               let engine = SearchEngine(rawValue: engineRaw) {
                self.defaultSearchEngine = engine
            }
        }
    }
}

// MARK: - Search Engine Preset

public enum SearchEngine: String, Codable, CaseIterable, Identifiable {
    case google = "Google"
    case duckduckgo = "DuckDuckGo"
    case bing = "Bing"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .google: return "magnifyingglass"
        case .duckduckgo: return "shield.lefthalf.filled"
        case .bing: return "b.circle"
        }
    }
    
    public func searchUrl(for query: String) -> String {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        switch self {
        case .google:
            return "https://www.google.com/search?q=\(encoded)"
        case .duckduckgo:
            return "https://duckduckgo.com/?q=\(encoded)"
        case .bing:
            return "https://www.bing.com/search?q=\(encoded)"
        }
    }
}
