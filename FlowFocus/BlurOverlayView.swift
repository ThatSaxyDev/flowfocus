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
                        
                        // Menu Bar Cutout - Pill shape on the RIGHT side only (status icons area)
                        if let mainScreen = NSScreen.main {
                            let menuBarHeight = mainScreen.frame.height - mainScreen.visibleFrame.height - mainScreen.visibleFrame.minY + mainScreen.frame.minY
                            let pillWidth: CGFloat = 500
                            let pillHeight = max(menuBarHeight - 4, 24)
                            let pillX = mainScreen.frame.maxX - (pillWidth / 2) - 8
                            let pillY = (menuBarHeight / 2)
                            
                            Capsule()
                                .frame(width: pillWidth, height: pillHeight)
                                .position(x: pillX, y: pillY)
                                .blendMode(.destinationOut)
                        }
                        
                        // Cutouts (Holes) with smooth movement
                        let rects = focusManager.getCutoutRects()
                        ForEach(rects.indices, id: \.self) { index in
                            let rect = rects[index]
                            RoundedRectangle(cornerRadius: 12)
                                .frame(width: rect.width + 8, height: rect.height + 8) // Slight padding
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
