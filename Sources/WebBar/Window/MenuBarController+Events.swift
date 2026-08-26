import AppKit
import SwiftUI

// MARK: - Event Monitoring, Hotkeys & NSWindowDelegate
extension MenuBarController: NSWindowDelegate {
    public func setupEventMonitors() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        ) { [weak self] _ in
            guard let self = self,
                  let panel = self.panel,
                  panel.isVisible,
                  !self.appState.isPinned else {
                return
            }
            
            let mouseLocation = NSEvent.mouseLocation
            
            for window in NSApp.windows where window.isVisible {
                if window.frame.contains(mouseLocation) {
                    return
                }
            }
            
            self.hidePanel()
        }
    }
    
    public func setupHotkeys() {
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
        hotkey.onEscape = { [weak self] in
            guard let self = self else { return }
            if self.appState.isFloatingURLBarOpen {
                withAnimation(.easeOut(duration: 0.18)) {
                    self.appState.isFloatingURLBarOpen = false
                }
            } else if self.appState.isSettingsOpen {
                withAnimation(.easeOut(duration: 0.18)) {
                    self.appState.isSettingsOpen = false
                }
            } else if self.appState.activeTab?.isBlank == true && self.appState.tabs.count > 1 {
                self.appState.closeActiveTabIfBlank()
                self.syncStatusItems()
            }
        }
        hotkey.startMonitoring()
    }
    
    // MARK: - NSWindowDelegate
    public func windowDidResize(_ notification: Notification) {
        guard let panel = panel, !isProgrammaticResize else { return }
        let newWidth = panel.frame.width
        let newHeight = panel.frame.height
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.appState.activeTab?.viewport == .custom {
                self.appState.setCustomDimensions(width: newWidth, height: newHeight, for: self.appState.selectedTabId)
            }
        }
    }
    
    public func windowDidResignKey(_ notification: Notification) {
        guard let panel = panel, panel.isVisible, !appState.isPinned else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let panel = self.panel, panel.isVisible,
                  !self.appState.isPinned else { return }
            
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
