import AteliaKit
import Foundation
import Testing
@testable import AteliaMacCore

/// Errors thrown by tool-output render store fixture clients.
private enum MacToolOutputRenderStoreFixtureError: Error {
    case unconfiguredResponse
}

/// Fixture client that records the latest render request and session.
private actor MacToolOutputRenderStoreClientFixture: AteliaClient {
    private var responses: [Result<AteliaToolOutputRenderResponse, any Error>]
    private var lastSession: AteliaSession?
    private var lastRequest: AteliaToolOutputRenderRequest?

    /// Creates a fixture with queued render responses.
    init(responses: [Result<AteliaToolOutputRenderResponse, any Error>] = []) {
        self.responses = responses
    }

    /// Records request/session and returns the next queued response.
    func renderToolOutputResponse(
        for session: AteliaSession,
        request: AteliaToolOutputRenderRequest
    ) async throws -> AteliaToolOutputRenderResponse {
        lastSession = session
        lastRequest = request
        guard !responses.isEmpty else {
            throw MacToolOutputRenderStoreFixtureError.unconfiguredResponse
        }
        return try responses.removeFirst().get()
    }

    /// Returns the most recent request session observed.
    func recordedSession() -> AteliaSession? {
        lastSession
    }

    /// Returns the most recent render request observed.
    func recordedRequest() -> AteliaToolOutputRenderRequest? {
        lastRequest
    }
}

/// Builds protocol metadata for render responses.
private func toolOutputMetadata() -> AteliaProtocolMetadata {
    AteliaProtocolMetadata(
        protocolVersion: "1.0.0",
        daemonVersion: "0.2.0",
        storageVersion: "0.2.0",
        capabilities: ["tool_output_render.v1"]
    )
}

/// Builds a render response fixture.
private func toolOutputResponse(
    suffix: String,
    format: AteliaToolOutputRenderFormat = .json,
    renderedOutput: String = "{\"value\":\"ready\"}"
) -> AteliaToolOutputRenderResponse {
    AteliaToolOutputRenderResponse(
        metadata: toolOutputMetadata(),
        toolResult: AteliaToolResultRef(
            toolResultId: "tool_result_\(suffix)",
            toolInvocationId: "tool_invocation_\(suffix)",
            jobId: "job_\(suffix)",
            repositoryId: "repo_\(suffix)",
            contentType: "application/json"
        ),
        format: format,
        renderedOutput: renderedOutput,
        renderedOutputMetadata: AteliaRenderedToolOutputMetadata(
            degraded: true,
            fallbackReason: nil,
            truncation: nil
        )
    )
}

/// Builds a render request fixture.
private func toolOutputRequest(
    suffix: String,
    format: AteliaToolOutputRenderFormat = .json
) -> AteliaToolOutputRenderRequest {
    AteliaToolOutputRenderRequest(
        toolResult: AteliaToolResultRef(
            toolResultId: "tool_result_\(suffix)",
            toolInvocationId: "tool_invocation_\(suffix)",
            jobId: "job_\(suffix)",
            repositoryId: "repo_\(suffix)",
            contentType: "application/json"
        ),
        format: format
    )
}

/// Verifies render forwards request/session and updates cached render fields.
@Test func renderForwardsSessionAndRequestAndCachesRenderState() async throws {
    let session = AteliaSession()
    let request = toolOutputRequest(suffix: "render", format: .text)
    let response = toolOutputResponse(suffix: "render", format: .text, renderedOutput: "Rendered value")
    let client = MacToolOutputRenderStoreClientFixture(
        responses: [.success(response)]
    )
    let store = MacToolOutputRenderStore(client: client, session: session)

    let rendered = try await store.render(request: request)

    #expect(rendered == response)
    #expect(await client.recordedSession() == session)
    #expect(await client.recordedRequest() == request)
    #expect(await store.response == response)
    #expect(await store.metadata == response.metadata)
    #expect(await store.toolResult == response.toolResult)
    #expect(await store.format == response.format)
    #expect(await store.renderedOutput == response.renderedOutput)
    #expect(await store.renderedOutputMetadata == response.renderedOutputMetadata)

    let snapshot = await store.snapshot
    #expect(snapshot.response == response)
    #expect(snapshot.metadata == response.metadata)
    #expect(snapshot.toolResult == response.toolResult)
    #expect(snapshot.format == response.format)
    #expect(snapshot.renderedOutput == response.renderedOutput)
    #expect(snapshot.renderedOutputMetadata == response.renderedOutputMetadata)
}

/// Verifies clear resets cached response and derived render fields.
@Test func clearResetsCachedRenderState() async throws {
    let request = toolOutputRequest(suffix: "clear")
    let response = toolOutputResponse(suffix: "clear")
    let client = MacToolOutputRenderStoreClientFixture(
        responses: [.success(response)]
    )
    let store = MacToolOutputRenderStore(client: client, session: AteliaSession())

    _ = try await store.render(request: request)
    await store.clear()

    #expect(await store.response == nil)
    #expect(await store.metadata == nil)
    #expect(await store.toolResult == nil)
    #expect(await store.format == nil)
    #expect(await store.renderedOutput == nil)
    #expect(await store.renderedOutputMetadata == nil)

    let snapshot = await store.snapshot
    #expect(snapshot.response == nil)
    #expect(snapshot.metadata == nil)
    #expect(snapshot.toolResult == nil)
    #expect(snapshot.format == nil)
    #expect(snapshot.renderedOutput == nil)
    #expect(snapshot.renderedOutputMetadata == nil)
}
