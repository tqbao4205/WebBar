import SwiftUI
import AppKit

public struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
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
            
            // Floating Active Tab Pointer Indicator (Points up to active Menu Bar icon)
            ActiveTabPointerView()
            
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

// MARK: - Active Tab Pointer Indicator (Adaptive Vibrant Spotlight)

private struct ActiveTabPointerView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        HStack(spacing: 0) {
            Spacer()
                .frame(width: max(16, appState.arrowOffsetX - 17))
            
            // Sleek Apple Accent Spotlight & Micro-Chevron (Vivid on both Dark & Light backgrounds)
            VStack(spacing: 1.5) {
                // Minimalist micro-chevron pointing up
                Image(systemName: "chevron.compact.up")
                    .font(.system(size: 11.5, weight: .black))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.85)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color.black.opacity(0.28), radius: 2, y: 1)
                
                // Luminous accent light bar along the top edge
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.accentColor.opacity(0.12),
                                Color.accentColor,
                                Color.accentColor.opacity(0.12)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 34, height: 2.6)
                    .shadow(color: Color.accentColor.opacity(0.45), radius: 3, y: 0)
                    .shadow(color: Color.black.opacity(0.25), radius: 1.5, y: 0.5)
            }
            .frame(width: 34)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 1)
        .animation(.spring(response: 0.32, dampingFraction: 0.8), value: appState.arrowOffsetX)
        .allowsHitTesting(false)
        .zIndex(450)
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
