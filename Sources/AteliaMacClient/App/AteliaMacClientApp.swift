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
            appModel.handleSidebarAction(sidebarAction)
        case .composer(let composerIntent):
            appModel.handleComposerIntent(composerIntent)
        }
    }
}
