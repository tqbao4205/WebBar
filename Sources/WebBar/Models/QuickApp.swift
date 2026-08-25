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
        defaultViewport: ViewportMode = .iphonePro,
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
    
    public static let presets: [QuickApp] = [
        // AI Assistants
        QuickApp(
            id: "chatgpt",
            name: "ChatGPT",
            urlString: "https://chatgpt.com",
            category: .ai,
            iconSymbol: "bubble.left.and.sparkles.fill",
            colorHex: "#10A37F",
            defaultViewport: .iphonePro,
            description: "OpenAI conversational AI model"
        ),
        QuickApp(
            id: "claude",
            name: "Claude",
            urlString: "https://claude.ai",
            category: .ai,
            iconSymbol: "brain.head.profile",
            colorHex: "#D97706",
            defaultViewport: .iphonePro,
            description: "Anthropic helpful and harmless AI"
        ),
        QuickApp(
            id: "gemini",
            name: "Gemini",
            urlString: "https://gemini.google.com",
            category: .ai,
            iconSymbol: "sparkles",
            colorHex: "#3B82F6",
            defaultViewport: .iphonePro,
            description: "Google multimodal AI assistant"
        ),
        QuickApp(
            id: "perplexity",
            name: "Perplexity",
            urlString: "https://www.perplexity.ai",
            category: .ai,
            iconSymbol: "magnifyingglass.circle.fill",
            colorHex: "#0D9488",
            defaultViewport: .iphonePro,
            description: "AI-powered answer engine & search"
        ),
        QuickApp(
            id: "deepseek",
            name: "DeepSeek",
            urlString: "https://chat.deepseek.com",
            category: .ai,
            iconSymbol: "atom",
            colorHex: "#4F46E5",
            defaultViewport: .iphonePro,
            description: "DeepSeek high-performance coding AI"
        ),
        
        // Productivity & Dev
        QuickApp(
            id: "translate",
            name: "Google Translate",
            urlString: "https://translate.google.com",
            category: .tools,
            iconSymbol: "character.book.closed.fill",
            colorHex: "#2563EB",
            defaultViewport: .iphoneSE,
            description: "Real-time multilingual translation"
        ),
        QuickApp(
            id: "github",
            name: "GitHub",
            urlString: "https://github.com",
            category: .tools,
            iconSymbol: "chevron.left.forwardslash.chevron.right",
            colorHex: "#24292F",
            defaultViewport: .iphonePro,
            description: "Code repositories and pull requests"
        ),
        QuickApp(
            id: "notion",
            name: "Notion",
            urlString: "https://www.notion.so",
            category: .tools,
            iconSymbol: "doc.text.fill",
            colorHex: "#37352F",
            defaultViewport: .iphonePro,
            description: "Connected workspace for notes and docs"
        ),
        QuickApp(
            id: "calendar",
            name: "Google Calendar",
            urlString: "https://calendar.google.com",
            category: .tools,
            iconSymbol: "calendar",
            colorHex: "#0284C7",
            defaultViewport: .iphonePro,
            description: "Schedule, agenda & event tracker"
        ),
        
        // Social & Media
        QuickApp(
            id: "zalo",
            name: "Zalo Web",
            urlString: "https://chat.zalo.me",
            category: .media,
            iconSymbol: "message.fill",
            colorHex: "#0068FF",
            defaultViewport: .iphonePro,
            description: "Nhắn tin và gọi điện Zalo Web miễn phí"
        ),
        QuickApp(
            id: "messenger",
            name: "Messenger",
            urlString: "https://www.messenger.com",
            category: .media,
            iconSymbol: "bubble.left.and.bubble.right.fill",
            colorHex: "#0084FF",
            defaultViewport: .iphonePro,
            description: "Facebook Messenger trò chuyện trực tuyến"
        ),
        QuickApp(
            id: "twitter",
            name: "X (Twitter)",
            urlString: "https://x.com",
            category: .media,
            iconSymbol: "bubble.right.fill",
            colorHex: "#1DA1F2",
            defaultViewport: .iphonePro,
            description: "Real-time news and microblogging"
        ),
        QuickApp(
            id: "tiktok",
            name: "TikTok",
            urlString: "https://www.tiktok.com",
            category: .media,
            iconSymbol: "play.circle.fill",
            colorHex: "#FE2C55",
            defaultViewport: .iphonePro,
            description: "Xem video ngắn, xu hướng và âm nhạc TikTok"
        ),
        QuickApp(
            id: "youtube",
            name: "YouTube",
            urlString: "https://m.youtube.com",
            category: .media,
            iconSymbol: "play.rectangle.fill",
            colorHex: "#EF4444",
            defaultViewport: .iphonePro,
            description: "Watch videos, tutorials and music"
        ),
        QuickApp(
            id: "reddit",
            name: "Reddit",
            urlString: "https://www.reddit.com",
            category: .media,
            iconSymbol: "flame.fill",
            colorHex: "#FF4500",
            defaultViewport: .iphonePro,
            description: "Online forums and discussions"
        ),
        QuickApp(
            id: "telegram",
            name: "Telegram Web",
            urlString: "https://web.telegram.org",
            category: .media,
            iconSymbol: "paperplane.fill",
            colorHex: "#0088CC",
            defaultViewport: .iphonePro,
            description: "Fast and secure cloud messaging"
        ),
        
        // Search & Knowledge
        QuickApp(
            id: "google",
            name: "Google Search",
            urlString: "https://www.google.com",
            category: .reference,
            iconSymbol: "magnifyingglass",
            colorHex: "#EA4335",
            defaultViewport: .iphoneSE,
            description: "Search the web"
        ),
        QuickApp(
            id: "wikipedia",
            name: "Wikipedia",
            urlString: "https://en.m.wikipedia.org",
            category: .reference,
            iconSymbol: "text.book.closed.fill",
            colorHex: "#6B7280",
            defaultViewport: .iphonePro,
            description: "Free online encyclopedia"
        ),
        QuickApp(
            id: "hackernews",
            name: "Hacker News",
            urlString: "https://news.ycombinator.com",
            category: .reference,
            iconSymbol: "newspaper.fill",
            colorHex: "#FF6600",
            defaultViewport: .iphoneSE,
            description: "Tech news and startup discussions"
        )
    ]
}
