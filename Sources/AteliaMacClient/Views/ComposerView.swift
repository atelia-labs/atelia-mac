import AteliaMacClientModels
import SwiftUI

enum ComposerIntent: Equatable {
    case insertMention(String)
    case send(text: String, configuration: ComposerConfiguration, contexts: [ComposerContextSelection])
}

struct ComposerView: View {
    let goal: GoalStatus
    let configuration: ComposerConfiguration
    private let hasAttachmentOverride: Bool
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
        self.hasAttachmentOverride = hasAttachment
        self.onIntent = onIntent
        _draftText = State(initialValue: text)
        _selectedContexts = State(initialValue: configuration.visibleContextSelections)
    }

    private var showsAttachment: Bool {
        composerShowsAttachment(hasAttachment: hasAttachmentOverride, configuration: configuration)
    }

    private var isSendEnabled: Bool {
        !draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            ComposerBody(
                goal: goal,
                hasAttachment: showsAttachment,
                draftText: $draftText,
                contextReferences: configuration.contextReferences,
                attachmentPreview: configuration.attachmentPreview,
                onIntent: onIntent
            )

            HStack(spacing: 13) {
                HStack(spacing: 5) {
                    Image(systemName: "exclamationmark.shield")
                        .font(.system(size: 14, weight: .regular))
                    Text(configuration.permissionMode.displayName)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("権限モード: \(configuration.permissionMode.displayName)")
                .accessibilityHint(configuration.permissionMode.permissionScope)
                .font(.atelia(13))
                .foregroundStyle(Color.clientWarning)

                Spacer()

                Image(systemName: "circle.dotted")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color.clientMutedText)
                    .accessibilityHidden(true)

                HStack(spacing: 5) {
                    Text(configuration.selectedModel.displayName)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("モデル: \(configuration.selectedModel.displayName)")
                .accessibilityHint(configuration.selectedModel.routeKey)
                .font(.atelia(14))
                .foregroundStyle(Color.clientText)

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
            height: showsAttachment ? AteliaClientLayout.composerAttachmentHeight : AteliaClientLayout.composerMinHeight
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
                        )
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
        draftText = composerTextAfterInsertingMention(draftText: draftText, mention: mention)
        onIntent(.insertMention(mention))
    }
}

func composerTextAfterInsertingMention(draftText: String, mention: String) -> String {
    guard !draftText.isEmpty else { return "\(mention) " }

    var normalizedDraft = draftText
    while normalizedDraft.last?.isWhitespace == true {
        normalizedDraft.removeLast()
    }

    return "\(normalizedDraft) \(mention) "
}

func composerShowsAttachment(hasAttachment: Bool, configuration: ComposerConfiguration) -> Bool {
    hasAttachment || configuration.attachmentPreview != nil
}

private struct ComposerContextChip: View {
    let context: ComposerContextReference
    let tint: Color

    var body: some View {
        ComposerContextChipLabel(
            title: context.title,
            subtitle: context.subtitle,
            systemName: context.systemImageName,
            tint: tint
        )
        .accessibilityLabel(context.accessibilityLabel)
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
        var selections = contextReferences.map {
            ComposerContextSelection(
                id: $0.id,
                kind: $0.kind,
                displayName: $0.displayName
            )
        }

        if let attachmentPreview {
            let attachmentContextID = attachmentPreview.contextReferenceID ?? attachmentPreview.id
            let attachmentContextKind = contextReferences.first { $0.id == attachmentContextID }?.kind ?? ComposerContextKind.file
            let attachmentDisplayName = attachmentPreview.title
            selections.upsert(ComposerContextSelection(
                id: attachmentContextID,
                kind: attachmentContextKind,
                displayName: attachmentDisplayName
            ))
        }

        return selections
    }
}

private extension ComposerContextReference {
    var displayName: String {
        subtitle.isEmpty ? title : subtitle
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
