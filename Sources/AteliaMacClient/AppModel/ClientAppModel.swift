import AteliaMacCore
import Foundation
import Observation

@MainActor
@Observable
final class ClientAppModel {
    private let projectStatusStore: MacProjectStatusStore

    private(set) var projectStatusSnapshot: MacProjectStatusSnapshot?
    private(set) var sidebarProjection: ClientSidebarProjection
    private(set) var isReloading: Bool
    private(set) var lastErrorMessage: String?

    init(projectStatusStore: MacProjectStatusStore) {
        self.projectStatusStore = projectStatusStore
        self.projectStatusSnapshot = nil
        self.sidebarProjection = .empty
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
        sidebarProjection = .empty
        lastErrorMessage = nil
    }

    func syncProjectStatusFromStore() async {
        let snapshot = await projectStatusStore.snapshot
        projectStatusSnapshot = snapshot
        sidebarProjection = ClientSidebarProjection(snapshot: snapshot)
    }
}
