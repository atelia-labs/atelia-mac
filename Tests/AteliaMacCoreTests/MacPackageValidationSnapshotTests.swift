import AteliaKit
import Testing
@testable import AteliaMacCore

private let packageValidationFixtureResponse = AteliaPackageValidationResponse(
    metadata: AteliaProtocolMetadata(
        protocolVersion: "1.0.0",
        daemonVersion: "0.2.0",
        storageVersion: "0.2.0",
        capabilities: ["extensions.validate.v1"]
    ),
    manifest: AteliaPackageManifest(fields: [
        "schema": .string("atelia.extension.v1"),
        "id": .string("com.example.review.extension"),
        "name": .string("Review extension"),
        "version": .string("1.0.0"),
        "provenance": .object([
            "source": .string("github"),
            "manifest_digest": .string("sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"),
            "artifact_digest": .string("sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"),
            "registry_identity": .string("review-registry"),
            "artifact_type": .string("package"),
            "commit": .string("1234567890abcdef")
        ]),
        "permissions": .object([
            "filesystem.read": .object([
                "description": .string("Read access"),
                "risk_tier": .string("R1")
            ]),
            "filesystem.write": .object([
                "description": .string("Write access"),
                "risk_tier": .string("R2")
            ])
        ])
    ]),
    boundary: .official
)

/// Verifies a complete validation response maps to Mac-facing labels.
@Test func mapSnapshotFieldsFromValidationResponse() {
    let snapshot = MacPackageValidationSnapshot(response: packageValidationFixtureResponse)

    #expect(snapshot.id == "com.example.review.extension")
    #expect(snapshot.schemaLabel == "Schema: atelia.extension.v1")
    #expect(snapshot.nameLabel == "Name: Review extension")
    #expect(snapshot.versionLabel == "Version: 1.0.0")
    #expect(snapshot.boundaryLabel == "Official")
    #expect(snapshot.sourceLabel == "Source: github")
    #expect(snapshot.manifestDigestLabel == "Manifest digest: sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
    #expect(snapshot.artifactDigestLabel == "Artifact digest: sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb")
    #expect(snapshot.permissionsLabel == "Permissions: filesystem.read, filesystem.write")
    #expect(snapshot.manifest["id"] == .string("com.example.review.extension"))
}

/// Verifies legacy top-level fields still populate snapshot labels when provenance is absent.
@Test func mapLegacyFlatProvenanceFieldsToSnapshotLabels() {
    let snapshot = MacPackageValidationSnapshot(response: AteliaPackageValidationResponse(
        metadata: packageValidationFixtureResponse.metadata,
        manifest: AteliaPackageManifest(fields: [
            "id": .string("com.example.legacy.extension"),
            "source": .string("legacy-source"),
            "manifest_digest": .string("sha256:legacy-manifest"),
            "artifact_digest": .string("sha256:legacy-artifact"),
            "permissions": .array([.string("legacy.permission"), .string("legacy.permission.two")])
        ]),
        boundary: .official
    ))

    #expect(snapshot.id == "com.example.legacy.extension")
    #expect(snapshot.sourceLabel == "Source: legacy-source")
    #expect(snapshot.manifestDigestLabel == "Manifest digest: sha256:legacy-manifest")
    #expect(snapshot.artifactDigestLabel == "Artifact digest: sha256:legacy-artifact")
    #expect(snapshot.permissionsLabel == "Permissions: legacy.permission, legacy.permission.two")
}

/// Verifies missing manifest identifiers use a stable digest fallback ID.
@Test func mapMissingManifestIdToUnknown() {
    let snapshot = MacPackageValidationSnapshot(response: AteliaPackageValidationResponse(
        metadata: packageValidationFixtureResponse.metadata,
        manifest: AteliaPackageManifest(fields: [
            "manifest_digest": .string("sha256:unidentified"),
            "name": .string("Unidentified package")
        ]),
        boundary: .thirdParty
    ))

    #expect(snapshot.id == "unknown-sha256:unidentified")
    #expect(snapshot.nameLabel == "Name: Unidentified package")
    #expect(snapshot.boundaryLabel == "Third-party")
    #expect(snapshot.versionLabel == nil)
}

/// Verifies blank manifest identifiers use the same stable fallback path.
@Test func mapBlankManifestIdToUnknown() {
    let snapshot = MacPackageValidationSnapshot(response: AteliaPackageValidationResponse(
        metadata: packageValidationFixtureResponse.metadata,
        manifest: AteliaPackageManifest(fields: [
            "id": .string("   "),
            "artifact_digest": .string("sha256:blank")
        ]),
        boundary: .thirdParty
    ))

    #expect(snapshot.id == "unknown-sha256:blank")
}

/// Verifies blank digest fields are ignored when building a fallback identifier.
@Test func mapWhitespaceManifestDigestIgnoredForFallback() {
    let snapshot = MacPackageValidationSnapshot(response: AteliaPackageValidationResponse(
        metadata: packageValidationFixtureResponse.metadata,
        manifest: AteliaPackageManifest(fields: [
            "id": .string("   "),
            "manifest_digest": .string("   \n"),
            "artifact_digest": .string("sha256:from-artifact")
        ]),
        boundary: .thirdParty
    ))

    #expect(snapshot.id == "unknown-sha256:from-artifact")
}

/// Verifies unknown trust boundaries remain visible in the snapshot.
@Test func mapUnknownBoundaryForValidationSnapshot() {
    let snapshot = MacPackageValidationSnapshot(response: AteliaPackageValidationResponse(
        metadata: packageValidationFixtureResponse.metadata,
        manifest: AteliaPackageManifest(fields: [
            "id": .string("com.example.shadow"),
            "schema": .string("atelia.extension.v1")
        ]),
        boundary: .unknown("experimental_shadow")
    ))

    #expect(snapshot.id == "com.example.shadow")
    #expect(snapshot.schemaLabel == "Schema: atelia.extension.v1")
    #expect(snapshot.boundaryLabel == "Unknown boundary: experimental_shadow")
    #expect(snapshot.nameLabel == nil)
}
