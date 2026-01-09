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
        
        // Setup Global Hotkeys (Basic implementation using NSEvent)
        // Note: For robust global hotkeys, we'd normally use Carbon/HotKey libs, 
        // but for a simple prototype, NSEvent monitoring works if the app has headers.
        // Actually, detecting key presses when app is background requires Accessibility permissions.
        
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            self.handleGlobalKey(event)
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
                 if let id = WindowTracker.shared.focusedWindowID as? CGWindowID {
                     WindowFocusManager.shared.togglePin(windowID: id)
                 }
            case "\u{1b}": // Escape
                WindowFocusManager.shared.clearPins()
            default:
                break
            }
        }
    }
}
