import AteliaMacClientModels
import SwiftUI

struct ClientShellView: View {
    let state: ClientMockState

    var body: some View {
        HStack(spacing: 0) {
            SidebarView(
                activeTitle: state.activeConversationTitle,
                groups: state.workspaceGroups,
                globalItems: state.recentChats
            )

            Rectangle()
                .fill(Color.clientSidebarRail)
                .frame(width: 1)

            PlaceholderConversationView(state: state)
        }
        .background(Color.white)
        .font(.atelia(14))
        .preferredColorScheme(.light)
    }
}

private struct PlaceholderConversationView: View {
    let state: ClientMockState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(state.activeConversationTitle)
                .font(.atelia(15, weight: .medium))
                .foregroundStyle(Color.clientStrongText)

            Text("Conversation surface lands in the next stacked lane.")
                .font(.ateliaLatin(13))
                .foregroundStyle(Color.clientMutedText)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.white)
    }
}
