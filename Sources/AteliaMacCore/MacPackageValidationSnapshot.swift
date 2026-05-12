import AteliaKit
import Foundation

/// Mac-facing snapshot for a package validation result.
public struct MacPackageValidationSnapshot: Sendable, Equatable, Identifiable {
    /// Stable package identifier from the validated manifest.
    public let id: String
    /// Package schema label from the validated manifest.
    public let schemaLabel: String?
    /// Package name label from the validated manifest.
    public let nameLabel: String?
    /// Package version label from the validated manifest.
    public let versionLabel: String?
    /// Human-readable trust boundary for the validated package.
    public let boundaryLabel: String
    /// Source label from the validated manifest.
    public let sourceLabel: String?
    /// Manifest-digest label if the manifest carried one.
    public let manifestDigestLabel: String?
    /// Artifact-digest label if the manifest carried one.
    public let artifactDigestLabel: String?
    /// Human-readable permissions summary if present.
    public let permissionsLabel: String?
    /// Validated manifest that can be inspected by callers.
    public let manifest: AteliaPackageManifest

    /// Creates a Mac validation snapshot from a shared validation response.
    public init(response: AteliaPackageValidationResponse) {
        let manifest = response.manifest

        self.id = Self.identifier(from: manifest)
        self.schemaLabel = Self.valueLabel(prefix: "Schema", value: Self.stringValue(from: manifest["schema"]))
        self.nameLabel = Self.valueLabel(prefix: "Name", value: Self.stringValue(from: manifest["name"]))
        self.versionLabel = Self.valueLabel(prefix: "Version", value: Self.stringValue(from: manifest["version"]))
        self.boundaryLabel = Self.boundaryLabel(for: response.boundary)
        self.sourceLabel = Self.valueLabel(
            prefix: "Source",
            value: Self.stringValue(
                from: Self.provenanceValue(from: manifest, key: "source")
            )
        )
        self.manifestDigestLabel = Self.valueLabel(
            prefix: "Manifest digest",
            value: Self.stringValue(from: Self.provenanceValue(from: manifest, key: "manifest_digest"))
        )
        self.artifactDigestLabel = Self.valueLabel(
            prefix: "Artifact digest",
            value: Self.stringValue(from: Self.provenanceValue(from: manifest, key: "artifact_digest"))
        )
        self.permissionsLabel = Self.permissionListLabel(from: manifest["permissions"])
        self.manifest = manifest
    }

    /// Returns a scalar manifest value as display text when it can be represented compactly.
    private static func stringValue(from value: AteliaPackageManifestValue?) -> String? {
        guard let value else {
            return nil
        }

        switch value {
        case .string(let value):
            return value
        case .number(let number):
            return "\(number)"
        case .bool(let flag):
            return flag ? "true" : "false"
        case .null:
            return nil
        default:
            return nil
        }
    }

    /// Returns a trimmed manifest ID or the fallback ID when the manifest ID is blank.
    private static func identifier(from manifest: AteliaPackageManifest) -> String {
        if let id = Self.stringValue(from: manifest["id"])?.trimmingCharacters(in: .whitespacesAndNewlines),
           !id.isEmpty {
            return id
        }

        return Self.fallbackIdentifier(from: manifest)
    }

    /// Builds a stable fallback ID from manifest digests before using a random value.
    private static func fallbackIdentifier(from manifest: AteliaPackageManifest) -> String {
        if let manifestDigest = Self.stringValue(from: Self.provenanceValue(from: manifest, key: "manifest_digest"))?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !manifestDigest.isEmpty {
            return "unknown-\(manifestDigest)"
        }

        if let artifactDigest = Self.stringValue(from: Self.provenanceValue(from: manifest, key: "artifact_digest"))?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !artifactDigest.isEmpty {
            return "unknown-\(artifactDigest)"
        }

        return "unknown-\(UUID().uuidString)"
    }

    /// Reads a provenance field from nested manifest fields and falls back to top-level fields when missing.
    private static func provenanceValue(from manifest: AteliaPackageManifest, key: String) -> AteliaPackageManifestValue? {
        if case .object(let provenance) = manifest["provenance"], let value = provenance[key] {
            return value
        }
        return manifest[key]
    }

    /// Builds a comma-separated permission summary from a manifest permission list or map.
    private static func permissionListLabel(from value: AteliaPackageManifestValue?) -> String? {
        switch value {
        case .array(let permissions):
            let items = permissions.compactMap { item -> String? in
                guard case .string(let permission) = item else {
                    return nil
                }
                return permission
            }

            if items.isEmpty {
                return nil
            }
            return "Permissions: \(items.joined(separator: ", "))"

        case .object(let permissions):
            let items = permissions.keys.sorted()
            if items.isEmpty {
                return nil
            }
            return "Permissions: \(items.joined(separator: ", "))"

        default:
            return nil
        }
    }

    /// Builds a prefixed label when a manifest value is present.
    private static func valueLabel(prefix: String, value: String?) -> String? {
        guard let value else {
            return nil
        }
        return "\(prefix): \(value)"
    }

    /// Formats the validation trust boundary for Mac inspection surfaces.
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
}
