import AteliaKit
import Testing
@testable import AteliaMacCore

private let packageRollbackSnapshotFixture = AteliaPackageRollbackRecord(
    packageId: "com.example.review.extension",
    version: "1.0.0",
    manifestDigest: "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
    artifactDigest: "sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
    source: .init(
        source: "github",
        repository: "https://github.com/example/review",
        sourceRef: "refs/tags/v1.0.0",
        manifestPath: "packages/review/package.yml",
        commit: "deadbeef",
        registryIdentity: "atelia-official"
    ),
    boundary: .official,
    status: .installedPreviousVersion,
    previousVersion: "2.0.0",
    approvedPermissions: ["repo.read"],
    rollbackSnapshot: .init(
        manifestDigest: "sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc",
        artifactDigest: "sha256:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd"
    )
)

@Test func mapSnapshotFieldsForRollbackSuccessState() {
    let snapshot = MacPackageRollbackSnapshot(record: packageRollbackSnapshotFixture)

    #expect(snapshot.id == "com.example.review.extension")
    #expect(snapshot.versionLabel == "1.0.0")
    #expect(snapshot.statusLabel == "Rolled back")
    #expect(snapshot.boundaryLabel == "Official")
    #expect(snapshot.sourceLabel == "Registry: atelia-official | Source: github | https://github.com/example/review @ refs/tags/v1.0.0 | Manifest: packages/review/package.yml | Commit: deadbeef")
    #expect(snapshot.previousVersion == "2.0.0")
    #expect(snapshot.approvedPermissions == ["repo.read"])
    #expect(snapshot.previousVersionLabel == "Previous version: 2.0.0")
    #expect(snapshot.manifestDigestLabel == "Manifest digest: sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
    #expect(snapshot.artifactDigestLabel == "Artifact digest: sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb")
    #expect(snapshot.rollbackSnapshotManifestDigestLabel == "Rollback snapshot manifest digest: sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc")
    #expect(snapshot.rollbackSnapshotArtifactDigestLabel == "Rollback snapshot artifact digest: sha256:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd")
}

@Test func mapUnknownEnumsThroughTrustIndexStyleLabels() {
    let snapshot = MacPackageRollbackSnapshot(record: .init(
        packageId: "com.example.future",
        version: "0.9.0",
        manifestDigest: "sha256:111111111111111111111111111111111111111111111111111111111111111111",
        artifactDigest: "sha256:222222222222222222222222222222222222222222222222222222222222222222",
        source: .init(
            source: "s3",
            repository: "s3://bucket/example",
            sourceRef: "refs/main",
            manifestPath: "Manifest",
            commit: "cafebabe"
        ),
        boundary: .unknown("private_marketplace"),
        status: .unknown("awaiting_audit"),
        previousVersion: nil,
        approvedPermissions: []
    ))

    #expect(snapshot.statusLabel == "Unknown status: awaiting_audit")
    #expect(snapshot.boundaryLabel == "Unknown boundary: private_marketplace")
    #expect(snapshot.sourceLabel == "Source: s3 | s3://bucket/example @ refs/main | Manifest: Manifest | Commit: cafebabe")
    #expect(snapshot.previousVersion == nil)
    #expect(snapshot.previousVersionLabel == nil)
}
