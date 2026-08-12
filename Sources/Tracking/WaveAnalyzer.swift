import CoreGraphics
import Foundation

/// Vurderingen af én person i ét øjeblik.
struct WaveVerdict {
    /// 0–1. Ligner bevægelsen et vink, sådan som kameraet ser den?
    var cameraScore: Float = 0
    /// 0–1. Bekræfter LiDAR, at der er et fysisk menneske i den rigtige afstand?
    var lidarScore: Float = 0
    /// Hvor mange gange hånden har skiftet retning inden for tidsvinduet.
    var reversals: Int = 0
    /// Vinkets bredde i centimeter, målt i den virkelige verden takket være dybden.
    var amplitudeCm: Float = 0
    /// Afstanden til personen i meter, nil hvis LiDAR ikke nåede hende.
    var distance: Float?

    /// Begge sensorer skal være enige, før vi siger ja. Kameraet alene tager fejl af
    /// alt fra en person der retter på håret til en der rækker ud efter noget.
    var isWaving: Bool { cameraScore >= 0.6 && lidarScore >= 0.5 }

    enum Confidence { case none, cameraOnly, lidarOnly, confirmed }

    var confidence: Confidence {
        switch (cameraScore >= 0.6, lidarScore >= 0.5) {
        case (true, true): return .confirmed
        case (true, false): return .cameraOnly
        case (false, true): return .lidarOnly
        case (false, false): return .none
        }
    }

    var label: String {
        switch confidence {
        case .confirmed: return "VINKER"
        case .cameraOnly: return "Måske — LiDAR bekræfter ikke"
        case .lidarOnly: return "Person set, intet vink"
        case .none: return "Ingen vinkebevægelse"
        }
    }
}

/// Afgør om en hånd vinker, ud fra hvordan den har bevæget sig over de sidste sekunder.
///
/// Et vink har tre kendetegn, som alle tre skal være opfyldt:
/// 1. Hånden er hævet — over skulderen. Det udelukker det meste almindelige armbevægelse.
/// 2. Hånden skifter retning gentagne gange. En enkelt bevægelse er at pege eller række ud.
/// 3. Udsvinget har en menneskelig størrelse i centimeter. Det er her LiDAR tjener sit navn:
///    uden afstanden ville et lillebitte vink tæt på og et stort vink langt væk se ens ud.
final class WaveAnalyzer {

    /// Et øjebliksbillede af håndens position.
    private struct Sample {
        let time: TimeInterval
        /// Håndens vandrette placering i forhold til skulderen, i Vision-enheder.
        let offset: CGFloat
        /// Var hånden hævet over skulderen?
        let raised: Bool
    }

    // Justeringsknapper — samlet ét sted, så de er til at finde og lege med.
    private let window: TimeInterval = 2.0       // hvor langt tilbage vi kigger
    private let minimumReversals = 3             // færre end tre er ikke et vink
    private let minimumAmplitudeCm: Float = 8    // mindre er skælven eller støj
    private let maximumAmplitudeCm: Float = 120  // større er hele kroppen, ikke en hånd
    private let directionDeadZone: CGFloat = 0.004 // ignorér mikroryk

    private var leftSamples: [Sample] = []
    private var rightSamples: [Sample] = []

    /// Fodrer analysen med et nyt billede og får den aktuelle vurdering tilbage.
    func update(pose: BodyPose,
                distance: Float?,
                geometry: CameraGeometry,
                bodyDepthSpread: Float?,
                time: TimeInterval) -> WaveVerdict {

        record(pose: pose, side: .right, into: &rightSamples, time: time)
        record(pose: pose, side: .left, into: &leftSamples, time: time)
        prune(before: time - window)

        // Den hånd der vinker tydeligst vinder — man vinker sjældent med begge.
        let right = evaluate(samples: rightSamples, distance: distance, geometry: geometry)
        let left = evaluate(samples: leftSamples, distance: distance, geometry: geometry)
        var verdict = right.cameraScore >= left.cameraScore ? right : left

        verdict.distance = distance
        verdict.lidarScore = lidarScore(distance: distance, spread: bodyDepthSpread)
        return verdict
    }

    func reset() {
        leftSamples.removeAll()
        rightSamples.removeAll()
    }

    // MARK: - Opsamling

    private enum Side { case left, right }

    private func record(pose: BodyPose, side: Side, into samples: inout [Sample], time: TimeInterval) {
        let wristJoint: BodyPose.Joint = side == .right ? .rightWrist : .leftWrist
        let shoulderJoint: BodyPose.Joint = side == .right ? .rightShoulder : .leftShoulder

        guard let wrist = pose.points[wristJoint],
              let shoulder = pose.points[shoulderJoint] else { return }

        // Vi måler hånden i forhold til skulderen, ikke i forhold til billedet. Så tæller
        // det ikke som et vink, når personen selv går sidelæns eller telefonen bevæger sig.
        samples.append(Sample(time: time,
                              offset: wrist.x - shoulder.x,
                              raised: wrist.y > shoulder.y))
    }

    private func prune(before cutoff: TimeInterval) {
        leftSamples.removeAll { $0.time < cutoff }
        rightSamples.removeAll { $0.time < cutoff }
    }

    // MARK: - Vurdering

    private func evaluate(samples: [Sample], distance: Float?, geometry: CameraGeometry) -> WaveVerdict {
        var verdict = WaveVerdict()
        guard samples.count >= 6 else { return verdict }

        // Kravet om hævet hånd er det billigste og skarpeste filter — tag det først.
        let raisedFraction = Float(samples.filter(\.raised).count) / Float(samples.count)
        guard raisedFraction >= 0.7 else { return verdict }

        let offsets = samples.map(\.offset)
        verdict.reversals = countReversals(offsets)

        let span = (offsets.max() ?? 0) - (offsets.min() ?? 0)
        // Uden dybde kan vi ikke omregne til centimeter. Så falder vi tilbage på en
        // grov antagelse om 2 meters afstand — og lader LiDAR-scoren afsløre usikkerheden.
        let metresPerUnit = geometry.metresPerHorizontalUnit(atDistance: distance ?? 2.0)
        verdict.amplitudeCm = Float(span * metresPerUnit * 100)

        guard verdict.reversals >= minimumReversals,
              verdict.amplitudeCm >= minimumAmplitudeCm,
              verdict.amplitudeCm <= maximumAmplitudeCm else { return verdict }

        // Scoren vokser med antallet af retningsskift og med hvor sikkert hånden var hævet.
        let reversalScore = min(1, Float(verdict.reversals - minimumReversals + 1) / 3)
        verdict.cameraScore = min(1, 0.5 * reversalScore + 0.5 * raisedFraction)
        return verdict
    }

    /// Tæller hvor mange gange bevægelsen vender. Den døde zone forhindrer, at små
    /// rystelser omkring nul tælles som hundredvis af vendinger.
    private func countReversals(_ values: [CGFloat]) -> Int {
        var reversals = 0
        var direction: Int = 0
        var anchor = values[0]

        for value in values.dropFirst() {
            let delta = value - anchor
            guard abs(delta) > directionDeadZone else { continue }
            let newDirection = delta > 0 ? 1 : -1
            if direction != 0, newDirection != direction { reversals += 1 }
            direction = newDirection
            anchor = value
        }
        return reversals
    }

    /// LiDAR's egen stemme. Den siger ikke noget om bevægelsen — den siger, om der
    /// overhovedet står et menneske af kød og blod inden for rækkevidde.
    private func lidarScore(distance: Float?, spread: Float?) -> Float {
        guard let distance else { return 0 }

        // LiDAR'en i iPhone rækker cirka fem meter. Derudover er tallene gætværk.
        let rangeScore: Float
        switch distance {
        case ..<0.4: rangeScore = 0.2      // for tæt på, kroppen fylder hele billedet
        case 0.4..<4.5: rangeScore = 1.0
        case 4.5..<5.5: rangeScore = 0.5   // yderkanten af rækkevidden
        default: rangeScore = 0.1
        }

        // Et rigtigt menneske er ikke fladt. Et ansigt på en skærm eller en plakat har
        // næsten ingen dybdeforskel mellem skulder, hoved og hånd — en person har 10–40 cm.
        let solidityScore: Float
        if let spread {
            switch spread {
            case ..<0.03: solidityScore = 0.0   // fladt: billede, skærm eller plakat
            case 0.03..<0.08: solidityScore = 0.6
            default: solidityScore = 1.0
            }
        } else {
            solidityScore = 0.3                 // for få gyldige dybdepunkter til at afgøre det
        }

        return min(1, 0.5 * rangeScore + 0.5 * solidityScore)
    }
}
