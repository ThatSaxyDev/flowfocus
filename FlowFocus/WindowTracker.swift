import Cocoa
import Combine
import ApplicationServices

class WindowTracker: ObservableObject {
    static let shared = WindowTracker()
    
    @Published var focusedWindowFrame: CGRect = .zero
    @Published var focusedWindowID: CGWindowID = 0
    @Published var appWindowIDs: Set<CGWindowID> = []
    
    private var displayTimer: Timer?
    private var frameCounter = 0
    
    init() {
        startTracking()
    }
    
    deinit {
        stopTracking()
    }
    
    func startTracking() {
        // Use Timer instead of deprecated CVDisplayLink
        // 60 FPS = 1/60 = ~0.0167 seconds
        displayTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] _ in
            self?.updateFocusedWindowKey()
        }
        RunLoop.current.add(displayTimer!, forMode: .common)
    }
    
    func stopTracking() {
        displayTimer?.invalidate()
        displayTimer = nil
    }
    
    private func updateFocusedWindowKey() {
        // High-frequency polling using Accessibility API for smoothness
        updateFocusedWindowFrameAX()
        
        // Run ID check every ~160ms (every 10 frames at 60fps)
        frameCounter += 1
        if frameCounter % 10 == 0 {
            updateFocusedWindowID_CG()
        }
    }

    private func updateFocusedWindowFrameAX() {
        let systemWide = AXUIElementCreateSystemWide()
        
        var focusedApp: AnyObject?
        let errApp = AXUIElementCopyAttributeValue(systemWide, kAXFocusedApplicationAttribute as CFString, &focusedApp)
        guard errApp == .success, let app = focusedApp else { return }
        let appElement = app as! AXUIElement
        
        var focusedWindow: AnyObject?
        let errWin = AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &focusedWindow)
        guard errWin == .success, let window = focusedWindow else { return }
        let windowElement = window as! AXUIElement
        
        var position: AnyObject?
        var size: AnyObject?
        AXUIElementCopyAttributeValue(windowElement, kAXPositionAttribute as CFString, &position)
        AXUIElementCopyAttributeValue(windowElement, kAXSizeAttribute as CFString, &size)
        
        if let posVal = position as! AXValue?, let sizeVal = size as! AXValue? {
            var pt = CGPoint.zero
            var sz = CGSize.zero
            AXValueGetValue(posVal, .cgPoint, &pt)
            AXValueGetValue(sizeVal, .cgSize, &sz)
            
            let rect = CGRect(origin: pt, size: sz)
            
            DispatchQueue.main.async {
                if self.focusedWindowFrame != rect {
                    self.focusedWindowFrame = rect
                }
            }
        }
    }
    
    private func updateFocusedWindowID_CG() {
        guard let info = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else { return }
        
        for window in info {
            guard let layer = window[kCGWindowLayer as String] as? Int, layer == 0,
                  let ownerName = window[kCGWindowOwnerName as String] as? String,
                  ownerName != "FlowFocus",
                  let id = window[kCGWindowNumber as String] as? CGWindowID,
                  let ownerPID = window[kCGWindowOwnerPID as String] as? Int32
            else { continue }
            
            DispatchQueue.main.async {
                if self.focusedWindowID != id {
                     self.focusedWindowID = id
                     self.fetchAppWindows(pid: ownerPID)
                }
            }
            return
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
