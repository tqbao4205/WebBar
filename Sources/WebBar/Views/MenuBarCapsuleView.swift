import SwiftUI
import AppKit

public struct MenuBarCapsuleView: View {
    @ObservedObject var appState: AppState
    let onTabClick: (UUID) -> Void
    let onAddTab: () -> Void
    let onRightClick: (UUID, NSEvent) -> Void
    
    @State private var hoveredTabId: UUID?
    @State private var isPlusHovered: Bool = false
    
    public init(
        appState: AppState,
        onTabClick: @escaping (UUID) -> Void,
        onAddTab: @escaping () -> Void,
        onRightClick: @escaping (UUID, NSEvent) -> Void
    ) {
        self.appState = appState
        self.onTabClick = onTabClick
        self.onAddTab = onAddTab
        self.onRightClick = onRightClick
    }
    
    public var body: some View {
        HStack(spacing: 5) {
            // 1. "+" Button to add a new tab directly from the Menu Bar
            Button(action: onAddTab) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(isPlusHovered ? .white : .white.opacity(0.9))
                    .frame(width: 19, height: 19)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(isPlusHovered ? Color.white.opacity(0.25) : Color.clear)
                    )
            }
            .buttonStyle(.plain)
            .help("New Tab (⌘T)")
            .onHover { isPlusHovered = $0 }
            
            // Subtle vertical separator
            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 1, height: 13)
            
            // 2. Open Tab Icons with individual active highlights
            ForEach(appState.tabs) { tab in
                let isSelected = (tab.id == appState.selectedTabId)
                let isHovered = (hoveredTabId == tab.id)
                
                MenuBarTabButton(
                    tab: tab,
                    isSelected: isSelected,
                    isHovered: isHovered,
                    onClick: { onTabClick(tab.id) },
                    onRightClick: { event in onRightClick(tab.id, event) }
                )
                .onHover { hovering in
                    hoveredTabId = hovering ? tab.id : nil
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2.5)
        .background(
            RoundedRectangle(cornerRadius: 6.5)
                .fill(Color.black.opacity(0.2))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6.5)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.8),
                            Color.white.opacity(0.5),
                            Color.white.opacity(0.35)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1.2
                )
        )
        .padding(.horizontal, 3)
    }
}

private struct MenuBarTabButton: View {
    let tab: TabItem
    let isSelected: Bool
    let isHovered: Bool
    let onClick: () -> Void
    let onRightClick: (NSEvent) -> Void
    
    var body: some View {
        RightClickableRepresentable(
            onClick: onClick,
            onRightClick: onRightClick
        ) {
            ZStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: 4.5)
                        .fill(Color.white.opacity(0.28))
                        .frame(width: 21, height: 21)
                } else if isHovered {
                    RoundedRectangle(cornerRadius: 4.5)
                        .fill(Color.white.opacity(0.14))
                        .frame(width: 21, height: 21)
                }
                
                TabIconView(tab: tab, size: 17)
            }
            .frame(width: 21, height: 21)
        }
        .frame(width: 21, height: 21)
        .help(tab.isBlank ? "AI Launcher" : tab.title)
    }
}

private struct RightClickableRepresentable<Content: View>: NSViewRepresentable {
    let onClick: () -> Void
    let onRightClick: (NSEvent) -> Void
    let content: () -> Content
    
    func makeNSView(context: Context) -> RightClickHostingView<Content> {
        let view = RightClickHostingView(rootView: content())
        view.onClick = onClick
        view.onRightClick = onRightClick
        return view
    }
    
    func updateNSView(_ nsView: RightClickHostingView<Content>, context: Context) {
        nsView.rootView = content()
        nsView.onClick = onClick
        nsView.onRightClick = onRightClick
    }
}

private class RightClickHostingView<Content: View>: NSHostingView<Content> {
    var onClick: (() -> Void)?
    var onRightClick: ((NSEvent) -> Void)?
    
    override func mouseUp(with event: NSEvent) {
        onClick?()
    }
    
    override func rightMouseUp(with event: NSEvent) {
        onRightClick?(event)
    }
}
