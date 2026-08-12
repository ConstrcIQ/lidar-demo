import SwiftUI

/// Tegner skeletterne og dommen oven på kamerabilledet.
struct TrackingOverlay: View {
    let people: [PersonSnapshot]
    let size: CGSize

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(people) { person in
                SkeletonShape(bones: person.bones, size: size)
                    .stroke(colour(for: person.verdict), lineWidth: 3)

                JointDots(joints: Array(person.joints.values), size: size)
                    .fill(colour(for: person.verdict))

                VerdictBadge(verdict: person.verdict, personId: person.id)
                    .position(badgePosition(for: person))
            }
        }
        .animation(.easeOut(duration: 0.12), value: people.count)
    }

    private func colour(for verdict: WaveVerdict) -> Color {
        switch verdict.confidence {
        case .confirmed: return .green
        case .cameraOnly: return .yellow
        case .lidarOnly: return .cyan
        case .none: return .white.opacity(0.75)
        }
    }

    /// Etiketten placeres over hovedet, men holdes inden for skærmen.
    private func badgePosition(for person: PersonSnapshot) -> CGPoint {
        let box = person.boundingBox
        let x = min(max((box.midX) * size.width, 90), size.width - 90)
        let y = max(box.minY * size.height - 44, 60)
        return CGPoint(x: x, y: y)
    }
}

private struct SkeletonShape: Shape {
    let bones: [(CGPoint, CGPoint)]
    let size: CGSize

    func path(in rect: CGRect) -> Path {
        var path = Path()
        for (start, end) in bones {
            path.move(to: CGPoint(x: start.x * size.width, y: start.y * size.height))
            path.addLine(to: CGPoint(x: end.x * size.width, y: end.y * size.height))
        }
        return path
    }
}

private struct JointDots: Shape {
    let joints: [CGPoint]
    let size: CGSize

    func path(in rect: CGRect) -> Path {
        var path = Path()
        for joint in joints {
            let centre = CGPoint(x: joint.x * size.width, y: joint.y * size.height)
            path.addEllipse(in: CGRect(x: centre.x - 4, y: centre.y - 4, width: 8, height: 8))
        }
        return path
    }
}

/// Den lille etiket over personen. Den viser BEGGE sensorers stemme hver for sig —
/// det er hele pointen med demoen, så det skal ikke gemmes væk i én samlet procent.
private struct VerdictBadge: View {
    let verdict: WaveVerdict
    let personId: Int

    var body: some View {
        VStack(spacing: 3) {
            Text(verdict.label)
                .font(.caption.weight(.bold))
                .foregroundStyle(verdict.isWaving ? .black : .white)

            HStack(spacing: 8) {
                ScorePill(title: "Kamera", value: verdict.cameraScore)
                ScorePill(title: "LiDAR", value: verdict.lidarScore)
            }

            if let distance = verdict.distance {
                Text(String(format: "%.2f m · %.0f cm udsving · %d skift",
                            distance, verdict.amplitudeCm, verdict.reversals))
                    .font(.system(size: 9))
                    .foregroundStyle(verdict.isWaving ? .black.opacity(0.7) : .white.opacity(0.7))
                    .monospacedDigit()
            } else {
                Text("ingen dybde")
                    .font(.system(size: 9))
                    .foregroundStyle(.orange)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(background, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(alignment: .topLeading) {
            Text("#\(personId)")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white)
                .padding(3)
                .background(.black.opacity(0.6), in: Circle())
                .offset(x: -8, y: -8)
        }
    }

    private var background: Color {
        verdict.isWaving ? .green : .black.opacity(0.55)
    }
}

private struct ScorePill: View {
    let title: String
    let value: Float

    var body: some View {
        HStack(spacing: 3) {
            Text(title)
                .font(.system(size: 9, weight: .medium))
            Text(String(format: "%.0f%%", value * 100))
                .font(.system(size: 9, weight: .bold))
                .monospacedDigit()
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(barColour, in: Capsule())
    }

    private var barColour: Color {
        value >= 0.6 ? .green.opacity(0.8) : value >= 0.3 ? .orange.opacity(0.8) : .gray.opacity(0.6)
    }
}
