import SwiftUI

/// Hele designets farver ét sted. Bemærk hvad der IKKE er her: en accentfarve.
///
/// Kvaliteten af en rep vises i hvid styrke — fyldt, halvgennemsigtig, kun kontur — aldrig
/// i kulør. Det er både renere at se på og sværere at lyve med: et dårligt sæt kan ikke
/// gemme sig bag en venlig farve.
enum Palette {
    static let bg      = Color.black
    static let card    = Color(red: 0.078, green: 0.078, blue: 0.086)   // #141416
    static let card2   = Color(red: 0.110, green: 0.110, blue: 0.122)   // #1C1C1F
    static let line    = Color(red: 0.165, green: 0.165, blue: 0.180)   // #2A2A2E
    static let fg      = Color.white
    static let fg2     = Color(red: 0.596, green: 0.596, blue: 0.624)   // #98989F
    static let fg3     = Color(red: 0.353, green: 0.353, blue: 0.380)   // #5A5A61
}

enum Radius {
    static let card: CGFloat = 20
    static let inner: CGFloat = 16
    static let pill: CGFloat = 999
}

// MARK: - Typografi

extension View {

    /// Den lille grå versaletikette over hvert tal.
    func eyebrow() -> some View {
        self.font(.system(size: 11, weight: .semibold))
            .tracking(1.5)
            .textCase(.uppercase)
            .foregroundStyle(Palette.fg2)
    }

    /// Skærmens overskrift. Stram og tung — det er den, der bærer udtrykket.
    func screenTitle() -> some View {
        self.font(.system(size: 32, weight: .heavy))
            .tracking(-1.1)
            .foregroundStyle(Palette.fg)
    }
}

/// Store tal. Altid med fast cifferbredde, så intet hopper sidelæns når tallet skifter.
struct DisplayNumber: View {
    let value: String
    var size: CGFloat = 64
    var color: Color = Palette.fg

    var body: some View {
        Text(value)
            .font(.system(size: size, weight: .heavy))
            .monospacedDigit()
            .tracking(size * -0.05)
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
    }
}

// MARK: - Kort

struct Card<Content: View>: View {
    var padding: CGFloat = 20
    var background: Color = Palette.card
    var radius: CGFloat = Radius.card
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) { content }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(padding)
            .background(background, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}
