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

@Test func thirdPartyFontNoticesShipInClientResourceBundle() throws {
    let url = try #require(ClientResourceBundle.thirdPartyNoticesURL())

    #expect(FileManager.default.fileExists(atPath: url.path))
    #expect(url.lastPathComponent == "THIRD_PARTY_NOTICES.md")
    #expect(url.deletingLastPathComponent().lastPathComponent.hasSuffix(".bundle"))

    let notice = try String(contentsOf: url, encoding: .utf8)
    #expect(notice.contains("SIL Open Font License, Version 1.1"))
    #expect(notice.contains("Copyright 2016 The Inter Project Authors"))
    #expect(notice.contains("Copyright 2020 The JetBrains Mono Project Authors"))
    #expect(notice.contains("Copyright: (c) 2014-2021 Adobe"))
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
