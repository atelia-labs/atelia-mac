import AteliaKit

/// Mac-facing wrapper for tool output render operations and cached render state.
public actor MacToolOutputRenderStore {
    private let store: AteliaToolOutputRenderStore

    /// Creates a tool-output render store for a client/session pair.
    public init(client: some AteliaClient, session: AteliaSession) {
        self.store = AteliaToolOutputRenderStore(client: client, session: session)
    }

    /// Returns the latest tool-output render response from cache.
    public var response: AteliaToolOutputRenderResponse? {
        get async {
            await store.response
        }
    }

    /// Returns the latest protocol metadata from cache.
    public var metadata: AteliaProtocolMetadata? {
        get async {
            await store.metadata
        }
    }

    /// Returns the latest tool-result reference from cache.
    public var toolResult: AteliaToolResultRef? {
        get async {
            await store.toolResult
        }
    }

    /// Returns the requested output format from the latest render.
    public var format: AteliaToolOutputRenderFormat? {
        get async {
            await store.format
        }
    }

    /// Returns the rendered output body from the latest render.
    public var renderedOutput: String? {
        get async {
            await store.renderedOutput
        }
    }

    /// Returns metadata about the latest rendered tool output.
    public var renderedOutputMetadata: AteliaRenderedToolOutputMetadata? {
        get async {
            await store.renderedOutputMetadata
        }
    }

    /// Returns an atomic snapshot of cached tool-output render state.
    public var snapshot: AteliaToolOutputRenderStoreSnapshot {
        get async {
            await store.snapshot()
        }
    }

    /// Renders a tool-output payload and updates cached render state.
    @discardableResult
    public func render(
        request: AteliaToolOutputRenderRequest
    ) async throws -> AteliaToolOutputRenderResponse {
        try await store.render(request: request)
    }

    /// Clears all cached render state.
    public func clear() async {
        await store.clear()
    }
}
