import SwiftUI

/// Skærmens ene handling. Hver skærm har præcis én, den sidder i bunden, og den siger
/// hvad der sker — ikke hvad man kan.
struct PillButton: View {
    let title: String
    var style: Style = .solid
    let action: () -> Void

    enum Style { case solid, ghost }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .tracking(-0.2)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .foregroundStyle(style == .solid ? Palette.bg : Palette.fg)
                .background {
                    if style == .solid {
                        Capsule().fill(Palette.fg)
                    } else {
                        Capsule().stroke(Palette.line, lineWidth: 1.5)
                    }
                }
        }
        .buttonStyle(.plain)
    }
}

/// Bunden af hver skærm. Holder handlingen fri af hjemmeindikatoren.
struct BottomDock<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) { content }
            .padding(.horizontal, 20)
            .padding(.bottom, 14)
    }
}
