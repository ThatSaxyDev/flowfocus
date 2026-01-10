import SwiftUI
import Combine

struct BlurOverlayView: View {
    @ObservedObject var settings = SettingsManager.shared
    @ObservedObject var focusManager = WindowFocusManager.shared
    
    // Timer to force refresh UI if needed, though bindings should handle it
    let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            if settings.isEnabled {
                GeometryReader { geometry in
                     ZStack {
                        // Background Layer
                        if settings.isDimMode {
                            Color.black.opacity(settings.dimOpacity)
                        } else {
                            ZStack {
                                // "popover" material is often cleaner/blurrier than hudWindow
                                VisualEffectView(material: .popover, blendingMode: .behindWindow)
                                    .opacity(1.0) // Keep blur full strength to avoid "fading out" of the blur radius
                                
                                // Use the slider to control the DARKNESS/TINT instead of blur opacity
                                Color.black.opacity(Double(settings.blurStrength) / 120.0) // 0 to ~0.8 opacity
                            }
                        }
                    }
                    // The cutout mask
                    .mask(
                        ZStack {
                            Rectangle()
                                .fill(Color.black)
                            
                            // Cutouts (Holes)
                            let rects = focusManager.getCutoutRects()
                            ForEach(rects.indices, id: \.self) { index in
                                let rect = rects[index]
                                RoundedRectangle(cornerRadius: 10)
                                    .frame(width: rect.width, height: rect.height)
                                    .position(x: rect.midX, y: rect.midY)
                                    .blendMode(.destinationOut)
                            }
                        }
                        .compositingGroup() // Important for destinationOut to work on the mask container
                    )
                }
                .allowsHitTesting(false) // Let clicks pass through!
                .edgesIgnoringSafeArea(.all)
            }
        }
        .onReceive(timer) { _ in
            // Force redraw logic handled by ObservableObject, 
            // but we need to ensure the getCutoutRects() calculation is triggered/refreshing view.
            // Since getCutoutRects accesses WindowTracker which publishes updates, 
            // we need to make sure this View observes those updates.
            // focusManager observes WindowTracker but getCutoutRects runs on demand.
            // We need focusManager to publish when rects change.
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
