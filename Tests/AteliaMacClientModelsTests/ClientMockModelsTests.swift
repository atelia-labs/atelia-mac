import Testing
@testable import AteliaMacClientModels

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
    #expect(navigationItems.allSatisfy { $0.action?.declaredBySurfaceID == $0.surface.surfaceID })
}

@Test func packageProvidedAreasAreOptionalBundledSurfaces() {
    let state = ClientMockState.codexReference
    let navigationItems = state.workspaceGroups.flatMap { $0.items + $0.settings } + state.recentChats
    let packageProvidedItems = navigationItems.filter {
        $0.surface.packageID != MockSurfaceReference.hostPackageID
    }

    #expect(packageProvidedItems.count == 4)
    #expect(packageProvidedItems.allSatisfy { $0.surface.lifecycle == .availableWhenEnabled })
    #expect(packageProvidedItems.allSatisfy { $0.surface.trust == .bundledOfficial })
    #expect(packageProvidedItems.allSatisfy { $0.surface.criticality == .userRemovable })
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
