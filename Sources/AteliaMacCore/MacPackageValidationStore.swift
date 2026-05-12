import AteliaKit

/// Mac-facing wrapper for invoking package validation and caching the latest response.
public actor MacPackageValidationStore {
    private let client: any AteliaClient
    private let session: AteliaSession
    private var latestResponse: AteliaPackageValidationResponse?
    private var latestSnapshot: MacPackageValidationSnapshot?
    private var nextValidationGeneration = 0
    private var latestAppliedGeneration = 0
    private var clearGeneration = 0

    /// Creates a package-validation store for a client/session pair.
    public init(client: some AteliaClient, session: AteliaSession) {
        self.client = client
        self.session = session
    }

    /// Returns the latest full validation response, if one has been loaded.
    public var response: AteliaPackageValidationResponse? {
        latestResponse
    }

    /// Returns the latest protocol metadata from the validation response, if loaded.
    public var metadata: AteliaProtocolMetadata? {
        latestResponse?.metadata
    }

    /// Returns the latest validated manifest, if loaded.
    public var manifest: AteliaPackageManifest? {
        latestResponse?.manifest
    }

    /// Returns the latest boundary from the validation response, if loaded.
    public var boundary: AteliaPackageTrustIndexEntry.Boundary? {
        latestResponse?.boundary
    }

    /// Returns a Mac-facing snapshot of the latest validation response, if loaded.
    public var snapshot: MacPackageValidationSnapshot? {
        latestSnapshot
    }

    /// Returns the validated package ID tied to the cached snapshot.
    public var packageId: String? {
        latestSnapshot?.id
    }

    /// Validates a package manifest and caches the response.
    public func validate(request: AteliaPackageValidationRequest) async throws {
        nextValidationGeneration += 1
        let validationGeneration = nextValidationGeneration
        let response = try await client.packageValidationResponse(for: session, request: request)
        guard validationGeneration == nextValidationGeneration,
              validationGeneration > latestAppliedGeneration,
              validationGeneration > clearGeneration else {
            return
        }
        latestAppliedGeneration = validationGeneration
        latestResponse = response
        latestSnapshot = MacPackageValidationSnapshot(response: response)
    }

    /// Clears any cached package-validation state.
    public func clear() {
        clearGeneration = nextValidationGeneration
        latestResponse = nil
        latestSnapshot = nil
    }
}
