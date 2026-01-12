import SwiftUI
import HotKey

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
    
    // Global hotkeys using HotKey library
    var toggleFocusHotKey: HotKey?
    var openSettingsHotKey: HotKey?
    var clearPinsHotKey: HotKey?
    var quitHotKey: HotKey?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Prevent multiple instances
        let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: Bundle.main.bundleIdentifier!)
        if runningApps.count > 1 {
            // Another instance is already running, quit this one
            NSApp.terminate(nil)
            return
        }
        
        // Initialize components
        menuBarController = MenuBarController()
        overlayController = OverlayWindowController()
        
        // Check for Accessibility Permissions
        checkAccessibilityPermissions()
        
        // Show the popover on launch to help users find the menu bar icon
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.menuBarController?.openSettings()
        }
        
        // Setup Global Hotkeys using HotKey library
        setupGlobalHotkeys()
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
    
    func setupGlobalHotkeys() {
        // ⌃⌥⌘F = Turn FlowFocus on/off
        toggleFocusHotKey = HotKey(key: .f, modifiers: [.control, .option, .command])
        toggleFocusHotKey?.keyDownHandler = {
            DispatchQueue.main.async {
                SettingsManager.shared.isEnabled.toggle()
            }
        }
        
        // ⌃⌥⌘, = Toggle Settings (open if closed, close if open)
        openSettingsHotKey = HotKey(key: .comma, modifiers: [.control, .option, .command])
        openSettingsHotKey?.keyDownHandler = { [weak self] in
            DispatchQueue.main.async {
                self?.menuBarController?.togglePopover()
            }
        }
        
        // ⌃⌥⌘Escape = Clear pins (or open settings if no pins)
        clearPinsHotKey = HotKey(key: .escape, modifiers: [.control, .option, .command])
        clearPinsHotKey?.keyDownHandler = { [weak self] in
            if WindowFocusManager.shared.pinnedWindowIDs.isEmpty {
                // If no pins, escape also opens/toggles settings as a fallback/panic button
                DispatchQueue.main.async {
                    self?.menuBarController?.openSettings()
                }
            } else {
                WindowFocusManager.shared.clearPins()
            }
        }
        
        // ⌃⌥⌘Q = Quit FlowFocus
        quitHotKey = HotKey(key: .q, modifiers: [.control, .option, .command])
        quitHotKey?.keyDownHandler = {
            DispatchQueue.main.async {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}
