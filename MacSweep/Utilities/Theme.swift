import SwiftUI

// MARK: - MacSweep Design System
// Based on Stitch designs: Dark mode, blue accent, Inter-style font, 8pt corners

struct Theme {
    // MARK: - Colors
    struct Colors {
        // Backgrounds
        static let background = Color(hex: "0D1117")
        static let cardBackground = Color(hex: "161B22")
        static let elevatedBackground = Color(hex: "21262D")
        static let sidebarBackground = Color(hex: "0D1117")
        static let headerBackground = Color(hex: "161B22")

        // Accent
        static let primaryAccent = Color(hex: "3C83F6")
        static let secondaryAccent = Color(hex: "10B981")
        static let dangerAccent = Color(hex: "EF4444")
        static let warningAccent = Color(hex: "F59E0B")
        static let orangeAccent = Color(hex: "F97316")
        static let purpleAccent = Color(hex: "8B5CF6")
        static let cyanAccent = Color(hex: "06B6D4")

        // Text
        static let primaryText = Color(hex: "F0F6FC")
        static let secondaryText = Color(hex: "8B949E")
        static let tertiaryText = Color(hex: "6E7681")

        // Borders
        static let border = Color(hex: "30363D")
        static let activeBorder = Color(hex: "3C83F6")

        // Status
        static let success = Color(hex: "10B981")
        static let critical = Color(hex: "EF4444")
        static let medium = Color(hex: "F59E0B")
        static let low = Color(hex: "3C83F6")

        // Chart
        static let chartUsed = Color(hex: "3C83F6")
        static let chartFree = Color(hex: "10B981")
        static let chartGradientStart = Color(hex: "3C83F6")
        static let chartGradientEnd = Color(hex: "06B6D4")
    }

    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
    }

    // MARK: - Corner Radius
    struct Radius {
        static let small: CGFloat = 4
        static let medium: CGFloat = 8
        static let large: CGFloat = 12
        static let xlarge: CGFloat = 16
    }

    // MARK: - Typography
    struct Typography {
        static let largeTitle = Font.system(size: 28, weight: .bold, design: .rounded)
        static let title = Font.system(size: 22, weight: .bold, design: .rounded)
        static let title2 = Font.system(size: 18, weight: .semibold, design: .rounded)
        static let headline = Font.system(size: 15, weight: .semibold)
        static let body = Font.system(size: 14, weight: .regular)
        static let callout = Font.system(size: 13, weight: .regular)
        static let caption = Font.system(size: 12, weight: .regular)
        static let overline = Font.system(size: 11, weight: .semibold)
        static let metric = Font.system(size: 36, weight: .bold, design: .rounded)
        static let metricLarge = Font.system(size: 48, weight: .bold, design: .rounded)
    }
}

// MARK: - Color Hex Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Modifiers
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.Radius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.medium)
                    .stroke(Theme.Colors.border, lineWidth: 1)
            )
    }
}

struct ElevatedCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Theme.Colors.elevatedBackground)
            .cornerRadius(Theme.Radius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.medium)
                    .stroke(Theme.Colors.border, lineWidth: 1)
            )
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }

    func elevatedCardStyle() -> some View {
        modifier(ElevatedCardStyle())
    }
}
