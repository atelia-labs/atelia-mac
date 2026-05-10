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
        MacClientFeature(id: "project-space", title: "Atelia project space", isInitialScope: true),
        MacClientFeature(id: "project-home", title: "Project home surface", isInitialScope: true),
        MacClientFeature(id: "project-conversation", title: "Project conversation", isInitialScope: true),
        MacClientFeature(id: "project-navigation", title: "Minimal project navigation", isInitialScope: true),
        MacClientFeature(id: "secretary-connection", title: "Atelia Secretary daemon connection", isInitialScope: true),
        MacClientFeature(id: "permission-recovery", title: "Permission, approval, audit, and recovery surfaces", isInitialScope: true),
        MacClientFeature(id: "package-management", title: "Package installation, inspection, disabling, rollback, and safe mode", isInitialScope: true),
        MacClientFeature(id: "presentation-renderer", title: "AEP semantic presentation renderer subset", isInitialScope: true),
        MacClientFeature(id: "settings", title: "Settings", isInitialScope: true)
    ]
}
