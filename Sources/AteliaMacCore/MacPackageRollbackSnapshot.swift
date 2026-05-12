import AteliaKit

/// Mac-facing snapshot for a package rollback result returned by Secretary.
public struct MacPackageRollbackSnapshot: Sendable, Equatable, Identifiable {
    /// Stable package identifier.
    public let id: String
    /// Package version after the rollback operation.
    public let versionLabel: String
    /// Human-readable status text for rollback results.
    public let statusLabel: String
    /// Trust boundary label for the target package revision.
    public let boundaryLabel: String?
    /// Human-readable provenance source label for host inspection.
    public let sourceLabel: String
    /// Human-readable previous-version metadata for rollback.
    public let previousVersionLabel: String?
    /// Previous version captured by Secretary, when known.
    public let previousVersion: String?
    /// Approved permissions retained by the package after rollback.
    public let approvedPermissions: [String]
    /// Human-readable manifest digest label.
    public let manifestDigestLabel: String
    /// Human-readable artifact digest label.
    public let artifactDigestLabel: String
    /// Optional human-readable rollback snapshot manifest digest.
    public let rollbackSnapshotManifestDigestLabel: String?
    /// Optional human-readable rollback snapshot artifact digest.
    public let rollbackSnapshotArtifactDigestLabel: String?

    /// Creates a Mac rollback snapshot from a shared rollback record.
    public init(record: AteliaPackageRollbackRecord) {
        let trustIndexRow = MacPackageTrustIndexRow(entry: AteliaPackageTrustIndexEntry(
            packageId: record.packageId,
            version: record.version,
            status: record.status,
            boundary: record.boundary,
            manifestDigest: record.manifestDigest,
            artifactDigest: record.artifactDigest,
            source: record.source,
            block: nil
        ))

        self.id = record.packageId
        self.versionLabel = record.version
        self.statusLabel = trustIndexRow.statusLabel
        self.boundaryLabel = trustIndexRow.boundaryLabel
        self.sourceLabel = trustIndexRow.sourceLabel
        self.previousVersion = record.previousVersion
        self.approvedPermissions = record.approvedPermissions
        self.previousVersionLabel = Self.previousVersionLabel(for: record.previousVersion)
        self.manifestDigestLabel = Self.valueLabel(prefix: "Manifest digest", value: record.manifestDigest)
        self.artifactDigestLabel = Self.valueLabel(prefix: "Artifact digest", value: record.artifactDigest)
        self.rollbackSnapshotManifestDigestLabel = Self.valueLabel(
            prefix: "Rollback snapshot manifest digest",
            value: record.rollbackSnapshot?.manifestDigest
        )
        self.rollbackSnapshotArtifactDigestLabel = Self.valueLabel(
            prefix: "Rollback snapshot artifact digest",
            value: record.rollbackSnapshot?.artifactDigest
        )
    }

    private static func valueLabel(prefix: String, value: String) -> String {
        "\(prefix): \(value)"
    }

    private static func valueLabel(prefix: String, value: String?) -> String? {
        guard let value else {
            return nil
        }
        return "\(prefix): \(value)"
    }

    private static func previousVersionLabel(for previousVersion: String?) -> String? {
        guard let previousVersion else { return nil }
        return "Previous version: \(previousVersion)"
    }
}
