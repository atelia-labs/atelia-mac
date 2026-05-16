import CoreText
import Foundation
import Testing
@testable import AteliaMacClient

@Test func bundledFontResourcesResolveFromSwiftPMResourceRoot() {
    let urls = ClientFontRegistrar.bundledFontURLs()
    let expectedNames = Set(ClientFontRegistrar.bundledFonts.map(\.fileName))

    #expect(Set(urls.keys) == expectedNames)

    for url in urls.values {
        #expect(FileManager.default.fileExists(atPath: url.path))
        #expect(url.pathExtension == "ttf")
        #expect(url.deletingLastPathComponent().lastPathComponent.hasSuffix(".bundle"))
    }
}

@Test func bundledFontRegistrationReportsSuccessAndExposesPostScriptNames() {
    let result = ClientFontRegistrar.registerBundledFonts()

    #expect(result.missingFonts.isEmpty)
    #expect(result.failedFonts.isEmpty)
    #expect(result.registeredFonts.count + result.alreadyRegisteredFonts.count == ClientFontRegistrar.bundledFonts.count)

    for font in ClientFontRegistrar.bundledFonts {
        let registeredFont = CTFontCreateWithName(font.postScriptName as CFString, 14, nil)
        #expect(CTFontCopyPostScriptName(registeredFont) as String == font.postScriptName)
    }
}

@Test func clientTextFontUsesBundledNotoSansJPForJapaneseFallback() {
    let result = ClientFontRegistrar.registerBundledFonts()
    #expect(result.isSuccessful)

    let baseFont = ClientFontRegistrar.clientTextFont(size: 14)
    let sample = "削除しました。" as CFString
    let fallbackFont = CTFontCreateForString(
        baseFont,
        sample,
        CFRange(location: 0, length: CFStringGetLength(sample))
    )

    #expect(CTFontCopyPostScriptName(fallbackFont) as String == ClientFontRegistrar.japaneseFallbackPostScriptName)
}
