import Foundation

public struct QuickAppPresets {
    public static let catalog: [QuickApp] = [
        // AI Assistants
        QuickApp(
            id: "chatgpt",
            name: "ChatGPT",
            urlString: "https://chatgpt.com",
            category: .ai,
            iconSymbol: "bubble.left.and.sparkles.fill",
            colorHex: "#10A37F",
            defaultViewport: .iphoneSE,
            description: "OpenAI conversational AI model"
        ),
        QuickApp(
            id: "claude",
            name: "Claude",
            urlString: "https://claude.ai",
            category: .ai,
            iconSymbol: "brain.head.profile",
            colorHex: "#D97706",
            defaultViewport: .iphoneSE,
            description: "Anthropic helpful and harmless AI"
        ),
        QuickApp(
            id: "gemini",
            name: "Gemini",
            urlString: "https://gemini.google.com",
            category: .ai,
            iconSymbol: "sparkles",
            colorHex: "#3B82F6",
            defaultViewport: .iphoneSE,
            description: "Google multimodal AI assistant"
        ),
        QuickApp(
            id: "perplexity",
            name: "Perplexity",
            urlString: "https://www.perplexity.ai",
            category: .ai,
            iconSymbol: "magnifyingglass.circle.fill",
            colorHex: "#0D9488",
            defaultViewport: .iphoneSE,
            description: "AI-powered answer engine & search"
        ),
        QuickApp(
            id: "deepseek",
            name: "DeepSeek",
            urlString: "https://chat.deepseek.com",
            category: .ai,
            iconSymbol: "atom",
            colorHex: "#4F46E5",
            defaultViewport: .iphoneSE,
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
            defaultViewport: .iphoneSE,
            description: "Code repositories and pull requests"
        ),
        QuickApp(
            id: "notion",
            name: "Notion",
            urlString: "https://www.notion.so",
            category: .tools,
            iconSymbol: "doc.text.fill",
            colorHex: "#37352F",
            defaultViewport: .iphoneSE,
            description: "Connected workspace for notes and docs"
        ),
        QuickApp(
            id: "calendar",
            name: "Google Calendar",
            urlString: "https://calendar.google.com",
            category: .tools,
            iconSymbol: "calendar",
            colorHex: "#0284C7",
            defaultViewport: .iphoneSE,
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
            defaultViewport: .iphoneSE,
            description: "Nhắn tin và gọi điện Zalo Web miễn phí"
        ),
        QuickApp(
            id: "messenger",
            name: "Messenger",
            urlString: "https://www.messenger.com",
            category: .media,
            iconSymbol: "bubble.left.and.bubble.right.fill",
            colorHex: "#0084FF",
            defaultViewport: .iphoneSE,
            description: "Facebook Messenger trò chuyện trực tuyến"
        ),
        QuickApp(
            id: "twitter",
            name: "X (Twitter)",
            urlString: "https://x.com",
            category: .media,
            iconSymbol: "bubble.right.fill",
            colorHex: "#1DA1F2",
            defaultViewport: .iphoneSE,
            description: "Real-time news and microblogging"
        ),
        QuickApp(
            id: "tiktok",
            name: "TikTok",
            urlString: "https://www.tiktok.com",
            category: .media,
            iconSymbol: "play.circle.fill",
            colorHex: "#FE2C55",
            defaultViewport: .iphoneSE,
            description: "Xem video ngắn, xu hướng và âm nhạc TikTok"
        ),
        QuickApp(
            id: "youtube",
            name: "YouTube",
            urlString: "https://m.youtube.com",
            category: .media,
            iconSymbol: "play.rectangle.fill",
            colorHex: "#EF4444",
            defaultViewport: .iphoneSE,
            description: "Watch videos, tutorials and music"
        ),
        QuickApp(
            id: "reddit",
            name: "Reddit",
            urlString: "https://www.reddit.com",
            category: .media,
            iconSymbol: "flame.fill",
            colorHex: "#FF4500",
            defaultViewport: .iphoneSE,
            description: "Online forums and discussions"
        ),
        QuickApp(
            id: "telegram",
            name: "Telegram Web",
            urlString: "https://web.telegram.org",
            category: .media,
            iconSymbol: "paperplane.fill",
            colorHex: "#0088CC",
            defaultViewport: .iphoneSE,
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
            defaultViewport: .iphoneSE,
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
