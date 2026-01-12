import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = SettingsManager.shared
    @ObservedObject var focusManager = WindowFocusManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            // Enable Toggle
            HStack {
                Image(systemName: settings.isEnabled ? "eye.fill" : "eye.slash")
                    .foregroundColor(settings.isEnabled ? .accentColor : .secondary)
                Text("FlowFocus")
                    .font(.headline)
                Spacer()
                Toggle("", isOn: $settings.isEnabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }
            .padding(.horizontal, 4)
            
            Divider()
            
            // Focus Mode Picker
            HStack {
                Text("Mode")
                    .foregroundColor(.secondary)
                Spacer()
                Picker("", selection: $settings.focusMode) {
                    ForEach(SettingsManager.FocusMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(width: 140)
            }
            
            // Blur/Dim Segmented Picker
            VStack(alignment: .leading, spacing: 8) {
                Picker("", selection: $settings.isDimMode) {
                    Text("🌫️ Blur").tag(false)
                    Text("🌑 Dim").tag(true)
                }
                .pickerStyle(.segmented)
                
                // Single Intensity Slider
                HStack {
                    Text("Intensity")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    Slider(
                        value: settings.isDimMode ? $settings.dimOpacity : $settings.blurStrength,
                        in: settings.isDimMode ? 0...0.85 : 0...100
                    )
                }
            }
            
            // Window Selection Section (only show in multiPin mode)
            if settings.focusMode == .multiPin {
                Divider()
                WindowSelectionView()
            }
            
            Divider()
            
            // Keyboard Shortcuts Help (collapsible)
            DisclosureGroup {
                VStack(alignment: .leading, spacing: 8) {
                    ShortcutRow(keys: ["⌃", "⌥", "⌘", "F"], action: "Turn on / off")
                    ShortcutRow(keys: ["⌃", "⌥", "⌘", ","], action: "Open settings")
                    ShortcutRow(keys: ["⌃", "⌥", "⌘", "esc"], action: "Clear all pins")
                    ShortcutRow(keys: ["⌃", "⌥", "⌘", "Q"], action: "Quit")
                }
                .padding(.top, 4)
            } label: {
                HStack {
                    Image(systemName: "keyboard")
                        .foregroundColor(.secondary)
                    Text("Keyboard Shortcuts")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            // Quit Button
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Text("Quit FlowFocus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            
            // Footer
            Text("Made by Kiishi")
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)
        }
        .padding()
        .frame(width: 280)
    }
}

// Separate view for window selection to avoid layout recursion
struct WindowSelectionView: View {
    @ObservedObject var focusManager = WindowFocusManager.shared
    @State private var windows: [(id: CGWindowID, name: String, appName: String, isPinned: Bool)] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "macwindow.on.rectangle")
                    .foregroundColor(.accentColor)
                Text("Select Windows")
                    .font(.subheadline.weight(.medium))
                Spacer()
                
                Button("Refresh") {
                    refreshWindows()
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
                .font(.caption)
                
                if !focusManager.pinnedWindowIDs.isEmpty {
                    Button("Clear") {
                        focusManager.clearPins()
                        refreshWindows()
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.red)
                    .font(.caption)
                }
            }
            
            if windows.isEmpty {
                Text("No windows available.\nTap Refresh to reload.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 4) {
                        ForEach(windows, id: \.id) { window in
                            WindowRowView(window: window) {
                                focusManager.togglePin(windowID: window.id)
                                refreshWindows()
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .frame(height: 100)
                .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                .cornerRadius(8)
            }
        }
        .task {
            // Small delay to ensure view is fully rendered
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            await MainActor.run {
                refreshWindows()
            }
        }
    }
    
    private func refreshWindows() {
        windows = focusManager.getAllWindowsInfo()
    }
}

struct WindowRowView: View {
    let window: (id: CGWindowID, name: String, appName: String, isPinned: Bool)
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: window.isPinned ? "checkmark.circle.fill" : "circle")
                .foregroundColor(window.isPinned ? .accentColor : .secondary)
                .font(.system(size: 16))
            
            VStack(alignment: .leading, spacing: 1) {
                Text(window.name)
                    .font(.caption)
                    .lineLimit(1)
                    .truncationMode(.middle)
                if window.name != window.appName {
                    Text(window.appName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(window.isPinned ? Color.accentColor.opacity(0.1) : Color.clear)
        .cornerRadius(6)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

struct ShortcutRow: View {
    let keys: [String]
    let action: String
    
    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 3) {
                ForEach(keys, id: \.self) { key in
                    KeyCapView(key: key)
                }
            }
            Text(action)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
    }
}

struct KeyCapView: View {
    let key: String
    
    var body: some View {
        Text(key)
            .font(.system(size: 10, weight: .medium, design: .rounded))
            .foregroundColor(.primary)
            .frame(minWidth: 18, minHeight: 18)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
            )
    }
}
