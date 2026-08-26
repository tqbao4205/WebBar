import SwiftUI
import AppKit

public struct QuickAppsGrid: View {
    @EnvironmentObject var appState: AppState
    @State private var searchInput: String = ""
    @State private var detectedClipboardUrl: String? = nil
    @State private var isSuccess: Bool = false
    @FocusState private var isFieldFocused: Bool
    
    private var isVI: Bool {
        appState.language == .vietnamese
    }
    
    private var borderColor: Color {
        if isSuccess {
            return Color.green.opacity(0.9)
        } else if appState.urlErrorMessage != nil {
            return Color.red.opacity(0.65)
        } else if isFieldFocused {
            return Color.accentColor.opacity(0.65)
        } else {
            return Color.white.opacity(0.12)
        }
    }
    
    private var backgroundColor: Color {
        if isSuccess {
            return Color.green.opacity(0.12)
        } else if appState.urlErrorMessage != nil {
            return Color.red.opacity(0.08)
        } else {
            return Color.primary.opacity(0.05)
        }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            headerView
            
            Spacer(minLength: 6)
            
            inputSectionView
            
            Spacer(minLength: 8)
            
            footerView
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
                withAnimation {
                    isSuccess = false
                }
            }
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill((isSuccess ? Color.green : Color.accentColor).opacity(0.18))
                    .frame(width: 26, height: 26)
                
                Image(systemName: isSuccess ? "checkmark" : "link")
                    .font(.system(size: 12.5, weight: .bold))
                    .foregroundColor(isSuccess ? .green : .accentColor)
            }
            
            Text(isVI ? "Dán Liên Kết Website" : "Open Website")
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
                .help(isVI ? "Hủy bỏ & Đóng tab (Esc)" : "Cancel & Close Tab (Esc)")
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
    }
    
    // MARK: - Input Section
    private var inputSectionView: some View {
        VStack(spacing: 5) {
            HStack(spacing: 10) {
                Image(systemName: isSuccess ? "checkmark.circle.fill" : "globe")
                    .font(.system(size: 14.5, weight: .medium))
                    .foregroundColor(isSuccess ? .green : (isFieldFocused ? .accentColor : .secondary))
                
                TextField(isVI ? "Nhập hoặc dán link website..." : "Enter or paste website URL...", text: $searchInput)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13.5, weight: .regular))
                    .focused($isFieldFocused)
                    .onSubmit {
                        performNavigation()
                    }
                
                trailingActionButton
            }
            .padding(.horizontal, 12)
            .frame(height: 44)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .stroke(borderColor, lineWidth: isSuccess ? 1.5 : 1)
            )
            .scaleEffect(isSuccess ? 1.012 : 1.0)
            .padding(.horizontal, 18)
            
            if let errorMsg = appState.urlErrorMessage {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 10.5))
                        .foregroundColor(.red)
                    Text(errorMsg)
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundColor(.red)
                        .lineLimit(1)
                    Spacer()
                }
                .padding(.horizontal, 22)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    // MARK: - Trailing Action Button
    @ViewBuilder
    private var trailingActionButton: some View {
        if !searchInput.isEmpty {
            HStack(spacing: 6) {
                Button {
                    searchInput = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary.opacity(0.7))
                }
                .buttonStyle(.plain)
                .help(isVI ? "Xóa nội dung" : "Clear input")
                
                Button {
                    performNavigation()
                } label: {
                    HStack(spacing: 4) {
                        Text(isVI ? "Mở" : "Open")
                            .font(.system(size: 12, weight: .bold))
                        Image(systemName: isSuccess ? "checkmark" : "arrow.right")
                            .font(.system(size: 10.5, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 5.5)
                    .background(isSuccess ? Color.green : Color.accentColor)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .help(isVI ? "Mở trang web (↵)" : "Open website (↵)")
            }
        } else if let clip = detectedClipboardUrl, !clip.isEmpty {
            Button {
                triggerNavigation(with: clip)
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: isSuccess ? "checkmark.circle.fill" : "doc.on.clipboard.fill")
                        .font(.system(size: 11, weight: .bold))
                    Text(displayHostname(for: clip))
                        .font(.system(size: 11, weight: .semibold))
                        .lineLimit(1)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5.5)
                .background(isSuccess ? Color.green : Color.accentColor)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .help("\(isVI ? "Dán và mở:" : "Paste & open:") \(clip)")
        } else {
            Button {
                pasteFromClipboard()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 11))
                    Text(isVI ? "Dán Link" : "Paste")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5.5)
                .background(Color.primary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 7))
            }
            .buttonStyle(.plain)
            .help(isVI ? "Dán từ bộ nhớ tạm (⌘V)" : "Paste from clipboard (⌘V)")
        }
    }
    
    // MARK: - Footer
    private var footerView: some View {
        HStack(spacing: 12) {
            Text(isVI ? "↵ Enter Mở" : "↵ Enter Open")
            Text("•")
            Text(isVI ? "⌘V Dán" : "⌘V Paste")
            Text("•")
            Text(isVI ? "Esc Hủy" : "Esc Cancel")
        }
        .font(.system(size: 9.5, weight: .medium))
        .foregroundColor(.secondary.opacity(0.6))
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.12))
    }
    
    // MARK: - Navigation Logic
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
            
            if appState.validateAndFormatURL(input: pasteboardString) != nil {
                triggerNavigation(with: pasteboardString)
            }
        }
    }
    
    private func performNavigation() {
        let query = searchInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty {
            if let clip = detectedClipboardUrl, !clip.isEmpty {
                triggerNavigation(with: clip)
            }
            return
        }
        triggerNavigation(with: query)
    }
    
    private func triggerNavigation(with text: String) {
        let query = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        
        if appState.validateAndFormatURL(input: query) != nil {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.72)) {
                isSuccess = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) {
                appState.navigateTo(input: query)
            }
        } else {
            withAnimation {
                isSuccess = false
            }
            appState.navigateTo(input: query)
        }
    }
    
    private func displayHostname(for urlStr: String) -> String {
        let cleanUrl = urlStr.hasPrefix("http") ? urlStr : ("https://" + urlStr)
        if let url = URL(string: cleanUrl), let host = url.host, !host.isEmpty {
            let clean = host.replacingOccurrences(of: "www.", with: "")
            return (isVI ? "Dán: " : "Paste: ") + clean
        }
        return isVI ? "Dán & Mở" : "Paste & Open"
    }
}
