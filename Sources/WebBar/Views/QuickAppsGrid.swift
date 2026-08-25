import SwiftUI

public struct QuickAppsGrid: View {
    @EnvironmentObject var appState: AppState
    @State private var searchInput: String = ""
    @FocusState private var isFieldFocused: Bool
    
    private let columns = [
        GridItem(.adaptive(minimum: 76, maximum: 90), spacing: 10)
    ]
    
    public var body: some View {
        VStack(spacing: 0) {
            // 1. Sleek Spotlight Search Bar
            HStack(spacing: 10) {
                Image(systemName: "globe")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.secondary)
                
                TextField("Nhập URL hoặc tìm kiếm...", text: $searchInput)
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
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                
                Button {
                    performNavigation()
                } label: {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .frame(height: 44)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(
                        isFieldFocused
                            ? Color.accentColor.opacity(0.65)
                            : Color.white.opacity(0.22),
                        lineWidth: isFieldFocused ? 1.5 : 1
                    )
            )
            .shadow(color: Color.black.opacity(0.18), radius: 10, y: 3)
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 12)
            
            // 2. Quick App Launcher Grid
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Ứng Dụng Phổ Biến")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                    
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(QuickApp.presets) { app in
                            QuickAppButton(app: app) {
                                appState.loadQuickApp(app)
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                }
                .padding(.bottom, 16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            searchInput = appState.urlInputText
            isFieldFocused = true
        }
    }
    
    private func performNavigation() {
        let query = searchInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        appState.navigateTo(input: query)
    }
}

private struct QuickAppButton: View {
    let app: QuickApp
    let action: () -> Void
    @State private var isHovered: Bool = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(hex: app.colorHex).opacity(0.9))
                        .frame(width: 48, height: 48)
                        .shadow(color: Color(hex: app.colorHex).opacity(isHovered ? 0.45 : 0.2), radius: isHovered ? 8 : 4, y: 2)
                    
                    Image(systemName: app.iconSymbol)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.white)
                }
                .scaleEffect(isHovered ? 1.06 : 1.0)
                
                Text(app.name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isHovered ? .primary : .secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

fileprivate extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
