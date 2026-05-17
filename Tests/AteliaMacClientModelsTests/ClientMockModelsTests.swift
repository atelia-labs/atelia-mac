import Testing
import AteliaMacClientModels

@Test func mockNavigationUsesStableIdsAndSurfaceMetadata() {
    let state = ClientMockState.ateliaReference
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
    #expect(state.activeNavigationItemID == "nav:mac-atelia:project-conversation")
    #expect(state.activeSurfaceID == MockSurfaceReference.projectConversation.id)
}

@Test func projectSectionHeaderProjectionCarriesMenuContract() {
    let state = ClientMockState.ateliaReference
    let header = state.projection.projectSectionHeader

    #expect(header.title == "プロジェクト")
    #expect(header.actions.map(\.id) == [
        "project:add:create-folder",
        "project:add:use-existing-folder"
    ])
    #expect(header.actions.map(\.kind) == [.createFolder, .useExistingFolder])
    #expect(header.actions.map(\.title) == [
        "新規フォルダを作成",
        "既存のフォルダを使用"
    ])
    #expect(header.actions.map(\.symbolName) == [
        "folder.badge.plus",
        "folder"
    ])
    #expect(header.actions.map(\.accessibilityLabel) == [
        "新規フォルダを作成",
        "既存のフォルダを使用"
    ])
}

@Test func packageProvidedAreasAreOptionalBundledSurfaces() {
    let state = ClientMockState.ateliaReference
    let navigationItems = state.workspaceGroups.flatMap { $0.items + $0.settings } + state.recentChats
    let packageProvidedItems = navigationItems.filter {
        $0.surface.packageID != MockSurfaceReference.hostPackageID
    }

    #expect(packageProvidedItems.count == 4)
    #expect(packageProvidedItems.allSatisfy { $0.surface.lifecycle == .available })
    #expect(packageProvidedItems.allSatisfy { $0.surface.trust == .bundledOfficial })
    #expect(packageProvidedItems.allSatisfy { $0.surface.criticality == .userRemovable })
}

@Test func globalItemsIncludeProjectedPackageRoutes() {
    let state = ClientMockState.ateliaReference

    #expect(state.recentChats.map(\.id) == [
        "recent:mac-atelia:project-conversation",
        "recent:mac-atelia:package-management",
        "recent:official-automations:surface-home",
        "recent:official-review:surface-home"
    ])
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
        label: "Open test surface",
        packageID: surface.packageID,
        surfaceID: surface.surfaceID,
        actionOwnerComponentID: "test-surface",
        capabilityCallerComponentID: "test-backend",
        callerCapabilityID: "service.test.read",
        componentProfile: "TestListItem.v1",
        requiredPermissions: ["test.read"],
        risk: .r1,
        invokes: .service(service: "test.surface.v1", method: "open"),
        executionPath: .serviceBroker,
        confirmationRequired: false,
        redactionProjection: "package_default",
        auditEvent: "test.opened"
    )
    let item = ChatListItem(
        id: "nav:test",
        projectID: "project:test",
        resourceID: "resource:test",
        title: "Test",
        trailing: nil,
        leadingAffordance: .activity,
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
    let composer = ComposerConfiguration(
        routeKey: "composer:test",
        selectedModel: ComposerModelSelection(
            id: "model:test",
            routeKey: "models/test",
            displayName: "Test model"
        ),
        permissionMode: ComposerPermissionMode(
            id: "permission:test",
            routeKey: "permissions/test",
            permissionScope: "test.write",
            displayName: "Test access"
        )
    )
    let state = ClientMockState(
        activeConversationTitle: "Conversation",
        activeProjectTitle: "Project",
        activeSelection: ClientMockActiveSelection(
            projectID: item.projectID,
            surfacePackageID: item.surface.packageID,
            surfaceID: item.surface.surfaceID,
            resourceID: item.resourceID
        ),
        workspaceGroups: [group],
        recentChats: [item],
        changeSummary: changeSummary,
        messages: [message],
        activity: activity,
        goal: goal,
        composer: composer
    )

    #expect(state.workspaceGroups.first?.items.first?.action == action)
    #expect(state.projection.workspaceGroups.first?.items.first?.isSelected == true)
    #expect(state.conversation.turns.count == 2)
    #expect(state.conversation.turns.first?.blocks.first?.id == message.id)
    #expect(state.conversation.turns.last?.blocks.first?.id == "activity.mock.Conversation")
    guard case .secretary? = state.conversation.turns.last?.actor else {
        Issue.record("Expected fallback conversation to synthesize a secretary activity turn.")
        return
    }
    #expect(state.activity.document.title == document.title)
    #expect(state.goal.elapsed == goal.elapsed)
    #expect(state.composer == composer)
}

@Test func fallbackConversationSynthesizesActivityTurnFromDefaultInitializerPath() {
    let surface = MockSurfaceReference(
        packageID: "dev.atelia.test.package",
        surfaceID: "test-surface",
        lifecycle: .available,
        trust: .bundledOfficial,
        criticality: .optional,
        schemaVersion: "surface.mock.v1"
    )
    let item = ChatListItem(
        id: "nav:test",
        projectID: "project:test",
        resourceID: "resource:test",
        title: "Test",
        trailing: nil,
        surface: surface
    )
    let message = ChatMessage(id: "message:test", text: "User request")
    let activity = ActivityBlock(
        duration: "2s",
        title: "Secretary activity",
        bullets: ["Rendered activity"],
        document: DocumentPreview(title: "Doc", subtitle: "Preview"),
        review: ReviewPreview(title: "Review", additions: 1, deletions: 0)
    )
    let state = ClientMockState(
        activeConversationTitle: "Conversation",
        activeProjectTitle: "Project",
        activeSelection: ClientMockActiveSelection(
            projectID: item.projectID,
            surfacePackageID: item.surface.packageID,
            surfaceID: item.surface.surfaceID,
            resourceID: item.resourceID
        ),
        workspaceGroups: [],
        recentChats: [item],
        changeSummary: ChangeSummary(
            filePath: "Sources/Test.swift",
            additions: 1,
            deletions: 0,
            collapsedFileCount: 0
        ),
        messages: [message],
        activity: activity,
        goal: GoalStatus(title: "Goal", elapsed: "2s"),
        composer: ComposerConfiguration(
            routeKey: "composer:test",
            selectedModel: ComposerModelSelection(
                id: "model:test",
                routeKey: "models/test",
                displayName: "Test model"
            ),
            permissionMode: ComposerPermissionMode(
                id: "permission:test",
                routeKey: "permissions/test",
                permissionScope: "test.write",
                displayName: "Test access"
            )
        )
    )

    guard case .user? = state.conversation.turns.first?.actor else {
        Issue.record("Expected first fallback conversation turn to remain the user message.")
        return
    }
    guard case .secretary? = state.conversation.turns.last?.actor else {
        Issue.record("Expected second fallback conversation turn to be secretary activity.")
        return
    }
    guard case .activity(let activityBlock)? = state.conversation.turns.last?.blocks.first else {
        Issue.record("Expected fallback conversation to include secretary activity.")
        return
    }
    #expect(activityBlock.duration == activity.duration)
    #expect(activityBlock.status == "完了")
    #expect(activityBlock.title == activity.title)
    #expect(activityBlock.bullets == activity.bullets)
}

@Test func directDiffLineFixtureInitializerPreservesSemanticText() {
    let added = ClientConversationDiffLineFixture(id: "line.added", kind: .added, text: "+let next = value")
    let removed = ClientConversationDiffLineFixture(id: "line.removed", kind: .removed, text: "-let old = value")
    let context = ClientConversationDiffLineFixture(id: "line.context", kind: .context, text: "    let stable = value")

    #expect(added.text == "+let next = value")
    #expect(removed.text == "-let old = value")
    #expect(context.text == "    let stable = value")
}

@Test func rawUnifiedDiffLineFixtureFactoryStripsMarkerOnce() {
    let added = ClientConversationDiffLineFixture.rawUnifiedDiff(id: "line.added", kind: .added, text: "++let next = value")
    let removed = ClientConversationDiffLineFixture.rawUnifiedDiff(id: "line.removed", kind: .removed, text: "--let old = value")
    let context = ClientConversationDiffLineFixture.rawUnifiedDiff(id: "line.context", kind: .context, text: "    let stable = value")

    #expect(added.text == "+let next = value")
    #expect(removed.text == "-let old = value")
    #expect(context.text == "   let stable = value")
}

@Test func mockComposerConfigurationKeepsModelDisplayInState() {
    let state = ClientMockState.ateliaReference

    #expect(state.composer.routeKey == "composer:project-conversation:follow-up")
    #expect(state.composer.selectedModel.id == "model:atelia-balanced")
    #expect(state.composer.selectedModel.routeKey == "models/atelia-balanced")
    #expect(state.composer.selectedModel.displayName == "5.5 中")
    #expect(state.composer.permissionMode.id == "permission:full-access")
    #expect(state.composer.permissionMode.routeKey == "permissions/full-access")
    #expect(state.composer.permissionMode.permissionScope == "workspace.full-access")
    #expect(state.composer.permissionMode.displayName == "フルアクセス")
    #expect(state.composer.contextReferences.map(\.id) == [
        "context:file:standard-surfaces",
        "context:extension:surface-protocol"
    ])
    #expect(state.composer.contextReferences.map(\.kind) == [.file, .packageExtension])
    #expect(state.composer.attachmentPreview?.id == "attachment:standard-surfaces")
    #expect(state.composer.attachmentPreview?.contextReferenceID == "context:file:standard-surfaces")
    #expect(state.composer.attachmentPreview?.title == "standard-surfaces.md")
}

@Test func mockActionsCarrySurfaceProtocolRoutingMetadata() {
    let state = ClientMockState.ateliaReference
    let navigationItems = state.workspaceGroups.flatMap { $0.items + $0.settings } + state.recentChats
    let actions = navigationItems.compactMap(\.action)

    #expect(MockSurfaceReference.hostPackageID == "host.bootstrap.macos")
    #expect(actions.allSatisfy { !$0.actionOwnerComponentID.isEmpty })
    #expect(actions.allSatisfy { !$0.capabilityCallerComponentID.isEmpty })
    #expect(actions.allSatisfy { !$0.callerCapabilityID.isEmpty })
    #expect(actions.allSatisfy { !$0.componentProfile.isEmpty })
    #expect(actions.allSatisfy { !$0.requiredPermissions.isEmpty })
    #expect(actions.allSatisfy { $0.risk == .r1 })
    #expect(actions.allSatisfy { $0.resolverCorrelationHandling == .resolverMintedRequired })
    #expect(actions.allSatisfy { !$0.redactionProjection.isEmpty })
    #expect(actions.allSatisfy { action in
        switch action.invokes {
        case .service:
            action.executionPath == .serviceBroker || action.executionPath == .secretaryBackendService
        case .broker:
            action.executionPath == .hostBroker
        case .tool:
            action.executionPath == .secretaryTool
        }
    })
}

@Test func activeSelectionIsDerivedInProjection() {
    let state = ClientMockState.ateliaReference
    let projectedItems = state.projection.workspaceGroups.flatMap { $0.items + $0.settings }
        + state.projection.recentChats
    let selectedItems = projectedItems.filter(\.isSelected)

    #expect(state.activeSelection.projectID == "project:mac-atelia")
    #expect(state.activeSelection.surfacePackageID == MockSurfaceReference.hostPackageID)
    #expect(state.activeSelection.surfaceID == "project-conversation")
    #expect(state.activeSelection.resourceID == "conversation:mac-atelia:secretary")
    #expect(Set(selectedItems.map(\.id)) == Set([
        "nav:mac-atelia:project-conversation",
        "recent:mac-atelia:project-conversation"
    ]))
    #expect(state.workspaceGroups.flatMap { $0.items + $0.settings }.allSatisfy { item in
        state.activeSelection.matches(item) == projectedItems.contains {
            $0.id == item.id && $0.isSelected
        }
    })
}

@Test func leadingAffordanceRolesMapToPresentationOutsideFixtureState() {
    let state = ClientMockState.ateliaReference
    let projectedItems = state.projection.workspaceGroups.flatMap { $0.items + $0.settings }
        + state.projection.recentChats
    let assistantItems = projectedItems.filter { $0.leadingAffordance == .assistantConversation }

    #expect(!assistantItems.isEmpty)
    #expect(assistantItems.allSatisfy { $0.leadingPresentation == .assistantMark })
    #expect(projectedItems.first { $0.leadingAffordance == .delegatedWork }?.leadingPresentation == .branchGlyph)
    #expect(projectedItems.first { $0.leadingAffordance == .packageInstall }?.leadingPresentation == .addGlyph)
}

@Test func selectedNavigationIsDerivedFromActiveSelectionNotTitles() {
    let state = ClientMockState.ateliaReference
    let navigationItems = state.workspaceGroups.flatMap { $0.items + $0.settings } + state.recentChats
    let selectedByItemID = navigationItems.filter { $0.id == state.activeNavigationItemID }
    let selectedBySurfaceID = navigationItems.filter { $0.surface.id == state.activeSurfaceID }

    #expect(selectedByItemID.map(\.title) == ["Secretary"])
    #expect(selectedByItemID.count == 1)
    #expect(selectedBySurfaceID.count == 3)
    #expect(Set(selectedBySurfaceID.map(\.title)) == Set(["Secretary", "Project conversation"]))
    #expect(state.activeNavigationItemID != state.activeConversationTitle)
    #expect(state.activeSurfaceID != state.activeConversationTitle)
}

@Test func baselineItemsStayWithinDocumentedHostSurfaces() {
    let state = ClientMockState.ateliaReference
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

@Test func primaryNavigationActionsUseRouteMetadata() {
    let newThread = MockActionReference.startNewThread
    let search = MockActionReference.searchAllProjects

    #expect(newThread.declaredBySurfaceID == MockSurfaceReference.projectConversation.surfaceID)
    #expect(search.declaredBySurfaceID == MockSurfaceReference.globalSearch.surfaceID)
    #expect(MockSurfaceReference.globalSearch.trust == .bundledOfficial)
    #expect(MockSurfaceReference.globalSearch.criticality == .userRemovable)
    #expect(newThread.permissionScope == "project.conversation.write")
    #expect(search.permissionScope == "workspace.search.read")
}

@Test func mockCopyDoesNotEmbedInternalModelRoutingNames() {
    let state = ClientMockState.ateliaReference
    let searchableText = [
        state.activeConversationTitle,
        state.activeProjectTitle,
        state.workspaceGroups.map { [$0.title, $0.subtitle].compactMap(\.self).joined(separator: " ") }.joined(separator: " "),
        state.recentChats.map(\.title).joined(separator: " "),
        state.messages.map(\.text).joined(separator: " "),
        state.activity.title,
        state.activity.bullets.joined(separator: " "),
        state.goal.title,
        state.composer.routeKey,
        state.composer.selectedModel.id,
        state.composer.selectedModel.routeKey,
        state.composer.selectedModel.displayName,
        state.composer.permissionMode.id,
        state.composer.permissionMode.routeKey,
        state.composer.permissionMode.permissionScope,
        state.composer.permissionMode.displayName
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
