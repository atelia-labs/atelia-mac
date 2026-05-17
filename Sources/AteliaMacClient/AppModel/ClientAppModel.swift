import AteliaKit
import AteliaMacClientModels
import AteliaMacCore
import Foundation
import Observation

@MainActor
@Observable
final class ClientAppModel {
    private let projectStatusStore: MacProjectStatusStore
    private let projectLifecycleStore: (any MacProjectLifecycleStoring)?
    private let projectFolderSelection: any ProjectFolderSelectionProviding
    private let localProjectRegistry: any LocalProjectRegistry

    private(set) var projectStatusSnapshot: MacProjectStatusSnapshot?
    private(set) var localProjects: [LocalProjectRegistration]
    private(set) var sidebarProjection: ClientSidebarProjection
    private(set) var shellState: ClientMockState
    private(set) var isReloading: Bool
    private(set) var lastErrorMessage: String?
    private(set) var lastComposerSubmissionRequest: ComposerJobSubmissionRequest?
    private(set) var lastAteliaSubmitJobRequest: AteliaSubmitJobRequest?
    private(set) var sidebarSelectionState: ClientSidebarSelectionState?
    private var localConversationDrafts: [String: [ClientConversationTurnFixture]]
    private var registeredRepositoryIDsByLocalProjectID: [String: String]
    private var composerSubmissionSequence: UInt64
    private var localProjectOpenTasksByID: [String: LocalProjectOpenTask]
    private var projectTopologyGeneration: UInt64

    init(
        projectStatusStore: MacProjectStatusStore,
        projectLifecycleStore: (any MacProjectLifecycleStoring)? = nil,
        projectFolderSelection: any ProjectFolderSelectionProviding = ProjectFolderPicker(),
        localProjectRegistry: any LocalProjectRegistry = InMemoryLocalProjectRegistry()
    ) {
        self.projectStatusStore = projectStatusStore
        self.projectLifecycleStore = projectLifecycleStore
        self.projectFolderSelection = projectFolderSelection
        self.localProjectRegistry = localProjectRegistry
        self.projectStatusSnapshot = nil
        let loadedLocalProjects = localProjectRegistry.listProjects()
        self.localProjects = loadedLocalProjects
        self.sidebarSelectionState = nil
        self.localConversationDrafts = [:]
        self.sidebarProjection = ClientSidebarProjection(
            snapshot: nil,
            localProjects: loadedLocalProjects,
            selectionState: nil
        )
        self.shellState = .ateliaReference
        self.isReloading = false
        self.lastErrorMessage = nil
        self.lastComposerSubmissionRequest = nil
        self.lastAteliaSubmitJobRequest = nil
        self.registeredRepositoryIDsByLocalProjectID = [:]
        self.composerSubmissionSequence = 0
        self.localProjectOpenTasksByID = [:]
        self.projectTopologyGeneration = 0
        syncShellState()
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
        projectTopologyGeneration += 1
        cancelLocalProjectOpenTasks()
        await projectStatusStore.clear()
        projectStatusSnapshot = nil
        localProjects = []
        localProjectRegistry.clearProjects()
        sidebarSelectionState = .unloaded()
        lastComposerSubmissionRequest = nil
        lastAteliaSubmitJobRequest = nil
        localConversationDrafts = [:]
        registeredRepositoryIDsByLocalProjectID = [:]
        composerSubmissionSequence += 1
        syncSidebarProjection()
        lastErrorMessage = nil
    }

    func syncProjectStatusFromStore() async {
        let snapshot = await projectStatusStore.snapshot
        projectStatusSnapshot = snapshot
        if let snapshot {
            migrateLocalConversationDrafts(
                matchingRootPath: snapshot.repositoryRootPath,
                to: snapshot.repositoryId
            )

            if let selectionState = sidebarSelectionState,
               let selectedLocalProject = localProject(forProjectID: selectionState.activeSelection.projectID),
               selectedLocalProject.hasSameRootPath(as: snapshot.repositoryRootPath) {
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
            } else if let selectionState = sidebarSelectionState, selectionState.isUnloaded {
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
        case .removeLocalProject(let id):
            removeLocalProject(id: id)
        }
    }

    func activeConversationTarget() -> ComposerConversationTarget {
        let activeSelection = sidebarSelectionState?.activeSelection ?? sidebarProjection.activeSelection
        if activeSelection.projectID == "global" {
            return .global
        }

        guard let snapshot = projectStatusSnapshot else {
            guard activeSelection.surfaceID == MockSurfaceReference.projectConversation.surfaceID,
                  let localProject = localProject(forProjectID: activeSelection.projectID) else {
                return .unavailable
            }

            return .project(repositoryId: localProject.id)
        }

        if activeSelection.projectID == "project:\(snapshot.repositoryId)",
           activeSelection.surfaceID == MockSurfaceReference.projectConversation.surfaceID {
            return .project(repositoryId: snapshot.repositoryId)
        }

        if activeSelection.surfaceID == MockSurfaceReference.projectConversation.surfaceID,
           let localProject = localProject(forProjectID: activeSelection.projectID) {
            return .project(repositoryId: localProject.id)
        }

        return .unavailable
    }

    func handleComposerIntent(_ intent: ComposerIntent) {
        switch intent {
        case .send(let text, let configuration, let contexts):
            handleComposerSend(
                text: text,
                configuration: configuration,
                contexts: contexts
            )
        default:
            break
        }
    }

    func handleProjectSectionHeaderAction(_ action: ProjectSectionHeaderActionViewData) {
        switch action.kind {
        case .createFolder:
            guard let folderURL = projectFolderSelection.createNewFolder() else {
                return
            }

            registerLocalProject(folderURL: folderURL, source: .newFolder)
        case .useExistingFolder:
            guard let folderURL = projectFolderSelection.chooseExistingFolder() else {
                return
            }

            registerLocalProject(folderURL: folderURL, source: .existingFolder)
        }
    }

    func registerLocalProject(folderURL: URL, source: LocalProjectRegistrationSource) {
        if let snapshot = projectStatusSnapshot,
           LocalProjectRegistration.make(folderURL: folderURL, source: source)
            .hasSameRootPath(as: snapshot.repositoryRootPath) {
            sidebarSelectionState = .projectSecretary(snapshot: snapshot)
            lastErrorMessage = nil
            syncSidebarProjection()
            return
        }

        let project = localProjectRegistry.registerProject(folderURL: folderURL, source: source)
        localProjects = localProjectRegistry.listProjects()
        sidebarSelectionState = .projectSecretary(project: project)
        lastErrorMessage = nil
        syncSidebarProjection()
        openLocalProject(project)
    }

    func removeLocalProject(id: String) {
        guard localProjectRegistry.removeProject(id: id) else {
            return
        }

        localProjects = localProjectRegistry.listProjects()
        localConversationDrafts[id] = nil
        registeredRepositoryIDsByLocalProjectID[id] = nil
        localProjectOpenTasksByID.removeValue(forKey: id)?.task.cancel()
        if sidebarSelectionState?.activeSelection.projectID == "project:\(id)" {
            if let snapshot = projectStatusSnapshot {
                sidebarSelectionState = .projectSecretary(snapshot: snapshot)
            } else if let firstLocalProject = localProjects.first {
                sidebarSelectionState = .projectSecretary(project: firstLocalProject)
            } else {
                sidebarSelectionState = .unloaded()
            }
        }
        lastErrorMessage = nil
        syncSidebarProjection()
    }

    private func syncSidebarProjection() {
        sidebarProjection = ClientSidebarProjection(
            snapshot: projectStatusSnapshot,
            localProjects: localProjects,
            selectionState: sidebarSelectionState
        )
        syncShellState()
    }

    private func syncShellState() {
        var state = ClientMockState.ateliaReference
        let activeSelection = sidebarProjection.activeSelection

        state.activeSelection = activeSelection
        state.activeConversationTitle = sidebarProjection.activeConversationTitle
        state.activeProjectTitle = sidebarProjection.activeProjectTitle
        state.conversation = shellConversation(for: activeSelection, title: sidebarProjection.activeConversationTitle)
        state.goal = shellGoal(for: activeSelection)
        state.composer = shellComposer(for: activeSelection)

        shellState = state
    }

    private func shellComposer(for activeSelection: ClientMockActiveSelection) -> ComposerConfiguration {
        var composer = ClientMockState.ateliaReference.composer
        switch activeSelection.surfaceID {
        case MockSurfaceReference.projectConversation.surfaceID:
            composer.routeKey = "composer:\(activeSelection.surfaceID):follow-up"
        default:
            composer.routeKey = "composer:\(activeSelection.surfaceID)"
            composer.contextReferences = []
            composer.attachmentPreview = nil
        }
        return composer
    }

    private func shellGoal(for activeSelection: ClientMockActiveSelection) -> GoalStatus {
        if activeSelection.surfaceID == MockSurfaceReference.globalSecretary.surfaceID {
            return GoalStatus(
                title: "Global Secretary に接続",
                elapsed: ClientMockState.ateliaReference.goal.elapsed
            )
        }

        return ClientMockState.ateliaReference.goal
    }

    private func shellConversation(
        for activeSelection: ClientMockActiveSelection,
        title: String
    ) -> ClientConversationFixture {
        var conversation = ClientMockState.ateliaReference.conversation
        conversation.title = title

        guard activeSelection.surfaceID == MockSurfaceReference.projectConversation.surfaceID,
              let repositoryId = repositoryId(forProjectID: activeSelection.projectID),
              let drafts = localConversationDrafts[repositoryId] else {
            return conversation
        }

        conversation.turns.append(contentsOf: drafts)
        return conversation
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
                projectSnapshot: projectSnapshotForProjectCommand(),
                localProject: localProjectForProjectCommand(),
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

        if let localProject = localProject(forProjectID: projectID) {
            return localProject.displayName
        }

        return projectStatusSnapshot?.repositoryDisplayName ?? "プロジェクト未読込"
    }

    private func fallbackScope(for surface: MockSurfaceReference) -> (projectID: String, projectTitle: String) {
        if surface == MockSurfaceReference.projectConversation || surface == MockSurfaceReference.projectHome {
            if let localProject = selectedLocalProject() {
                return (
                    projectID: localProject.projectID,
                    projectTitle: localProject.displayName
                )
            }

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

    private func handleComposerSend(
        text: String,
        configuration: ComposerConfiguration,
        contexts: [ComposerContextSelection]
    ) {
        lastComposerSubmissionRequest = nil
        lastAteliaSubmitJobRequest = nil
        lastErrorMessage = nil

        guard let request = makeComposerJobSubmissionRequest(
            text: text,
            configuration: configuration,
            contexts: contexts,
            target: activeConversationTarget()
        ) else {
            return
        }

        lastComposerSubmissionRequest = request
        appendLocalComposerDraft(request)
        syncShellState()
        composerSubmissionSequence += 1
        submitComposerRequest(
            request,
            generation: projectTopologyGeneration,
            sequence: composerSubmissionSequence
        )
    }

    private func makeComposerJobSubmissionRequest(
        text: String,
        configuration: ComposerConfiguration,
        contexts: [ComposerContextSelection],
        target: ComposerConversationTarget
    ) -> ComposerJobSubmissionRequest? {
        guard case .project(let repositoryId) = target else {
            lastErrorMessage = "プロジェクトを選択してください。"
            return nil
        }

        guard let request = ComposerJobSubmissionRequest.fromSendIntent(
            text: text,
            repositoryId: repositoryId,
            configuration: configuration,
            contexts: contexts,
            repositoryRootPath: repositoryRootPath(for: repositoryId)
        ) else {
            return nil
        }

        return request
    }

    private func repositoryRootPath(for repositoryId: String) -> String? {
        if let localProject = localProjects.first(where: { $0.id == repositoryId }) {
            return localProject.rootPath
        }

        if let snapshot = projectStatusSnapshot, snapshot.repositoryId == repositoryId {
            return snapshot.repositoryRootPath
        }

        return nil
    }

    private func appendLocalComposerDraft(_ request: ComposerJobSubmissionRequest) {
        let draftIndex = (localConversationDrafts[request.repositoryId]?.count ?? 0) / 2 + 1
        let draftID = "local-draft:\(request.repositoryId):\(draftIndex)"
        var turns = localConversationDrafts[request.repositoryId] ?? []

        turns.append(
            ClientConversationTurnFixture(
                id: "turn.user.\(draftID)",
                actor: .user,
                blocks: [
                    .message(
                        ChatMessage(
                            id: "message.user.\(draftID)",
                            text: request.message,
                            attachmentName: request.contextIDs.first
                        )
                    )
                ]
            )
        )
        turns.append(
            ClientConversationTurnFixture(
                id: "turn.secretary.\(draftID)",
                actor: .secretary,
                blocks: [
                    .activity(
                        ClientConversationActivityFixture(
                            id: "activity.secretary.\(draftID)",
                            duration: "draft",
                            status: "下書き",
                            title: "Secretary ジョブ下書きをローカルに追加しました。",
                            bullets: localDraftBullets(for: request)
                        )
                    )
                ]
            )
        )

        localConversationDrafts[request.repositoryId] = turns
    }

    private func migrateLocalConversationDrafts(matchingRootPath rootPath: String, to repositoryId: String) {
        for localProject in localProjects where localProject.hasSameRootPath(as: rootPath) {
            migrateLocalConversationDrafts(from: localProject.id, to: repositoryId)
        }
    }

    private func migrateLocalConversationDrafts(from localRepositoryId: String, to repositoryId: String) {
        guard localRepositoryId != repositoryId,
              let localDrafts = localConversationDrafts.removeValue(forKey: localRepositoryId),
              !localDrafts.isEmpty else {
            return
        }

        var repositoryDrafts = localConversationDrafts[repositoryId] ?? []
        repositoryDrafts.append(contentsOf: localDrafts)
        localConversationDrafts[repositoryId] = repositoryDrafts
    }

    private func openLocalProject(_ project: LocalProjectRegistration) {
        guard let openTask = localProjectOpenTask(for: project, generation: projectTopologyGeneration) else {
            return
        }

        let generation = projectTopologyGeneration
        Task { [weak self] in
            do {
                let repository = try await openTask.task.value
                await MainActor.run {
                    guard let self,
                          generation == self.projectTopologyGeneration,
                          self.hasLocalProject(id: project.id) else {
                        return
                    }
                    self.registeredRepositoryIDsByLocalProjectID[project.id] = repository.repositoryId
                    if self.localProjectOpenTasksByID[project.id] === openTask {
                        self.localProjectOpenTasksByID[project.id] = nil
                    }
                }
            } catch {
                await MainActor.run {
                    if let self, self.localProjectOpenTasksByID[project.id] === openTask {
                        self.localProjectOpenTasksByID[project.id] = nil
                    }
                    guard let self,
                          generation == self.projectTopologyGeneration,
                          self.hasLocalProject(id: project.id) else {
                        return
                    }
                    self.lastErrorMessage = error.localizedDescription
                }
            }
        }
    }

    private func submitComposerRequest(
        _ request: ComposerJobSubmissionRequest,
        generation: UInt64,
        sequence: UInt64
    ) {
        guard projectLifecycleStore != nil else {
            return
        }

        Task { [weak self] in
            await self?.submitComposerRequestToLifecycleStore(
                request,
                generation: generation,
                sequence: sequence
            )
        }
    }

    private func submitComposerRequestToLifecycleStore(
        _ request: ComposerJobSubmissionRequest,
        generation: UInt64,
        sequence: UInt64
    ) async {
        guard let projectLifecycleStore else {
            return
        }

        do {
            if LocalProjectRegistration.isLocalProjectID(request.repositoryId),
               !hasLocalProject(id: request.repositoryId) {
                return
            }
            guard generation == projectTopologyGeneration else {
                return
            }
            let repositoryId = try await lifecycleRepositoryID(for: request.repositoryId, generation: generation)
            guard generation == projectTopologyGeneration else {
                return
            }
            let ateliaRequest = request.ateliaSubmitJobRequest(repositoryId: repositoryId)
            _ = try await projectLifecycleStore.submit(request: ateliaRequest)
            guard sequence == composerSubmissionSequence else {
                return
            }
            if LocalProjectRegistration.isLocalProjectID(request.repositoryId),
               !hasLocalProject(id: request.repositoryId) {
                return
            }
            lastAteliaSubmitJobRequest = ateliaRequest
        } catch {
            guard sequence == composerSubmissionSequence else {
                return
            }
            if LocalProjectRegistration.isLocalProjectID(request.repositoryId),
               !hasLocalProject(id: request.repositoryId) {
                return
            }
            lastErrorMessage = error.localizedDescription
        }
    }

    private func lifecycleRepositoryID(for repositoryId: String, generation: UInt64) async throws -> String {
        guard generation == projectTopologyGeneration else {
            throw ClientAppModelLifecycleError.staleLocalProject
        }

        if let localProject = localProjects.first(where: { $0.id == repositoryId }) {
            if let registeredRepositoryID = registeredRepositoryIDsByLocalProjectID[localProject.id] {
                return registeredRepositoryID
            }

            let repository = try await openLocalProjectIfNeeded(localProject, generation: generation)
            return repository.repositoryId
        }

        if LocalProjectRegistration.isLocalProjectID(repositoryId) {
            throw ClientAppModelLifecycleError.staleLocalProject
        }

        return repositoryId
    }

    @discardableResult
    private func openLocalProjectIfNeeded(
        _ project: LocalProjectRegistration,
        generation: UInt64
    ) async throws -> AteliaRepository {
        if let registeredRepositoryID = registeredRepositoryIDsByLocalProjectID[project.id] {
            return AteliaRepository(
                repositoryId: registeredRepositoryID,
                displayName: project.displayName,
                rootPath: project.rootPath,
                allowedScope: AteliaPathScope(kind: .repository),
                trustState: .unspecified,
                createdAtUnixMilliseconds: 0,
                updatedAtUnixMilliseconds: 0
            )
        }

        guard let openTask = localProjectOpenTask(for: project, generation: generation) else {
            throw ClientAppModelLifecycleError.staleLocalProject
        }
        defer {
            if localProjectOpenTasksByID[project.id] === openTask {
                localProjectOpenTasksByID[project.id] = nil
            }
        }

        let repository = try await openTask.task.value
        if generation == projectTopologyGeneration, hasLocalProject(id: project.id) {
            registeredRepositoryIDsByLocalProjectID[project.id] = repository.repositoryId
        }
        return repository
    }

    private func localProjectOpenTask(
        for project: LocalProjectRegistration,
        generation: UInt64
    ) -> LocalProjectOpenTask? {
        guard generation == projectTopologyGeneration,
              hasLocalProject(id: project.id),
              let projectLifecycleStore else {
            return nil
        }

        if let existingOpenTask = localProjectOpenTasksByID[project.id] {
            return existingOpenTask
        }

        let request = AteliaRegisterRepositoryRequest(
            displayName: project.displayName,
            rootPath: project.rootPath,
            allowedScope: AteliaPathScope(kind: .repository),
            requester: ClientLifecycleRequestIdentity.requester
        )
        let openTask = LocalProjectOpenTask(task: Task {
            try Task.checkCancellation()
            return try await projectLifecycleStore.open(request: request)
        })
        localProjectOpenTasksByID[project.id] = openTask
        return openTask
    }

    private func hasLocalProject(id: String) -> Bool {
        localProjects.contains { $0.id == id }
    }

    private func cancelLocalProjectOpenTasks() {
        let tasks = localProjectOpenTasksByID.values
        localProjectOpenTasksByID = [:]
        for openTask in tasks {
            openTask.task.cancel()
        }
    }

    private func localDraftBullets(for request: ComposerJobSubmissionRequest) -> [String] {
        var bullets = [
            "Goal は未指定のまま会話メッセージとして保持",
            "Backend 送信前の request contract を保持"
        ]

        if !request.contextIDs.isEmpty {
            let contextLabel = request.contextIDs.joined(separator: ", ")
            bullets.append("Context \(contextLabel)")
        }

        return bullets
    }

    private func selectedLocalProject() -> LocalProjectRegistration? {
        let projectID = sidebarSelectionState?.activeSelection.projectID ?? sidebarProjection.activeSelection.projectID
        return localProject(forProjectID: projectID)
    }

    private func localProjectForProjectCommand() -> LocalProjectRegistration? {
        selectedLocalProject() ?? (projectStatusSnapshot == nil ? localProjects.first : nil)
    }

    private func projectSnapshotForProjectCommand() -> MacProjectStatusSnapshot? {
        guard selectedLocalProject() == nil else {
            return nil
        }

        return projectStatusSnapshot
    }

    private func localProject(forProjectID projectID: String) -> LocalProjectRegistration? {
        localProjects.first { $0.projectID == projectID }
    }

    private func repositoryId(forProjectID projectID: String) -> String? {
        if let snapshot = projectStatusSnapshot, projectID == "project:\(snapshot.repositoryId)" {
            return snapshot.repositoryId
        }

        return localProject(forProjectID: projectID)?.id
    }
}

private final class LocalProjectOpenTask {
    let task: Task<AteliaRepository, any Error>

    init(task: Task<AteliaRepository, any Error>) {
        self.task = task
    }
}

private enum ClientAppModelLifecycleError: LocalizedError {
    case lifecycleStoreUnavailable
    case staleLocalProject

    var errorDescription: String? {
        switch self {
        case .lifecycleStoreUnavailable:
            return "Project lifecycle store is unavailable."
        case .staleLocalProject:
            return "Local project is no longer available."
        }
    }
}
