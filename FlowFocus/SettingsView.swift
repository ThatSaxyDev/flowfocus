import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = SettingsManager.shared
    
    var body: some View {
        Form {
            Section(header: Text("General")) {
                Toggle("Enable FlowFocus", isOn: $settings.isEnabled)
                
                Picker("Focus Mode", selection: $settings.focusMode) {
                    ForEach(SettingsManager.FocusMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
            }
            
            Section(header: Text("Appearance")) {
                Toggle("Use Dim Mode instead of Blur", isOn: $settings.isDimMode)
                
                if settings.isDimMode {
                    Slider(value: $settings.dimOpacity, in: 0...1) {
                        Text("Dim Opacity")
                    }
                } else {
                    Slider(value: $settings.blurStrength, in: 0...100) {
                        Text("Blur Strength")
                    }
                }
            }
            
            Section(header: Text("Shortcuts")) {
                Text("Toggle Focus: ⌃⌥⌘F")
                Text("Pin Window: ⌃⌥⌘P")
                Text("Clear Pins: ⌃⌥⌘Escape")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            
            Button("Quit FlowFocus") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding()
        .frame(width: 300)
    }
}
