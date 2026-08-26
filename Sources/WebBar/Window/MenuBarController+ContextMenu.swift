import AppKit
import WebKit

// MARK: - Native Status Bar Context Menu & Selectors
extension MenuBarController {
    public func showContextMenu(for tabId: UUID, event: NSEvent? = nil) {
        guard let tab = appState.tabs.first(where: { $0.id == tabId }) else { return }
        let isVI = appState.language == .vietnamese
        
        let menu = NSMenu()
        
        // 1. Header
        let titleItem = NSMenuItem(title: tab.isBlank ? "WebBar" : tab.title, action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        menu.addItem(NSMenuItem.separator())
        
        // 2. Tab & Navigation Actions
        menu.addItem(createMenuItem(
            title: isVI ? "Mở Tab Mới" : "New Tab",
            systemImage: "plus",
            action: #selector(menuNewTab),
            keyEquivalent: "t"
        ))
        
        menu.addItem(createMenuItem(
            title: isVI ? "Tải Lại Trang" : "Reload Page",
            systemImage: "arrow.clockwise",
            action: #selector(menuReloadTab),
            keyEquivalent: "r"
        ))
        
        if !tab.isBlank && !tab.urlString.isEmpty {
            menu.addItem(createMenuItem(
                title: isVI ? "Sao Chép Link (URL)" : "Copy URL",
                systemImage: "doc.on.doc",
                action: #selector(menuCopyURL(_:)),
                keyEquivalent: "c",
                modifierMask: [.command, .shift],
                representedObject: tab.urlString
            ))
            
            menu.addItem(createMenuItem(
                title: isVI ? "Mở Bằng Safari" : "Open in Safari",
                systemImage: "safari",
                action: #selector(menuOpenInBrowser(_:)),
                keyEquivalent: "o",
                modifierMask: [.command, .option],
                representedObject: tab.urlString
            ))
        }
        
        if appState.tabs.count > 1 {
            menu.addItem(createMenuItem(
                title: isVI ? "Đóng Tab Này" : "Close Tab",
                systemImage: "xmark",
                action: #selector(menuCloseTab(_:)),
                keyEquivalent: "w",
                representedObject: tabId
            ))
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // 3. Window View & Display Controls
        menu.addItem(createMenuItem(
            title: isVI ? "Ghim giữ cửa sổ mở" : "Keep Window Open (Pin)",
            systemImage: appState.isPinned ? "pin.fill" : "pin",
            action: #selector(menuTogglePin),
            keyEquivalent: "p",
            modifierMask: [.command, .shift],
            state: appState.isPinned ? .on : .off
        ))
        
        // Device Viewport Submenu
        let viewportMenu = NSMenu()
        for mode in ViewportMode.allCases {
            let item = createMenuItem(
                title: mode.displayName,
                systemImage: mode.iconName,
                action: #selector(menuSelectViewport(_:)),
                representedObject: [tabId.uuidString, mode.rawValue],
                state: (tab.viewport == mode) ? .on : .off
            )
            viewportMenu.addItem(item)
        }
        let viewportItem = createMenuItem(
            title: isVI ? "Thiết bị: \(tab.viewport.rawValue)" : "Device: \(tab.viewport.rawValue)",
            systemImage: tab.viewport.iconName
        )
        viewportItem.submenu = viewportMenu
        menu.addItem(viewportItem)
        
        // Zoom Submenu
        let zoomMenu = NSMenu()
        zoomMenu.addItem(createMenuItem(
            title: isVI ? "Phóng to (+10%)" : "Zoom In (+10%)",
            systemImage: "plus.magnifyingglass",
            action: #selector(menuZoomIn),
            keyEquivalent: "+"
        ))
        zoomMenu.addItem(createMenuItem(
            title: isVI ? "Thu nhỏ (-10%)" : "Zoom Out (-10%)",
            systemImage: "minus.magnifyingglass",
            action: #selector(menuZoomOut),
            keyEquivalent: "-"
        ))
        zoomMenu.addItem(createMenuItem(
            title: isVI ? "Mặc định (100%)" : "Reset Zoom (100%)",
            systemImage: "arrow.counterclockwise",
            action: #selector(menuResetZoom),
            keyEquivalent: "0"
        ))
        
        let zoomItem = createMenuItem(
            title: "Zoom (\(Int(tab.zoomFactor * 100))%)",
            systemImage: "viewfinder"
        )
        zoomItem.submenu = zoomMenu
        menu.addItem(zoomItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 4. Settings & Quit
        menu.addItem(createMenuItem(
            title: isVI ? "Cài Đặt..." : "Settings...",
            systemImage: "gearshape",
            action: #selector(menuOpenSettings),
            keyEquivalent: ","
        ))
        
        menu.addItem(createMenuItem(
            title: isVI ? "Thoát WebBar" : "Quit WebBar",
            systemImage: "power",
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
    
    // MARK: - Native Menu Item Helper
    public func createMenuItem(
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
                img.isTemplate = true
                item.image = img
            }
        }
        return item
    }
    
    // MARK: - Action Selectors
    @objc internal func menuNewTab() {
        appState.addNewTab()
        syncStatusItems()
        showPanel(for: appState.selectedTabId)
    }
    
    @objc internal func menuReloadTab() {
        appState.reloadActiveTab()
    }
    
    @objc internal func menuCopyURL(_ sender: NSMenuItem) {
        if let urlStr = sender.representedObject as? String {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(urlStr, forType: .string)
        }
    }
    
    @objc internal func menuOpenInBrowser(_ sender: NSMenuItem) {
        if let urlStr = sender.representedObject as? String, let url = URL(string: urlStr) {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc internal func menuCloseTab(_ sender: NSMenuItem) {
        if let tabId = sender.representedObject as? UUID {
            appState.closeTab(id: tabId)
            syncStatusItems()
        }
    }
    
    @objc internal func menuTogglePin() {
        appState.togglePin()
    }
    
    @objc internal func menuZoomIn() {
        appState.zoomIn()
    }
    
    @objc internal func menuZoomOut() {
        appState.zoomOut()
    }
    
    @objc internal func menuResetZoom() {
        appState.resetZoom()
    }
    
    @objc internal func menuSelectViewport(_ sender: NSMenuItem) {
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
    
    @objc internal func menuOpenSettings() {
        appState.isSettingsOpen = true
        showPanel()
    }
    
    @objc internal func menuQuit() {
        NSApplication.shared.terminate(nil)
    }
}
