import Testing
import AteliaMacClientModels

@Test func mockNavigationUsesStableIdsAndSurfaceMetadata() {
    let state = ClientMockState.codexReference
    let groups = state.workspaceGroups
    let navigationItems = groups.flatMap { $0.items + $0.settings } + state.recentChats

    #expect(groups.map(\.id) == [
        "project:mac-atelia",
        "project:atelia-secretary",
        "packages:bundled-official"
    ])
    #expect(Set(groups.map(\.id)).count == groups.count)
    #expect(Set(navigationItems.map(\.id)).count == navigationItems.count)
    #expect(navigationItems.allSatisfy { !$0.id.isEmpty })
    #expect(navigationItems.allSatisfy { !$0.surface.packageID.isEmpty })
    #expect(navigationItems.allSatisfy { !$0.surface.surfaceID.isEmpty })
    #expect(navigationItems.allSatisfy { $0.action?.declaredByPackageID == $0.surface.packageID })
    #expect(navigationItems.allSatisfy { $0.action?.declaredBySurfaceID == $0.surface.surfaceID })
}

@Test func packageProvidedAreasAreOptionalBundledSurfaces() {
    let state = ClientMockState.codexReference
    let navigationItems = state.workspaceGroups.flatMap { $0.items + $0.settings } + state.recentChats
    let packageProvidedItems = navigationItems.filter {
        $0.surface.packageID != MockSurfaceReference.hostPackageID
    }

    #expect(packageProvidedItems.count == 4)
    #expect(packageProvidedItems.allSatisfy { $0.surface.lifecycle == .available })
    #expect(packageProvidedItems.allSatisfy { $0.surface.trust == .bundledOfficial })
    #expect(packageProvidedItems.allSatisfy { $0.surface.criticality == .userRemovable })
}

@Test func publicAPIIsConstructibleWithoutTestableImport() {
    let surface = MockSurfaceReference(
        packageID: "dev.atelia.test.package",
        surfaceID: "test-surface",
        lifecycle: .available,
        trust: .bundledOfficial,
        criticality: .optional,
        schemaVersion: "surface.mock.v1"
    )
    let action = MockActionReference(
        actionID: "action.test.open",
        declaredByPackageID: surface.packageID,
        declaredBySurfaceID: surface.surfaceID,
        permissionScope: "test.read",
        auditEvent: "test.opened"
    )
    let item = ChatListItem(
        id: "nav:test",
        title: "Test",
        trailing: nil,
        isSelected: true,
        leadingStatus: .green,
        surface: surface,
        action: action
    )
    let group = WorkspaceGroup(
        id: "group:test",
        title: "Test Group",
        subtitle: nil,
        surface: surface,
        items: [item],
        settings: [],
        status: .warning,
        emptyText: "No items"
    )
    let changeSummary = ChangeSummary(
        filePath: "Sources/Test.swift",
        additions: 1,
        deletions: 0,
        collapsedFileCount: 0
    )
    let message = ChatMessage(
        id: "message:test",
        text: "Test message",
        attachmentName: nil
    )
    let document = DocumentPreview(title: "Test.md", subtitle: "Markdown")
    let review = ReviewPreview(title: "Review", additions: 1, deletions: 0)
    let activity = ActivityBlock(
        duration: "1s",
        title: "Activity",
        bullets: ["Done"],
        document: document,
        review: review
    )
    let goal = GoalStatus(title: "Goal", elapsed: "1s")
    let state = ClientMockState(
        activeConversationTitle: "Conversation",
        activeProjectTitle: "Project",
        workspaceGroups: [group],
        recentChats: [item],
        changeSummary: changeSummary,
        messages: [message],
        activity: activity,
        goal: goal
    )

    #expect(state.workspaceGroups.first?.items.first?.action == action)
    #expect(state.activity.document.title == document.title)
    #expect(state.goal.elapsed == goal.elapsed)
}

@Test func baselineItemsStayWithinDocumentedHostSurfaces() {
    let state = ClientMockState.codexReference
    let navigationItems = state.workspaceGroups.flatMap { $0.items + $0.settings } + state.recentChats
    let hostSurfaceIDs = Set(
        navigationItems
            .filter { $0.surface.packageID == MockSurfaceReference.hostPackageID }
            .map(\.surface.surfaceID)
    )

    #expect(hostSurfaceIDs == Set([
        "project-home",
        "project-conversation",
        "package-management",
        "permission-recovery",
        "settings"
    ]))
}

@Test func mockCopyDoesNotEmbedInternalModelRoutingNames() {
    let state = ClientMockState.codexReference
    let searchableText = [
        state.activeConversationTitle,
        state.activeProjectTitle,
        state.workspaceGroups.map { [$0.title, $0.subtitle].compactMap(\.self).joined(separator: " ") }.joined(separator: " "),
        state.recentChats.map(\.title).joined(separator: " "),
        state.messages.map(\.text).joined(separator: " "),
        state.activity.title,
        state.activity.bullets.joined(separator: " "),
        state.goal.title
    ].joined(separator: " ")

    for forbiddenPattern in [#"\bGLM\b"#, #"\bSpark\b"#, #"\bmini\b"#, #"\bgpt[-\w.]*\b"#] {
        #expect(
            searchableText.range(
                of: forbiddenPattern,
                options: [.regularExpression, .caseInsensitive]
            ) == nil
        )
    }
}
