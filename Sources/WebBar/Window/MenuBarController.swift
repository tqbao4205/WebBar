import AppKit
import SwiftUI
import Combine
import WebKit

public final class MenuBarController: NSObject {
    public static let shared = MenuBarController()
    
    public var capsuleStatusItem: NSStatusItem?
    public var capsuleView: MenuBarCapsuleNSView?
    public private(set) var panel: FloatingPanel?
    internal var eventMonitor: Any?
    private var cancellables = Set<AnyCancellable>()
    internal var isProgrammaticResize = false
    
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
    
    // MARK: - Multi-Status Items Capsule Setup
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
    
    // MARK: - Reactive Bindings
    private func setupBindings() {
        appState.$tabs
            .combineLatest(appState.$selectedTabId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _, selectedId in
                guard let self = self else { return }
                self.capsuleView?.updateCapsuleLayout()
                self.positionPanelUnderStatusBar(for: selectedId, animated: self.panel?.isVisible == true)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    self.capsuleView?.updateCapsuleLayout()
                    self.positionPanelUnderStatusBar(for: selectedId, animated: false)
                }
            }
            .store(in: &cancellables)
        
        appState.$windowOpacity
            .receive(on: DispatchQueue.main)
            .sink { [weak self] opacity in
                self?.panel?.alphaValue = CGFloat(opacity)
            }
            .store(in: &cancellables)
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
        let isAlreadyVisible = panel.isVisible
        
        positionPanelUnderStatusBar(for: targetId, animated: isAlreadyVisible)
        
        if !isAlreadyVisible {
            panel.alphaValue = 0.0
            panel.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.22
                context.timingFunction = CAMediaTimingFunction(controlPoints: 0.16, 1.0, 0.3, 1.0)
                panel.animator().alphaValue = CGFloat(appState.windowOpacity)
            }
        } else {
            panel.alphaValue = CGFloat(appState.windowOpacity)
            panel.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
        
        capsuleView?.needsDisplay = true
    }
    
    public func hidePanel() {
        if appState.activeTab?.isBlank == true && appState.tabs.count > 1 {
            appState.closeActiveTabIfBlank()
            syncStatusItems()
        }
        
        appState.pauseAllMedia()
        
        guard let panel = panel, panel.isVisible else { return }
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.18
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().alphaValue = 0.0
        }, completionHandler: { [weak self] in
            self?.panel?.orderOut(nil)
            self?.capsuleView?.needsDisplay = true
        })
    }
    
    deinit {
        if let eventMonitor = eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
    }
}
