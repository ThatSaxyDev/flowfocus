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
            
            // Pinned Windows Section (only show in multiPin mode)
            if settings.focusMode == .multiPin {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "pin.fill")
                            .foregroundColor(.orange)
                        Text("Pinned Windows")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        if !focusManager.pinnedWindowIDs.isEmpty {
                            Button("Clear") {
                                focusManager.clearPins()
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.red)
                            .font(.caption)
                        }
                    }
                    
                    if focusManager.pinnedWindowIDs.isEmpty {
                        Text("No windows pinned.\nUse ⌃⌥⌘P to pin the focused window.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(focusManager.getPinnedWindowInfo(), id: \.id) { info in
                            HStack {
                                Image(systemName: "macwindow")
                                    .foregroundColor(.secondary)
                                Text(info.name)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                Spacer()
                                Button {
                                    focusManager.togglePin(windowID: info.id)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                            .font(.caption)
                            .padding(.vertical, 2)
                        }
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

