import AppKit
import SwiftUI

// MARK: - Status Bar Alignment & Multi-Screen Layout Management
extension MenuBarController {
    public func setCapsuleStatusItemLength(_ length: CGFloat) {
        capsuleStatusItem?.length = length
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
        
        capsuleView?.updateCapsuleLayout()
        
        let panelSize = appState.currentWindowSize
        
        let screen = buttonWindow.screen
            ?? NSScreen.screens.first(where: { NSMouseInRect(buttonWindow.frame.origin, $0.frame, false) })
            ?? NSScreen.main
            ?? NSScreen.screens[0]
        
        let screenVisibleFrame = screen.visibleFrame
        
        // Exact pixel X of the active tab icon on macOS screen
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
        
        var x = tabScreenX - (panelSize.width / 2.0)
        x = max(screenVisibleFrame.minX + 8, min(x, screenVisibleFrame.maxX - panelSize.width - 8))
        
        let y = buttonWindow.frame.minY - panelSize.height - 4
        let targetFrame = NSRect(x: x, y: y, width: panelSize.width, height: panelSize.height)
        
        isProgrammaticResize = true
        if animated && panel.isVisible {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.36
                context.timingFunction = CAMediaTimingFunction(controlPoints: 0.16, 1.0, 0.3, 1.0)
                panel.animator().setFrame(targetFrame, display: true)
            }, completionHandler: { [weak self] in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    self?.isProgrammaticResize = false
                }
            })
        } else {
            panel.setFrame(targetFrame, display: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                self?.isProgrammaticResize = false
            }
        }
        
        // Update arrow center X offset relative to window
        let calculatedArrowX = tabScreenX - x
        withAnimation(.spring(response: 0.36, dampingFraction: 0.85)) {
            self.appState.arrowOffsetX = max(18, min(panelSize.width - 18, calculatedArrowX))
        }
    }
}
