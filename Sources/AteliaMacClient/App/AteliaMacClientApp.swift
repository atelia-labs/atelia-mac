import AteliaKit
import AteliaMacClientModels
import AteliaMacCore
import SwiftUI

@main
struct AteliaMacClientApp: App {
    @State private var appModel: ClientAppModel

    init() {
        ClientFontRegistrar.registerBundledFonts()
        _appModel = State(initialValue: ClientAppModel(projectStatusStore: Self.projectStatusStore()))
    }

    var body: some Scene {
        WindowGroup {
            ClientShellView(
                state: .ateliaReference,
                sidebarProjection: appModel.sidebarProjection,
                onAction: handleClientShellAction
            )
                .frame(minWidth: AteliaClientLayout.minimumWindowWidth, minHeight: 640)
                .preferredColorScheme(AteliaClientDesign.supportsLightColorSchemeOnly ? .light : nil)
                .task {
                    try? await appModel.reloadProjectStatus()
                }
        }
        .windowStyle(.hiddenTitleBar)
    }

    private static func projectStatusStore() -> MacProjectStatusStore {
        MacProjectStatusStore(
            client: HTTPAteliaClient(),
            session: AteliaSession(),
            repositoryId: runtimeRepositoryID()
        )
    }

    private static func runtimeRepositoryID() -> String {
        let environment = ProcessInfo.processInfo.environment
        if let repositoryID = environment["ATELIA_REPOSITORY_ID"], !repositoryID.isEmpty {
            return repositoryID
        }
        return URL(fileURLWithPath: FileManager.default.currentDirectoryPath).lastPathComponent
    }

    @MainActor
    private func handleClientShellAction(_ action: ClientShellAction) {
        switch action {
        case .openSettings:
            break
        case .sidebar(let sidebarAction):
            handleSidebarAction(sidebarAction)
        case .composer:
            break
        }
    }

    @MainActor
    private func handleSidebarAction(_ action: SidebarAction) {
        switch action {
        case .projectSectionHeaderAction(let headerAction):
            handleProjectSectionHeaderAction(headerAction)
        case .command, .chatItem:
            break
        }
    }

    @MainActor
    private func handleProjectSectionHeaderAction(_ action: ProjectSectionHeaderActionViewData) {
        switch action.kind {
        case .createFolder:
            // TODO(project-add): wire the new-project-folder creation flow once backend support exists.
            break
        case .useExistingFolder:
            guard let folderURL = ProjectFolderPicker.chooseExistingFolder() else {
                return
            }

            // TODO(project-add): hand the selected folder URL to real project registration state.
            print("TODO(project-add): selected existing folder at \(folderURL.path)")
        }
    }
}
