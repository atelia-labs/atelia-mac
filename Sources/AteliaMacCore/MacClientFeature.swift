import AteliaKit
import Foundation

public struct MacClientFeature: Sendable, Equatable, Identifiable {
    public let id: String
    public let title: String

    public init(id: String, title: String) {
        self.id = id
        self.title = title
    }

    public static let initial: [MacClientFeature] = [
        MacClientFeature(id: "project-space", title: "Atelia project space"),
        MacClientFeature(id: "project-home", title: "Project home surface"),
        MacClientFeature(id: "project-conversation", title: "Project conversation"),
        MacClientFeature(id: "project-navigation", title: "Minimal project navigation"),
        MacClientFeature(id: "secretary-connection", title: "Atelia Secretary daemon connection"),
        MacClientFeature(id: "permission-recovery", title: "Permission, approval, audit, and recovery surfaces"),
        MacClientFeature(id: "package-management", title: "Package installation, inspection, disabling, rollback, and safe mode"),
        MacClientFeature(id: "presentation-renderer", title: "AEP semantic presentation renderer subset"),
        MacClientFeature(id: "settings", title: "Settings")
    ]
}
