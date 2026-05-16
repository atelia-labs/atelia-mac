import AteliaMacClientModels
import AteliaMacCore
import Foundation

struct ClientSidebarProjection {
    var activeConversationTitle: String
    var activeProjectTitle: String
    var activeSelection: ClientMockActiveSelection
    var projectSectionHeader: ProjectSectionHeaderViewData
    var projectAddCandidateLabel: String?
    var workspaceGroups: [WorkspaceGroup]
    var globalItems: [ChatListItem]

    var activeNavigationItemID: String {
        navigationItems.first { activeSelection.matches($0) }?.id ?? ""
    }

    var activeSurfaceID: String {
        "\(activeSelection.surfacePackageID)#\(activeSelection.surfaceID)"
    }

    init(
        snapshot: MacProjectStatusSnapshot?,
        pendingProjectAddSelection: ProjectAddSelection?
    ) {
        guard let snapshot else {
            self.activeConversationTitle = "Secretary"
            self.activeProjectTitle = "プロジェクト未読込"
            self.activeSelection = ClientMockActiveSelection(
                projectID: "project:unloaded",
                surfacePackageID: MockSurfaceReference.hostPackageID,
                surfaceID: MockSurfaceReference.projectConversation.surfaceID,
                resourceID: "conversation:unloaded:secretary"
            )
            self.projectSectionHeader = .projectSectionHeader
            self.workspaceGroups = [
                WorkspaceGroup(
                    id: "project:unloaded",
                    title: "プロジェクト未読込",
                    subtitle: nil,
                    surface: .projectHome,
                    items: [
                        ChatListItem(
                            id: "nav:unloaded:project-conversation",
                            projectID: "project:unloaded",
                            resourceID: "conversation:unloaded:secretary",
                            title: "Secretary",
                            trailing: nil,
                            leadingAffordance: .assistantConversation,
                            surface: .projectConversation,
                            action: .openProjectConversation
                        )
                    ],
                    emptyText: "Project status has not been loaded."
                )
            ]
            self.globalItems = Self.globalItems()
            self.projectAddCandidateLabel = pendingProjectAddSelection?.label
            return
        }

        let projectTitle = snapshot.repositoryDisplayName

        self.activeConversationTitle = "Secretary"
        self.activeProjectTitle = projectTitle
        self.activeSelection = ClientMockActiveSelection(
            projectID: "project:\(snapshot.repositoryId)",
            surfacePackageID: MockSurfaceReference.hostPackageID,
            surfaceID: MockSurfaceReference.projectConversation.surfaceID,
            resourceID: "conversation:\(snapshot.repositoryId):secretary"
        )
        self.projectSectionHeader = .projectSectionHeader
        self.projectAddCandidateLabel = pendingProjectAddSelection?.label
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

    init(mockState: ClientMockState) {
        self.activeConversationTitle = mockState.activeConversationTitle
        self.activeProjectTitle = mockState.activeProjectTitle
        self.activeSelection = mockState.activeSelection
        self.projectSectionHeader = mockState.projection.projectSectionHeader
        self.projectAddCandidateLabel = nil
        self.workspaceGroups = mockState.workspaceGroups
        self.globalItems = mockState.recentChats
    }

    static var empty: ClientSidebarProjection {
        ClientSidebarProjection(snapshot: nil, pendingProjectAddSelection: nil)
    }

    private static func projectItems(for snapshot: MacProjectStatusSnapshot) -> [ChatListItem] {
        [
            ChatListItem(
                id: "nav:\(snapshot.repositoryId):project-conversation",
                projectID: "project:\(snapshot.repositoryId)",
                resourceID: "conversation:\(snapshot.repositoryId):secretary",
                title: "Secretary",
                trailing: nil,
                leadingAffordance: .assistantConversation,
                surface: .projectConversation,
                action: .openProjectConversation
            ),
            ChatListItem(
                id: "nav:\(snapshot.repositoryId):delegated-work",
                projectID: "project:\(snapshot.repositoryId)",
                resourceID: "work:\(snapshot.repositoryId):delegated",
                title: "ジョブ",
                trailing: countLabel(snapshot.recentJobs.count),
                leadingAffordance: snapshot.recentJobs.isEmpty ? nil : .delegatedWork,
                surface: .projectHome,
                action: .inspectDelegatedWork
            )
        ]
    }

    private static func projectSettings(for snapshot: MacProjectStatusSnapshot) -> [ChatListItem] {
        [
            ChatListItem(
                id: "nav:\(snapshot.repositoryId):permission-recovery",
                projectID: "project:\(snapshot.repositoryId)",
                resourceID: "permissions:\(snapshot.repositoryId):audit",
                title: "ポリシー判断",
                trailing: countLabel(snapshot.recentPolicyDecisions.count),
                leadingAffordance: snapshot.recentPolicyDecisions.isEmpty ? nil : .packageInstall,
                surface: .permissionRecovery,
                action: .reviewPermissions
            ),
            ChatListItem(
                id: "nav:\(snapshot.repositoryId):settings",
                projectID: "project:\(snapshot.repositoryId)",
                resourceID: "settings:\(snapshot.repositoryId):project",
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
                projectID: "global",
                resourceID: "conversation:global:secretary",
                title: "Global Secretary",
                trailing: nil,
                leadingAffordance: .assistantConversation,
                surface: .globalSecretary,
                action: .openGlobalSecretary
            ),
            ChatListItem(
                id: "global:search",
                projectID: "global",
                resourceID: "search:global",
                title: "検索",
                trailing: nil,
                surface: .globalSearch,
                action: .searchAllProjects
            ),
            ChatListItem(
                id: "global:extensions",
                projectID: "global",
                resourceID: "packages:global:installed",
                title: "拡張機能",
                trailing: nil,
                surface: .packageManagement,
                action: .inspectInstalledPackages
            ),
            ChatListItem(
                id: "global:automations",
                projectID: "global",
                resourceID: "package-surface:official-automations:home",
                title: "オートメーション",
                trailing: nil,
                surface: .officialAutomations,
                action: .openAutomationsPackage
            ),
            ChatListItem(
                id: "global:mobile-setup",
                projectID: "global",
                resourceID: "settings:global:mobile",
                title: "Atelia Mobile を設定",
                trailing: nil,
                surface: .settings,
                action: .openMobileSetup
            )
        ]
    }

    private var navigationItems: [ChatListItem] {
        workspaceGroups.flatMap { $0.items + $0.settings } + globalItems
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
