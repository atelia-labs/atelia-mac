import AteliaMacClientModels
import AteliaKit
import Foundation

enum ClientLifecycleRequestIdentity {
    static let requester = AteliaActor.user(id: "mac-client", displayName: "Atelia Mac")
}

enum ComposerConversationTarget: Equatable, Sendable {
    case project(repositoryId: String)
    case global
    case unavailable
}

struct ComposerJobSubmissionRequest: Equatable, Sendable {
    let repositoryId: String
    let message: String
    let goal: String?
    let modelRouteKey: String
    let permissionModeRouteKey: String
    let contextIDs: [String]
    let contextDisplayNames: [String]
    let pathScope: AteliaPathScope?

    static func fromSendIntent(
        text: String,
        repositoryId: String,
        configuration: ComposerConfiguration,
        contexts: [ComposerContextSelection],
        repositoryRootPath: String? = nil
    ) -> ComposerJobSubmissionRequest? {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            return nil
        }
        let pathScope = Self.explicitRootPathScope(for: repositoryRootPath)

        return ComposerJobSubmissionRequest(
            repositoryId: repositoryId,
            message: trimmedText,
            goal: nil,
            modelRouteKey: configuration.selectedModel.routeKey,
            permissionModeRouteKey: configuration.permissionMode.routeKey,
            contextIDs: contexts.map(\.id),
            contextDisplayNames: contexts.map { $0.displayName ?? $0.id },
            pathScope: pathScope
        )
    }

    func ateliaSubmitJobRequest(repositoryId resolvedRepositoryId: String? = nil) -> AteliaSubmitJobRequest {
        let toolIntent = Self.toolIntent(for: message)
        return AteliaSubmitJobRequest(
            repositoryId: resolvedRepositoryId ?? repositoryId,
            requester: ClientLifecycleRequestIdentity.requester,
            kind: toolIntent.map { _ in "tool" } ?? "message",
            message: message,
            goal: goal,
            modelRouteKey: modelRouteKey.isEmpty ? nil : modelRouteKey,
            permissionModeRouteKey: permissionModeRouteKey.isEmpty ? nil : permissionModeRouteKey,
            pathScope: pathScope,
            requestedCapabilities: toolIntent?.requestedCapabilities,
            toolArgs: toolIntent?.toolArgs
        )
    }

    private static func toolIntent(for message: String) -> ComposerToolIntent? {
        let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else {
            return nil
        }

        if let query = argument(afterAnyPrefix: [
            "search ",
            "/search ",
            "fs.search ",
            "filesystem.search "
        ], in: trimmedMessage) {
            return ComposerToolIntent(
                requestedCapabilities: ["filesystem.search"],
                toolArgs: AteliaSubmitJobToolArgs(pattern: query, max: 20)
            )
        }

        if let comparisonPath = argument(afterAnyPrefix: [
            "diff ",
            "/diff ",
            "fs.diff ",
            "filesystem.diff "
        ], in: trimmedMessage) {
            return ComposerToolIntent(
                requestedCapabilities: ["filesystem.diff"],
                toolArgs: AteliaSubmitJobToolArgs(
                    comparisonPath: comparisonPath,
                    maxBytes: 131_072,
                    maxChars: 32_000
                )
            )
        }

        return nil
    }

    private static func explicitRootPathScope(for path: String?) -> AteliaPathScope? {
        guard let path,
              !path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        return AteliaPathScope(kind: .explicitPaths, roots: [path])
    }

    private static func argument(afterAnyPrefix prefixes: [String], in message: String) -> String? {
        let lowercasedMessage = message.lowercased()
        for prefix in prefixes where lowercasedMessage.hasPrefix(prefix) {
            // Command prefixes are ASCII-only, so their character count is safe
            // to apply to the original message after lowercased matching.
            let index = message.index(message.startIndex, offsetBy: prefix.count)
            let argument = message[index...].trimmingCharacters(in: .whitespacesAndNewlines)
            return argument.isEmpty ? nil : argument
        }
        return nil
    }
}

private struct ComposerToolIntent: Equatable, Sendable {
    let requestedCapabilities: [String]
    let toolArgs: AteliaSubmitJobToolArgs
}
