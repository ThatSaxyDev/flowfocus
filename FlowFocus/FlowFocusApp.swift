import SwiftUI

@main
struct FlowFocusApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var menuBarController: MenuBarController?
    var overlayController: OverlayWindowController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize components
        menuBarController = MenuBarController()
        overlayController = OverlayWindowController()
        
        // Check for Accessibility Permissions
        checkAccessibilityPermissions()
        
        // Setup Global Hotkeys (Basic implementation using NSEvent)
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            self.handleGlobalKey(event)
        }
    }
    
    func checkAccessibilityPermissions() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let isTrusted = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        if !isTrusted {
            // Wait a sec for the system prompt, or show our own if needed.
            // But usually AXIsProcessTrustedWithOptions(prompt: true) shows the system dialog.
            print("Access Not Trusted")
        }
    }
    
    func handleGlobalKey(_ event: NSEvent) {
        // ⌃⌥⌘F = Toggle Focus (Control + Option + Command + F)
        if event.modifierFlags.contains([.control, .option, .command]) {
            switch event.characters?.lowercased() {
            case "f":
                DispatchQueue.main.async {
                    SettingsManager.shared.isEnabled.toggle()
                }
            case "p":
                 // Pin focused window
                 let id = WindowTracker.shared.focusedWindowID
                 WindowFocusManager.shared.togglePin(windowID: id)
            case ",":
                // ⌃⌥⌘, = Open Settings
                DispatchQueue.main.async {
                    self.menuBarController?.openSettings()
                }
            case "\u{1b}": // Escape
                if WindowFocusManager.shared.pinnedWindowIDs.isEmpty {
                     // If no pins, escape also opens/toggles settings as a fallback/panic button
                     DispatchQueue.main.async {
                         self.menuBarController?.openSettings()
                     }
                } else {
                    WindowFocusManager.shared.clearPins()
                }
            default:
                break
            }
        }
    }
}
