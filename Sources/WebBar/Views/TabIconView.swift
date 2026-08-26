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
        ZStack {
            if let icon = webIcon {
                Image(nsImage: icon)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
            } else if tab.isBlank {
                ZStack {
                    RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                        .fill(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                                .stroke(Color.black.opacity(0.12), lineWidth: 0.75)
                        )
                    Image(systemName: "plus")
                        .font(.system(size: size * 0.48, weight: .medium))
                        .foregroundColor(Color(white: 0.48))
                }
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                        .fill(Color.primary.opacity(0.12))
                    Image(systemName: "globe")
                        .font(.system(size: size * 0.52, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
        )
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
        FaviconManager.shared.getDirectWebIcon(for: tab, size: NSSize(width: size * 2.0, height: size * 2.0)) { image in
            self.webIcon = image
        }
    }
}
