import Vision
import CoreGraphics

/// Et skelet set af kameraet i ét enkelt billede.
/// Alle punkter er i Visions koordinatsystem: normaliseret 0–1, origo nederst til venstre.
struct BodyPose {

    /// De led vi bruger. Vision kender flere, men resten er ligegyldige for et vink.
    enum Joint: CaseIterable {
        case neck, leftShoulder, rightShoulder
        case leftElbow, rightElbow
        case leftWrist, rightWrist
        case leftHip, rightHip, root

        var visionName: VNHumanBodyPoseObservation.JointName {
            switch self {
            case .neck: return .neck
            case .leftShoulder: return .leftShoulder
            case .rightShoulder: return .rightShoulder
            case .leftElbow: return .leftElbow
            case .rightElbow: return .rightElbow
            case .leftWrist: return .leftWrist
            case .rightWrist: return .rightWrist
            case .leftHip: return .leftHip
            case .rightHip: return .rightHip
            case .root: return .root
            }
        }
    }

    /// Kun led kameraet er rimeligt sikker på. Usikre led er udeladt frem for at gætte.
    private(set) var points: [Joint: CGPoint] = [:]
    private(set) var confidences: [Joint: Float] = [:]

    /// Midtpunktet mellem skuldrene — vores håndtag på personen, når vi skal genkende
    /// hende igen i næste billede.
    var centre: CGPoint {
        if let left = points[.leftShoulder], let right = points[.rightShoulder] {
            return CGPoint(x: (left.x + right.x) / 2, y: (left.y + right.y) / 2)
        }
        return points[.neck] ?? points[.root] ?? .zero
    }

    /// Hvor meget af skelettet vi faktisk fik fat i, 0–1.
    var completeness: Float {
        Float(points.count) / Float(Joint.allCases.count)
    }

    /// Skulderbredde i Vision-enheder. Bruges som groft mål for personens størrelse
    /// i billedet, når vi ikke har dybde at læne os op ad.
    var shoulderWidth: CGFloat? {
        guard let left = points[.leftShoulder], let right = points[.rightShoulder] else { return nil }
        return abs(left.x - right.x)
    }

    init(observation: VNHumanBodyPoseObservation, minimumConfidence: Float = 0.3) {
        guard let recognised = try? observation.recognizedPoints(.all) else { return }
        for joint in Joint.allCases {
            guard let point = recognised[joint.visionName],
                  point.confidence >= minimumConfidence else { continue }
            points[joint] = point.location
            confidences[joint] = point.confidence
        }
    }

    /// Knogler til optegning. Kun de par hvor begge ender blev fundet.
    static let bones: [(Joint, Joint)] = [
        (.neck, .leftShoulder), (.neck, .rightShoulder),
        (.leftShoulder, .leftElbow), (.leftElbow, .leftWrist),
        (.rightShoulder, .rightElbow), (.rightElbow, .rightWrist),
        (.leftShoulder, .leftHip), (.rightShoulder, .rightHip),
        (.leftHip, .rightHip)
    ]
}

/// Kører Visions kropsholdnings-model på et kamerabillede.
final class BodyPoseDetector {

    private let request = VNDetectHumanBodyPoseRequest()

    /// Telefonen holdes i portræt, og bagkameraets buffer er liggende. `.right` er den
    /// drejning, der rejser billedet op — bruger man en anden, står skelettet på hovedet
    /// eller på siden, og alle "hånd over skulder"-vurderinger bliver forkerte.
    func poses(in pixelBuffer: CVPixelBuffer) -> [BodyPose] {
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right)
        do {
            try handler.perform([request])
        } catch {
            return []
        }
        guard let observations = request.results else { return [] }
        return observations
            .map { BodyPose(observation: $0) }
            .filter { $0.points[.leftShoulder] != nil || $0.points[.rightShoulder] != nil }
    }
}
