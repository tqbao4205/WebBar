import SwiftUI

public struct TabBarView: View {
    @EnvironmentObject var appState: AppState
    @State private var hoveredTabId: UUID?
    @State private var isPlusHovered: Bool = false
    
    public var body: some View {
        HStack(spacing: 6) {
            // Bordered Tabs Capsule Container
            HStack(spacing: 4) {
                // New Tab Button (+) on the left
                Button {
                    appState.addNewTab()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(isPlusHovered ? .primary : .secondary)
                        .frame(width: 24, height: 24)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .fill(isPlusHovered ? Color.primary.opacity(0.12) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
                .help("New Tab (⌘T)")
                .onHover { isPlusHovered = $0 }
                
                // Subtle separator
                Rectangle()
                    .fill(Color.primary.opacity(0.15))
                    .frame(width: 1, height: 14)
                
                // Scrollable Tab List
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(appState.tabs) { tab in
                            TabButton(
                                tab: tab,
                                isSelected: tab.id == appState.selectedTabId,
                                isHovered: hoveredTabId == tab.id,
                                canClose: appState.tabs.count > 1,
                                onSelect: {
                                    appState.selectTab(id: tab.id)
                                },
                                onClose: {
                                    appState.closeTab(id: tab.id)
                                }
                            )
                            .onHover { isHovering in
                                hoveredTabId = isHovering ? tab.id : nil
                            }
                        }
                    }
                    .padding(.horizontal, 2)
                    .padding(.vertical, 2)
                }
            }
            .padding(.horizontal, 5)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.primary.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.primary.opacity(0.18), lineWidth: 1)
            )
            .padding(.horizontal, 8)
        }
        .frame(height: 36)
        .background(Color.black.opacity(0.18))
    }
}

private struct TabButton: View {
    let tab: TabItem
    let isSelected: Bool
    let isHovered: Bool
    let canClose: Bool
    let onSelect: () -> Void
    let onClose: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            // Tab Content Button (Click anywhere to select tab)
            Button(action: onSelect) {
                HStack(spacing: 6) {
                    TabIconView(tab: tab, size: 16)
                    
                    Text(tab.isBlank ? "AI Launcher" : tab.title)
                        .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                        .lineLimit(1)
                        .foregroundColor(isSelected ? .primary : .secondary)
                        .frame(maxWidth: 130, alignment: .leading)
                }
                .padding(.leading, 6)
                .padding(.trailing, canClose ? 2 : 8)
                .padding(.vertical, 4)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            // Close Tab (x)
            if canClose && (isHovered || isSelected) {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(.secondary)
                        .frame(width: 16, height: 16)
                        .background(Color.primary.opacity(isHovered ? 0.2 : 0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .padding(.trailing, 4)
                .help("Close Tab (⌘W)")
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.primary.opacity(0.18) : (isHovered ? Color.primary.opacity(0.08) : Color.clear))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 1)
        )
    }
}
