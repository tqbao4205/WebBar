import Foundation
import SwiftUI

// MARK: - Tab CRUD & Lifecycle Management
extension AppState {
    public func addNewTab(
        url: String = "",
        title: String = "New Tab",
        viewport: ViewportMode = .iphoneSE
    ) {
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
        
        MenuBarController.shared.capsuleView?.updateCapsuleLayout()
        MenuBarController.shared.positionPanelUnderStatusBar(
            for: newTab.id,
            animated: MenuBarController.shared.panel?.isVisible == true
        )
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
    
    public func closeActiveTab() {
        closeTab(id: selectedTabId)
    }
    
    public func selectTab(id: UUID) {
        if let current = activeTab, current.isBlank, current.id != id, tabs.count > 1 {
            closeTab(id: current.id)
        }
        
        guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }
        selectedTabId = id
        urlInputText = tabs[index].urlString
        
        if tabs[index].unreadCount > 0 {
            tabs[index].unreadCount = 0
            saveState()
            MenuBarController.shared.syncStatusItems()
        }
        
        MenuBarController.shared.updatePanelFrame(animated: true)
    }
    
    public func selectTabAtIndex(_ index: Int) {
        guard index >= 0 && index < tabs.count else { return }
        selectTab(id: tabs[index].id)
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
    
    public func setUnreadCount(for tabId: UUID, count: Int) {
        guard let index = tabs.firstIndex(where: { $0.id == tabId }) else { return }
        
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
}
