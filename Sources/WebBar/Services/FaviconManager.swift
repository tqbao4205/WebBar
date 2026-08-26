import AppKit
import CoreGraphics

public final class FaviconManager {
    public static let shared = FaviconManager()
    
    private var cache: [String: NSImage] = [:]
    
    private init() {}
    
    /// Fetches and creates a 100% uniform rounded square (Apple Squircle) app icon with authentic website favicon
    public func getDirectWebIcon(for tab: TabItem, size: NSSize = NSSize(width: 48, height: 48), completion: @escaping (NSImage) -> Void) {
        // 1. If tab is blank (New Tab), return clean plus squircle
        if tab.isBlank {
            let icon = createBlankTabSquareIcon(size: size)
            completion(icon)
            return
        }
        
        let urlKey = tab.urlString.lowercased()
        let cacheKey = (tab.faviconUrl ?? tab.urlString) + "_authentic_favicon_white_v25_\(Int(size.width))"
        
        if let cached = cache[cacheKey] {
            completion(cached)
            return
        }
        
        // 2. Extract candidate download URLs directly from the website
        var candidateUrls: [URL] = []
        if let directFavicon = tab.faviconUrl, let url = URL(string: directFavicon) {
            candidateUrls.append(url)
        }
        if let webUrl = URL(string: tab.urlString), let host = webUrl.host, !host.isEmpty {
            if let appleTouchIcon = URL(string: "\(webUrl.scheme ?? "https")://\(host)/apple-touch-icon.png") {
                candidateUrls.append(appleTouchIcon)
            }
            if let googleFavicon = URL(string: "https://www.google.com/s2/favicons?domain=\(host)&sz=128") {
                candidateUrls.append(googleFavicon)
            }
            if let duckFavicon = URL(string: "https://icons.duckduckgo.com/ip3/\(host).ico") {
                candidateUrls.append(duckFavicon)
            }
            if let directHostFavicon = URL(string: "\(webUrl.scheme ?? "https")://\(host)/favicon.ico") {
                candidateUrls.append(directHostFavicon)
            }
        }
        
        // 3. Download website favicon and format into the pure white rounded square icon
        fetchFirstValidImage(urls: candidateUrls) { [weak self] downloadedImage in
            guard let self = self else { return }
            
            if let image = downloadedImage {
                let finalImage = self.createUniformSquareFavicon(from: image, size: size)
                self.cache[cacheKey] = finalImage
                DispatchQueue.main.async {
                    completion(finalImage)
                }
            } else {
                // Fallback only if download fails
                let fallback = self.createBrandSquareIcon(for: urlKey, size: size)
                    ?? self.createDomainInitialSquareIcon(for: tab.urlString, size: size)
                self.cache[cacheKey] = fallback
                DispatchQueue.main.async {
                    completion(fallback)
                }
            }
        }
    }
    
    // MARK: - Synchronized Pure White Brand Badges (Khối vuông nền trắng chuẩn Apple)
    
    public func createBrandSquareIcon(for urlStr: String, size: NSSize) -> NSImage? {
        let lower = urlStr.lowercased()
        
        if lower.contains("zalo.me") {
            return drawSquareBadge(symbol: "message.fill", brandHex: "#0068FF", size: size)
        } else if lower.contains("facebook.com") || lower.contains("fb.com") {
            return drawSquareBadge(symbol: "f.square.fill", brandHex: "#1877F2", size: size)
        } else if lower.contains("messenger.com") {
            return drawSquareBadge(symbol: "bubble.middle.bottom.fill", brandHex: "#0084FF", size: size)
        } else if lower.contains("youtube.com") || lower.contains("youtu.be") {
            return drawSquareBadge(symbol: "play.rectangle.fill", brandHex: "#FF0000", size: size)
        } else if lower.contains("tiktok.com") {
            return drawSquareBadge(symbol: "music.note", brandHex: "#000000", size: size)
        } else if lower.contains("chatgpt.com") || lower.contains("openai.com") {
            return drawSquareBadge(symbol: "bubble.left.and.sparkles.fill", brandHex: "#10A37F", size: size)
        } else if lower.contains("claude.ai") {
            return drawSquareBadge(symbol: "brain.head.profile", brandHex: "#D97706", size: size)
        } else if lower.contains("gemini.google.com") {
            return drawSquareBadge(symbol: "sparkles", brandHex: "#3B82F6", size: size)
        } else if lower.contains("translate.google.com") {
            return drawSquareBadge(symbol: "character.book.closed.fill", brandHex: "#1A73E8", size: size)
        } else if lower.contains("google.com") {
            return drawSquareBadge(symbol: "magnifyingglass", brandHex: "#EA4335", size: size)
        } else if lower.contains("github.com") {
            return drawSquareBadge(symbol: "chevron.left.forwardslash.chevron.right", brandHex: "#24292F", size: size)
        } else if lower.contains("x.com") || lower.contains("twitter.com") {
            return drawSquareBadge(symbol: "xmark", brandHex: "#000000", size: size)
        } else if lower.contains("notion.so") {
            return drawSquareBadge(symbol: "doc.text.fill", brandHex: "#2D2D2D", size: size)
        } else if lower.contains("telegram.org") {
            return drawSquareBadge(symbol: "paperplane.fill", brandHex: "#229ED9", size: size)
        } else if lower.contains("instagram.com") {
            return drawSquareBadge(symbol: "camera.fill", brandHex: "#E1306C", size: size)
        }
        return nil
    }
    
    private func drawSquareBadge(symbol: String, brandHex: String, size: NSSize) -> NSImage {
        let canvas = NSImage(size: size)
        canvas.lockFocus()
        
        guard let ctx = NSGraphicsContext.current?.cgContext else {
            canvas.unlockFocus()
            return canvas
        }
        
        let rect = CGRect(origin: .zero, size: CGSize(width: size.width, height: size.height))
        let cornerRadius = size.width * 0.22
        let path = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
        
        ctx.saveGState()
        ctx.addPath(path)
        ctx.clip()
        
        // 1. Pure White Background Fill
        ctx.setFillColor(NSColor.white.cgColor)
        ctx.fill(rect)
        
        // 2. Subtle micro border
        ctx.addPath(path)
        ctx.setStrokeColor(NSColor.black.withAlphaComponent(0.12).cgColor)
        ctx.setLineWidth(1.0)
        ctx.strokePath()
        
        // 3. Centered Brand Colored Logo Glyph
        let symPointSize = size.width * 0.58
        let config = NSImage.SymbolConfiguration(pointSize: symPointSize, weight: .bold)
        if let sym = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)?.withSymbolConfiguration(config) {
            let symRect = CGRect(
                x: (size.width - symPointSize) / 2.0,
                y: (size.height - symPointSize) / 2.0,
                width: symPointSize,
                height: symPointSize
            )
            
            // Draw in authentic brand color
            let brandColor = colorFromHex(brandHex)
            let tinted = sym.copy() as! NSImage
            tinted.lockFocus()
            brandColor.set()
            NSRect(origin: .zero, size: tinted.size).fill(using: .sourceAtop)
            tinted.unlockFocus()
            
            tinted.draw(in: symRect, from: .zero, operation: .sourceOver, fraction: 1.0)
        }
        
        ctx.restoreGState()
        canvas.unlockFocus()
        return canvas
    }
    
    // MARK: - Downloaded Favicon Square Formatter (Pure White Squircle)
    
    public func createUniformSquareFavicon(from image: NSImage, size: NSSize = NSSize(width: 48, height: 48)) -> NSImage {
        let canvas = NSImage(size: size)
        canvas.lockFocus()
        
        guard let ctx = NSGraphicsContext.current?.cgContext else {
            image.draw(in: NSRect(origin: .zero, size: size))
            canvas.unlockFocus()
            return canvas
        }
        
        let rect = CGRect(origin: .zero, size: CGSize(width: size.width, height: size.height))
        let cornerRadius = size.width * 0.22
        let path = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
        
        ctx.saveGState()
        ctx.addPath(path)
        ctx.clip()
        
        // 1. Pure White Background Fill
        ctx.setFillColor(NSColor.white.cgColor)
        ctx.fill(rect)
        
        // 2. Subtle micro border
        ctx.addPath(path)
        ctx.setStrokeColor(NSColor.black.withAlphaComponent(0.12).cgColor)
        ctx.setLineWidth(1.0)
        ctx.strokePath()
        
        // 3. Draw favicon centered with uniform padding on pure white
        let padding = size.width * 0.15
        let innerRect = rect.insetBy(dx: padding, dy: padding)
        
        let imgSize = image.size
        if imgSize.width > 0 && imgSize.height > 0 {
            let aspect = imgSize.width / imgSize.height
            var drawRect = innerRect
            if aspect > 1.0 {
                let h = innerRect.width / aspect
                drawRect = CGRect(x: innerRect.minX, y: innerRect.midY - h / 2.0, width: innerRect.width, height: h)
            } else {
                let w = innerRect.height * aspect
                drawRect = CGRect(x: innerRect.midX - w / 2.0, y: innerRect.minY, width: w, height: innerRect.height)
            }
            image.draw(in: drawRect, from: .zero, operation: .sourceOver, fraction: 1.0)
        } else {
            image.draw(in: innerRect, from: .zero, operation: .sourceOver, fraction: 1.0)
        }
        
        ctx.restoreGState()
        canvas.unlockFocus()
        return canvas
    }
    
    // MARK: - Domain Initial & Blank Fallbacks (Pure White Square)
    
    public func createDomainInitialSquareIcon(for urlStr: String, size: NSSize) -> NSImage {
        let canvas = NSImage(size: size)
        canvas.lockFocus()
        
        guard let ctx = NSGraphicsContext.current?.cgContext else {
            canvas.unlockFocus()
            return canvas
        }
        
        let rect = CGRect(origin: .zero, size: CGSize(width: size.width, height: size.height))
        let cornerRadius = size.width * 0.22
        let path = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
        
        ctx.saveGState()
        ctx.addPath(path)
        ctx.clip()
        
        // 1. Pure White Background
        ctx.setFillColor(NSColor.white.cgColor)
        ctx.fill(rect)
        
        // 2. Subtle micro border
        ctx.addPath(path)
        ctx.setStrokeColor(NSColor.black.withAlphaComponent(0.12).cgColor)
        ctx.setLineWidth(1.0)
        ctx.strokePath()
        
        // Extract first letter of domain
        let host = URL(string: urlStr)?.host ?? urlStr
        let cleanHost = host.replacingOccurrences(of: "www.", with: "")
        let initial = String(cleanHost.prefix(1)).uppercased()
        let letter = initial.isEmpty ? "W" : initial
        
        let font = NSFont.systemFont(ofSize: size.width * 0.54, weight: .bold)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor(white: 0.15, alpha: 1.0)
        ]
        let str = NSAttributedString(string: letter, attributes: attrs)
        let strSize = str.size()
        let strRect = CGRect(
            x: (size.width - strSize.width) / 2.0,
            y: (size.height - strSize.height) / 2.0,
            width: strSize.width,
            height: strSize.height
        )
        str.draw(in: strRect)
        
        ctx.restoreGState()
        canvas.unlockFocus()
        return canvas
    }
    
    private func createBlankTabSquareIcon(size: NSSize) -> NSImage {
        let canvas = NSImage(size: size)
        canvas.lockFocus()
        
        guard let ctx = NSGraphicsContext.current?.cgContext else {
            canvas.unlockFocus()
            return canvas
        }
        
        let rect = CGRect(origin: .zero, size: CGSize(width: size.width, height: size.height))
        let cornerRadius = size.width * 0.22
        let path = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
        
        ctx.saveGState()
        ctx.addPath(path)
        ctx.clip()
        
        // 1. Pristine White Background
        ctx.setFillColor(NSColor(white: 0.98, alpha: 1.0).cgColor)
        ctx.fill(rect)
        
        // 2. Subtle Soft Border
        ctx.addPath(path)
        ctx.setStrokeColor(NSColor.black.withAlphaComponent(0.12).cgColor)
        ctx.setLineWidth(1.0)
        ctx.strokePath()
        
        // 3. Crisp Centered Soft Neutral Grey Plus Symbol
        let symPointSize = size.width * 0.48
        let config = NSImage.SymbolConfiguration(pointSize: symPointSize, weight: .medium)
        if let sym = NSImage(systemSymbolName: "plus", accessibilityDescription: nil)?.withSymbolConfiguration(config) {
            let symRect = CGRect(
                x: (size.width - symPointSize) / 2.0,
                y: (size.height - symPointSize) / 2.0,
                width: symPointSize,
                height: symPointSize
            )
            let tinted = sym.copy() as! NSImage
            tinted.lockFocus()
            NSColor(white: 0.48, alpha: 1.0).set()
            NSRect(origin: .zero, size: tinted.size).fill(using: .sourceAtop)
            tinted.unlockFocus()
            
            tinted.draw(in: symRect, from: .zero, operation: .sourceOver, fraction: 1.0)
        }
        
        ctx.restoreGState()
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
    
    private func colorFromHex(_ hex: String) -> NSColor {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0
        return NSColor(red: r, green: g, blue: b, alpha: 1.0)
    }
}
