import Foundation

// MARK: - Per-Tab Background Auto-Refresh Timers
extension AppState {
    public func setAutoRefresh(seconds: Int, for tabId: UUID? = nil) {
        let targetId = tabId ?? selectedTabId
        guard let index = tabs.firstIndex(where: { $0.id == targetId }) else { return }
        tabs[index].autoRefreshSeconds = seconds
        
        refreshTimers[targetId]?.invalidate()
        refreshTimers.removeValue(forKey: targetId)
        
        if seconds > 0 {
            let timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(seconds), repeats: true) { [weak self] _ in
                guard let self = self, self.selectedTabId == targetId else { return }
                self.reloadActiveTab()
            }
            refreshTimers[targetId] = timer
        }
    }
    
    public func clearAllRefreshTimers() {
        for (_, timer) in refreshTimers {
            timer.invalidate()
        }
        refreshTimers.removeAll()
    }
}
