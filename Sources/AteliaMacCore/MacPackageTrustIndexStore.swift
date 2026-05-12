import AteliaKit
import Foundation

/// Mac-facing wrapper around the shared package trust-index store.
public actor MacPackageTrustIndexStore {
    private let store: AteliaPackageTrustIndexStore

    /// Creates a Mac trust-index store for a client/session pair.
    public init(client: some AteliaClient, session: AteliaSession) {
        self.store = AteliaPackageTrustIndexStore(client: client, session: session)
    }

    /// Returns the latest protocol metadata, if one has been loaded.
    public var metadata: AteliaProtocolMetadata? {
        get async {
            await store.metadata
        }
    }

    /// Returns the latest package trust-index rows.
    public var rows: [MacPackageTrustIndexRow] {
        get async {
            let packages = await store.packages
            return packages.map(MacPackageTrustIndexRow.init(entry:))
        }
    }

    /// Returns the package trust-index rows that require attention.
    public var rowsRequiringAttention: [MacPackageTrustIndexRow] {
        get async {
            let packages = await store.packagesRequiringAttention
            return packages.map(MacPackageTrustIndexRow.init(entry:))
        }
    }

    /// Returns the trust-index row for the given package identifier.
    public func row(id packageId: String) async -> MacPackageTrustIndexRow? {
        await store.package(id: packageId).map(MacPackageTrustIndexRow.init(entry:))
    }

    /// Reloads the latest trust index response from the client.
    public func reload() async throws {
        try await store.reload()
    }

    /// Clears any cached trust index state.
    public func clear() async {
        await store.clear()
    }
}
