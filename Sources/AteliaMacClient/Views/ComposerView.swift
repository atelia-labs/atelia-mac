import AteliaMacClientModels
import SwiftUI

enum ComposerIntent: Equatable {
    case attachFile
    case insertMention(String)
    case openContext(ComposerContextSelection)
    case selectPermissionMode(ComposerPermissionMode)
    case selectModel(ComposerModelSelection)
    case startVoiceInput
    case send(text: String, configuration: ComposerConfiguration, contexts: [ComposerContextSelection])
}

struct ComposerView: View {
    let goal: GoalStatus
    let configuration: ComposerConfiguration
    var hasAttachment = false
    var onIntent: (ComposerIntent) -> Void = { _ in }

    @State private var draftText: String
    @State private var selectedContexts: [ComposerContextSelection] = []

    init(
        goal: GoalStatus,
        configuration: ComposerConfiguration,
        hasAttachment: Bool = false,
        text: String = "",
        onIntent: @escaping (ComposerIntent) -> Void = { _ in }
    ) {
        self.goal = goal
        self.configuration = configuration
        self.hasAttachment = hasAttachment || configuration.attachmentPreview != nil
        self.onIntent = onIntent
        _draftText = State(initialValue: text)
        _selectedContexts = State(initialValue: configuration.visibleContextSelections)
    }

    private var isSendEnabled: Bool {
        !draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            ComposerBody(
                goal: goal,
                hasAttachment: hasAttachment,
                draftText: $draftText,
                selectedContexts: $selectedContexts,
                contextReferences: configuration.contextReferences,
                attachmentPreview: configuration.attachmentPreview,
                onIntent: onIntent
            )

            HStack(spacing: 13) {
                ComposerAttachmentButton {
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
                    onIntent(.send(text: draftText, configuration: configuration, contexts: selectedContexts))
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
        .onChange(of: configuration) { _, newConfiguration in
            selectedContexts = newConfiguration.visibleContextSelections
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
    @Binding var draftText: String
    @Binding var selectedContexts: [ComposerContextSelection]
    let contextReferences: [ComposerContextReference]
    let attachmentPreview: ComposerAttachmentPreview?
    let onIntent: (ComposerIntent) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if hasAttachment {
                ComposerAttachmentPreviewView(attachment: attachmentPreview)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "scope")
                        .font(.system(size: 12, weight: .regular))

                    Text(goal.title)
                        .font(.atelia(12))
                        .lineLimit(1)
                }
                .foregroundStyle(Color.clientMutedText)

                HStack(spacing: 8) {
                    ComposerMentionMenu(
                        draftText: $draftText,
                        onIntent: onIntent
                    )

                    ForEach(contextReferences) { context in
                        ComposerContextChip(
                            context: context,
                            tint: context.kind.composerTint
                        ) {
                            let selection = ComposerContextSelection(id: context.id, kind: context.kind)
                            selectedContexts.upsert(selection)
                            onIntent(.openContext(selection))
                        }
                    }

                    Spacer(minLength: 0)

                    HStack(spacing: 8) {
                        Text("/")
                            .font(.ateliaLatin(14, weight: .semibold))
                            .foregroundStyle(Color.clientMutedText)
                            .accessibilityHidden(true)

                        TextField(
                            "コマンドを入力",
                            text: $draftText
                        )
                        .font(.atelia(12.75))
                        .textFieldStyle(.plain)
                        .foregroundStyle(Color.clientStrongText)
                        .tint(Color.clientAccent)
                        .accessibilityLabel("コマンド入力")
                        .accessibilityHint("Secretary のコマンド本文を入力")
                    }
                    .padding(.horizontal, 10)
                    .frame(width: 238, height: 24)
                    .background {
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(Color.white)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .stroke(Color.clientLineStrong, lineWidth: 1)
                    }
                }
            }
        }
        .padding(.top, hasAttachment ? 10 : 8)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct ComposerMentionMenu: View {
    @Binding var draftText: String
    let onIntent: (ComposerIntent) -> Void

    var body: some View {
        Menu {
            Button {
                insertMention("@Global Secretary")
            } label: {
                Label("Global Secretary", systemImage: "globe")
            }

            Button {
                insertMention("@Secretary")
            } label: {
                Label("Project Secretary", systemImage: "folder")
            }
        } label: {
            ComposerContextChipLabel(
                title: "@",
                subtitle: "mention",
                systemName: "at",
                tint: Color.clientAccent
            )
        }
        .menuStyle(.borderlessButton)
        .buttonStyle(.plain)
        .accessibilityLabel("メンション")
        .accessibilityHint("Secretary を指定する @ メンションを挿入")
    }

    private func insertMention(_ mention: String) {
        draftText = draftText.isEmpty ? "\(mention) " : "\(draftText) \(mention)"
        onIntent(.insertMention(mention))
    }
}

private struct ComposerContextChip: View {
    let context: ComposerContextReference
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ComposerContextChipLabel(
                title: context.title,
                subtitle: context.subtitle,
                systemName: context.systemImageName,
                tint: tint
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(context.accessibilityLabel)
        .accessibilityHint("文脈を開く")
    }
}

private struct ComposerContextChipLabel: View {
    let title: String
    let subtitle: String
    let systemName: String
    let tint: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemName)
                .font(.system(size: 11.5, weight: .regular))

            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.atelia(11.75, weight: .medium))
                    .lineLimit(1)

                Text(subtitle)
                    .font(.atelia(9.75))
                    .foregroundStyle(Color.clientSubtleText)
                    .lineLimit(1)
            }
        }
        .foregroundStyle(tint)
        .frame(height: 24)
        .padding(.horizontal, 10)
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.clientSurfaceSofter)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.clientDockHairline, lineWidth: 1)
        }
    }
}

private struct ComposerAttachmentPreviewView: View {
    let attachment: ComposerAttachmentPreview?

    var body: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Color.white)
                .frame(width: 72, height: 54)
                .overlay {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .stroke(Color.clientLine, lineWidth: 1)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(attachment?.title ?? "添付ファイル")
                    .font(.ateliaLatin(11.5, weight: .medium))
                    .foregroundStyle(Color.clientStrongText)
                    .lineLimit(1)

                Text(attachment?.subtitle ?? "ファイル文脈")
                    .font(.atelia(10.75))
                    .foregroundStyle(Color.clientSubtleText)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .frame(height: 70)
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.clientLine, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(attachment?.title ?? "添付ファイル")
        .accessibilityHint(attachment?.subtitle ?? "添付済みのファイル文脈")
    }
}

private extension ComposerContextKind {
    var composerTint: Color {
        switch self {
        case .file:
            Color.clientFileMention
        case .packageExtension:
            Color.clientMutedText
        }
    }
}

private extension ComposerContextReference {
    var accessibilityLabel: String {
        "\(title): \(subtitle)"
    }
}

extension ComposerConfiguration {
    var visibleContextSelections: [ComposerContextSelection] {
        var selections = contextReferences.map { ComposerContextSelection(id: $0.id, kind: $0.kind) }

        if let attachmentPreview {
            let attachmentContextID = attachmentPreview.contextReferenceID ?? attachmentPreview.id
            let attachmentContextKind = contextReferences.first { $0.id == attachmentContextID }?.kind ?? ComposerContextKind.file
            selections.upsert(ComposerContextSelection(id: attachmentContextID, kind: attachmentContextKind))
        }

        return selections
    }
}

private extension Array where Element == ComposerContextSelection {
    mutating func upsert(_ selection: ComposerContextSelection) {
        if let existingIndex = firstIndex(where: { $0.id == selection.id }) {
            self[existingIndex] = selection
        } else {
            append(selection)
        }
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

private struct ComposerAttachmentButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "paperclip")
                    .font(.system(size: 14, weight: .regular))

                Text("ファイル")
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
