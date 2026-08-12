import SwiftUI

/// Appens forløb. Ét skridt ad gangen — der er aldrig to valg på skærmen samtidig.
struct ContentView: View {

    private enum Route {
        case home, placement, live, summary, history
    }

    @State private var route: Route = .home
    @State private var completedSet: WorkoutSet = MockData.goodSet
    @State private var showingBadExample = false

    var body: some View {
        ZStack {
            Palette.bg.ignoresSafeArea()

            switch route {
            case .home:
                HomeScreen(
                    onStart: { go(.placement) },
                    onHistory: { go(.history) }
                )
                .transition(.opacity)

            case .placement:
                PlacementScreen(
                    onReady: { go(.live) },
                    onBack: { go(.home) }
                )
                .transition(.opacity)

            case .live:
                LiveScreen(onFinish: {
                    completedSet = showingBadExample ? MockData.badSet : MockData.goodSet
                    go(.summary)
                })
                .transition(.opacity)

            case .summary:
                SummaryScreen(
                    set: completedSet,
                    onSave: { go(.home) },
                    onToggleExample: toggleExample
                )
                .transition(.opacity)

            case .history:
                HistoryScreen(onBack: { go(.home) })
                    .transition(.opacity)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func go(_ next: Route) {
        withAnimation(.easeInOut(duration: 0.22)) { route = next }
    }

    /// Foreløbig: lader et tryk på rep-striben skifte mellem et godt og et dårligt sæt,
    /// så designets ærlighed kan efterprøves på selve enheden. Fjernes med målingerne.
    private func toggleExample() {
        showingBadExample.toggle()
        withAnimation(.easeOut(duration: 0.25)) {
            completedSet = showingBadExample ? MockData.badSet : MockData.goodSet
        }
    }
}
