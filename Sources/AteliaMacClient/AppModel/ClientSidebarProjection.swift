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
                    title: "プロジェクト未読込",
                    subtitle: nil,
                    items: [
                        ChatListItem(title: "Secretary", trailing: nil, isSelected: true, leadingStatus: .secretary)
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
                title: projectTitle,
                subtitle: Self.repositorySubtitle(for: snapshot.repositoryRootPath),
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
            ChatListItem(title: "Secretary", trailing: nil, isSelected: true, leadingStatus: .secretary),
            ChatListItem(
                title: "ジョブ",
                trailing: countLabel(snapshot.recentJobs.count),
                leadingStatus: snapshot.recentJobs.isEmpty ? nil : .branch
            )
        ]
    }

    private static func projectSettings(for snapshot: MacProjectStatusSnapshot) -> [ChatListItem] {
        [
            ChatListItem(
                title: "ポリシー判断",
                trailing: countLabel(snapshot.recentPolicyDecisions.count),
                leadingStatus: snapshot.recentPolicyDecisions.isEmpty ? nil : .plus
            ),
            ChatListItem(title: "プロジェクト設定", trailing: nil)
        ]
    }

    private static func globalItems() -> [ChatListItem] {
        [
            ChatListItem(title: "Global Secretary", trailing: nil, leadingStatus: .secretary),
            ChatListItem(title: "検索", trailing: nil),
            ChatListItem(title: "拡張機能", trailing: nil),
            ChatListItem(title: "オートメーション", trailing: nil),
            ChatListItem(title: "Atelia Mobile を設定", trailing: nil)
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
        snapshot.daemonLabel.contains("| Ready") && snapshot.storageLabel.contains("| Ready") ? nil : .warning
    }
}
