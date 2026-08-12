import ARKit
import CoreVideo

/// Slår op i LiDAR-dybdekortet. Kortet er et lille gråtonebillede (typisk 256×192),
/// hvor hver pixel er afstanden i meter, og det ligger i samme retning og
/// billedformat som den rå kamerabuffer.
struct DepthProbe {

    private let depthMap: CVPixelBuffer
    private let confidenceMap: CVPixelBuffer?
    private let width: Int
    private let height: Int
    private let bytesPerRow: Int
    private let base: UnsafeMutableRawPointer

    /// Sandhedens øjeblik: uden LiDAR er der ingen `sceneDepth`, og så findes proben ikke.
    init?(frame: ARFrame) {
        guard let depth = frame.sceneDepth else { return nil }
        depthMap = depth.depthMap
        confidenceMap = depth.confidenceMap

        guard CVPixelBufferLockBaseAddress(depthMap, .readOnly) == kCVReturnSuccess else { return nil }
        guard let address = CVPixelBufferGetBaseAddress(depthMap) else {
            CVPixelBufferUnlockBaseAddress(depthMap, .readOnly)
            return nil
        }
        base = address
        width = CVPixelBufferGetWidth(depthMap)
        height = CVPixelBufferGetHeight(depthMap)
        bytesPerRow = CVPixelBufferGetBytesPerRow(depthMap)
    }

    /// SKAL kaldes, når man er færdig — ellers lækkes en låst buffer pr. billede,
    /// og appen går i stå efter få sekunder.
    func release() {
        CVPixelBufferUnlockBaseAddress(depthMap, .readOnly)
    }

    /// Afstand i meter på et normaliseret punkt i den rå buffer (origo øverst til venstre).
    /// Returnerer nil hvor LiDAR ikke fik svar — typisk glas, blanke flader, eller for langt væk.
    func distance(atNormalized point: CGPoint) -> Float? {
        let column = Int((point.x * CGFloat(width)).rounded())
        let row = Int((point.y * CGFloat(height)).rounded())
        guard column >= 0, column < width, row >= 0, row < height else { return nil }

        let rowStart = base.advanced(by: row * bytesPerRow)
        let value = rowStart.assumingMemoryBound(to: Float32.self)[column]
        guard value.isFinite, value > 0.1, value < 8 else { return nil }
        return value
    }

    /// Medianafstanden i et lille kvadrat omkring punktet. Et enkelt pixelopslag på en
    /// håndled hopper voldsomt, fordi kanten af en arm ofte rammer baggrunden — medianen
    /// af naboerne er langt mere stabil.
    func robustDistance(atNormalized point: CGPoint, radius: Int = 2) -> Float? {
        let centreColumn = Int((point.x * CGFloat(width)).rounded())
        let centreRow = Int((point.y * CGFloat(height)).rounded())

        var samples: [Float] = []
        for row in (centreRow - radius)...(centreRow + radius) {
            guard row >= 0, row < height else { continue }
            let rowStart = base.advanced(by: row * bytesPerRow)
                .assumingMemoryBound(to: Float32.self)
            for column in (centreColumn - radius)...(centreColumn + radius) {
                guard column >= 0, column < width else { continue }
                let value = rowStart[column]
                if value.isFinite, value > 0.1, value < 8 { samples.append(value) }
            }
        }

        guard !samples.isEmpty else { return nil }
        samples.sort()
        return samples[samples.count / 2]
    }
}
