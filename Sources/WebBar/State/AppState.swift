import Foundation
import SwiftUI
import Combine

public enum AppLanguage: String, Codable, CaseIterable, Identifiable {
    case vietnamese = "vi"
    case english = "en"
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .vietnamese: return "Tiếng Việt 🇻🇳"
        case .english: return "English 🇬🇧"
        }
    }
}

public final class AppState: ObservableObject {
    // MARK: - Published State
    @Published public var tabs: [TabItem] = []
    @Published public var selectedTabId: UUID = UUID()
    @Published public var isPinned: Bool = false
    @Published public var language: AppLanguage = .vietnamese {
        didSet { saveState() }
    }
    @Published public var windowOpacity: Double = 1.0
    @Published public var isSettingsOpen: Bool = false
    @Published public var urlInputText: String = ""
    @Published public var isOmniboxFocused: Bool = false
    @Published public var isAdBlockEnabledGlobally: Bool = true
    @Published public var customWidth: CGFloat = 393
    @Published public var customHeight: CGFloat = 750
    @Published public var arrowOffsetX: CGFloat = 196
    @Published public var isTopBarHidden: Bool = true
    @Published public var isFloatingURLBarOpen: Bool = false
    @Published public var launchAtLogin: Bool = false
    @Published public var zoomToastText: String? = nil
    @Published public var urlErrorMessage: String? = nil
    
    // Webview navigation triggers
    @Published public var navigationTrigger: UUID = UUID()
    @Published public var reloadTrigger: UUID = UUID()
    @Published public var backTrigger: UUID = UUID()
    @Published public var forwardTrigger: UUID = UUID()
    @Published public var pauseMediaTrigger: UUID = UUID()
    
    // Active tab status
    @Published public var currentCanGoBack: Bool = false
    @Published public var currentCanGoForward: Bool = false
    @Published public var currentIsLoading: Bool = false
    @Published public var currentProgress: Double = 0.0
    
    // Internal Timers & Storage
    internal var zoomToastTimer: Timer?
    internal var refreshTimers: [UUID: Timer] = [:]
    internal let userDefaultsKey = "WebBarSavedTabs"
    internal let settingsDefaultsKey = "WebBarUserSettings"
    
    // MARK: - Initialization
    public init() {
        loadState()
        
        if tabs.isEmpty {
            let defaultTab = TabItem(
                title: "New Tab",
                urlString: "",
                viewport: .iphoneSE,
                isAdBlockEnabled: isAdBlockEnabledGlobally
            )
            tabs = [defaultTab]
            selectedTabId = defaultTab.id
        }
        
        self.launchAtLogin = LaunchAtLoginManager.shared.isEnabled
    }
    
    // MARK: - Computed Properties
    public var activeTab: TabItem? {
        tabs.first(where: { $0.id == selectedTabId }) ?? tabs.first
    }
    
    public var activeTabIndex: Int {
        tabs.firstIndex(where: { $0.id == selectedTabId }) ?? 0
    }
    
    public var currentWindowBackgroundColor: Color {
        return Color(nsColor: .windowBackgroundColor)
    }
    
    public var currentWindowSize: CGSize {
        guard let tab = activeTab else { return ViewportMode.iphoneSE.size }
        return tab.currentSize
    }
    
    // MARK: - Window Toggles & Bridge Methods
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
        isFloatingURLBarOpen = true
        isOmniboxFocused = true
    }
    
    public func closeFloatingURLBar() {
        isFloatingURLBarOpen = false
        isOmniboxFocused = false
    }
    
    public func toggleAdBlock() {
        isAdBlockEnabledGlobally.toggle()
        saveState()
    }
    
    public func setLaunchAtLogin(_ enabled: Bool) {
        LaunchAtLoginManager.shared.setEnabled(enabled)
        launchAtLogin = enabled
    }
    
    public func pauseAllMedia() {
        pauseMediaTrigger = UUID()
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
    
    public func syncStatusItems() {
        MenuBarController.shared.syncStatusItems()
    }
}
