import RealityKit
import SwiftUI

/// Bygger bro mellem RealityKits ARView (UIKit) og SwiftUI.
struct ARViewContainer: UIViewRepresentable {
    let arView: ARView

    func makeUIView(context: Context) -> ARView { arView }

    func updateUIView(_ uiView: ARView, context: Context) {}
}
