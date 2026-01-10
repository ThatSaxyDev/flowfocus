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
                        
                        // Menu Bar Cutout - Animates from pill to rectangle when popover opens
                        if let mainScreen = NSScreen.main {
                            let menuBarHeight = mainScreen.frame.height - mainScreen.visibleFrame.height - mainScreen.visibleFrame.minY + mainScreen.frame.minY
                            
                            // Pill dimensions (closed state)
                            let pillWidth: CGFloat = 700
                            let pillHeight = max(menuBarHeight - 4, 24)
                            
                            // Rectangle dimensions (open state) - covers popover area
                            let popoverWidth: CGFloat = 700 // Slightly larger than popover (300)
                            let popoverHeight: CGFloat = 450 // Slightly larger than popover (400)
                            
                            // Calculate dimensions based on popover state
                            let cutoutWidth = settings.isPopoverOpen ? popoverWidth : pillWidth
                            let cutoutHeight = settings.isPopoverOpen ? popoverHeight : pillHeight
                            let cutoutX = mainScreen.frame.maxX - (settings.isPopoverOpen ? popoverWidth / 2 + 20 : pillWidth / 2 + 8)
                            let cutoutY = settings.isPopoverOpen ? (popoverHeight / 2) + menuBarHeight : menuBarHeight / 2
                            let cornerRadius: CGFloat = settings.isPopoverOpen ? 16 : pillHeight / 2
                            
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .frame(width: cutoutWidth, height: cutoutHeight)
                                .position(x: cutoutX, y: cutoutY)
                                .blendMode(.destinationOut)
                                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: settings.isPopoverOpen)
                        }
                        
                        // Cutouts (Holes) with smooth movement
                        let rects = focusManager.getCutoutRects()
                        ForEach(rects.indices, id: \.self) { index in
                            let rect = rects[index]
                            RoundedRectangle(cornerRadius: 12)
                                .frame(width: rect.width, height: rect.height) // Snug fit
                                .position(x: rect.midX, y: rect.midY)
                                .blendMode(.destinationOut)
                        }
                    }
                    .compositingGroup()
                    .animation(.interactiveSpring(response: 0.15, dampingFraction: 0.8), value: focusManager.getCutoutRects().map { "\($0)" })
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
