import AteliaMacClientModels
import SwiftUI

enum ComposerIntent: Equatable {
    case attachFile
    case selectPermissionMode(ComposerPermissionMode)
    case selectModel(ComposerModelSelection)
    case startVoiceInput
    case send(text: String, configuration: ComposerConfiguration)
}

struct ComposerView: View {
    let goal: GoalStatus
    let configuration: ComposerConfiguration
    var hasAttachment = false
    var text = ""
    var onIntent: (ComposerIntent) -> Void = { _ in }

    private var isSendEnabled: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            ComposerBody(goal: goal, hasAttachment: hasAttachment, text: text)

            HStack(spacing: 13) {
                ComposerExtensionControl {
                    onIntent(.attachFile)
                }

                Button {
                    onIntent(.selectPermissionMode(configuration.permissionMode))
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "exclamationmark.shield")
                            .font(.system(size: 14, weight: .regular))
                        Text(configuration.permissionMode.displayName)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .regular))
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("権限モード: \(configuration.permissionMode.displayName)")
                .accessibilityHint(configuration.permissionMode.permissionScope)
                .font(.atelia(13))
                .foregroundStyle(Color.clientWarning)

                Spacer()

                Image(systemName: "circle.dotted")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color.clientMutedText)
                    .accessibilityHidden(true)

                Button {
                    onIntent(.selectModel(configuration.selectedModel))
                } label: {
                    HStack(spacing: 5) {
                        Text(configuration.selectedModel.displayName)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .regular))
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("モデル: \(configuration.selectedModel.displayName)")
                .accessibilityHint(configuration.selectedModel.routeKey)
                .font(.atelia(14))
                .foregroundStyle(Color.clientText)

                PlainIconButton(
                    systemName: "mic",
                    accessibilityLabel: "音声入力",
                    accessibilityHint: "音声入力を開始"
                ) {
                    onIntent(.startVoiceInput)
                }

                Button {
                    guard isSendEnabled else { return }
                    onIntent(.send(text: text, configuration: configuration))
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.white)
                        .frame(width: 29, height: 29)
                        .background(isSendEnabled ? Color(hex: 0x0d0d0d) : Color(hex: 0x9a9a9a))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("送信")
                .accessibilityHint(isSendEnabled ? "入力内容を送信" : "入力すると送信できます")
                .disabled(!isSendEnabled)
            }
            .frame(height: 42)
            .padding(.horizontal, 12)
        }
        .frame(
            width: AteliaClientLayout.contentWidth,
            height: hasAttachment ? AteliaClientLayout.composerAttachmentHeight : AteliaClientLayout.composerMinHeight
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
    let goal: GoalStatus
    let hasAttachment: Bool
    let text: String

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "scope")
                        .font(.system(size: 12, weight: .regular))

                    Text(goal.title)
                        .font(.atelia(12))
                        .lineLimit(1)
                }
                .foregroundStyle(Color.clientMutedText)

                if text.isEmpty {
                    Text("@Global Secretary にフォローアップの変更を求める")
                        .font(.atelia(14))
                        .foregroundStyle(Color.clientSubtleText)
                }
            }
            .padding(.top, 12)
            .padding(.leading, 14)
            .padding(.trailing, 14)

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
    let accessibilityLabel: String
    let accessibilityHint: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .regular))
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(Color.clientMutedText)
                .frame(width: 17, height: 17)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
    }
}

private struct ComposerExtensionControl: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 14, weight: .regular))

                Text("拡張機能")
                    .font(.atelia(13))
            }
            .foregroundStyle(Color.clientMutedText)
            .frame(height: 26)
            .padding(.horizontal, 9)
            .background {
                Capsule()
                    .fill(Color.clientSurfaceSofter)
            }
            .overlay {
                Capsule()
                    .stroke(Color.clientDockHairline, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("ファイルを添付")
        .accessibilityHint("会話にファイルを追加")
    }
}
