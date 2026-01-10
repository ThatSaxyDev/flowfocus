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
                        in: settings.isDimMode ? 0...1 : 0...100
                    )
                }
            }
            
            // Window Selection Section (only show in multiPin mode)
            if settings.focusMode == .multiPin {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "macwindow.on.rectangle")
                            .foregroundColor(.accentColor)
                        Text("Select Windows")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        if !focusManager.pinnedWindowIDs.isEmpty {
                            Button("Clear All") {
                                focusManager.clearPins()
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.red)
                            .font(.caption)
                        }
                    }
                    
                    let windows = focusManager.getAllWindowsInfo()
                    
                    if windows.isEmpty {
                        Text("No windows available")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 8)
                    } else {
                        ScrollView {
                            VStack(spacing: 4) {
                                ForEach(windows, id: \.id) { window in
                                    HStack(spacing: 8) {
                                        // Toggle
                                        Image(systemName: window.isPinned ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(window.isPinned ? .accentColor : .secondary)
                                            .font(.system(size: 16))
                                        
                                        // App icon placeholder + name
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
                                        focusManager.togglePin(windowID: window.id)
                                    }
                                }
                            }
                        }
                        .frame(maxHeight: 150)
                    }
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
        }
        .padding()
        .frame(width: 280)
    }
}

