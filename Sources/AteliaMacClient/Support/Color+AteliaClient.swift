import AppKit
import SwiftUI

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        let red = Double((hex >> 16) & 0xff) / 255
        let green = Double((hex >> 8) & 0xff) / 255
        let blue = Double(hex & 0xff) / 255
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}

extension Font {
    static func atelia(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch weight {
        case .ultraLight, .thin, .light:
            return .custom("Inter-Light", fixedSize: size)
        case .medium, .semibold, .bold, .heavy, .black:
            return .custom("Inter-Medium", fixedSize: size)
        default:
            return .custom("Inter-Regular", fixedSize: size)
        }
    }

    static func ateliaLatin(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch weight {
        case .ultraLight, .thin, .light:
            .custom("Inter-Light", fixedSize: size)
        case .semibold, .bold, .heavy, .black:
            .custom("Inter-Medium", fixedSize: size)
        case .medium:
            .custom("Inter-Medium", fixedSize: size)
        default:
            .custom("Inter-Regular", fixedSize: size)
        }
    }
}

enum CodexLayout {
    static let sidebarWidth: CGFloat = 270
    static let contentWidth: CGFloat = 736
    static let userBubbleMaxWidth: CGFloat = 566
    static let userBubbleHorizontalPadding: CGFloat = 13
    static let userBubbleVerticalPadding: CGFloat = 13
    static let topbarHeight: CGFloat = 52
    static let composerMinHeight: CGFloat = 112
    static let composerAttachmentHeight: CGFloat = 193
    static let composerFooterHeight: CGFloat = 190
}

extension Color {
    static let clientText = Color(hex: 0x333333)
    static let clientStrongText = Color(hex: 0x222222)
    static let clientMutedText = Color(hex: 0x8a8a8a)
    static let clientSubtleText = Color(hex: 0xacacac)
    static let clientLine = Color(hex: 0xececec)
    static let clientLineSoft = Color(hex: 0xf1f1f1)
    static let clientLineStrong = Color(hex: 0xe0e0e0)
    static let clientSurfaceSoft = Color(hex: 0xf4f4f4)
    static let clientSurfaceSofter = Color(hex: 0xf7f7f7)
    static let clientSidebar = Color(hex: 0xf7f7f7)
    static let clientSidebarRail = Color(hex: 0xe8e8e8)
    static let clientSidebarSelected = Color(hex: 0xe5e5e5)
    static let clientSidebarShortcut = Color(hex: 0xeeeeee)
    static let clientSidebarText = Color.black.opacity(0.58)
    static let clientSidebarIcon = Color.black.opacity(0.46)
    static let clientDockBorder = Color.black.opacity(0.075)
    static let clientDockHairline = Color.black.opacity(0.06)
    static let clientAccent = Color(hex: 0xc2255d)
    static let clientSuccess = Color(hex: 0x0b6b45)
    static let clientDanger = Color(hex: 0xb42318)
    static let clientWarning = Color(hex: 0xf15a24)
    static let clientFileMention = Color(hex: 0xc4375d)
}

extension View {
    func clientLightText() -> some View {
        fontWeight(.regular)
    }
}
