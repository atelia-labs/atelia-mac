import CoreText
import Foundation

enum ClientFontRegistrar {
    static func registerBundledFonts() {
        for name in [
            "NotoSansJP",
            "Inter-Light",
            "Inter-Regular",
            "Inter-Medium",
            "Inter-SemiBold",
            "JetBrainsMono-Regular"
        ] {
            guard let fontURL = Bundle.module.url(
                forResource: name,
                withExtension: "ttf",
                subdirectory: "Fonts"
            ) else {
                continue
            }

            CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
        }
    }

    static func debugFallbackFonts() {
        let base = CTFontCreateWithName("Inter-Regular" as CFString, 14, nil)
        let samples = [
            "A",
            "AGENTS.md",
            "削除しました。",
            "フルアクセス",
            "フォローアップの変更を求める"
        ]

        for sample in samples {
            let string = sample as CFString
            let font = CTFontCreateForString(
                base,
                string,
                CFRange(location: 0, length: CFStringGetLength(string))
            )
            let postScriptName = CTFontCopyPostScriptName(font)
            print("[AteliaMacClient] fallback font:", sample, "=>", postScriptName)
        }
    }
}
