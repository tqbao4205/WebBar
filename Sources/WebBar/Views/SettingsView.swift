import SwiftUI

public struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    
    private var isVI: Bool {
        appState.language == .vietnamese
    }
    
    private var refreshOptions: [(String, Int)] {
        if isVI {
            return [("Tắt", 0), ("10 giây", 10), ("30 giây", 30), ("1 phút", 60), ("5 phút", 300)]
        } else {
            return [("Off", 0), ("10s", 10), ("30s", 30), ("1m", 60), ("5m", 300)]
        }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Label(isVI ? "Cài Đặt WebBar" : "WebBar Settings", systemImage: "gearshape.fill")
                    .font(.system(size: 13.5, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        appState.isSettingsOpen = false
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary.opacity(0.7))
                }
                .buttonStyle(.plain)
                .help(isVI ? "Đóng cài đặt" : "Close Settings")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.primary.opacity(0.04))
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    // 1. General Settings
                    GroupBox(label: Label(isVI ? "Chung" : "General", systemImage: "slider.horizontal.3")) {
                        VStack(spacing: 10) {
                            // Language Selector
                            VStack(alignment: .leading, spacing: 6) {
                                Text(isVI ? "Ngôn ngữ hiển thị" : "App Language")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                Picker("", selection: $appState.language) {
                                    ForEach(AppLanguage.allCases) { lang in
                                        Text(lang.title).tag(lang)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                            
                            Divider()
                            
                            // Launch at Login
                            Toggle(isVI ? "Tự mở khi bật máy (Launch at Login)" : "Launch at Login", isOn: Binding(
                                get: { appState.launchAtLogin },
                                set: { appState.setLaunchAtLogin($0) }
                            ))
                            .font(.system(size: 11.5))
                            
                            Divider()
                            
                            // Keep Window Open Toggle
                            Toggle(isVI ? "Ghim giữ cửa sổ (Keep Window Open)" : "Keep Window Open (Pin)", isOn: Binding(
                                get: { appState.isPinned },
                                set: { appState.isPinned = $0 }
                            ))
                            .font(.system(size: 11.5))
                        }
                        .padding(8)
                    }
                    
                    // 2. Optimization & Content
                    GroupBox(label: Label(isVI ? "Nội Dung & Tối Ưu" : "Content & Optimization", systemImage: "shield.lefthalf.filled")) {
                        VStack(spacing: 10) {
                            // AdBlock Toggle
                            Toggle(isVI ? "Chặn quảng cáo & Banner rác" : "AdBlock & Banner Cleaner", isOn: $appState.isAdBlockEnabledGlobally)
                                .font(.system(size: 11.5))
                            
                            Divider()
                            
                            // Auto Refresh Interval
                            HStack {
                                Text(isVI ? "Tự động tải lại trang (Tab hiện tại)" : "Auto Refresh (Active Tab)")
                                    .font(.system(size: 11.5))
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
                                .frame(width: 95)
                            }
                        }
                        .padding(8)
                    }
                    
                    // 3. Shortcuts Section
                    GroupBox(label: Label(isVI ? "Phím Tắt Nhanh" : "Global Shortcuts", systemImage: "keyboard")) {
                        VStack(spacing: 6) {
                            ShortcutRow(shortcut: "⌥ ⌘ B", description: isVI ? "Bật / Tắt cửa sổ WebBar" : "Toggle WebBar Window")
                            ShortcutRow(shortcut: "⌘ T", description: isVI ? "Mở Tab Mới" : "Open New Tab")
                            ShortcutRow(shortcut: "⌘ W", description: isVI ? "Đóng Tab Hiện Tại" : "Close Active Tab")
                            ShortcutRow(shortcut: "⌘ R", description: isVI ? "Tải Lại Trang Web" : "Reload Active Page")
                            ShortcutRow(shortcut: "⌘ L", description: isVI ? "Thanh Tìm Kiếm / URL" : "Focus URL Omnibox")
                            ShortcutRow(shortcut: "⇧ ⌘ P", description: isVI ? "Ghim / Bỏ Ghim Cửa Sổ" : "Toggle Pin on Top")
                            ShortcutRow(shortcut: "⌘ 1..9", description: isVI ? "Chuyển Đổi Tab Nhanh" : "Switch Tab by Index")
                        }
                        .padding(8)
                    }
                    
                    // Footer Actions
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("WebBar v1.0.0")
                                .font(.system(size: 10.5, weight: .semibold))
                            Text(isVI ? "Trình duyệt Menu Bar cho macOS" : "Menu Bar Browser for macOS")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(role: .destructive) {
                            NSApplication.shared.terminate(nil)
                        } label: {
                            Text(isVI ? "Thoát WebBar" : "Quit WebBar")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.red)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4.5)
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
