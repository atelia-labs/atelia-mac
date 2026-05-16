import CoreText
import Foundation
import os

enum ClientFontRegistrar {
    struct FontResource: Equatable {
        let fileName: String
        let postScriptName: String
    }

    struct RegistrationFailure: Equatable {
        let fileName: String
        let url: URL
        let domain: String
        let code: Int
        let message: String
    }

    struct RegistrationResult: Equatable {
        let registeredFonts: [String]
        let alreadyRegisteredFonts: [String]
        let missingFonts: [String]
        let failedFonts: [RegistrationFailure]

        var isSuccessful: Bool {
            missingFonts.isEmpty && failedFonts.isEmpty
        }
    }

    static let interRegularPostScriptName = "Inter-Regular"
    static let japaneseFallbackPostScriptName = "NotoSansJP-Thin"

    static let bundledFonts = [
        FontResource(fileName: "NotoSansJP", postScriptName: japaneseFallbackPostScriptName),
        FontResource(fileName: "Inter-Light", postScriptName: "Inter-Light"),
        FontResource(fileName: interRegularPostScriptName, postScriptName: interRegularPostScriptName),
        FontResource(fileName: "Inter-Medium", postScriptName: "Inter-Medium"),
        FontResource(fileName: "Inter-SemiBold", postScriptName: "Inter-SemiBold"),
        FontResource(fileName: "JetBrainsMono-Regular", postScriptName: "JetBrainsMono-Regular")
    ]

    private static let logger = Logger(subsystem: "com.atelia.mac.client", category: "Fonts")

    static func bundledFontURL(for font: FontResource, in bundle: Bundle = .module) -> URL? {
        if let url = bundle.url(forResource: font.fileName, withExtension: "ttf") {
            return url
        }

        return bundle.url(forResource: font.fileName, withExtension: "ttf", subdirectory: "Fonts")
    }

    static func bundledFontURLs(in bundle: Bundle = .module) -> [String: URL] {
        Dictionary(
            uniqueKeysWithValues: bundledFonts.compactMap { font in
                guard let url = bundledFontURL(for: font, in: bundle) else {
                    return nil
                }

                return (font.fileName, url)
            }
        )
    }

    @discardableResult
    static func registerBundledFonts(bundle: Bundle = .module) -> RegistrationResult {
        var registeredFonts: [String] = []
        var alreadyRegisteredFonts: [String] = []
        var missingFonts: [String] = []
        var failedFonts: [RegistrationFailure] = []

        for font in bundledFonts {
            guard let fontURL = bundledFontURL(for: font, in: bundle) else {
                missingFonts.append(font.fileName)
                logger.error("Missing bundled font resource: \(font.fileName, privacy: .public).ttf")
                continue
            }

            var registrationError: Unmanaged<CFError>?
            let didRegister = CTFontManagerRegisterFontsForURL(
                fontURL as CFURL,
                .process,
                &registrationError
            )

            if didRegister {
                registeredFonts.append(font.postScriptName)
                continue
            }

            guard let error = registrationError?.takeRetainedValue() else {
                let failure = RegistrationFailure(
                    fileName: font.fileName,
                    url: fontURL,
                    domain: "CoreText",
                    code: -1,
                    message: "CTFontManagerRegisterFontsForURL returned false without an error."
                )
                failedFonts.append(failure)
                logger.error("Failed to register bundled font \(font.fileName, privacy: .public): \(failure.message, privacy: .public)")
                continue
            }

            let nsError = error as Error as NSError
            if nsError.domain == String(kCTFontManagerErrorDomain),
               nsError.code == CTFontManagerError.alreadyRegistered.rawValue {
                alreadyRegisteredFonts.append(font.postScriptName)
                continue
            }

            let failure = RegistrationFailure(
                fileName: font.fileName,
                url: fontURL,
                domain: nsError.domain,
                code: nsError.code,
                message: nsError.localizedDescription
            )
            failedFonts.append(failure)
            logger.error(
                "Failed to register bundled font \(font.fileName, privacy: .public) at \(fontURL.path, privacy: .public): \(failure.domain, privacy: .public) \(failure.code) \(failure.message, privacy: .public)"
            )
        }

        return RegistrationResult(
            registeredFonts: registeredFonts,
            alreadyRegisteredFonts: alreadyRegisteredFonts,
            missingFonts: missingFonts,
            failedFonts: failedFonts
        )
    }

    static func clientTextFont(size: CGFloat) -> CTFont {
        let baseDescriptor = CTFontDescriptorCreateWithNameAndSize(
            interRegularPostScriptName as CFString,
            size
        )
        let japaneseDescriptor = CTFontDescriptorCreateWithNameAndSize(
            japaneseFallbackPostScriptName as CFString,
            size
        )
        let descriptor = CTFontDescriptorCreateCopyWithAttributes(
            baseDescriptor,
            [kCTFontCascadeListAttribute: [japaneseDescriptor]] as CFDictionary
        )

        return CTFontCreateWithFontDescriptor(descriptor, size, nil)
    }

    static func debugFallbackFonts() {
        let base = clientTextFont(size: 14)
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
