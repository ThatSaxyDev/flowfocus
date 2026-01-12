import SwiftUI
import Combine

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @AppStorage("blurStrength") var blurStrength: Double = 50.0
    @AppStorage("isDimMode") var isDimMode: Bool = false
    @AppStorage("dimOpacity") var dimOpacity: Double = 0.5
    @AppStorage("isEnabled") var isEnabled: Bool = true
    @AppStorage("focusMode") var focusMode: FocusMode = .single
    
    // Runtime state (not persisted)
    @Published var isPopoverOpen: Bool = false
    @Published var isMenuBarHovered: Bool = false
    
    enum FocusMode: String, CaseIterable, Identifiable {
        case single = "Single Window"
        case multiPin = "Pin Windows"
        case currentApp = "Current App"
        
        var id: String { self.rawValue }
    }
    
    private init() {}
}
