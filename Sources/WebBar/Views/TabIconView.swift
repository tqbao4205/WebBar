import SwiftUI
import AppKit

public struct TabIconView: View {
    let tab: TabItem
    let size: CGFloat
    @State private var webIcon: NSImage?
    
    public init(tab: TabItem, size: CGFloat = 18) {
        self.tab = tab
        self.size = size
    }
    
    public var body: some View {
        Group {
            if let icon = webIcon {
                Image(nsImage: icon)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
            } else if tab.isBlank {
                Image(systemName: "sparkles")
                    .font(.system(size: size * 0.55, weight: .bold))
                    .foregroundColor(.accentColor)
            } else if let symbol = tab.customIcon {
                Image(systemName: symbol)
                    .font(.system(size: size * 0.55, weight: .semibold))
                    .foregroundColor(.primary)
            } else {
                Image(systemName: "globe")
                    .font(.system(size: size * 0.55, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22))
        .overlay(alignment: .topTrailing) {
            if tab.hasUnread {
                Circle()
                    .fill(Color.red)
                    .frame(width: 6.5, height: 6.5)
                    .overlay(Circle().stroke(Color.black.opacity(0.35), lineWidth: 0.75))
                    .offset(x: 2, y: -2)
            }
        }
        .onAppear {
            loadIcon()
        }
        .onChange(of: tab.faviconUrl) { _ in
            loadIcon()
        }
        .onChange(of: tab.urlString) { _ in
            loadIcon()
        }
    }
    
    private func loadIcon() {
        FaviconManager.shared.getDirectWebIcon(for: tab) { image in
            self.webIcon = image
        }
    }
}
