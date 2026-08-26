import AppKit

public final class HotkeyManager {
    public static let shared = HotkeyManager()
    
    private var globalMonitor: Any?
    private var localMonitor: Any?
    
    public var onToggleWindow: (() -> Void)?
    public var onNewTab: (() -> Void)?
    public var onCloseActiveTab: (() -> Void)?
    public var onReload: (() -> Void)?
    public var onFocusURL: (() -> Void)?
    public var onTogglePin: (() -> Void)?
    public var onToggleTopBar: (() -> Void)?
    public var onSelectTabAtIndex: ((Int) -> Void)?
    public var onGoBack: (() -> Void)?
    public var onGoForward: (() -> Void)?
    public var onZoomIn: (() -> Void)?
    public var onZoomOut: (() -> Void)?
    public var onResetZoom: (() -> Void)?
    public var onEscape: (() -> Void)?
    
    private init() {}
    
    public func startMonitoring() {
        // Global monitor (captures events even when app is in background)
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event, isGlobal: true)
        }
        
        // Local monitor (captures events when WebBar window is active/focused)
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if let self = self, self.handleKeyEvent(event, isGlobal: false) {
                return nil // Handled event, suppress propagation
            }
            return event
        }
    }
    
    public func stopMonitoring() {
        if let globalMonitor = globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }
        if let localMonitor = localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
    }
    
    @discardableResult
    private func handleKeyEvent(_ event: NSEvent, isGlobal: Bool) -> Bool {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let key = event.charactersIgnoringModifiers?.lowercased() ?? ""
        let keyCode = event.keyCode
        
        // Global shortcut: Option + Command + B -> Toggle Window
        if flags == [.command, .option] && (key == "b" || key == "B") {
            DispatchQueue.main.async { [weak self] in
                self?.onToggleWindow?()
            }
            return true
        }
        
        // Shortcuts when focused in app
        if !isGlobal {
            // Esc key (keyCode 53) -> Dismiss / Cancel
            if flags.isEmpty && keyCode == 53 {
                DispatchQueue.main.async { [weak self] in
                    self?.onEscape?()
                }
                return true
            }
            // Check Cmd + Zoom shortcuts (Cmd + +, Cmd + =, Cmd + -, Cmd + 0)
            if flags.contains(.command) {
                if keyCode == 24 || key == "=" || key == "+" { // '+' key / '=' key
                    onZoomIn?()
                    return true
                } else if keyCode == 27 || key == "-" { // '-' key
                    onZoomOut?()
                    return true
                } else if keyCode == 29 || key == "0" { // '0' key
                    onResetZoom?()
                    return true
                }
            }
            
            if flags == .command {
                switch key {
                case "t":
                    onNewTab?()
                    return true
                case "w":
                    onCloseActiveTab?()
                    return true
                case "r":
                    onReload?()
                    return true
                case "l":
                    onFocusURL?()
                    return true
                case "[":
                    onGoBack?()
                    return true
                case "]":
                    onGoForward?()
                    return true
                case "1", "2", "3", "4", "5", "6", "7", "8", "9":
                    if let index = Int(key) {
                        onSelectTabAtIndex?(index - 1)
                        return true
                    }
                case "\\":
                    onToggleTopBar?()
                    return true
                default:
                    break
                }
            } else if flags == [.command, .shift] {
                if key == "p" || key == "P" {
                    onTogglePin?()
                    return true
                } else if key == "h" || key == "H" || key == "f" || key == "F" {
                    onToggleTopBar?()
                    return true
                }
            }
        }
        
        return false
    }
}
