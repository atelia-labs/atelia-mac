import AppKit
import SwiftUI

struct CodexAttributedText: NSViewRepresentable {
    var text: String
    var maxWidth: CGFloat
    var fontName = AteliaClientFont.interFontName(for: .regular)
    var fontSize: CGFloat = 14
    var lineHeight: CGFloat = 24
    var color = NSColor(
        calibratedRed: CGFloat(51) / 255,
        green: CGFloat(51) / 255,
        blue: CGFloat(51) / 255,
        alpha: 1
    )

    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField(labelWithString: "")
        textField.isBordered = false
        textField.isEditable = false
        textField.isSelectable = false
        textField.drawsBackground = false
        textField.lineBreakMode = .byWordWrapping
        textField.maximumNumberOfLines = 0
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textField.setContentHuggingPriority(.defaultHigh, for: .vertical)
        return textField
    }

    func updateNSView(_ textField: NSTextField, context: Context) {
        textField.preferredMaxLayoutWidth = maxWidth
        textField.attributedStringValue = attributedString()
    }

    private func attributedString() -> NSAttributedString {
        let paragraph = NSMutableParagraphStyle()
        paragraph.minimumLineHeight = lineHeight
        paragraph.maximumLineHeight = lineHeight
        paragraph.lineBreakMode = .byWordWrapping
        paragraph.alignment = .left

        return NSAttributedString(
            string: text,
            attributes: [
                .font: AteliaClientFont.nsFont(
                    size: fontSize,
                    weight: .regular,
                    preferredName: fontName
                ),
                .foregroundColor: color,
                .paragraphStyle: paragraph,
                .kern: 0
            ]
        )
    }
}
