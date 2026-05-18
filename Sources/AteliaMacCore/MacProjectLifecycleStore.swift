import AteliaKit

/// Mac-facing boundary for project registration and job submission.
public protocol MacProjectLifecycleStoring: Sendable {
    /// Opens or registers a repository root and returns the persisted projection.
    @discardableResult
    func open(request: AteliaRegisterRepositoryRequest) async throws -> AteliaRepository

    /// Submits a project-scoped Secretary job and returns the persisted projection.
    @discardableResult
    func submit(request: AteliaSubmitJobRequest) async throws -> AteliaJob

    /// Loads polling-friendly events for one project-scoped job.
    @discardableResult
    func listJobEvents(jobId: String, request: AteliaListEventsRequest) async throws -> [AteliaEvent]
}

/// Mac-facing wrapper around the shared project lifecycle store.
public actor MacProjectLifecycleStore: MacProjectLifecycleStoring {
    private let store: AteliaProjectLifecycleStore

    /// Creates a Mac project-lifecycle store for a client/session pair.
    public init(client: some AteliaClient, session: AteliaSession) {
        self.store = AteliaProjectLifecycleStore(client: client, session: session)
    }

    /// Returns the latest lifecycle snapshot cached by the shared store.
    public func snapshot() async -> AteliaProjectLifecycleStoreSnapshot {
        await store.snapshot()
    }

    /// Opens or registers a repository root and updates cached lifecycle state.
    @discardableResult
    public func open(request: AteliaRegisterRepositoryRequest) async throws -> AteliaRepository {
        try await store.open(request: request)
    }

    /// Submits a project-scoped Secretary job and updates cached lifecycle state.
    @discardableResult
    public func submit(request: AteliaSubmitJobRequest) async throws -> AteliaJob {
        try await store.submit(request: request)
    }

    /// Loads polling-friendly events for one project-scoped job.
    @discardableResult
    public func listJobEvents(jobId: String, request: AteliaListEventsRequest = .init()) async throws -> [AteliaEvent] {
        try await store.listJobEvents(jobId: jobId, request: request)
    }

    /// Clears all cached project lifecycle state.
    public func clear() async {
        await store.clear()
    }
}
