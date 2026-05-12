import AteliaKit
import Testing
@testable import AteliaMacCore

private let projectStatusSnapshotFixture = AteliaProjectStatus(
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

private let unknownProjectStatusSnapshotFixture = AteliaProjectStatus(
    metadata: AteliaProtocolMetadata(
        protocolVersion: "1.0.0",
        daemonVersion: "0.2.0",
        storageVersion: "0.2.0",
        capabilities: ["project_status.v1"]
    ),
    repository: AteliaRepository(
        repositoryId: "repo_future",
        displayName: "Future Repo",
        rootPath: "/workspace/future",
        allowedScope: AteliaPathScope(kind: .repository),
        trustState: .trusted,
        createdAtUnixMilliseconds: 1710000000000,
        updatedAtUnixMilliseconds: 1710000100000
    ),
    recentJobs: [
        AteliaJob(
            jobId: "job_future",
            repositoryId: "repo_future",
            requester: .unknown(rawValue: "external", id: "actor_123", displayName: nil),
            kind: "sync",
            goal: "Keep going",
            status: .unrecognized("paused_elsewhere"),
            createdAtUnixMilliseconds: 1710000003000
        )
    ],
    recentPolicyDecisions: [
        AteliaPolicyDecision(
            decisionId: "pol_future",
            outcome: .unknown("deferred"),
            riskTier: .unknown("R9"),
            requestedCapability: "future.capability",
            reasonCode: "future_reason",
            reason: "Future reason"
        )
    ],
    latestCursor: nil,
    daemonStatus: .unknown("warming_up"),
    storageStatus: .unknown("sealed")
)

@Test func projectStatusSnapshotMapsPresentationSafeFields() {
    let snapshot = MacProjectStatusSnapshot(status: projectStatusSnapshotFixture)

    #expect(snapshot.repositoryId == "repo_123")
    #expect(snapshot.repositoryDisplayName == "Atelia Kit")
    #expect(snapshot.repositoryRootPath == "/workspace/atelia-kit")
    #expect(snapshot.daemonLabel == "Daemon 0.2.0 | Ready")
    #expect(snapshot.storageLabel == "Storage 0.2.0 | Migrating")
    #expect(snapshot.latestCursor == AteliaEventCursor(sequence: 17, eventId: "evt_123"))
    #expect(snapshot.latestCursorLabel == "Sequence 17 | Event evt_123")
    #expect(snapshot.recentJobs.count == 2)
    #expect(snapshot.recentJobs[0].id == "job_123")
    #expect(snapshot.recentJobs[0].statusLabel == "Running")
    #expect(snapshot.recentJobs[0].requesterLabel == "Secretary")
    #expect(snapshot.recentJobs[0].kindLabel == "tool")
    #expect(snapshot.recentJobs[0].goalLabel == "Read package manifest")
    #expect(snapshot.recentJobs[0].latestEventId == "evt_123")
    #expect(snapshot.recentJobs[1].id == "job_456")
    #expect(snapshot.recentJobs[1].statusLabel == "Queued")
    #expect(snapshot.recentJobs[1].requesterLabel == "Aki")
    #expect(snapshot.recentJobs[1].kindLabel == "review")
    #expect(snapshot.recentJobs[1].goalLabel == "Check protocol shapes")
    #expect(snapshot.recentJobs[1].latestEventId == nil)
    #expect(snapshot.recentPolicyDecisions.count == 2)
    #expect(snapshot.recentPolicyDecisions[0].id == "pol_123")
    #expect(snapshot.recentPolicyDecisions[0].outcomeLabel == "Allowed")
    #expect(snapshot.recentPolicyDecisions[0].riskTierLabel == "R1")
    #expect(snapshot.recentPolicyDecisions[0].requestedCapabilityLabel == "filesystem.read")
    #expect(snapshot.recentPolicyDecisions[0].reasonCodeLabel == "bounded_read")
    #expect(snapshot.recentPolicyDecisions[0].reasonLabel == "Read-only access is sufficient")
    #expect(snapshot.recentPolicyDecisions[1].id == "pol_456")
    #expect(snapshot.recentPolicyDecisions[1].outcomeLabel == "Needs approval")
    #expect(snapshot.recentPolicyDecisions[1].riskTierLabel == "R3")
    #expect(snapshot.recentPolicyDecisions[1].requestedCapabilityLabel == "filesystem.write")
    #expect(snapshot.recentPolicyDecisions[1].reasonCodeLabel == "approval_required")
    #expect(snapshot.recentPolicyDecisions[1].reasonLabel == "Writes need explicit approval")
}

@Test func projectStatusSnapshotKeepsUnknownValuesVisible() {
    let snapshot = MacProjectStatusSnapshot(status: unknownProjectStatusSnapshotFixture)

    #expect(snapshot.daemonLabel == "Daemon 0.2.0 | Unknown: warming_up")
    #expect(snapshot.storageLabel == "Storage 0.2.0 | Unknown: sealed")
    #expect(snapshot.latestCursor == nil)
    #expect(snapshot.latestCursorLabel == nil)
    #expect(snapshot.recentJobs.count == 1)
    #expect(snapshot.recentJobs[0].id == "job_future")
    #expect(snapshot.recentJobs[0].statusLabel == "Unknown: paused_elsewhere")
    #expect(snapshot.recentJobs[0].requesterLabel == "Unknown external actor_123")
    #expect(snapshot.recentJobs[0].kindLabel == "sync")
    #expect(snapshot.recentJobs[0].goalLabel == "Keep going")
    #expect(snapshot.recentJobs[0].latestEventId == nil)
    #expect(snapshot.recentPolicyDecisions.count == 1)
    #expect(snapshot.recentPolicyDecisions[0].id == "pol_future")
    #expect(snapshot.recentPolicyDecisions[0].outcomeLabel == "Unknown: deferred")
    #expect(snapshot.recentPolicyDecisions[0].riskTierLabel == "R9")
    #expect(snapshot.recentPolicyDecisions[0].requestedCapabilityLabel == "future.capability")
    #expect(snapshot.recentPolicyDecisions[0].reasonCodeLabel == "future_reason")
    #expect(snapshot.recentPolicyDecisions[0].reasonLabel == "Future reason")
}

@Test func projectStatusSnapshotFallsBackForEmptyRequesterDisplayNames() {
    let status = AteliaProjectStatus(
        metadata: AteliaProtocolMetadata(
            protocolVersion: "1.0.0",
            daemonVersion: "0.2.0",
            storageVersion: "0.2.0",
            capabilities: ["project_status.v1"]
        ),
        repository: AteliaRepository(
            repositoryId: "repo_empty_names",
            displayName: "Empty Names",
            rootPath: "/workspace/empty-names",
            allowedScope: AteliaPathScope(kind: .repository),
            trustState: .trusted,
            createdAtUnixMilliseconds: 1710000000000,
            updatedAtUnixMilliseconds: 1710000100000
        ),
        recentJobs: [
            AteliaJob(
                jobId: "job_user_empty",
                repositoryId: "repo_empty_names",
                requester: .user(id: "user_empty", displayName: ""),
                kind: "review",
                goal: "Review",
                status: .queued,
                createdAtUnixMilliseconds: 1710000000000
            ),
            AteliaJob(
                jobId: "job_agent_empty",
                repositoryId: "repo_empty_names",
                requester: .agent(id: "agent_empty", displayName: ""),
                kind: "tool",
                goal: "Run tool",
                status: .running,
                createdAtUnixMilliseconds: 1710000001000
            )
        ],
        recentPolicyDecisions: [],
        latestCursor: nil,
        daemonStatus: .ready,
        storageStatus: .ready
    )

    let snapshot = MacProjectStatusSnapshot(status: status)

    #expect(snapshot.recentJobs[0].requesterLabel == "User")
    #expect(snapshot.recentJobs[1].requesterLabel == "Agent")
}
