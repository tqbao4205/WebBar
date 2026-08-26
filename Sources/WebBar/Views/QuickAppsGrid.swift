import SwiftUI
import AppKit

public struct QuickAppsGrid: View {
    @EnvironmentObject var appState: AppState
    @State private var searchInput: String = ""
    @State private var detectedClipboardUrl: String? = nil
    @FocusState private var isFieldFocused: Bool
    
    public var body: some View {
        VStack(spacing: 10) {
            // 1. Sleek Compact Header (Icon + Title + Close Button)
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.18))
                        .frame(width: 26, height: 26)
                    
                    Image(systemName: "link")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.accentColor)
                }
                
                Text("Dán Liên Kết Website")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if appState.tabs.count > 1 {
                    Button {
                        appState.closeActiveTabIfBlank()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                    .help("Hủy bỏ & Đóng tab (Esc)")
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            
            // 2. Single Unified Compact Input Bar
            VStack(spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: "globe")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(isFieldFocused ? .accentColor : .secondary)
                    
                    TextField("Nhập hoặc dán link website...", text: $searchInput)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12.5, weight: .regular))
                        .focused($isFieldFocused)
                        .onSubmit {
                            performNavigation()
                        }
                    
                    if !searchInput.isEmpty {
                        Button {
                            searchInput = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                        .help("Xóa nội dung")
                        
                        Button {
                            performNavigation()
                        } label: {
                            HStack(spacing: 3) {
                                Text("Mở")
                                    .font(.system(size: 11, weight: .bold))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(Color.accentColor)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .help("Mở trang web (↵)")
                    } else if let clip = detectedClipboardUrl, !clip.isEmpty {
                        Button {
                            appState.navigateTo(input: clip)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "doc.on.clipboard.fill")
                                    .font(.system(size: 10, weight: .bold))
                                Text(displayHostname(for: clip))
                                    .font(.system(size: 10.5, weight: .semibold))
                                    .lineLimit(1)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentColor)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .help("Dán và mở: \(clip)")
                    } else {
                        Button {
                            pasteFromClipboard()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "doc.on.clipboard")
                                    .font(.system(size: 10.5))
                                Text("Dán Link")
                                    .font(.system(size: 10.5, weight: .medium))
                            }
                            .foregroundColor(.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.primary.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                        .help("Dán từ bộ nhớ tạm (⌘V)")
                    }
                }
                .padding(.horizontal, 10)
                .frame(height: 38)
                .background(Color.primary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(
                            appState.urlErrorMessage != nil
                                ? Color.red.opacity(0.6)
                                : (isFieldFocused ? Color.accentColor.opacity(0.65) : Color.white.opacity(0.12)),
                            lineWidth: 1
                        )
                )
                .padding(.horizontal, 16)
                
                // Inline Error Note
                if let errorMsg = appState.urlErrorMessage {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.red)
                        Text(errorMsg)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.red)
                            .lineLimit(1)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                }
            }
            
            Spacer(minLength: 0)
            
            // MARK: - Micro Shortcut Hints Footer
            HStack(spacing: 12) {
                Text("↵ Enter Mở")
                Text("•")
                Text("⌘V Dán")
                Text("•")
                Text("Esc Hủy")
            }
            .font(.system(size: 9.5, weight: .medium))
            .foregroundColor(.secondary.opacity(0.6))
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .background(Color.black.opacity(0.12))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            searchInput = appState.urlInputText
            checkClipboardForUrl()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                isFieldFocused = true
            }
        }
        .onChange(of: appState.urlInputText) { newUrl in
            if !newUrl.isEmpty {
                searchInput = newUrl
            }
        }
        .onChange(of: appState.urlErrorMessage) { error in
            if error != nil {
                if !appState.urlInputText.isEmpty {
                    searchInput = appState.urlInputText
                }
                isFieldFocused = true
            }
        }
    }
    
    private func checkClipboardForUrl() {
        guard let pasteboardString = NSPasteboard.general.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !pasteboardString.isEmpty else {
            detectedClipboardUrl = nil
            return
        }
        
        let lower = pasteboardString.lowercased()
        if lower.hasPrefix("http://") || lower.hasPrefix("https://") {
            detectedClipboardUrl = pasteboardString
        } else if (lower.contains(".com") || lower.contains(".vn") || lower.contains(".ai") || lower.contains(".io") || lower.contains(".net") || lower.contains(".org") || lower.contains(".me") || lower.contains(".app") || lower.contains(".dev")) && !lower.contains(" ") && pasteboardString.count >= 4 {
            detectedClipboardUrl = pasteboardString
        } else {
            detectedClipboardUrl = nil
        }
    }
    
    private func pasteFromClipboard() {
        if let pasteboardString = NSPasteboard.general.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines),
           !pasteboardString.isEmpty {
            searchInput = pasteboardString
            isFieldFocused = true
        }
    }
    
    private func performNavigation() {
        let query = searchInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty {
            if let clip = detectedClipboardUrl, !clip.isEmpty {
                appState.navigateTo(input: clip)
            }
            return
        }
        appState.navigateTo(input: query)
    }
    
    private func displayHostname(for urlStr: String) -> String {
        let cleanUrl = urlStr.hasPrefix("http") ? urlStr : ("https://" + urlStr)
        if let url = URL(string: cleanUrl), let host = url.host, !host.isEmpty {
            let clean = host.replacingOccurrences(of: "www.", with: "")
            return "Dán: " + clean
        }
        return "Dán & Mở"
    }
}
