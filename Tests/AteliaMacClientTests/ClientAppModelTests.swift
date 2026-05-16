import AteliaKit
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
    #expect(model.sidebarProjection.workspaceGroups.count == 1)

    let group = try #require(model.sidebarProjection.workspaceGroups.first)
    #expect(group.title == "Atelia Kit")
    #expect(group.subtitle == "atelia-kit")
    #expect(group.status == .warning)
    #expect(group.items.map(\.title) == ["Secretary", "ジョブ"])
    #expect(group.items.map(\.trailing) == [nil, "2"])
    #expect(group.items.first?.isSelected == true)
    #expect(group.settings.map(\.title) == ["ポリシー判断", "プロジェクト設定"])
    #expect(group.settings.map(\.trailing) == ["1", nil])
    #expect(model.sidebarProjection.globalItems.map(\.title) == [
        "Global Secretary",
        "検索",
        "拡張機能",
        "オートメーション",
        "Atelia Mobile を設定"
    ])
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
