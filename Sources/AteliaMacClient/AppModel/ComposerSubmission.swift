import AteliaMacClientModels
import AteliaKit
import Foundation

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
    let pathScope: AteliaPathScope?

    static func fromSendIntent(
        text: String,
        repositoryId: String,
        configuration: ComposerConfiguration,
        contexts: [ComposerContextSelection]
    ) -> ComposerJobSubmissionRequest? {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            return nil
        }

        return ComposerJobSubmissionRequest(
            repositoryId: repositoryId,
            message: trimmedText,
            goal: nil,
            modelRouteKey: configuration.selectedModel.routeKey,
            permissionModeRouteKey: configuration.permissionMode.routeKey,
            contextIDs: contexts.map(\.id),
            pathScope: nil
        )
    }

    func ateliaSubmitJobRequest(repositoryId resolvedRepositoryId: String? = nil) -> AteliaSubmitJobRequest {
        let toolIntent = Self.toolIntent(for: message)
        return AteliaSubmitJobRequest(
            repositoryId: resolvedRepositoryId ?? repositoryId,
            requester: .user(id: "mac-client", displayName: "Atelia Mac"),
            kind: toolIntent.map { _ in "tool" } ?? "message",
            goal: goal,
            pathScope: toolIntent?.pathScope ?? pathScope,
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
                pathScope: AteliaPathScope(kind: .repository),
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
                pathScope: AteliaPathScope(kind: .repository),
                toolArgs: AteliaSubmitJobToolArgs(
                    comparisonPath: comparisonPath,
                    maxBytes: 131_072,
                    maxChars: 32_000
                )
            )
        }

        return nil
    }

    private static func argument(afterAnyPrefix prefixes: [String], in message: String) -> String? {
        let lowercasedMessage = message.lowercased()
        for prefix in prefixes where lowercasedMessage.hasPrefix(prefix) {
            let index = message.index(message.startIndex, offsetBy: prefix.count)
            let argument = message[index...].trimmingCharacters(in: .whitespacesAndNewlines)
            return argument.isEmpty ? nil : argument
        }
        return nil
    }
}

private struct ComposerToolIntent: Equatable, Sendable {
    let requestedCapabilities: [String]
    let pathScope: AteliaPathScope
    let toolArgs: AteliaSubmitJobToolArgs
}
