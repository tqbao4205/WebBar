import AppKit

public final class MenuBarCapsuleNSView: NSView {
    public weak var controller: MenuBarController?
    private var trackingArea: NSTrackingArea?
    private var hoveredIndex: Int? = nil // -1 for +, 0...n for tabs
    private var tabWebIcons: [String: NSImage] = [:]
    
    // Drag & Drop Reordering & Delete State
    private var isDragging: Bool = false
    private var dragCandidateIndex: Int? = nil
    private var draggedTabIndex: Int? = nil
    private var mouseDownLocation: NSPoint = .zero
    private var currentDragLocation: NSPoint = .zero
    private var isMarkedForDeletion: Bool = false
    
    // Prominent Borderless Sizing
    private let itemWidth: CGFloat = 28
    private let itemHeight: CGFloat = 22
    private let iconSize: CGFloat = 21.0
    private let itemSpacing: CGFloat = 4.0
    private let capsulePaddingH: CGFloat = 4.0
    
    public init(controller: MenuBarController) {
        self.controller = controller
        super.init(frame: .zero)
        self.wantsLayer = true
        updateCapsuleLayout()
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public var totalCapsuleWidth: CGFloat {
        guard let controller = controller else { return bounds.width }
        let webTabs = controller.appState.tabs.filter { !$0.isBlank }
        let totalCount = webTabs.count + 1
        let tabsTotalWidth = (CGFloat(totalCount) * itemWidth) + (CGFloat(totalCount - 1) * itemSpacing)
        return (capsulePaddingH * 2) + tabsTotalWidth
    }
    
    public func updateCapsuleLayout() {
        let totalWidth = totalCapsuleWidth
        let totalHeight: CGFloat = 24
        
        let newFrame = NSRect(x: 0, y: 0, width: totalWidth, height: totalHeight)
        if self.frame != newFrame {
            self.frame = newFrame
            controller?.setCapsuleStatusItemLength(totalWidth)
        }
        
        setupTrackingArea()
        needsDisplay = true
    }
    
    /// Returns the exact center X coordinate of the specified tab's icon inside the capsule view
    public func tabCenterRelativeX(for tabId: UUID?) -> CGFloat {
        guard let controller = controller else { return itemWidth / 2.0 }
        let webTabs = controller.appState.tabs.filter { !$0.isBlank }
        let index: Int
        if let tabId = tabId, let found = webTabs.firstIndex(where: { $0.id == tabId }) {
            index = found
        } else {
            // Blank / New Tab points directly to the [+] squircle at the end!
            index = webTabs.count
        }
        let itemX = capsulePaddingH + (CGFloat(index) * (itemWidth + itemSpacing))
        return itemX + (itemWidth / 2.0)
    }
    
    private func setupTrackingArea() {
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .mouseMoved, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        self.trackingArea = area
    }
    
    override public func updateTrackingAreas() {
        super.updateTrackingAreas()
        setupTrackingArea()
    }
    
    // MARK: - Drawing (Prominent White Squircle Icons)
    
    override public func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let ctx = NSGraphicsContext.current?.cgContext, let controller = controller else { return }
        
        let bounds = self.bounds
        let midY = bounds.height / 2.0
        
        let startX = capsulePaddingH
        let webTabs = controller.appState.tabs.filter { !$0.isBlank }
        let selectedTabId = controller.appState.selectedTabId
        let isBlankActive = controller.appState.activeTab?.isBlank == true
        let targetDropIdx = isDragging && !isMarkedForDeletion ? targetDropIndex(for: currentDragLocation.x) : nil
        
        let isPanelOpen = (controller.panel?.isVisible == true)
        
        // A. Draw stationary web tabs
        for (index, tab) in webTabs.enumerated() {
            if isDragging && index == draggedTabIndex {
                continue
            }
            
            var visualIndex = CGFloat(index)
            if let draggedIdx = draggedTabIndex, let targetIdx = targetDropIdx {
                if draggedIdx < targetIdx && index > draggedIdx && index <= targetIdx {
                    visualIndex -= 1.0
                } else if draggedIdx > targetIdx && index >= targetIdx && index < draggedIdx {
                    visualIndex += 1.0
                }
            }
            
            let itemX = startX + (visualIndex * (itemWidth + itemSpacing))
            let tabRect = NSRect(
                x: itemX,
                y: midY - (itemHeight / 2.0),
                width: itemWidth,
                height: itemHeight
            )
            let isSelected = isPanelOpen && (tab.id == selectedTabId) && !isBlankActive
            let isHovered = (hoveredIndex == index && !isDragging)
            
            // 1. Draw Apple Liquid Glass Square Highlight behind active/hovered tab
            if isSelected || isHovered {
                drawLiquidGlassPill(in: tabRect, isSelected: isSelected, ctx: ctx)
            }
            
            // 2. Draw clean prominent white squircle tab icon
            let tabKey = tab.id.uuidString + "_" + tab.urlString + "_" + (tab.faviconUrl ?? "")
            let iconRect = NSRect(
                x: tabRect.midX - (iconSize / 2.0),
                y: midY - (iconSize / 2.0),
                width: iconSize,
                height: iconSize
            )
            
            let alpha: CGFloat = isSelected ? 1.0 : (isHovered ? 0.92 : 0.65)
            ctx.saveGState()
            ctx.setAlpha(alpha)
            drawTabIcon(for: tab, key: tabKey, in: iconRect)
            ctx.restoreGState()
            
            // Draw subtle active dot indicator under the selected tab icon
            if isSelected {
                let dotRadius: CGFloat = 1.75
                let dotCenter = CGPoint(x: tabRect.midX, y: 1.8)
                ctx.addEllipse(in: CGRect(x: dotCenter.x - dotRadius, y: dotCenter.y - dotRadius, width: dotRadius * 2, height: dotRadius * 2))
                ctx.setFillColor(NSColor.white.withAlphaComponent(0.95).cgColor)
                ctx.fillPath()
            }
            
            // Draw Red Notification Dot Badge if tab has unread messages/notifications
            if tab.hasUnread {
                drawRedNotificationDot(in: iconRect, ctx: ctx)
            }
        }
        
        // B. Draw permanent [+] Squircle Button at the end of the capsule
        let plusIndex = webTabs.count
        let plusItemX = startX + (CGFloat(plusIndex) * (itemWidth + itemSpacing))
        let plusTabRect = NSRect(
            x: plusItemX,
            y: midY - (itemHeight / 2.0),
            width: itemWidth,
            height: itemHeight
        )
        let isPlusSelected = isPanelOpen && isBlankActive
        let isPlusHovered = (hoveredIndex == plusIndex && !isDragging)
        
        if isPlusSelected || isPlusHovered {
            drawLiquidGlassPill(in: plusTabRect, isSelected: isPlusSelected, ctx: ctx)
        }
        
        let plusIconRect = NSRect(
            x: plusTabRect.midX - (iconSize / 2.0),
            y: midY - (iconSize / 2.0),
            width: iconSize,
            height: iconSize
        )
        
        let plusAlpha: CGFloat = isPlusSelected ? 1.0 : (isPlusHovered ? 0.92 : 0.70)
        ctx.saveGState()
        ctx.setAlpha(plusAlpha)
        if let cachedPlus = tabWebIcons["__permanent_plus_squircle__"] {
            cachedPlus.draw(in: plusIconRect)
        } else {
            let blankTabDummy = TabItem(title: "New Tab", urlString: "")
            FaviconManager.shared.getDirectWebIcon(for: blankTabDummy, size: NSSize(width: 48, height: 48)) { [weak self] img in
                self?.tabWebIcons["__permanent_plus_squircle__"] = img
                self?.needsDisplay = true
            }
        }
        ctx.restoreGState()
        
        if isPlusSelected {
            let dotRadius: CGFloat = 1.75
            let dotCenter = CGPoint(x: plusTabRect.midX, y: 1.8)
            ctx.addEllipse(in: CGRect(x: dotCenter.x - dotRadius, y: dotCenter.y - dotRadius, width: dotRadius * 2, height: dotRadius * 2))
            ctx.setFillColor(NSColor.white.withAlphaComponent(0.95).cgColor)
            ctx.fillPath()
        }
        
        // C. Draw Floating Dragged Tab
        if isDragging, let dragIdx = draggedTabIndex, dragIdx < webTabs.count {
            let tab = webTabs[dragIdx]
            let floatX = currentDragLocation.x - (itemWidth / 2.0)
            let floatY = currentDragLocation.y - (itemHeight / 2.0)
            let floatRect = NSRect(x: floatX, y: floatY, width: itemWidth, height: itemHeight)
            
            if isMarkedForDeletion {
                let deletePath = CGPath(roundedRect: floatRect.insetBy(dx: -1.5, dy: -1.5), cornerWidth: 5.5, cornerHeight: 5.5, transform: nil)
                ctx.addPath(deletePath)
                ctx.setFillColor(NSColor.systemRed.withAlphaComponent(0.75).cgColor)
                ctx.fillPath()
                
                let xConfig = NSImage.SymbolConfiguration(pointSize: 13.0, weight: .bold)
                if let xImg = NSImage(systemSymbolName: "xmark", accessibilityDescription: "Delete")?.withSymbolConfiguration(xConfig) {
                    let xRect = NSRect(x: floatRect.midX - 6.5, y: floatRect.midY - 6.5, width: 13.0, height: 13.0)
                    xImg.draw(in: xRect)
                }
            } else {
                drawLiquidGlassPill(in: floatRect, isSelected: true, ctx: ctx)
                
                let tabKey = tab.id.uuidString + "_" + tab.urlString + "_" + (tab.faviconUrl ?? "")
                let iconRect = NSRect(
                    x: floatRect.midX - (iconSize / 2.0),
                    y: floatRect.midY - (iconSize / 2.0),
                    width: iconSize,
                    height: iconSize
                )
                drawTabIcon(for: tab, key: tabKey, in: iconRect)
                
                if tab.hasUnread {
                    drawRedNotificationDot(in: iconRect, ctx: ctx)
                }
            }
        }
    }
    
    /// Draws Apple's signature prominent Liquid Glass Bubble tile (Bong bóng kính lỏng 3D)
    private func drawLiquidGlassPill(in rect: NSRect, isSelected: Bool, ctx: CGContext) {
        let tileSide: CGFloat = 22.0
        let tileRect = NSRect(
            x: rect.midX - (tileSide / 2.0),
            y: rect.midY - (tileSide / 2.0),
            width: tileSide,
            height: tileSide
        )
        let tileRadius: CGFloat = 6.0
        let tilePath = CGPath(roundedRect: tileRect, cornerWidth: tileRadius, cornerHeight: tileRadius, transform: nil)
        
        ctx.saveGState()
        
        if isSelected {
            // 1. Soft Ambient Bubble Floating Shadow (Tạo độ nổi cho bong bóng)
            ctx.saveGState()
            ctx.setShadow(offset: CGSize(width: 0, height: -1.0), blur: 3.5, color: NSColor.black.withAlphaComponent(0.35).cgColor)
            ctx.addPath(tilePath)
            ctx.setFillColor(NSColor.white.withAlphaComponent(0.18).cgColor)
            ctx.fillPath()
            ctx.restoreGState()
            
            // 2. Rich Liquid Glass Frosted Core Fill (Nền kính lỏng đậm nét)
            ctx.addPath(tilePath)
            ctx.setFillColor(NSColor.white.withAlphaComponent(0.28).cgColor)
            ctx.fillPath()
            
            // 3. Specular Bubble Top Gloss Highlight (Vệt sáng bóng khúc xạ của bong bóng thủy tinh)
            let colors = [
                NSColor.white.withAlphaComponent(0.55).cgColor,
                NSColor.white.withAlphaComponent(0.22).cgColor,
                NSColor.white.withAlphaComponent(0.04).cgColor
            ] as CFArray
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 0.45, 1.0]) {
                ctx.saveGState()
                ctx.addPath(tilePath)
                ctx.clip()
                ctx.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: tileRect.midX, y: tileRect.maxY),
                    end: CGPoint(x: tileRect.midX, y: tileRect.minY),
                    options: []
                )
                ctx.restoreGState()
            }
            
            // 4. Luminous Liquid Glass Bubble Rim (Viền sáng phản quang bóng bẩy)
            ctx.addPath(tilePath)
            ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.60).cgColor)
            ctx.setLineWidth(0.85)
            ctx.strokePath()
            
            // 5. Subtle Inner Bottom Ambient Glow
            let bottomGlowRect = CGRect(x: tileRect.minX + 3.0, y: tileRect.minY + 1.2, width: tileRect.width - 6.0, height: 1.0)
            ctx.addEllipse(in: bottomGlowRect)
            ctx.setFillColor(NSColor.white.withAlphaComponent(0.40).cgColor)
            ctx.fillPath()
        } else {
            // Subtle Hover Glass Square Tile
            ctx.addPath(tilePath)
            ctx.setFillColor(NSColor.white.withAlphaComponent(0.12).cgColor)
            ctx.fillPath()
            
            ctx.addPath(tilePath)
            ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.22).cgColor)
            ctx.setLineWidth(0.6)
            ctx.strokePath()
        }
        
        ctx.restoreGState()
    }
    
    private func drawRedNotificationDot(in iconRect: NSRect, ctx: CGContext) {
        let dotRadius: CGFloat = 3.0
        let dotCenter = CGPoint(x: iconRect.maxX - 1.0, y: iconRect.maxY - 1.0)
        let dotRect = CGRect(
            x: dotCenter.x - dotRadius,
            y: dotCenter.y - dotRadius,
            width: dotRadius * 2,
            height: dotRadius * 2
        )
        
        ctx.saveGState()
        // Subtle outline for contrast against any menu bar wallpaper
        ctx.addEllipse(in: dotRect.insetBy(dx: -0.75, dy: -0.75))
        ctx.setFillColor(NSColor.black.withAlphaComponent(0.5).cgColor)
        ctx.fillPath()
        
        // Vibrant Apple Red Badge
        ctx.addEllipse(in: dotRect)
        ctx.setFillColor(NSColor(red: 1.0, green: 0.231, blue: 0.188, alpha: 1.0).cgColor)
        ctx.fillPath()
        ctx.restoreGState()
    }
    
    private func drawTabIcon(for tab: TabItem, key: String, in iconRect: NSRect) {
        if let cachedIcon = tabWebIcons[key] {
            cachedIcon.draw(in: iconRect)
        } else {
            FaviconManager.shared.getDirectWebIcon(for: tab) { [weak self] downloadedIcon in
                self?.tabWebIcons[key] = downloadedIcon
                self?.needsDisplay = true
            }
            
            if let symbol = tab.customIcon, let img = NSImage(systemSymbolName: symbol, accessibilityDescription: nil) {
                img.draw(in: iconRect)
            } else if tab.isBlank, let img = NSImage(systemSymbolName: "sparkles", accessibilityDescription: nil) {
                img.draw(in: iconRect)
            } else if let img = NSImage(systemSymbolName: "globe", accessibilityDescription: nil) {
                img.draw(in: iconRect)
            }
        }
    }
    
    // MARK: - Drag & Drop Mouse Event Handling
    
    override public func mouseDown(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)
        mouseDownLocation = loc
        dragCandidateIndex = hitIndex(for: loc)
        isDragging = false
        draggedTabIndex = nil
        isMarkedForDeletion = false
    }
    
    override public func mouseDragged(with event: NSEvent) {
        guard let candidate = dragCandidateIndex, candidate >= 0 else { return }
        let loc = convert(event.locationInWindow, from: nil)
        currentDragLocation = loc
        
        let dx = loc.x - mouseDownLocation.x
        let dy = loc.y - mouseDownLocation.y
        let distance = hypot(dx, dy)
        
        if !isDragging && distance > 4.0 {
            isDragging = true
            draggedTabIndex = candidate
            NSCursor.closedHand.push()
        }
        
        if isDragging {
            isMarkedForDeletion = isOutsideCapsule(loc)
            needsDisplay = true
        }
    }
    
    override public func mouseUp(with event: NSEvent) {
        guard let controller = controller else { return }
        let loc = convert(event.locationInWindow, from: nil)
        
        if isDragging {
            NSCursor.pop()
            if isMarkedForDeletion || isOutsideCapsule(loc) {
                if let dragIdx = draggedTabIndex, dragIdx < controller.appState.tabs.count {
                    let tabToDelete = controller.appState.tabs[dragIdx]
                    NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
                    controller.appState.closeTab(id: tabToDelete.id)
                }
            } else {
                if let sourceIdx = draggedTabIndex {
                    let destIdx = targetDropIndex(for: loc.x)
                    if sourceIdx != destIdx {
                        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
                        controller.appState.moveTab(from: sourceIdx, to: destIdx)
                    }
                }
            }
            
            isDragging = false
            draggedTabIndex = nil
            dragCandidateIndex = nil
            isMarkedForDeletion = false
            needsDisplay = true
            return
        }
        
        let clickedTarget = hitIndex(for: loc)
        let webTabs = controller.appState.tabs.filter { !$0.isBlank }
        
        if let index = clickedTarget {
            if index < webTabs.count {
                // Clicked an existing web tab
                let tab = webTabs[index]
                if controller.panel?.isVisible == true && controller.appState.selectedTabId == tab.id && controller.appState.activeTab?.isBlank == false {
                    controller.hidePanel()
                } else {
                    controller.appState.selectTab(id: tab.id)
                    controller.showPanel(for: tab.id)
                }
            } else if index == webTabs.count {
                // Clicked the permanent [+] New Tab button at the end!
                if controller.panel?.isVisible == true && controller.appState.activeTab?.isBlank == true {
                    controller.hidePanel()
                } else if let blankTab = controller.appState.tabs.first(where: { $0.isBlank }) {
                    controller.appState.selectTab(id: blankTab.id)
                    if controller.panel?.isVisible != true {
                        controller.showPanel(for: blankTab.id)
                    }
                } else {
                    controller.appState.addNewTab()
                    controller.showPanel(for: controller.appState.selectedTabId)
                }
            }
        }
        
        dragCandidateIndex = nil
        isDragging = false
        needsDisplay = true
    }
    
    override public func rightMouseDown(with event: NSEvent) {
        guard let controller = controller else { return }
        let loc = convert(event.locationInWindow, from: nil)
        let clickedTarget = hitIndex(for: loc)
        let webTabs = controller.appState.tabs.filter { !$0.isBlank }
        
        let targetTabId: UUID
        if let index = clickedTarget, index >= 0 && index < webTabs.count {
            targetTabId = webTabs[index].id
        } else {
            targetTabId = controller.appState.selectedTabId
        }
        controller.showContextMenu(for: targetTabId, event: event)
    }
    
    override public func mouseMoved(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)
        let newHover = hitIndex(for: loc)
        if newHover != hoveredIndex {
            hoveredIndex = newHover
            needsDisplay = true
        }
    }
    
    override public func mouseExited(with event: NSEvent) {
        hoveredIndex = nil
        needsDisplay = true
    }
    
    // MARK: - Geometry & Hit-Testing Helpers
    
    private func targetDropIndex(for locX: CGFloat) -> Int {
        guard let controller = controller else { return 0 }
        let webTabs = controller.appState.tabs.filter { !$0.isBlank }
        let tabsCount = webTabs.count
        guard tabsCount > 0 else { return 0 }
        
        let startX = capsulePaddingH
        let relativeX = locX - startX
        let totalPerItem = itemWidth + itemSpacing
        let calculated = Int(round(relativeX / totalPerItem))
        return max(0, min(tabsCount - 1, calculated))
    }
    
    private func isOutsideCapsule(_ loc: NSPoint) -> Bool {
        let dragAllowance = NSRect(x: -15, y: -16, width: bounds.width + 30, height: bounds.height + 28)
        return !dragAllowance.contains(loc)
    }
    
    private func hitIndex(for loc: NSPoint) -> Int? {
        guard let controller = controller else { return nil }
        let startX = capsulePaddingH
        let webTabs = controller.appState.tabs.filter { !$0.isBlank }
        let totalCount = webTabs.count + 1
        for i in 0..<totalCount {
            let tabRect = NSRect(
                x: startX + (CGFloat(i) * (itemWidth + itemSpacing)),
                y: 0,
                width: itemWidth + itemSpacing,
                height: bounds.height
            )
            if tabRect.contains(loc) {
                return i
            }
        }
        return nil
    }
}
