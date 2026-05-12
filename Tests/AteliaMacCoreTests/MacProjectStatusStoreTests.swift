import AteliaKit
import Foundation
import Testing
@testable import AteliaMacCore

private actor ProjectStatusClientFixture: AteliaClient {
    private let response: AteliaProjectStatus
    private var callCount = 0
    private var requestedRepositoryIDs: [String] = []

    init(response: AteliaProjectStatus) {
        self.response = response
    }

    func projectStatus(
        for session: AteliaSession,
        repositoryId: String
    ) async throws -> AteliaProjectStatus {
        _ = session
        callCount += 1
        requestedRepositoryIDs.append(repositoryId)
        return response
    }

    func calls() -> Int {
        callCount
    }

    func repositoryIDs() -> [String] {
        requestedRepositoryIDs
    }
}

private let projectStatusStoreFixture = AteliaProjectStatus(
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
        ),
        AteliaPolicyDecision(
            decisionId: "pol_456",
            outcome: .needsApproval,
            riskTier: .r3,
            requestedCapability: "filesystem.write",
            reasonCode: "approval_required",
            reason: "Writes need explicit approval"
        )
    ],
    latestCursor: AteliaEventCursor(sequence: 17, eventId: "evt_123"),
    daemonStatus: .ready,
    storageStatus: .migrating
)

@Test func reloadPopulatesDerivedMacState() async throws {
    let client = ProjectStatusClientFixture(response: projectStatusStoreFixture)
    let store = MacProjectStatusStore(client: client, session: AteliaSession(), repositoryId: "repo_123")

    try await store.reload()

    #expect(await client.calls() == 1)
    #expect(await client.repositoryIDs() == ["repo_123"])
    #expect(await store.repositoryId == "repo_123")
    #expect(await store.snapshot == MacProjectStatusSnapshot(status: projectStatusStoreFixture))
    #expect(await store.repositoryDisplayName == "Atelia Kit")
    #expect(await store.repositoryRootPath == "/workspace/atelia-kit")
    #expect(await store.daemonLabel == "Daemon 0.2.0 | Ready")
    #expect(await store.storageLabel == "Storage 0.2.0 | Migrating")
    #expect(await store.latestCursor == AteliaEventCursor(sequence: 17, eventId: "evt_123"))
    #expect(await store.recentJobs.count == 2)
    #expect(await store.recentPolicyDecisions.count == 2)
}

@Test func clearResetsDerivedMacStateAndKeepsRepositoryId() async throws {
    let client = ProjectStatusClientFixture(response: projectStatusStoreFixture)
    let store = MacProjectStatusStore(client: client, session: AteliaSession(), repositoryId: "repo_123")

    try await store.reload()
    await store.clear()

    #expect(await store.repositoryId == "repo_123")
    #expect(await store.snapshot == nil)
    #expect(await store.repositoryDisplayName == nil)
    #expect(await store.repositoryRootPath == nil)
    #expect(await store.daemonLabel == nil)
    #expect(await store.storageLabel == nil)
    #expect(await store.latestCursor == nil)
    #expect(await store.recentJobs.isEmpty)
    #expect(await store.recentPolicyDecisions.isEmpty)
}
