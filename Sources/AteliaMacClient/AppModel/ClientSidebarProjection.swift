import AteliaMacClientModels
import AteliaMacCore
import Foundation

struct ClientSidebarProjection {
    var activeConversationTitle: String
    var activeProjectTitle: String
    var workspaceGroups: [WorkspaceGroup]
    var globalItems: [ChatListItem]

    init(snapshot: MacProjectStatusSnapshot?) {
        guard let snapshot else {
            self.activeConversationTitle = "Secretary"
            self.activeProjectTitle = "プロジェクト未読込"
            self.workspaceGroups = [
                WorkspaceGroup(
                    id: "project:unloaded",
                    title: "プロジェクト未読込",
                    subtitle: nil,
                    surface: .projectHome,
                    items: [
                        ChatListItem(
                            id: "nav:unloaded:project-conversation",
                            title: "Secretary",
                            trailing: nil,
                            isSelected: true,
                            leadingStatus: .secretary,
                            surface: .projectConversation,
                            action: .openProjectConversation
                        )
                    ],
                    emptyText: "Project status has not been loaded."
                )
            ]
            self.globalItems = Self.globalItems()
            return
        }

        let projectTitle = snapshot.repositoryDisplayName

        self.activeConversationTitle = "Secretary"
        self.activeProjectTitle = projectTitle
        self.workspaceGroups = [
            WorkspaceGroup(
                id: "project:\(snapshot.repositoryId)",
                title: projectTitle,
                subtitle: Self.repositorySubtitle(for: snapshot.repositoryRootPath),
                surface: .projectHome,
                items: Self.projectItems(for: snapshot),
                settings: Self.projectSettings(for: snapshot),
                status: Self.status(for: snapshot)
            )
        ]
        self.globalItems = Self.globalItems()
    }

    static var empty: ClientSidebarProjection {
        ClientSidebarProjection(snapshot: nil)
    }

    private static func projectItems(for snapshot: MacProjectStatusSnapshot) -> [ChatListItem] {
        [
            ChatListItem(
                id: "nav:\(snapshot.repositoryId):project-conversation",
                title: "Secretary",
                trailing: nil,
                isSelected: true,
                leadingStatus: .secretary,
                surface: .projectConversation,
                action: .openProjectConversation
            ),
            ChatListItem(
                id: "nav:\(snapshot.repositoryId):delegated-work",
                title: "ジョブ",
                trailing: countLabel(snapshot.recentJobs.count),
                leadingStatus: snapshot.recentJobs.isEmpty ? nil : .branch,
                surface: .projectHome,
                action: .inspectDelegatedWork
            )
        ]
    }

    private static func projectSettings(for snapshot: MacProjectStatusSnapshot) -> [ChatListItem] {
        [
            ChatListItem(
                id: "nav:\(snapshot.repositoryId):permission-recovery",
                title: "ポリシー判断",
                trailing: countLabel(snapshot.recentPolicyDecisions.count),
                leadingStatus: snapshot.recentPolicyDecisions.isEmpty ? nil : .plus,
                surface: .permissionRecovery,
                action: .reviewPermissions
            ),
            ChatListItem(
                id: "nav:\(snapshot.repositoryId):settings",
                title: "プロジェクト設定",
                trailing: nil,
                surface: .settings,
                action: .openProjectSettings
            )
        ]
    }

    private static func globalItems() -> [ChatListItem] {
        [
            ChatListItem(
                id: "global:secretary",
                title: "Global Secretary",
                trailing: nil,
                leadingStatus: .secretary,
                surface: .projectConversation,
                action: .openProjectConversation
            ),
            ChatListItem(id: "global:search", title: "検索", trailing: nil, surface: .projectHome),
            ChatListItem(
                id: "global:extensions",
                title: "拡張機能",
                trailing: nil,
                surface: .packageManagement,
                action: .inspectInstalledPackages
            ),
            ChatListItem(
                id: "global:automations",
                title: "オートメーション",
                trailing: nil,
                surface: .officialAutomations,
                action: .openAutomationsPackage
            ),
            ChatListItem(id: "global:mobile-setup", title: "Atelia Mobile を設定", trailing: nil, surface: .settings)
        ]
    }

    private static func repositorySubtitle(for rootPath: String) -> String? {
        let lastPathComponent = URL(fileURLWithPath: rootPath).lastPathComponent
        return lastPathComponent.isEmpty ? nil : lastPathComponent
    }

    private static func countLabel(_ count: Int) -> String? {
        count > 0 ? "\(count)" : nil
    }

    private static func status(for snapshot: MacProjectStatusSnapshot) -> WorkspaceGroup.Status? {
        snapshot.isReady ? nil : .warning
    }
}
