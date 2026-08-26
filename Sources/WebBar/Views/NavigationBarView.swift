import SwiftUI

public struct NavigationBarView: View {
    @EnvironmentObject var appState: AppState
    @FocusState private var isTextFieldFocused: Bool
    @State private var inputUrl: String = ""
    
    public var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 5) {
                // Navigation Controls Group (Back / Forward / Reload)
                HStack(spacing: 1) {
                    Button {
                        appState.goBack()
                    } label: {
                        Image(systemName: "chevron.backward")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(appState.currentCanGoBack ? .primary : .secondary.opacity(0.3))
                            .frame(width: 20, height: 22)
                    }
                    .buttonStyle(.plain)
                    .disabled(!appState.currentCanGoBack)
                    .help("Back (⌘[)")
                    
                    Button {
                        appState.goForward()
                    } label: {
                        Image(systemName: "chevron.forward")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(appState.currentCanGoForward ? .primary : .secondary.opacity(0.3))
                            .frame(width: 20, height: 22)
                    }
                    .buttonStyle(.plain)
                    .disabled(!appState.currentCanGoForward)
                    .help("Forward (⌘])")
                    
                    Button {
                        appState.reloadActiveTab()
                    } label: {
                        Image(systemName: appState.currentIsLoading ? "xmark" : "arrow.clockwise")
                            .font(.system(size: 9.5, weight: .semibold))
                            .foregroundColor(.secondary)
                            .frame(width: 20, height: 22)
                    }
                    .buttonStyle(.plain)
                    .help("Reload (⌘R)")
                }
                
                // Minimalist Omnibox / Search Input
                HStack(spacing: 5) {
                    Image(systemName: (appState.activeTab?.urlString.hasPrefix("https://") == true) ? "lock.fill" : "magnifyingglass")
                        .font(.system(size: 9))
                        .foregroundColor((appState.activeTab?.urlString.hasPrefix("https://") == true) ? .green.opacity(0.7) : .secondary)
                    
                    TextField("Search or enter URL...", text: $inputUrl)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11))
                        .focused($isTextFieldFocused)
                        .onAppear {
                            inputUrl = appState.activeTab?.urlString ?? ""
                        }
                        .onChange(of: appState.activeTab?.urlString) { newUrl in
                            if !isTextFieldFocused {
                                inputUrl = newUrl ?? ""
                            }
                        }
                        .onSubmit {
                            appState.navigateTo(input: inputUrl)
                            isTextFieldFocused = false
                        }
                    
                    if !inputUrl.isEmpty {
                        Button {
                            inputUrl = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 7)
                .frame(height: 24)
                .background(Color.primary.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isTextFieldFocused ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 1)
                )
                
                // Viewport Preset Picker Dropdown
                Menu {
                    ForEach(ViewportMode.allCases) { mode in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                appState.setViewport(mode)
                            }
                        } label: {
                            HStack {
                                Label(mode.rawValue, systemImage: mode.iconName)
                                if appState.activeTab?.viewport == mode {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: appState.activeTab?.viewport.iconName ?? "iphone")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 22, height: 22)
                }
                .menuStyle(.borderlessButton)
                .frame(width: 22, height: 22)
                .help("Viewport Size")
                
                // Pin on Top Button
                Button {
                    withAnimation {
                        appState.togglePin()
                    }
                } label: {
                    Image(systemName: appState.isPinned ? "pin.fill" : "pin")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(appState.isPinned ? .orange : .secondary)
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.plain)
                .help(appState.isPinned ? "Unpin Window" : "Keep Window Open (Pin)")
                
                // Hide Bar / Zen Mode Button
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        appState.toggleTopBar()
                    }
                } label: {
                    Image(systemName: "chevron.up.circle.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.plain)
                .help("Hide Top Bar & Fullscreen Web (⌘\\ or ⇧⌘H)")
                
                // Settings Button
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        appState.isSettingsOpen.toggle()
                    }
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(appState.isSettingsOpen ? .accentColor : .secondary)
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.plain)
                .help("Settings")
            }
            .padding(.horizontal, 6)
            .frame(height: 30)
            .background(Color.black.opacity(0.12))
            
            // Progress Bar (Slim line under Navigation Bar)
            if appState.currentIsLoading {
                GeometryReader { geo in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, geo.size.width * CGFloat(appState.currentProgress)), height: 2)
                        .animation(.easeInOut(duration: 0.2), value: appState.currentProgress)
                }
                .frame(height: 2)
            }
        }
        .onAppear {
            inputUrl = appState.activeTab?.urlString ?? ""
        }
        .onChange(of: appState.selectedTabId) { _ in
            inputUrl = appState.activeTab?.urlString ?? ""
        }
        .onChange(of: appState.activeTab?.urlString) { newUrl in
            if !isTextFieldFocused {
                inputUrl = newUrl ?? ""
            }
        }
    }
}
