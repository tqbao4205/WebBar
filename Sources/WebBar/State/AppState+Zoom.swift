import Foundation
import SwiftUI

// MARK: - Page Zoom Factor Management & HUD Toast
extension AppState {
    public func zoomIn(for tabId: UUID? = nil) {
        let targetId = tabId ?? selectedTabId
        guard let index = tabs.firstIndex(where: { $0.id == targetId }) else { return }
        let currentZoom = tabs[index].zoomFactor
        // Increment by +10% (0.1), clamped up to 300% (3.0)
        let newZoom = min(3.0, ((currentZoom + 0.1) * 10).rounded() / 10.0)
        tabs[index].zoomFactor = newZoom
        saveState()
        objectWillChange.send()
        showZoomToast(text: "\(Int(round(newZoom * 100)))%")
    }
    
    public func zoomOut(for tabId: UUID? = nil) {
        let targetId = tabId ?? selectedTabId
        guard let index = tabs.firstIndex(where: { $0.id == targetId }) else { return }
        let currentZoom = tabs[index].zoomFactor
        // Decrement by -10% (0.1), clamped down to 50% (0.5)
        let newZoom = max(0.5, ((currentZoom - 0.1) * 10).rounded() / 10.0)
        tabs[index].zoomFactor = newZoom
        saveState()
        objectWillChange.send()
        showZoomToast(text: "\(Int(round(newZoom * 100)))%")
    }
    
    public func resetZoom(for tabId: UUID? = nil) {
        let targetId = tabId ?? selectedTabId
        guard let index = tabs.firstIndex(where: { $0.id == targetId }) else { return }
        tabs[index].zoomFactor = 1.0
        saveState()
        objectWillChange.send()
        showZoomToast(text: "100%")
    }
    
    public func showZoomToast(text: String) {
        zoomToastTimer?.invalidate()
        withAnimation(.spring(response: 0.22, dampingFraction: 0.75)) {
            self.zoomToastText = text
        }
        zoomToastTimer = Timer.scheduledTimer(withTimeInterval: 1.4, repeats: false) { [weak self] _ in
            withAnimation(.easeOut(duration: 0.25)) {
                self?.zoomToastText = nil
            }
        }
    }
}
