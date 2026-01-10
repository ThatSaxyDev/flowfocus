import Cocoa
import Combine
import CoreVideo
import ApplicationServices

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
        // High-frequency polling using Accessibility API for smoothness
        updateFocusedWindowFrameAX()
        
        // Lower-frequency polling for IDs (pinning support) could go here or remain
        // For now, let's just make sure we get the frame fast.
        // We still need the ID to update 'focusedWindowID' for the FocusManager logic.
        // But running CGWindowList every 16ms is heavy.
        // We can optimize by only running CGWindowList if the App/Window *changed*, 
        // but detecting that change requires... checking.
        // Let's rely on AX for the Geometry (Visuals) and maybe run ID check less often?
        // Or just run the ID check on a throttle.
        
        // Actually, let's keep the ID check separate on a background queue/timer if possible,
        // OR just do it every N frames.
        
        struct State {
            static var counter = 0
        }
        State.counter += 1
        if State.counter % 10 == 0 { // Run ID check every ~160ms (approx)
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
                // Smooth update for visuals
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
            
            // To match AX frame with CG ID is tricky without fuzzy matching frames.
            // But usually the frontmost window in CGWindowList IS the focused window.
            
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
