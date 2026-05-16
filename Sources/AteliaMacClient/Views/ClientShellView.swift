import AteliaMacClientModels
import SwiftUI

enum ClientShellAction {
    case openSettings
    case sidebar(SidebarAction)
    case composer(ComposerIntent)
}

struct ClientShellView: View {
    let state: ClientMockState
    let sidebarProjection: ClientSidebarProjection
    var onAction: (ClientShellAction) -> Void = { _ in }

    init(
        state: ClientMockState,
        sidebarProjection: ClientSidebarProjection? = nil,
        onAction: @escaping (ClientShellAction) -> Void = { _ in }
    ) {
        self.state = state
        self.sidebarProjection = sidebarProjection ?? ClientSidebarProjection(mockState: state)
        self.onAction = onAction
    }

    var body: some View {
        HStack(spacing: 0) {
            SidebarView(
                activeSelection: sidebarProjection.activeSelection,
                activeNavigationItemID: sidebarProjection.activeNavigationItemID,
                activePrimaryCommandID: sidebarProjection.activePrimaryCommandID,
                projectSectionHeader: sidebarProjection.projectSectionHeader,
                projectAddCandidateLabel: sidebarProjection.projectAddCandidateLabel,
                groups: sidebarProjection.workspaceGroups,
                globalItems: sidebarProjection.globalItems,
                onAction: { onAction(.sidebar($0)) }
            )

            Rectangle()
                .fill(Color.clientSidebarRail)
                .frame(width: AteliaClientLayout.sidebarDividerWidth)

            conversationView
        }
        .background(Color.white)
        .font(.atelia(14))
    }

    var conversationView: ConversationView {
        ConversationView(
            conversation: AteliaConversation(fixture: state.conversation),
            activeConversationTitle: sidebarProjection.activeConversationTitle,
            activeProjectTitle: sidebarProjection.activeProjectTitle,
            goal: state.goal,
            composer: state.composer,
            onOpenSettings: { onAction(.openSettings) },
            onComposerIntent: { onAction(.composer($0)) }
        )
    }
}
