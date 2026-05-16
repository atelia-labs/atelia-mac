import AteliaMacClientModels
import SwiftUI

struct ConversationView: View {
    let conversation: AteliaConversation
    let activeConversationTitle: String
    let activeProjectTitle: String
    let sidebarProjection: ClientSidebarProjection?
    let goal: GoalStatus
    let composer: ComposerConfiguration
    var onOpenSettings: () -> Void = {}
    var onProjectMenuAction: (SidebarAction) -> Void = { _ in }
    var onComposerIntent: (ComposerIntent) -> Void = { _ in }

    var body: some View {
        VStack(spacing: 0) {
            ConversationTopBar(
                activeConversationTitle: activeConversationTitle,
                activeProjectTitle: activeProjectTitle,
                projectMenuItems: sidebarProjection?.projectMenuItems ?? [],
                globalItems: sidebarProjection?.globalItems ?? [],
                onOpenSettings: onOpenSettings,
                onProjectMenuAction: onProjectMenuAction
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    ForEach(conversation.turns) { turn in
                        AteliaConversationTurnView(turn: turn)
                    }
                }
                .frame(width: AteliaClientLayout.contentWidth, alignment: .leading)
                .padding(.top, 34)
                .padding(.bottom, 28)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .scrollIndicators(.hidden)

            ComposerView(goal: goal, configuration: composer, onIntent: onComposerIntent)
                .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}

private struct ConversationTopBar: View {
    let activeConversationTitle: String
    let activeProjectTitle: String
    let projectMenuItems: [ChatListItem]
    let globalItems: [ChatListItem]
    let onOpenSettings: () -> Void
    let onProjectMenuAction: (SidebarAction) -> Void

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 1) {
                Text(activeConversationTitle)
                    .font(.atelia(16.5, weight: .semibold))
                    .foregroundStyle(Color.clientStrongText)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            Spacer()

            HStack(spacing: 8) {
                ConversationProjectChipMenu(
                    activeProjectTitle: activeProjectTitle,
                    projectMenuItems: projectMenuItems,
                    globalItems: globalItems,
                    onProjectMenuAction: onProjectMenuAction
                )

                Button(action: onOpenSettings) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(Color.clientSidebarIcon)
                        .frame(width: 28, height: 28)
                        .background(Color.black.opacity(0.01))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Atelia 設定")
                .accessibilityHint("Global Secretary とプロジェクト設定を開く")
            }
        }
        .padding(.horizontal, 24)
        .frame(height: AteliaClientLayout.topbarHeight)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.clientLineSoft)
                .frame(height: 1)
        }
    }
}

private struct ConversationProjectChipMenu: View {
    let activeProjectTitle: String
    let projectMenuItems: [ChatListItem]
    let globalItems: [ChatListItem]
    let onProjectMenuAction: (SidebarAction) -> Void

    var body: some View {
        Menu {
            if !projectMenuItems.isEmpty {
                Section("Project Secretary") {
                    ForEach(projectMenuItems) { item in
                        ConversationMenuItemButton(item: item, onProjectMenuAction: onProjectMenuAction)
                    }
                }
            }

            if !globalItems.isEmpty {
                Section("Global Secretary") {
                    ForEach(globalItems) { item in
                        ConversationMenuItemButton(item: item, onProjectMenuAction: onProjectMenuAction)
                    }
                }
            }
        } label: {
            HStack(spacing: 7) {
                Image(systemName: "folder")
                    .font(.system(size: 12.5, weight: .regular))

                Text(activeProjectTitle)
                    .font(.atelia(13.25, weight: .medium))
                    .lineLimit(1)

                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .regular))
            }
            .foregroundStyle(Color.clientStrongText)
            .padding(.horizontal, 11)
            .frame(height: 28)
            .background {
                Capsule(style: .continuous)
                    .fill(Color.clientSurfaceSofter)
            }
            .overlay {
                Capsule(style: .continuous)
                    .stroke(Color.clientLineStrong, lineWidth: 1)
            }
        }
        .menuStyle(.borderlessButton)
        .buttonStyle(.plain)
        .accessibilityLabel("プロジェクト \(activeProjectTitle)")
        .accessibilityHint("プロジェクトの Secretary と設定を開く")
    }
}

private struct ConversationMenuItemButton: View {
    let item: ChatListItem
    let onProjectMenuAction: (SidebarAction) -> Void

    var body: some View {
        if let action = item.action {
            Button {
                onProjectMenuAction(.chatItem(
                    id: item.id,
                    projectID: item.projectID,
                    resourceID: item.resourceID,
                    title: item.title,
                    surface: item.surface,
                    action: action
                ))
            } label: {
                Label(item.title, systemImage: symbolName)
            }
        } else {
            Button {} label: {
                Label(item.title, systemImage: symbolName)
            }
            .disabled(true)
        }
    }

    private var symbolName: String {
        switch item.leadingAffordance?.presentation {
        case .some(.statusDot):
            return "circle.fill"
        case .some(.assistantMark):
            return "sparkles"
        case .some(.branchGlyph):
            return "arrow.triangle.branch"
        case .some(.addGlyph):
            return "plus.circle"
        case nil:
            switch item.surface.surfaceID {
            case "settings":
                return "gearshape"
            case "package-management":
                return "square.grid.2x2"
            case "permission-recovery":
                return "checklist"
            case "automations-home":
                return "clock"
            case "project-conversation":
                return "message"
            default:
                return "circle"
            }
        }
    }
}

private struct AteliaConversationTurnView: View {
    let turn: AteliaConversationTurn

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(turn.blocks) { block in
                switch block {
                case .message(let message):
                    AteliaUserMessageView(message: message)
                case .activity(let activity):
                    AteliaActivityView(activity: activity)
                case .toolOutput(let toolOutput):
                    AteliaToolOutputView(toolOutput: toolOutput)
                case .changeSet(let changeSet):
                    AteliaChangeSetView(changeSet: changeSet)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: turn.actor == .user ? .trailing : .leading)
    }
}

private struct AteliaUserMessageView: View {
    let message: AteliaMessageBlock

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(message.text)
                .font(.atelia(14))
                .foregroundStyle(Color.clientStrongText)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            if let attachmentName = message.attachmentName {
                HStack(spacing: 7) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 13, weight: .regular))
                    Text(attachmentName)
                        .font(.ateliaLatin(12, weight: .medium))
                }
                .foregroundStyle(Color.clientFileMention)
                .padding(.horizontal, 10)
                .frame(height: 30)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 7))
                .overlay {
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(Color.clientLine, lineWidth: 1)
                }
            }
        }
        .padding(.horizontal, AteliaClientLayout.userBubbleHorizontalPadding)
        .padding(.vertical, AteliaClientLayout.userBubbleVerticalPadding)
        .frame(maxWidth: AteliaClientLayout.userBubbleMaxWidth, alignment: .leading)
        .background(Color.clientSurfaceSofter)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct AteliaActivityView: View {
    let activity: AteliaActivityBlock

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 9) {
                SecretaryMark()

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 7) {
                        Text("Secretary")
                            .font(.ateliaLatin(13, weight: .medium))
                            .foregroundStyle(Color.clientStrongText)

                        Text(activity.status)
                            .font(.atelia(12, weight: .medium))
                            .foregroundStyle(Color.clientSuccess)

                        Text(activity.duration)
                            .font(.ateliaLatin(12))
                            .foregroundStyle(Color.clientMutedText)
                    }

                    Text(activity.title)
                        .font(.atelia(14, weight: .medium))
                        .foregroundStyle(Color.clientStrongText)
                }
            }

            VStack(alignment: .leading, spacing: 7) {
                ForEach(Array(activity.bullets.enumerated()), id: \.offset) { _, bullet in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(Color.clientSuccess)
                            .frame(width: 5, height: 5)
                            .padding(.top, 7)

                        Text(bullet)
                            .font(.atelia(13))
                            .foregroundStyle(Color.clientText)
                            .lineSpacing(2)
                    }
                }
            }
            .padding(.leading, 33)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct AteliaToolOutputView: View {
    let toolOutput: AteliaToolOutputBlock

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 8) {
                Image(systemName: "terminal")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color.clientMutedText)

                Text(toolOutput.toolName)
                    .font(.ateliaLatin(13, weight: .medium))
                    .foregroundStyle(Color.clientStrongText)

                Text(statusText)
                    .font(.ateliaLatin(12))
                    .foregroundStyle(statusColor)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("$ \(toolOutput.command)")
                    .foregroundStyle(Color.clientMutedText)

                ForEach(Array(toolOutput.output.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .foregroundStyle(Color.clientText)
                }
            }
            .font(.ateliaMonospaced(12))
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.clientSurfaceSofter)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.clientLine, lineWidth: 1)
            }
        }
        .padding(.leading, 33)
    }

    private var statusText: String {
        switch toolOutput.status {
        case .succeeded:
            "succeeded"
        case .failed:
            "failed"
        case .running:
            "running"
        }
    }

    private var statusColor: Color {
        switch toolOutput.status {
        case .succeeded:
            Color.clientSuccess
        case .failed:
            Color.clientDanger
        case .running:
            Color.clientWarning
        }
    }
}

private struct AteliaChangeSetView: View {
    let changeSet: AteliaChangeSetBlock
    @State private var isExpanded: Bool

    init(changeSet: AteliaChangeSetBlock) {
        self.changeSet = changeSet
        _isExpanded = State(initialValue: changeSet.isExpandedByDefault)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.16)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.clientMutedText)
                        .frame(width: 16, height: 16)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(changeSet.title)
                            .font(.atelia(13, weight: .medium))
                            .foregroundStyle(Color.clientStrongText)

                        Text(changeSet.summary)
                            .font(.atelia(12))
                            .foregroundStyle(Color.clientMutedText)
                            .lineLimit(2)
                    }

                    Spacer()

                    ChangeMetric(label: "+", value: changeSet.additions, color: Color.clientSuccess)
                    ChangeMetric(label: "-", value: changeSet.deletions, color: Color.clientDanger)

                    Text("\(changeSet.files.count) files")
                        .font(.ateliaLatin(12))
                        .foregroundStyle(Color.clientMutedText)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                AteliaDiffCodeScroller(files: changeSet.files)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.clientSurfaceSofter)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.clientLine, lineWidth: 1)
        }
        .padding(.leading, 33)
    }
}

private struct AteliaDiffCodeScroller: View {
    let files: [AteliaChangedFile]

    private var scrollModel: AteliaDiffScrollModel {
        AteliaDiffScrollModel(files: files)
    }

    var body: some View {
        ClientCodeScrollView(contentWidth: scrollModel.contentWidth) {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(files) { file in
                    AteliaDiffFileView(file: file)
                }
            }
            .padding(12)
            .frame(width: scrollModel.contentWidth, alignment: .leading)
        }
        .frame(height: 312)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct ChangeMetric: View {
    let label: String
    let value: Int
    let color: Color

    var body: some View {
        Text("\(label)\(value)")
            .font(.ateliaLatin(12, weight: .medium))
            .foregroundStyle(color)
    }
}

private struct AteliaDiffFileView: View {
    let file: AteliaChangedFile

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "doc.text")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color.clientMutedText)

                Text(file.path)
                    .font(.ateliaLatin(12, weight: .medium))
                    .foregroundStyle(Color.clientStrongText)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)

                Spacer()

                ChangeMetric(label: "+", value: file.additions, color: Color.clientSuccess)
                ChangeMetric(label: "-", value: file.deletions, color: Color.clientDanger)
            }
            .padding(.horizontal, 10)
            .frame(height: 34)
            .background(Color.clientSurfaceSoft)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color.clientLineSoft)
                    .frame(height: 1)
            }

            ForEach(file.hunks) { hunk in
                AteliaDiffHunkView(hunk: hunk)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 7))
    }
}

private struct AteliaDiffHunkView: View {
    let hunk: AteliaDiffHunk

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(hunk.header)
                .font(.ateliaMonospaced(11))
                .foregroundStyle(Color.clientMutedText)
                .padding(.horizontal, 10)
                .frame(maxWidth: .infinity, minHeight: 28, alignment: .leading)
                .background(Color.white)

            ForEach(hunk.lines) { line in
                AteliaDiffLineView(line: line)
            }
        }
    }
}

private struct AteliaDiffLineView: View {
    let line: AteliaDiffLine

    var body: some View {
        HStack(spacing: 8) {
            Text(line.marker)
                .frame(width: 12, alignment: .center)
                .foregroundStyle(markerColor)

            Text(line.text)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(Color.clientText)
        }
        .font(.ateliaMonospaced(11))
        .padding(.horizontal, 10)
        .frame(minHeight: 22)
        .background(backgroundColor)
    }

    private var markerColor: Color {
        switch line.kind {
        case .added:
            Color.clientSuccess
        case .removed:
            Color.clientDanger
        case .context:
            Color.clientMutedText
        }
    }

    private var backgroundColor: Color {
        switch line.kind {
        case .added:
            Color.clientSuccess.opacity(0.08)
        case .removed:
            Color.clientDanger.opacity(0.08)
        case .context:
            Color.white
        }
    }
}

private struct SecretaryMark: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.clientAccent.opacity(0.10))

            Image(systemName: "sparkle")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Color.clientAccent)
        }
        .frame(width: 24, height: 24)
    }
}
