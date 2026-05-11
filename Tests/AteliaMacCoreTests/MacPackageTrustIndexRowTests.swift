import AteliaKit
import Testing
@testable import AteliaMacCore

/// Verifies installed packages expose status, boundary, source, and version labels.
@Test func installedPackageRowShowsSourceAndBoundary() {
    let entry = AteliaPackageTrustIndexEntry(
        packageId: "com.example.review",
        version: "1.2.3",
        status: .installed,
        boundary: .thirdParty,
        source: .init(
            repository: "https://github.com/example/review-package",
            sourceRef: "refs/tags/v1.2.3"
        )
    )

    let row = MacPackageTrustIndexRow(entry: entry)

    #expect(row.id == "com.example.review")
    #expect(row.versionLabel == "1.2.3")
    #expect(row.statusLabel == "Installed")
    #expect(row.reviewState == .available)
    #expect(row.boundaryLabel == "Third-party")
    #expect(row.sourceLabel == "https://github.com/example/review-package @ refs/tags/v1.2.3")
    #expect(row.blockReasonLabel == nil)
}

/// Verifies blocked packages surface their review state and block reason.
@Test func blockedPackageRowShowsBlockReason() {
    let entry = AteliaPackageTrustIndexEntry(
        packageId: "com.example.blocked",
        status: .blocked,
        block: .init(
            reason: .policyViolation,
            key: .extensionId("com.example.blocked")
        )
    )

    let row = MacPackageTrustIndexRow(entry: entry)

    #expect(row.statusLabel == "Blocked")
    #expect(row.reviewState == .blocked)
    #expect(row.sourceLabel == "Source unknown")
    #expect(row.blockReasonLabel == "Policy violation")
}

/// Verifies forward-compatible unknown trust-index values remain visible.
@Test func unknownPackageFieldsStayVisible() {
    let entry = AteliaPackageTrustIndexEntry(
        packageId: "com.example.future",
        status: .unknown("quarantined_elsewhere"),
        boundary: .unknown("partner_registry"),
        source: .init(
            source: "future_source",
            repository: "https://github.com/example/future-package",
            sourceRef: "refs/heads/main",
            manifestPath: "packages/future/aep.yaml",
            commit: "abc1234",
            registryIdentity: "registry.example/com.example.future"
        ),
        block: .init(
            reason: .unknown("future_reason"),
            key: .unknown(name: "future_key")
        )
    )

    let row = MacPackageTrustIndexRow(entry: entry)

    #expect(row.statusLabel == "Unknown status: quarantined_elsewhere")
    #expect(row.reviewState == .unknown)
    #expect(row.boundaryLabel == "Unknown boundary: partner_registry")
    #expect(row.sourceLabel == "Registry: registry.example/com.example.future | Source: future_source | https://github.com/example/future-package @ refs/heads/main | Manifest: packages/future/aep.yaml | Commit: abc1234")
    #expect(row.blockReasonLabel == "Unknown block reason: future_reason")
}

/// Verifies a source ref without repository context is not dropped.
@Test func sourceRefWithoutRepositoryStaysVisible() {
    let entry = AteliaPackageTrustIndexEntry(
        packageId: "com.example.refonly",
        source: .init(source: "git", sourceRef: "refs/heads/main")
    )

    let row = MacPackageTrustIndexRow(entry: entry)

    #expect(row.sourceLabel == "Source: git | Ref: refs/heads/main")
}

/// Verifies active update and rollback states are grouped as in progress.
@Test func inProgressStatusesMapToInProgressReviewState() {
    let updating = MacPackageTrustIndexRow(entry: .init(
        packageId: "com.example.updating",
        status: .updating
    ))
    let rollingBack = MacPackageTrustIndexRow(entry: .init(
        packageId: "com.example.rollback",
        status: .rollbackInProgress
    ))

    #expect(updating.reviewState == .inProgress)
    #expect(rollingBack.reviewState == .inProgress)
}
