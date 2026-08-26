import SwiftUI
import AppKit

public struct QuickAppsGrid: View {
    @EnvironmentObject var appState: AppState
    @State private var searchInput: String = ""
    @State private var detectedClipboardUrl: String? = nil
    @FocusState private var isFieldFocused: Bool
    
    public var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 16) {
                // 1. Sleek Icon & Title Header (With Cancel button if multiple tabs exist)
                ZStack(alignment: .topTrailing) {
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(Color.accentColor.opacity(0.15))
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: "link.circle.fill")
                                .font(.system(size: 26, weight: .semibold))
                                .foregroundColor(.accentColor)
                        }
                        .shadow(color: Color.accentColor.opacity(0.25), radius: 8, y: 3)
                        
                        Text("Dán Liên Kết Website")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 40)
                    
                    if appState.tabs.count > 1 {
                        Button {
                            appState.closeActiveTabIfBlank()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.secondary.opacity(0.8))
                        }
                        .buttonStyle(.plain)
                        .help("Hủy bỏ & Đóng tab (Esc)")
                        .padding(.trailing, 16)
                        .padding(.top, 2)
                    }
                }
                
                // 2. Single Unified Natural Input Bar (Gộp 2 ô làm 1 duy nhất)
                VStack(spacing: 8) {
                    HStack(spacing: 10) {
                        Image(systemName: "link")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(isFieldFocused ? .accentColor : .secondary)
                        
                        TextField("Nhập hoặc dán link website...", text: $searchInput)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13.5, weight: .regular))
                            .focused($isFieldFocused)
                            .onSubmit {
                                performNavigation()
                            }
                        
                        if !searchInput.isEmpty {
                            Button {
                                searchInput = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary.opacity(0.8))
                            }
                            .buttonStyle(.plain)
                            .help("Xóa nội dung")
                            
                            Button {
                                performNavigation()
                            } label: {
                                HStack(spacing: 4) {
                                    Text("Mở")
                                        .font(.system(size: 12, weight: .bold))
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.system(size: 13, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.accentColor)
                                .clipShape(Capsule())
                                .shadow(color: Color.accentColor.opacity(0.35), radius: 6, y: 2)
                            }
                            .buttonStyle(.plain)
                            .help("Mở trang web (↵)")
                        } else if let clip = detectedClipboardUrl, !clip.isEmpty {
                            // Smart Clipboard Quick Action Button inside the single bar
                            Button {
                                appState.navigateTo(input: clip)
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: "doc.on.clipboard.fill")
                                        .font(.system(size: 11, weight: .bold))
                                    Text(displayHostname(for: clip))
                                        .font(.system(size: 11, weight: .semibold))
                                        .lineLimit(1)
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.accentColor)
                                .clipShape(Capsule())
                                .shadow(color: Color.accentColor.opacity(0.3), radius: 4, y: 1)
                            }
                            .buttonStyle(.plain)
                            .help("Dán và mở: \(clip)")
                        } else {
                            Button {
                                pasteFromClipboard()
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: "doc.on.clipboard")
                                        .font(.system(size: 11.5))
                                    Text("Dán Link")
                                        .font(.system(size: 11.5, weight: .medium))
                                }
                                .foregroundColor(.primary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.primary.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                            .help("Dán từ bộ nhớ tạm (⌘V)")
                        }
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 48)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(
                                appState.urlErrorMessage != nil
                                    ? Color.red.opacity(0.6)
                                    : (isFieldFocused ? Color.accentColor.opacity(0.7) : Color.white.opacity(0.18)),
                                lineWidth: (isFieldFocused || appState.urlErrorMessage != nil) ? 1.5 : 1
                            )
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 12, y: 4)
                    .padding(.horizontal, 20)
                    
                    // Inline Error Note directly attached under the single bar
                    if let errorMsg = appState.urlErrorMessage {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.red)
                            
                            Text(errorMsg)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.red)
                                .lineLimit(2)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
            .frame(maxWidth: 500)
            
            Spacer()
            
            // MARK: - Micro Shortcut Hints Footer
            HStack(spacing: 16) {
                Label("↵ Enter để mở", systemImage: "return")
                Label("⌘V Dán link", systemImage: "command")
                Label("⌘W Đóng tab", systemImage: "xmark")
            }
            .font(.system(size: 10.5, weight: .medium))
            .foregroundColor(.secondary.opacity(0.7))
            .padding(.vertical, 7)
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
