import SwiftUI

/// Sættets forløb som én figur — én søjle pr. rep, i den rækkefølge de blev lavet.
///
/// Kvaliteten aflæses i to uafhængige kanaler på samme tid: **højde** og **fylde**.
/// Det er med vilje. Ligger man på gulvet og kigger skævt på en skærm med genskin, kan
/// den ene kanal falde ud — og så kan figuren stadig læses på den anden.
struct RepStrip: View {
    let reps: [Rep]
    var height: CGFloat = 88
    var spacing: CGFloat = 5

    var body: some View {
        HStack(alignment: .bottom, spacing: spacing) {
            ForEach(reps) { rep in
                bar(for: rep.quality)
            }
        }
        .frame(height: height, alignment: .bottom)
        .animation(.easeOut(duration: 0.25), value: reps.count)
    }

    @ViewBuilder
    private func bar(for quality: RepQuality) -> some View {
        let shape = RoundedRectangle(cornerRadius: 3, style: .continuous)

        switch quality {
        case .full:
            shape.fill(Palette.fg)
                .frame(height: height)
        case .partial:
            shape.fill(Palette.fg.opacity(0.38))
                .frame(height: height * 0.64)
        case .low:
            shape.stroke(Palette.fg.opacity(0.42), lineWidth: 1.5)
                .frame(height: height * 0.32)
        }
    }
}

/// Historikkens graf. Samme grammatik som rep-striben, bare én søjle pr. session —
/// så den, der har set striben danne sig under et sæt, kan læse grafen uden forklaring.
struct TrendChart: View {
    let values: [Int]
    /// Sessioner hvor under halvdelen af reppene var rene tegnes hule. Højden — som er
    /// en eksakt optælling — vises stadig præcist. Det er kun rosen, der holdes tilbage.
    var hollowIndices: Set<Int> = []
    var height: CGFloat = 150

    var body: some View {
        let peak = max(values.max() ?? 1, 1)

        HStack(alignment: .bottom, spacing: 8) {
            ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                let h = height * CGFloat(value) / CGFloat(peak)
                Group {
                    if hollowIndices.contains(index) {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .stroke(Palette.fg.opacity(0.4), lineWidth: 1.5)
                    } else {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(Palette.fg)
                    }
                }
                .frame(height: max(h, 6))
            }
        }
        .frame(height: height, alignment: .bottom)
    }
}

/// En fejl og hvor ofte den optræder. Måleren er ikke pynt — den lader rækkefølgen
/// aflæses uden at læse tallene.
struct FaultRow: View {
    let fault: FaultTally

    var body: some View {
        HStack(spacing: 14) {
            Text(fault.name)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Palette.fg)

            Spacer(minLength: 8)

            Capsule()
                .fill(Palette.line)
                .frame(width: 72, height: 5)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(Palette.fg)
                        .frame(width: 72 * fault.share, height: 5)
                }

            Text("\(Int(fault.share * 100))%")
                .font(.system(size: 13))
                .monospacedDigit()
                .foregroundStyle(Palette.fg2)
                .frame(width: 38, alignment: .trailing)
        }
        .padding(.vertical, 14)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Palette.line).frame(height: 1)
        }
    }
}
