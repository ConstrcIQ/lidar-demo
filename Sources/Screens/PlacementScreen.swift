import SwiftUI

/// Den eneste skærm brugeren kigger på, før hun lægger sig ned. Alt herefter er lyd.
struct PlacementScreen: View {
    var onReady: () -> Void
    var onBack: () -> Void

    /// Foreløbigt sat til opfyldt. Når målingerne flytter ind, kommer de herfra.
    private let checks: [(String, Bool)] = [
        ("Afstand — 1,2 m", true),
        ("Hele kroppen er med", true),
        ("Gulvet er fundet", true)
    ]

    private var ready: Bool { checks.allSatisfy(\.1) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            BackButton(action: onBack)
                .padding(.top, 4)

            Text("Stil telefonen\nfra siden")
                .screenTitle()
                .padding(.top, 10)

            ViewfinderBox(ready: ready)
                .padding(.top, 18)

            VStack(spacing: 0) {
                ForEach(Array(checks.enumerated()), id: \.offset) { index, check in
                    HStack(spacing: 12) {
                        Tick(on: check.1)
                        Text(check.0)
                            .font(.system(size: 15))
                            .foregroundStyle(Palette.fg)
                        Spacer()
                    }
                    .padding(.vertical, 13)
                    if index < checks.count - 1 {
                        Rectangle().fill(Palette.line).frame(height: 1)
                    }
                }
            }
            .padding(.top, 10)

            Spacer(minLength: 16)
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Palette.bg)
        .safeAreaInset(edge: .bottom) {
            BottomDock {
                PillButton(title: ready ? "Klar — begynd" : "Ret telefonen ind",
                           style: ready ? .solid : .ghost,
                           action: onReady)
                    .disabled(!ready)
            }
        }
    }
}

/// Antydningen af kameraets billede med en person i planke. Rammen er hel, når
/// alt er på plads, og stiplet mens der stadig mangler noget.
private struct ViewfinderBox: View {
    let ready: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Palette.card)

            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(ready ? Palette.fg.opacity(0.9) : Palette.fg3,
                              style: StrokeStyle(lineWidth: 2, dash: ready ? [] : [6, 5]))
                .padding(22)

            PlankGlyph()
                .frame(width: 150, height: 60)
        }
        .frame(height: 300)
    }
}

private struct PlankGlyph: View {
    var body: some View {
        Canvas { context, size in
            let ink = Color.white.opacity(0.16)
            let scaleX = size.width / 150
            let scaleY = size.height / 60

            var torso = Path()
            torso.addRoundedRect(in: CGRect(x: 34 * scaleX, y: 20 * scaleY,
                                            width: 76 * scaleX, height: 15 * scaleY),
                                 cornerSize: CGSize(width: 7 * scaleX, height: 7 * scaleY))
            context.fill(torso, with: .color(ink))

            var head = Path()
            head.addEllipse(in: CGRect(x: 19 * scaleX, y: 18 * scaleY,
                                       width: 18 * scaleX, height: 18 * scaleY))
            context.fill(head, with: .color(ink))

            var limbs = Path()
            limbs.move(to: CGPoint(x: 46 * scaleX, y: 35 * scaleY))
            limbs.addLine(to: CGPoint(x: 40 * scaleX, y: 54 * scaleY))
            limbs.move(to: CGPoint(x: 104 * scaleX, y: 35 * scaleY))
            limbs.addLine(to: CGPoint(x: 112 * scaleX, y: 54 * scaleY))
            context.stroke(limbs, with: .color(ink),
                           style: StrokeStyle(lineWidth: 6 * scaleX, lineCap: .round))
        }
    }
}

private struct Tick: View {
    let on: Bool

    var body: some View {
        ZStack {
            if on {
                Circle().fill(Palette.fg)
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(Palette.bg)
            } else {
                Circle().strokeBorder(Palette.fg3, lineWidth: 1.5)
            }
        }
        .frame(width: 22, height: 22)
    }
}

struct BackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Palette.fg2)
                .frame(width: 40, height: 40, alignment: .leading)
        }
        .buttonStyle(.plain)
    }
}
