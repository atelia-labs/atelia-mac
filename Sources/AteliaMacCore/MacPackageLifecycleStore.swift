import AteliaKit

/// Mac-facing wrapper for package lifecycle operations and cached package/blocklist state.
public actor MacPackageLifecycleStore {
    private let store: AteliaPackageLifecycleStore

    /// Creates a Mac package-lifecycle store for a client/session pair.
    public init(client: some AteliaClient, session: AteliaSession) {
        self.store = AteliaPackageLifecycleStore(client: client, session: session)
    }

    /// Returns the latest protocol metadata from cached lifecycle responses.
    public var metadata: AteliaProtocolMetadata? {
        get async {
            await store.metadata
        }
    }

    /// Returns the latest lifecycle or rollback record from cached responses.
    public var latestRecord: AteliaPackageLifecycleRecord? {
        get async {
            await store.latestRecord
        }
    }

    /// Returns the latest lifecycle response, when one has completed.
    public var lifecycleResponse: AteliaPackageLifecycleResponse? {
        get async {
            await store.lifecycleResponse
        }
    }

    /// Returns the latest rollback response, when one has completed.
    public var rollbackResponse: AteliaPackageRollbackResponse? {
        get async {
            await store.rollbackResponse
        }
    }

    /// Returns the latest package status response, when one has completed.
    public var statusResponse: AteliaPackageStatusResponse? {
        get async {
            await store.statusResponse
        }
    }

    /// Returns the latest package inspect response, when one has completed.
    public var inspectResponse: AteliaPackageInspectResponse? {
        get async {
            await store.inspectResponse
        }
    }

    /// Returns the latest package inspect payload, when one has completed.
    public var inspectPayload: AteliaPackageInspect? {
        get async {
            await store.inspectResponse?.inspect
        }
    }

    /// Returns the latest package list response, when one has completed.
    public var listResponse: AteliaPackageListResponse? {
        get async {
            await store.listResponse
        }
    }

    /// Returns the latest blocklist apply response, when one has completed.
    public var blocklistApplyResponse: AteliaPackageBlocklistApplyResponse? {
        get async {
            await store.blocklistApplyResponse
        }
    }

    /// Returns the latest blocklist list response, when one has completed.
    public var blocklistListResponse: AteliaPackageBlocklistListResponse? {
        get async {
            await store.blocklistListResponse
        }
    }

    /// Returns the known package status rows.
    public var packages: [AteliaPackageStatus] {
        get async {
            await store.packages
        }
    }

    /// Returns the known package blocklist entries.
    public var blocklistEntries: [AteliaPackageBlocklistEntry] {
        get async {
            await store.blocklistEntries
        }
    }

    /// Returns the latest cached package row for the given package identifier.
    public func package(id packageId: String) async -> AteliaPackageStatus? {
        await store.package(id: packageId)
    }

    /// Installs a package and updates the store with the latest operation result.
    @discardableResult
    public func install(request: AteliaPackageLifecycleRequest) async throws -> AteliaPackageLifecycleRecord {
        try await store.install(request: request)
    }

    /// Updates a package and updates the store with the latest operation result.
    @discardableResult
    public func update(request: AteliaPackageLifecycleRequest) async throws -> AteliaPackageLifecycleRecord {
        try await store.update(request: request)
    }

    /// Rolls back a package and updates the store with the latest operation result.
    @discardableResult
    public func rollback(packageId: String) async throws -> AteliaPackageRollbackRecord {
        try await store.rollback(packageId: packageId)
    }

    /// Disables a package and updates the store with the latest operation result.
    @discardableResult
    public func disable(packageId: String) async throws -> AteliaPackageLifecycleRecord {
        try await store.disable(packageId: packageId)
    }

    /// Enables a package and updates the store with the latest operation result.
    @discardableResult
    public func enable(packageId: String) async throws -> AteliaPackageLifecycleRecord {
        try await store.enable(packageId: packageId)
    }

    /// Removes a package and updates the store with the latest operation result.
    @discardableResult
    public func remove(packageId: String) async throws -> AteliaPackageLifecycleRecord {
        try await store.remove(packageId: packageId)
    }

    /// Loads a package status and updates cached package state.
    @discardableResult
    public func status(packageId: String) async throws -> AteliaPackageStatus {
        try await store.status(packageId: packageId)
    }

    /// Loads a package inspect payload and updates cached inspect state.
    @discardableResult
    public func inspect(packageId: String) async throws -> AteliaPackageInspect {
        try await store.inspect(packageId: packageId)
    }

    /// Loads package status entries and updates cached package state.
    @discardableResult
    public func list(request: AteliaPackageListRequest = .init()) async throws -> [AteliaPackageStatus] {
        try await store.list(request: request)
    }

    /// Applies one package blocklist entry and updates cached blocklist state.
    @discardableResult
    public func applyBlocklist(
        request: AteliaPackageBlocklistRequest
    ) async throws -> AteliaPackageBlocklistEntry {
        try await store.applyBlocklist(request: request)
    }

    /// Loads package blocklist entries and updates cached blocklist state.
    @discardableResult
    public func listBlocklist() async throws -> [AteliaPackageBlocklistEntry] {
        try await store.listBlocklist()
    }

    /// Clears all cached package lifecycle, status, and blocklist state.
    public func clear() async {
        await store.clear()
    }
}
