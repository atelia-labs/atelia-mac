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
    #expect(model.sidebarProjection.workspaceGroups.count == 1)

    let group = try #require(model.sidebarProjection.workspaceGroups.first)
    #expect(group.title == "Atelia Kit")
    #expect(group.subtitle == "atelia-kit")
    #expect(group.status == .warning)
    #expect(group.items.map(\.title) == ["Secretary", "ジョブ"])
    #expect(group.items.map(\.trailing) == [nil, "2"])
    #expect(model.sidebarProjection.activeNavigationItemID == "nav:repo_123:project-conversation")
    #expect(model.sidebarProjection.activeSurfaceID == MockSurfaceReference.projectConversation.id)
    #expect(group.settings.map(\.title) == ["ポリシー判断", "プロジェクト設定"])
    #expect(group.settings.map(\.trailing) == ["1", nil])
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
    await model.clearProjectStatus()

    #expect(model.projectStatusSnapshot == nil)
    #expect(model.sidebarProjection.activeProjectTitle == "プロジェクト未読込")
    #expect(model.sidebarProjection.workspaceGroups.first?.title == "プロジェクト未読込")
    #expect(model.lastErrorMessage == nil)
    #expect(await store.snapshot == nil)
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
@Test func clientAppModelRecordsExistingFolderSelectionAsPendingProjectAddSelection() {
    let picker = ProjectFolderSelectionClientFixture()
    picker.existingFolderURL = URL(fileURLWithPath: "/Users/yohaku/Projects/AteliaKit")
    let client = ProjectStatusClientFixture(response: readyClientAppModelProjectStatusFixture)
    let store = MacProjectStatusStore(client: client, session: AteliaSession(), repositoryId: "repo_ready")
    let model = ClientAppModel(projectStatusStore: store, projectFolderSelection: picker)

    model.handleProjectSectionHeaderAction(ProjectSectionHeaderViewData.projectSectionHeader.actions[1])

    #expect(picker.existingFolderCallCount == 1)
    #expect(picker.newFolderCallCount == 0)
    #expect(model.pendingProjectAddSelection?.source == .existingFolder)
    #expect(model.pendingProjectAddSelection?.folderURL == URL(fileURLWithPath: "/Users/yohaku/Projects/AteliaKit"))
    #expect(model.sidebarProjection.projectAddCandidateLabel == "AteliaKit")
}

@MainActor
@Test func clientAppModelRecordsNewFolderSelectionAsPendingProjectAddSelection() {
    let picker = ProjectFolderSelectionClientFixture()
    picker.newFolderURL = URL(fileURLWithPath: "/Users/yohaku/Projects/NewAteliaProject")
    let client = ProjectStatusClientFixture(response: readyClientAppModelProjectStatusFixture)
    let store = MacProjectStatusStore(client: client, session: AteliaSession(), repositoryId: "repo_ready")
    let model = ClientAppModel(projectStatusStore: store, projectFolderSelection: picker)

    model.handleProjectSectionHeaderAction(ProjectSectionHeaderViewData.projectSectionHeader.actions[0])

    #expect(picker.existingFolderCallCount == 0)
    #expect(picker.newFolderCallCount == 1)
    #expect(model.pendingProjectAddSelection?.source == .newFolder)
    #expect(model.pendingProjectAddSelection?.folderURL == URL(fileURLWithPath: "/Users/yohaku/Projects/NewAteliaProject"))
    #expect(model.sidebarProjection.projectAddCandidateLabel == "NewAteliaProject")
}

@Test func projectFolderCreationEnsuresDirectoryExists() throws {
    let parentDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    let folderURL = parentDirectory.appendingPathComponent("NewAteliaProject", isDirectory: true)

    defer {
        try? FileManager.default.removeItem(at: parentDirectory)
    }

    try FileManager.default.createDirectory(at: parentDirectory, withIntermediateDirectories: true)

    let resultURL = try ProjectFolderCreation.ensureDirectory(at: folderURL)

    #expect(resultURL == folderURL)
    #expect(FileManager.default.fileExists(atPath: folderURL.path))
    var isDirectory: ObjCBool = false
    #expect(FileManager.default.fileExists(atPath: folderURL.path, isDirectory: &isDirectory))
    #expect(isDirectory.boolValue)
}
