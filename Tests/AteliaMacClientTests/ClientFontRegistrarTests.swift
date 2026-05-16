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
    #expect(notice.contains("NotoSansJP-VF.ttf"))
    #expect(notice.contains("NotoSansJP-Thin_Regular"))
}

@Test func bundledFontRegistrationReportsSuccessAndExposesPostScriptNames() {
    let result = ClientFontRegistrar.registerBundledFonts()

    #expect(result.missingFonts.isEmpty)
    #expect(result.failedFonts.isEmpty)
    #expect(result.registeredFonts.count + result.alreadyRegisteredFonts.count == ClientFontRegistrar.bundledFonts.count)
    #expect(ClientFontRegistrar.japaneseFallbackPostScriptName == "NotoSansJP-Thin_Regular")
    #expect(ClientFontRegistrar.bundledFonts.contains(
        ClientFontRegistrar.FontResource(
            fileName: "NotoSansJP-VF",
            postScriptName: ClientFontRegistrar.japaneseFallbackPostScriptName
        )
    ))

    for font in ClientFontRegistrar.bundledFonts {
        let registeredFont = CTFontCreateWithName(font.postScriptName as CFString, 14, nil)
        #expect(CTFontCopyPostScriptName(registeredFont) as String == font.postScriptName)
    }
}

@Test func clientTextFontUsesBundledNotoSansJPForJapaneseFallbackAcrossInterWeights() {
    let result = ClientFontRegistrar.registerBundledFonts()
    #expect(result.isSuccessful)

    let sample = "削除しました。" as CFString

    for interPostScriptName in ClientFontRegistrar.interPostScriptNames {
        let baseFont = ClientFontRegistrar.clientTextFont(named: interPostScriptName, size: 14)
        let fallbackFont = CTFontCreateForString(
            baseFont,
            sample,
            CFRange(location: 0, length: CFStringGetLength(sample))
        )

        #expect(CTFontCopyPostScriptName(baseFont) as String == interPostScriptName)
        #expect(CTFontCopyPostScriptName(fallbackFont) as String == ClientFontRegistrar.japaneseFallbackPostScriptName)
    }
}
