import SwiftUI

struct HomeScreen: View {
    var onStart: () -> Void
    var onHistory: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            Text("Armbøjninger")
                .screenTitle()
                .padding(.top, 8)

            Card {
                Text("Dage i træk").eyebrow()
                HStack(alignment: .lastTextBaseline) {
                    DisplayNumber(value: "\(MockData.streak)", size: 64)
                    Spacer()
                    Text("bedste: \(MockData.bestStreak)")
                        .font(.system(size: 14))
                        .foregroundStyle(Palette.fg2)
                }
                .padding(.top, 10)
            }
            .padding(.top, 22)

            Button(action: onHistory) {
                HStack {
                    Text("Seneste sæt").eyebrow()
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Palette.fg3)
                }
            }
            .buttonStyle(.plain)
            .padding(.top, 30)

            VStack(spacing: 0) {
                ForEach(Array(MockData.recentSessions.enumerated()), id: \.offset) { index, session in
                    SessionRow(day: session.day, total: session.total, good: session.good)
                    if index < MockData.recentSessions.count - 1 {
                        Rectangle().fill(Palette.line).frame(height: 1)
                    }
                }
            }
            .padding(.top, 6)

            Spacer(minLength: 24)
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Palette.bg)
        .safeAreaInset(edge: .bottom) {
            BottomDock { PillButton(title: "Start sæt", action: onStart) }
        }
    }
}

private struct SessionRow: View {
    let day: String
    let total: Int
    let good: Int

    /// Faldt over halvdelen igennem, mister tallet sin hvidhed. Ingen alarmfarve —
    /// bare fraværet af den fremhævning, en god session får.
    private var heldUp: Bool { Double(good) / Double(total) >= 0.5 }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(day)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Palette.fg)
                Text("\(total) reps · \(good) med god form")
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.fg2)
            }
            Spacer()
            Text("\(total)")
                .font(.system(size: heldUp ? 19 : 15, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(heldUp ? Palette.fg : Palette.fg2)
        }
        .padding(.vertical, 15)
    }
}
