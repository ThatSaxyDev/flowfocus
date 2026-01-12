import Cocoa
import SwiftUI

class OverlayWindowController: NSObject {
    static var shared: OverlayWindowController?
    var overlayWindow: NSWindow?
    
    override init() {
        super.init()
        OverlayWindowController.shared = self
        createWindow()
        setupScreenObserver()
    }
    
    func createWindow() {
        let screenFrame = NSScreen.screens.map { $0.frame }.reduce(NSScreen.main?.frame ?? .zero) { $0.union($1) }
        
        let window = NSWindow(
            contentRect: screenFrame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .init(Int(CGWindowLevelForKey(.assistiveTechHighWindow)))
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        
        // SAFE: Let all clicks pass through (no blocking for now)
        window.ignoresMouseEvents = true
        
        let hostingView = NSHostingView(rootView: BlurOverlayView())
        window.contentView = hostingView
        
        self.overlayWindow = window
        window.orderFront(nil)
    }
    
    func setupScreenObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(screenChanged), name: NSApplication.didChangeScreenParametersNotification, object: nil)
    }
    
    @objc func screenChanged() {
        let screenFrame = NSScreen.screens.map { $0.frame }.reduce(NSScreen.main?.frame ?? .zero) { $0.union($1) }
        overlayWindow?.setFrame(screenFrame, display: true)
    }
    
    // MARK: - Popover Visibility Helpers
    
    func hideForPopover() {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            overlayWindow?.animator().alphaValue = 0.0
        }
    }
    
    func showAfterPopover() {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            overlayWindow?.animator().alphaValue = 1.0
        }
    }
}
