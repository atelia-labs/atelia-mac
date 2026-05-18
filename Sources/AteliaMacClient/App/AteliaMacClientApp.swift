import AteliaKit
import AteliaMacClientModels
import AteliaMacCore
import SwiftUI

@main
struct AteliaMacClientApp: App {
    @State private var appModel: ClientAppModel

    init() {
        ClientFontRegistrar.registerBundledFonts()
        let client = HTTPAteliaClient()
        let session = AteliaSession()
        _appModel = State(initialValue: ClientAppModel(
            projectStatusStore: Self.projectStatusStore(client: client, session: session),
            projectLifecycleStore: Self.projectLifecycleStore(client: client, session: session),
            localProjectRegistry: UserDefaultsLocalProjectRegistry()
        ))
    }

    var body: some Scene {
        WindowGroup {
            ClientShellView(
                state: appModel.shellState,
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

    private static func projectStatusStore(client: HTTPAteliaClient, session: AteliaSession) -> MacProjectStatusStore {
        MacProjectStatusStore(
            client: client,
            session: session,
            repositoryId: runtimeRepositoryID()
        )
    }

    private static func projectLifecycleStore(client: HTTPAteliaClient, session: AteliaSession) -> MacProjectLifecycleStore {
        MacProjectLifecycleStore(client: client, session: session)
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
            appModel.openGlobalSettings()
        case .sidebar(let sidebarAction):
            appModel.handleSidebarAction(sidebarAction)
        case .composer(let composerIntent):
            appModel.handleComposerIntent(composerIntent)
        }
    }
}
