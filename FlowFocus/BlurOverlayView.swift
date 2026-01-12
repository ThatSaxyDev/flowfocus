import SwiftUI
import Combine

struct BlurOverlayView: View {
    @ObservedObject var settings = SettingsManager.shared
    @ObservedObject var focusManager = WindowFocusManager.shared
    
    // Timer to force refresh UI if needed, though bindings should handle it
    let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                 ZStack {
                    // Background Layer with crossfade animation
                    ZStack {
                        // Dim mode layer
                        Color.black
                            .opacity(settings.isDimMode ? settings.dimOpacity : 0)
                        
                        // Blur mode layer
                        if !settings.isDimMode {
                            VisualEffectView(material: .popover, blendingMode: .behindWindow)
                            
                            // Tint layer with smooth slider response
                            Color.black
                                .opacity(Double(settings.blurStrength) / 120.0)
                        }
                    }
                    .animation(.easeInOut(duration: 0.25), value: settings.isDimMode) // Mode switch crossfade
                    .animation(.linear(duration: 0.1), value: settings.blurStrength) // Smooth slider
                    .animation(.linear(duration: 0.1), value: settings.dimOpacity) // Smooth slider
                }
                // The cutout mask
                .mask(
                    ZStack {
                        Rectangle()
                            .fill(Color.black)
                        
                        // Menu Bar Cutout - Animates based on state:
                        // - Default: pill shape on right side
                        // - Hover at top: stretches to full width for window controls access
                        // - Popover open: expands downward for popover
                        if let mainScreen = NSScreen.main {
                            let menuBarHeight = mainScreen.frame.height - mainScreen.visibleFrame.height - mainScreen.visibleFrame.minY + mainScreen.frame.minY
                            
                            let pillHeight = max(menuBarHeight - 4, 24)
                            let popoverHeight: CGFloat = 500
                            
                            // Width: full screen when hovering, otherwise fixed width
                            let defaultWidth: CGFloat = 900
                            let fullWidth = mainScreen.frame.width + 20 // Slightly wider to ensure full coverage
                            let cutoutWidth = settings.isMenuBarHovered || settings.isPopoverOpen ? fullWidth : defaultWidth
                            
                            // Height changes for popover
                            let cutoutHeight = settings.isPopoverOpen ? popoverHeight : pillHeight
                            
                            // Position: center when full width, right-aligned otherwise
                            let rightAlignedX = mainScreen.frame.maxX - defaultWidth / 2 - 8
                            let centeredX = mainScreen.frame.midX
                            let cutoutX = settings.isMenuBarHovered || settings.isPopoverOpen ? centeredX : rightAlignedX
                            
                            let cutoutY = cutoutHeight / 2 // Top-anchored
                            let cornerRadius: CGFloat = settings.isPopoverOpen ? 16 : (settings.isMenuBarHovered ? 14 : pillHeight / 2)
                            
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .frame(width: cutoutWidth, height: cutoutHeight)
                                .position(x: cutoutX, y: cutoutY)
                                .blendMode(.destinationOut)
                                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: settings.isMenuBarHovered)
                                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: settings.isPopoverOpen)
                        }
                        
                        // Cutouts (Holes)
                        let rects = focusManager.getCutoutRects()
                        let isSingleWindow = rects.count == 1
                        
                        ForEach(rects.indices, id: \.self) { index in
                            let rect = rects[index]
                            RoundedRectangle(cornerRadius: 12)
                                .frame(width: rect.width, height: rect.height)
                                .position(x: rect.midX, y: rect.midY)
                                .blendMode(.destinationOut)
                                // Single window: smooth spring, Multi-window: subtle smooth animation
                                .animation(isSingleWindow 
                                    ? .interactiveSpring(response: 0.12, dampingFraction: 0.85) 
                                    : .easeOut(duration: 0.15), value: rect)
                        }
                    }
                    .compositingGroup()
                )
            }
        }
        .allowsHitTesting(false)
        .edgesIgnoringSafeArea(.all)
        .opacity(settings.isEnabled ? 1.0 : 0.0)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: settings.isEnabled) // Bouncy spring for toggle
        .onReceive(timer) { _ in
            focusManager.objectWillChange.send()
        }
    }
}

// Helper for NSVisualEffectView in SwiftUI
struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        // Force dark appearance for that "premium glass" look
        view.appearance = NSAppearance(named: .vibrantDark)
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
