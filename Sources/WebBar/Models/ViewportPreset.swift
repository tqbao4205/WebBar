import Foundation
import CoreGraphics

public enum ViewportMode: String, Codable, CaseIterable, Identifiable {
    case iphoneSE = "iPhone SE"
    case iphonePro = "iPhone 16 Pro"
    case ipadMini = "iPad Mini"
    case desktopCompact = "Desktop (Compact)"
    case desktopWide = "Desktop (Wide)"
    case custom = "Custom"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .iphoneSE:
            return "iPhone SE (375×667)"
        case .iphonePro:
            return "iPhone 16 Pro (393×750)"
        case .ipadMini:
            return "iPad Mini (744×850)"
        case .desktopCompact:
            return "Desktop Compact (800×600)"
        case .desktopWide:
            return "Desktop Wide (1050×720)"
        case .custom:
            return "Custom"
        }
    }
    
    public var size: CGSize {
        switch self {
        case .iphoneSE:
            return CGSize(width: 375, height: 667)
        case .iphonePro:
            return CGSize(width: 393, height: 750)
        case .ipadMini:
            return CGSize(width: 744, height: 850)
        case .desktopCompact:
            return CGSize(width: 800, height: 600)
        case .desktopWide:
            return CGSize(width: 1050, height: 720)
        case .custom:
            return CGSize(width: 500, height: 700)
        }
    }
    
    public var iconName: String {
        switch self {
        case .iphoneSE:
            return "iphone"
        case .iphonePro:
            return "iphone.gen3"
        case .ipadMini:
            return "ipad"
        case .desktopCompact:
            return "display"
        case .desktopWide:
            return "macwindow"
        case .custom:
            return "slider.horizontal.3"
        }
    }
    
    public var isMobile: Bool {
        switch self {
        case .iphoneSE, .iphonePro, .ipadMini:
            return true
        default:
            return false
        }
    }
    
    public var userAgent: String {
        switch self {
        case .iphoneSE, .iphonePro:
            return "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1"
        case .ipadMini:
            return "Mozilla/5.0 (iPad; CPU OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1"
        case .desktopCompact, .desktopWide, .custom:
            return "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Safari/605.1.15"
        }
    }
}
