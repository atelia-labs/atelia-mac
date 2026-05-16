import AteliaMacClientModels
import AteliaMacCore
import Foundation
import Observation

struct ProjectAddSelection: Equatable, Sendable {
    enum Source: Equatable, Sendable {
        case newFolder
        case existingFolder
    }

    var source: Source
    var folderURL: URL

    var label: String {
        let folderName = folderURL.lastPathComponent
        return folderName.isEmpty ? folderURL.path : folderName
    }
}

@MainActor
@Observable
final class ClientAppModel {
    private let projectStatusStore: MacProjectStatusStore
    private let projectFolderSelection: any ProjectFolderSelectionProviding

    private(set) var projectStatusSnapshot: MacProjectStatusSnapshot?
    private(set) var sidebarProjection: ClientSidebarProjection
    private(set) var isReloading: Bool
    private(set) var lastErrorMessage: String?
    private(set) var pendingProjectAddSelection: ProjectAddSelection?
    private(set) var sidebarSelectionState: ClientSidebarSelectionState?

    init(
        projectStatusStore: MacProjectStatusStore,
        projectFolderSelection: any ProjectFolderSelectionProviding = ProjectFolderPicker()
    ) {
        self.projectStatusStore = projectStatusStore
        self.projectFolderSelection = projectFolderSelection
        self.projectStatusSnapshot = nil
        self.pendingProjectAddSelection = nil
        self.sidebarSelectionState = nil
        self.sidebarProjection = ClientSidebarProjection(
            snapshot: nil,
            pendingProjectAddSelection: nil,
            selectionState: nil
        )
        self.isReloading = false
        self.lastErrorMessage = nil
    }

    func reloadProjectStatus() async throws {
        isReloading = true
        lastErrorMessage = nil
        defer {
            isReloading = false
        }

        do {
            try await projectStatusStore.reload()
            await syncProjectStatusFromStore()
        } catch {
            lastErrorMessage = error.localizedDescription
            throw error
        }
    }

    func clearProjectStatus() async {
        await projectStatusStore.clear()
        projectStatusSnapshot = nil
        pendingProjectAddSelection = nil
        sidebarSelectionState = .unloaded()
        syncSidebarProjection()
        lastErrorMessage = nil
    }

    func clearPendingProjectAddSelection() {
        pendingProjectAddSelection = nil
        syncSidebarProjection()
    }

    func syncProjectStatusFromStore() async {
        let snapshot = await projectStatusStore.snapshot
        projectStatusSnapshot = snapshot
        if let snapshot {
            if let selectionState = sidebarSelectionState, selectionState.isUnloaded {
                if selectionState.activePrimaryCommandID == "primary:new-thread" {
                    sidebarSelectionState = .newThread(
                        commandID: "primary:new-thread",
                        title: selectionState.activeConversationTitle,
                        projectSnapshot: snapshot,
                        surface: MockSurfaceReference.projectConversation
                    )
                } else {
                    sidebarSelectionState = .projectSecretary(snapshot: snapshot)
                }
            } else if sidebarSelectionState == nil {
                sidebarSelectionState = .projectSecretary(snapshot: snapshot)
            }
        } else if sidebarSelectionState == nil {
            sidebarSelectionState = .unloaded()
        }
        syncSidebarProjection()
    }

    func handleSidebarAction(_ action: SidebarAction) {
        switch action {
        case .command(id: let id, title: let title, surface: let surface, action: let sidebarAction):
            handleSidebarCommandAction(
                id: id,
                title: title,
                surface: surface,
                action: sidebarAction
            )
        case .chatItem(id: let id, projectID: let projectID, resourceID: let resourceID, title: let title, surface: let surface, action: let sidebarAction):
            handleSidebarChatItemAction(
                id: id,
                projectID: projectID,
                resourceID: resourceID,
                title: title,
                surface: surface,
                action: sidebarAction
            )
        case .projectSectionHeaderAction(let headerAction):
            handleProjectSectionHeaderAction(headerAction)
        case .dismissProjectAddCandidate:
            clearPendingProjectAddSelection()
        }
    }

    func handleProjectSectionHeaderAction(_ action: ProjectSectionHeaderActionViewData) {
        switch action.kind {
        case .createFolder:
            guard let folderURL = projectFolderSelection.createNewFolder() else {
                return
            }

            recordPendingProjectAddSelection(folderURL: folderURL, source: .newFolder)
        case .useExistingFolder:
            guard let folderURL = projectFolderSelection.chooseExistingFolder() else {
                return
            }

            recordPendingProjectAddSelection(folderURL: folderURL, source: .existingFolder)
        }
    }

    func recordPendingProjectAddSelection(folderURL: URL, source: ProjectAddSelection.Source) {
        pendingProjectAddSelection = ProjectAddSelection(source: source, folderURL: folderURL)
        lastErrorMessage = nil
        syncSidebarProjection()
    }

    private func syncSidebarProjection() {
        sidebarProjection = ClientSidebarProjection(
            snapshot: projectStatusSnapshot,
            pendingProjectAddSelection: pendingProjectAddSelection,
            selectionState: sidebarSelectionState
        )
    }

    private func handleSidebarCommandAction(
        id: String,
        title: String,
        surface: MockSurfaceReference,
        action: MockActionReference
    ) {
        switch action {
        case .startNewThread:
            let selectionState = ClientSidebarSelectionState.newThread(
                commandID: id,
                title: title,
                projectSnapshot: projectStatusSnapshot,
                surface: surface
            )
            sidebarSelectionState = selectionState
        case .searchAllProjects:
            sidebarSelectionState = .globalSearch(commandID: id, title: title)
        case .openProjectSettings:
            sidebarSelectionState = .globalSettings(title: title)
        default:
            let scope = fallbackScope(for: surface)
            sidebarSelectionState = .selectionState(
                projectTitle: scope.projectTitle,
                navigationItemID: nil,
                primaryCommandID: id,
                title: title,
                surface: surface,
                projectID: scope.projectID,
                resourceID: "surface-command:\(id)"
            )
        }
        syncSidebarProjection()
    }

    private func handleSidebarChatItemAction(
        id: String,
        projectID: String,
        resourceID: String,
        title: String,
        surface: MockSurfaceReference,
        action: MockActionReference
    ) {
        switch action {
        case .openGlobalSecretary:
            sidebarSelectionState = .globalSecretary()
        case .searchAllProjects:
            sidebarSelectionState = .globalSearch(commandID: nil, title: title)
        default:
            sidebarSelectionState = .selectionState(
                projectTitle: projectTitle(for: projectID),
                navigationItemID: id,
                primaryCommandID: nil,
                title: title,
                surface: surface,
                projectID: projectID,
                resourceID: resourceID
            )
        }
        syncSidebarProjection()
    }

    private func projectTitle(for projectID: String) -> String {
        if projectID == "global" {
            return "全プロジェクト"
        }

        return projectStatusSnapshot?.repositoryDisplayName ?? "プロジェクト未読込"
    }

    private func fallbackScope(for surface: MockSurfaceReference) -> (projectID: String, projectTitle: String) {
        if surface == MockSurfaceReference.projectConversation || surface == MockSurfaceReference.projectHome {
            return (
                projectID: projectStatusSnapshot.map { "project:\($0.repositoryId)" } ?? "project:unloaded",
                projectTitle: projectStatusSnapshot?.repositoryDisplayName ?? "プロジェクト未読込"
            )
        }

        return (
            projectID: "global",
            projectTitle: "全プロジェクト"
        )
    }
}
