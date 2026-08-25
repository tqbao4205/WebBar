import Foundation
import ServiceManagement
import AppKit

public final class LaunchAtLoginManager {
    public static let shared = LaunchAtLoginManager()
    
    private let launchAgentLabel = "com.webbar.app"
    private var launchAgentPlistPath: URL {
        let libraryDir = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
        return libraryDir.appendingPathComponent("LaunchAgents").appendingPathComponent("\(launchAgentLabel).plist")
    }
    
    private init() {}
    
    public var isEnabled: Bool {
        if #available(macOS 13.0, *) {
            if SMAppService.mainApp.status == .enabled {
                return true
            }
        }
        return FileManager.default.fileExists(atPath: launchAgentPlistPath.path)
    }
    
    public func setEnabled(_ enable: Bool) {
        // Try native macOS 13+ SMAppService first
        if #available(macOS 13.0, *) {
            do {
                if enable {
                    if SMAppService.mainApp.status != .enabled {
                        try SMAppService.mainApp.register()
                    }
                } else {
                    if SMAppService.mainApp.status == .enabled {
                        try SMAppService.mainApp.unregister()
                    }
                }
            } catch {
                print("SMAppService registration note: \(error)")
            }
        }
        
        // Also manage LaunchAgent plist for 100% reliable startup
        if enable {
            installLaunchAgent()
        } else {
            removeLaunchAgent()
        }
    }
    
    private func installLaunchAgent() {
        let appBundlePath = Bundle.main.bundlePath
        let plistContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>\(launchAgentLabel)</string>
            <key>ProgramArguments</key>
            <array>
                <string>/usr/bin/open</string>
                <string>\(appBundlePath)</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
            <key>ProcessType</key>
            <string>Interactive</string>
        </dict>
        </plist>
        """
        
        do {
            let launchAgentsDir = launchAgentPlistPath.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: launchAgentsDir, withIntermediateDirectories: true)
            try plistContent.write(to: launchAgentPlistPath, atomically: true, encoding: .utf8)
        } catch {
            print("Failed to write LaunchAgent plist: \(error)")
        }
    }
    
    private func removeLaunchAgent() {
        if FileManager.default.fileExists(atPath: launchAgentPlistPath.path) {
            try? FileManager.default.removeItem(at: launchAgentPlistPath)
        }
    }
}
