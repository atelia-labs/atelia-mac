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
        let folderName = folderURL.lastPathComponent.isEmpty ? folderURL.path : folderURL.lastPathComponent
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

    init(
        projectStatusStore: MacProjectStatusStore,
        projectFolderSelection: any ProjectFolderSelectionProviding = ProjectFolderPicker()
    ) {
        self.projectStatusStore = projectStatusStore
        self.projectFolderSelection = projectFolderSelection
        self.projectStatusSnapshot = nil
        self.pendingProjectAddSelection = nil
        self.sidebarProjection = ClientSidebarProjection(
            snapshot: nil,
            pendingProjectAddSelection: nil
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
        syncSidebarProjection()
        lastErrorMessage = nil
    }

    func syncProjectStatusFromStore() async {
        let snapshot = await projectStatusStore.snapshot
        projectStatusSnapshot = snapshot
        syncSidebarProjection()
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
            pendingProjectAddSelection: pendingProjectAddSelection
        )
    }
}
