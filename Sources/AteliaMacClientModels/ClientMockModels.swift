import Foundation

public struct ClientMockState: Sendable {
    public var activeConversationTitle: String
    public var activeProjectTitle: String
    public var workspaceGroups: [WorkspaceGroup]
    public var recentChats: [ChatListItem]
    public var changeSummary: ChangeSummary
    public var messages: [ChatMessage]
    public var activity: ActivityBlock
    public var goal: GoalStatus

    public static let ateliaReference = ClientMockState(
        activeConversationTitle: "Secretary による package safety 更新",
        activeProjectTitle: "Mac Atelia",
        workspaceGroups: [
            WorkspaceGroup(
                id: "project:mac-atelia",
                title: "Mac Atelia",
                subtitle: nil,
                surface: .projectHome,
                items: [
                    ChatListItem(
                        id: "nav:mac-atelia:project-conversation",
                        title: "Secretary",
                        trailing: nil,
                        isSelected: true,
                        leadingStatus: .secretary,
                        surface: .projectConversation,
                        action: .openProjectConversation
                    ),
                    ChatListItem(
                        id: "nav:mac-atelia:delegated-work",
                        title: "委任中の作業",
                        trailing: "3",
                        leadingStatus: .branch,
                        surface: .projectHome,
                        action: .inspectDelegatedWork
                    )
                ],
                settings: [
                    ChatListItem(
                        id: "nav:mac-atelia:package-management",
                        title: "パッケージ",
                        trailing: nil,
                        leadingStatus: .plus,
                        surface: .packageManagement,
                        action: .inspectInstalledPackages
                    ),
                    ChatListItem(
                        id: "nav:mac-atelia:permission-recovery",
                        title: "権限と監査",
                        trailing: nil,
                        surface: .permissionRecovery,
                        action: .reviewPermissions
                    ),
                    ChatListItem(
                        id: "nav:mac-atelia:settings",
                        title: "プロジェクト設定",
                        trailing: nil,
                        surface: .settings,
                        action: .openProjectSettings
                    )
                ]
            ),
            WorkspaceGroup(
                id: "project:atelia-secretary",
                title: "atelia-secretary",
                subtitle: "Global Secretary",
                surface: .projectHome,
                items: [
                    ChatListItem(
                        id: "nav:atelia-secretary:project-conversation",
                        title: "Secretary",
                        trailing: nil,
                        leadingStatus: .secretary,
                        surface: .projectConversation,
                        action: .openProjectConversation
                    ),
                    ChatListItem(
                        id: "nav:atelia-secretary:package-audit",
                        title: "package audit",
                        trailing: "2",
                        surface: .packageManagement,
                        action: .inspectInstalledPackages
                    )
                ],
                status: .warning
            ),
            WorkspaceGroup(
                id: "packages:bundled-official",
                title: "公式パッケージ",
                subtitle: "bundled-official / enabled",
                surface: .packageManagement,
                items: [
                    ChatListItem(
                        id: "nav:official-automations:surface-home",
                        title: "Automations",
                        trailing: "2",
                        surface: .officialAutomations,
                        action: .openAutomationsPackage
                    ),
                    ChatListItem(
                        id: "nav:official-review:surface-home",
                        title: "Review",
                        trailing: nil,
                        surface: .officialReview,
                        action: .openReviewPackage
                    )
                ]
            )
        ],
        recentChats: [
            ChatListItem(
                id: "recent:mac-atelia:project-conversation",
                title: "Project conversation",
                trailing: nil,
                leadingStatus: .secretary,
                surface: .projectConversation,
                action: .openProjectConversation
            ),
            ChatListItem(
                id: "recent:mac-atelia:package-management",
                title: "Package inspection",
                trailing: nil,
                surface: .packageManagement,
                action: .inspectInstalledPackages
            ),
            ChatListItem(
                id: "recent:official-automations:surface-home",
                title: "Automations package",
                trailing: nil,
                surface: .officialAutomations,
                action: .openAutomationsPackage
            ),
            ChatListItem(
                id: "recent:official-review:surface-home",
                title: "Review package",
                trailing: nil,
                surface: .officialReview,
                action: .openReviewPackage
            )
        ],
        changeSummary: ChangeSummary(
            filePath: "atelia-secretary-package-audit/crates/ateliad/src/rpc.rs",
            additions: 68,
            deletions: 9,
            collapsedFileCount: 1
        ),
        messages: [
            ChatMessage(
                id: "message:surface-fixture-request",
                text: "おっけー\npackage safety review の mock 表示を、baseline surface と bundled-official package surface が分かれる形に直してほしい。\n将来の実データに置き換えられるように、surface id、package id、action metadata、stable id を持たせて。",
                attachmentName: "standard-surfaces.md"
            )
        ],
        activity: ActivityBlock(
            duration: "36s",
            title: "Client mock surface fixture を更新しました。",
            bullets: [
                "navigation item を stable mock id と surface provenance で識別",
                "`package-management` と `permission-recovery` を baseline surface として明示",
                "`official.automations` は bundled-official package surface として optional lifecycle に分離"
            ],
            document: DocumentPreview(title: "standard-surfaces.md", subtitle: "ドキュメント・MD"),
            review: ReviewPreview(title: "2 件のファイルを編集", additions: 50, deletions: 47)
        ),
        goal: GoalStatus(
            title: "一時停止中の目標 Package-Driven Atelia MDP: dynamic Mac client",
            elapsed: "33h 39m 21s"
        )
    )

    public static let codexReference = ateliaReference
}

public struct MockSurfaceReference: Hashable, Identifiable, Sendable {
    public var packageID: String
    public var surfaceID: String
    public var lifecycle: MockSurfaceLifecycle
    public var trust: MockSurfaceTrust
    public var criticality: MockSurfaceCriticality
    public var schemaVersion: String

    public var id: String {
        "\(packageID)#\(surfaceID)"
    }

    public static let hostPackageID = "dev.atelia.mac.host"
}

public enum MockSurfaceLifecycle: String, Hashable, Sendable {
    case mounted
    case availableWhenEnabled
}

public enum MockSurfaceTrust: String, Hashable, Sendable {
    case hostShippedBuiltIn
    case bundledOfficial
}

public enum MockSurfaceCriticality: String, Hashable, Sendable {
    case hostRequired
    case userRemovable
}

public struct MockActionReference: Hashable, Sendable {
    public var actionID: String
    public var declaredBySurfaceID: String
    public var permissionScope: String
    public var auditEvent: String
}

public extension MockSurfaceReference {
    static let projectHome = MockSurfaceReference(
        packageID: hostPackageID,
        surfaceID: "project-home",
        lifecycle: .mounted,
        trust: .hostShippedBuiltIn,
        criticality: .hostRequired,
        schemaVersion: "surface.mock.v1"
    )

    static let projectConversation = MockSurfaceReference(
        packageID: hostPackageID,
        surfaceID: "project-conversation",
        lifecycle: .mounted,
        trust: .hostShippedBuiltIn,
        criticality: .hostRequired,
        schemaVersion: "surface.mock.v1"
    )

    static let packageManagement = MockSurfaceReference(
        packageID: hostPackageID,
        surfaceID: "package-management",
        lifecycle: .mounted,
        trust: .hostShippedBuiltIn,
        criticality: .hostRequired,
        schemaVersion: "surface.mock.v1"
    )

    static let permissionRecovery = MockSurfaceReference(
        packageID: hostPackageID,
        surfaceID: "permission-recovery",
        lifecycle: .mounted,
        trust: .hostShippedBuiltIn,
        criticality: .hostRequired,
        schemaVersion: "surface.mock.v1"
    )

    static let settings = MockSurfaceReference(
        packageID: hostPackageID,
        surfaceID: "settings",
        lifecycle: .mounted,
        trust: .hostShippedBuiltIn,
        criticality: .hostRequired,
        schemaVersion: "surface.mock.v1"
    )

    static let officialAutomations = MockSurfaceReference(
        packageID: "dev.atelia.packages.official.automations",
        surfaceID: "automations-home",
        lifecycle: .availableWhenEnabled,
        trust: .bundledOfficial,
        criticality: .userRemovable,
        schemaVersion: "surface.mock.v1"
    )

    static let officialReview = MockSurfaceReference(
        packageID: "dev.atelia.packages.official.review",
        surfaceID: "review-home",
        lifecycle: .availableWhenEnabled,
        trust: .bundledOfficial,
        criticality: .userRemovable,
        schemaVersion: "surface.mock.v1"
    )
}

public extension MockActionReference {
    static let openProjectConversation = MockActionReference(
        actionID: "action.project-conversation.open",
        declaredBySurfaceID: "project-conversation",
        permissionScope: "project.conversation.read",
        auditEvent: "project_conversation.opened"
    )

    static let inspectDelegatedWork = MockActionReference(
        actionID: "action.project-home.inspect-delegated-work",
        declaredBySurfaceID: "project-home",
        permissionScope: "project.work.read",
        auditEvent: "project_work.inspected"
    )

    static let inspectInstalledPackages = MockActionReference(
        actionID: "action.package-management.inspect-installed",
        declaredBySurfaceID: "package-management",
        permissionScope: "packages.inspect",
        auditEvent: "packages.inspected"
    )

    static let reviewPermissions = MockActionReference(
        actionID: "action.permission-recovery.review",
        declaredBySurfaceID: "permission-recovery",
        permissionScope: "permissions.review",
        auditEvent: "permissions.reviewed"
    )

    static let openProjectSettings = MockActionReference(
        actionID: "action.settings.open-project",
        declaredBySurfaceID: "settings",
        permissionScope: "project.settings.read",
        auditEvent: "project_settings.opened"
    )

    static let openAutomationsPackage = MockActionReference(
        actionID: "action.official-automations.open",
        declaredBySurfaceID: "automations-home",
        permissionScope: "packages.official.automations.read",
        auditEvent: "package_surface.opened"
    )

    static let openReviewPackage = MockActionReference(
        actionID: "action.official-review.open",
        declaredBySurfaceID: "review-home",
        permissionScope: "packages.official.review.read",
        auditEvent: "package_surface.opened"
    )
}

public struct WorkspaceGroup: Identifiable, Sendable {
    public enum Status: Sendable {
        case warning
    }

    public var id: String
    public var title: String
    public var subtitle: String?
    public var surface: MockSurfaceReference
    public var items: [ChatListItem]
    public var settings: [ChatListItem] = []
    public var status: Status?
    public var emptyText: String?
}

public struct ChatListItem: Identifiable, Sendable {
    public enum LeadingStatus: Sendable {
        case green
        case secretary
        case branch
        case plus
    }

    public var id: String
    public var title: String
    public var trailing: String?
    public var isSelected = false
    public var leadingStatus: LeadingStatus?
    public var surface: MockSurfaceReference
    public var action: MockActionReference?
}

public struct ChangeSummary: Sendable {
    public var filePath: String
    public var additions: Int
    public var deletions: Int
    public var collapsedFileCount: Int
}

public struct ChatMessage: Identifiable, Sendable {
    public var id: String
    public var text: String
    public var attachmentName: String?
}

public struct ActivityBlock: Sendable {
    public var duration: String
    public var title: String
    public var bullets: [String]
    public var document: DocumentPreview
    public var review: ReviewPreview
}

public struct DocumentPreview: Sendable {
    public var title: String
    public var subtitle: String
}

public struct ReviewPreview: Sendable {
    public var title: String
    public var additions: Int
    public var deletions: Int
}

public struct GoalStatus: Sendable {
    public var title: String
    public var elapsed: String
}
