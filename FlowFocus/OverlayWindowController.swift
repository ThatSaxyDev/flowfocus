import Cocoa
import SwiftUI

class OverlayWindowController: NSObject {
    var overlayWindow: NSWindow?
    
    override init() {
        super.init()
        createWindow()
        setupScreenObserver()
    }
    
    func createWindow() {
        // Create a window that covers the entire virtual screen union
        let screenFrame = NSScreen.screens.map { $0.frame }.reduce(NSScreen.main?.frame ?? .zero) { $0.union($1) }
        
        let window = NSWindow(
            contentRect: screenFrame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .init(Int(CGWindowLevelForKey(.assistiveTechHighWindow))) // Very high level
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.ignoresMouseEvents = true // Let clicks pass through
        
        // Host the SwiftUI View
        let hostingView = NSHostingView(rootView: BlurOverlayView())
        window.contentView = hostingView
        
        self.overlayWindow = window
        window.orderFront(nil)
    }
    
    func setupScreenObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(screenChanged), name: NSApplication.didChangeScreenParametersNotification, object: nil)
    }
    
    @objc func screenChanged() {
        // Update frame when screens change
        let screenFrame = NSScreen.screens.map { $0.frame }.reduce(NSScreen.main?.frame ?? .zero) { $0.union($1) }
        overlayWindow?.setFrame(screenFrame, display: true)
    }
}
