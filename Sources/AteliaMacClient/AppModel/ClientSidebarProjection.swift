import AteliaMacClientModels
import AteliaMacCore
import Foundation

struct ClientSidebarSelectionState: Equatable, Sendable {
    var activeSelection: ClientMockActiveSelection
    var activeConversationTitle: String
    var activeProjectTitle: String
    var activeNavigationItemID: String?
    var activePrimaryCommandID: String?

    var isUnloaded: Bool {
        activeSelection.projectID == "project:unloaded"
    }

    static func selectionState(
        projectTitle: String,
        navigationItemID: String?,
        primaryCommandID: String?,
        title: String,
        surface: MockSurfaceReference,
        projectID: String,
        resourceID: String
    ) -> ClientSidebarSelectionState {
        ClientSidebarSelectionState(
            activeSelection: ClientMockActiveSelection(
                projectID: projectID,
                surfacePackageID: surface.packageID,
                surfaceID: surface.surfaceID,
                resourceID: resourceID
            ),
            activeConversationTitle: title,
            activeProjectTitle: projectTitle,
            activeNavigationItemID: navigationItemID,
            activePrimaryCommandID: primaryCommandID
        )
    }

    static func projectSecretary(snapshot: MacProjectStatusSnapshot) -> ClientSidebarSelectionState {
        ClientSidebarSelectionState(
            activeSelection: ClientMockActiveSelection(
                projectID: "project:\(snapshot.repositoryId)",
                surfacePackageID: MockSurfaceReference.hostPackageID,
                surfaceID: MockSurfaceReference.projectConversation.surfaceID,
                resourceID: "conversation:\(snapshot.repositoryId):secretary"
            ),
            activeConversationTitle: "Secretary",
            activeProjectTitle: snapshot.repositoryDisplayName,
            activeNavigationItemID: "nav:\(snapshot.repositoryId):project-conversation",
            activePrimaryCommandID: nil
        )
    }

    static func unloaded() -> ClientSidebarSelectionState {
        ClientSidebarSelectionState(
            activeSelection: ClientMockActiveSelection(
                projectID: "project:unloaded",
                surfacePackageID: MockSurfaceReference.hostPackageID,
                surfaceID: MockSurfaceReference.projectConversation.surfaceID,
                resourceID: "conversation:unloaded:secretary"
            ),
            activeConversationTitle: "Secretary",
            activeProjectTitle: "プロジェクト未読込",
            activeNavigationItemID: "nav:unloaded:project-conversation",
            activePrimaryCommandID: nil
        )
    }

    static func globalSecretary() -> ClientSidebarSelectionState {
        ClientSidebarSelectionState(
            activeSelection: ClientMockActiveSelection(
                projectID: "global",
                surfacePackageID: MockSurfaceReference.globalSecretary.packageID,
                surfaceID: MockSurfaceReference.globalSecretary.surfaceID,
                resourceID: "conversation:global:secretary"
            ),
            activeConversationTitle: "Global Secretary",
            activeProjectTitle: "全プロジェクト",
            activeNavigationItemID: "global:secretary",
            activePrimaryCommandID: nil
        )
    }

    static func globalSearch(commandID: String?, title: String) -> ClientSidebarSelectionState {
        ClientSidebarSelectionState(
            activeSelection: ClientMockActiveSelection(
                projectID: "global",
                surfacePackageID: MockSurfaceReference.globalSearch.packageID,
                surfaceID: MockSurfaceReference.globalSearch.surfaceID,
                resourceID: "search:global"
            ),
            activeConversationTitle: title,
            activeProjectTitle: "全プロジェクト",
            activeNavigationItemID: "global:search",
            activePrimaryCommandID: commandID
        )
    }

    static func globalSettings(title: String) -> ClientSidebarSelectionState {
        ClientSidebarSelectionState(
            activeSelection: ClientMockActiveSelection(
                projectID: "global",
                surfacePackageID: MockSurfaceReference.settings.packageID,
                surfaceID: MockSurfaceReference.settings.surfaceID,
                resourceID: "settings:global:workspace"
            ),
            activeConversationTitle: title,
            activeProjectTitle: "全プロジェクト",
            activeNavigationItemID: "global:settings",
            activePrimaryCommandID: nil
        )
    }

    static func newThread(
        commandID: String,
        title: String,
        projectSnapshot: MacProjectStatusSnapshot?,
        surface: MockSurfaceReference
    ) -> ClientSidebarSelectionState {
        let repositoryId = projectSnapshot?.repositoryId ?? "unloaded"
        let projectID = projectSnapshot.map { "project:\($0.repositoryId)" } ?? "project:unloaded"
        return ClientSidebarSelectionState(
            activeSelection: ClientMockActiveSelection(
                projectID: projectID,
                surfacePackageID: surface.packageID,
                surfaceID: surface.surfaceID,
                resourceID: "conversation:\(repositoryId):draft"
            ),
            activeConversationTitle: title,
            activeProjectTitle: projectSnapshot?.repositoryDisplayName ?? "プロジェクト未読込",
            activeNavigationItemID: projectSnapshot.map { "nav:\($0.repositoryId):project-conversation" } ?? "nav:unloaded:project-conversation",
            activePrimaryCommandID: commandID
        )
    }
}

struct ClientSidebarProjection {
    var activeConversationTitle: String
    var activeProjectTitle: String
    var activeSelection: ClientMockActiveSelection
    var activeNavigationItemID: String
    var activePrimaryCommandID: String?
    var projectSectionHeader: ProjectSectionHeaderViewData
    var projectAddCandidateLabel: String?
    var workspaceGroups: [WorkspaceGroup]
    var globalItems: [ChatListItem]

    var activeSurfaceID: String {
        "\(activeSelection.surfacePackageID)#\(activeSelection.surfaceID)"
    }

    init(
        snapshot: MacProjectStatusSnapshot?,
        pendingProjectAddSelection: ProjectAddSelection?,
        selectionState: ClientSidebarSelectionState? = nil
    ) {
        guard let snapshot else {
            let selectionState = selectionState ?? .unloaded()
            self.activeConversationTitle = selectionState.activeConversationTitle
            self.activeProjectTitle = selectionState.activeProjectTitle
            self.activeSelection = selectionState.activeSelection
            self.activeNavigationItemID = selectionState.activeNavigationItemID ?? ""
            self.activePrimaryCommandID = selectionState.activePrimaryCommandID
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

        let selectionState = selectionState ?? .projectSecretary(snapshot: snapshot)
        let projectGroup = WorkspaceGroup(
            id: "project:\(snapshot.repositoryId)",
            title: snapshot.repositoryDisplayName,
            subtitle: Self.repositorySubtitle(for: snapshot.repositoryRootPath),
            surface: .projectHome,
            items: Self.projectItems(for: snapshot),
            settings: Self.projectSettings(for: snapshot),
            status: Self.status(for: snapshot)
        )
        let globalItems = Self.globalItems()

        self.activeConversationTitle = selectionState.activeConversationTitle
        self.activeProjectTitle = selectionState.activeProjectTitle
        self.activeSelection = selectionState.activeSelection
        self.activeNavigationItemID = selectionState.activeNavigationItemID ?? (projectGroup.items + projectGroup.settings + globalItems).first { selectionState.activeSelection.matches($0) }?.id ?? ""
        self.activePrimaryCommandID = selectionState.activePrimaryCommandID
        self.projectSectionHeader = .projectSectionHeader
        self.projectAddCandidateLabel = pendingProjectAddSelection?.label
        self.workspaceGroups = [projectGroup]
        self.globalItems = globalItems
    }

    init(mockState: ClientMockState) {
        self.activeConversationTitle = mockState.activeConversationTitle
        self.activeProjectTitle = mockState.activeProjectTitle
        self.activeSelection = mockState.activeSelection
        self.activeNavigationItemID = mockState.activeNavigationItemID
        self.activePrimaryCommandID = nil
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
                id: "nav:\(snapshot.repositoryId):extensions",
                projectID: "project:\(snapshot.repositoryId)",
                resourceID: "packages:\(snapshot.repositoryId):installed",
                title: "拡張機能",
                trailing: nil,
                surface: .packageManagement,
                action: nil
            ),
            ChatListItem(
                id: "nav:\(snapshot.repositoryId):automations",
                projectID: "project:\(snapshot.repositoryId)",
                resourceID: "package-surface:official-automations:home",
                title: "オートメーション",
                trailing: nil,
                surface: .officialAutomations,
                action: nil
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
