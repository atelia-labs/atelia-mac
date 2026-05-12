import AteliaKit
import Testing
@testable import AteliaMacCore

/// Scripted validation client used to return deterministic responses.
private actor PackageValidationClientFixture: AteliaClient {
    private let responses: [Result<AteliaPackageValidationResponse, Error>]
    private var callCount = 0
    private var manifestRequestHistory: [String?] = []
    private var nextResponseIndex = 0

    /// Creates a fixture with ordered validation responses.
    init(responses: [Result<AteliaPackageValidationResponse, Error>]) {
        self.responses = responses
    }

    /// Returns the next configured validation response and records the requested manifest ID.
    func packageValidationResponse(
        for session: AteliaSession,
        request: AteliaPackageValidationRequest
    ) async throws -> AteliaPackageValidationResponse {
        _ = session
        callCount += 1
        manifestRequestHistory.append(request.manifest["id"].flatMap {
            if case .string(let value) = $0 { value } else { nil }
        })

        guard nextResponseIndex < responses.count else {
            throw AteliaClientError.packageValidationUnavailable
        }
        let result = responses[nextResponseIndex]
        nextResponseIndex += 1
        return try result.get()
    }

    /// Number of validation calls observed by the fixture.
    func calls() -> Int {
        callCount
    }

    /// Manifest identifiers submitted through validation requests.
    func requestedManifestHistory() -> [String?] {
        manifestRequestHistory
    }
}

/// Validation client fixture that lets tests complete requests out of order.
private actor ControllablePackageValidationClientFixture: AteliaClient {
    private var continuations: [CheckedContinuation<AteliaPackageValidationResponse, any Error>] = []
    private var callCount = 0
    private var manifestRequestHistory: [String?] = []

    /// Suspends validation until the test resumes the captured continuation.
    func packageValidationResponse(
        for session: AteliaSession,
        request: AteliaPackageValidationRequest
    ) async throws -> AteliaPackageValidationResponse {
        _ = session
        callCount += 1
        manifestRequestHistory.append(request.manifest["id"].flatMap {
            if case .string(let value) = $0 { value } else { nil }
        })

        return try await withCheckedThrowingContinuation { continuation in
            continuations.append(continuation)
        }
    }

    /// Number of validation calls observed by the fixture.
    func calls() -> Int {
        callCount
    }

    /// Manifest identifiers submitted through validation requests.
    func requestedManifestHistory() -> [String?] {
        manifestRequestHistory
    }

    /// Resumes a captured validation request with a configured result.
    func respond(to index: Int, with result: Result<AteliaPackageValidationResponse, any Error>) {
        continuations[index].resume(with: result)
    }
}

/// Waits for the controllable validation client to observe a call count.
private func waitForValidationCalls(
    _ expectedCalls: Int,
    in client: ControllablePackageValidationClientFixture
) async {
    for _ in 0..<100 {
        let calls = await client.calls()
        if calls >= expectedCalls {
            return
        }
        try? await Task.sleep(nanoseconds: 1_000_000)
    }

    let calls = await client.calls()
    #expect(calls >= expectedCalls, "Timed out waiting for \(expectedCalls) validation calls; saw \(calls).")
}

private let packageValidationRequest = AteliaPackageValidationRequest(
    manifest: AteliaPackageManifest(fields: [
        "id": .string("com.example.review.extension"),
        "schema": .string("atelia.extension.v1")
    ]),
    approveLocalUnsigned: true
)

private let packageValidationFixtureResponse = AteliaPackageValidationResponse(
    metadata: AteliaProtocolMetadata(
        protocolVersion: "1.0.0",
        daemonVersion: "0.2.0",
        storageVersion: "0.2.0",
        capabilities: ["extensions.validate.v1"]
    ),
    manifest: AteliaPackageManifest(fields: [
        "id": .string("com.example.review.extension"),
        "schema": .string("atelia.extension.v1"),
        "name": .string("Review extension")
    ]),
    boundary: .official
)

private let replacementPackageValidationFixtureResponse = AteliaPackageValidationResponse(
    metadata: AteliaProtocolMetadata(
        protocolVersion: "1.0.1",
        daemonVersion: "0.2.1",
        storageVersion: "0.2.1",
        capabilities: ["extensions.validate.v1"]
    ),
    manifest: AteliaPackageManifest(fields: [
        "id": .string("com.example.other.extension"),
        "schema": .string("atelia.extension.v1"),
        "name": .string("Replacement extension")
    ]),
    boundary: .thirdParty
)

/// Verifies successful validation populates metadata, manifest, boundary, and snapshot state.
@Test func validationStoresLatestResponseMetadataManifestAndSnapshot() async throws {
    let client = PackageValidationClientFixture(
        responses: [.success(packageValidationFixtureResponse)]
    )
    let store = MacPackageValidationStore(client: client, session: AteliaSession())

    try await store.validate(request: packageValidationRequest)

    #expect(await client.calls() == 1)
    #expect(await client.requestedManifestHistory() == ["com.example.review.extension"])
    #expect(await store.response == packageValidationFixtureResponse)
    #expect(await store.metadata == packageValidationFixtureResponse.metadata)
    #expect(await store.manifest == packageValidationFixtureResponse.manifest)
    #expect(await store.boundary == .official)
    #expect(await store.packageId == "com.example.review.extension")
    #expect(await store.snapshot == MacPackageValidationSnapshot(response: packageValidationFixtureResponse))
}

/// Verifies cached snapshots keep a stable fallback ID when the manifest omits one.
@Test func validationCachesSnapshotIdentityForMissingManifestId() async throws {
    let response = AteliaPackageValidationResponse(
        metadata: packageValidationFixtureResponse.metadata,
        manifest: AteliaPackageManifest(fields: [
            "schema": .string("atelia.extension.v1"),
            "name": .string("Unidentified package")
        ]),
        boundary: .thirdParty
    )
    let client = PackageValidationClientFixture(responses: [.success(response)])
    let store = MacPackageValidationStore(client: client, session: AteliaSession())

    try await store.validate(request: AteliaPackageValidationRequest(manifest: response.manifest))

    let firstSnapshot = await store.snapshot
    let secondSnapshot = await store.snapshot

    #expect(firstSnapshot?.id.hasPrefix("unknown-") == true)
    #expect(firstSnapshot == secondSnapshot)
    #expect(await store.packageId == firstSnapshot?.id)
}

/// Verifies validation failures surface without clearing the last successful snapshot.
@Test func validationPreservesLastSuccessOnSubsequentFailure() async throws {
    let client = PackageValidationClientFixture(responses: [
        .success(packageValidationFixtureResponse),
        .failure(AteliaClientError.packageValidationUnavailable)
    ])
    let store = MacPackageValidationStore(client: client, session: AteliaSession())

    try await store.validate(request: packageValidationRequest)
    #expect(await store.snapshot == MacPackageValidationSnapshot(response: packageValidationFixtureResponse))

    await #expect(throws: AteliaClientError.packageValidationUnavailable) {
        try await store.validate(request: packageValidationRequest)
    }

    #expect(await client.calls() == 2)
    #expect(await store.snapshot == MacPackageValidationSnapshot(response: packageValidationFixtureResponse))
    #expect(await store.metadata == packageValidationFixtureResponse.metadata)
    #expect(await store.manifest == packageValidationFixtureResponse.manifest)
}

/// Verifies an older validation completion cannot replace a newer successful result.
@Test func olderValidationCompletionDoesNotOverwriteNewerRequest() async throws {
    let client = ControllablePackageValidationClientFixture()
    let store = MacPackageValidationStore(client: client, session: AteliaSession())

    let initialValidation = Task {
        try await store.validate(request: packageValidationRequest)
    }
    await waitForValidationCalls(1, in: client)
    await client.respond(to: 0, with: .success(packageValidationFixtureResponse))
    try await initialValidation.value

    let staleValidation = Task {
        try await store.validate(request: AteliaPackageValidationRequest(
            manifest: AteliaPackageManifest(fields: [
                "id": .string("com.example.stale.extension"),
                "schema": .string("atelia.extension.v1")
            ]),
            allowLocalProcessRuntime: true
        ))
    }
    await waitForValidationCalls(2, in: client)

    let freshValidation = Task {
        try await store.validate(request: AteliaPackageValidationRequest(
            manifest: AteliaPackageManifest(fields: [
                "id": .string("com.example.fresh.extension"),
                "schema": .string("atelia.extension.v1")
            ]),
            approveSourceChange: true
        ))
    }
    await waitForValidationCalls(3, in: client)

    await client.respond(to: 2, with: .success(replacementPackageValidationFixtureResponse))
    try await freshValidation.value

    await client.respond(to: 1, with: .success(packageValidationFixtureResponse))

    try await staleValidation.value

    #expect(await client.calls() == 3)
    #expect(await store.snapshot == MacPackageValidationSnapshot(response: replacementPackageValidationFixtureResponse))
    #expect(await store.packageId == "com.example.other.extension")
    #expect(await client.requestedManifestHistory() == [
        "com.example.review.extension",
        "com.example.stale.extension",
        "com.example.fresh.extension"
    ])
}

/// Verifies a stale completion is ignored once a newer validation request has started.
@Test func staleValidationCompletionIsIgnoredAfterNewerRequestStarts() async throws {
    let client = ControllablePackageValidationClientFixture()
    let store = MacPackageValidationStore(client: client, session: AteliaSession())

    let staleValidation = Task {
        try await store.validate(request: AteliaPackageValidationRequest(
            manifest: AteliaPackageManifest(fields: [
                "id": .string("com.example.stale.extension"),
                "schema": .string("atelia.extension.v1")
            ])
        ))
    }
    await waitForValidationCalls(1, in: client)

    let freshValidation = Task {
        try await store.validate(request: AteliaPackageValidationRequest(
            manifest: AteliaPackageManifest(fields: [
                "id": .string("com.example.fresh.extension"),
                "schema": .string("atelia.extension.v1")
            ])
        ))
    }
    await waitForValidationCalls(2, in: client)

    await client.respond(to: 0, with: .success(packageValidationFixtureResponse))
    try await staleValidation.value
    #expect(await store.snapshot == nil)

    await client.respond(to: 1, with: .success(replacementPackageValidationFixtureResponse))
    try await freshValidation.value
    #expect(await store.snapshot == MacPackageValidationSnapshot(response: replacementPackageValidationFixtureResponse))
}

/// Verifies clear removes all cached validation state.
@Test func clearResetsValidationState() async throws {
    let client = PackageValidationClientFixture(responses: [.success(packageValidationFixtureResponse)])
    let store = MacPackageValidationStore(client: client, session: AteliaSession())

    try await store.validate(request: packageValidationRequest)
    await store.clear()

    #expect(await store.response == nil)
    #expect(await store.metadata == nil)
    #expect(await store.manifest == nil)
    #expect(await store.boundary == nil)
    #expect(await store.snapshot == nil)
    #expect(await store.packageId == nil)
}
