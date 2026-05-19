import AteliaKit
import AteliaMacClientModels
import Foundation
import Testing
@testable import AteliaMacClient
@testable import AteliaMacCore

@MainActor
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
    case invalidMaxWait(String)
    case invalidProjectPath(String)
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
    let daemonPortRaw = environment["ATELIA_DAEMON_PORT"] ?? "8080"
    guard let configuredPort = Int(daemonPortRaw), configuredPort > 0 && configuredPort <= 65535 else {
        throw PDH175LiveSmokeConfigError.invalidDaemonPort(daemonPortRaw)
    }
    let endpoint = AteliaEndpoint(host: host, port: configuredPort)

    let projectPathString = environment["ATELIA_E2E_PROJECT_PATH"] ?? FileManager.default.currentDirectoryPath
    let configuredProjectPath = URL(fileURLWithPath: projectPathString).standardizedFileURL
    let isDirectory = (try? configuredProjectPath.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
    if !isDirectory {
        throw PDH175LiveSmokeConfigError.invalidProjectPath(projectPathString)
    }
    let command = environment["ATELIA_E2E_COMMAND"] ?? "search package"
    let defaultMaxWaitMilliseconds: UInt64 = 30_000
    let maxWaitMilliseconds: UInt64
    if let waitMillisecondsRaw = environment["ATELIA_E2E_MAX_WAIT_MS"] {
        guard let parsedMaxWaitMilliseconds = UInt64(waitMillisecondsRaw) else {
            throw PDH175LiveSmokeConfigError.invalidMaxWait(waitMillisecondsRaw)
        }
        maxWaitMilliseconds = parsedMaxWaitMilliseconds
    } else {
        maxWaitMilliseconds = defaultMaxWaitMilliseconds
    }
    let bearerToken = environment["ATELIA_DAEMON_AUTH_TOKEN"]

    return PDH175LiveSmokeConfig(
        endpoint: endpoint,
        bearerToken: bearerToken,
        projectPath: configuredProjectPath,
        command: command,
        maxWaitMilliseconds: maxWaitMilliseconds,
        isEnabled: true
    )
}

private func pdh175LiveSmokeDeadlineExceeded(
    start: ContinuousClock.Instant,
    maxWaitMilliseconds: UInt64
) -> Bool {
    return ContinuousClock.now - start > .milliseconds(maxWaitMilliseconds)
}

private func pdh175LiveSmokeMatchesFilesystemSearchRequest(
    output: ClientConversationToolOutputFixture,
    command: String
) -> Bool {
    guard output.toolName == "filesystem.search" else {
        return false
    }
    if output.command.isEmpty {
        return true
    }
    return output.command == command
}

private func pdh175LiveSmokeToolOutputSummary(_ turnIndex: Int, turnID: String, output: ClientConversationToolOutputFixture) -> String {
    "\(turnIndex) \(turnID) \(output.id) \(output.toolName) \(output.command.isEmpty ? "<empty command>" : output.command) \(output.status)"
}

private func pdh175LiveSmokeToolOutputSignature(_ turnIndex: Int, output: ClientConversationToolOutputFixture) -> String {
    "\(turnIndex)-\(output.id)-\(String(reflecting: output.status))"
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

    let projectPath = config.projectPath
    print("PDH-175 live smoke resolved project path: \(projectPath.path)")
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
    while !(model.localProjects == [expectedProject]) && !pdh175LiveSmokeDeadlineExceeded(start: registrationDeadline, maxWaitMilliseconds: 10_000) && model.lastErrorMessage == nil {
        try await Task.sleep(for: .milliseconds(50))
    }
    if model.localProjects != [expectedProject] {
        print(
            """
            PDH-175 live smoke registration failed:
            error: \(String(describing: model.lastErrorMessage))
            expected project id: \(expectedProject.id)
            expected root path: \(expectedProject.rootPath)
            actual project ids: \(model.localProjects.map(\.id))
            actual root paths: \(model.localProjects.map(\.rootPath))
            active selection project id: \(String(describing: model.sidebarProjection.activeSelection.projectID))
            """
        )
    }
    #expect(model.lastErrorMessage == nil)
    #expect(model.localProjects == [expectedProject])
    #expect(model.sidebarProjection.activeSelection.projectID == expectedProject.projectID)

    let outputStartTurnIndex = model.shellState.conversation.turns.count

    model.handleComposerIntent(ComposerIntent.send(
        text: config.command,
        configuration: ClientMockState.ateliaReference.composer,
        contexts: []
    ))

    let submitTimeout = ContinuousClock.now
    while model.lastAteliaSubmitJobRequest == nil && !pdh175LiveSmokeDeadlineExceeded(start: submitTimeout, maxWaitMilliseconds: config.maxWaitMilliseconds) && model.lastErrorMessage == nil {
        try await Task.sleep(for: .milliseconds(100))
    }
    if model.lastAteliaSubmitJobRequest == nil {
        print(
            """
            PDH-175 live smoke submit timeout:
            error: \(String(describing: model.lastErrorMessage))
            """
        )
    }
    #expect(model.lastErrorMessage == nil)
    #expect(model.lastAteliaSubmitJobRequest != nil)
    let submitRequest = try #require(model.lastAteliaSubmitJobRequest)
    #expect(submitRequest.requestedCapabilities == ["filesystem.search"])

    let outputDeadline = ContinuousClock.now
    var toolOutputBlock: ClientConversationToolOutputFixture?
    var toolOutputDiagnostics: [String] = []
    var observedToolOutputSignatures: Set<String> = []
    while toolOutputBlock == nil && !pdh175LiveSmokeDeadlineExceeded(start: outputDeadline, maxWaitMilliseconds: config.maxWaitMilliseconds) && model.lastErrorMessage == nil {
        let turns = model.shellState.conversation.turns
        for turnIndex in outputStartTurnIndex..<turns.count {
            let turn = turns[turnIndex]
            guard turn.actor == .secretary else { continue }
            for block in turn.blocks {
                if case .toolOutput(let output) = block {
                    let signature = pdh175LiveSmokeToolOutputSignature(turnIndex, output: output)
                    if observedToolOutputSignatures.contains(signature) {
                        continue
                    }
                    observedToolOutputSignatures.insert(signature)
                    toolOutputDiagnostics.append(
                        pdh175LiveSmokeToolOutputSummary(turnIndex, turnID: turn.id, output: output)
                    )
                    if pdh175LiveSmokeMatchesFilesystemSearchRequest(output: output, command: config.command) {
                        if case .succeeded = output.status {
                            toolOutputBlock = output
                        }
                    }
                }
            }
        }
        if toolOutputBlock == nil {
            try await Task.sleep(for: .milliseconds(150))
        }
    }
    if toolOutputBlock == nil {
        print(
            """
            PDH-175 live smoke output timeout:
            error: \(String(describing: model.lastErrorMessage))
            candidate tool outputs:\n\(toolOutputDiagnostics.joined(separator: "\n"))
            """
        )
    }
    #expect(model.lastErrorMessage == nil)

    let renderedToolOutput = try #require(toolOutputBlock)
    #expect(renderedToolOutput.toolName == "filesystem.search")
    if !renderedToolOutput.command.isEmpty {
        #expect(renderedToolOutput.command == config.command)
    }
    #expect(!renderedToolOutput.output.isEmpty)
    #expect(renderedToolOutput.status == .succeeded)
}
