import Cocoa
import SwiftUI

class MenuBarController: NSObject, NSPopoverDelegate {
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
        popover?.delegate = self
    }
    
    @objc func togglePopover() {
        guard let button = statusItem?.button else { return }
        
        if let popover = popover {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                // Animate the cutout to expand for the popover
                SettingsManager.shared.isPopoverOpen = true
                
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
    
    func openSettings() {
        guard let button = statusItem?.button else { return }
        if let popover = popover, !popover.isShown {
            // Animate the cutout to expand for the popover
            SettingsManager.shared.isPopoverOpen = true
            
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    // MARK: - NSPopoverDelegate
    
    func popoverDidClose(_ notification: Notification) {
        // Animate the cutout back to pill shape
        SettingsManager.shared.isPopoverOpen = false
    }
}

