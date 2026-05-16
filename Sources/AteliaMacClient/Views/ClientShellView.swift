import AteliaMacClientModels
import SwiftUI

enum ClientShellAction {
    case openSettings
    case sidebar(SidebarAction)
    case composer(ComposerIntent)
}

struct ClientShellView: View {
    let state: ClientMockState
    var onAction: (ClientShellAction) -> Void = { _ in }

    var body: some View {
        HStack(spacing: 0) {
            SidebarView(
                activeSelection: state.activeSelection,
                activeNavigationItemID: state.activeNavigationItemID,
                groups: state.workspaceGroups,
                globalItems: state.recentChats,
                onAction: { onAction(.sidebar($0)) }
            )

            Rectangle()
                .fill(Color.clientSidebarRail)
                .frame(width: AteliaClientLayout.sidebarDividerWidth)

            ConversationView(
                conversation: AteliaConversation(fixture: state.conversation),
                activeProjectTitle: state.activeProjectTitle,
                goal: state.goal,
                composer: state.composer,
                onOpenSettings: { onAction(.openSettings) },
                onComposerIntent: { onAction(.composer($0)) }
            )
        }
        .background(Color.white)
        .font(.atelia(14))
    }
}
