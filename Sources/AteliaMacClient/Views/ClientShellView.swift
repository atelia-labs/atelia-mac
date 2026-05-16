import AteliaMacClientModels
import SwiftUI

struct ClientShellView: View {
    let state: ClientMockState

    var body: some View {
        HStack(spacing: 0) {
            SidebarView(
                activeNavigationItemID: state.activeNavigationItemID,
                activeSurfaceID: state.activeSurfaceID,
                groups: state.workspaceGroups,
                globalItems: state.recentChats
            )

            Rectangle()
                .fill(Color.clientSidebarRail)
                .frame(width: 1)

            ConversationSurfaceView(state: state)
        }
        .background(Color.white)
        .font(.atelia(14))
        .preferredColorScheme(.light)
    }
}

private struct ConversationSurfaceView: View {
    let state: ClientMockState

    var body: some View {
        VStack(spacing: 0) {
            ConversationTopBar(state: state)

            ClientScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    AteliaIdentityHeader(state: state)

                    ForEach(state.messages) { message in
                        UserMessageBubble(message: message)
                    }

                    ActivityCard(activity: state.activity)
                }
                .frame(width: AteliaClientLayout.contentWidth, alignment: .leading)
                .padding(.top, 24)
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity, alignment: .center)
            }

            ComposerDock(goal: state.goal, configuration: state.composer)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}

private struct ConversationTopBar: View {
    let state: ClientMockState

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Atelia")
                    .font(.atelia(16, weight: .semibold))
                    .foregroundStyle(Color.clientStrongText)

                Text("Global Secretary / \(state.activeProjectTitle)")
                    .font(.atelia(12.5))
                    .foregroundStyle(Color.clientMutedText)
            }

            Spacer()

            Button {} label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color.clientSidebarIcon)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Atelia 設定")
            .accessibilityHint("Global Secretary とプロジェクト設定を開く")
        }
        .frame(height: AteliaClientLayout.topbarHeight)
        .padding(.horizontal, 24)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.clientLineSoft)
                .frame(height: 1)
        }
    }
}

private struct AteliaIdentityHeader: View {
    let state: ClientMockState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Atelia / Global Secretary")
                .font(.atelia(13, weight: .medium))
                .foregroundStyle(Color.clientAccent)

            Text(state.activeConversationTitle)
                .font(.atelia(24, weight: .semibold))
                .foregroundStyle(Color.clientStrongText)

            HStack(spacing: 8) {
                Label("surface \(state.activeSurfaceID)", systemImage: "rectangle.3.group")
                Label(state.goal.elapsed, systemImage: "timer")
            }
            .font(.atelia(12))
            .foregroundStyle(Color.clientMutedText)
        }
        .padding(.bottom, 4)
    }
}

private struct UserMessageBubble: View {
    let message: ChatMessage

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(message.text)
                .font(.atelia(14))
                .foregroundStyle(Color.clientText)
                .fixedSize(horizontal: false, vertical: true)

            if let attachmentName = message.attachmentName {
                HStack(spacing: 7) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 13, weight: .regular))

                    Text(attachmentName)
                        .font(.atelia(12.5))
                }
                .foregroundStyle(Color.clientFileMention)
            }
        }
        .padding(.horizontal, AteliaClientLayout.userBubbleHorizontalPadding)
        .padding(.vertical, AteliaClientLayout.userBubbleVerticalPadding)
        .frame(maxWidth: AteliaClientLayout.userBubbleMaxWidth, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.clientSurfaceSofter)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

private struct ActivityCard: View {
    let activity: ActivityBlock

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(activity.duration)
                    .font(.atelia(12, weight: .medium))
                    .foregroundStyle(Color.clientMutedText)

                Text(activity.title)
                    .font(.atelia(14, weight: .medium))
                    .foregroundStyle(Color.clientText)
            }

            VStack(alignment: .leading, spacing: 6) {
                ForEach(activity.bullets, id: \.self) { bullet in
                    Label(bullet, systemImage: "checkmark")
                        .font(.atelia(13))
                        .foregroundStyle(Color.clientMutedText)
                }
            }

            HStack(spacing: 10) {
                PreviewPill(
                    title: activity.document.title,
                    subtitle: activity.document.subtitle,
                    systemImage: "doc.text"
                )

                PreviewPill(
                    title: activity.review.title,
                    subtitle: "+\(activity.review.additions) -\(activity.review.deletions)",
                    systemImage: "square.and.pencil"
                )
            }
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.clientLine, lineWidth: 1)
        }
    }
}

private struct PreviewPill: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color.clientMutedText)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.atelia(12.5, weight: .medium))
                    .foregroundStyle(Color.clientText)

                Text(subtitle)
                    .font(.atelia(11.5))
                    .foregroundStyle(Color.clientMutedText)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Color.clientSurfaceSofter)
        }
    }
}

private struct ComposerDock: View {
    let goal: GoalStatus
    let configuration: ComposerConfiguration

    var body: some View {
        VStack(spacing: 0) {
            ComposerView(goal: goal, configuration: configuration)
                .padding(.bottom, 24)
        }
        .frame(height: AteliaClientLayout.composerFooterHeight)
        .frame(maxWidth: .infinity)
        .background {
            LinearGradient(
                colors: [.white.opacity(0), .white],
                startPoint: .top,
                endPoint: .center
            )
        }
    }
}
