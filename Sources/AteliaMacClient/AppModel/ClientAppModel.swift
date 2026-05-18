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
    private let toolOutputRenderStore: (any MacToolOutputRendering)?
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
    private var localProjectGenerationsByID: [String: UInt64]
    private var localProjectGenerationCounter: UInt64
    private var composerSubmissionSequence: UInt64
    private var localProjectOpenTasksByID: [String: LocalProjectOpenTask]
    private var projectTopologyGeneration: UInt64

    init(
        projectStatusStore: MacProjectStatusStore,
        projectLifecycleStore: (any MacProjectLifecycleStoring)? = nil,
        toolOutputRenderStore: (any MacToolOutputRendering)? = nil,
        projectFolderSelection: any ProjectFolderSelectionProviding = ProjectFolderPicker(),
        localProjectRegistry: any LocalProjectRegistry = InMemoryLocalProjectRegistry()
    ) {
        self.projectStatusStore = projectStatusStore
        self.projectLifecycleStore = projectLifecycleStore
        self.toolOutputRenderStore = toolOutputRenderStore
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
        self.localProjectGenerationsByID = Dictionary(uniqueKeysWithValues: loadedLocalProjects.enumerated().map { index, project in
            (project.id, UInt64(index + 1))
        })
        self.localProjectGenerationCounter = UInt64(loadedLocalProjects.count)
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
        localProjectGenerationCounter += 1
        localProjectGenerationsByID = [:]
        composerSubmissionSequence += 1
        syncSidebarProjection()
        lastErrorMessage = nil
    }

    func syncProjectStatusFromStore() async {
        let snapshot = await projectStatusStore.snapshot
        projectStatusSnapshot = snapshot
        if let snapshot {
            func upgradedProjectSelection(from selectionState: ClientSidebarSelectionState) -> ClientSidebarSelectionState {
                if selectionState.activePrimaryCommandID == "primary:new-thread" {
                    return .newThread(
                        commandID: "primary:new-thread",
                        title: selectionState.activeConversationTitle,
                        projectSnapshot: snapshot,
                        surface: MockSurfaceReference.projectConversation
                    )
                }

                return .projectSecretary(snapshot: snapshot)
            }

            migrateLocalConversationDrafts(
                matchingRootPath: snapshot.repositoryRootPath,
                to: snapshot.repositoryId
            )

            if let selectionState = sidebarSelectionState,
               let selectedLocalProject = localProject(forProjectID: selectionState.activeSelection.projectID),
               selectedLocalProject.hasSameRootPath(as: snapshot.repositoryRootPath) {
                sidebarSelectionState = upgradedProjectSelection(from: selectionState)
            } else if let selectionState = sidebarSelectionState, selectionState.isUnloaded {
                sidebarSelectionState = upgradedProjectSelection(from: selectionState)
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

    func openGlobalSettings() {
        sidebarSelectionState = .globalSettings(title: "設定")
        syncSidebarProjection()
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
        localProjectGenerationCounter += 1
        localProjectGenerationsByID[project.id] = localProjectGenerationCounter
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
        localProjectGenerationCounter += 1
        localProjectGenerationsByID[id] = localProjectGenerationCounter
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
        let draftID = appendLocalComposerDraft(request)
        syncShellState()
        composerSubmissionSequence += 1
        submitComposerRequest(
            request,
            draftID: draftID,
            localProjectGeneration: localProjectGeneration(for: request.repositoryId),
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

    private func appendLocalComposerDraft(_ request: ComposerJobSubmissionRequest) -> String {
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
                            attachmentName: request.contextDisplayNames.first
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
        return draftID
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
            } catch is CancellationError {
                await MainActor.run {
                    if let self, self.localProjectOpenTasksByID[project.id] === openTask {
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
        draftID: String,
        localProjectGeneration: UInt64?,
        generation: UInt64,
        sequence: UInt64
    ) {
        guard projectLifecycleStore != nil else {
            return
        }

        if LocalProjectRegistration.isLocalProjectID(request.repositoryId),
           !hasLocalProject(id: request.repositoryId) {
            return
        }

        Task { [weak self] in
            await self?.submitComposerRequestToLifecycleStore(
                request,
                draftID: draftID,
                localProjectGeneration: localProjectGeneration,
                generation: generation,
                sequence: sequence
            )
        }
    }

    private func submitComposerRequestToLifecycleStore(
        _ request: ComposerJobSubmissionRequest,
        draftID: String,
        localProjectGeneration: UInt64?,
        generation: UInt64,
        sequence: UInt64
    ) async {
        guard let projectLifecycleStore else {
            return
        }

        do {
            if !hasCurrentLocalProjectGeneration(request.repositoryId, generation: localProjectGeneration) {
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
            let job = try await projectLifecycleStore.submit(request: ateliaRequest)
            guard generation == projectTopologyGeneration else {
                return
            }
            if !hasCurrentLocalProjectGeneration(request.repositoryId, generation: localProjectGeneration) {
                return
            }
            if sequence == composerSubmissionSequence {
                lastAteliaSubmitJobRequest = ateliaRequest
            }
            updateLocalComposerDraft(
                request,
                draftID: draftID,
                job: job,
                events: [],
                renderedOutputs: []
            )
            let events: [AteliaEvent]
            let renderedOutputs: [ClientRenderedToolOutput]
            do {
                events = try await projectLifecycleStore.listJobEvents(
                    jobId: job.jobId,
                    request: .init(repositoryId: job.repositoryId)
                )
            } catch {
                guard generation == projectTopologyGeneration else {
                    return
                }
                if !hasCurrentLocalProjectGeneration(request.repositoryId, generation: localProjectGeneration) {
                    return
                }
                if sequence == composerSubmissionSequence {
                    lastErrorMessage = error.localizedDescription
                }
                markLocalComposerDraftObservationFailed(request, draftID: draftID, job: job, error: error)
                return
            }
            guard generation == projectTopologyGeneration else {
                return
            }
            if !hasCurrentLocalProjectGeneration(request.repositoryId, generation: localProjectGeneration) {
                return
            }
            renderedOutputs = await renderedToolOutputs(from: events)
            guard generation == projectTopologyGeneration else {
                return
            }
            if !hasCurrentLocalProjectGeneration(request.repositoryId, generation: localProjectGeneration) {
                return
            }
            updateLocalComposerDraft(
                request,
                draftID: draftID,
                job: job,
                events: events,
                renderedOutputs: renderedOutputs
            )
        } catch {
            guard generation == projectTopologyGeneration else {
                return
            }
            if !hasCurrentLocalProjectGeneration(request.repositoryId, generation: localProjectGeneration) {
                return
            }
            markLocalComposerDraftFailed(request, draftID: draftID, error: error)
            if sequence == composerSubmissionSequence {
                lastErrorMessage = error.localizedDescription
            }
        }
    }

    private func renderedToolOutputs(from events: [AteliaEvent]) async -> [ClientRenderedToolOutput] {
        guard let toolOutputRenderStore else {
            return []
        }

        var renderedOutputs: [ClientRenderedToolOutput] = []
        for event in events {
            guard let toolResult = AteliaToolResultRef(event: event) else {
                continue
            }

            do {
                let response = try await toolOutputRenderStore.render(
                    request: AteliaToolOutputRenderRequest(toolResult: toolResult, format: .text)
                )
                renderedOutputs.append(ClientRenderedToolOutput(event: event, response: response, error: nil))
            } catch {
                renderedOutputs.append(ClientRenderedToolOutput(event: event, response: nil, error: error.localizedDescription))
            }
        }
        return renderedOutputs
    }

    private func updateLocalComposerDraft(
        _ request: ComposerJobSubmissionRequest,
        draftID: String,
        job: AteliaJob,
        events: [AteliaEvent],
        renderedOutputs: [ClientRenderedToolOutput]
    ) {
        guard let storageKey = localConversationDraftStorageKey(for: request, draftID: draftID),
              var turns = localConversationDrafts[storageKey],
              let turnIndex = turns.firstIndex(where: { $0.id == "turn.secretary.\(draftID)" }) else {
            return
        }

        var blocks: [ClientConversationBlockFixture] = [
            .activity(
                ClientConversationActivityFixture(
                    id: "activity.secretary.\(draftID)",
                    duration: "job \(job.jobId)",
                    status: job.status.conversationStatusLabel,
                    title: job.status.conversationTitle,
                    bullets: jobConversationBullets(for: request, job: job, events: events)
                )
            )
        ]
        blocks.append(contentsOf: renderedOutputs.map { renderedOutputBlock(for: $0, request: request) })
        turns[turnIndex] = ClientConversationTurnFixture(
            id: "turn.secretary.\(draftID)",
            actor: .secretary,
            blocks: blocks
        )
        localConversationDrafts[storageKey] = turns
        syncShellState()
    }

    private func markLocalComposerDraftObservationFailed(
        _ request: ComposerJobSubmissionRequest,
        draftID: String,
        job: AteliaJob,
        error: any Error
    ) {
        guard let storageKey = localConversationDraftStorageKey(for: request, draftID: draftID),
              var turns = localConversationDrafts[storageKey],
              let turnIndex = turns.firstIndex(where: { $0.id == "turn.secretary.\(draftID)" }) else {
            return
        }

        turns[turnIndex] = ClientConversationTurnFixture(
            id: "turn.secretary.\(draftID)",
            actor: .secretary,
            blocks: [
                .activity(
                    ClientConversationActivityFixture(
                        id: "activity.secretary.\(draftID)",
                        duration: "job \(job.jobId)",
                        status: "結果取得失敗",
                        title: "Secretary ジョブは送信されましたが、結果を取得できませんでした。",
                        bullets: [
                            "Job \(job.jobId)",
                            error.localizedDescription
                        ]
                    )
                )
            ]
        )
        localConversationDrafts[storageKey] = turns
        syncShellState()
    }

    private func markLocalComposerDraftFailed(
        _ request: ComposerJobSubmissionRequest,
        draftID: String,
        error: any Error
    ) {
        guard let storageKey = localConversationDraftStorageKey(for: request, draftID: draftID),
              var turns = localConversationDrafts[storageKey],
              let turnIndex = turns.firstIndex(where: { $0.id == "turn.secretary.\(draftID)" }) else {
            return
        }

        turns[turnIndex] = ClientConversationTurnFixture(
            id: "turn.secretary.\(draftID)",
            actor: .secretary,
            blocks: [
                .activity(
                    ClientConversationActivityFixture(
                        id: "activity.secretary.\(draftID)",
                        duration: "error",
                        status: "失敗",
                        title: "Secretary ジョブの送信に失敗しました。",
                        bullets: [error.localizedDescription]
                    )
                )
            ]
        )
        localConversationDrafts[storageKey] = turns
        syncShellState()
    }

    private func localConversationDraftStorageKey(
        for request: ComposerJobSubmissionRequest,
        draftID: String
    ) -> String? {
        let secretaryTurnID = "turn.secretary.\(draftID)"
        if localConversationDrafts[request.repositoryId]?.contains(where: { $0.id == secretaryTurnID }) == true {
            return request.repositoryId
        }

        return localConversationDrafts.first { _, turns in
            turns.contains { $0.id == secretaryTurnID }
        }?.key
    }

    private func jobConversationBullets(
        for request: ComposerJobSubmissionRequest,
        job: AteliaJob,
        events: [AteliaEvent]
    ) -> [String] {
        var bullets = [
            "Job \(job.jobId)",
            "Capability \(request.primaryCapabilityLabel)"
        ]
        if let latestEventId = job.latestEventId {
            bullets.append("Latest event \(latestEventId)")
        }
        if let resultEvent = events.first(where: { $0.refs.toolResultId != nil }) {
            bullets.append("Tool result \(resultEvent.refs.toolResultId ?? "")")
        }
        return bullets
    }

    private func renderedOutputBlock(
        for renderedOutput: ClientRenderedToolOutput,
        request: ComposerJobSubmissionRequest
    ) -> ClientConversationBlockFixture {
        let toolResultId = renderedOutput.event.refs.toolResultId ?? renderedOutput.event.eventId
        let status: ClientConversationToolOutputFixture.Status = renderedOutput.error != nil || renderedOutput.event.severity == .error ? .failed : .succeeded
        let output: [String]
        if let response = renderedOutput.response {
            output = response.renderedOutput
                .split(whereSeparator: \.isNewline)
                .map(String.init)
        } else {
            output = [renderedOutput.error ?? "Tool output rendering failed."]
        }
        return .toolOutput(
            ClientConversationToolOutputFixture(
                id: "tool-output.\(toolResultId)",
                toolName: request.primaryCapabilityLabel,
                command: request.message,
                status: status,
                output: output.isEmpty ? ["No output."] : output
            )
        )
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

    private func localProjectGeneration(for repositoryId: String) -> UInt64? {
        guard LocalProjectRegistration.isLocalProjectID(repositoryId) else {
            return nil
        }
        return localProjectGenerationsByID[repositoryId]
    }

    private func hasCurrentLocalProjectGeneration(_ repositoryId: String, generation: UInt64?) -> Bool {
        guard LocalProjectRegistration.isLocalProjectID(repositoryId) else {
            return true
        }
        guard let generation else {
            return false
        }
        return hasLocalProject(id: repositoryId) && localProjectGenerationsByID[repositoryId] == generation
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
            let contextLabel = request.contextDisplayNames.joined(separator: ", ")
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

private struct ClientRenderedToolOutput {
    var event: AteliaEvent
    var response: AteliaToolOutputRenderResponse?
    var error: String?
}

private extension ComposerJobSubmissionRequest {
    var primaryCapabilityLabel: String {
        ateliaSubmitJobRequest().requestedCapabilities?.first ?? "message"
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

private extension AteliaJob.Status {
    var conversationStatusLabel: String {
        switch self {
        case .queued:
            return "queued"
        case .running:
            return "running"
        case .succeeded:
            return "succeeded"
        case .failed:
            return "failed"
        case .blocked:
            return "blocked"
        case .canceled:
            return "canceled"
        case .unknown:
            return "unknown"
        case .unrecognized(let rawValue):
            return rawValue
        }
    }

    var conversationTitle: String {
        switch self {
        case .queued:
            return "Secretary ジョブをキューに追加しました。"
        case .running:
            return "Secretary ジョブを実行しています。"
        case .succeeded:
            return "Secretary ジョブが完了しました。"
        case .failed:
            return "Secretary ジョブが失敗しました。"
        case .blocked:
            return "Secretary ジョブがポリシーで停止しました。"
        case .canceled:
            return "Secretary ジョブがキャンセルされました。"
        case .unknown, .unrecognized:
            return "Secretary ジョブの状態を確認しました。"
        }
    }
}
