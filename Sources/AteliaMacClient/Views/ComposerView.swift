import SwiftUI

struct ComposerView: View {
    let goal: GoalStatus
    var hasAttachment = false
    var text = ""

    private var isSendEnabled: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            ComposerBody(hasAttachment: hasAttachment, text: text)

            HStack(spacing: 13) {
                PlainIconButton(systemName: "plus")

                HStack(spacing: 5) {
                    Image(systemName: "exclamationmark.shield")
                        .font(.system(size: 14, weight: .regular))
                    Text("フルアクセス")
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .regular))
                }
                .font(.atelia(13))
                .foregroundStyle(Color.clientWarning)

                Spacer()

                Image(systemName: "circle.dotted")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color.clientMutedText)

                HStack(spacing: 5) {
                    Text("5.5 中")
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .regular))
                }
                .font(.atelia(14))
                .foregroundStyle(Color.clientText)

                PlainIconButton(systemName: "mic")

                Button {} label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.white)
                        .frame(width: 29, height: 29)
                        .background(isSendEnabled ? Color(hex: 0x0d0d0d) : Color(hex: 0x9a9a9a))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .frame(height: 42)
            .padding(.horizontal, 12)
        }
        .frame(
            width: CodexLayout.contentWidth,
            height: hasAttachment ? CodexLayout.composerAttachmentHeight : CodexLayout.composerMinHeight
        )
        .background {
            ComposerSurface()
        }
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.clientDockBorder, lineWidth: 1)
        }
    }
}

private struct ComposerSurface: View {
    var body: some View {
        VisualEffectView(material: .contentBackground, blendingMode: .withinWindow)
            .overlay(Color.white.opacity(0.94))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color.black.opacity(0.02), radius: 2, x: 0, y: 1)
    }
}

private struct ComposerBody: View {
    let hasAttachment: Bool
    let text: String

    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text("フォローアップの変更を求める")
                    .font(.atelia(14))
                    .foregroundStyle(Color.clientSubtleText)
                    .padding(.top, 13)
                    .padding(.leading, 14)
            }

            if hasAttachment {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                    .frame(width: 84, height: 82)
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.clientLine, lineWidth: 1)
                    }
                    .padding(.top, 10)
                    .padding(.leading, 13)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct PlainIconButton: View {
    let systemName: String

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 15, weight: .regular))
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(Color.clientMutedText)
            .frame(width: 17, height: 17)
    }
}
