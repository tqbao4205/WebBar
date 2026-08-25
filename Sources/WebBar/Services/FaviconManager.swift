import AppKit
import CoreGraphics

public final class FaviconManager {
    public static let shared = FaviconManager()
    
    private var cache: [String: NSImage] = [:]
    
    private init() {}
    
    /// Fetches and creates a clean, frameless app icon for the macOS Menu Bar
    public func getDirectWebIcon(for tab: TabItem, asMonochrome: Bool = true, completion: @escaping (NSImage) -> Void) {
        // 1. If tab is blank (AI Launcher), return launcher sparkles symbol
        if tab.isBlank {
            completion(createSparklesIcon())
            return
        }
        
        let urlKey = tab.urlString.lowercased()
        let cacheKey = (tab.faviconUrl ?? tab.urlString) + "_frameless_clean_v5"
        
        if let cached = cache[cacheKey] {
            completion(cached)
            return
        }
        
        // 2. Instant Frameless Brand Icon for popular platforms
        if let instantBrandIcon = createWhiteBrandSquircleIcon(for: urlKey) {
            self.cache[cacheKey] = instantBrandIcon
            completion(instantBrandIcon)
        }
        
        // 3. Extract candidate download URLs directly from the website
        var candidateUrls: [URL] = []
        if let directFavicon = tab.faviconUrl, let url = URL(string: directFavicon) {
            candidateUrls.append(url)
        }
        if let webUrl = URL(string: tab.urlString), let host = webUrl.host, !host.isEmpty {
            if let googleFavicon = URL(string: "https://www.google.com/s2/favicons?domain=\(host)&sz=128") {
                candidateUrls.append(googleFavicon)
            }
            if let directHostFavicon = URL(string: "\(webUrl.scheme ?? "https")://\(host)/favicon.ico") {
                candidateUrls.append(directHostFavicon)
            }
        }
        
        // 4. Download website favicon and format cleanly without surrounding frames
        fetchFirstValidImage(urls: candidateUrls) { [weak self] downloadedImage in
            guard let self = self else { return }
            
            if let image = downloadedImage {
                let finalImage = self.createFramelessImage(image: image, size: NSSize(width: 24, height: 24))
                self.cache[cacheKey] = finalImage
                DispatchQueue.main.async {
                    completion(finalImage)
                }
            } else if self.cache[cacheKey] == nil {
                let fallback = self.createWhiteBrandSquircleIcon(for: urlKey) ?? self.createGlobeIcon()
                self.cache[cacheKey] = fallback
                DispatchQueue.main.async {
                    completion(fallback)
                }
            }
        }
    }
    
    public func createWhiteBrandSquircleIcon(for urlStr: String) -> NSImage? {
        let lower = urlStr.lowercased()
        if lower.contains("facebook.com") || lower.contains("fb.com") {
            return createFramelessSymbol(symbol: "f.square.fill")
        } else if lower.contains("zalo.me") {
            return createFramelessSymbol(symbol: "message.fill")
        } else if lower.contains("instagram.com") {
            return createFramelessSymbol(symbol: "camera.fill")
        } else if lower.contains("tiktok.com") {
            return createFramelessSymbol(symbol: "music.note")
        } else if lower.contains("chatgpt.com") || lower.contains("openai.com") {
            return createFramelessSymbol(symbol: "bubble.left.and.sparkles.fill")
        } else if lower.contains("youtube.com") || lower.contains("youtu.be") {
            return createFramelessSymbol(symbol: "play.rectangle.fill")
        } else if lower.contains("messenger.com") {
            return createFramelessSymbol(symbol: "bubble.middle.bottom.fill")
        } else if lower.contains("google.com") {
            return createFramelessSymbol(symbol: "g.circle.fill")
        } else if lower.contains("github.com") {
            return createFramelessSymbol(symbol: "chevron.left.forwardslash.chevron.right")
        } else if lower.contains("x.com") || lower.contains("twitter.com") {
            return createFramelessSymbol(symbol: "xmark.circle.fill")
        }
        return nil
    }
    
    /// Creates a crisp, frameless bold SF symbol
    private func createFramelessSymbol(symbol: String) -> NSImage {
        let config = NSImage.SymbolConfiguration(pointSize: 18.0, weight: .bold)
        if let sym = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)?.withSymbolConfiguration(config) {
            sym.isTemplate = true
            return sym
        }
        return NSImage()
    }
    
    /// Formats any downloaded web favicon cleanly without any outer box or border
    public func createFramelessImage(image: NSImage, size: NSSize = NSSize(width: 24, height: 24)) -> NSImage {
        let canvas = NSImage(size: size)
        canvas.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: size), from: .zero, operation: .sourceOver, fraction: 1.0)
        canvas.unlockFocus()
        return canvas
    }
    
    private func fetchFirstValidImage(urls: [URL], completion: @escaping (NSImage?) -> Void) {
        guard let first = urls.first else {
            completion(nil)
            return
        }
        let remaining = Array(urls.dropFirst())
        
        URLSession.shared.dataTask(with: first) { [weak self] data, _, error in
            if let data = data, let image = NSImage(data: data), image.isValid, error == nil {
                completion(image)
            } else {
                self?.fetchFirstValidImage(urls: remaining, completion: completion)
            }
        }.resume()
    }
    
    // MARK: - Fallback Icons
    
    private func createSparklesIcon() -> NSImage {
        let config = NSImage.SymbolConfiguration(pointSize: 17.0, weight: .bold)
        let img = NSImage(systemSymbolName: "sparkles.rectangle.stack", accessibilityDescription: "WebBar")?.withSymbolConfiguration(config) ?? NSImage()
        img.isTemplate = true
        return img
    }
    
    private func createGlobeIcon() -> NSImage {
        let config = NSImage.SymbolConfiguration(pointSize: 17.0, weight: .bold)
        let img = NSImage(systemSymbolName: "globe", accessibilityDescription: "Web")?.withSymbolConfiguration(config) ?? NSImage()
        img.isTemplate = true
        return img
    }
}
