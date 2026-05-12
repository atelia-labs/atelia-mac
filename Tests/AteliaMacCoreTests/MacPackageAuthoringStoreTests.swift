import AteliaKit
import Foundation
import Testing
@testable import AteliaMacCore

private actor PackageAuthoringStoreClientFixture: AteliaClient {
    /// Queued authoring-flow responses returned by the fixture.
    private var authoringFlowResponses: [Result<AteliaPackageAuthoringFlowResponse, any Error>]
    /// Queued remix responses returned by the fixture.
    private var remixResponses: [Result<AteliaPackageRemixResponse, any Error>]
    /// Queued publication responses returned by the fixture.
    private var publicationResponses: [Result<AteliaPackagePublicationResponse, any Error>]
    /// Queued registry-submission responses returned by the fixture.
    private var registrySubmissionResponses: [Result<AteliaPackageRegistrySubmissionResponse, any Error>]

    private var lastAuthoringFlowSession: AteliaSession?
    private var lastRemixSession: AteliaSession?
    private var lastPublicationSession: AteliaSession?
    private var lastRegistrySession: AteliaSession?

    private var lastAuthoringFlowRequest: AteliaPackageAuthoringFlowRequest?
    private var lastRemixRequest: AteliaPackageRemixRequest?
    private var lastPublicationRequest: AteliaPackagePublicationRequest?
    private var lastRegistrySubmissionRequest: AteliaPackageRegistrySubmissionRequest?

    /// Creates a fixture with response queues for each operation.
    init(
        authoringFlowResponses: [Result<AteliaPackageAuthoringFlowResponse, any Error>] = [],
        remixResponses: [Result<AteliaPackageRemixResponse, any Error>] = [],
        publicationResponses: [Result<AteliaPackagePublicationResponse, any Error>] = [],
        registrySubmissionResponses: [Result<AteliaPackageRegistrySubmissionResponse, any Error>] = []
    ) {
        self.authoringFlowResponses = authoringFlowResponses
        self.remixResponses = remixResponses
        self.publicationResponses = publicationResponses
        self.registrySubmissionResponses = registrySubmissionResponses
    }

    /// Records and returns the next authoring-flow response.
    func packageAuthoringFlowResponse(
        for session: AteliaSession,
        request: AteliaPackageAuthoringFlowRequest
    ) async throws -> AteliaPackageAuthoringFlowResponse {
        lastAuthoringFlowSession = session
        lastAuthoringFlowRequest = request
        return try dequeue(&authoringFlowResponses, fallback: AteliaClientError.packageAuthoringFlowUnavailable)
    }

    /// Records and returns the next remix response.
    func packageRemixResponse(
        for session: AteliaSession,
        request: AteliaPackageRemixRequest
    ) async throws -> AteliaPackageRemixResponse {
        lastRemixSession = session
        lastRemixRequest = request
        return try dequeue(&remixResponses, fallback: AteliaClientError.packageRemixUnavailable)
    }

    /// Records and returns the next publication response.
    func packagePublicationResponse(
        for session: AteliaSession,
        request: AteliaPackagePublicationRequest
    ) async throws -> AteliaPackagePublicationResponse {
        lastPublicationSession = session
        lastPublicationRequest = request
        return try dequeue(&publicationResponses, fallback: AteliaClientError.packagePublicationUnavailable)
    }

    /// Records and returns the next registry-submission response.
    func packageRegistrySubmissionResponse(
        for session: AteliaSession,
        request: AteliaPackageRegistrySubmissionRequest
    ) async throws -> AteliaPackageRegistrySubmissionResponse {
        lastRegistrySession = session
        lastRegistrySubmissionRequest = request
        return try dequeue(
            &registrySubmissionResponses,
            fallback: AteliaClientError.packageRegistrySubmissionUnavailable
        )
    }

    func recordedAuthoringFlowSession() -> AteliaSession? {
        lastAuthoringFlowSession
    }

    func recordedRemixSession() -> AteliaSession? {
        lastRemixSession
    }

    func recordedPublicationSession() -> AteliaSession? {
        lastPublicationSession
    }

    func recordedRegistrySubmissionSession() -> AteliaSession? {
        lastRegistrySession
    }

    func recordedAuthoringFlowRequest() -> AteliaPackageAuthoringFlowRequest? {
        lastAuthoringFlowRequest
    }

    func recordedRemixRequest() -> AteliaPackageRemixRequest? {
        lastRemixRequest
    }

    func recordedPublicationRequest() -> AteliaPackagePublicationRequest? {
        lastPublicationRequest
    }

    func recordedRegistrySubmissionRequest() -> AteliaPackageRegistrySubmissionRequest? {
        lastRegistrySubmissionRequest
    }

    private func dequeue<T>(
        _ queue: inout [Result<T, any Error>],
        fallback: Error
    ) throws -> T {
        guard !queue.isEmpty else {
            throw fallback
        }
        return try queue.removeFirst().get()
    }
}

private func decodableValue<T: Decodable>(_ object: [String: Any]) -> T {
    let data = try! JSONSerialization.data(withJSONObject: object, options: [])
    return try! JSONDecoder().decode(T.self, from: data)
}

private func encodableObject<T: Encodable>(_ value: T) -> [String: Any] {
    let data = try! JSONEncoder().encode(value)
    return (try! JSONSerialization.jsonObject(with: data, options: [])) as! [String: Any]
}

private func makeAuthoringFlowResponse(
    metadata: AteliaProtocolMetadata,
    flow: AteliaPackageAuthoringFlow
) -> AteliaPackageAuthoringFlowResponse {
    decodableValue([
        "metadata": encodableObject(metadata),
        "flow": encodableObject(flow)
    ])
}

private func makeRemixResponse(
    metadata: AteliaProtocolMetadata,
    flow: AteliaPackageAuthoringFlow
) -> AteliaPackageRemixResponse {
    decodableValue([
        "metadata": encodableObject(metadata),
        "flow": encodableObject(flow)
    ])
}

private func makePublicationResponse(
    metadata: AteliaProtocolMetadata,
    flow: AteliaPackageAuthoringFlow
) -> AteliaPackagePublicationResponse {
    decodableValue([
        "metadata": encodableObject(metadata),
        "flow": encodableObject(flow)
    ])
}

private func makeRegistrySubmissionResponse(
    metadata: AteliaProtocolMetadata,
    packageId: String,
    state: AteliaPackageRegistrySubmissionState,
    message: String? = nil,
    flow: AteliaPackageAuthoringFlow? = nil
) -> AteliaPackageRegistrySubmissionResponse {
    let stateData = try! JSONEncoder().encode(state)
    let stateValue = (
        try! JSONSerialization.jsonObject(
            with: stateData,
            options: .fragmentsAllowed
        ) as! String
    )

    var object: [String: Any] = [
        "metadata": encodableObject(metadata),
        "package_id": packageId,
        "state": stateValue
    ]
    if let message {
        object["message"] = message
    }
    if let flow {
        object["flow"] = encodableObject(flow)
    }
    return decodableValue(object)
}

private func packageAuthoringMetadata(_ capability: String) -> AteliaProtocolMetadata {
    AteliaProtocolMetadata(
        protocolVersion: "1.0.0",
        daemonVersion: "0.2.0",
        storageVersion: "0.2.0",
        capabilities: [capability]
    )
}

private func sourceReference() -> AteliaPackageGitHubSourceReference {
    AteliaPackageGitHubSourceReference(
        repository: "github.com/atelia-labs/atelia",
        ref: "main",
        manifestPath: "Packages/review/aep.yaml",
        manifestDigest: "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
        artifactDigests: [
            "sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
        ]
    )
}

private func authoringFlow(
    packageId: String = "com.example.review.extension",
    sourceClass: AteliaPackageSourceClass = .workspaceLocal,
    source: AteliaPackageGitHubSourceReference? = sourceReference(),
    steps: [AteliaPackageAuthoringFlowStep] = [
        AteliaPackageAuthoringFlowStep(
            id: .inspect,
            title: "Inspect package",
            state: .complete
        ),
        AteliaPackageAuthoringFlowStep(
            id: .publish,
            title: "Publish package",
            state: .requiresConsent,
            requiresExplicitConsent: true
        )
    ],
    publicationPlan: AteliaPackagePublicationPlan? = AteliaPackagePublicationPlan(
        visibility: .publicSearchable,
        sourceClass: .workspaceLocal,
        source: sourceReference(),
        requiresRegistrySubmission: true,
        productionInstallable: false
    )
) -> AteliaPackageAuthoringFlow {
    AteliaPackageAuthoringFlow(
        packageId: packageId,
        sourceClass: sourceClass,
        source: source,
        steps: steps,
        publicationPlan: publicationPlan
    )
}

/// Verifies `load` forwards request/session and caches derived authoring state.
@Test func loadDelegatesAndCachesFlowState() async throws {
    let flow = authoringFlow(
        packageId: "com.example.review.extension",
        sourceClass: .verifiedRegistry,
        source: sourceReference(),
        steps: [
            AteliaPackageAuthoringFlowStep(
                id: .inspect,
                title: "Inspect package",
                state: .complete
            ),
            AteliaPackageAuthoringFlowStep(
                id: .registrySearch,
                title: "Check registry",
                state: .requiresConsent,
                requiresExplicitConsent: true
            )
        ]
    )
    let response = makeAuthoringFlowResponse(
        metadata: packageAuthoringMetadata("extensions.authoring-flow.v1"),
        flow: flow
    )
    let request = AteliaPackageAuthoringFlowRequest(
        packageId: "com.example.review.extension",
        includePrivateSteps: true
    )
    let session = AteliaSession()
    let client = PackageAuthoringStoreClientFixture(
        authoringFlowResponses: [.success(response)]
    )
    let store = MacPackageAuthoringStore(client: client, session: session)

    let loadedFlow = try await store.load(request: request)

    #expect(loadedFlow == flow)
    #expect(await client.recordedAuthoringFlowRequest() == request)
    #expect(await client.recordedAuthoringFlowSession() == session)
    #expect(await store.authoringFlowResponse == response)
    #expect(await store.metadata == response.metadata)
    #expect(await store.flow == response.flow)
    #expect(await store.source == response.flow.source)
    #expect(await store.sourceClass == response.flow.sourceClass)
    #expect(await store.publicationPlan == response.flow.publicationPlan)
    #expect(await store.steps == response.flow.steps)
    #expect(await store.stepsRequiringConsent == [response.flow.steps[1]])
}

/// Verifies all delegation methods forward inputs and update shared cached state.
@Test func flowsAndRegistrySubmissionUpdateStateAndSnapshot() async throws {
    let remixResponse = makeRemixResponse(
        metadata: packageAuthoringMetadata("extensions.remix.v1"),
        flow: authoringFlow(
            packageId: "com.example.review.extension",
            sourceClass: .workspaceLocal,
            steps: [
                AteliaPackageAuthoringFlowStep(
                    id: .remix,
                    title: "Remix package",
                    state: .inProgress
                )
            ]
        )
    )
    let publicationResponse = makePublicationResponse(
        metadata: packageAuthoringMetadata("extensions.publication.v1"),
        flow: authoringFlow(
            packageId: "com.example.review.extension",
            sourceClass: .bundledOfficial,
            steps: [
                AteliaPackageAuthoringFlowStep(
                    id: .publish,
                    title: "Prepare publication",
                    state: .inProgress
                )
            ]
        )
    )
    let registryResponse = makeRegistrySubmissionResponse(
        metadata: packageAuthoringMetadata("extensions.registry-submission.v1"),
        packageId: "com.example.review.extension",
        state: AteliaPackageRegistrySubmissionState.accepted,
        message: "ok",
        flow: nil
    )

    let remixRequest = AteliaPackageRemixRequest(
        packageId: "com.example.review.extension",
        sourceClass: .workspaceLocal,
        source: sourceReference()
    )
    let publicationRequest = AteliaPackagePublicationRequest(
        packageId: "com.example.review.extension",
        sourceClass: .bundledOfficial,
        source: sourceReference(),
        visibility: .privateRemix,
        requiresRegistrySubmission: true,
        productionInstallable: true
    )
    let registryRequest = AteliaPackageRegistrySubmissionRequest(
        packageId: "com.example.review.extension",
        state: .accepted,
        note: "approved"
    )

    let session = AteliaSession()
    let client = PackageAuthoringStoreClientFixture(
        remixResponses: [.success(remixResponse)],
        publicationResponses: [.success(publicationResponse)],
        registrySubmissionResponses: [.success(registryResponse)]
    )
    let store = MacPackageAuthoringStore(client: client, session: session)

    let remixed = try await store.remix(request: remixRequest)
    let prepared = try await store.preparePublication(request: publicationRequest)
    let submissionState = try await store.submitRegistry(request: registryRequest)

    #expect(remixed == remixResponse.flow)
    #expect(prepared == publicationResponse.flow)
    #expect(submissionState == .accepted)
    #expect(await client.recordedRemixRequest() == remixRequest)
    #expect(await client.recordedPublicationRequest() == publicationRequest)
    #expect(await client.recordedRegistrySubmissionRequest() == registryRequest)
    #expect(await client.recordedRemixSession() == session)
    #expect(await client.recordedPublicationSession() == session)
    #expect(await client.recordedRegistrySubmissionSession() == session)
    #expect(await store.remixResponse == remixResponse)
    #expect(await store.publicationResponse == publicationResponse)
    #expect(await store.registrySubmissionResponse == registryResponse)
    #expect(await store.flow == prepared)
    #expect(await store.steps == prepared.steps)
    #expect(await store.sourceClass == prepared.sourceClass)
    #expect(await store.source == prepared.source)
    #expect(await store.registrySubmissionState == AteliaPackageRegistrySubmissionState.accepted)

    let snapshot = await store.snapshot
    #expect(snapshot.remixResponse == remixResponse)
    #expect(snapshot.publicationResponse == publicationResponse)
    #expect(snapshot.registrySubmissionResponse == registryResponse)
    #expect(snapshot.metadata == packageAuthoringMetadata("extensions.registry-submission.v1"))
    #expect(snapshot.flow == prepared)
    #expect(snapshot.steps == prepared.steps)
    #expect(snapshot.stepsRequiringConsent == prepared.stepsRequiringConsent)
    #expect(snapshot.publicationPlan == prepared.publicationPlan)
    #expect(snapshot.source == prepared.source)
    #expect(snapshot.sourceClass == prepared.sourceClass)
    #expect(snapshot.registrySubmissionState == AteliaPackageRegistrySubmissionState.accepted)
}

/// Verifies `clear` removes cached authoring envelopes, flow state, and snapshot values.
@Test func clearDiscardsCachedAuthoringState() async throws {
    let response = makeAuthoringFlowResponse(
        metadata: packageAuthoringMetadata("extensions.authoring-flow.v1"),
        flow: authoringFlow()
    )
    let loadRequest = AteliaPackageAuthoringFlowRequest(packageId: "com.example.review.extension")
    let client = PackageAuthoringStoreClientFixture(
        authoringFlowResponses: [.success(response)]
    )
    let store = MacPackageAuthoringStore(client: client, session: AteliaSession())

    _ = try await store.load(request: loadRequest)
    #expect(await store.flow == response.flow)

    await store.clear()

    #expect(await store.metadata == nil)
    #expect(await store.flow == nil)
    #expect(await store.authoringFlowResponse == nil)
    #expect(await store.remixResponse == nil)
    #expect(await store.publicationResponse == nil)
    #expect(await store.registrySubmissionResponse == nil)
    #expect(await store.source == nil)
    #expect(await store.sourceClass == nil)
    #expect(await store.steps.isEmpty)
    #expect(await store.stepsRequiringConsent.isEmpty)
    #expect(await store.publicationPlan == nil)
    #expect(await store.registrySubmissionState == nil)

    let snapshot = await store.snapshot
    #expect(snapshot.metadata == nil)
    #expect(snapshot.flow == nil)
    #expect(snapshot.authoringFlowResponse == nil)
    #expect(snapshot.remixResponse == nil)
    #expect(snapshot.publicationResponse == nil)
    #expect(snapshot.registrySubmissionResponse == nil)
    #expect(snapshot.steps.isEmpty)
    #expect(snapshot.stepsRequiringConsent.isEmpty)
    #expect(snapshot.publicationPlan == nil)
    #expect(snapshot.source == nil)
    #expect(snapshot.sourceClass == nil)
    #expect(snapshot.registrySubmissionState == nil)
}
