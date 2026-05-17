import AteliaKit
import AteliaMacClientModels
import Foundation
import Testing
@testable import AteliaMacClient
@testable import AteliaMacCore

private actor ProjectStatusClientFixture: AteliaClient {
    private let result: Result<AteliaProjectStatus, Error>
    private var callCount = 0
    private var requestedRepositoryIDs: [String] = []

    init(response: AteliaProjectStatus) {
        self.result = .success(response)
    }

    init(error: Error) {
        self.result = .failure(error)
    }

    func projectStatus(
        for session: AteliaSession,
        repositoryId: String
    ) async throws -> AteliaProjectStatus {
        _ = session
        callCount += 1
        requestedRepositoryIDs.append(repositoryId)
        return try result.get()
    }

    func calls() -> Int {
        callCount
    }

    func repositoryIDs() -> [String] {
        requestedRepositoryIDs
    }
}

private enum ProjectStatusClientFixtureError: Error {
    case failed
}

@MainActor
private final class ProjectFolderSelectionClientFixture: ProjectFolderSelectionProviding {
    var existingFolderURL: URL?
    var newFolderURL: URL?
    private(set) var existingFolderCallCount = 0
    private(set) var newFolderCallCount = 0

    func chooseExistingFolder() -> URL? {
        existingFolderCallCount += 1
        return existingFolderURL
    }

    func createNewFolder() -> URL? {
        newFolderCallCount += 1
        return newFolderURL
    }
}

private let clientAppModelProjectStatusFixture = AteliaProjectStatus(
    metadata: AteliaProtocolMetadata(
        protocolVersion: "1.0.0",
        daemonVersion: "0.2.0",
        storageVersion: "0.2.0",
        capabilities: ["project_status.v1"]
    ),
    repository: AteliaRepository(
        repositoryId: "repo_123",
        displayName: "Atelia Kit",
        rootPath: "/workspace/atelia-kit",
        allowedScope: AteliaPathScope(kind: .repository),
        trustState: .trusted,
        createdAtUnixMilliseconds: 1710000000000,
        updatedAtUnixMilliseconds: 1710000100000
    ),
    recentJobs: [
        AteliaJob(
            jobId: "job_123",
            repositoryId: "repo_123",
            requester: .agent(id: "agent_secretary", displayName: "Secretary"),
            kind: "tool",
            goal: "Read package manifest",
            status: .running,
            createdAtUnixMilliseconds: 1710000000000,
            startedAtUnixMilliseconds: 1710000001000,
            latestEventId: "evt_123"
        ),
        AteliaJob(
            jobId: "job_456",
            repositoryId: "repo_123",
            requester: .user(id: "user_123", displayName: "Aki"),
            kind: "review",
            goal: "Check protocol shapes",
            status: .queued,
            createdAtUnixMilliseconds: 1710000002000
        )
    ],
    recentPolicyDecisions: [
        AteliaPolicyDecision(
            decisionId: "pol_123",
            outcome: .allowed,
            riskTier: .r1,
            requestedCapability: "filesystem.read",
            reasonCode: "bounded_read",
            reason: "Read-only access is sufficient"
        )
    ],
    latestCursor: AteliaEventCursor(sequence: 17, eventId: "evt_123"),
    daemonStatus: .ready,
    storageStatus: .migrating
)

private let readyClientAppModelProjectStatusFixture = AteliaProjectStatus(
    metadata: AteliaProtocolMetadata(
        protocolVersion: "1.0.0",
        daemonVersion: "0.2.0",
        storageVersion: "0.2.0",
        capabilities: ["project_status.v1"]
    ),
    repository: AteliaRepository(
        repositoryId: "repo_ready",
        displayName: "Ready Repo",
        rootPath: "/workspace/ready-repo",
        allowedScope: AteliaPathScope(kind: .repository),
        trustState: .trusted,
        createdAtUnixMilliseconds: 1710000000000,
        updatedAtUnixMilliseconds: 1710000100000
    ),
    recentJobs: [],
    recentPolicyDecisions: [],
    latestCursor: nil,
    daemonStatus: .ready,
    storageStatus: .ready
)

@MainActor
@Test func clientAppModelReloadProjectsStoreStateIntoSidebar() async throws {
    let client = ProjectStatusClientFixture(response: clientAppModelProjectStatusFixture)
    let store = MacProjectStatusStore(client: client, session: AteliaSession(), repositoryId: "repo_123")
    let model = ClientAppModel(projectStatusStore: store)

    #expect(model.projectStatusSnapshot == nil)
    #expect(model.sidebarProjection.activeProjectTitle == "プロジェクト未読込")

    try await model.reloadProjectStatus()

    #expect(await client.calls() == 1)
    #expect(await client.repositoryIDs() == ["repo_123"])
    #expect(model.isReloading == false)
    #expect(model.lastErrorMessage == nil)
    #expect(model.projectStatusSnapshot == MacProjectStatusSnapshot(status: clientAppModelProjectStatusFixture))
    #expect(model.sidebarProjection.activeConversationTitle == "Secretary")
    #expect(model.sidebarProjection.activeProjectTitle == "Atelia Kit")
    #expect(model.sidebarProjection.projectSectionHeader.title == "プロジェクト")
    #expect(model.sidebarProjection.projectSectionHeader.actions.map(\.id) == [
        "project:add:create-folder",
        "project:add:use-existing-folder"
    ])
    #expect(model.sidebarProjection.projectSectionHeader.actions.map(\.kind) == [
        .createFolder,
        .useExistingFolder
    ])
    #expect(model.sidebarProjection.workspaceGroups.count == 1)

    let group = try #require(model.sidebarProjection.workspaceGroups.first)
    #expect(group.title == "Atelia Kit")
    #expect(group.subtitle == "atelia-kit")
    #expect(group.status == .warning)
    #expect(group.items.map(\.title) == ["Secretary", "ジョブ"])
    #expect(group.items.map(\.trailing) == [nil, "2"])
    #expect(model.sidebarProjection.activeNavigationItemID == "nav:repo_123:project-conversation")
    #expect(model.sidebarProjection.activeSurfaceID == MockSurfaceReference.projectConversation.id)
    #expect(group.settings.map(\.title) == ["ポリシー判断", "拡張機能", "オートメーション", "プロジェクト設定"])
    #expect(group.settings.map(\.trailing) == ["1", nil, nil, nil])
    #expect(model.sidebarProjection.projectMenuItems.map(\.title) == [
        "Secretary",
        "ジョブ",
        "ポリシー判断",
        "拡張機能",
        "オートメーション",
        "プロジェクト設定"
    ])
    #expect(model.sidebarProjection.globalItems.map(\.title) == [
        "Global Secretary",
        "検索",
        "拡張機能",
        "オートメーション",
        "Atelia Mobile を設定"
    ])

    let globalSecretary = try #require(model.sidebarProjection.globalItems.first { $0.id == "global:secretary" })
    let globalSearch = try #require(model.sidebarProjection.globalItems.first { $0.id == "global:search" })
    #expect(globalSecretary.projectID == "global")
    #expect(globalSecretary.resourceID == "conversation:global:secretary")
    #expect(globalSecretary.surface == .globalSecretary)
    #expect(globalSecretary.action == .openGlobalSecretary)
    #expect(globalSecretary.surface.trust == .bundledOfficial)
    #expect(globalSecretary.surface.criticality == .userRemovable)
    #expect(globalSearch.surface == .globalSearch)
    #expect(globalSearch.action == .searchAllProjects)
    #expect(globalSearch.surface.trust == .bundledOfficial)
    #expect(globalSearch.surface.criticality == .userRemovable)

    let mobileSetup = try #require(model.sidebarProjection.globalItems.first { $0.id == "global:mobile-setup" })
    #expect(mobileSetup.surface == .settings)
    #expect(mobileSetup.action == .openMobileSetup)
    #expect(mobileSetup.action?.declaredBySurfaceID == MockSurfaceReference.settings.surfaceID)
}

@MainActor
@Test func clientAppModelRoutesGlobalSecretarySelectionIntoConversationState() async throws {
    let client = ProjectStatusClientFixture(response: clientAppModelProjectStatusFixture)
    let store = MacProjectStatusStore(client: client, session: AteliaSession(), repositoryId: "repo_123")
    let model = ClientAppModel(projectStatusStore: store)

    try await model.reloadProjectStatus()

    let globalSecretary = try #require(model.sidebarProjection.globalItems.first { $0.id == "global:secretary" })

    model.handleSidebarAction(.chatItem(
        id: globalSecretary.id,
        projectID: globalSecretary.projectID,
        resourceID: globalSecretary.resourceID,
        title: globalSecretary.title,
        surface: globalSecretary.surface,
        action: try #require(globalSecretary.action)
    ))

    #expect(model.sidebarProjection.activeConversationTitle == "Global Secretary")
    #expect(model.sidebarProjection.activeProjectTitle == "全プロジェクト")
    #expect(model.sidebarProjection.activeNavigationItemID == "global:secretary")
    #expect(model.sidebarProjection.activePrimaryCommandID == nil)
    #expect(model.sidebarProjection.activeSurfaceID == MockSurfaceReference.globalSecretary.id)
}

@MainActor
@Test func clientAppModelRoutesGlobalSettingsSelectionIntoWorkspaceState() async throws {
    let client = ProjectStatusClientFixture(response: clientAppModelProjectStatusFixture)
    let store = MacProjectStatusStore(client: client, session: AteliaSession(), repositoryId: "repo_123")
    let model = ClientAppModel(projectStatusStore: store)

    try await model.reloadProjectStatus()

    model.handleSidebarAction(.command(
        id: "global:settings",
        title: "設定",
        surface: .settings,
        action: .openProjectSettings
    ))

    #expect(model.sidebarProjection.activeConversationTitle == "設定")
    #expect(model.sidebarProjection.activeProjectTitle == "全プロジェクト")
    #expect(model.sidebarProjection.activeSelection.projectID == "global")
    #expect(model.sidebarProjection.activeSelection.resourceID == "settings:global:workspace")
    #expect(model.sidebarProjection.activeNavigationItemID == "global:settings")
    #expect(model.sidebarProjection.activePrimaryCommandID == nil)
    #expect(model.sidebarProjection.activeSurfaceID == MockSurfaceReference.settings.id)
}

@MainActor
@Test func clientAppModelRoutesProjectSettingsSelectionIntoProjectState() async throws {
    let client = ProjectStatusClientFixture(response: clientAppModelProjectStatusFixture)
    let store = MacProjectStatusStore(client: client, session: AteliaSession(), repositoryId: "repo_123")
    let model = ClientAppModel(projectStatusStore: store)

    try await model.reloadProjectStatus()

    let projectSettings = try #require(model.sidebarProjection.workspaceGroups.first?.settings.last { $0.id == "nav:repo_123:settings" })

    model.handleSidebarAction(.chatItem(
        id: projectSettings.id,
        projectID: projectSettings.projectID,
        resourceID: projectSettings.resourceID,
        title: projectSettings.title,
        surface: projectSettings.surface,
        action: try #require(projectSettings.action)
    ))

    #expect(model.sidebarProjection.activeConversationTitle == "プロジェクト設定")
    #expect(model.sidebarProjection.activeProjectTitle == "Atelia Kit")
    #expect(model.sidebarProjection.activeNavigationItemID == "nav:repo_123:settings")
    #expect(model.sidebarProjection.activePrimaryCommandID == nil)
}

@MainActor
@Test func clientAppModelRoutesPrimaryCommandSelectionIntoShellState() async throws {
    let client = ProjectStatusClientFixture(response: clientAppModelProjectStatusFixture)
    let store = MacProjectStatusStore(client: client, session: AteliaSession(), repositoryId: "repo_123")
    let model = ClientAppModel(projectStatusStore: store)

    try await model.reloadProjectStatus()

    model.handleSidebarAction(.command(
        id: "primary:global-search",
        title: "検索",
        surface: .globalSearch,
        action: .searchAllProjects
    ))

    #expect(model.sidebarProjection.activeConversationTitle == "検索")
    #expect(model.sidebarProjection.activeProjectTitle == "全プロジェクト")
    #expect(model.sidebarProjection.activeNavigationItemID == "global:search")
    #expect(model.sidebarProjection.activePrimaryCommandID == "primary:global-search")
    #expect(model.sidebarProjection.activeSurfaceID == MockSurfaceReference.globalSearch.id)
}

@MainActor
@Test func clientAppModelRoutesNewThreadCommandSelectionIntoProjectConversationState() async throws {
    let client = ProjectStatusClientFixture(response: clientAppModelProjectStatusFixture)
    let store = MacProjectStatusStore(client: client, session: AteliaSession(), repositoryId: "repo_123")
    let model = ClientAppModel(projectStatusStore: store)

    try await model.reloadProjectStatus()

    model.handleSidebarAction(.command(
        id: "primary:new-thread",
        title: "新しいスレッド",
        surface: .projectConversation,
        action: .startNewThread
    ))

    #expect(model.sidebarProjection.activeConversationTitle == "新しいスレッド")
    #expect(model.sidebarProjection.activeProjectTitle == "Atelia Kit")
    #expect(model.sidebarProjection.activeNavigationItemID == "nav:repo_123:project-conversation")
    #expect(model.sidebarProjection.activePrimaryCommandID == "primary:new-thread")
    #expect(model.sidebarProjection.activeSurfaceID == MockSurfaceReference.projectConversation.id)
}

@MainActor
@Test func clientAppModelUpgradesUnloadedSecretarySelectionAfterReload() async throws {
    let client = ProjectStatusClientFixture(response: clientAppModelProjectStatusFixture)
    let store = MacProjectStatusStore(client: client, session: AteliaSession(), repositoryId: "repo_123")
    let model = ClientAppModel(projectStatusStore: store)

    await model.clearProjectStatus()
    try await model.reloadProjectStatus()

    #expect(model.sidebarProjection.activeProjectTitle == "Atelia Kit")
    #expect(model.sidebarProjection.activeSelection.projectID == "project:repo_123")
    #expect(model.sidebarProjection.activeNavigationItemID == "nav:repo_123:project-conversation")
    #expect(model.sidebarProjection.activeConversationTitle == "Secretary")
}

@MainActor
@Test func clientAppModelUpgradesUnloadedNewThreadSelectionAfterReload() async throws {
    let client = ProjectStatusClientFixture(response: clientAppModelProjectStatusFixture)
    let store = MacProjectStatusStore(client: client, session: AteliaSession(), repositoryId: "repo_123")
    let model = ClientAppModel(projectStatusStore: store)

    await model.clearProjectStatus()

    model.handleSidebarAction(.command(
        id: "primary:new-thread",
        title: "新しいスレッド",
        surface: .projectConversation,
        action: .startNewThread
    ))

    #expect(model.sidebarProjection.activeSelection.projectID == "project:unloaded")
    #expect(model.sidebarProjection.activePrimaryCommandID == "primary:new-thread")

    try await model.reloadProjectStatus()

    #expect(model.sidebarProjection.activeProjectTitle == "Atelia Kit")
    #expect(model.sidebarProjection.activeSelection.projectID == "project:repo_123")
    #expect(model.sidebarProjection.activeNavigationItemID == "nav:repo_123:project-conversation")
    #expect(model.sidebarProjection.activePrimaryCommandID == "primary:new-thread")
    #expect(model.sidebarProjection.activeConversationTitle == "新しいスレッド")
}

@MainActor
@Test func clientAppModelRoutesUnsupportedCommandActionThroughGenericSelectionState() async throws {
    let client = ProjectStatusClientFixture(response: clientAppModelProjectStatusFixture)
    let store = MacProjectStatusStore(client: client, session: AteliaSession(), repositoryId: "repo_123")
    let model = ClientAppModel(projectStatusStore: store)

    try await model.reloadProjectStatus()

    model.handleSidebarAction(.command(
        id: "primary:custom",
        title: "カスタム",
        surface: .settings,
        action: .openProjectConversation
    ))

    #expect(model.sidebarProjection.activeConversationTitle == "カスタム")
    #expect(model.sidebarProjection.activeProjectTitle == "全プロジェクト")
    #expect(model.sidebarProjection.activeSelection.projectID == "global")
    #expect(model.sidebarProjection.activePrimaryCommandID == "primary:custom")
    #expect(model.sidebarProjection.activeNavigationItemID == "")
}

@MainActor
@Test func clientAppModelRoutesUnsupportedProjectContextCommandActionThroughProjectScopedSelectionState() async throws {
    let client = ProjectStatusClientFixture(response: clientAppModelProjectStatusFixture)
    let store = MacProjectStatusStore(client: client, session: AteliaSession(), repositoryId: "repo_123")
    let model = ClientAppModel(projectStatusStore: store)

    try await model.reloadProjectStatus()

    model.handleSidebarAction(.command(
        id: "primary:custom-project",
        title: "カスタム",
        surface: .projectConversation,
        action: .openProjectConversation
    ))

    #expect(model.sidebarProjection.activeConversationTitle == "カスタム")
    #expect(model.sidebarProjection.activeProjectTitle == "Atelia Kit")
    #expect(model.sidebarProjection.activeSelection.projectID == "project:repo_123")
    #expect(model.sidebarProjection.activePrimaryCommandID == "primary:custom-project")
    #expect(model.sidebarProjection.activeNavigationItemID == "")
}

@MainActor
@Test func clientAppModelSidebarClearsWarningWhenDaemonAndStorageAreReady() async throws {
    let client = ProjectStatusClientFixture(response: readyClientAppModelProjectStatusFixture)
    let store = MacProjectStatusStore(client: client, session: AteliaSession(), repositoryId: "repo_ready")
    let model = ClientAppModel(projectStatusStore: store)

    try await model.reloadProjectStatus()

    let group = try #require(model.sidebarProjection.workspaceGroups.first)
    #expect(group.status == nil)
}

@MainActor
@Test func clientAppModelClearResetsSnapshotAndProjection() async throws {
    let client = ProjectStatusClientFixture(response: clientAppModelProjectStatusFixture)
    let store = MacProjectStatusStore(client: client, session: AteliaSession(), repositoryId: "repo_123")
    let model = ClientAppModel(projectStatusStore: store)

    try await model.reloadProjectStatus()
    model.handleComposerIntent(.send(
        text: "既存のリクエスト",
        configuration: ClientMockState.ateliaReference.composer,
        contexts: []
    ))
    await model.clearProjectStatus()

    #expect(model.projectStatusSnapshot == nil)
    #expect(model.sidebarProjection.activeProjectTitle == "プロジェクト未読込")
    #expect(model.sidebarProjection.workspaceGroups.first?.title == "プロジェクト未読込")
    #expect(model.lastComposerSubmissionRequest == nil)
    #expect(model.lastErrorMessage == nil)
    #expect(await store.snapshot == nil)
}

@MainActor
@Test func clientAppModelClearProjectStatusAlsoClearsLocalProjects() async throws {
    let picker = ProjectFolderSelectionClientFixture()
    picker.existingFolderURL = URL(fileURLWithPath: "/Users/yohaku/Projects/AteliaKit")
    let client = ProjectStatusClientFixture(response: readyClientAppModelProjectStatusFixture)
    let store = MacProjectStatusStore(client: client, session: AteliaSession(), repositoryId: "repo_ready")
    let model = ClientAppModel(projectStatusStore: store, projectFolderSelection: picker)

    let useExistingFolderAction = ProjectSectionHeaderViewData.projectSectionHeader.actions.first(where: { $0.kind == .useExistingFolder })!

    model.handleProjectSectionHeaderAction(useExistingFolderAction)
    await model.clearProjectStatus()

    #expect(model.localProjects == [])
    #expect(model.sidebarProjection.workspaceGroups.map(\.id) == ["project:unloaded"])
}

@MainActor
@Test func clientAppModelUnloadedProjectionUsesStableSelectionContract() async throws {
    let client = ProjectStatusClientFixture(response: clientAppModelProjectStatusFixture)
    let store = MacProjectStatusStore(client: client, session: AteliaSession(), repositoryId: "repo_123")
    let model = ClientAppModel(projectStatusStore: store)

    #expect(model.sidebarProjection.activeNavigationItemID == "nav:unloaded:project-conversation")
    #expect(model.sidebarProjection.activeSurfaceID == MockSurfaceReference.projectConversation.id)
    #expect(model.sidebarProjection.workspaceGroups.first?.items.first?.resourceID == "conversation:unloaded:secretary")
}

@MainActor
@Test func clientAppModelProjectionDoesNotReuseProjectMetadataForGlobalRows() async throws {
    let client = ProjectStatusClientFixture(response: readyClientAppModelProjectStatusFixture)
    let store = MacProjectStatusStore(client: client, session: AteliaSession(), repositoryId: "repo_ready")
    let model = ClientAppModel(projectStatusStore: store)

    try await model.reloadProjectStatus()

    let globalRows = model.sidebarProjection.globalItems

    #expect(globalRows.allSatisfy { $0.projectID == "global" })
    #expect(globalRows.allSatisfy { $0.action?.declaredBySurfaceID == $0.surface.surfaceID })
    #expect(globalRows.first { $0.id == "global:secretary" }?.surface != .projectConversation)
    #expect(globalRows.first { $0.id == "global:search" }?.surface != .projectHome)
}

@MainActor
@Test func clientAppModelReportsActiveProjectSecretaryTarget() async throws {
    let client = ProjectStatusClientFixture(response: clientAppModelProjectStatusFixture)
    let store = MacProjectStatusStore(client: client, session: AteliaSession(), repositoryId: "repo_123")
    let model = ClientAppModel(projectStatusStore: store)

    try await model.reloadProjectStatus()

    #expect(model.activeConversationTarget() == .project(repositoryId: "repo_123"))

    let globalSecretary = try #require(model.sidebarProjection.globalItems.first { $0.id == "global:secretary" })
    model.handleSidebarAction(.chatItem(
        id: globalSecretary.id,
        projectID: globalSecretary.projectID,
        resourceID: globalSecretary.resourceID,
        title: globalSecretary.title,
        surface: globalSecretary.surface,
        action: try #require(globalSecretary.action)
    ))

    #expect(model.activeConversationTarget() == .global)
}

@MainActor
@Test func clientAppModelOnlyReportsProjectTargetForProjectConversationSurface() async throws {
    let client = ProjectStatusClientFixture(response: clientAppModelProjectStatusFixture)
    let store = MacProjectStatusStore(client: client, session: AteliaSession(), repositoryId: "repo_123")
    let model = ClientAppModel(projectStatusStore: store)

    try await model.reloadProjectStatus()

    let projectHome = try #require(model.sidebarProjection.workspaceGroups.first?.items.first { $0.surface == .projectHome })
    model.handleSidebarAction(.chatItem(
        id: projectHome.id,
        projectID: projectHome.projectID,
        resourceID: projectHome.resourceID,
        title: projectHome.title,
        surface: projectHome.surface,
        action: try #require(projectHome.action)
    ))
    #expect(model.activeConversationTarget() == .unavailable)

    let permissionRecovery = try #require(model.sidebarProjection.workspaceGroups.first?.settings.first { $0.surface == .permissionRecovery })
    model.handleSidebarAction(.chatItem(
        id: permissionRecovery.id,
        projectID: permissionRecovery.projectID,
        resourceID: permissionRecovery.resourceID,
        title: permissionRecovery.title,
        surface: permissionRecovery.surface,
        action: try #require(permissionRecovery.action)
    ))
    #expect(model.activeConversationTarget() == .unavailable)

    let settings = try #require(model.sidebarProjection.workspaceGroups.first?.settings.first { $0.surface == .settings })
    model.handleSidebarAction(.chatItem(
        id: settings.id,
        projectID: settings.projectID,
        resourceID: settings.resourceID,
        title: settings.title,
        surface: settings.surface,
        action: try #require(settings.action)
    ))
    #expect(model.activeConversationTarget() == .unavailable)
}

@MainActor
@Test func clientAppModelReportsUnavailableConversationTargetWhenNoProjectStatusLoaded() async {
    let client = ProjectStatusClientFixture(response: clientAppModelProjectStatusFixture)
    let store = MacProjectStatusStore(client: client, session: AteliaSession(), repositoryId: "repo_123")
    let model = ClientAppModel(projectStatusStore: store)

    #expect(model.activeConversationTarget() == .unavailable)
}

@MainActor
@Test func clientAppModelPreservesGlobalConversationTargetWithoutProjectStatusLoaded() async throws {
    let client = ProjectStatusClientFixture(response: clientAppModelProjectStatusFixture)
    let store = MacProjectStatusStore(client: client, session: AteliaSession(), repositoryId: "repo_123")
    let model = ClientAppModel(projectStatusStore: store)
    let globalSecretary = try #require(model.sidebarProjection.globalItems.first { $0.id == "global:secretary" })

    model.handleSidebarAction(.chatItem(
        id: globalSecretary.id,
        projectID: globalSecretary.projectID,
        resourceID: globalSecretary.resourceID,
        title: globalSecretary.title,
        surface: globalSecretary.surface,
        action: try #require(globalSecretary.action)
    ))

    #expect(model.projectStatusSnapshot == nil)
    #expect(model.activeConversationTarget() == .global)
}

@MainActor
@Test func clientAppModelRejectsComposerSendWhenConversationTargetIsUnavailable() async {
    let client = ProjectStatusClientFixture(response: clientAppModelProjectStatusFixture)
    let store = MacProjectStatusStore(client: client, session: AteliaSession(), repositoryId: "repo_123")
    let model = ClientAppModel(projectStatusStore: store)

    model.handleComposerIntent(.send(
        text: "テスト",
        configuration: ClientMockState.ateliaReference.composer,
        contexts: []
    ))

    #expect(model.activeConversationTarget() == .unavailable)
    #expect(model.lastComposerSubmissionRequest == nil)
    #expect(model.lastErrorMessage == "プロジェクトを選択してください。")
}

@MainActor
@Test func clientAppModelBuildsProjectSecretarySubmitRequestFromComposerSend() async throws {
    let client = ProjectStatusClientFixture(response: clientAppModelProjectStatusFixture)
    let store = MacProjectStatusStore(client: client, session: AteliaSession(), repositoryId: "repo_123")
    let model = ClientAppModel(projectStatusStore: store)

    try await model.reloadProjectStatus()

    let configuration = ComposerConfiguration(
        routeKey: "composer:project-conversation:follow-up",
        selectedModel: ComposerModelSelection(
            id: "model:atelia-balanced",
            routeKey: "models/atelia-balanced",
            displayName: "5.5 中"
        ),
        permissionMode: ComposerPermissionMode(displayName: "フルアクセス"),
        contextReferences: [
            ComposerContextReference(
                id: "context:file:standard-surfaces",
                kind: .file,
                title: "ファイル",
                subtitle: "standard-surfaces.md",
                systemImageName: "doc"
            )
        ]
    )

    model.handleComposerIntent(.send(
        text: "  進捗を要約して  ",
        configuration: configuration,
        contexts: [
            ComposerContextSelection(id: "context:file:standard-surfaces", kind: .file)
        ]
    ))

    let request = try #require(model.lastComposerSubmissionRequest)

    #expect(request.repositoryId == "repo_123")
    #expect(request.message == "進捗を要約して")
    #expect(request.goal == nil)
    #expect(request.contextIDs == ["context:file:standard-surfaces"])
    #expect(request.modelRouteKey == "models/atelia-balanced")
    #expect(request.permissionModeRouteKey == "")
}

@MainActor
@Test func clientAppModelAppendsLocalDraftTurnsForProjectSecretarySend() async throws {
    let client = ProjectStatusClientFixture(response: clientAppModelProjectStatusFixture)
    let store = MacProjectStatusStore(client: client, session: AteliaSession(), repositoryId: "repo_123")
    let model = ClientAppModel(projectStatusStore: store)

    try await model.reloadProjectStatus()

    let originalTurnCount = model.shellState.conversation.turns.count

    model.handleComposerIntent(.send(
        text: "  テスト計画を作って  ",
        configuration: ClientMockState.ateliaReference.composer,
        contexts: [
            ComposerContextSelection(id: "context:file:test-plan", kind: .file)
        ]
    ))

    #expect(model.shellState.conversation.turns.count == originalTurnCount + 2)

    let userDraft = try #require(model.shellState.conversation.turns.dropLast().last)
    let secretaryDraft = try #require(model.shellState.conversation.turns.last)

    #expect(userDraft.blocks.first?.id == "message.user.local-draft:repo_123:1")
    #expect(secretaryDraft.blocks.first?.id == "activity.secretary.local-draft:repo_123:1")
}

@MainActor
@Test func clientAppModelRemovesVisibleLocalDraftStateWhenLocalProjectIsRemoved() throws {
    let folderURL = URL(fileURLWithPath: "/Users/yohaku/Projects/DraftProject")
    let project = LocalProjectRegistration.make(folderURL: folderURL, source: .existingFolder)
    let registry = InMemoryLocalProjectRegistry(projects: [project])
    let client = ProjectStatusClientFixture(response: readyClientAppModelProjectStatusFixture)
    let store = MacProjectStatusStore(client: client, session: AteliaSession(), repositoryId: "repo_ready")
    let model = ClientAppModel(projectStatusStore: store, localProjectRegistry: registry)
    let originalTurnCount = model.shellState.conversation.turns.count

    model.handleComposerIntent(.send(
        text: "ローカル下書きを作成",
        configuration: ClientMockState.ateliaReference.composer,
        contexts: []
    ))

    #expect(model.shellState.conversation.turns.count == originalTurnCount + 2)

    model.handleSidebarAction(.removeLocalProject(id: project.id))
    model.registerLocalProject(folderURL: folderURL, source: .existingFolder)

    #expect(model.localProjects == [project])
    #expect(model.sidebarProjection.activeSelection.projectID == project.projectID)
    #expect(model.shellState.conversation.turns.count == originalTurnCount)
    #expect(model.shellState.conversation.turns.allSatisfy { turn in
        !turn.id.contains("local-draft:\(project.id)")
    })
}

@MainActor
@Test func clientAppModelUsesInjectedLocalProjectRegistryForInitialProjection() {
    let folderURL = URL(fileURLWithPath: "/Users/yohaku/Projects/Registered")
    let project = LocalProjectRegistration.make(folderURL: folderURL, source: .existingFolder)
    let registry = InMemoryLocalProjectRegistry(projects: [project])
    let client = ProjectStatusClientFixture(response: readyClientAppModelProjectStatusFixture)
    let store = MacProjectStatusStore(client: client, session: AteliaSession(), repositoryId: "repo_ready")
    let model = ClientAppModel(projectStatusStore: store, localProjectRegistry: registry)

    #expect(model.localProjects == [project])
    #expect(model.sidebarProjection.activeProjectTitle == "Registered")
    #expect(model.sidebarProjection.activeConversationTitle == "Secretary")
    #expect(model.sidebarProjection.activeSelection.projectID == project.projectID)
    #expect(model.activeConversationTarget() == .project(repositoryId: project.id))
}

@MainActor
@Test func clientAppModelHidesLocalProjectWhenBackendSnapshotHasSameRootPath() async throws {
    let folderURL = URL(fileURLWithPath: "/workspace/ready-repo")
    let project = LocalProjectRegistration.make(folderURL: folderURL, source: .existingFolder)
    let registry = InMemoryLocalProjectRegistry(projects: [project])
    let client = ProjectStatusClientFixture(response: readyClientAppModelProjectStatusFixture)
    let store = MacProjectStatusStore(client: client, session: AteliaSession(), repositoryId: "repo_ready")
    let model = ClientAppModel(projectStatusStore: store, localProjectRegistry: registry)

    #expect(model.sidebarProjection.workspaceGroups.map(\.id) == [project.projectID])

    try await model.reloadProjectStatus()

    #expect(model.localProjects == [project])
    #expect(model.sidebarProjection.workspaceGroups.map(\.id) == ["project:repo_ready"])
    #expect(model.sidebarProjection.activeProjectTitle == "Ready Repo")
    #expect(model.sidebarProjection.activeSelection.projectID == "project:repo_ready")
    #expect(model.sidebarProjection.workspaceGroups.first?.localProjectID == nil)
}

@MainActor
@Test func clientAppModelRemovesSelectedLocalProjectFromSidebarActionAndFallsBackToNextProject() {
    let firstProject = LocalProjectRegistration.make(
        folderURL: URL(fileURLWithPath: "/Users/yohaku/Projects/First"),
        source: .existingFolder
    )
    let secondProject = LocalProjectRegistration.make(
        folderURL: URL(fileURLWithPath: "/Users/yohaku/Projects/Second"),
        source: .newFolder
    )
    let registry = InMemoryLocalProjectRegistry(projects: [firstProject, secondProject])
    let client = ProjectStatusClientFixture(response: readyClientAppModelProjectStatusFixture)
    let store = MacProjectStatusStore(client: client, session: AteliaSession(), repositoryId: "repo_ready")
    let model = ClientAppModel(projectStatusStore: store, localProjectRegistry: registry)

    model.handleSidebarAction(.removeLocalProject(id: firstProject.id))

    #expect(model.localProjects == [secondProject])
    #expect(registry.listProjects() == [secondProject])
    #expect(model.sidebarProjection.activeProjectTitle == "Second")
    #expect(model.sidebarProjection.activeSelection.projectID == secondProject.projectID)
    #expect(model.sidebarProjection.workspaceGroups.map(\.id) == [secondProject.projectID])
    #expect(model.sidebarProjection.workspaceGroups.first?.localProjectID == secondProject.id)
}

@MainActor
@Test func clientAppModelRemovesNonSelectedLocalProjectFromSidebarActionWithoutChangingSelection() {
    let firstProject = LocalProjectRegistration.make(
        folderURL: URL(fileURLWithPath: "/Users/yohaku/Projects/First"),
        source: .existingFolder
    )
    let secondProject = LocalProjectRegistration.make(
        folderURL: URL(fileURLWithPath: "/Users/yohaku/Projects/Second"),
        source: .newFolder
    )
    let registry = InMemoryLocalProjectRegistry(projects: [firstProject, secondProject])
    let client = ProjectStatusClientFixture(response: readyClientAppModelProjectStatusFixture)
    let store = MacProjectStatusStore(client: client, session: AteliaSession(), repositoryId: "repo_ready")
    let model = ClientAppModel(projectStatusStore: store, localProjectRegistry: registry)

    model.handleSidebarAction(.removeLocalProject(id: secondProject.id))

    #expect(model.localProjects == [firstProject])
    #expect(registry.listProjects() == [firstProject])
    #expect(model.sidebarProjection.activeProjectTitle == "First")
    #expect(model.sidebarProjection.activeSelection.projectID == firstProject.projectID)
    #expect(model.sidebarProjection.workspaceGroups.map(\.id) == [firstProject.projectID])
}

@MainActor
@Test func clientAppModelDoesNotRemoveBackendProjectFromSidebarAction() async throws {
    let localProject = LocalProjectRegistration.make(
        folderURL: URL(fileURLWithPath: "/Users/yohaku/Projects/LocalOnly"),
        source: .existingFolder
    )
    let registry = InMemoryLocalProjectRegistry(projects: [localProject])
    let client = ProjectStatusClientFixture(response: readyClientAppModelProjectStatusFixture)
    let store = MacProjectStatusStore(client: client, session: AteliaSession(), repositoryId: "repo_ready")
    let model = ClientAppModel(projectStatusStore: store, localProjectRegistry: registry)

    try await model.reloadProjectStatus()

    model.handleSidebarAction(.removeLocalProject(id: "repo_ready"))

    #expect(model.localProjects == [localProject])
    #expect(registry.listProjects() == [localProject])
    #expect(model.sidebarProjection.workspaceGroups.map(\.id) == ["project:repo_ready", localProject.projectID])
    #expect(model.sidebarProjection.workspaceGroups.first { $0.id == "project:repo_ready" }?.localProjectID == nil)
}

@MainActor
@Test func clientAppModelRejectsComposerSendWhenGlobalConversationIsSelected() async throws {
    let client = ProjectStatusClientFixture(response: clientAppModelProjectStatusFixture)
    let store = MacProjectStatusStore(client: client, session: AteliaSession(), repositoryId: "repo_123")
    let model = ClientAppModel(projectStatusStore: store)

    try await model.reloadProjectStatus()

    let globalSecretary = try #require(model.sidebarProjection.globalItems.first { $0.id == "global:secretary" })
    model.handleSidebarAction(.chatItem(
        id: globalSecretary.id,
        projectID: globalSecretary.projectID,
        resourceID: globalSecretary.resourceID,
        title: globalSecretary.title,
        surface: globalSecretary.surface,
        action: try #require(globalSecretary.action)
    ))

    model.handleComposerIntent(.send(
        text: "グローバル宛のメッセージ",
        configuration: ClientMockState.ateliaReference.composer,
        contexts: []
    ))

    #expect(model.lastComposerSubmissionRequest == nil)
    #expect(model.lastErrorMessage == "プロジェクトを選択してください。")
}

@MainActor
@Test func clientAppModelUpdatesShellStateWhenSelectionChanges() async throws {
    let client = ProjectStatusClientFixture(response: clientAppModelProjectStatusFixture)
    let store = MacProjectStatusStore(client: client, session: AteliaSession(), repositoryId: "repo_123")
    let model = ClientAppModel(projectStatusStore: store)

    try await model.reloadProjectStatus()

    #expect(model.shellState.activeSelection == model.sidebarProjection.activeSelection)
    #expect(model.shellState.activeConversationTitle == model.sidebarProjection.activeConversationTitle)
    #expect(model.shellState.activeProjectTitle == model.sidebarProjection.activeProjectTitle)
    #expect(model.shellState.composer.routeKey == "composer:project-conversation:follow-up")
    #expect(!model.shellState.composer.contextReferences.isEmpty)

    let globalSecretary = try #require(model.sidebarProjection.globalItems.first { $0.id == "global:secretary" })
    model.handleSidebarAction(.chatItem(
        id: globalSecretary.id,
        projectID: globalSecretary.projectID,
        resourceID: globalSecretary.resourceID,
        title: globalSecretary.title,
        surface: globalSecretary.surface,
        action: try #require(globalSecretary.action)
    ))

    #expect(model.shellState.activeSelection == model.sidebarProjection.activeSelection)
    #expect(model.shellState.composer.routeKey == "composer:global-secretary")
    #expect(model.shellState.composer.contextReferences.isEmpty)
    #expect(model.shellState.activeConversationTitle == "Global Secretary")

    let projectSecretary = try #require(model.sidebarProjection.workspaceGroups.first?.items.first { $0.id == "nav:repo_123:project-conversation" })
    model.handleSidebarAction(.chatItem(
        id: projectSecretary.id,
        projectID: projectSecretary.projectID,
        resourceID: projectSecretary.resourceID,
        title: projectSecretary.title,
        surface: projectSecretary.surface,
        action: try #require(projectSecretary.action)
    ))

    #expect(model.shellState.activeSelection == model.sidebarProjection.activeSelection)
    #expect(model.shellState.composer.routeKey == "composer:project-conversation:follow-up")
    #expect(!model.shellState.composer.contextReferences.isEmpty)
}

@MainActor
@Test func clientSidebarProjectionProjectMenuItemsUseActiveProjectGroup() throws {
    var state = ClientMockState.ateliaReference
    let activeProjectGroup = try #require(state.workspaceGroups.first { $0.id == "project:atelia-secretary" })
    let activeProjectItem = try #require(activeProjectGroup.items.first)

    state.activeSelection = ClientMockActiveSelection(
        projectID: activeProjectItem.projectID,
        surfacePackageID: activeProjectItem.surface.packageID,
        surfaceID: activeProjectItem.surface.surfaceID,
        resourceID: activeProjectItem.resourceID
    )

    let projection = ClientSidebarProjection(mockState: state)

    #expect(projection.projectMenuItems.map(\.id) == (activeProjectGroup.items + activeProjectGroup.settings).map(\.id))
    #expect(projection.projectMenuItems.map(\.id) != (state.workspaceGroups.first?.items.map(\.id) ?? []))
}

@MainActor
@Test func clientSidebarProjectionProjectMenuItemsFallbackToFirstProjectGroup() throws {
    var state = ClientMockState.ateliaReference
    let fallbackProjectGroup = try #require(state.workspaceGroups.first { $0.id.hasPrefix("project:") })

    state.activeSelection = ClientMockActiveSelection(
        projectID: "global",
        surfacePackageID: MockSurfaceReference.globalSecretary.packageID,
        surfaceID: MockSurfaceReference.globalSecretary.surfaceID,
        resourceID: "conversation:global:secretary"
    )

    let projection = ClientSidebarProjection(mockState: state)

    #expect(projection.projectMenuItems.map(\.id) == (fallbackProjectGroup.items + fallbackProjectGroup.settings).map(\.id))
}

@MainActor
@Test func clientAppModelKeepsExistingProjectionWhenReloadFails() async throws {
    let client = ProjectStatusClientFixture(error: ProjectStatusClientFixtureError.failed)
    let store = MacProjectStatusStore(client: client, session: AteliaSession(), repositoryId: "repo_123")
    let model = ClientAppModel(projectStatusStore: store)

    await #expect(throws: ProjectStatusClientFixtureError.failed) {
        try await model.reloadProjectStatus()
    }

    #expect(await client.calls() == 1)
    #expect(model.isReloading == false)
    #expect(model.projectStatusSnapshot == nil)
    #expect(model.sidebarProjection.activeProjectTitle == "プロジェクト未読込")
    #expect(model.lastErrorMessage != nil)
}

@MainActor
@Test func clientAppModelRegistersExistingFolderSelectionAsLocalProject() {
    let picker = ProjectFolderSelectionClientFixture()
    let folderURL = URL(fileURLWithPath: "/Users/yohaku/Projects/AteliaKit")
    let expectedProject = LocalProjectRegistration.make(folderURL: folderURL, source: .existingFolder)
    picker.existingFolderURL = folderURL
    let client = ProjectStatusClientFixture(response: readyClientAppModelProjectStatusFixture)
    let store = MacProjectStatusStore(client: client, session: AteliaSession(), repositoryId: "repo_ready")
    let model = ClientAppModel(projectStatusStore: store, projectFolderSelection: picker)

    let useExistingFolderAction = ProjectSectionHeaderViewData.projectSectionHeader.actions.first(where: { $0.kind == .useExistingFolder })!

    model.handleProjectSectionHeaderAction(useExistingFolderAction)

    #expect(picker.existingFolderCallCount == 1)
    #expect(picker.newFolderCallCount == 0)
    #expect(model.localProjects == [expectedProject])
    #expect(model.sidebarProjection.activeProjectTitle == "AteliaKit")
    #expect(model.sidebarProjection.activeSelection.projectID == expectedProject.projectID)
    #expect(model.sidebarProjection.activeNavigationItemID == "nav:\(expectedProject.id):project-conversation")
    #expect(model.sidebarProjection.workspaceGroups.map(\.id) == [expectedProject.projectID])
    #expect(model.sidebarProjection.workspaceGroups.first?.localProjectID == expectedProject.id)
}

@MainActor
@Test func clientAppModelSelectsBackendProjectWhenRegisteringLoadedBackendRoot() async throws {
    let picker = ProjectFolderSelectionClientFixture()
    let backendRootURL = URL(fileURLWithPath: "/workspace/ready-repo")
    picker.existingFolderURL = backendRootURL
    let registry = InMemoryLocalProjectRegistry()
    let client = ProjectStatusClientFixture(response: readyClientAppModelProjectStatusFixture)
    let store = MacProjectStatusStore(client: client, session: AteliaSession(), repositoryId: "repo_ready")
    let model = ClientAppModel(projectStatusStore: store, projectFolderSelection: picker, localProjectRegistry: registry)

    try await model.reloadProjectStatus()

    let useExistingFolderAction = ProjectSectionHeaderViewData.projectSectionHeader.actions.first(where: { $0.kind == .useExistingFolder })!
    model.handleProjectSectionHeaderAction(useExistingFolderAction)

    #expect(picker.existingFolderCallCount == 1)
    #expect(model.localProjects == [])
    #expect(registry.listProjects() == [])
    #expect(model.sidebarProjection.activeProjectTitle == "Ready Repo")
    #expect(model.sidebarProjection.activeSelection.projectID == "project:repo_ready")
    #expect(model.sidebarProjection.activeNavigationItemID == "nav:repo_ready:project-conversation")
    #expect(model.activeConversationTarget() == .project(repositoryId: "repo_ready"))
    #expect(model.sidebarProjection.workspaceGroups.map(\.id) == ["project:repo_ready"])
}

@MainActor
@Test func clientAppModelRegistersNewFolderSelectionAsLocalProject() {
    let picker = ProjectFolderSelectionClientFixture()
    let folderURL = URL(fileURLWithPath: "/Users/yohaku/Projects/NewAteliaProject")
    let expectedProject = LocalProjectRegistration.make(folderURL: folderURL, source: .newFolder)
    picker.newFolderURL = folderURL
    let client = ProjectStatusClientFixture(response: readyClientAppModelProjectStatusFixture)
    let store = MacProjectStatusStore(client: client, session: AteliaSession(), repositoryId: "repo_ready")
    let model = ClientAppModel(projectStatusStore: store, projectFolderSelection: picker)

    let createFolderAction = ProjectSectionHeaderViewData.projectSectionHeader.actions.first(where: { $0.kind == .createFolder })!

    model.handleProjectSectionHeaderAction(createFolderAction)

    #expect(picker.existingFolderCallCount == 0)
    #expect(picker.newFolderCallCount == 1)
    #expect(model.localProjects == [expectedProject])
    #expect(model.sidebarProjection.activeProjectTitle == "NewAteliaProject")
    #expect(model.sidebarProjection.activeSelection.projectID == expectedProject.projectID)
}

@Test func projectFolderCreationEnsuresDirectoryExists() throws {
    let parentDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    let folderURL = parentDirectory.appendingPathComponent("NewAteliaProject", isDirectory: true)

    defer {
        try? FileManager.default.removeItem(at: parentDirectory)
    }

    try FileManager.default.createDirectory(at: parentDirectory, withIntermediateDirectories: true)

    let ensuredURL = try ProjectFolderCreation.ensureDirectory(at: folderURL)
    var isDirectory: ObjCBool = false

    #expect(ensuredURL == folderURL)
    #expect(FileManager.default.fileExists(atPath: folderURL.path, isDirectory: &isDirectory))
    #expect(isDirectory.boolValue)
}

@Test func projectFolderCreationThrowsWhenTargetExistsAsFile() throws {
    let parentDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    let fileURL = parentDirectory.appendingPathComponent("ExistingProject", isDirectory: false)

    defer {
        try? FileManager.default.removeItem(at: parentDirectory)
    }

    try FileManager.default.createDirectory(at: parentDirectory, withIntermediateDirectories: true)
    FileManager.default.createFile(atPath: fileURL.path, contents: Data(), attributes: nil)

    #expect(FileManager.default.fileExists(atPath: fileURL.path))
    #expect(throws: CocoaError.self) {
        try ProjectFolderCreation.ensureDirectory(at: fileURL)
    }
}
