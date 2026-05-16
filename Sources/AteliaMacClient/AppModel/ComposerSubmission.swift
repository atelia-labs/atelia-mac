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
            modelRouteKey: configuration.routeKey,
            permissionModeRouteKey: configuration.permissionMode.routeKey,
            contextIDs: contexts.map(\.id),
            pathScope: nil
        )
    }
}
