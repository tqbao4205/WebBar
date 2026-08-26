import AppKit
import SwiftUI

public final class FloatingPanel: NSPanel {
    public init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [
                .titled,
                .fullSizeContentView,
                .resizable
            ],
            backing: .buffered,
            defer: false
        )
        
        self.isFloatingPanel = true
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.isMovableByWindowBackground = false
        self.isReleasedWhenClosed = false
        self.backgroundColor = .clear
        self.isOpaque = false
        self.minSize = NSSize(width: 320, height: 60)
        self.maxSize = NSSize(width: 1600, height: 1200)
        
        // Hide standard window controls (close, minimize, zoom) in titlebar since we have custom controls
        self.standardWindowButton(.closeButton)?.isHidden = true
        self.standardWindowButton(.miniaturizeButton)?.isHidden = true
        self.standardWindowButton(.zoomButton)?.isHidden = true
    }
    
    public override var canBecomeKey: Bool {
        return true
    }
    
    public override var canBecomeMain: Bool {
        return true
    }
    
    public override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.type == .keyDown {
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let chars = event.charactersIgnoringModifiers?.lowercased() ?? ""
            
            if flags == .command {
                switch chars {
                case "c":
                    if NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: self) { return true }
                case "v":
                    if NSApp.sendAction(#selector(NSText.paste(_:)), to: nil, from: self) { return true }
                case "x":
                    if NSApp.sendAction(#selector(NSText.cut(_:)), to: nil, from: self) { return true }
                case "a":
                    if NSApp.sendAction(#selector(NSText.selectAll(_:)), to: nil, from: self) { return true }
                case "z":
                    if NSApp.sendAction(#selector(UndoManager.undo), to: nil, from: self) { return true }
                default:
                    break
                }
            } else if flags == [.command, .shift] {
                switch chars {
                case "z":
                    if NSApp.sendAction(#selector(UndoManager.redo), to: nil, from: self) { return true }
                case "v":
                    if NSApp.sendAction(#selector(NSTextView.pasteAsPlainText(_:)), to: nil, from: self) { return true }
                default:
                    break
                }
            } else if flags == [.command, .option, .shift] {
                if chars == "v" {
                    if NSApp.sendAction(#selector(NSTextView.pasteAsPlainText(_:)), to: nil, from: self) { return true }
                }
            }
        }
        return super.performKeyEquivalent(with: event)
    }
}
