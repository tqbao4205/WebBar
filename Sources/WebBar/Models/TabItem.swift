import Foundation
import SwiftUI

public struct TabItem: Identifiable, Codable, Hashable {
    public var id: UUID
    public var title: String
    public var urlString: String
    public var faviconUrl: String?
    public var viewport: ViewportMode
    public var customWidth: CGFloat?
    public var customHeight: CGFloat?
    public var isPinned: Bool
    public var autoRefreshSeconds: Int
    public var isAdBlockEnabled: Bool
    public var isDarkModeInjected: Bool
    public var zoomFactor: Double
    public var customIcon: String?
    public var unreadCount: Int
    
    public var hasUnread: Bool {
        return unreadCount > 0
    }
    
    // Non-codable runtime state managed separately or defaulted
    public init(
        id: UUID = UUID(),
        title: String = "New Tab",
        urlString: String = "",
        faviconUrl: String? = nil,
        viewport: ViewportMode = .iphoneSE,
        customWidth: CGFloat? = nil,
        customHeight: CGFloat? = nil,
        isPinned: Bool = false,
        autoRefreshSeconds: Int = 0,
        isAdBlockEnabled: Bool = true,
        isDarkModeInjected: Bool = false,
        zoomFactor: Double = 1.0,
        customIcon: String? = nil,
        unreadCount: Int = 0
    ) {
        self.id = id
        self.title = title
        self.urlString = urlString
        self.faviconUrl = faviconUrl
        self.viewport = viewport
        self.customWidth = customWidth
        self.customHeight = customHeight
        self.isPinned = isPinned
        self.autoRefreshSeconds = autoRefreshSeconds
        self.isAdBlockEnabled = isAdBlockEnabled
        self.isDarkModeInjected = isDarkModeInjected
        self.zoomFactor = zoomFactor
        self.customIcon = customIcon
        self.unreadCount = unreadCount
    }
    
    public var currentSize: CGSize {
        if isBlank {
            return CGSize(width: 380, height: 165)
        }
        if viewport == .custom {
            return CGSize(
                width: max(320, customWidth ?? 393),
                height: max(400, customHeight ?? 750)
            )
        }
        return viewport.size
    }
    
    public var isBlank: Bool {
        urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    public var formattedDisplayUrl: String {
        guard let url = URL(string: urlString), let host = url.host else {
            return urlString.isEmpty ? "Search or enter URL" : urlString
        }
        return host.replacingOccurrences(of: "www.", with: "")
    }
}
