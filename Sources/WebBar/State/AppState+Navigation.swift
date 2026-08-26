import Foundation
import SwiftUI

// MARK: - Navigation, URL Normalization & Validation
extension AppState {
    public func validateAndFormatURL(input: String) -> String? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        
        let lower = trimmed.lowercased()
        
        // Recognized web services & popular shortcuts
        switch lower {
        case "zalo", "zalo.me", "chat.zalo.me":
            return "https://chat.zalo.me"
        case "google", "gg", "google.com":
            return "https://www.google.com"
        case "tiktok", "tiktok.com":
            return "https://www.tiktok.com/explore"
        case "fb", "facebook", "facebook.com":
            return "https://www.facebook.com"
        case "messenger", "messenger.com":
            return "https://www.messenger.com"
        case "youtube", "yt", "youtube.com":
            return "https://www.youtube.com"
        case "chatgpt", "gpt":
            return "https://chatgpt.com"
        case "gemini":
            return "https://gemini.google.com"
        case "claude":
            return "https://claude.ai"
        case "github", "github.com":
            return "https://github.com"
        case "notion", "notion.so":
            return "https://notion.so"
        case "telegram", "telegram.org":
            return "https://web.telegram.org"
        case "instagram", "instagram.com":
            return "https://www.instagram.com"
        default:
            break
        }
        
        // Complete URL with explicit http/https scheme
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            if let url = URL(string: trimmed), let host = url.host, !host.isEmpty, !host.contains(" ") {
                return trimmed
            }
            return nil
        }
        
        // Domain with TLD (e.g. "domain.com", "sub.domain.vn/path", "localhost:3000")
        if !trimmed.contains(" ") && (trimmed.contains(".") || trimmed.hasPrefix("localhost")) {
            let candidate = "https://" + trimmed
            if let url = URL(string: candidate), let host = url.host, !host.isEmpty, (host.contains(".") || host == "localhost") {
                return candidate
            }
        }
        
        return nil
    }
    
    public func navigateTo(input: String) {
        let cleanInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanInput.isEmpty else { return }
        
        guard let destinationUrl = validateAndFormatURL(input: cleanInput) else {
            let isVI = language == .vietnamese
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                self.urlErrorMessage = isVI ? "Liên kết không hợp lệ (ví dụ: google.com)" : "Invalid URL (e.g. google.com)"
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) { [weak self] in
                withAnimation {
                    self?.urlErrorMessage = nil
                }
            }
            return
        }
        
        self.urlErrorMessage = nil
        
        guard let index = tabs.firstIndex(where: { $0.id == selectedTabId }) else { return }
        tabs[index].urlString = destinationUrl
        tabs[index].title = cleanInput
        tabs[index].viewport = .iphoneSE
        
        urlInputText = destinationUrl
        navigationTrigger = UUID()
        saveState()
        
        DispatchQueue.main.async {
            MenuBarController.shared.syncStatusItems()
            MenuBarController.shared.updatePanelFrame(animated: true)
        }
    }
    
    public func loadQuickApp(_ app: QuickApp) {
        if let active = activeTab, active.isBlank {
            guard let index = tabs.firstIndex(where: { $0.id == active.id }) else { return }
            tabs[index].title = app.name
            tabs[index].urlString = app.urlString
            tabs[index].viewport = app.defaultViewport
            tabs[index].customIcon = app.iconSymbol
            urlInputText = app.urlString
        } else {
            let newTab = TabItem(
                title: app.name,
                urlString: app.urlString,
                viewport: app.defaultViewport,
                customIcon: app.iconSymbol
            )
            tabs.append(newTab)
            selectedTabId = newTab.id
            urlInputText = app.urlString
        }
        navigationTrigger = UUID()
        saveState()
        DispatchQueue.main.async {
            MenuBarController.shared.syncStatusItems()
            MenuBarController.shared.updatePanelFrame()
        }
    }
    
    public func reportNavigationFailed(for tabId: UUID, failedUrl: String, error: Error) {
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
            return
        }
        
        guard let index = tabs.firstIndex(where: { $0.id == tabId }) else { return }
        
        tabs[index].urlString = ""
        tabs[index].title = "New Tab"
        urlInputText = failedUrl
        
        let isVI = language == .vietnamese
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            self.urlErrorMessage = isVI ? "Không thể tải trang web" : "Failed to load website"
        }
        
        saveState()
        DispatchQueue.main.async {
            MenuBarController.shared.syncStatusItems()
            MenuBarController.shared.updatePanelFrame()
        }
    }
}
