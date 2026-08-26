import Foundation

// MARK: - State Persistence & Restoration
extension AppState {
    public func saveState() {
        do {
            let encoded = try JSONEncoder().encode(tabs)
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
            
            let settings: [String: Any] = [
                "isPinned": isPinned,
                "language": language.rawValue,
                "windowOpacity": windowOpacity,
                "isAdBlockEnabledGlobally": isAdBlockEnabledGlobally,
                "customWidth": customWidth,
                "customHeight": customHeight
            ]
            UserDefaults.standard.set(settings, forKey: settingsDefaultsKey)
        } catch {
            print("Failed to save AppState: \(error)")
        }
    }
    
    public func loadState() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let savedTabs = try? JSONDecoder().decode([TabItem].self, from: data),
           !savedTabs.isEmpty {
            self.tabs = savedTabs
            self.selectedTabId = savedTabs.first?.id ?? UUID()
        }
        
        if let settings = UserDefaults.standard.dictionary(forKey: settingsDefaultsKey) {
            self.isPinned = settings["isPinned"] as? Bool ?? false
            if let langRaw = settings["language"] as? String, let lang = AppLanguage(rawValue: langRaw) {
                self.language = lang
            }
            self.windowOpacity = settings["windowOpacity"] as? Double ?? 1.0
            self.isAdBlockEnabledGlobally = settings["isAdBlockEnabledGlobally"] as? Bool ?? true
            self.customWidth = settings["customWidth"] as? CGFloat ?? 393
            self.customHeight = settings["customHeight"] as? CGFloat ?? 750
        }
    }
}
