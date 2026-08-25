import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Run as a menu bar accessory application (no dock icon clutter)
        NSApp.setActivationPolicy(.accessory)
        
        // Initialize menu bar item and windows
        MenuBarController.shared.setup()
        
        // Request macOS Notification permissions
        NotificationManager.shared.requestAuthorization()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}

@main
struct WebBarApp {
    static let delegate = AppDelegate()
    
    static func main() {
        let app = NSApplication.shared
        app.delegate = delegate
        app.run()
    }
}
