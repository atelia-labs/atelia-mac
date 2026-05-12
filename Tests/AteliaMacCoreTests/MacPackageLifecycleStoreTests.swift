@testable import AteliaKit
import Testing
@testable import AteliaMacCore

/// Test client that records package lifecycle requests and returns queued responses.
private actor PackageLifecycleClientFixture: AteliaClient {
    private var installResponses: [Result<AteliaPackageLifecycleResponse, Error>]
    private var updateResponses: [Result<AteliaPackageLifecycleResponse, Error>]
    private var rollbackResponses: [Result<AteliaPackageRollbackResponse, Error>]
    private var disableResponses: [Result<AteliaPackageLifecycleResponse, Error>]
    private var enableResponses: [Result<AteliaPackageLifecycleResponse, Error>]
    private var removeResponses: [Result<AteliaPackageLifecycleResponse, Error>]
    private var statusResponses: [Result<AteliaPackageStatusResponse, Error>]
    private var listResponses: [Result<AteliaPackageListResponse, Error>]
    private var blocklistApplyResponses: [Result<AteliaPackageBlocklistApplyResponse, Error>]
    private var blocklistListResponses: [Result<AteliaPackageBlocklistListResponse, Error>]

    private var installRequests: [AteliaPackageLifecycleRequest] = []
    private var updateRequests: [AteliaPackageLifecycleRequest] = []
    private var rollbackPackageIds: [String] = []
    private var disablePackageIds: [String] = []
    private var enablePackageIds: [String] = []
    private var removePackageIds: [String] = []
    private var statusPackageIds: [String] = []
    private var listRequests: [AteliaPackageListRequest] = []
    private var blocklistApplyRequests: [AteliaPackageBlocklistRequest] = []

    /// Creates a fixture with per-operation response queues.
    init(
        installResponses: [Result<AteliaPackageLifecycleResponse, Error>] = [],
        updateResponses: [Result<AteliaPackageLifecycleResponse, Error>] = [],
        rollbackResponses: [Result<AteliaPackageRollbackResponse, Error>] = [],
        disableResponses: [Result<AteliaPackageLifecycleResponse, Error>] = [],
        enableResponses: [Result<AteliaPackageLifecycleResponse, Error>] = [],
        removeResponses: [Result<AteliaPackageLifecycleResponse, Error>] = [],
        statusResponses: [Result<AteliaPackageStatusResponse, Error>] = [],
        listResponses: [Result<AteliaPackageListResponse, Error>] = [],
        blocklistApplyResponses: [Result<AteliaPackageBlocklistApplyResponse, Error>] = [],
        blocklistListResponses: [Result<AteliaPackageBlocklistListResponse, Error>] = []
    ) {
        self.installResponses = installResponses
        self.updateResponses = updateResponses
        self.rollbackResponses = rollbackResponses
        self.disableResponses = disableResponses
        self.enableResponses = enableResponses
        self.removeResponses = removeResponses
        self.statusResponses = statusResponses
        self.listResponses = listResponses
        self.blocklistApplyResponses = blocklistApplyResponses
        self.blocklistListResponses = blocklistListResponses
    }

    /// Records an install request and returns the next install response.
    func packageInstallResponse(
        for session: AteliaSession,
        request: AteliaPackageLifecycleRequest
    ) async throws -> AteliaPackageLifecycleResponse {
        _ = session
        installRequests.append(request)
        return try dequeue(&installResponses, fallback: AteliaClientError.packageInstallUnavailable)
    }

    /// Records an update request and returns the next update response.
    func packageUpdateResponse(
        for session: AteliaSession,
        request: AteliaPackageLifecycleRequest
    ) async throws -> AteliaPackageLifecycleResponse {
        _ = session
        updateRequests.append(request)
        return try dequeue(&updateResponses, fallback: AteliaClientError.packageUpdateUnavailable)
    }

    /// Records a rollback package identifier and returns the next rollback response.
    func packageRollbackResponse(
        for session: AteliaSession,
        packageId: String
    ) async throws -> AteliaPackageRollbackResponse {
        _ = session
        rollbackPackageIds.append(packageId)
        return try dequeue(&rollbackResponses, fallback: AteliaClientError.packageRollbackUnavailable)
    }

    /// Records a disable package identifier and returns the next disable response.
    func packageDisableResponse(
        for session: AteliaSession,
        packageId: String
    ) async throws -> AteliaPackageDisableResponse {
        _ = session
        disablePackageIds.append(packageId)
        return try dequeue(&disableResponses, fallback: AteliaClientError.packageDisableUnavailable)
    }

    /// Records an enable package identifier and returns the next enable response.
    func packageEnableResponse(
        for session: AteliaSession,
        packageId: String
    ) async throws -> AteliaPackageEnableResponse {
        _ = session
        enablePackageIds.append(packageId)
        return try dequeue(&enableResponses, fallback: AteliaClientError.packageEnableUnavailable)
    }

    /// Records a remove package identifier and returns the next remove response.
    func packageRemoveResponse(
        for session: AteliaSession,
        packageId: String
    ) async throws -> AteliaPackageRemoveResponse {
        _ = session
        removePackageIds.append(packageId)
        return try dequeue(&removeResponses, fallback: AteliaClientError.packageRemoveUnavailable)
    }

    /// Records a status package identifier and returns the next status response.
    func packageStatusResponse(
        for session: AteliaSession,
        packageId: String
    ) async throws -> AteliaPackageStatusResponse {
        _ = session
        statusPackageIds.append(packageId)
        return try dequeue(&statusResponses, fallback: AteliaClientError.packageStatusUnavailable)
    }

    /// Records a list request and returns the next list response.
    func packageListResponse(
        for session: AteliaSession,
        request: AteliaPackageListRequest
    ) async throws -> AteliaPackageListResponse {
        _ = session
        listRequests.append(request)
        return try dequeue(&listResponses, fallback: AteliaClientError.packageListUnavailable)
    }

    /// Records a blocklist apply request and returns the next apply response.
    func packageBlocklistApplyResponse(
        for session: AteliaSession,
        request: AteliaPackageBlocklistRequest
    ) async throws -> AteliaPackageBlocklistApplyResponse {
        _ = session
        blocklistApplyRequests.append(request)
        return try dequeue(&blocklistApplyResponses, fallback: AteliaClientError.packageBlocklistUnavailable)
    }

    /// Returns the next blocklist list response.
    func packageBlocklistListResponse(
        for session: AteliaSession
    ) async throws -> AteliaPackageBlocklistListResponse {
        _ = session
        return try dequeue(&blocklistListResponses, fallback: AteliaClientError.packageBlocklistUnavailable)
    }

    /// Returns install requests observed by the fixture.
    func installRequestHistory() -> [AteliaPackageLifecycleRequest] {
        installRequests
    }

    /// Returns update requests observed by the fixture.
    func updateRequestHistory() -> [AteliaPackageLifecycleRequest] {
        updateRequests
    }

    /// Returns rollback package identifiers observed by the fixture.
    func rollbackPackageIdHistory() -> [String] {
        rollbackPackageIds
    }

    /// Returns disable package identifiers observed by the fixture.
    func disablePackageIdHistory() -> [String] {
        disablePackageIds
    }

    /// Returns enable package identifiers observed by the fixture.
    func enablePackageIdHistory() -> [String] {
        enablePackageIds
    }

    /// Returns remove package identifiers observed by the fixture.
    func removePackageIdHistory() -> [String] {
        removePackageIds
    }

    /// Returns status package identifiers observed by the fixture.
    func statusPackageIdHistory() -> [String] {
        statusPackageIds
    }

    /// Returns list requests observed by the fixture.
    func listRequestHistory() -> [AteliaPackageListRequest] {
        listRequests
    }

    /// Returns blocklist apply requests observed by the fixture.
    func blocklistApplyRequestHistory() -> [AteliaPackageBlocklistRequest] {
        blocklistApplyRequests
    }

    /// Removes and returns the next queued response or throws the fallback error.
    private func dequeue<T>(
        _ queue: inout [Result<T, Error>],
        fallback: Error
    ) throws -> T {
        guard let first = queue.first else {
            throw fallback
        }
        queue.removeFirst()
        return try first.get()
    }
}

private let installResponse = AteliaPackageLifecycleResponse(
    metadata: AteliaProtocolMetadata(
        protocolVersion: "1.0.0",
        daemonVersion: "0.2.0",
        storageVersion: "0.2.0",
        capabilities: ["extensions.install.v1"]
    ),
    record: AteliaPackageLifecycleRecord(
        packageId: "com.example.install",
        version: "1.0.0",
        manifestDigest: "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
        artifactDigest: "sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
        source: .init(source: "registry"),
        boundary: .official,
        status: .installed
    )
)

private let updateResponse = AteliaPackageLifecycleResponse(
    metadata: AteliaProtocolMetadata(
        protocolVersion: "1.0.0",
        daemonVersion: "0.2.0",
        storageVersion: "0.2.0",
        capabilities: ["extensions.update.v1"]
    ),
    record: AteliaPackageLifecycleRecord(
        packageId: "com.example.update",
        version: "1.0.1",
        manifestDigest: "sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc",
        artifactDigest: "sha256:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
        source: .init(source: "registry"),
        boundary: .official,
        status: .installed
    )
)

private let rollbackResponse = AteliaPackageRollbackResponse(
    metadata: AteliaProtocolMetadata(
        protocolVersion: "1.0.0",
        daemonVersion: "0.2.0",
        storageVersion: "0.2.0",
        capabilities: ["extensions.rollback.v1"]
    ),
    record: AteliaPackageRollbackRecord(
        packageId: "com.example.rollback",
        version: "0.9.0",
        manifestDigest: "sha256:eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",
        artifactDigest: "sha256:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff",
        source: .init(source: "registry"),
        boundary: .official,
        status: .installedPreviousVersion
    )
)

private let disableResponse = AteliaPackageLifecycleResponse(
    metadata: AteliaProtocolMetadata(
        protocolVersion: "1.0.0",
        daemonVersion: "0.2.0",
        storageVersion: "0.2.0",
        capabilities: ["extensions.disable.v1"]
    ),
    record: AteliaPackageLifecycleRecord(
        packageId: "com.example.disable",
        version: "1.0.0",
        manifestDigest: "sha256:111111111111111111111111111111111111111111111111111111111111111111",
        artifactDigest: "sha256:222222222222222222222222222222222222222222222222222222222222222222",
        source: .init(source: "registry"),
        boundary: .official,
        status: .disabled
    )
)

private let enableResponse = AteliaPackageLifecycleResponse(
    metadata: AteliaProtocolMetadata(
        protocolVersion: "1.0.0",
        daemonVersion: "0.2.0",
        storageVersion: "0.2.0",
        capabilities: ["extensions.enable.v1"]
    ),
    record: AteliaPackageLifecycleRecord(
        packageId: "com.example.enable",
        version: "1.0.0",
        manifestDigest: "sha256:333333333333333333333333333333333333333333333333333333333333333333",
        artifactDigest: "sha256:444444444444444444444444444444444444444444444444444444444444444444",
        source: .init(source: "registry"),
        boundary: .official,
        status: .installed
    )
)

private let removeResponse = AteliaPackageLifecycleResponse(
    metadata: AteliaProtocolMetadata(
        protocolVersion: "1.0.0",
        daemonVersion: "0.2.0",
        storageVersion: "0.2.0",
        capabilities: ["extensions.remove.v1"]
    ),
    record: AteliaPackageLifecycleRecord(
        packageId: "com.example.remove",
        version: "1.0.0",
        manifestDigest: "sha256:555555555555555555555555555555555555555555555555555555555555555555",
        artifactDigest: "sha256:666666666666666666666666666666666666666666666666666666666666666666",
        source: .init(source: "registry"),
        boundary: .official,
        status: .installedPreviousVersion
    )
)

private let statusResponse = AteliaPackageStatusResponse(
    metadata: AteliaProtocolMetadata(
        protocolVersion: "1.0.0",
        daemonVersion: "0.2.0",
        storageVersion: "0.2.0",
        capabilities: ["extensions.status.v1"]
    ),
    package: AteliaPackageStatus(
        packageId: "com.example.status",
        record: AteliaPackageLifecycleRecord(
            packageId: "com.example.status",
            version: "2.0.0",
            manifestDigest: "sha256:777777777777777777777777777777777777777777777777777777777777777777",
            artifactDigest: "sha256:888888888888888888888888888888888888888888888888888888888888888888",
            source: .init(source: "registry"),
            boundary: .official,
            status: .installed
        )
    )
)

private let listResponse = AteliaPackageListResponse(
    metadata: AteliaProtocolMetadata(
        protocolVersion: "1.0.0",
        daemonVersion: "0.2.0",
        storageVersion: "0.2.0",
        capabilities: ["extensions.list.v1"]
    ),
    packages: [
        AteliaPackageStatus(
            packageId: "com.example.status",
            record: AteliaPackageLifecycleRecord(
                packageId: "com.example.status",
                version: "2.1.0",
                manifestDigest: "sha256:999999999999999999999999999999999999999999999999999999999999999999",
                artifactDigest: "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
                source: .init(source: "registry"),
                boundary: .official,
                status: .installed
            )
        ),
        AteliaPackageStatus(
            packageId: "com.example.listed",
            record: AteliaPackageLifecycleRecord(
                packageId: "com.example.listed",
                version: "1.0.0",
                manifestDigest: "sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
                artifactDigest: "sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc",
                source: .init(source: "registry"),
                boundary: .official,
                status: .installed
            )
        )
    ]
)

private let blocklistApplyResponse = AteliaPackageBlocklistApplyResponse(
    metadata: AteliaProtocolMetadata(
        protocolVersion: "1.0.0",
        daemonVersion: "0.2.0",
        storageVersion: "0.2.0",
        capabilities: ["extensions.blocklist.apply.v1"]
    ),
    entry: AteliaPackageBlocklistEntry(
        reason: .policyViolation,
        key: .extensionId("com.example.blocklist.applied"),
        note: "policy"
    )
)

private let blocklistListResponse = AteliaPackageBlocklistListResponse(
    metadata: AteliaProtocolMetadata(
        protocolVersion: "1.0.0",
        daemonVersion: "0.2.0",
        storageVersion: "0.2.0",
        capabilities: ["extensions.blocklist.list.v1"]
    ),
    entries: [
        AteliaPackageBlocklistEntry(
            reason: .userBlocked,
            key: .extensionId("com.example.blocklist.listed")
        )
    ]
)

private let installRequest = AteliaPackageLifecycleRequest(
    manifest: AteliaPackageManifest(fields: [
        "id": .string("com.example.install"),
        "schema": .string("atelia.extension.v1")
    ])
)

private let updateRequest = AteliaPackageLifecycleRequest(
    manifest: AteliaPackageManifest(fields: [
        "id": .string("com.example.update"),
        "schema": .string("atelia.extension.v1")
    ])
)

/// Verifies lifecycle operations forward requests, return payloads, and update cached state.
@Test func lifecycleStoreForwardsOperationsAndTracksDerivedState() async throws {
    let client = PackageLifecycleClientFixture(
        installResponses: [.success(installResponse)],
        updateResponses: [.success(updateResponse)],
        rollbackResponses: [.success(rollbackResponse)],
        disableResponses: [.success(disableResponse)],
        enableResponses: [.success(enableResponse)],
        removeResponses: [.success(removeResponse)],
        statusResponses: [.success(statusResponse)],
        listResponses: [.success(listResponse)],
        blocklistApplyResponses: [.success(blocklistApplyResponse)],
        blocklistListResponses: [.success(blocklistListResponse)]
    )
    let store = MacPackageLifecycleStore(client: client, session: AteliaSession())

    let installRecord = try await store.install(request: installRequest)
    let updateRecord = try await store.update(request: updateRequest)
    let rollbackRecord = try await store.rollback(packageId: "com.example.rollback")
    let disableRecord = try await store.disable(packageId: "com.example.disable")
    let enableRecord = try await store.enable(packageId: "com.example.enable")
    let removeRecord = try await store.remove(packageId: "com.example.remove")
    let status = try await store.status(packageId: "com.example.status")
    let packages = try await store.list()
    let appliedEntry = try await store.applyBlocklist(
        request: AteliaPackageBlocklistRequest(entry: blocklistApplyResponse.entry)
    )
    let blocklistEntries = try await store.listBlocklist()

    #expect(installRecord == installResponse.record)
    #expect(updateRecord == updateResponse.record)
    #expect(rollbackRecord == rollbackResponse.record)
    #expect(disableRecord == disableResponse.record)
    #expect(enableRecord == enableResponse.record)
    #expect(removeRecord == removeResponse.record)
    #expect(status == statusResponse.package)
    #expect(packages == listResponse.packages)
    #expect(appliedEntry == blocklistApplyResponse.entry)
    #expect(blocklistEntries == blocklistListResponse.entries)

    #expect(await client.installRequestHistory() == [installRequest])
    #expect(await client.updateRequestHistory() == [updateRequest])
    #expect(await client.rollbackPackageIdHistory() == ["com.example.rollback"])
    #expect(await client.disablePackageIdHistory() == ["com.example.disable"])
    #expect(await client.enablePackageIdHistory() == ["com.example.enable"])
    #expect(await client.removePackageIdHistory() == ["com.example.remove"])
    #expect(await client.statusPackageIdHistory() == ["com.example.status"])
    #expect(await client.listRequestHistory() == [AteliaPackageListRequest()])
    #expect(await client.blocklistApplyRequestHistory() == [AteliaPackageBlocklistRequest(entry: blocklistApplyResponse.entry)])

    #expect(await store.metadata == blocklistListResponse.metadata)
    #expect(await store.latestRecord == removeResponse.record)
    #expect(await store.lifecycleResponse == removeResponse)
    #expect(await store.rollbackResponse == rollbackResponse)
    #expect(await store.statusResponse == statusResponse)
    #expect(await store.listResponse == listResponse)
    #expect(await store.blocklistApplyResponse == blocklistApplyResponse)
    #expect(await store.blocklistListResponse == blocklistListResponse)
    #expect(await store.packages == listResponse.packages)
    #expect(await store.package(id: "com.example.status") == listResponse.packages[0])
    #expect(await store.blocklistEntries == blocklistListResponse.entries)
}

/// Verifies clear removes lifecycle, status, package, and blocklist cache state.
@Test func clearResetsLifecycleDerivedState() async throws {
    let client = PackageLifecycleClientFixture(
        installResponses: [.success(installResponse)],
        statusResponses: [.success(statusResponse)],
        listResponses: [.success(listResponse)],
        blocklistApplyResponses: [.success(blocklistApplyResponse)],
        blocklistListResponses: [.success(blocklistListResponse)]
    )
    let store = MacPackageLifecycleStore(client: client, session: AteliaSession())

    try await store.install(request: installRequest)
    try await store.status(packageId: "com.example.status")
    try await store.list()
    try await store.applyBlocklist(request: AteliaPackageBlocklistRequest(entry: blocklistApplyResponse.entry))
    try await store.listBlocklist()
    await store.clear()

    #expect(await store.metadata == nil)
    #expect(await store.latestRecord == nil)
    #expect(await store.lifecycleResponse == nil)
    #expect(await store.rollbackResponse == nil)
    #expect(await store.statusResponse == nil)
    #expect(await store.listResponse == nil)
    #expect(await store.blocklistApplyResponse == nil)
    #expect(await store.blocklistListResponse == nil)
    #expect(await store.packages.isEmpty)
    #expect(await store.blocklistEntries.isEmpty)
    #expect(await store.package(id: "com.example.status") == nil)
}
