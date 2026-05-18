import AppKit
import CoreText
import SwiftUI
@testable import AteliaMacClient
import Testing

@Test
func appKitTextColorTokenBridgesClientText() throws {
    let color = try #require(NSColor.clientText.usingColorSpace(.sRGB))
    let component = CGFloat(51) / 255

    #expect(abs(color.redComponent - component) < 0.0001)
    #expect(abs(color.greenComponent - component) < 0.0001)
    #expect(abs(color.blueComponent - component) < 0.0001)
    #expect(color.alphaComponent == 1)
}

@Test
func fontFallsBackToSystemWhenPreferredNameIsMissing() {
    let font = AteliaClientFont.nsFont(
        size: 15,
        weight: .semibold,
        preferredName: "Missing Atelia Client Font"
    )

    #expect(font.pointSize == 15)
    #expect(font.fontName == NSFont.systemFont(ofSize: 15, weight: .semibold).fontName)
}

@Test
func layoutConstantsMatchClientSupportContract() {
    #expect(AteliaClientDesign.supportsLightColorSchemeOnly)
    #expect(AteliaClientLayout.sidebarWidth == 270)
    #expect(AteliaClientLayout.sidebarDividerWidth == 1)
    #expect(AteliaClientLayout.contentWidth == 736)
    #expect(AteliaClientLayout.minimumWindowWidth == 1007)
    #expect(AteliaClientLayout.userBubbleMaxWidth == 566)
    #expect(AteliaClientLayout.composerMinHeight == 112)
}

@MainActor
@Test
func attributedTextConfiguresLineHeightAndSelectionContract() throws {
    let view = AteliaClientAttributedText(
        text: "Generated content",
        maxWidth: 320,
        fontSize: 13,
        lineHeight: 21
    )
    let string = view.attributedString()
    let attributes = string.attributes(at: 0, effectiveRange: nil)
    let paragraph = try #require(attributes[.paragraphStyle] as? NSParagraphStyle)

    #expect(view.isSelectable)
    #expect(paragraph.minimumLineHeight == 21)
    #expect(paragraph.maximumLineHeight == 21)
    #expect(paragraph.lineBreakMode == .byWordWrapping)
    #expect(attributes[.foregroundColor] as? NSColor == .clientText)
}

@MainActor
@Test
func attributedTextUsesJapaneseCascadeForBundledInterWeights() throws {
    let result = ClientFontRegistrar.registerBundledFonts()
    #expect(result.isSuccessful)

    let sample = "フォローアップの変更を求める"
    let sampleString = sample as CFString

    for interPostScriptName in ClientFontRegistrar.interPostScriptNames {
        let view = AteliaClientAttributedText(
            text: sample,
            maxWidth: 320,
            fontName: interPostScriptName
        )
        let font = try #require(view.attributedString().attribute(.font, at: 0, effectiveRange: nil) as? NSFont)
        let fallbackFont = CTFontCreateForString(
            font as CTFont,
            sampleString,
            CFRange(location: 0, length: CFStringGetLength(sampleString))
        )

        #expect(CTFontCopyPostScriptName(font as CTFont) as String == interPostScriptName)
        #expect(CTFontCopyPostScriptName(fallbackFont) as String == ClientFontRegistrar.japaneseFallbackPostScriptName)
    }
}

@MainActor
@Test
func clientScrollViewDocumentHeightShrinksBelowViewport() throws {
    let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 240, height: 500))
    let hostingView = NSHostingView(rootView: FixedHeightTestView())
    let coordinator = ClientScrollView<FixedHeightTestView>.Coordinator()
    coordinator.hostingView = hostingView

    coordinator.resizeDocumentView(in: scrollView)

    #expect(hostingView.frame.height == hostingView.fittingSize.height)
    #expect(hostingView.frame.height < scrollView.contentSize.height)
}

private struct FixedHeightTestView: View {
    var body: some View {
        Color.clear.frame(width: 240, height: 80)
    }
}
