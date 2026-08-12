import SwiftUI

/// Læses roligt, bagefter, i sofaen. Her må der godt være mere på skærmen —
/// men stadig ingen farve, og stadig ingen procenter på noget, der er et skøn.
struct HistoryScreen: View {
    var onBack: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                BackButton(action: onBack)
                    .padding(.top, 4)

                Text("Historik")
                    .screenTitle()
                    .padding(.top, 6)

                Card {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Rene reps, bedste").eyebrow()
                            DisplayNumber(value: "\(MockData.bestClean)", size: 40)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 8) {
                            Text("Mod sidste uge").eyebrow()
                            DisplayNumber(value: "+\(MockData.weekDelta)", size: 40)
                        }
                    }

                    TrendChart(values: MockData.trend, hollowIndices: [6])
                        .padding(.top, 20)

                    HStack {
                        Text("Uge 28"); Spacer()
                        Text("Uge 30"); Spacer()
                        Text("Uge 32"); Spacer()
                        Text("Nu")
                    }
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.fg3)
                    .padding(.top, 10)
                }
                .padding(.top, 20)

                Text("Hvad der oftest glipper").eyebrow()
                    .padding(.top, 28)

                VStack(spacing: 0) {
                    ForEach(MockData.faults) { FaultRow(fault: $0) }
                }
                .padding(.top, 4)

                Spacer(minLength: 20)
            }
            .padding(.horizontal, 20)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(Palette.bg)
        .safeAreaInset(edge: .bottom) {
            BottomDock {
                PillButton(title: "Eksportér data", style: .ghost) {}
            }
        }
    }
}
