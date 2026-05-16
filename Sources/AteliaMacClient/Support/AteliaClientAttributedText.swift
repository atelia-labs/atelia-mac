import AppKit
import SwiftUI

struct AteliaClientAttributedText: NSViewRepresentable {
    var text: String
    var maxWidth: CGFloat
    var fontName: String? = nil
    var fontSize: CGFloat = 14
    var lineHeight: CGFloat = 24
    var color = NSColor.clientText
    var isSelectable = true

    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField(labelWithString: "")
        textField.isBordered = false
        textField.isEditable = false
        textField.isSelectable = isSelectable
        textField.drawsBackground = false
        textField.lineBreakMode = .byWordWrapping
        textField.maximumNumberOfLines = 0
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textField.setContentHuggingPriority(.defaultHigh, for: .vertical)
        return textField
    }

    func updateNSView(_ textField: NSTextField, context: Context) {
        textField.preferredMaxLayoutWidth = maxWidth
        textField.isSelectable = isSelectable
        textField.attributedStringValue = attributedString()
    }

    func attributedString() -> NSAttributedString {
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
