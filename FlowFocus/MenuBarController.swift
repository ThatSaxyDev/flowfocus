import Cocoa
import SwiftUI

class MenuBarController: NSObject {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    
    override init() {
        super.init()
        setupMenuBar()
    }
    
    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "macwindow.on.rectangle", accessibilityDescription: "FlowFocus")
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 300, height: 400)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(rootView: SettingsView())
    }
    
    @objc func togglePopover() {
        guard let button = statusItem?.button else { return }
        
        if let popover = popover {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
    
    func openSettings() {
        // Since we are using a popover for settings, we just toggle it open.
        // We ensure it's open (not toggling off if already open).
        guard let button = statusItem?.button else { return }
        if let popover = popover, !popover.isShown {
             popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
             NSApp.activate(ignoringOtherApps: true)
        }
    }
}
