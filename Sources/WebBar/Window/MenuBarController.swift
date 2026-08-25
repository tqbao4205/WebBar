import AppKit
import SwiftUI
import Combine
import WebKit

public final class MenuBarController: NSObject {
    public static let shared = MenuBarController()
    
    public var capsuleStatusItem: NSStatusItem?
    public var capsuleView: MenuBarCapsuleNSView?
    public private(set) var panel: FloatingPanel?
    private var eventMonitor: Any?
    private var cancellables = Set<AnyCancellable>()
    private var isProgrammaticResize = false
    
    public let appState = AppState()
    
    public override init() {
        super.init()
    }
    
    public func setup() {
        setupPanel()
        syncStatusItems()
        setupEventMonitors()
        setupBindings()
        setupHotkeys()
    }
    
    public func setCapsuleStatusItemLength(_ length: CGFloat) {
        capsuleStatusItem?.length = length
    }
    
    // MARK: - Multi-Status Items Capsule Management
    
    public func syncStatusItems() {
        if capsuleStatusItem == nil {
            let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            self.capsuleStatusItem = item
            
            let capsule = MenuBarCapsuleNSView(controller: self)
            self.capsuleView = capsule
            
            if let button = item.button {
                button.target = nil
                button.action = nil
                button.subviews.forEach { $0.removeFromSuperview() }
                button.addSubview(capsule)
                
                capsule.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    capsule.leadingAnchor.constraint(equalTo: button.leadingAnchor),
                    capsule.trailingAnchor.constraint(equalTo: button.trailingAnchor),
                    capsule.topAnchor.constraint(equalTo: button.topAnchor),
                    capsule.bottomAnchor.constraint(equalTo: button.bottomAnchor)
                ])
            }
        }
        
        capsuleView?.updateCapsuleLayout()
    }
    
    public func showContextMenu(for tabId: UUID, event: NSEvent? = nil) {
        guard let tab = appState.tabs.first(where: { $0.id == tabId }) else { return }
        
        let menu = NSMenu()
        
        // 1. Header with Tab Title
        let titleItem = NSMenuItem(title: tab.isBlank ? "WebBar — New Tab" : tab.title, action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        menu.addItem(NSMenuItem.separator())
        
        // 2. Navigation Controls
        menu.addItem(createMenuItem(
            title: "Go to URL / Search...",
            systemImage: "magnifyingglass",
            action: #selector(menuGoToURL(_:)),
            keyEquivalent: "l",
            representedObject: tabId
        ))
        
        menu.addItem(createMenuItem(
            title: "Reload Page",
            systemImage: "arrow.clockwise",
            action: #selector(menuReloadTab),
            keyEquivalent: "r"
        ))
        
        if appState.currentCanGoBack {
            menu.addItem(createMenuItem(
                title: "Back",
                systemImage: "chevron.backward",
                action: #selector(menuGoBack),
                keyEquivalent: "["
            ))
        }
        
        if appState.currentCanGoForward {
            menu.addItem(createMenuItem(
                title: "Forward",
                systemImage: "chevron.forward",
                action: #selector(menuGoForward),
                keyEquivalent: "]"
            ))
        }
        
        if !tab.isBlank && !tab.urlString.isEmpty {
            menu.addItem(createMenuItem(
                title: "Copy URL",
                systemImage: "doc.on.doc",
                action: #selector(menuCopyURL(_:)),
                keyEquivalent: "c",
                modifierMask: [.command, .shift],
                representedObject: tab.urlString
            ))
            
            menu.addItem(createMenuItem(
                title: "Open in Safari",
                systemImage: "safari",
                action: #selector(menuOpenInBrowser(_:)),
                keyEquivalent: "o",
                modifierMask: [.command, .option],
                representedObject: tab.urlString
            ))
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // 3. Tab Management
        menu.addItem(createMenuItem(
            title: "New Tab",
            systemImage: "plus",
            action: #selector(menuNewTab),
            keyEquivalent: "t"
        ))
        
        if appState.tabs.count > 1 {
            menu.addItem(createMenuItem(
                title: "Close Tab",
                systemImage: "xmark",
                action: #selector(menuCloseTab(_:)),
                keyEquivalent: "w",
                representedObject: tabId
            ))
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // 4. Window & Viewport Controls
        menu.addItem(createMenuItem(
            title: "Pin on Top",
            systemImage: appState.isPinned ? "pin.fill" : "pin",
            action: #selector(menuTogglePin),
            keyEquivalent: "p",
            modifierMask: [.command, .shift],
            state: appState.isPinned ? .on : .off
        ))
        
        menu.addItem(createMenuItem(
            title: "Detach as Floating Window",
            systemImage: "macwindow.on.rectangle",
            action: #selector(menuToggleDetach),
            state: appState.isDetached ? .on : .off
        ))
        
        // Device Viewport Submenu
        let viewportMenu = NSMenu()
        for mode in ViewportMode.allCases {
            let item = createMenuItem(
                title: "\(mode.rawValue) (\(Int(mode.size.width))×\(Int(mode.size.height)))",
                systemImage: mode.iconName,
                action: #selector(menuSelectViewport(_:)),
                representedObject: [tabId.uuidString, mode.rawValue],
                state: (tab.viewport == mode) ? .on : .off
            )
            viewportMenu.addItem(item)
        }
        let viewportItem = createMenuItem(
            title: "Device: \(tab.viewport.rawValue)",
            systemImage: tab.viewport.iconName
        )
        viewportItem.submenu = viewportMenu
        menu.addItem(viewportItem)
        
        // Zoom Submenu
        let zoomMenu = NSMenu()
        zoomMenu.addItem(createMenuItem(
            title: "Zoom In (+10%)",
            systemImage: "plus.magnifyingglass",
            action: #selector(menuZoomIn),
            keyEquivalent: "+"
        ))
        zoomMenu.addItem(createMenuItem(
            title: "Zoom Out (-10%)",
            systemImage: "minus.magnifyingglass",
            action: #selector(menuZoomOut),
            keyEquivalent: "-"
        ))
        zoomMenu.addItem(createMenuItem(
            title: "Reset Zoom (100%)",
            systemImage: "arrow.counterclockwise",
            action: #selector(menuResetZoom),
            keyEquivalent: "0"
        ))
        
        let zoomItem = createMenuItem(title: "Zoom (\(Int(tab.zoomFactor * 100))%)", systemImage: "viewfinder")
        zoomItem.submenu = zoomMenu
        menu.addItem(zoomItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 5. Settings & Preferences
        menu.addItem(createMenuItem(
            title: "Settings & Preferences...",
            systemImage: "gearshape",
            action: #selector(menuOpenSettings),
            keyEquivalent: ","
        ))
        
        menu.addItem(createMenuItem(
            title: "Launch at Login (Khởi động cùng máy)",
            systemImage: "power",
            action: #selector(menuToggleLaunchAtLogin),
            state: appState.launchAtLogin ? .on : .off
        ))
        
        menu.addItem(createMenuItem(
            title: "Clear Cache & Refresh",
            systemImage: "trash",
            action: #selector(menuClearCache)
        ))
        
        menu.addItem(NSMenuItem.separator())
        
        // 6. Quit App
        menu.addItem(createMenuItem(
            title: "Quit WebBar",
            systemImage: "power.circle",
            action: #selector(menuQuit),
            keyEquivalent: "q"
        ))
        
        if let button = capsuleStatusItem?.button {
            if let event = event {
                let locationInButton = button.convert(event.locationInWindow, from: nil)
                menu.popUp(positioning: nil, at: locationInButton, in: button)
            } else {
                menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height), in: button)
            }
        }
    }
    
    // MARK: - Native Menu Item Helper with Monochrome Template Icons
    
    private func createMenuItem(
        title: String,
        systemImage: String? = nil,
        action: Selector? = nil,
        keyEquivalent: String = "",
        modifierMask: NSEvent.ModifierFlags = .command,
        representedObject: Any? = nil,
        state: NSControl.StateValue = .off
    ) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.keyEquivalentModifierMask = modifierMask
        item.target = self
        item.representedObject = representedObject
        item.state = state
        
        if let systemImage = systemImage {
            let config = NSImage.SymbolConfiguration(pointSize: 12.5, weight: .regular)
            if let img = NSImage(systemSymbolName: systemImage, accessibilityDescription: title)?.withSymbolConfiguration(config) {
                img.isTemplate = true // Pure monochrome white in Dark Mode, dark in Light Mode
                item.image = img
            }
        }
        return item
    }
    
    // MARK: - Menu Actions
    
    @objc private func menuGoToURL(_ sender: NSMenuItem) {
        if let tabId = sender.representedObject as? UUID {
            appState.selectTab(id: tabId)
            showPanel(for: tabId)
            appState.openFloatingURLBar()
        }
    }
    
    @objc private func menuGoBack() {
        appState.goBack()
    }
    
    @objc private func menuGoForward() {
        appState.goForward()
    }
    
    @objc private func menuCopyURL(_ sender: NSMenuItem) {
        if let urlStr = sender.representedObject as? String {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(urlStr, forType: .string)
        }
    }
    
    @objc private func menuOpenInBrowser(_ sender: NSMenuItem) {
        if let urlStr = sender.representedObject as? String, let url = URL(string: urlStr) {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc private func menuNewTab() {
        appState.addNewTab()
        syncStatusItems()
        showPanel(for: appState.selectedTabId)
    }
    
    @objc private func menuReloadTab() {
        appState.reloadActiveTab()
    }
    
    @objc private func menuCloseTab(_ sender: NSMenuItem) {
        if let tabId = sender.representedObject as? UUID {
            appState.closeTab(id: tabId)
            syncStatusItems()
        }
    }
    
    @objc private func menuTogglePin() {
        appState.togglePin()
    }
    
    @objc private func menuToggleDetach() {
        appState.toggleDetach()
    }
    
    @objc private func menuZoomIn() {
        appState.zoomIn()
    }
    
    @objc private func menuZoomOut() {
        appState.zoomOut()
    }
    
    @objc private func menuResetZoom() {
        appState.resetZoom()
    }
    
    @objc private func menuSelectViewport(_ sender: NSMenuItem) {
        if let params = sender.representedObject as? [String],
           params.count == 2,
           let tabId = UUID(uuidString: params[0]),
           let mode = ViewportMode(rawValue: params[1]) {
            appState.selectTab(id: tabId)
            appState.setViewport(mode, for: tabId)
            showPanel(for: tabId)
        } else if let modeRaw = sender.representedObject as? String,
                  let mode = ViewportMode(rawValue: modeRaw) {
            appState.setViewport(mode)
            showPanel()
        }
    }
    
    @objc private func menuOpenSettings() {
        appState.isSettingsOpen = true
        showPanel()
    }
    
    @objc private func menuClearCache() {
        let websiteDataTypes = Set([WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache])
        WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes, modifiedSince: Date.distantPast) { [weak self] in
            DispatchQueue.main.async {
                self?.appState.reloadActiveTab()
            }
        }
    }
    
    @objc private func menuToggleLaunchAtLogin() {
        appState.setLaunchAtLogin(!appState.launchAtLogin)
    }
    
    @objc private func menuQuit() {
        NSApplication.shared.terminate(nil)
    }
    
    // MARK: - Floating Panel Setup
    
    private func setupPanel() {
        let size = appState.currentWindowSize
        let initialRect = NSRect(x: 0, y: 0, width: size.width, height: size.height)
        
        let panel = FloatingPanel(contentRect: initialRect)
        panel.delegate = self
        let contentView = ContentView()
            .environmentObject(appState)
        
        panel.contentView = NSHostingView(rootView: contentView)
        self.panel = panel
    }
    
    // MARK: - Bindings & Observations
    
    private func setupBindings() {
        // Observe tabs & selected tab changes to update status items & window frame
        appState.$tabs
            .combineLatest(appState.$selectedTabId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.capsuleView?.updateCapsuleLayout()
                self?.updatePanelFrame()
            }
            .store(in: &cancellables)
        
        // Observe opacity changes
        appState.$windowOpacity
            .receive(on: DispatchQueue.main)
            .sink { [weak self] opacity in
                self?.panel?.alphaValue = CGFloat(opacity)
            }
            .store(in: &cancellables)
    }
    
    private func updatePanelFrame() {
        guard let panel = panel else { return }
        let targetSize = appState.currentWindowSize
        
        if abs(panel.frame.width - targetSize.width) < 1 && abs(panel.frame.height - targetSize.height) < 1 {
            return
        }
        
        isProgrammaticResize = true
        var currentFrame = panel.frame
        let heightDiff = targetSize.height - currentFrame.size.height
        
        currentFrame.origin.y -= heightDiff
        currentFrame.size = targetSize
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().setFrame(currentFrame, display: true)
        }, completionHandler: { [weak self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self?.isProgrammaticResize = false
            }
        })
    }
    
    // MARK: - Hotkey Integration
    
    private func setupHotkeys() {
        let hotkey = HotkeyManager.shared
        hotkey.onToggleWindow = { [weak self] in
            self?.togglePanel()
        }
        hotkey.onNewTab = { [weak self] in
            self?.appState.addNewTab()
            self?.syncStatusItems()
        }
        hotkey.onCloseActiveTab = { [weak self] in
            guard let self = self, let active = self.appState.activeTab else { return }
            self.appState.closeTab(id: active.id)
            self.syncStatusItems()
        }
        hotkey.onReload = { [weak self] in
            self?.appState.reloadActiveTab()
        }
        hotkey.onTogglePin = { [weak self] in
            self?.appState.togglePin()
        }
        hotkey.onToggleTopBar = { [weak self] in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                self?.appState.toggleTopBar()
            }
        }
        hotkey.onFocusURL = { [weak self] in
            self?.appState.openFloatingURLBar()
        }
        hotkey.onSelectTabAtIndex = { [weak self] index in
            self?.appState.selectTabAtIndex(index)
        }
        hotkey.onGoBack = { [weak self] in
            self?.appState.goBack()
        }
        hotkey.onGoForward = { [weak self] in
            self?.appState.goForward()
        }
        hotkey.onZoomIn = { [weak self] in
            self?.appState.zoomIn()
        }
        hotkey.onZoomOut = { [weak self] in
            self?.appState.zoomOut()
        }
        hotkey.onResetZoom = { [weak self] in
            self?.appState.resetZoom()
        }
        hotkey.startMonitoring()
    }
    
    // MARK: - Outside Click Event Monitor
    
    private func setupEventMonitors() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        ) { [weak self] _ in
            guard let self = self,
                  let panel = self.panel,
                  panel.isVisible,
                  !self.appState.isPinned,
                  !self.appState.isDetached else {
                return
            }
            
            let mouseLocation = NSEvent.mouseLocation
            
            // Do NOT hide if mouse is clicking ANY window of our app (Panel, Google Login Popup, Settings, Open Panel)
            for window in NSApp.windows where window.isVisible {
                if window.frame.contains(mouseLocation) {
                    return
                }
            }
            
            // Clicked genuinely outside all WebBar windows
            self.hidePanel()
        }
    }
    
    // MARK: - Panel Visibility Controls
    
    public func togglePanel() {
        guard let panel = panel else { return }
        if panel.isVisible {
            hidePanel()
        } else {
            showPanel(for: appState.selectedTabId)
        }
    }
    
    public func showPanel(for tabId: UUID? = nil) {
        guard let panel = panel else { return }
        let targetId = tabId ?? appState.selectedTabId
        
        if !appState.isDetached {
            positionPanelUnderStatusBar(for: targetId)
        }
        
        panel.alphaValue = CGFloat(appState.windowOpacity)
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        capsuleView?.needsDisplay = true
    }
    
    public func hidePanel() {
        appState.pauseAllMedia()
        panel?.orderOut(nil)
        capsuleView?.needsDisplay = true
    }
    
    public func updatePanelFrame(animated: Bool = true) {
        guard let panel = panel, panel.isVisible else { return }
        positionPanelUnderStatusBar(for: appState.selectedTabId, animated: animated)
    }
    
    public func positionPanelUnderStatusBar(for tabId: UUID, animated: Bool = false) {
        guard let panel = panel,
              let item = capsuleStatusItem,
              let button = item.button,
              let buttonWindow = button.window else {
            return
        }
        
        // Force immediate layout update of capsule view
        capsuleView?.updateCapsuleLayout()
        
        let panelSize = appState.currentWindowSize
        
        // Find screen containing button
        let screen = buttonWindow.screen
            ?? NSScreen.screens.first(where: { NSMouseInRect(buttonWindow.frame.origin, $0.frame, false) })
            ?? NSScreen.main
            ?? NSScreen.screens[0]
        
        let screenVisibleFrame = screen.visibleFrame
        
        // Get EXACT pixel X of the active tab icon on macOS screen
        let relativeX = capsuleView?.tabCenterRelativeX(for: tabId) ?? 49.5
        let tabScreenX: CGFloat
        if let capsule = capsuleView, let win = capsule.window {
            let localPoint = NSPoint(x: relativeX, y: capsule.bounds.midY)
            let windowPoint = capsule.convert(localPoint, to: nil)
            let screenPoint = win.convertToScreen(NSRect(origin: windowPoint, size: .zero)).origin
            tabScreenX = screenPoint.x
        } else {
            tabScreenX = buttonWindow.frame.origin.x + relativeX
        }
        
        // Calculate X centered under the active tab icon, clamped to screen bounds
        var x = tabScreenX - (panelSize.width / 2.0)
        x = max(screenVisibleFrame.minX + 8, min(x, screenVisibleFrame.maxX - panelSize.width - 8))
        
        // Align flush to Menu Bar so the organic liquid bridge touches the bottom edge seamlessly
        let y = buttonWindow.frame.minY - panelSize.height + 1
        
        let targetFrame = NSRect(x: x, y: y, width: panelSize.width, height: panelSize.height)
        
        isProgrammaticResize = true
        panel.setFrame(targetFrame, display: true)
        isProgrammaticResize = false
        
        // Update arrow/bridge center X offset relative to window, pointing with 100% precision to active tab icon
        appState.arrowOffsetX = max(30, min(panelSize.width - 30, tabScreenX - x))
    }
    
    deinit {
        if let eventMonitor = eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
    }
}

// MARK: - NSWindowDelegate

extension MenuBarController: NSWindowDelegate {
    public func windowDidResize(_ notification: Notification) {
        guard let panel = panel, !isProgrammaticResize else { return }
        let newWidth = panel.frame.width
        let newHeight = panel.frame.height
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.appState.setCustomDimensions(width: newWidth, height: newHeight, for: self.appState.selectedTabId)
        }
    }
    
    public func windowDidResignKey(_ notification: Notification) {
        guard let panel = panel, panel.isVisible, !appState.isPinned, !appState.isDetached else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let panel = self.panel, panel.isVisible,
                  !self.appState.isPinned, !self.appState.isDetached else { return }
            
            // If another window of our app (like Google OAuth Login Popup or Settings) is active, keep panel open!
            if NSApp.windows.contains(where: { $0.isVisible && $0 != panel && $0.isKeyWindow }) {
                return
            }
            
            let mouseLoc = NSEvent.mouseLocation
            for window in NSApp.windows where window.isVisible {
                if window.frame.contains(mouseLoc) {
                    return
                }
            }
            
            self.hidePanel()
        }
    }
}
