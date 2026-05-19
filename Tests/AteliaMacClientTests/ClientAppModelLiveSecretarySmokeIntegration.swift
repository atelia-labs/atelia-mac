import AteliaKit
import AteliaMacClientModels
import Foundation
import Testing
@testable import AteliaMacClient
@testable import AteliaMacCore

private final class LocalProjectSelectionFixture: ProjectFolderSelectionProviding {
    var existingFolderURL: URL?
    var newFolderURL: URL?
    private(set) var existingFolderCallCount = 0
    private(set) var newFolderCallCount = 0

    func chooseExistingFolder() -> URL? {
        existingFolderCallCount += 1
        return existingFolderURL
    }

    func createNewFolder() -> URL? {
        newFolderCallCount += 1
        return newFolderURL
    }
}

private struct PDH175LiveSmokeConfig {
    let endpoint: AteliaEndpoint
    let bearerToken: String?
    let projectPath: URL
    let command: String
    let maxWaitMilliseconds: UInt64
    let isEnabled: Bool
}

private enum PDH175LiveSmokeConfigError: Error {
    case invalidDaemonPort(String)
}

private func pdh175LiveSmokeConfig() throws -> PDH175LiveSmokeConfig {
    let environment = ProcessInfo.processInfo.environment
    let isEnabled = (environment["ATELIA_MAC_LIVE_E2E"] ?? "0") == "1"
    if !isEnabled {
        return PDH175LiveSmokeConfig(
            endpoint: AteliaEndpoint(),
            bearerToken: nil,
            projectPath: URL(fileURLWithPath: FileManager.default.currentDirectoryPath),
            command: "search package",
            maxWaitMilliseconds: 30_000,
            isEnabled: false
        )
    }

    let host = environment["ATELIA_DAEMON_HOST"] ?? "127.0.0.1"
    guard let configuredPort = Int(environment["ATELIA_DAEMON_PORT"] ?? "8080"), configuredPort > 0 else {
        throw PDH175LiveSmokeConfigError.invalidDaemonPort(environment["ATELIA_DAEMON_PORT"] ?? "8080")
    }
    let endpoint = AteliaEndpoint(host: host, port: configuredPort)

    let projectPath = URL(fileURLWithPath: environment["ATELIA_E2E_PROJECT_PATH"] ?? FileManager.default.currentDirectoryPath)
    let command = environment["ATELIA_E2E_COMMAND"] ?? "search package"
    let waitMillisecondsRaw = environment["ATELIA_E2E_MAX_WAIT_MS"] ?? "30000"
    let maxWaitMilliseconds = UInt64(waitMillisecondsRaw) ?? 30_000
    let bearerToken = environment["ATELIA_DAEMON_AUTH_TOKEN"]

    return PDH175LiveSmokeConfig(
        endpoint: endpoint,
        bearerToken: bearerToken,
        projectPath: projectPath,
        command: command,
        maxWaitMilliseconds: maxWaitMilliseconds,
        isEnabled: true
    )
}

private func pdh175LiveSmokeProjectFolder(for path: URL) -> URL {
    let isDirectory = (try? path.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
    if isDirectory {
        return path
    }
    return path.standardizedFileURL.deletingLastPathComponent()
}

private func pdh175LiveSmokeDeadlineExceeded(
    start: ContinuousClock.Instant,
    maxWaitMilliseconds: UInt64
) -> Bool {
    return ContinuousClock.now - start > .milliseconds(maxWaitMilliseconds)
}

private func pdh175LiveSmokeRepositoryID(for projectPath: URL) -> String {
    projectPath.lastPathComponent
}

@MainActor
@Test func clientAppModelLiveSecretaryFilesystemSearchSmoke() async throws {
    let config = try pdh175LiveSmokeConfig()
    guard config.isEnabled else {
        print("PDH-175 live smoke skipped: set ATELIA_MAC_LIVE_E2E=1 to run against a live Secretary daemon.")
        return
    }

    let projectPath = pdh175LiveSmokeProjectFolder(for: config.projectPath)
    #expect(FileManager.default.fileExists(atPath: projectPath.path), "project path must exist")

    let client = HTTPAteliaClient(
        bearerToken: config.bearerToken,
        transport: .urlSession()
    )
    let session = AteliaSession(endpoint: config.endpoint)
    let statusStore = MacProjectStatusStore(
        client: client,
        session: session,
        repositoryId: pdh175LiveSmokeRepositoryID(for: projectPath)
    )
    let lifecycleStore = MacProjectLifecycleStore(
        client: client,
        session: session
    )
    let renderStore = MacToolOutputRenderStore(
        client: client,
        session: session
    )
    let picker = LocalProjectSelectionFixture()
    let registry = InMemoryLocalProjectRegistry()
    picker.existingFolderURL = projectPath
    let expectedProject = LocalProjectRegistration.make(folderURL: projectPath, source: .existingFolder)
    let model = ClientAppModel(
        projectStatusStore: statusStore,
        projectLifecycleStore: lifecycleStore,
        toolOutputRenderStore: renderStore,
        projectFolderSelection: picker,
        localProjectRegistry: registry
    )

    let health = try await client.health(for: session)
    #expect(health.capabilities.contains("health.v1"))

    let useExistingFolderAction = ProjectSectionHeaderViewData.projectSectionHeader.actions.first(where: {
        $0.kind == .useExistingFolder
    })!

    model.handleProjectSectionHeaderAction(useExistingFolderAction)

    #expect(picker.existingFolderCallCount == 1)
    #expect(picker.newFolderCallCount == 0)

    let registrationDeadline = ContinuousClock.now
    while !(model.localProjects == [expectedProject]) && !pdh175LiveSmokeDeadlineExceeded(start: registrationDeadline, maxWaitMilliseconds: 10_000) {
        try await Task.sleep(for: .milliseconds(50))
    }
    if model.localProjects != [expectedProject] {
        print(
            """
            PDH-175 live smoke registration timeout:
            expected project id: \(expectedProject.id)
            expected root path: \(expectedProject.rootPath)
            actual project ids: \(model.localProjects.map(\.id))
            actual root paths: \(model.localProjects.map(\.rootPath))
            active selection project id: \(String(describing: model.sidebarProjection.activeSelection.projectID))
            """
        )
    }
    #expect(model.localProjects == [expectedProject])
    #expect(model.sidebarProjection.activeSelection.projectID == expectedProject.projectID)

    model.handleComposerIntent(ComposerIntent.send(
        text: config.command,
        configuration: ClientMockState.ateliaReference.composer,
        contexts: []
    ))

    let submitTimeout = ContinuousClock.now
    while model.lastAteliaSubmitJobRequest == nil && !pdh175LiveSmokeDeadlineExceeded(start: submitTimeout, maxWaitMilliseconds: config.maxWaitMilliseconds) {
        try await Task.sleep(for: .milliseconds(100))
    }
    #expect(model.lastAteliaSubmitJobRequest != nil)
    let submitRequest = try #require(model.lastAteliaSubmitJobRequest)
    #expect(submitRequest.requestedCapabilities == ["filesystem.search"])

    let outputDeadline = ContinuousClock.now
    var toolOutputBlock: ClientConversationToolOutputFixture?
    while toolOutputBlock == nil && !pdh175LiveSmokeDeadlineExceeded(start: outputDeadline, maxWaitMilliseconds: config.maxWaitMilliseconds) {
        for turn in model.shellState.conversation.turns where turn.actor == .secretary {
            toolOutputBlock = turn.blocks.compactMap({ block in
                if case .toolOutput(let output) = block { return output }
                return nil
            }).first
            if toolOutputBlock != nil { break }
        }
        if toolOutputBlock == nil {
            try await Task.sleep(for: .milliseconds(150))
        }
    }

    let renderedToolOutput = try #require(toolOutputBlock)
    #expect(renderedToolOutput.toolName == "filesystem.search")
    #expect(renderedToolOutput.command == config.command)
    #expect(!renderedToolOutput.output.isEmpty)
    #expect(renderedToolOutput.status == .succeeded)
}
