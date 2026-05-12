import AteliaKit

/// Mac-facing wrapper for invoking package rollback and caching the latest response.
public actor MacPackageRollbackStore {
    private let client: any AteliaClient
    private let session: AteliaSession
    private var latestResponse: AteliaPackageRollbackResponse?
    private var nextRollbackGeneration = 0
    private var latestAppliedGeneration = 0
    private var clearGeneration = 0

    /// Creates a Mac rollback store for a client/session pair.
    public init(client: some AteliaClient, session: AteliaSession) {
        self.client = client
        self.session = session
    }

    /// Returns the protocol metadata from the latest rollback response, if loaded.
    public var metadata: AteliaProtocolMetadata? {
        get async {
            latestResponse?.metadata
        }
    }

    /// Returns the most recent rollback snapshot, if loaded.
    public var snapshot: MacPackageRollbackSnapshot? {
        get async {
            latestResponse.map { MacPackageRollbackSnapshot(record: $0.record) }
        }
    }

    /// Returns the latest shared rollback record, if loaded.
    public var record: AteliaPackageRollbackRecord? {
        get async {
            latestResponse?.record
        }
    }

    /// Returns the package ID tied to the cached rollback response.
    public var packageId: String? {
        get async {
            latestResponse?.record.packageId
        }
    }

    /// Invokes the rollback endpoint for a package and caches the response.
    public func rollback(packageId: String) async throws {
        nextRollbackGeneration += 1
        let rollbackGeneration = nextRollbackGeneration
        let response = try await client.packageRollbackResponse(for: session, packageId: packageId)
        guard rollbackGeneration > latestAppliedGeneration,
              rollbackGeneration > clearGeneration else {
            return
        }
        latestAppliedGeneration = rollbackGeneration
        latestResponse = response
    }

    /// Clears any cached rollback state.
    public func clear() async {
        clearGeneration = nextRollbackGeneration
        latestResponse = nil
    }
}
