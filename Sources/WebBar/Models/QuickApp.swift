import Foundation
import SwiftUI

public enum AppCategory: String, CaseIterable, Identifiable, Codable {
    case ai = "AI Assistants"
    case tools = "Productivity & Dev"
    case media = "Social & Media"
    case reference = "Search & Knowledge"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .ai: return "sparkles"
        case .tools: return "hammer.fill"
        case .media: return "bubble.left.and.bubble.right.fill"
        case .reference: return "book.fill"
        }
    }
}

public struct QuickApp: Identifiable, Codable, Hashable {
    public var id: String
    public var name: String
    public var urlString: String
    public var category: AppCategory
    public var iconSymbol: String
    public var colorHex: String
    public var defaultViewport: ViewportMode
    public var description: String
    
    public init(
        id: String,
        name: String,
        urlString: String,
        category: AppCategory,
        iconSymbol: String,
        colorHex: String,
        defaultViewport: ViewportMode = .iphoneSE,
        description: String = ""
    ) {
        self.id = id
        self.name = name
        self.urlString = urlString
        self.category = category
        self.iconSymbol = iconSymbol
        self.colorHex = colorHex
        self.defaultViewport = defaultViewport
        self.description = description
    }
    
    public static var presets: [QuickApp] {
        QuickAppPresets.catalog
    }
}
