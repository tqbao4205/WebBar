import AppKit

/// A dedicated floating borderless overlay window that renders the dragged tab icon
/// anywhere across macOS desktop screens with zero clipping.
public final class DragTabOverlayWindow: NSWindow {
    public static let shared = DragTabOverlayWindow()
    
    private let overlayView = DragTabOverlayView()
    
    public init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 38, height: 38),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        self.isOpaque = false
        self.backgroundColor = .clear
        self.level = .popUpMenu
        self.hasShadow = true
        self.ignoresMouseEvents = true
        self.collectionBehavior = [.canJoinAllSpaces, .transient]
        self.contentView = overlayView
    }
    
    public func update(image: NSImage?, isDeleteMode: Bool, screenPoint: NSPoint) {
        overlayView.tabImage = image
        overlayView.isDeleteMode = isDeleteMode
        overlayView.needsDisplay = true
        
        let windowOrigin = NSPoint(x: screenPoint.x - 19, y: screenPoint.y - 19)
        self.setFrameOrigin(windowOrigin)
        
        if !self.isVisible {
            self.orderFront(nil)
        }
    }
    
    public func dismiss() {
        self.orderOut(nil)
    }
}

/// Custom drawing view for the floating dragged tab icon and delete badge
private final class DragTabOverlayView: NSView {
    var tabImage: NSImage?
    var isDeleteMode: Bool = false
    
    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        ctx.clear(bounds)
        
        let side: CGFloat = 26.0
        let tileRect = NSRect(
            x: bounds.midX - (side / 2.0),
            y: bounds.midY - (side / 2.0),
            width: side,
            height: side
        )
        let tileRadius: CGFloat = 7.0
        let tilePath = CGPath(roundedRect: tileRect, cornerWidth: tileRadius, cornerHeight: tileRadius, transform: nil)
        
        let iconSize: CGFloat = 16.0
        let iconRect = NSRect(
            x: bounds.midX - (iconSize / 2.0),
            y: bounds.midY - (iconSize / 2.0),
            width: iconSize,
            height: iconSize
        )
        
        if isDeleteMode {
            // 1. Red Glowing Delete Squircle Background
            ctx.addPath(tilePath)
            ctx.setFillColor(NSColor.systemRed.withAlphaComponent(0.35).cgColor)
            ctx.fillPath()
            
            ctx.addPath(tilePath)
            ctx.setStrokeColor(NSColor.systemRed.withAlphaComponent(0.95).cgColor)
            ctx.setLineWidth(1.5)
            ctx.strokePath()
            
            // 2. Tab Icon (Recognizable & Visible)
            if let img = tabImage {
                ctx.saveGState()
                ctx.setAlpha(0.88)
                img.draw(in: iconRect)
                ctx.restoreGState()
            }
            
            // 3. Prominent Red [✕] Delete Badge at top-right
            let badgeSize: CGFloat = 11.5
            let badgeRect = NSRect(
                x: tileRect.maxX - badgeSize + 2.5,
                y: tileRect.maxY - badgeSize + 2.5,
                width: badgeSize,
                height: badgeSize
            )
            ctx.addEllipse(in: badgeRect)
            ctx.setFillColor(NSColor.systemRed.cgColor)
            ctx.fillPath()
            
            let xConfig = NSImage.SymbolConfiguration(pointSize: 7.0, weight: .bold)
            if let xImg = NSImage(systemSymbolName: "xmark", accessibilityDescription: "Delete")?.withSymbolConfiguration(xConfig) {
                let symbolRect = NSRect(
                    x: badgeRect.midX - 3.5,
                    y: badgeRect.midY - 3.5,
                    width: 7.0,
                    height: 7.0
                )
                xImg.draw(in: symbolRect)
            }
        } else {
            // 1. Elevated Liquid Glass 3D Bubble
            ctx.addPath(tilePath)
            ctx.setFillColor(NSColor.white.withAlphaComponent(0.25).cgColor)
            ctx.fillPath()
            
            ctx.addPath(tilePath)
            ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.65).cgColor)
            ctx.setLineWidth(1.0)
            ctx.strokePath()
            
            // 2. Tab Icon
            if let img = tabImage {
                img.draw(in: iconRect)
            }
        }
    }
}
