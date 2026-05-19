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

private enum ProjectLifecycleStoreFixtureError: LocalizedError {
    case openFailed
    case submitFailed
    case renderFailed

    var errorDescription: String? {
        switch self {
        case .openFailed:
            "open failed"
        case .submitFailed:
            "submit failed"
        case .renderFailed:
            "render failed"
        }
    }
}

private actor ProjectLifecycleStoreFixture: MacProjectLifecycleStoring {
    private let repository: AteliaRepository
    private let job: AteliaJob
    private let jobEvents: [AteliaEvent]
    private var openErrors: [any Error]
    private let submitError: (any Error)?
    private let jobEventsError: (any Error)?
    private let waitsForOpenRelease: Bool
    private let waitsForSubmitRelease: Bool
    private let waitsForJobEventsRelease: Bool
    private var openRequests: [AteliaRegisterRepositoryRequest] = []
    private var submitRequests: [AteliaSubmitJobRequest] = []
    private var openContinuations: [CheckedContinuation<AteliaRegisterRepositoryRequest, Never>] = []
    private var submitContinuations: [CheckedContinuation<AteliaSubmitJobRequest, Never>] = []
    private var openReleaseContinuations: [CheckedContinuation<Void, Never>] = []
    private var submitReleaseContinuations: [CheckedContinuation<Void, Never>] = []
    private var jobEventsReleaseContinuations: [CheckedContinuation<Void, Never>] = []

    init(
        repository: AteliaRepository,
        job: AteliaJob,
        jobEvents: [AteliaEvent] = [],
        openError: (any Error)? = nil,
        submitError: (any Error)? = nil,
        jobEventsError: (any Error)? = nil,
        waitsForOpenRelease: Bool = false,
        waitsForSubmitRelease: Bool = false,
        waitsForJobEventsRelease: Bool = false
    ) {
        self.repository = repository
        self.job = job
        self.jobEvents = jobEvents
        self.openErrors = openError.map { [$0] } ?? []
        self.submitError = submitError
        self.jobEventsError = jobEventsError
        self.waitsForOpenRelease = waitsForOpenRelease
        self.waitsForSubmitRelease = waitsForSubmitRelease
        self.waitsForJobEventsRelease = waitsForJobEventsRelease
    }

    func open(request: AteliaRegisterRepositoryRequest) async throws -> AteliaRepository {
        openRequests.append(request)
        resumeOpenContinuations(with: request)
        if waitsForOpenRelease {
            await withCheckedContinuation { continuation in
                openReleaseContinuations.append(continuation)
            }
        }
        if !openErrors.isEmpty {
            let openError = openErrors.removeFirst()
            throw openError
        }
        return repository
    }

    func submit(request: AteliaSubmitJobRequest) async throws -> AteliaJob {
        submitRequests.append(request)
        resumeSubmitContinuations(with: request)
        if waitsForSubmitRelease {
            await withCheckedContinuation { continuation in
                submitReleaseContinuations.append(continuation)
            }
        }
        if let submitError {
            throw submitError
        }
        return job
    }

    func listJobEvents(jobId: String, request: AteliaListEventsRequest) async throws -> [AteliaEvent] {
        _ = jobId
        _ = request
        if let jobEventsError {
            throw jobEventsError
        }
        if waitsForJobEventsRelease {
            await withCheckedContinuation { continuation in
                jobEventsReleaseContinuations.append(continuation)
            }
        }
        return jobEvents
    }

    func recordedOpenRequests() -> [AteliaRegisterRepositoryRequest] {
        openRequests
    }

    func recordedSubmitRequests() -> [AteliaSubmitJobRequest] {
        submitRequests
    }

    func waitForSubmitRequest() async -> AteliaSubmitJobRequest {
        if let request = submitRequests.last {
            return request
        }

        return await withCheckedContinuation { continuation in
            submitContinuations.append(continuation)
        }
    }

    func waitForSubmitRequestCount(_ count: Int) async -> [AteliaSubmitJobRequest] {
        while submitRequests.count < count {
            _ = await withCheckedContinuation { continuation in
                submitContinuations.append(continuation)
            }
        }
        return submitRequests
    }

    func waitForOpenRequest() async -> AteliaRegisterRepositoryRequest {
        if let request = openRequests.last {
            return request
        }

        return await withCheckedContinuation { continuation in
            openContinuations.append(continuation)
        }
    }

    func releaseOpen() {
        let continuations = openReleaseContinuations
        openReleaseContinuations = []
        for continuation in continuations {
            continuation.resume()
        }
    }
    func releaseSubmit() {
        let continuations = submitReleaseContinuations
        submitReleaseContinuations = []
        for continuation in continuations {
            continuation.resume()
        }
    }

    func releaseJobEvents() {
        let continuations = jobEventsReleaseContinuations
        jobEventsReleaseContinuations = []
        for continuation in continuations {
            continuation.resume()
        }
    }

    private func resumeOpenContinuations(with request: AteliaRegisterRepositoryRequest) {
        let continuations = openContinuations
        openContinuations = []
        for continuation in continuations {
            continuation.resume(returning: request)
        }
    }

    private func resumeSubmitContinuations(with request: AteliaSubmitJobRequest) {
        let continuations = submitContinuations
        submitContinuations = []
        for continuation in continuations {
            continuation.resume(returning: request)
        }
    }
}

private actor ToolOutputRenderStoreFixture: MacToolOutputRendering {
    private let result: Result<AteliaToolOutputRenderResponse, any Error>
    private var requests: [AteliaToolOutputRenderRequest] = []

    init(response: AteliaToolOutputRenderResponse) {
        self.result = .success(response)
    }

    init(error: any Error) {
        self.result = .failure(error)
    }

    func render(request: AteliaToolOutputRenderRequest) async throws -> AteliaToolOutputRenderResponse {
        requests.append(request)
        return try result.get()
    }

    func recordedRequests() -> [AteliaToolOutputRenderRequest] {
        requests
    }
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

private let clientAppModelLifecycleRepositoryFixture = AteliaRepository(
    repositoryId: "repo_lifecycle",
    displayName: "Lifecycle Project",
    rootPath: "/Users/yohaku/Projects/LifecycleProject",
    allowedScope: AteliaPathScope(kind: .repository),
    trustState: .trusted,
    createdAtUnixMilliseconds: 1710000000000,
    updatedAtUnixMilliseconds: 1710000100000
)

private let clientAppModelLifecycleJobFixture = AteliaJob(
    jobId: "job_lifecycle",
    repositoryId: "repo_lifecycle",
    requester: .user(id: "mac-client", displayName: "Atelia Mac"),
    kind: "message",
    goal: nil,
    status: .queued,
    createdAtUnixMilliseconds: 1710000200000
)

private let clientAppModelSucceededLifecycleJobFixture = AteliaJob(
    jobId: "job_lifecycle",
    repositoryId: "repo_lifecycle",
    requester: .user(id: "mac-client", displayName: "Atelia Mac"),
    kind: "tool",
    goal: nil,
    status: .succeeded,
    createdAtUnixMilliseconds: 1710000200000,
    startedAtUnixMilliseconds: 1710000200100,
    completedAtUnixMilliseconds: 1710000200200,
    latestEventId: "evt_tool_result"
)

private let clientAppModelToolResultEventFixture = AteliaEvent(
    eventId: "evt_tool_result",
    sequence: 22,
    occurredAtUnixMilliseconds: 1710000200200,
    subject: AteliaEventSubject(type: .toolResult, id: "tool_result_123"),
    kind: "tool_result_recorded",
    severity: .info,
    message: "tool result recorded",
    refs: AteliaEventRefs(
        repositoryId: "repo_lifecycle",
        jobId: "job_lifecycle",
        toolInvocationId: "tool_invocation_123",
        toolResultId: "tool_result_123",
        contentType: "application/json"
    )
)

private let clientAppModelRenderedToolOutputFixture = AteliaToolOutputRenderResponse(
    metadata: AteliaProtocolMetadata(
        protocolVersion: "1.0.0",
        daemonVersion: "0.2.0",
        storageVersion: "0.2.0",
        capabilities: ["tool_output.render.v1"]
    ),
    toolResult: AteliaToolResultRef(
        toolResultId: "tool_result_123",
        toolInvocationId: "tool_invocation_123",
        jobId: "job_lifecycle",
        repositoryId: "repo_lifecycle",
        contentType: "application/json"
    ),
    format: .text,
    renderedOutput: "Found 2 matches\nSources/App.swift:42",
    renderedOutputMetadata: AteliaRenderedToolOutputMetadata(degraded: false)
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
@Test func clientAppModelOpensGlobalSettingsFromTopBarAction() async throws {
    let client = ProjectStatusClientFixture(response: clientAppModelProjectStatusFixture)
    let store = MacProjectStatusStore(client: client, session: AteliaSession(), repositoryId: "repo_123")
    let model = ClientAppModel(projectStatusStore: store)

    try await model.reloadProjectStatus()

    model.openGlobalSettings()

    #expect(model.sidebarProjection.activeConversationTitle == "設定")
    #expect(model.sidebarProjection.activeProjectTitle == "全プロジェクト")
    #expect(model.sidebarProjection.activeSelection.projectID == "global")
    #expect(model.sidebarProjection.activeSelection.resourceID == "settings:global:workspace")
    #expect(model.sidebarProjection.activeNavigationItemID == "global:settings")
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
        permissionMode: ComposerPermissionMode(
            routeKey: "permissions/full-access",
            displayName: "フルアクセス"
        ),
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
    #expect(request.permissionModeRouteKey == "permissions/full-access")
}

@MainActor
@Test func composerJobSubmissionRequestBuildsPlainAteliaSubmitJobRequest() throws {
    let request = try #require(ComposerJobSubmissionRequest.fromSendIntent(
        text: "  進捗を要約して  ",
        repositoryId: "repo_123",
        configuration: ClientMockState.ateliaReference.composer,
        contexts: []
    ))

    let ateliaRequest = request.ateliaSubmitJobRequest()

    #expect(ateliaRequest.repositoryId == "repo_123")
    #expect(ateliaRequest.requester == .user(id: "mac-client", displayName: "Atelia Mac"))
    #expect(ateliaRequest.kind == "message")
    #expect(ateliaRequest.message == "進捗を要約して")
    #expect(ateliaRequest.goal == nil)
    #expect(ateliaRequest.modelRouteKey == "models/atelia-balanced")
    #expect(ateliaRequest.permissionModeRouteKey == "permissions/full-access")
    #expect(ateliaRequest.pathScope == nil)
    #expect(ateliaRequest.requestedCapabilities == nil)
    #expect(ateliaRequest.toolArgs == nil)
}

@MainActor
@Test func composerJobSubmissionRequestMapsSimpleSearchIntentToToolArgs() throws {
    let request = try #require(ComposerJobSubmissionRequest.fromSendIntent(
        text: "search AteliaSubmitJobRequest",
        repositoryId: "repo_123",
        configuration: ClientMockState.ateliaReference.composer,
        contexts: [],
        repositoryRootPath: "/Users/yohaku/Projects/RepoForSearch"
    ))

    let ateliaRequest = request.ateliaSubmitJobRequest(repositoryId: "repo_registered")

    #expect(ateliaRequest.repositoryId == "repo_registered")
    #expect(ateliaRequest.kind == "tool")
    #expect(ateliaRequest.message == "search AteliaSubmitJobRequest")
    #expect(ateliaRequest.goal == nil)
    #expect(ateliaRequest.modelRouteKey == "models/atelia-balanced")
    #expect(ateliaRequest.permissionModeRouteKey == "permissions/full-access")
    #expect(ateliaRequest.pathScope == AteliaPathScope(kind: .explicitPaths, roots: ["/Users/yohaku/Projects/RepoForSearch"]))
    #expect(ateliaRequest.requestedCapabilities == ["filesystem.search"])
    #expect(ateliaRequest.toolArgs == AteliaSubmitJobToolArgs(pattern: "AteliaSubmitJobRequest", max: 20))
}

@MainActor
@Test func composerJobSubmissionRequestMapsSimpleDiffIntentToToolArgs() throws {
    let request = try #require(ComposerJobSubmissionRequest.fromSendIntent(
        text: "diff path/to/file.swift",
        repositoryId: "repo_123",
        configuration: ClientMockState.ateliaReference.composer,
        contexts: [],
        repositoryRootPath: "/Users/yohaku/Projects/RepoForDiff"
    ))

    let ateliaRequest = request.ateliaSubmitJobRequest(repositoryId: "repo_registered")

    #expect(ateliaRequest.repositoryId == "repo_registered")
    #expect(ateliaRequest.kind == "tool")
    #expect(ateliaRequest.message == "diff path/to/file.swift")
    #expect(ateliaRequest.goal == nil)
    #expect(ateliaRequest.modelRouteKey == "models/atelia-balanced")
    #expect(ateliaRequest.permissionModeRouteKey == "permissions/full-access")
    #expect(ateliaRequest.pathScope == AteliaPathScope(kind: .explicitPaths, roots: ["/Users/yohaku/Projects/RepoForDiff"]))
    #expect(ateliaRequest.requestedCapabilities == ["filesystem.diff"])
    #expect(
        ateliaRequest.toolArgs == AteliaSubmitJobToolArgs(
            comparisonPath: "path/to/file.swift",
            maxBytes: 131_072,
            maxChars: 32_000
        )
    )
}

@MainActor
@Test func clientAppModelOpensLocalProjectAndSubmitsComposerRequestThroughLifecycleStore() async throws {
    let folderURL = URL(fileURLWithPath: "/Users/yohaku/Projects/LifecycleProject")
    let localProject = LocalProjectRegistration.make(folderURL: folderURL, source: .existingFolder)
    let registry = InMemoryLocalProjectRegistry(projects: [localProject])
    let statusClient = ProjectStatusClientFixture(response: readyClientAppModelProjectStatusFixture)
    let statusStore = MacProjectStatusStore(client: statusClient, session: AteliaSession(), repositoryId: "repo_ready")
    let lifecycleStore = ProjectLifecycleStoreFixture(
        repository: clientAppModelLifecycleRepositoryFixture,
        job: clientAppModelLifecycleJobFixture
    )
    let model = ClientAppModel(
        projectStatusStore: statusStore,
        projectLifecycleStore: lifecycleStore,
        localProjectRegistry: registry
    )
    let originalTurnCount = model.shellState.conversation.turns.count

    model.handleComposerIntent(.send(
        text: "search AteliaSubmitJobRequest",
        configuration: ClientMockState.ateliaReference.composer,
        contexts: []
    ))

    let ateliaRequest = await lifecycleStore.waitForSubmitRequest()
    let openRequests = await lifecycleStore.recordedOpenRequests()

    #expect(openRequests == [
        AteliaRegisterRepositoryRequest(
            displayName: localProject.displayName,
            rootPath: localProject.rootPath,
            allowedScope: AteliaPathScope(kind: .repository),
            requester: .user(id: "mac-client", displayName: "Atelia Mac")
        )
    ])
    #expect(ateliaRequest.repositoryId == "repo_lifecycle")
    #expect(ateliaRequest.kind == "tool")
    #expect(ateliaRequest.message == "search AteliaSubmitJobRequest")
    #expect(ateliaRequest.modelRouteKey == "models/atelia-balanced")
    #expect(ateliaRequest.permissionModeRouteKey == "permissions/full-access")
    #expect(ateliaRequest.pathScope == AteliaPathScope(kind: .explicitPaths, roots: [localProject.rootPath]))
    #expect(ateliaRequest.requestedCapabilities == ["filesystem.search"])
    #expect(ateliaRequest.toolArgs == AteliaSubmitJobToolArgs(pattern: "AteliaSubmitJobRequest", max: 20))
    #expect(model.lastAteliaSubmitJobRequest == ateliaRequest)
    #expect(model.lastErrorMessage == nil)
    #expect(model.lastComposerSubmissionRequest?.repositoryId == localProject.id)
    #expect(model.shellState.conversation.turns.count == originalTurnCount + 2)
}

@MainActor
@Test func clientAppModelRendersSubmittedToolResultBackIntoConversation() async throws {
    let folderURL = URL(fileURLWithPath: "/Users/yohaku/Projects/LifecycleProject")
    let localProject = LocalProjectRegistration.make(folderURL: folderURL, source: .existingFolder)
    let registry = InMemoryLocalProjectRegistry(projects: [localProject])
    let statusClient = ProjectStatusClientFixture(response: readyClientAppModelProjectStatusFixture)
    let statusStore = MacProjectStatusStore(client: statusClient, session: AteliaSession(), repositoryId: "repo_ready")
    let lifecycleStore = ProjectLifecycleStoreFixture(
        repository: clientAppModelLifecycleRepositoryFixture,
        job: clientAppModelSucceededLifecycleJobFixture,
        jobEvents: [clientAppModelToolResultEventFixture]
    )
    let renderStore = ToolOutputRenderStoreFixture(response: clientAppModelRenderedToolOutputFixture)
    let model = ClientAppModel(
        projectStatusStore: statusStore,
        projectLifecycleStore: lifecycleStore,
        toolOutputRenderStore: renderStore,
        localProjectRegistry: registry
    )

    model.handleComposerIntent(.send(
        text: "search AteliaSubmitJobRequest",
        configuration: ClientMockState.ateliaReference.composer,
        contexts: []
    ))

    _ = await lifecycleStore.waitForSubmitRequest()
    for _ in 0..<20 {
        if !(await renderStore.recordedRequests().isEmpty) {
            break
        }
        try await Task.sleep(for: .milliseconds(10))
    }

    #expect(await renderStore.recordedRequests() == [
        AteliaToolOutputRenderRequest(
            toolResult: clientAppModelRenderedToolOutputFixture.toolResult,
            format: .text
        )
    ])

    let secretaryTurn = try #require(model.shellState.conversation.turns.last)
    #expect(secretaryTurn.id == "turn.secretary.local-draft:\(localProject.id):1")
    let toolOutputBlock = try #require(secretaryTurn.blocks.compactMap { block -> ClientConversationToolOutputFixture? in
        if case .toolOutput(let output) = block {
            return output
        }
        return nil
    }.first)
    #expect(toolOutputBlock.toolName == "filesystem.search")
    if case .succeeded = toolOutputBlock.status {
    } else {
        Issue.record("expected succeeded tool output")
    }
    #expect(toolOutputBlock.output == ["Found 2 matches", "Sources/App.swift:42"])
}

@MainActor
@Test func clientAppModelE2ESmokePathForProjectSecretaryFilesystemSearch() async throws {
    let picker = ProjectFolderSelectionClientFixture()
    let folderURL = URL(fileURLWithPath: "/Users/yohaku/Projects/LifecycleProject")
    picker.existingFolderURL = folderURL
    let expectedProject = LocalProjectRegistration.make(folderURL: folderURL, source: .existingFolder)
    let statusClient = ProjectStatusClientFixture(response: readyClientAppModelProjectStatusFixture)
    let statusStore = MacProjectStatusStore(client: statusClient, session: AteliaSession(), repositoryId: "repo_ready")
    let lifecycleStore = ProjectLifecycleStoreFixture(
        repository: clientAppModelLifecycleRepositoryFixture,
        job: clientAppModelSucceededLifecycleJobFixture,
        jobEvents: [clientAppModelToolResultEventFixture]
    )
    let renderStore = ToolOutputRenderStoreFixture(response: clientAppModelRenderedToolOutputFixture)
    let model = ClientAppModel(
        projectStatusStore: statusStore,
        projectLifecycleStore: lifecycleStore,
        toolOutputRenderStore: renderStore,
        projectFolderSelection: picker
    )

    let useExistingFolderAction = ProjectSectionHeaderViewData.projectSectionHeader.actions.first(where: { $0.kind == .useExistingFolder })!
    model.handleProjectSectionHeaderAction(useExistingFolderAction)

    #expect(picker.existingFolderCallCount == 1)
    #expect(picker.newFolderCallCount == 0)
    #expect(model.localProjects == [expectedProject])
    #expect(model.sidebarProjection.activeSelection.projectID == expectedProject.projectID)

    let openRequest = await lifecycleStore.waitForOpenRequest()
    #expect(openRequest == AteliaRegisterRepositoryRequest(
        displayName: expectedProject.displayName,
        rootPath: expectedProject.rootPath,
        allowedScope: AteliaPathScope(kind: .repository),
        requester: ClientLifecycleRequestIdentity.requester
    ))

    model.handleComposerIntent(.send(
        text: "search AteliaSubmitJobRequest",
        configuration: ClientMockState.ateliaReference.composer,
        contexts: []
    ))

    let submitRequest = await lifecycleStore.waitForSubmitRequest()
    #expect(submitRequest.repositoryId == "repo_lifecycle")
    #expect(submitRequest.requestedCapabilities == ["filesystem.search"])
    #expect(submitRequest.toolArgs == AteliaSubmitJobToolArgs(pattern: "AteliaSubmitJobRequest", max: 20))

    for _ in 0..<20 {
        if !(await renderStore.recordedRequests().isEmpty) {
            break
        }
        try await Task.sleep(for: .milliseconds(10))
    }

    #expect(await renderStore.recordedRequests() == [
        AteliaToolOutputRenderRequest(
            toolResult: clientAppModelRenderedToolOutputFixture.toolResult,
            format: .text
        )
    ])

    let secretaryTurn = try #require(model.shellState.conversation.turns.last)
    #expect(secretaryTurn.id == "turn.secretary.local-draft:\(expectedProject.id):1")
    let toolOutputBlock = try #require(secretaryTurn.blocks.compactMap { block -> ClientConversationToolOutputFixture? in
        if case .toolOutput(let output) = block {
            return output
        }
        return nil
    }.first)
    #expect(toolOutputBlock.toolName == "filesystem.search")
    #expect(toolOutputBlock.command == "search AteliaSubmitJobRequest")
    if case .succeeded = toolOutputBlock.status {
    } else {
        Issue.record("expected succeeded tool output")
    }
    #expect(toolOutputBlock.output == ["Found 2 matches", "Sources/App.swift:42"])
}

@MainActor
@Test func clientAppModelMarksToolOutputFailedWhenRenderingFails() async throws {
    let folderURL = URL(fileURLWithPath: "/Users/yohaku/Projects/LifecycleProject")
    let localProject = LocalProjectRegistration.make(folderURL: folderURL, source: .existingFolder)
    let registry = InMemoryLocalProjectRegistry(projects: [localProject])
    let statusClient = ProjectStatusClientFixture(response: readyClientAppModelProjectStatusFixture)
    let statusStore = MacProjectStatusStore(client: statusClient, session: AteliaSession(), repositoryId: "repo_ready")
    let lifecycleStore = ProjectLifecycleStoreFixture(
        repository: clientAppModelLifecycleRepositoryFixture,
        job: clientAppModelSucceededLifecycleJobFixture,
        jobEvents: [clientAppModelToolResultEventFixture]
    )
    let renderStore = ToolOutputRenderStoreFixture(error: ProjectLifecycleStoreFixtureError.renderFailed)
    let model = ClientAppModel(
        projectStatusStore: statusStore,
        projectLifecycleStore: lifecycleStore,
        toolOutputRenderStore: renderStore,
        localProjectRegistry: registry
    )

    model.handleComposerIntent(.send(
        text: "search AteliaSubmitJobRequest",
        configuration: ClientMockState.ateliaReference.composer,
        contexts: []
    ))

    _ = await lifecycleStore.waitForSubmitRequest()
    for _ in 0..<20 {
        if !(await renderStore.recordedRequests().isEmpty) {
            break
        }
        try await Task.sleep(for: .milliseconds(10))
    }

    let secretaryTurn = try #require(model.shellState.conversation.turns.last)
    let toolOutputBlock = try #require(secretaryTurn.blocks.compactMap { block -> ClientConversationToolOutputFixture? in
        if case .toolOutput(let output) = block {
            return output
        }
        return nil
    }.first)
    if case .failed = toolOutputBlock.status {
    } else {
        Issue.record("expected failed tool output")
    }
    #expect(toolOutputBlock.output == [
        "Phase: render",
        "Endpoint: toolOutputRenderStore.render",
        "Capability: filesystem.search",
        "Model route: models/atelia-balanced",
        "Permission route: permissions/full-access",
        "Job: job_lifecycle",
        "Event: evt_tool_result",
        "Error: render failed"
    ])
}

@MainActor
@Test func clientAppModelMarksToolOutputFailedWhenRenderingStructuredBackendError() async throws {
    let folderURL = URL(fileURLWithPath: "/Users/yohaku/Projects/LifecycleProject")
    let localProject = LocalProjectRegistration.make(folderURL: folderURL, source: .existingFolder)
    let registry = InMemoryLocalProjectRegistry(projects: [localProject])
    let statusClient = ProjectStatusClientFixture(response: readyClientAppModelProjectStatusFixture)
    let statusStore = MacProjectStatusStore(client: statusClient, session: AteliaSession(), repositoryId: "repo_ready")
    let lifecycleStore = ProjectLifecycleStoreFixture(
        repository: clientAppModelLifecycleRepositoryFixture,
        job: clientAppModelSucceededLifecycleJobFixture,
        jobEvents: [clientAppModelToolResultEventFixture]
    )
    let renderStore = ToolOutputRenderStoreFixture(
        error: HTTPAteliaClientError.apiError(
            AteliaAPIError(
                code: "rate_limit",
                reason: "API rate limit reached",
                recoverable: true,
                nextState: "retry_same_request",
                retryAfter: .seconds(2.5),
                auditRef: "audit_abc"
            )
        )
    )
    let model = ClientAppModel(
        projectStatusStore: statusStore,
        projectLifecycleStore: lifecycleStore,
        toolOutputRenderStore: renderStore,
        localProjectRegistry: registry
    )

    model.handleComposerIntent(.send(
        text: "search AteliaSubmitJobRequest",
        configuration: ClientMockState.ateliaReference.composer,
        contexts: []
    ))

    _ = await lifecycleStore.waitForSubmitRequest()
    for _ in 0..<20 {
        if !(await renderStore.recordedRequests().isEmpty) {
            break
        }
        try await Task.sleep(for: .milliseconds(10))
    }

    let secretaryTurn = try #require(model.shellState.conversation.turns.last)
    let toolOutputBlock = try #require(secretaryTurn.blocks.compactMap { block -> ClientConversationToolOutputFixture? in
        if case .toolOutput(let output) = block {
            return output
        }
        return nil
    }.first)
    if case .failed = toolOutputBlock.status {
    } else {
        Issue.record("expected failed tool output")
    }
    #expect(toolOutputBlock.output == [
        "Phase: render",
        "Endpoint: toolOutputRenderStore.render",
        "Capability: filesystem.search",
        "Model route: models/atelia-balanced",
        "Permission route: permissions/full-access",
        "Job: job_lifecycle",
        "Event: evt_tool_result",
        "Code: rate_limit",
        "Reason: API rate limit reached",
        "Recoverable: true",
        "Next action: retry_same_request",
        "Retry after: 2.5s",
        "Audit ref: audit_abc"
    ])
}

@MainActor
@Test func clientAppModelReportsLifecycleSubmitFailureWithoutMarkingSubmitSuccessful() async throws {
    let folderURL = URL(fileURLWithPath: "/Users/yohaku/Projects/LifecycleProject")
    let localProject = LocalProjectRegistration.make(folderURL: folderURL, source: .existingFolder)
    let registry = InMemoryLocalProjectRegistry(projects: [localProject])
    let statusClient = ProjectStatusClientFixture(response: readyClientAppModelProjectStatusFixture)
    let statusStore = MacProjectStatusStore(client: statusClient, session: AteliaSession(), repositoryId: "repo_ready")
    let lifecycleStore = ProjectLifecycleStoreFixture(
        repository: clientAppModelLifecycleRepositoryFixture,
        job: clientAppModelLifecycleJobFixture,
        submitError: ProjectLifecycleStoreFixtureError.submitFailed
    )
    let model = ClientAppModel(
        projectStatusStore: statusStore,
        projectLifecycleStore: lifecycleStore,
        localProjectRegistry: registry
    )

    model.handleComposerIntent(.send(
        text: "進捗を要約して",
        configuration: ClientMockState.ateliaReference.composer,
        contexts: []
    ))

    let ateliaRequest = await lifecycleStore.waitForSubmitRequest()

    #expect(ateliaRequest.repositoryId == "repo_lifecycle")
    #expect(ateliaRequest.kind == "message")
    #expect(ateliaRequest.message == "進捗を要約して")
    #expect(model.lastAteliaSubmitJobRequest == nil)
    let secretaryTurn = try #require(model.shellState.conversation.turns.last)
    let secretaryActivity = try #require(secretaryTurn.blocks.compactMap { block -> ClientConversationActivityFixture? in
        if case .activity(let activity) = block {
            return activity
        }
        return nil
    }.first)
    #expect(secretaryActivity.title == "Secretary ジョブの送信に失敗しました。")
    #expect(secretaryActivity.status == "失敗")
    #expect(secretaryActivity.bullets == [
        "Phase: submit",
        "Endpoint: projectLifecycleStore.submit",
        "Capability: message",
        "Model route: models/atelia-balanced",
        "Permission route: permissions/full-access",
        "Error: submit failed"
    ])
    #expect(model.lastErrorMessage == "submit failed")
}

@MainActor
@Test func clientAppModelReportsLifecycleSubmitFailureWithStructuredBackendError() async throws {
    let folderURL = URL(fileURLWithPath: "/Users/yohaku/Projects/LifecycleProject")
    let localProject = LocalProjectRegistration.make(folderURL: folderURL, source: .existingFolder)
    let registry = InMemoryLocalProjectRegistry(projects: [localProject])
    let statusClient = ProjectStatusClientFixture(response: readyClientAppModelProjectStatusFixture)
    let statusStore = MacProjectStatusStore(client: statusClient, session: AteliaSession(), repositoryId: "repo_ready")
    let lifecycleStore = ProjectLifecycleStoreFixture(
        repository: clientAppModelLifecycleRepositoryFixture,
        job: clientAppModelLifecycleJobFixture,
        submitError: HTTPAteliaClientError.apiError(
            AteliaAPIError(
                code: "validation_error",
                reason: "Invalid project route",
                recoverable: false,
                nextState: "abort_submission",
                retryAfter: nil,
                auditRef: nil
            )
        )
    )
    let model = ClientAppModel(
        projectStatusStore: statusStore,
        projectLifecycleStore: lifecycleStore,
        localProjectRegistry: registry
    )

    model.handleComposerIntent(.send(
        text: "進捗を要約して",
        configuration: ClientMockState.ateliaReference.composer,
        contexts: []
    ))

    let ateliaRequest = await lifecycleStore.waitForSubmitRequest()

    #expect(ateliaRequest.repositoryId == "repo_lifecycle")
    #expect(ateliaRequest.kind == "message")
    #expect(ateliaRequest.message == "進捗を要約して")
    #expect(model.lastAteliaSubmitJobRequest == nil)
    let secretaryTurn = try #require(model.shellState.conversation.turns.last)
    let secretaryActivity = try #require(secretaryTurn.blocks.compactMap { block -> ClientConversationActivityFixture? in
        if case .activity(let activity) = block {
            return activity
        }
        return nil
    }.first)
    #expect(secretaryActivity.bullets == [
        "Phase: submit",
        "Endpoint: projectLifecycleStore.submit",
        "Capability: message",
        "Model route: models/atelia-balanced",
        "Permission route: permissions/full-access",
        "Code: validation_error",
        "Reason: Invalid project route",
        "Recoverable: false",
        "Next action: abort_submission"
    ])
    #expect(model.lastErrorMessage == "validation_error: Invalid project route")
}

@MainActor
@Test func clientAppModelReportsLifecycleSubmitFailureWithHTTPStatusReason() async throws {
    let folderURL = URL(fileURLWithPath: "/Users/yohaku/Projects/LifecycleProject")
    let localProject = LocalProjectRegistration.make(folderURL: folderURL, source: .existingFolder)
    let registry = InMemoryLocalProjectRegistry(projects: [localProject])
    let statusClient = ProjectStatusClientFixture(response: readyClientAppModelProjectStatusFixture)
    let statusStore = MacProjectStatusStore(client: statusClient, session: AteliaSession(), repositoryId: "repo_ready")
    let lifecycleStore = ProjectLifecycleStoreFixture(
        repository: clientAppModelLifecycleRepositoryFixture,
        job: clientAppModelLifecycleJobFixture,
        submitError: HTTPAteliaClientError.unsuccessfulStatus(code: 503, reason: "Service unavailable")
    )
    let model = ClientAppModel(
        projectStatusStore: statusStore,
        projectLifecycleStore: lifecycleStore,
        localProjectRegistry: registry
    )

    model.handleComposerIntent(.send(
        text: "進捗を要約して",
        configuration: ClientMockState.ateliaReference.composer,
        contexts: []
    ))

    _ = await lifecycleStore.waitForSubmitRequest()

    let secretaryTurn = try #require(model.shellState.conversation.turns.last)
    let secretaryActivity = try #require(secretaryTurn.blocks.compactMap { block -> ClientConversationActivityFixture? in
        if case .activity(let activity) = block {
            return activity
        }
        return nil
    }.first)
    #expect(secretaryActivity.bullets == [
        "Phase: submit",
        "Endpoint: projectLifecycleStore.submit",
        "Capability: message",
        "Model route: models/atelia-balanced",
        "Permission route: permissions/full-access",
        "Status: 503",
        "Reason: Service unavailable"
    ])
    #expect(model.lastErrorMessage == "HTTP 503: Service unavailable")
}

@MainActor
@Test func clientAppModelReportsLifecycleEventObservationFailureWithStructuredBackendError() async throws {
    let folderURL = URL(fileURLWithPath: "/Users/yohaku/Projects/LifecycleProject")
    let localProject = LocalProjectRegistration.make(folderURL: folderURL, source: .existingFolder)
    let registry = InMemoryLocalProjectRegistry(projects: [localProject])
    let statusClient = ProjectStatusClientFixture(response: readyClientAppModelProjectStatusFixture)
    let statusStore = MacProjectStatusStore(client: statusClient, session: AteliaSession(), repositoryId: "repo_ready")
    let lifecycleStore = ProjectLifecycleStoreFixture(
        repository: clientAppModelLifecycleRepositoryFixture,
        job: clientAppModelLifecycleJobFixture,
        jobEventsError: HTTPAteliaClientError.apiError(
            AteliaAPIError(
                code: "transient_observation_error",
                reason: "Failed to list events",
                recoverable: true,
                nextState: "retry_same_request",
                retryAfter: .seconds(1.5)
            )
        )
    )
    let model = ClientAppModel(
        projectStatusStore: statusStore,
        projectLifecycleStore: lifecycleStore,
        localProjectRegistry: registry
    )

    model.handleComposerIntent(.send(
        text: "search AteliaSubmitJobRequest",
        configuration: ClientMockState.ateliaReference.composer,
        contexts: []
    ))

    _ = await lifecycleStore.waitForSubmitRequest()
    for _ in 0..<20 {
        let status = model.shellState.conversation.turns.last?.blocks.compactMap { block -> ClientConversationActivityFixture? in
            if case .activity(let activity) = block {
                return activity
            }
            return nil
        }.first?.status
        if status == "結果取得失敗" {
            break
        }
        try await Task.sleep(for: .milliseconds(10))
    }

    let secretaryTurn = try #require(model.shellState.conversation.turns.last)
    let secretaryActivity = try #require(secretaryTurn.blocks.compactMap { block -> ClientConversationActivityFixture? in
        if case .activity(let activity) = block {
            return activity
        }
        return nil
    }.first)
    #expect(secretaryActivity.status == "結果取得失敗")
    #expect(secretaryActivity.title == "Secretary ジョブは送信されましたが、結果を取得できませんでした。")
    #expect(secretaryActivity.bullets == [
        "Phase: event-observation",
        "Endpoint: projectLifecycleStore.listJobEvents",
        "Capability: filesystem.search",
        "Model route: models/atelia-balanced",
        "Permission route: permissions/full-access",
        "Job: job_lifecycle",
        "Code: transient_observation_error",
        "Reason: Failed to list events",
        "Recoverable: true",
        "Next action: retry_same_request",
        "Retry after: 1.5s"
    ])
    #expect(model.lastErrorMessage == "transient_observation_error: Failed to list events")
}

@MainActor
@Test func clientAppModelIgnoresLifecycleSubmitCompletionAfterLocalProjectRemoval() async throws {
    let folderURL = URL(fileURLWithPath: "/Users/yohaku/Projects/LifecycleProject")
    let localProject = LocalProjectRegistration.make(folderURL: folderURL, source: .existingFolder)
    let registry = InMemoryLocalProjectRegistry(projects: [localProject])
    let statusClient = ProjectStatusClientFixture(response: readyClientAppModelProjectStatusFixture)
    let statusStore = MacProjectStatusStore(client: statusClient, session: AteliaSession(), repositoryId: "repo_ready")
    let lifecycleStore = ProjectLifecycleStoreFixture(
        repository: clientAppModelLifecycleRepositoryFixture,
        job: clientAppModelLifecycleJobFixture,
        waitsForSubmitRelease: true
    )
    let model = ClientAppModel(
        projectStatusStore: statusStore,
        projectLifecycleStore: lifecycleStore,
        localProjectRegistry: registry
    )

    model.handleComposerIntent(.send(
        text: "search AteliaSubmitJobRequest",
        configuration: ClientMockState.ateliaReference.composer,
        contexts: []
    ))

    _ = await lifecycleStore.waitForSubmitRequest()
    model.handleSidebarAction(.removeLocalProject(id: localProject.id))
    await lifecycleStore.releaseSubmit()
    await Task.yield()
    await Task.yield()

    #expect(model.localProjects.isEmpty)
    #expect(model.lastAteliaSubmitJobRequest == nil)
    #expect(model.lastErrorMessage == nil)
}

@MainActor
@Test func clientAppModelKeepsLifecycleSubmitCompletionAfterUnrelatedLocalProjectRemoval() async throws {
    let firstFolderURL = URL(fileURLWithPath: "/Users/yohaku/Projects/LifecycleProjectOne")
    let secondFolderURL = URL(fileURLWithPath: "/Users/yohaku/Projects/LifecycleProjectTwo")
    let firstProject = LocalProjectRegistration.make(folderURL: firstFolderURL, source: .existingFolder)
    let secondProject = LocalProjectRegistration.make(folderURL: secondFolderURL, source: .existingFolder)
    let registry = InMemoryLocalProjectRegistry(projects: [firstProject, secondProject])
    let statusClient = ProjectStatusClientFixture(response: readyClientAppModelProjectStatusFixture)
    let statusStore = MacProjectStatusStore(client: statusClient, session: AteliaSession(), repositoryId: "repo_ready")
    let lifecycleStore = ProjectLifecycleStoreFixture(
        repository: clientAppModelLifecycleRepositoryFixture,
        job: clientAppModelLifecycleJobFixture,
        waitsForSubmitRelease: true
    )
    let model = ClientAppModel(
        projectStatusStore: statusStore,
        projectLifecycleStore: lifecycleStore,
        localProjectRegistry: registry
    )

    model.handleComposerIntent(.send(
        text: "search AteliaSubmitJobRequest",
        configuration: ClientMockState.ateliaReference.composer,
        contexts: []
    ))

    let ateliaRequest = await lifecycleStore.waitForSubmitRequest()
    model.handleSidebarAction(.removeLocalProject(id: secondProject.id))
    await lifecycleStore.releaseSubmit()
    await Task.yield()
    await Task.yield()

    #expect(model.localProjects == [firstProject])
    #expect(model.lastAteliaSubmitJobRequest == ateliaRequest)
    #expect(ateliaRequest.pathScope == AteliaPathScope(kind: .explicitPaths, roots: [firstProject.rootPath]))
    #expect(model.lastErrorMessage == nil)
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
            ComposerContextSelection(id: "context:file:test-plan", kind: .file, displayName: "test-plan.md")
        ]
    ))

    #expect(model.shellState.conversation.turns.count == originalTurnCount + 2)

    let userDraft = try #require(model.shellState.conversation.turns.dropLast().last)
    let secretaryDraft = try #require(model.shellState.conversation.turns.last)

    #expect(userDraft.blocks.first?.id == "message.user.local-draft:repo_123:1")
    #expect(secretaryDraft.blocks.first?.id == "activity.secretary.local-draft:repo_123:1")

    guard case .message(let message) = userDraft.blocks.first else {
        Issue.record("Expected user draft to contain a message block")
        return
    }
    #expect(message.attachmentName == "test-plan.md")
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
@Test func clientAppModelKeepsLocalDraftsVisibleWhenBackendSnapshotReplacesMatchingLocalProject() async throws {
    let folderURL = URL(fileURLWithPath: "/workspace/ready-repo")
    let project = LocalProjectRegistration.make(folderURL: folderURL, source: .existingFolder)
    let registry = InMemoryLocalProjectRegistry(projects: [project])
    let client = ProjectStatusClientFixture(response: readyClientAppModelProjectStatusFixture)
    let store = MacProjectStatusStore(client: client, session: AteliaSession(), repositoryId: "repo_ready")
    let model = ClientAppModel(projectStatusStore: store, localProjectRegistry: registry)
    let originalTurnCount = model.shellState.conversation.turns.count

    model.handleComposerIntent(.send(
        text: "ローカル下書きを保持",
        configuration: ClientMockState.ateliaReference.composer,
        contexts: []
    ))

    #expect(model.activeConversationTarget() == .project(repositoryId: project.id))
    #expect(model.shellState.conversation.turns.count == originalTurnCount + 2)

    try await model.reloadProjectStatus()

    #expect(model.sidebarProjection.activeSelection.projectID == "project:repo_ready")
    #expect(model.activeConversationTarget() == .project(repositoryId: "repo_ready"))
    #expect(model.shellState.conversation.turns.count == originalTurnCount + 2)
    #expect(model.shellState.conversation.turns.contains { turn in
        turn.id == "turn.user.local-draft:\(project.id):1"
    })
}

@MainActor
@Test func clientAppModelMigratesHiddenLocalDraftsWhenBackendSnapshotReplacesInactiveProject() async throws {
    let matchingProject = LocalProjectRegistration.make(
        folderURL: URL(fileURLWithPath: "/workspace/ready-repo"),
        source: .existingFolder
    )
    let otherProject = LocalProjectRegistration.make(
        folderURL: URL(fileURLWithPath: "/Users/yohaku/Projects/Other"),
        source: .existingFolder
    )
    let registry = InMemoryLocalProjectRegistry(projects: [matchingProject, otherProject])
    let client = ProjectStatusClientFixture(response: readyClientAppModelProjectStatusFixture)
    let store = MacProjectStatusStore(client: client, session: AteliaSession(), repositoryId: "repo_ready")
    let model = ClientAppModel(projectStatusStore: store, localProjectRegistry: registry)
    let originalTurnCount = model.shellState.conversation.turns.count

    model.handleComposerIntent(.send(
        text: "非アクティブでも下書きを保持",
        configuration: ClientMockState.ateliaReference.composer,
        contexts: []
    ))

    #expect(model.activeConversationTarget() == .project(repositoryId: matchingProject.id))
    #expect(model.shellState.conversation.turns.count == originalTurnCount + 2)

    let otherSecretary = try #require(model.sidebarProjection.workspaceGroups
        .first { $0.id == otherProject.projectID }?
        .items.first { $0.surface == .projectConversation })
    model.handleSidebarAction(.chatItem(
        id: otherSecretary.id,
        projectID: otherSecretary.projectID,
        resourceID: otherSecretary.resourceID,
        title: otherSecretary.title,
        surface: otherSecretary.surface,
        action: try #require(otherSecretary.action)
    ))

    #expect(model.activeConversationTarget() == .project(repositoryId: otherProject.id))

    try await model.reloadProjectStatus()

    #expect(model.sidebarProjection.activeSelection.projectID == otherProject.projectID)
    #expect(model.sidebarProjection.workspaceGroups.map(\.id) == ["project:repo_ready", otherProject.projectID])

    let backendSecretary = try #require(model.sidebarProjection.workspaceGroups
        .first { $0.id == "project:repo_ready" }?
        .items.first { $0.surface == .projectConversation })
    model.handleSidebarAction(.chatItem(
        id: backendSecretary.id,
        projectID: backendSecretary.projectID,
        resourceID: backendSecretary.resourceID,
        title: backendSecretary.title,
        surface: backendSecretary.surface,
        action: try #require(backendSecretary.action)
    ))

    #expect(model.activeConversationTarget() == .project(repositoryId: "repo_ready"))
    #expect(model.shellState.conversation.turns.count == originalTurnCount + 2)
    #expect(model.shellState.conversation.turns.contains { turn in
        turn.id == "turn.user.local-draft:\(matchingProject.id):1"
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
@Test func clientAppModelOpensRegisteredLocalProjectThroughLifecycleStore() async throws {
    let picker = ProjectFolderSelectionClientFixture()
    let folderURL = URL(fileURLWithPath: "/Users/yohaku/Projects/LifecycleProject")
    let expectedProject = LocalProjectRegistration.make(folderURL: folderURL, source: .existingFolder)
    picker.existingFolderURL = folderURL
    let statusClient = ProjectStatusClientFixture(response: readyClientAppModelProjectStatusFixture)
    let statusStore = MacProjectStatusStore(client: statusClient, session: AteliaSession(), repositoryId: "repo_ready")
    let lifecycleStore = ProjectLifecycleStoreFixture(
        repository: clientAppModelLifecycleRepositoryFixture,
        job: clientAppModelLifecycleJobFixture
    )
    let model = ClientAppModel(
        projectStatusStore: statusStore,
        projectLifecycleStore: lifecycleStore,
        projectFolderSelection: picker
    )

    let useExistingFolderAction = ProjectSectionHeaderViewData.projectSectionHeader.actions.first(where: { $0.kind == .useExistingFolder })!
    model.handleProjectSectionHeaderAction(useExistingFolderAction)

    let openRequest = await lifecycleStore.waitForOpenRequest()

    #expect(openRequest == AteliaRegisterRepositoryRequest(
        displayName: expectedProject.displayName,
        rootPath: expectedProject.rootPath,
        allowedScope: AteliaPathScope(kind: .repository),
        requester: ClientLifecycleRequestIdentity.requester
    ))
    #expect(model.localProjects == [expectedProject])
    #expect(model.sidebarProjection.activeSelection.projectID == expectedProject.projectID)
}

@MainActor
@Test func clientAppModelReusesInFlightLocalProjectOpenForImmediateSubmit() async throws {
    let picker = ProjectFolderSelectionClientFixture()
    let folderURL = URL(fileURLWithPath: "/Users/yohaku/Projects/LifecycleProject")
    picker.existingFolderURL = folderURL
    let statusClient = ProjectStatusClientFixture(response: readyClientAppModelProjectStatusFixture)
    let statusStore = MacProjectStatusStore(client: statusClient, session: AteliaSession(), repositoryId: "repo_ready")
    let lifecycleStore = ProjectLifecycleStoreFixture(
        repository: clientAppModelLifecycleRepositoryFixture,
        job: clientAppModelLifecycleJobFixture,
        waitsForOpenRelease: true
    )
    let model = ClientAppModel(
        projectStatusStore: statusStore,
        projectLifecycleStore: lifecycleStore,
        projectFolderSelection: picker
    )

    let useExistingFolderAction = ProjectSectionHeaderViewData.projectSectionHeader.actions.first(where: { $0.kind == .useExistingFolder })!
    model.handleProjectSectionHeaderAction(useExistingFolderAction)
    _ = await lifecycleStore.waitForOpenRequest()

    model.handleComposerIntent(.send(
        text: "search AteliaSubmitJobRequest",
        configuration: ClientMockState.ateliaReference.composer,
        contexts: []
    ))
    await Task.yield()

    #expect(await lifecycleStore.recordedOpenRequests().count == 1)

    await lifecycleStore.releaseOpen()
    let submitRequest = await lifecycleStore.waitForSubmitRequest()

    #expect(await lifecycleStore.recordedOpenRequests().count == 1)
    #expect(submitRequest.repositoryId == "repo_lifecycle")
}

@MainActor
@Test func clientAppModelSubmitsMultipleRapidComposerSends() async throws {
    let picker = ProjectFolderSelectionClientFixture()
    let folderURL = URL(fileURLWithPath: "/Users/yohaku/Projects/LifecycleProject")
    picker.existingFolderURL = folderURL
    let statusClient = ProjectStatusClientFixture(response: readyClientAppModelProjectStatusFixture)
    let statusStore = MacProjectStatusStore(client: statusClient, session: AteliaSession(), repositoryId: "repo_ready")
    let lifecycleStore = ProjectLifecycleStoreFixture(
        repository: clientAppModelLifecycleRepositoryFixture,
        job: clientAppModelLifecycleJobFixture,
        waitsForOpenRelease: true
    )
    let model = ClientAppModel(
        projectStatusStore: statusStore,
        projectLifecycleStore: lifecycleStore,
        projectFolderSelection: picker
    )

    let useExistingFolderAction = ProjectSectionHeaderViewData.projectSectionHeader.actions.first(where: { $0.kind == .useExistingFolder })!
    model.handleProjectSectionHeaderAction(useExistingFolderAction)
    _ = await lifecycleStore.waitForOpenRequest()

    model.handleComposerIntent(.send(
        text: "search first",
        configuration: ClientMockState.ateliaReference.composer,
        contexts: []
    ))
    model.handleComposerIntent(.send(
        text: "search second",
        configuration: ClientMockState.ateliaReference.composer,
        contexts: []
    ))

    #expect(await lifecycleStore.recordedOpenRequests().count == 1)

    await lifecycleStore.releaseOpen()
    let submitRequests = await lifecycleStore.waitForSubmitRequestCount(2)

    #expect(await lifecycleStore.recordedOpenRequests().count == 1)
    #expect(Set(submitRequests.compactMap(\.message)) == Set(["search first", "search second"]))
    #expect(submitRequests.allSatisfy { $0.repositoryId == "repo_lifecycle" })

    for _ in 0..<20 {
        let statuses = model.shellState.conversation.turns.compactMap { turn -> String? in
            guard turn.actor == .secretary,
                  case .activity(let activity) = turn.blocks.first else {
                return nil
            }
            return activity.status
        }
        if statuses.filter({ $0 != "下書き" }).count >= 2 {
            break
        }
        try await Task.sleep(for: .milliseconds(10))
    }

    let secretaryTurns = model.shellState.conversation.turns.filter { $0.actor == .secretary }
    #expect(secretaryTurns.contains { turn in
        guard turn.id == "turn.secretary.local-draft:\(model.localProjects[0].id):1",
              case .activity(let activity) = turn.blocks.first else {
            return false
        }
        return activity.id == "activity.secretary.local-draft:\(model.localProjects[0].id):1"
            && activity.status != "下書き"
    })
    #expect(secretaryTurns.contains { turn in
        guard turn.id == "turn.secretary.local-draft:\(model.localProjects[0].id):2",
              case .activity(let activity) = turn.blocks.first else {
            return false
        }
        return activity.id == "activity.secretary.local-draft:\(model.localProjects[0].id):2"
            && activity.status != "下書き"
    })
}

@MainActor
@Test func clientAppModelIgnoresLifecycleSubmitCompletionAfterClear() async throws {
    let folderURL = URL(fileURLWithPath: "/Users/yohaku/Projects/LifecycleProject")
    let localProject = LocalProjectRegistration.make(folderURL: folderURL, source: .existingFolder)
    let registry = InMemoryLocalProjectRegistry(projects: [localProject])
    let statusClient = ProjectStatusClientFixture(response: readyClientAppModelProjectStatusFixture)
    let statusStore = MacProjectStatusStore(client: statusClient, session: AteliaSession(), repositoryId: "repo_ready")
    let lifecycleStore = ProjectLifecycleStoreFixture(
        repository: clientAppModelLifecycleRepositoryFixture,
        job: clientAppModelLifecycleJobFixture,
        waitsForSubmitRelease: true
    )
    let model = ClientAppModel(
        projectStatusStore: statusStore,
        projectLifecycleStore: lifecycleStore,
        localProjectRegistry: registry
    )

    model.handleComposerIntent(.send(
        text: "search AteliaSubmitJobRequest",
        configuration: ClientMockState.ateliaReference.composer,
        contexts: []
    ))

    _ = await lifecycleStore.waitForSubmitRequest()
    await model.clearProjectStatus()
    await lifecycleStore.releaseSubmit()
    await Task.yield()
    await Task.yield()

    #expect(model.localProjects.isEmpty)
    #expect(model.lastAteliaSubmitJobRequest == nil)
    #expect(model.lastErrorMessage == nil)
}

@MainActor
@Test func clientAppModelIgnoresJobEventCompletionAfterClear() async throws {
    let folderURL = URL(fileURLWithPath: "/Users/yohaku/Projects/LifecycleProject")
    let localProject = LocalProjectRegistration.make(folderURL: folderURL, source: .existingFolder)
    let registry = InMemoryLocalProjectRegistry(projects: [localProject])
    let statusClient = ProjectStatusClientFixture(response: readyClientAppModelProjectStatusFixture)
    let statusStore = MacProjectStatusStore(client: statusClient, session: AteliaSession(), repositoryId: "repo_ready")
    let lifecycleStore = ProjectLifecycleStoreFixture(
        repository: clientAppModelLifecycleRepositoryFixture,
        job: clientAppModelSucceededLifecycleJobFixture,
        jobEvents: [clientAppModelToolResultEventFixture],
        waitsForJobEventsRelease: true
    )
    let model = ClientAppModel(
        projectStatusStore: statusStore,
        projectLifecycleStore: lifecycleStore,
        localProjectRegistry: registry
    )

    model.handleComposerIntent(.send(
        text: "search AteliaSubmitJobRequest",
        configuration: ClientMockState.ateliaReference.composer,
        contexts: []
    ))

    _ = await lifecycleStore.waitForSubmitRequest()
    await model.clearProjectStatus()
    await lifecycleStore.releaseJobEvents()
    await Task.yield()
    await Task.yield()

    #expect(model.localProjects.isEmpty)
    #expect(model.shellState.conversation.turns.allSatisfy { turn in
        !turn.id.contains("local-draft:\(localProject.id)")
    })
}

@MainActor
@Test func clientAppModelIgnoresStaleJobEventCompletionAfterProjectReadd() async throws {
    let picker = ProjectFolderSelectionClientFixture()
    let folderURL = URL(fileURLWithPath: "/Users/yohaku/Projects/LifecycleProject")
    picker.existingFolderURL = folderURL
    let localProject = LocalProjectRegistration.make(folderURL: folderURL, source: .existingFolder)
    let registry = InMemoryLocalProjectRegistry(projects: [localProject])
    let statusClient = ProjectStatusClientFixture(response: readyClientAppModelProjectStatusFixture)
    let statusStore = MacProjectStatusStore(client: statusClient, session: AteliaSession(), repositoryId: "repo_ready")
    let lifecycleStore = ProjectLifecycleStoreFixture(
        repository: clientAppModelLifecycleRepositoryFixture,
        job: clientAppModelSucceededLifecycleJobFixture,
        jobEvents: [clientAppModelToolResultEventFixture],
        waitsForJobEventsRelease: true
    )
    let renderStore = ToolOutputRenderStoreFixture(response: clientAppModelRenderedToolOutputFixture)
    let model = ClientAppModel(
        projectStatusStore: statusStore,
        projectLifecycleStore: lifecycleStore,
        toolOutputRenderStore: renderStore,
        projectFolderSelection: picker,
        localProjectRegistry: registry
    )

    model.handleComposerIntent(.send(
        text: "search first",
        configuration: ClientMockState.ateliaReference.composer,
        contexts: []
    ))
    _ = await lifecycleStore.waitForSubmitRequest()

    await model.clearProjectStatus()

    let useExistingFolderAction = ProjectSectionHeaderViewData.projectSectionHeader.actions.first(where: { $0.kind == .useExistingFolder })!
    model.handleProjectSectionHeaderAction(useExistingFolderAction)
    _ = await lifecycleStore.waitForOpenRequest()

    model.handleComposerIntent(.send(
        text: "search second",
        configuration: ClientMockState.ateliaReference.composer,
        contexts: []
    ))
    _ = await lifecycleStore.waitForSubmitRequestCount(2)

    await lifecycleStore.releaseJobEvents()
    for _ in 0..<20 {
        if await renderStore.recordedRequests().count == 1 {
            break
        }
        try await Task.sleep(for: .milliseconds(10))
    }

    #expect(await renderStore.recordedRequests().count == 1)
    #expect(model.shellState.conversation.turns.contains(where: { turn in
        turn.actor == .user && turn.blocks.contains(where: { block in
            if case .message(let message) = block {
                return message.text == "search second"
            }
            return false
        })
    }))
    #expect(model.shellState.conversation.turns.allSatisfy { turn in
        !turn.blocks.contains(where: { block in
            if case .message(let message) = block {
                return message.text == "search first"
            }
            return false
        })
    })
}

@MainActor
@Test func clientAppModelIgnoresStaleJobEventCompletionAfterLocalProjectRemoveAndReadd() async throws {
    let picker = ProjectFolderSelectionClientFixture()
    let folderURL = URL(fileURLWithPath: "/Users/yohaku/Projects/LifecycleProject")
    picker.existingFolderURL = folderURL
    let localProject = LocalProjectRegistration.make(folderURL: folderURL, source: .existingFolder)
    let registry = InMemoryLocalProjectRegistry(projects: [localProject])
    let statusClient = ProjectStatusClientFixture(response: readyClientAppModelProjectStatusFixture)
    let statusStore = MacProjectStatusStore(client: statusClient, session: AteliaSession(), repositoryId: "repo_ready")
    let lifecycleStore = ProjectLifecycleStoreFixture(
        repository: clientAppModelLifecycleRepositoryFixture,
        job: clientAppModelSucceededLifecycleJobFixture,
        jobEvents: [clientAppModelToolResultEventFixture],
        waitsForJobEventsRelease: true
    )
    let renderStore = ToolOutputRenderStoreFixture(response: clientAppModelRenderedToolOutputFixture)
    let model = ClientAppModel(
        projectStatusStore: statusStore,
        projectLifecycleStore: lifecycleStore,
        toolOutputRenderStore: renderStore,
        projectFolderSelection: picker,
        localProjectRegistry: registry
    )

    model.handleComposerIntent(.send(
        text: "search first",
        configuration: ClientMockState.ateliaReference.composer,
        contexts: []
    ))
    _ = await lifecycleStore.waitForSubmitRequest()

    model.handleSidebarAction(.removeLocalProject(id: localProject.id))
    let useExistingFolderAction = ProjectSectionHeaderViewData.projectSectionHeader.actions.first(where: { $0.kind == .useExistingFolder })!
    model.handleProjectSectionHeaderAction(useExistingFolderAction)
    _ = await lifecycleStore.waitForOpenRequest()

    model.handleComposerIntent(.send(
        text: "search second",
        configuration: ClientMockState.ateliaReference.composer,
        contexts: []
    ))
    _ = await lifecycleStore.waitForSubmitRequestCount(2)

    await lifecycleStore.releaseJobEvents()
    for _ in 0..<20 {
        if await renderStore.recordedRequests().count == 1 {
            break
        }
        try await Task.sleep(for: .milliseconds(10))
    }

    #expect(await renderStore.recordedRequests().count == 1)
    #expect(model.shellState.conversation.turns.contains(where: { turn in
        turn.actor == .user && turn.blocks.contains(where: { block in
            if case .message(let message) = block {
                return message.text == "search second"
            }
            return false
        })
    }))
    #expect(model.shellState.conversation.turns.allSatisfy { turn in
        !turn.blocks.contains(where: { block in
            if case .message(let message) = block {
                return message.text == "search first"
            }
            return false
        })
    })
}

@MainActor
@Test func clientAppModelUpdatesToolResultAfterLocalDraftMigratesToBackendSnapshot() async throws {
    let folderURL = URL(fileURLWithPath: "/workspace/atelia-kit")
    let localProject = LocalProjectRegistration.make(folderURL: folderURL, source: .existingFolder)
    let registry = InMemoryLocalProjectRegistry(projects: [localProject])
    let statusClient = ProjectStatusClientFixture(response: clientAppModelProjectStatusFixture)
    let statusStore = MacProjectStatusStore(client: statusClient, session: AteliaSession(), repositoryId: "repo_123")
    let lifecycleStore = ProjectLifecycleStoreFixture(
        repository: clientAppModelLifecycleRepositoryFixture,
        job: clientAppModelSucceededLifecycleJobFixture,
        jobEvents: [clientAppModelToolResultEventFixture],
        waitsForJobEventsRelease: true
    )
    let renderStore = ToolOutputRenderStoreFixture(response: clientAppModelRenderedToolOutputFixture)
    let model = ClientAppModel(
        projectStatusStore: statusStore,
        projectLifecycleStore: lifecycleStore,
        toolOutputRenderStore: renderStore,
        localProjectRegistry: registry
    )

    model.handleComposerIntent(.send(
        text: "search AteliaSubmitJobRequest",
        configuration: ClientMockState.ateliaReference.composer,
        contexts: []
    ))
    _ = await lifecycleStore.waitForSubmitRequest()

    try await model.reloadProjectStatus()
    #expect(model.sidebarProjection.activeSelection.projectID == "project:repo_123")

    await lifecycleStore.releaseJobEvents()
    for _ in 0..<20 {
        if await renderStore.recordedRequests().count == 1 {
            break
        }
        try await Task.sleep(for: .milliseconds(10))
    }

    let secretaryTurn = try #require(model.shellState.conversation.turns.last)
    #expect(secretaryTurn.id == "turn.secretary.local-draft:\(localProject.id):1")
    let toolOutputBlock = try #require(secretaryTurn.blocks.compactMap { block -> ClientConversationToolOutputFixture? in
        if case .toolOutput(let output) = block {
            return output
        }
        return nil
    }.first)
    #expect(toolOutputBlock.output == ["Found 2 matches", "Sources/App.swift:42"])
}

@MainActor
@Test func clientAppModelReportsLocalProjectOpenFailure() async throws {
    let picker = ProjectFolderSelectionClientFixture()
    let folderURL = URL(fileURLWithPath: "/Users/yohaku/Projects/LifecycleProject")
    picker.existingFolderURL = folderURL
    let statusClient = ProjectStatusClientFixture(response: readyClientAppModelProjectStatusFixture)
    let statusStore = MacProjectStatusStore(client: statusClient, session: AteliaSession(), repositoryId: "repo_ready")
    let lifecycleStore = ProjectLifecycleStoreFixture(
        repository: clientAppModelLifecycleRepositoryFixture,
        job: clientAppModelLifecycleJobFixture,
        openError: ProjectLifecycleStoreFixtureError.openFailed
    )
    let model = ClientAppModel(
        projectStatusStore: statusStore,
        projectLifecycleStore: lifecycleStore,
        projectFolderSelection: picker
    )

    let useExistingFolderAction = ProjectSectionHeaderViewData.projectSectionHeader.actions.first(where: { $0.kind == .useExistingFolder })!
    model.handleProjectSectionHeaderAction(useExistingFolderAction)
    _ = await lifecycleStore.waitForOpenRequest()
    for _ in 0..<10 {
        await Task.yield()
    }

    #expect(model.lastErrorMessage == "open failed")
}

@MainActor
@Test func clientAppModelSuppressesLocalProjectOpenCancellationError() async throws {
    let picker = ProjectFolderSelectionClientFixture()
    let folderURL = URL(fileURLWithPath: "/Users/yohaku/Projects/LifecycleProject")
    picker.existingFolderURL = folderURL
    let statusClient = ProjectStatusClientFixture(response: readyClientAppModelProjectStatusFixture)
    let statusStore = MacProjectStatusStore(client: statusClient, session: AteliaSession(), repositoryId: "repo_ready")
    let lifecycleStore = ProjectLifecycleStoreFixture(
        repository: clientAppModelLifecycleRepositoryFixture,
        job: clientAppModelLifecycleJobFixture,
        openError: CancellationError()
    )
    let model = ClientAppModel(
        projectStatusStore: statusStore,
        projectLifecycleStore: lifecycleStore,
        projectFolderSelection: picker
    )

    let useExistingFolderAction = ProjectSectionHeaderViewData.projectSectionHeader.actions.first(where: { $0.kind == .useExistingFolder })!
    model.handleProjectSectionHeaderAction(useExistingFolderAction)
    _ = await lifecycleStore.waitForOpenRequest()
    for _ in 0..<10 {
        await Task.yield()
    }

    #expect(model.lastErrorMessage == nil)
}

@MainActor
@Test func clientAppModelIgnoresLocalProjectOpenFailureAfterRemoval() async throws {
    let picker = ProjectFolderSelectionClientFixture()
    let folderURL = URL(fileURLWithPath: "/Users/yohaku/Projects/LifecycleProject")
    let expectedProject = LocalProjectRegistration.make(folderURL: folderURL, source: .existingFolder)
    picker.existingFolderURL = folderURL
    let statusClient = ProjectStatusClientFixture(response: readyClientAppModelProjectStatusFixture)
    let statusStore = MacProjectStatusStore(client: statusClient, session: AteliaSession(), repositoryId: "repo_ready")
    let lifecycleStore = ProjectLifecycleStoreFixture(
        repository: clientAppModelLifecycleRepositoryFixture,
        job: clientAppModelLifecycleJobFixture,
        openError: ProjectLifecycleStoreFixtureError.openFailed
    )
    let model = ClientAppModel(
        projectStatusStore: statusStore,
        projectLifecycleStore: lifecycleStore,
        projectFolderSelection: picker
    )

    let useExistingFolderAction = ProjectSectionHeaderViewData.projectSectionHeader.actions.first(where: { $0.kind == .useExistingFolder })!
    model.handleProjectSectionHeaderAction(useExistingFolderAction)
    _ = await lifecycleStore.waitForOpenRequest()

    model.handleSidebarAction(.removeLocalProject(id: expectedProject.id))
    await lifecycleStore.releaseOpen()
    await Task.yield()
    await Task.yield()

    #expect(model.localProjects.isEmpty)
    #expect(model.lastErrorMessage == nil)
}

@MainActor
@Test func clientAppModelCanRetryLocalProjectOpenAfterFailure() async throws {
    let picker = ProjectFolderSelectionClientFixture()
    let folderURL = URL(fileURLWithPath: "/Users/yohaku/Projects/LifecycleProject")
    picker.existingFolderURL = folderURL
    let statusClient = ProjectStatusClientFixture(response: readyClientAppModelProjectStatusFixture)
    let statusStore = MacProjectStatusStore(client: statusClient, session: AteliaSession(), repositoryId: "repo_ready")
    let lifecycleStore = ProjectLifecycleStoreFixture(
        repository: clientAppModelLifecycleRepositoryFixture,
        job: clientAppModelLifecycleJobFixture,
        openError: ProjectLifecycleStoreFixtureError.openFailed
    )
    let model = ClientAppModel(
        projectStatusStore: statusStore,
        projectLifecycleStore: lifecycleStore,
        projectFolderSelection: picker
    )

    let useExistingFolderAction = ProjectSectionHeaderViewData.projectSectionHeader.actions.first(where: { $0.kind == .useExistingFolder })!
    model.handleProjectSectionHeaderAction(useExistingFolderAction)
    _ = await lifecycleStore.waitForOpenRequest()
    for _ in 0..<10 {
        await Task.yield()
    }

    model.handleComposerIntent(.send(
        text: "search AteliaSubmitJobRequest",
        configuration: ClientMockState.ateliaReference.composer,
        contexts: []
    ))

    let submitRequest = await lifecycleStore.waitForSubmitRequest()

    #expect(await lifecycleStore.recordedOpenRequests().count == 2)
    #expect(submitRequest.repositoryId == "repo_lifecycle")
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
