import SwiftUI

enum AppTheme {
    static let background = Color("AppBackground")
    static let card = Color("CardBackground")
    static let coral = Color("Coral")
    static let coralSoft = Color("CoralSoft")
    static let ink = Color("Ink")
    static let inkSecondary = Color("InkSecondary")
    static let field = Color("FieldBackground")

    static let radiusCard: CGFloat = 28
    static let radiusControl: CGFloat = 18
}

struct SoftCard: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background(AppTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous))
            .shadow(
                color: .black.opacity(colorScheme == .dark ? 0.42 : 0.08),
                radius: colorScheme == .dark ? 14 : 18,
                x: 0,
                y: 8
            )
    }
}

extension View {
    func softCard() -> some View {
        modifier(SoftCard())
    }
}
