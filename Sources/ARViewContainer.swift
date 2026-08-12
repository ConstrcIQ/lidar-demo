import RealityKit
import SwiftUI

/// Bygger bro mellem RealityKits ARView (UIKit) og SwiftUI.
struct ARViewContainer: UIViewRepresentable {
    let session: ScanSession

    func makeUIView(context: Context) -> ARView {
        session.arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}
}
