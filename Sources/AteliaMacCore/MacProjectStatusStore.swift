import AteliaKit
import Foundation

/// Mac-facing wrapper around the shared project-status store.
public actor MacProjectStatusStore {
    private let store: AteliaProjectStatusStore
    private let repositoryIdValue: String

    /// Creates a Mac project-status store for a client/session/repository triplet.
    public init(client: some AteliaClient, session: AteliaSession, repositoryId: String) {
        self.store = AteliaProjectStatusStore(client: client, session: session, repositoryId: repositoryId)
        self.repositoryIdValue = repositoryId
    }

    /// Returns the configured repository identifier.
    public var repositoryId: String {
        repositoryIdValue
    }

    /// Returns the latest Mac-facing snapshot, if one has been loaded.
    public var snapshot: MacProjectStatusSnapshot? {
        get async {
            await store.status.map(MacProjectStatusSnapshot.init(status:))
        }
    }

    /// Returns the repository display name, if one has been loaded.
    public var repositoryDisplayName: String? {
        get async {
            await snapshot?.repositoryDisplayName
        }
    }

    /// Returns the repository root path, if one has been loaded.
    public var repositoryRootPath: String? {
        get async {
            await snapshot?.repositoryRootPath
        }
    }

    /// Returns the latest daemon label, if one has been loaded.
    public var daemonLabel: String? {
        get async {
            await snapshot?.daemonLabel
        }
    }

    /// Returns the latest storage label, if one has been loaded.
    public var storageLabel: String? {
        get async {
            await snapshot?.storageLabel
        }
    }

    /// Returns the latest cursor, if one has been loaded.
    public var latestCursor: AteliaEventCursor? {
        get async {
            await snapshot?.latestCursor
        }
    }

    /// Returns the recent job summaries in response order.
    public var recentJobs: [MacProjectStatusSnapshot.RecentJobSummary] {
        get async {
            await snapshot?.recentJobs ?? []
        }
    }

    /// Returns the recent policy-decision summaries in response order.
    public var recentPolicyDecisions: [MacProjectStatusSnapshot.RecentPolicyDecisionSummary] {
        get async {
            await snapshot?.recentPolicyDecisions ?? []
        }
    }

    /// Reloads the latest project status from the client.
    public func reload() async throws {
        try await store.reload()
    }

    /// Clears any cached project status state.
    public func clear() async {
        await store.clear()
    }
}
