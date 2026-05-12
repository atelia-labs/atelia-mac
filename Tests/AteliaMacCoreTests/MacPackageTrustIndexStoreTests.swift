import AteliaKit
import Foundation
import Testing
@testable import AteliaMacCore

private actor PackageTrustIndexClientFixture: AteliaClient {
    private let response: AteliaPackageTrustIndexResponse
    private var callCount = 0

    init(response: AteliaPackageTrustIndexResponse) {
        self.response = response
    }

    func packageTrustIndexResponse(for session: AteliaSession) async throws -> AteliaPackageTrustIndexResponse {
        _ = session
        callCount += 1
        return response
    }

    func calls() -> Int {
        callCount
    }
}

private let packageTrustIndexFixtureResponse = AteliaPackageTrustIndexResponse(
    metadata: AteliaProtocolMetadata(
        protocolVersion: "1.0.0",
        daemonVersion: "0.2.0",
        storageVersion: "0.2.0",
        capabilities: ["package_trust_index.v1"]
    ),
    packages: [
        AteliaPackageTrustIndexEntry(
            packageId: "com.example.alpha",
            version: "1.2.3",
            status: .installed,
            boundary: .official,
            source: .init(
                repository: "https://github.com/example/alpha",
                sourceRef: "refs/tags/v1.2.3"
            )
        ),
        AteliaPackageTrustIndexEntry(
            packageId: "com.example.beta",
            status: .blocked,
            boundary: .thirdParty,
            block: .init(
                reason: .policyViolation,
                key: .extensionId("com.example.beta")
            )
        )
    ]
)

@Test func reloadPopulatesMetadataRowsAndLookup() async throws {
    let client = PackageTrustIndexClientFixture(response: packageTrustIndexFixtureResponse)
    let store = MacPackageTrustIndexStore(client: client, session: AteliaSession())

    try await store.reload()

    let expectedRows = packageTrustIndexFixtureResponse.packages.map(MacPackageTrustIndexRow.init(entry:))

    #expect(await client.calls() == 1)
    #expect(await store.metadata == packageTrustIndexFixtureResponse.metadata)
    #expect(await store.rows == expectedRows)
    #expect(await store.rowsRequiringAttention == [expectedRows[1]])
    #expect(await store.row(id: "com.example.alpha") == expectedRows[0])
    #expect(await store.row(id: "com.example.beta") == expectedRows[1])
    #expect(await store.row(id: "com.example.missing") == nil)
}

@Test func clearResetsDerivedMacState() async throws {
    let client = PackageTrustIndexClientFixture(response: packageTrustIndexFixtureResponse)
    let store = MacPackageTrustIndexStore(client: client, session: AteliaSession())

    try await store.reload()
    await store.clear()

    #expect(await store.metadata == nil)
    #expect(await store.rows.isEmpty)
    #expect(await store.rowsRequiringAttention.isEmpty)
    #expect(await store.row(id: "com.example.alpha") == nil)
}
