import AteliaKit

/// Mac-facing wrapper for package authoring operations and cached authoring state.
public actor MacPackageAuthoringStore {
    private let store: AteliaPackageAuthoringStore

    /// Creates a package-authoring store for a client/session pair.
    public init(client: some AteliaClient, session: AteliaSession) {
        self.store = AteliaPackageAuthoringStore(client: client, session: session)
    }

    /// Returns the latest protocol metadata from successful authoring operations.
    public var metadata: AteliaProtocolMetadata? {
        get async {
            await store.metadata
        }
    }

    /// Returns the latest package-authoring flow.
    public var flow: AteliaPackageAuthoringFlow? {
        get async {
            await store.flow
        }
    }

    /// Returns the latest authoring-flow response envelope.
    public var authoringFlowResponse: AteliaPackageAuthoringFlowResponse? {
        get async {
            await store.authoringFlowResponse
        }
    }

    /// Returns the latest remix response envelope.
    public var remixResponse: AteliaPackageRemixResponse? {
        get async {
            await store.remixResponse
        }
    }

    /// Returns the latest publication response envelope.
    public var publicationResponse: AteliaPackagePublicationResponse? {
        get async {
            await store.publicationResponse
        }
    }

    /// Returns the latest registry-submission response envelope.
    public var registrySubmissionResponse: AteliaPackageRegistrySubmissionResponse? {
        get async {
            await store.registrySubmissionResponse
        }
    }

    /// Returns the latest cached flow steps.
    public var steps: [AteliaPackageAuthoringFlowStep] {
        get async {
            await store.steps
        }
    }

    /// Returns the latest cached flow steps that require user consent.
    public var stepsRequiringConsent: [AteliaPackageAuthoringFlowStep] {
        get async {
            await store.stepsRequiringConsent
        }
    }

    /// Returns the cached publication plan from the latest flow.
    public var publicationPlan: AteliaPackagePublicationPlan? {
        get async {
            await store.publicationPlan
        }
    }

    /// Returns the cached source class from the latest flow.
    public var sourceClass: AteliaPackageSourceClass? {
        get async {
            await store.sourceClass
        }
    }

    /// Returns the cached source reference from the latest flow.
    public var source: AteliaPackageGitHubSourceReference? {
        get async {
            await store.source
        }
    }

    /// Returns the latest registry-submission state.
    public var registrySubmissionState: AteliaPackageRegistrySubmissionState? {
        get async {
            await store.registrySubmissionState
        }
    }

    /// Returns an atomic snapshot of the cached authoring state.
    public var snapshot: AteliaPackageAuthoringStoreSnapshot {
        get async {
            await store.snapshot()
        }
    }

    /// Loads the package authoring flow for a package.
    @discardableResult
    public func load(
        request: AteliaPackageAuthoringFlowRequest
    ) async throws -> AteliaPackageAuthoringFlow {
        try await store.load(request: request)
    }

    /// Starts a package remix request and updates local state.
    @discardableResult
    public func remix(
        request: AteliaPackageRemixRequest
    ) async throws -> AteliaPackageAuthoringFlow {
        try await store.remix(request: request)
    }

    /// Prepares publication and updates local state.
    @discardableResult
    public func preparePublication(
        request: AteliaPackagePublicationRequest
    ) async throws -> AteliaPackageAuthoringFlow {
        try await store.preparePublication(request: request)
    }

    /// Submits registry-submission state and updates local state.
    @discardableResult
    public func submitRegistry(
        request: AteliaPackageRegistrySubmissionRequest
    ) async throws -> AteliaPackageRegistrySubmissionState {
        try await store.submitRegistry(request: request)
    }

    /// Clears all cached authoring state.
    public func clear() async {
        await store.clear()
    }
}
