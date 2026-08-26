import SwiftUI

public struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    
    private let refreshOptions: [(String, Int)] = [
        ("Off", 0),
        ("10s", 10),
        ("30s", 30),
        ("1m", 60),
        ("5m", 300)
    ]
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Label("WebBar Settings", systemImage: "gearshape.fill")
                    .font(.system(size: 13, weight: .bold))
                
                Spacer()
                
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        appState.isSettingsOpen = false
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.primary.opacity(0.04))
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    // Window & Display Section
                    GroupBox(label: Label("Window & Display", systemImage: "macwindow")) {
                        VStack(spacing: 10) {
                            // Opacity Slider
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Window Opacity")
                                        .font(.system(size: 11))
                                    Spacer()
                                    Text("\(Int(appState.windowOpacity * 100))%")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                                Slider(value: $appState.windowOpacity, in: 0.2...1.0, step: 0.05)
                            }
                            
                            Divider()
                            
                            // Keep Window Open Toggle
                            Toggle("Keep Window Open (Ghim giữ cửa sổ)", isOn: Binding(
                                get: { appState.isPinned },
                                set: { appState.isPinned = $0 }
                            ))
                            .font(.system(size: 11))
                            
                            Divider()
                            
                            // Launch at Login Toggle
                            Toggle("Launch at Login (Tự mở khi bật máy)", isOn: Binding(
                                get: { appState.launchAtLogin },
                                set: { appState.setLaunchAtLogin($0) }
                            ))
                            .font(.system(size: 11))
                        }
                        .padding(6)
                    }
                    
                    // Custom Dimension Controls (if Custom Viewport is active)
                    if appState.activeTab?.viewport == .custom {
                        GroupBox(label: Label("Custom Dimensions", systemImage: "slider.horizontal.3")) {
                            VStack(spacing: 8) {
                                HStack {
                                    Text("Width: \(Int(appState.customWidth))px")
                                        .font(.system(size: 11))
                                    Spacer()
                                }
                                Slider(value: Binding(
                                    get: { appState.customWidth },
                                    set: { appState.customWidth = $0 }
                                ), in: 320...1200, step: 20)
                                
                                HStack {
                                    Text("Height: \(Int(appState.customHeight))px")
                                        .font(.system(size: 11))
                                    Spacer()
                                }
                                Slider(value: Binding(
                                    get: { appState.customHeight },
                                    set: { appState.customHeight = $0 }
                                ), in: 400...1000, step: 20)
                            }
                            .padding(6)
                        }
                    }
                    
                    // Search Engine Selection
                    GroupBox(label: Label("Default Search Engine", systemImage: "magnifyingglass")) {
                        VStack(spacing: 6) {
                            Picker("", selection: $appState.defaultSearchEngine) {
                                ForEach(SearchEngine.allCases) { engine in
                                    Text(engine.rawValue).tag(engine)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        .padding(6)
                    }
                    
                    // Content & Performance Section
                    GroupBox(label: Label("Content & Optimization", systemImage: "shield.lefthalf.filled")) {
                        VStack(spacing: 10) {
                            Toggle("AdBlock & Banner Cleaner", isOn: $appState.isAdBlockEnabledGlobally)
                                .font(.system(size: 11))
                            
                            Divider()
                            
                            // Auto Refresh Interval
                            HStack {
                                Text("Auto Refresh (Active Tab)")
                                    .font(.system(size: 11))
                                Spacer()
                                Picker("", selection: Binding(
                                    get: { appState.activeTab?.autoRefreshSeconds ?? 0 },
                                    set: { appState.setAutoRefresh(seconds: $0) }
                                )) {
                                    ForEach(refreshOptions, id: \.1) { label, value in
                                        Text(label).tag(value)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(width: 80)
                            }
                        }
                        .padding(6)
                    }
                    
                    // Shortcuts Section
                    GroupBox(label: Label("Global Shortcuts", systemImage: "keyboard")) {
                        VStack(spacing: 6) {
                            ShortcutRow(shortcut: "⌥ ⌘ B", description: "Toggle WebBar Window")
                            ShortcutRow(shortcut: "⌘ T", description: "Open New Tab")
                            ShortcutRow(shortcut: "⌘ W", description: "Close Active Tab")
                            ShortcutRow(shortcut: "⌘ R", description: "Reload Active Page")
                            ShortcutRow(shortcut: "⌘ L", description: "Focus URL Omnibox")
                            ShortcutRow(shortcut: "⇧ ⌘ P", description: "Toggle Pin on Top")
                            ShortcutRow(shortcut: "⌘ 1..9", description: "Switch Tab by Index")
                        }
                        .padding(6)
                    }
                    
                    // Footer Actions
                    HStack {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("WebBar v1.0.0")
                                .font(.system(size: 10, weight: .semibold))
                            Text("Inspired by MenuBarX")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(role: .destructive) {
                            NSApplication.shared.terminate(nil)
                        } label: {
                            Text("Quit WebBar")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.red)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.red.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 4)
                }
                .padding(14)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }
}

private struct ShortcutRow: View {
    let shortcut: String
    let description: String
    
    var body: some View {
        HStack {
            Text(description)
                .font(.system(size: 10.5))
                .foregroundColor(.secondary)
            Spacer()
            Text(shortcut)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.primary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
    }
}
