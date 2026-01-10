import SwiftUI
import Combine

class WindowFocusManager: ObservableObject {
    static let shared = WindowFocusManager()
    
    @Published var pinnedWindowIDs: Set<CGWindowID> = []
    
    private var windowTracker = WindowTracker.shared
    private var settings = SettingsManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        // Here we could add logic to auto-pin something if needed
    }
    
    func togglePin(windowID: CGWindowID) {
        if pinnedWindowIDs.contains(windowID) {
            pinnedWindowIDs.remove(windowID)
        } else {
            pinnedWindowIDs.insert(windowID)
        }
    }
    
    func clearPins() {
        pinnedWindowIDs.removeAll()
    }
    
    func shouldHighlight(windowID: CGWindowID) -> Bool {
        if !settings.isEnabled { return false }
        
        switch settings.focusMode {
        case .single:
            return windowID == windowTracker.focusedWindowID
        case .multiPin:
            return windowID == windowTracker.focusedWindowID || pinnedWindowIDs.contains(windowID)
        case .currentApp:
            return windowTracker.appWindowIDs.contains(windowID)
        }
    }
    
    // Helper to get all rects that should be clear
    func getCutoutRects() -> [CGRect] {
        guard settings.isEnabled else { return [] }
        
        guard let info = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else { return [] }
        
        var rects: [CGRect] = []
        
        for window in info {
            guard let id = window[kCGWindowNumber as String] as? CGWindowID,
                  let boundsDict = window[kCGWindowBounds as String] as? [String: Any],
                  let bounds = CGRect(dictionaryRepresentation: boundsDict as CFDictionary)
            else { continue }
            
            if shouldHighlight(windowID: id) {
                // Flip coordinate system for macOS (CGWindowList uses top-left 0,0)
                // AppKit/SwiftUI might need conversion depending on view context
                // But for a full screen overlay that matches screen coords, this might be fine
                // Actually, SwiftUI uses top-left 0,0. Cocoa uses bottom-left.
                // CGWindowList returns coords with top-left origin.
                // We'll pass it raw and let the view handle coordinate mapping if needed.
                rects.append(bounds)
            }
        }
        
        return rects
    }
    
    // Get info about pinned windows for the settings UI
    func getPinnedWindowInfo() -> [(id: CGWindowID, name: String)] {
        guard let info = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else { return [] }
        
        var result: [(id: CGWindowID, name: String)] = []
        
        for window in info {
            guard let id = window[kCGWindowNumber as String] as? CGWindowID,
                  pinnedWindowIDs.contains(id)
            else { continue }
            
            let ownerName = window[kCGWindowOwnerName as String] as? String ?? "Unknown"
            let windowName = window[kCGWindowName as String] as? String
            let displayName = windowName ?? ownerName
            
            result.append((id: id, name: displayName))
        }
        
        return result
    }
}
