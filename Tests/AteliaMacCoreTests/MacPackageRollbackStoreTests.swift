import AteliaKit
import Testing
@testable import AteliaMacCore

private actor PackageRollbackClientFixture: AteliaClient {
    private let responses: [Result<AteliaPackageRollbackResponse, Error>]
    private var callCount = 0
    private var requestedPackageIDList: [String] = []
    private var nextResponseIndex = 0

    init(responses: [Result<AteliaPackageRollbackResponse, Error>]) {
        self.responses = responses
    }

    func packageRollbackResponse(
        for session: AteliaSession,
        packageId: String
    ) async throws -> AteliaPackageRollbackResponse {
        _ = session
        callCount += 1
        requestedPackageIDList.append(packageId)

        guard nextResponseIndex < responses.count else {
            throw AteliaClientError.packageRollbackUnavailable
        }
        let result = responses[nextResponseIndex]
        nextResponseIndex += 1
        return try result.get()
    }

    func calls() -> Int {
        callCount
    }

    func requestedPackageIds() -> [String] {
        requestedPackageIDList
    }
}

private actor ControllablePackageRollbackClientFixture: AteliaClient {
    private var continuations: [CheckedContinuation<AteliaPackageRollbackResponse, any Error>] = []
    private var callCount = 0
    private var requestedPackageIDList: [String] = []

    func packageRollbackResponse(
        for session: AteliaSession,
        packageId: String
    ) async throws -> AteliaPackageRollbackResponse {
        _ = session
        callCount += 1
        requestedPackageIDList.append(packageId)

        return try await withCheckedThrowingContinuation { continuation in
            continuations.append(continuation)
        }
    }

    func calls() -> Int {
        callCount
    }

    func requestedPackageIds() -> [String] {
        requestedPackageIDList
    }

    func respond(to index: Int, with result: Result<AteliaPackageRollbackResponse, any Error>) {
        continuations[index].resume(with: result)
    }
}

private let packageRollbackFixtureResponse = AteliaPackageRollbackResponse(
    metadata: AteliaProtocolMetadata(
        protocolVersion: "1.0.0",
        daemonVersion: "0.2.0",
        storageVersion: "0.2.0",
        capabilities: ["extensions.rollback.v1"]
    ),
    record: AteliaPackageRollbackRecord(
        packageId: "com.example.review.extension",
        version: "1.0.0",
        manifestDigest: "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
        artifactDigest: "sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
        source: .init(
            source: "github",
            repository: "https://github.com/example/review",
            sourceRef: "refs/tags/v1.0.0"
        ),
        boundary: .official,
        status: .installedPreviousVersion,
        previousVersion: "2.0.0",
        approvedPermissions: ["repo.read"],
        rollbackSnapshot: .init(
            manifestDigest: "sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc",
            artifactDigest: "sha256:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd"
        )
    )
)

@Test func rollbackStoresLatestSnapshotAndMetadata() async throws {
    let client = PackageRollbackClientFixture(responses: [.success(packageRollbackFixtureResponse)])
    let store = MacPackageRollbackStore(client: client, session: AteliaSession())

    try await store.rollback(packageId: "com.example.review.extension")

    let expectedSnapshot = MacPackageRollbackSnapshot(record: packageRollbackFixtureResponse.record)

    #expect(await client.calls() == 1)
    #expect(await client.requestedPackageIds() == ["com.example.review.extension"])
    #expect(await store.metadata == packageRollbackFixtureResponse.metadata)
    #expect(await store.packageId == "com.example.review.extension")
    #expect(await store.snapshot == expectedSnapshot)
    #expect(await store.record == packageRollbackFixtureResponse.record)
}

@Test func rollbackSurfacesErrorsAndKeepsExistingSnapshotOnFailure() async throws {
    let client = PackageRollbackClientFixture(responses: [
        .success(packageRollbackFixtureResponse),
        .failure(AteliaClientError.packageRollbackUnavailable)
    ])
    let store = MacPackageRollbackStore(client: client, session: AteliaSession())

    try await store.rollback(packageId: "com.example.review.extension")
    #expect(await store.snapshot == MacPackageRollbackSnapshot(record: packageRollbackFixtureResponse.record))

    await #expect(throws: AteliaClientError.packageRollbackUnavailable) {
        try await store.rollback(packageId: "com.example.review.extension")
    }

    #expect(await client.calls() == 2)
    #expect(await store.snapshot == MacPackageRollbackSnapshot(record: packageRollbackFixtureResponse.record))
    #expect(await store.record == packageRollbackFixtureResponse.record)
}

@Test func olderRollbackCompletionDoesNotOverwriteNewerFailedRequest() async throws {
    let client = ControllablePackageRollbackClientFixture()
    let store = MacPackageRollbackStore(client: client, session: AteliaSession())

    let olderRollback = Task {
        try await store.rollback(packageId: "com.example.older")
    }
    while await client.calls() < 1 {
        await Task.yield()
    }

    let newerRollback = Task {
        try await store.rollback(packageId: "com.example.newer")
    }
    while await client.calls() < 2 {
        await Task.yield()
    }

    await client.respond(to: 1, with: .failure(AteliaClientError.packageRollbackUnavailable))
    await #expect(throws: AteliaClientError.packageRollbackUnavailable) {
        try await newerRollback.value
    }

    await client.respond(to: 0, with: .success(packageRollbackFixtureResponse))
    try await olderRollback.value

    #expect(await client.calls() == 2)
    #expect(await client.requestedPackageIds() == ["com.example.older", "com.example.newer"])
    #expect(await store.metadata == nil)
    #expect(await store.snapshot == nil)
    #expect(await store.record == nil)
}

@Test func clearResetsDerivedRollbackSnapshot() async throws {
    let client = PackageRollbackClientFixture(responses: [.success(packageRollbackFixtureResponse)])
    let store = MacPackageRollbackStore(client: client, session: AteliaSession())

    try await store.rollback(packageId: "com.example.review.extension")
    await store.clear()

    #expect(await store.metadata == nil)
    #expect(await store.snapshot == nil)
    #expect(await store.record == nil)
    #expect(await store.packageId == nil)
}
