import SwiftUI
import AppKit

public struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var isTopPillHovered: Bool = false
    
    private var hasNotch: Bool {
        !appState.isDetached
    }
    
    public var body: some View {
        ZStack(alignment: .top) {
            // Main Container
            VStack(spacing: 0) {
                // Top Navigation & Tab Bars (Collapsible / Hideable)
                if !appState.isTopBarHidden {
                    VStack(spacing: 0) {
                        TabBarView()
                            .zIndex(10)
                        
                        NavigationBarView()
                            .zIndex(9)
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Web Browser & AI Launcher Multi-Tab Stack (100% Edge-to-Edge)
                ZStack {
                    ForEach(appState.tabs) { tab in
                        ZStack {
                            if tab.isBlank {
                                QuickAppsGrid()
                            } else {
                                WebKitView(appState: appState, tab: tab)
                            }
                        }
                        .opacity(tab.id == appState.selectedTabId ? 1 : 0)
                        .allowsHitTesting(tab.id == appState.selectedTabId)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .zIndex(1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(appState.currentWindowBackgroundColor)
            )
            .clipShape(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .shadow(color: Color.black.opacity(0.32), radius: 20, x: 0, y: 10)
            
            // Floating Spotlight URL Bar Overlay (Triggered via ⌘L or Menu Bar icon)
            if appState.isFloatingURLBarOpen {
                FloatingSpotlightURLBar()
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(250)
            }
            
            // Settings Overlay Drawer
            if appState.isSettingsOpen {
                SettingsView()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .zIndex(200)
            }
            
            // Corner Resize Drag Handle (Bottom Right)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    WindowResizeHandle()
                        .padding(4)
                }
            }
            .zIndex(150)
            
            // Zoom Level Toast HUD
            if let zoomText = appState.zoomToastText {
                VStack {
                    Spacer()
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 11, weight: .bold))
                        Text(zoomText)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.35), radius: 10, y: 4)
                    .padding(.bottom, 24)
                    .transition(.scale(scale: 0.85).combined(with: .opacity))
                }
                .allowsHitTesting(false)
                .zIndex(300)
            }
        }
        .frame(minWidth: 320, maxWidth: .infinity, minHeight: 60, maxHeight: .infinity)
        .edgesIgnoringSafeArea(.all)
    }
}

// MARK: - Floating Spotlight URL Bar (Compact & Sleek)

private struct FloatingSpotlightURLBar: View {
    @EnvironmentObject var appState: AppState
    @FocusState private var isFieldFocused: Bool
    
    var body: some View {
        ZStack {
            // Click outside backdrop to dismiss
            Color.black.opacity(0.18)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.18)) {
                        appState.isFloatingURLBarOpen = false
                    }
                }
            
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Image(systemName: "globe")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    TextField("Nhập URL hoặc tìm kiếm Google...", text: $appState.urlInputText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13, weight: .regular))
                        .focused($isFieldFocused)
                        .onSubmit {
                            appState.navigateTo(input: appState.urlInputText)
                            withAnimation(.easeOut(duration: 0.18)) {
                                appState.isFloatingURLBarOpen = false
                            }
                        }
                    
                    if !appState.urlInputText.isEmpty {
                        Button {
                            appState.urlInputText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Button {
                        appState.navigateTo(input: appState.urlInputText)
                        withAnimation(.easeOut(duration: 0.18)) {
                            appState.isFloatingURLBarOpen = false
                        }
                    } label: {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8.5)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.35), radius: 16, y: 6)
                .padding(.horizontal, 16)
                .padding(.top, 24)
                
                Spacer()
            }
        }
        .onAppear {
            isFieldFocused = true
        }
    }
}

// MARK: - Notched Window Shape (Organic Liquid Bridge to Menu Bar)

public struct NotchedWindowShape: Shape {
    public var notchX: CGFloat
    public var cornerRadius: CGFloat = 12
    public var notchWidth: CGFloat = 20.0
    public var notchHeight: CGFloat = 13.0
    public var hasNotch: Bool = true
    
    public var animatableData: CGFloat {
        get { notchX }
        set { notchX = newValue }
    }
    
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let topY = hasNotch ? notchHeight : 0
        let r = cornerRadius
        let w = rect.width
        let h = rect.height
        
        let nHalf: CGFloat = notchWidth / 2.0
        let cx = max(r + nHalf + 4, min(w - r - nHalf - 4, notchX))
        
        // Start top left after corner
        path.move(to: CGPoint(x: r, y: topY))
        
        if hasNotch {
            // Straight line to left base fillet start
            path.addLine(to: CGPoint(x: cx - nHalf - 3.0, y: topY))
            
            // Concave fillet curve into left base of pointer
            path.addCurve(
                to: CGPoint(x: cx - nHalf + 1.8, y: topY - 3.0),
                control1: CGPoint(x: cx - nHalf, y: topY),
                control2: CGPoint(x: cx - nHalf + 0.8, y: topY - 1.2)
            )
            
            // Steep tapered slope rising to the ultra-sharp apex
            path.addCurve(
                to: CGPoint(x: cx, y: 0),
                control1: CGPoint(x: cx - 3.0, y: 4.0),
                control2: CGPoint(x: cx - 0.8, y: 0)
            )
            
            // Steep tapered slope descending from the ultra-sharp apex
            path.addCurve(
                to: CGPoint(x: cx + nHalf - 1.8, y: topY - 3.0),
                control1: CGPoint(x: cx + 0.8, y: 0),
                control2: CGPoint(x: cx + 3.0, y: 4.0)
            )
            
            // Concave fillet curve out of right base of pointer into top edge
            path.addCurve(
                to: CGPoint(x: cx + nHalf + 3.0, y: topY),
                control1: CGPoint(x: cx + nHalf - 0.8, y: topY - 1.2),
                control2: CGPoint(x: cx + nHalf, y: topY)
            )
        }
        
        // Line to top right corner
        path.addLine(to: CGPoint(x: w - r, y: topY))
        
        // Top right corner
        path.addArc(
            center: CGPoint(x: w - r, y: topY + r),
            radius: r,
            startAngle: Angle(degrees: -90),
            endAngle: Angle(degrees: 0),
            clockwise: false
        )
        
        // Right side
        path.addLine(to: CGPoint(x: w, y: h - r))
        
        // Bottom right corner
        path.addArc(
            center: CGPoint(x: w - r, y: h - r),
            radius: r,
            startAngle: Angle(degrees: 0),
            endAngle: Angle(degrees: 90),
            clockwise: false
        )
        
        // Bottom side
        path.addLine(to: CGPoint(x: r, y: h))
        
        // Bottom left corner
        path.addArc(
            center: CGPoint(x: r, y: h - r),
            radius: r,
            startAngle: Angle(degrees: 90),
            endAngle: Angle(degrees: 180),
            clockwise: false
        )
        
        // Left side
        path.addLine(to: CGPoint(x: 0, y: topY + r))
        
        // Top left corner
        path.addArc(
            center: CGPoint(x: r, y: topY + r),
            radius: r,
            startAngle: Angle(degrees: 180),
            endAngle: Angle(degrees: 270),
            clockwise: false
        )
        
        path.closeSubpath()
        return path
    }
}

// MARK: - Window Resize Handle

private struct WindowResizeHandle: View {
    @EnvironmentObject var appState: AppState
    @State private var startSize: CGSize = .zero
    @State private var isHovered: Bool = false
    
    var body: some View {
        ZStack {
            // Diagonal resize lines icon
            Path { path in
                path.move(to: CGPoint(x: 12, y: 3))
                path.addLine(to: CGPoint(x: 3, y: 12))
                
                path.move(to: CGPoint(x: 12, y: 7))
                path.addLine(to: CGPoint(x: 7, y: 12))
                
                path.move(to: CGPoint(x: 12, y: 11))
                path.addLine(to: CGPoint(x: 11, y: 12))
            }
            .stroke(
                isHovered ? Color.accentColor : Color.primary.opacity(0.3),
                style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
            )
            .frame(width: 14, height: 14)
        }
        .frame(width: 18, height: 18)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
        .gesture(
            DragGesture(minimumDistance: 1)
                .onChanged { value in
                    guard let panel = MenuBarController.shared.panel else { return }
                    if startSize == .zero {
                        startSize = panel.frame.size
                    }
                    
                    let targetWidth = max(320, min(1600, startSize.width + value.translation.width))
                    let targetHeight = max(380, min(1200, startSize.height + value.translation.height))
                    
                    var currentFrame = panel.frame
                    let heightDiff = targetHeight - currentFrame.size.height
                    
                    currentFrame.origin.y -= heightDiff
                    currentFrame.size.width = targetWidth
                    currentFrame.size.height = targetHeight
                    
                    panel.setFrame(currentFrame, display: true)
                    
                    appState.customWidth = targetWidth
                    appState.customHeight = targetHeight
                    
                    if let active = appState.activeTab, active.viewport != .custom {
                        appState.setViewport(.custom)
                    }
                }
                .onEnded { _ in
                    startSize = .zero
                }
        )
        .help("Drag to resize window")
    }
}
