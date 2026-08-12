import ARKit
import RealityKit
import SwiftUI

/// Ejer AR-sessionen og oversætter det ARKit rapporterer til noget grænsefladen kan vise.
final class ScanSession: NSObject, ObservableObject {

    /// iPhone 12 Pro og nyere Pro-modeller (inkl. 17 Pro) har LiDAR. Alt andet fejler her.
    static var deviceHasLiDAR: Bool {
        ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)
    }

    @Published private(set) var isRunning = false
    @Published private(set) var meshChunkCount = 0
    @Published private(set) var triangleCount = 0
    /// Afstand i meter til det punkt skærmens midte peger på. nil før første dybdebillede.
    @Published private(set) var centerDistance: Float?
    @Published private(set) var statusText = "Klar. Tryk Start."

    @Published var showMesh = true {
        didSet { applyMeshVisibility() }
    }

    let arView = ARView(frame: .zero)

    /// Dybdebilledet kommer 60 gange i sekundet — vi aflæser det 10 gange i sekundet.
    private var lastDepthRead = Date.distantPast
    private let depthReadInterval: TimeInterval = 0.1

    override init() {
        super.init()
        arView.session.delegate = self
        arView.automaticallyConfigureSession = false
        arView.environment.sceneUnderstanding.options = [.occlusion]
        applyMeshVisibility()
    }

    // MARK: - Styring

    func start() {
        guard Self.deviceHasLiDAR else {
            statusText = "Denne enhed har ikke LiDAR."
            return
        }

        let config = ARWorldTrackingConfiguration()
        // Byg en 3D-mesh af omgivelserne. Med klassifikation, hvis chippen kan.
        config.sceneReconstruction =
            ARWorldTrackingConfiguration.supportsSceneReconstruction(.meshWithClassification)
            ? .meshWithClassification
            : .mesh
        // Giv os også det rå dybdekort pr. billede — det er her afstandsmålingen kommer fra.
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            config.frameSemantics.insert(.sceneDepth)
        }
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .automatic

        arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        isRunning = true
        statusText = "Bevæg telefonen langsomt rundt."
    }

    func pause() {
        arView.session.pause()
        isRunning = false
        statusText = "På pause."
    }

    func reset() {
        meshChunkCount = 0
        triangleCount = 0
        centerDistance = nil
        start()
    }

    private func applyMeshVisibility() {
        arView.debugOptions = showMesh ? [.showSceneUnderstanding] : []
    }

    // MARK: - Aflæsning af det rå dybdekort

    /// Dybdekortet er et lille gråtonebillede (typisk 256×192) hvor hver pixel er
    /// afstanden i meter. Vi henter den midterste pixel.
    private func readCenterDistance(from frame: ARFrame) -> Float? {
        guard let depthMap = frame.sceneDepth?.depthMap else { return nil }

        CVPixelBufferLockBaseAddress(depthMap, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(depthMap, .readOnly) }

        guard let base = CVPixelBufferGetBaseAddress(depthMap) else { return nil }
        let width = CVPixelBufferGetWidth(depthMap)
        let height = CVPixelBufferGetHeight(depthMap)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(depthMap)

        let row = height / 2
        let column = width / 2
        let rowStart = base.advanced(by: row * bytesPerRow)
        let value = rowStart.assumingMemoryBound(to: Float32.self)[column]

        return value.isFinite && value > 0 ? value : nil
    }
}

// MARK: - ARSessionDelegate

extension ScanSession: ARSessionDelegate {

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard Date().timeIntervalSince(lastDepthRead) >= depthReadInterval else { return }
        lastDepthRead = Date()

        let distance = readCenterDistance(from: frame)
        DispatchQueue.main.async { self.centerDistance = distance }
    }

    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        recount(session)
    }

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        recount(session)
    }

    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        recount(session)
    }

    /// Hver mesh-brik er et ARMeshAnchor. ARKit tilføjer og opdaterer dem løbende,
    /// så vi tæller hele sættet forfra i stedet for at forsøge at følge med i deltaer.
    private func recount(_ session: ARSession) {
        guard let anchors = session.currentFrame?.anchors else { return }
        let meshAnchors = anchors.compactMap { $0 as? ARMeshAnchor }
        let chunks = meshAnchors.count
        let triangles = meshAnchors.reduce(0) { $0 + $1.geometry.faces.count }

        DispatchQueue.main.async {
            self.meshChunkCount = chunks
            self.triangleCount = triangles
        }
    }

    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        let message: String
        switch camera.trackingState {
        case .normal:
            message = "Scanner."
        case .notAvailable:
            message = "Sporing utilgængelig."
        case .limited(.initializing):
            message = "Starter op …"
        case .limited(.excessiveMotion):
            message = "Bevæg telefonen langsommere."
        case .limited(.insufficientFeatures):
            message = "For lidt detalje i motivet."
        case .limited(.relocalizing):
            message = "Genfinder position …"
        case .limited:
            message = "Begrænset sporing."
        }
        DispatchQueue.main.async { self.statusText = message }
    }

    func session(_ session: ARSession, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.isRunning = false
            self.statusText = "Fejl: \(error.localizedDescription)"
        }
    }
}
