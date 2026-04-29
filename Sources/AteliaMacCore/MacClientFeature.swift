import AteliaKit
import Foundation

public struct MacClientFeature: Sendable, Equatable, Identifiable {
    public var id: String
    public var title: String
    public var isInitialScope: Bool

    public init(id: String, title: String, isInitialScope: Bool) {
        self.id = id
        self.title = title
        self.isInitialScope = isInitialScope
    }

    public static let initial: [MacClientFeature] = [
        MacClientFeature(id: "atelia", title: "Atelia surface", isInitialScope: true),
        MacClientFeature(id: "projects", title: "Projects and threads", isInitialScope: true),
        MacClientFeature(id: "git", title: "Git review surface", isInitialScope: true),
        MacClientFeature(id: "terminal", title: "In-app terminal", isInitialScope: true),
        MacClientFeature(id: "voice", title: "Voice operation", isInitialScope: true),
        MacClientFeature(id: "extensions", title: "Hooks, automations, and extensions", isInitialScope: true),
        MacClientFeature(id: "browser", title: "In-app browser", isInitialScope: false)
    ]
}
