import SwiftUI
import Combine

struct BlurOverlayView: View {
    @ObservedObject var settings = SettingsManager.shared
    @ObservedObject var focusManager = WindowFocusManager.shared
    
    // Timer to force refresh UI if needed, though bindings should handle it
    let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    
    var body: some View {
        let rects = focusManager.getCutoutRects()
        
        return GeometryReader { geometry in
            ZStack {
                // Background Layer
                if settings.isDimMode {
                    Color.black.opacity(settings.dimOpacity)
                } else {
                    ZStack {
                        // hudWindow + vibrantDark appearance = Premium dark glass
                        VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                        // A very subtle tint on top
                        Color.black.opacity(0.05 + (settings.blurStrength / 300.0))
                    }
                    .opacity(settings.blurStrength / 100.0)
                }
            }
            // The cutout mask
            .mask(
                ZStack {
                    Rectangle()
                        .fill(Color.black)
                    
                    // Cutouts (Holes)
                    ForEach(rects.indices, id: \.self) { index in
                        let rect = rects[index]
                        // Convert global CG coords to local view coords
                        // Assuming the window covers the whole screen exactly matching global coords 
                        // (We need to ensure OverlayWindowController sets this up correctly)
                        // Note: CGWindowList origin is top-left of primary screen.
                        // SwiftUI GeometryReader local coords depend on window position.
                        // If window is at (0,0) of screen, they match.
                        
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
