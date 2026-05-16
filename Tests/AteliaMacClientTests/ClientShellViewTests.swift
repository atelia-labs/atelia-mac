import AteliaMacClientModels
import Testing
@testable import AteliaMacClient

@MainActor
@Test func clientShellConversationUsesSidebarProjectionProjectTitle() {
    let state = ClientMockState.ateliaReference
    var sidebarProjection = ClientSidebarProjection(mockState: state)
    sidebarProjection.activeConversationTitle = "Runtime Thread"
    sidebarProjection.activeProjectTitle = "Runtime Project"

    let shell = ClientShellView(state: state, sidebarProjection: sidebarProjection)

    #expect(state.activeProjectTitle == "Mac Atelia")
    #expect(shell.conversationView.activeConversationTitle == "Runtime Thread")
    #expect(shell.conversationView.activeProjectTitle == "Runtime Project")
}
