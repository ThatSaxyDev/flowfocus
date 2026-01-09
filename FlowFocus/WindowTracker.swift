import Cocoa
import Combine
import CoreVideo

class WindowTracker: ObservableObject {
    static let shared = WindowTracker()
    
    @Published var focusedWindowFrame: CGRect = .zero
    @Published var focusedWindowID: CGWindowID = 0
    @Published var appWindowIDs: Set<CGWindowID> = []
    
    private var displayLink: CVDisplayLink?
    
    init() {
        setupDisplayLink()
        startTracking()
    }
    
    deinit {
        stopTracking()
    }
    
    func setupDisplayLink() {
        CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
        
        let displayLinkOutputCallback: CVDisplayLinkOutputCallback = { displayLink, _inNow, _inOutputTime, _flagsIn, _flagsOut, displayLinkContext in
            let manager = Unmanaged<WindowTracker>.fromOpaque(displayLinkContext!).takeUnretainedValue()
            manager.updateFocusedWindowKey()
            return kCVReturnSuccess
        }
        
        if let link = displayLink {
            CVDisplayLinkSetOutputCallback(link, displayLinkOutputCallback, Unmanaged.passUnretained(self).toOpaque())
        }
    }
    
    func startTracking() {
        guard let link = displayLink else { return }
        CVDisplayLinkStart(link)
    }
    
    func stopTracking() {
        guard let link = displayLink else { return }
        CVDisplayLinkStop(link)
    }
    
    private func updateFocusedWindowKey() {
        guard let info = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else { return }
        
        // Find the frontmost window (excluding our own overlay and system windows)
        // This is a naive implementation; for robust focus tracking we might use Accessibility API
        // For now, we look for the first window that isn't us and has a title/is normal
        
        for window in info {
            guard let layer = window[kCGWindowLayer as String] as? Int, layer == 0, // Normal window layer
                  let ownerName = window[kCGWindowOwnerName as String] as? String,
                  ownerName != "FlowFocus", // Ignore ourselves
                  let boundsDict = window[kCGWindowBounds as String] as? [String: Any],
                  let bounds = CGRect(dictionaryRepresentation: boundsDict as CFDictionary),
                  let id = window[kCGWindowNumber as String] as? CGWindowID,
                  let ownerPID = window[kCGWindowOwnerPID as String] as? Int32
            else { continue }
            
            // Checking availability/validity might need AX API, but geometry is fast
            
            DispatchQueue.main.async {
                if self.focusedWindowID != id {
                    self.focusedWindowID = id
                    self.fetchAppWindows(pid: ownerPID)
                }
                
                // Always update frame in case it moves
                if self.focusedWindowFrame != bounds {
                    self.focusedWindowFrame = bounds
                }
            }
            return // Found top window
        }
    }
    
    private func fetchAppWindows(pid: Int32) {
        guard let info = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else { return }
        
        var ids: Set<CGWindowID> = []
        for window in info {
            guard let ownerPID = window[kCGWindowOwnerPID as String] as? Int32,
                  ownerPID == pid,
                  let id = window[kCGWindowNumber as String] as? CGWindowID,
                  let layer = window[kCGWindowLayer as String] as? Int, layer == 0
            else { continue }
            ids.insert(id)
        }
        
        DispatchQueue.main.async {
            self.appWindowIDs = ids
        }
    }
}
