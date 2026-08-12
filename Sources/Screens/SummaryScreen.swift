import SwiftUI

/// Læses forpustet, ca. 40 cm fra skærmen, i en skæv vinkel. Derfor: tallet først,
/// figuren derefter, sætningen til sidst — og ingenting at fortolke.
struct SummaryScreen: View {
    let set: WorkoutSet
    var onSave: () -> Void
    /// Kun mens tallene er foreløbige: skifter mellem et godt og et dårligt sæt, så
    /// designets ærlighed kan efterprøves på enheden. Fjernes når målingerne flytter ind.
    var onToggleExample: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                Text("Sæt færdigt").eyebrow()
                    .padding(.top, 8)

                HStack(alignment: .lastTextBaseline, spacing: 10) {
                    DisplayNumber(value: "\(set.total)", size: 104)
                    Text("reps")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Palette.fg2)
                        .padding(.bottom, 12)
                }
                .padding(.top, 6)

                // Tallet mister sin hvidhed, når under halvdelen af sættet holdt.
                // Ingen rød, ingen advarsel — bare fraværet af fremhævning.
                (Text("\(set.goodCount)").fontWeight(.heavy) + Text(" med god form"))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(set.heldUp ? Palette.fg : Palette.fg2)
                    .padding(.top, 14)

                RepStrip(reps: set.reps)
                    .padding(.top, 20)
                    .contentShape(Rectangle())
                    .onTapGesture(perform: onToggleExample)

                HStack {
                    Text("Første").eyebrow()
                    Spacer()
                    Text("Sidste").eyebrow()
                }
                .padding(.top, 10)

                HStack(spacing: 10) {
                    MiniStat(label: "Ned", value: "~\(format(set.eccentric))", unit: "s")
                    MiniStat(label: "Op", value: "~\(format(set.concentric))", unit: "s")
                    MiniStat(label: "Tid", value: clock(set.duration), unit: nil)
                }
                .padding(.top, 20)

                Text(set.summarySentence)
                    .font(.system(size: 16))
                    .lineSpacing(3)
                    .foregroundStyle(Palette.fg)
                    .padding(.top, 20)

                Spacer(minLength: 20)
            }
            .padding(.horizontal, 20)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(Palette.bg)
        .safeAreaInset(edge: .bottom) {
            BottomDock { PillButton(title: "Gem sæt", action: onSave) }
        }
    }

    /// Tilden foran tallet er ikke pynt. Grænsen mellem ned og op er et skøn, og
    /// tallet skal se ud som det skøn det er.
    private func format(_ seconds: Double) -> String {
        String(format: "%.1f", seconds).replacingOccurrences(of: ".", with: ",")
    }

    private func clock(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}

private struct MiniStat: View {
    let label: String
    let value: String
    let unit: String?

    var body: some View {
        Card(padding: 16, background: Palette.card2, radius: Radius.inner) {
            Text(label).eyebrow()
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 22, weight: .heavy))
                    .monospacedDigit()
                    .tracking(-0.7)
                    .foregroundStyle(Palette.fg)
                if let unit {
                    Text(unit)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Palette.fg2)
                }
            }
            .padding(.top, 8)
        }
    }
}
