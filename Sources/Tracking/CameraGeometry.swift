import ARKit
import CoreGraphics

/// Oversætter mellem de tre koordinatsystemer vi arbejder i:
///
/// 1. **Rå kamerabuffer** — liggende (fx 1920×1440), origo øverst til venstre. Det er her
///    kameraets linsedata (intrinsics) og LiDAR-dybdekortet hører hjemme.
/// 2. **Vision** — billedet rejst op i portræt, normaliseret 0–1, origo NEDERST til venstre,
///    y peger opad. Det er her skeletpunkterne kommer ud.
/// 3. **Skærmen** — hvad brugeren faktisk ser, efter ARView har beskåret billedet.
///
/// Alt det fnidder samles her, så resten af koden slipper for det.
struct CameraGeometry {

    /// Den rå buffers bredde i pixels (den lange, liggende led).
    let imageWidth: CGFloat
    /// Den rå buffers højde i pixels.
    let imageHeight: CGFloat
    /// Brændvidde i pixels, vandret og lodret i den rå buffer.
    let fx: CGFloat
    let fy: CGFloat

    init?(frame: ARFrame) {
        let resolution = frame.camera.imageResolution
        guard resolution.width > 0, resolution.height > 0 else { return nil }
        imageWidth = resolution.width
        imageHeight = resolution.height
        let k = frame.camera.intrinsics
        fx = CGFloat(k[0][0])
        fy = CGFloat(k[1][1])
        guard fx > 0, fy > 0 else { return nil }
    }

    // MARK: - Vision → rå buffer

    /// Vision leverer punkter i det oprejste billede. Telefonen holdes i portræt, så det
    /// oprejste billede er den rå buffer drejet 90° med uret. Regner man den drejning
    /// baglæns, ender man her.
    func normalizedImagePoint(fromVision point: CGPoint) -> CGPoint {
        CGPoint(x: 1 - point.y, y: 1 - point.x)
    }

    /// Samme punkt, men i faktiske pixels i den rå buffer.
    func bufferPixel(fromVision point: CGPoint) -> CGPoint {
        let n = normalizedImagePoint(fromVision: point)
        return CGPoint(x: n.x * imageWidth, y: n.y * imageHeight)
    }

    // MARK: - Pixels → meter

    /// Hvor mange meter svarer ét skridt i Visions vandrette akse til, når motivet
    /// står `distance` meter væk?
    ///
    /// Hulkamera-modellen siger: meter = pixels × afstand ÷ brændvidde. Visions vandrette
    /// akse løber langs den rå buffers LODRETTE led (fordi billedet er drejet), så det er
    /// `imageHeight` og `fy` der skal bruges — ikke `fx`. Bytter man rundt her, bliver alle
    /// målinger skæve med en faktor 4/3, og det ses ikke uden at måle efter.
    func metresPerHorizontalUnit(atDistance distance: Float) -> CGFloat {
        imageHeight * CGFloat(distance) / fy
    }

    /// Det samme for Visions lodrette akse.
    func metresPerVerticalUnit(atDistance distance: Float) -> CGFloat {
        imageWidth * CGFloat(distance) / fx
    }

    /// Afstanden mellem to Vision-punkter, omregnet til meter i motivets plan.
    func metres(between a: CGPoint, and b: CGPoint, atDistance distance: Float) -> CGFloat {
        let dx = (a.x - b.x) * metresPerHorizontalUnit(atDistance: distance)
        let dy = (a.y - b.y) * metresPerVerticalUnit(atDistance: distance)
        return sqrt(dx * dx + dy * dy)
    }
}
