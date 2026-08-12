import ARKit
import RealityKit
import SwiftUI

/// Det færdige resultat for én person, klar til at blive tegnet.
/// Punkterne er allerede omregnet til skærmens koordinatsystem (0–1, origo øverst til venstre).
struct PersonSnapshot: Identifiable {
    let id: Int
    let joints: [BodyPose.Joint: CGPoint]
    let bones: [(CGPoint, CGPoint)]
    let verdict: WaveVerdict
    /// Ramme omkring personen, til at placere etiketten.
    let boundingBox: CGRect
}

/// Kører AR-sessionen og samler kamera og LiDAR til én vurdering pr. person.
final class TrackingSession: NSObject, ObservableObject {

    static var isSupported: Bool {
        ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth)
    }

    @Published private(set) var people: [PersonSnapshot] = []
    @Published private(set) var isRunning = false
    @Published private(set) var statusText = "Klar. Tryk Start."
    /// Billeder pr. sekund vi når at analysere — nyttigt at kunne se, om telefonen hænger i bremsen.
    @Published private(set) var analysisRate: Double = 0

    let arView = ARView(frame: .zero)

    /// Skærmens størrelse i punkter. Uden den kan vi ikke regne skeletpunkter om til
    /// skærmkoordinater. Den skrives fra hovedtråden og læses fra analysetråden, så
    /// ændringen sendes ind på analysekøen frem for at blive sat direkte.
    private var viewportSize: CGSize = .zero

    func setViewport(_ size: CGSize) {
        processingQueue.async { self.viewportSize = size }
    }

    private let detector = BodyPoseDetector()
    private let tracker = PersonTracker()

    /// AR-billederne kommer 60 gange i sekundet. Visions kropsmodel er alt for tung til
    /// det, og et vink kræver ikke den opløsning i tid — 15 gange i sekundet er rigeligt
    /// til at fange retningsskift, og lader telefonen være kølig.
    private let targetInterval: TimeInterval = 1.0 / 15.0
    private var lastProcessed: TimeInterval = 0
    private var rateWindow: [TimeInterval] = []

    /// Al analyse foregår her, aldrig på hovedtråden.
    private let processingQueue = DispatchQueue(label: "dk.lidardemo.tracking", qos: .userInitiated)

    override init() {
        super.init()
        arView.automaticallyConfigureSession = false
        // Ved at give ARKit vores egen kø får vi billederne uden for hovedtråden, og
        // vi holder aldrig på et billede længere end selve analysen.
        arView.session.delegateQueue = processingQueue
        arView.session.delegate = self
    }

    // MARK: - Styring

    func start() {
        guard Self.isSupported else {
            statusText = "Denne enhed har ikke LiDAR."
            return
        }
        let config = ARWorldTrackingConfiguration()
        config.frameSemantics.insert(.sceneDepth)
        config.planeDetection = []

        arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        tracker.reset()
        isRunning = true
        statusText = "Ret kameraet mod en person."
    }

    func pause() {
        arView.session.pause()
        isRunning = false
        people = []
        statusText = "På pause."
    }

    // MARK: - Analysen

    private func process(frame: ARFrame) {
        guard let geometry = CameraGeometry(frame: frame) else { return }

        let poses = detector.poses(in: frame.capturedImage)
        let time = frame.timestamp

        // LiDAR-opslaget låser en buffer — den SKAL frigives igen, uanset hvordan vi forlader
        // funktionen, ellers står appen stille efter et par sekunder.
        let probe = DepthProbe(frame: frame)
        defer { probe?.release() }

        let tracked = tracker.update(poses: poses, time: time)

        let viewport = viewportSize
        let transform = viewport == .zero
            ? nil
            : frame.displayTransform(for: .portrait, viewportSize: viewport)

        var snapshots: [PersonSnapshot] = []

        for person in tracked {
            let pose = person.pose

            // Dybde på kroppens midte og hvor meget dybden varierer hen over kroppen.
            let torsoJoints: [BodyPose.Joint] = [.neck, .leftShoulder, .rightShoulder, .leftHip, .rightHip]
            var depths: [Float] = []
            for joint in torsoJoints {
                guard let point = pose.points[joint], let probe else { continue }
                let normalized = geometry.normalizedImagePoint(fromVision: point)
                if let distance = probe.robustDistance(atNormalized: normalized) {
                    depths.append(distance)
                }
            }

            let distance: Float? = depths.isEmpty ? nil : depths.sorted()[depths.count / 2]
            let spread: Float? = depths.count >= 3 ? (depths.max()! - depths.min()!) : nil

            person.verdict = person.analyzer.update(pose: pose,
                                                    distance: distance,
                                                    geometry: geometry,
                                                    bodyDepthSpread: spread,
                                                    time: time)

            snapshots.append(makeSnapshot(person: person,
                                          geometry: geometry,
                                          transform: transform))
        }

        recordRate(at: time)
        let rate = currentRate

        DispatchQueue.main.async {
            self.people = snapshots
            self.analysisRate = rate
            if !snapshots.isEmpty {
                self.statusText = snapshots.count == 1
                    ? "1 person i billedet."
                    : "\(snapshots.count) personer i billedet."
            } else {
                self.statusText = "Ingen personer set."
            }
        }
    }

    /// Regner skelettet om fra Visions koordinater til skærmens.
    private func makeSnapshot(person: TrackedPerson,
                              geometry: CameraGeometry,
                              transform: CGAffineTransform?) -> PersonSnapshot {

        func toScreen(_ visionPoint: CGPoint) -> CGPoint {
            let normalized = geometry.normalizedImagePoint(fromVision: visionPoint)
            guard let transform else { return normalized }
            return normalized.applying(transform)
        }

        var joints: [BodyPose.Joint: CGPoint] = [:]
        for (joint, point) in person.pose.points {
            joints[joint] = toScreen(point)
        }

        var bones: [(CGPoint, CGPoint)] = []
        for (a, b) in BodyPose.bones {
            guard let start = joints[a], let end = joints[b] else { continue }
            bones.append((start, end))
        }

        let xs = joints.values.map(\.x)
        let ys = joints.values.map(\.y)
        let box: CGRect
        if let minX = xs.min(), let maxX = xs.max(), let minY = ys.min(), let maxY = ys.max() {
            box = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        } else {
            box = .zero
        }

        return PersonSnapshot(id: person.id,
                              joints: joints,
                              bones: bones,
                              verdict: person.verdict,
                              boundingBox: box)
    }

    // MARK: - Målt hastighed

    private func recordRate(at time: TimeInterval) {
        rateWindow.append(time)
        rateWindow.removeAll { $0 < time - 1.0 }
    }

    private var currentRate: Double {
        Double(rateWindow.count)
    }
}

// MARK: - ARSessionDelegate

extension TrackingSession: ARSessionDelegate {

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard frame.timestamp - lastProcessed >= targetInterval else { return }
        lastProcessed = frame.timestamp
        process(frame: frame)
    }

    func session(_ session: ARSession, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.isRunning = false
            self.statusText = "Fejl: \(error.localizedDescription)"
        }
    }
}
