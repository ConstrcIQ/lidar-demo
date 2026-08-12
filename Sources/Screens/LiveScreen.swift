import Combine
import SwiftUI

/// Skærmen ingen kigger på. Den skal alligevel kunne aflæses fuldstændigt på et halvt
/// sekund, skævt, fra gulvet — derfor ét tal, ingenting andet.
struct LiveScreen: View {
    var onFinish: () -> Void

    @State private var count = 0
    @State private var showHint = false

    /// Foreløbig taktslag, så skærmen kan bedømmes i bevægelse. Når rep-genkendelsen
    /// flytter ind, forsvinder denne timer og tallet kommer derfra.
    private let demoTick = Timer.publish(every: 1.6, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Palette.bg.ignoresSafeArea()

            VStack(spacing: 26) {
                Text("\(count)")
                    .font(.system(size: 190, weight: .heavy))
                    .monospacedDigit()
                    .tracking(-9)
                    .foregroundStyle(Palette.fg)
                    // Hårdt skift, ingen optælling der ruller. Et tal der animerer er
                    // et tal man skal vente på.
                    .animation(nil, value: count)

                Text("Tæller")
                    .font(.system(size: 13, weight: .semibold))
                    .tracking(2.3)
                    .textCase(.uppercase)
                    .foregroundStyle(Palette.fg2)
            }

            if showHint {
                VStack {
                    Spacer()
                    Text("Tryk for at afslutte")
                        .font(.system(size: 13))
                        .foregroundStyle(Palette.fg3)
                        .padding(.bottom, 28)
                }
                .transition(.opacity)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onFinish() }
        .onReceive(demoTick) { _ in
            if count < 14 { count += 1 }
        }
        .task {
            try? await Task.sleep(for: .seconds(2.5))
            withAnimation(.easeIn(duration: 0.4)) { showHint = true }
        }
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
    }
}
