import AteliaKit

/// Mac-facing package trust-index row derived from Secretary's shared trust-index model.
public struct MacPackageTrustIndexRow: Sendable, Equatable, Identifiable {
    /// Presentation severity for package review lists.
    public enum ReviewState: Sendable, Equatable {
        /// Package is usable without immediate intervention.
        case available
        /// Package is installed but disabled.
        case disabled
        /// Package is blocked by policy, registry, or user action.
        case blocked
        /// Package is currently changing state.
        case inProgress
        /// Package status is missing or not yet understood by this client.
        case unknown
    }

    /// Stable package identifier.
    public let id: String
    /// Package version label, when Secretary knows the installed or blocked version.
    public let versionLabel: String?
    /// Human-readable status text for package inspection rows.
    public let statusLabel: String
    /// Trust-index state used by Mac package review UI.
    public let reviewState: ReviewState
    /// Human-readable trust boundary label.
    public let boundaryLabel: String?
    /// Human-readable package source label.
    public let sourceLabel: String
    /// Human-readable blocked-package reason, when present.
    public let blockReasonLabel: String?

    /// Creates a Mac trust-index row from a shared AteliaKit entry.
    public init(entry: AteliaPackageTrustIndexEntry) {
        self.id = entry.packageId
        self.versionLabel = entry.version
        self.statusLabel = Self.statusLabel(for: entry.status)
        self.reviewState = Self.reviewState(for: entry.status)
        self.boundaryLabel = entry.boundary.map(Self.boundaryLabel)
        self.sourceLabel = Self.sourceLabel(for: entry.source)
        self.blockReasonLabel = entry.block.map { Self.blockReasonLabel(for: $0.reason) }
    }

    /// Converts a shared package status into Mac package-inspection copy.
    private static func statusLabel(for status: AteliaPackageTrustIndexEntry.Status?) -> String {
        switch status {
        case .installed:
            return "Installed"
        case .disabled:
            return "Disabled"
        case .blocked:
            return "Blocked"
        case .updating:
            return "Updating"
        case .rollbackInProgress:
            return "Rollback in progress"
        case .installedPreviousVersion:
            return "Rolled back"
        case .unknown(let rawValue):
            return "Unknown status: \(rawValue)"
        case nil:
            return "Unknown status"
        }
    }

    /// Converts a shared package status into a compact Mac review state.
    private static func reviewState(for status: AteliaPackageTrustIndexEntry.Status?) -> ReviewState {
        switch status {
        case .installed, .installedPreviousVersion:
            return .available
        case .disabled:
            return .disabled
        case .blocked:
            return .blocked
        case .updating, .rollbackInProgress:
            return .inProgress
        case .unknown, nil:
            return .unknown
        }
    }

    /// Converts a shared package boundary into Mac package-inspection copy.
    private static func boundaryLabel(for boundary: AteliaPackageTrustIndexEntry.Boundary) -> String {
        switch boundary {
        case .official:
            return "Official"
        case .thirdParty:
            return "Third-party"
        case .localDevelopment:
            return "Local development"
        case .unknown(let rawValue):
            return "Unknown boundary: \(rawValue)"
        }
    }

    /// Builds a visible source-provenance label without dropping retained trust-index fields.
    private static func sourceLabel(for source: AteliaPackageTrustIndexEntry.SourceSnapshot?) -> String {
        guard let source else {
            return "Source unknown"
        }

        var details: [String] = []
        if let registryIdentity = source.registryIdentity, !registryIdentity.isEmpty {
            details.append("Registry: \(registryIdentity)")
        }

        if let sourceKind = source.source, !sourceKind.isEmpty {
            details.append("Source: \(sourceKind)")
        }

        if let repository = source.repository, !repository.isEmpty {
            if let sourceRef = source.sourceRef, !sourceRef.isEmpty {
                details.append("\(repository) @ \(sourceRef)")
            } else {
                details.append(repository)
            }
        } else if let sourceRef = source.sourceRef, !sourceRef.isEmpty {
            details.append("Ref: \(sourceRef)")
        }

        if let manifestPath = source.manifestPath, !manifestPath.isEmpty {
            details.append("Manifest: \(manifestPath)")
        }

        if let commit = source.commit, !commit.isEmpty {
            details.append("Commit: \(commit)")
        }

        if details.isEmpty {
            return "Source unknown"
        }

        return details.joined(separator: " | ")
    }

    /// Converts a shared block reason into Mac package-inspection copy.
    private static func blockReasonLabel(for reason: AteliaPackageTrustIndexEntry.Block.Reason) -> String {
        switch reason {
        case .malware:
            return "Malware"
        case .manifestMismatch:
            return "Manifest mismatch"
        case .overPermissioned:
            return "Over-permissioned"
        case .vulnerableVersion:
            return "Vulnerable version"
        case .compromisedSigner:
            return "Compromised signer"
        case .policyViolation:
            return "Policy violation"
        case .userBlocked:
            return "User blocked"
        case .registryRemoved:
            return "Registry removed"
        case .unknown(let rawValue):
            return "Unknown block reason: \(rawValue)"
        }
    }
}
