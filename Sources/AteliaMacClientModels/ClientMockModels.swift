import Foundation

public struct ClientMockState: Sendable {
    public var activeConversationTitle: String
    public var activeProjectTitle: String
    public var activeSelection: ClientMockActiveSelection
    public var conversation: ClientConversationFixture
    public var workspaceGroups: [WorkspaceGroup]
    public var recentChats: [ChatListItem]
    public var changeSummary: ChangeSummary
    public var messages: [ChatMessage]
    public var activity: ActivityBlock
    public var goal: GoalStatus
    public var composer: ComposerConfiguration

    public var activeNavigationItemID: String {
        navigationItems.first { activeSelection.matches($0) }?.id ?? ""
    }

    public var activeSurfaceID: String {
        "\(activeSelection.surfacePackageID)#\(activeSelection.surfaceID)"
    }

    public init(
        activeConversationTitle: String,
        activeProjectTitle: String,
        activeSelection: ClientMockActiveSelection,
        conversation: ClientConversationFixture? = nil,
        workspaceGroups: [WorkspaceGroup],
        recentChats: [ChatListItem],
        changeSummary: ChangeSummary,
        messages: [ChatMessage],
        activity: ActivityBlock,
        goal: GoalStatus,
        composer: ComposerConfiguration
    ) {
        self.activeConversationTitle = activeConversationTitle
        self.activeProjectTitle = activeProjectTitle
        self.activeSelection = activeSelection
        self.conversation = conversation ?? Self.synthesizedConversation(
            title: activeConversationTitle,
            messages: messages,
            activity: activity
        )
        self.workspaceGroups = workspaceGroups
        self.recentChats = recentChats
        self.changeSummary = changeSummary
        self.messages = messages
        self.activity = activity
        self.goal = goal
        self.composer = composer
    }

    private static func synthesizedConversation(
        title: String,
        messages: [ChatMessage],
        activity: ActivityBlock
    ) -> ClientConversationFixture {
        ClientConversationFixture(
            id: "conversation.mock.\(title)",
            title: title,
            turns: messages.map { message in
                ClientConversationTurnFixture(
                    id: "turn.\(message.id)",
                    actor: .user,
                    blocks: [.message(message)]
                )
            } + [
                ClientConversationTurnFixture(
                    id: "turn.activity.mock.\(title)",
                    actor: .secretary,
                    blocks: [
                        .activity(
                            ClientConversationActivityFixture(
                                id: "activity.mock.\(title)",
                                duration: activity.duration,
                                status: "完了",
                                title: activity.title,
                                bullets: activity.bullets
                            )
                        )
                    ]
                )
            ]
        )
    }

    public static let ateliaReference = ClientMockState(
        activeConversationTitle: "Secretary による package safety 更新",
        activeProjectTitle: "Mac Atelia",
        activeSelection: ClientMockActiveSelection(
            projectID: "project:mac-atelia",
            surfacePackageID: MockSurfaceReference.hostPackageID,
            surfaceID: "project-conversation",
            resourceID: "conversation:mac-atelia:secretary"
        ),
        conversation: .mdpRenderingReference,
        workspaceGroups: [
            WorkspaceGroup(
                id: "project:mac-atelia",
                title: "Mac Atelia",
                subtitle: nil,
                surface: .projectHome,
                items: [
                    ChatListItem(
                        id: "nav:mac-atelia:project-conversation",
                        projectID: "project:mac-atelia",
                        resourceID: "conversation:mac-atelia:secretary",
                        title: "Secretary",
                        trailing: nil,
                        leadingAffordance: .assistantConversation,
                        surface: .projectConversation,
                        action: .openProjectConversation
                    ),
                    ChatListItem(
                        id: "nav:mac-atelia:delegated-work",
                        projectID: "project:mac-atelia",
                        resourceID: "work:mac-atelia:delegated",
                        title: "委任中の作業",
                        trailing: "3",
                        leadingAffordance: .delegatedWork,
                        surface: .projectHome,
                        action: .inspectDelegatedWork
                    )
                ],
                settings: [
                    ChatListItem(
                        id: "nav:mac-atelia:package-management",
                        projectID: "project:mac-atelia",
                        resourceID: "packages:mac-atelia:installed",
                        title: "パッケージ",
                        trailing: nil,
                        leadingAffordance: .packageInstall,
                        surface: .packageManagement,
                        action: .inspectInstalledPackages
                    ),
                    ChatListItem(
                        id: "nav:mac-atelia:permission-recovery",
                        projectID: "project:mac-atelia",
                        resourceID: "permissions:mac-atelia:audit",
                        title: "権限と監査",
                        trailing: nil,
                        surface: .permissionRecovery,
                        action: .reviewPermissions
                    ),
                    ChatListItem(
                        id: "nav:mac-atelia:settings",
                        projectID: "project:mac-atelia",
                        resourceID: "settings:mac-atelia:project",
                        title: "プロジェクト設定",
                        trailing: nil,
                        surface: .settings,
                        action: .openProjectSettings
                    )
                ]
            ),
            WorkspaceGroup(
                id: "project:atelia-secretary",
                title: "atelia-secretary",
                subtitle: "Global Secretary",
                surface: .projectHome,
                items: [
                    ChatListItem(
                        id: "nav:atelia-secretary:project-conversation",
                        projectID: "project:atelia-secretary",
                        resourceID: "conversation:atelia-secretary:secretary",
                        title: "Secretary",
                        trailing: nil,
                        leadingAffordance: .assistantConversation,
                        surface: .projectConversation,
                        action: .openProjectConversation
                    ),
                    ChatListItem(
                        id: "nav:atelia-secretary:package-audit",
                        projectID: "project:atelia-secretary",
                        resourceID: "packages:atelia-secretary:audit",
                        title: "package audit",
                        trailing: "2",
                        surface: .packageManagement,
                        action: .inspectInstalledPackages
                    )
                ],
                status: .warning
            ),
            WorkspaceGroup(
                id: "packages:bundled-official",
                title: "公式パッケージ",
                subtitle: "bundled-official / enabled",
                surface: .packageManagement,
                items: [
                    ChatListItem(
                        id: "nav:official-automations:surface-home",
                        projectID: "project:mac-atelia",
                        resourceID: "package-surface:official-automations:home",
                        title: "Automations",
                        trailing: "2",
                        surface: .officialAutomations,
                        action: .openAutomationsPackage
                    ),
                    ChatListItem(
                        id: "nav:official-review:surface-home",
                        projectID: "project:mac-atelia",
                        resourceID: "package-surface:official-review:home",
                        title: "Review",
                        trailing: nil,
                        surface: .officialReview,
                        action: .openReviewPackage
                    )
                ]
            )
        ],
        recentChats: [
            ChatListItem(
                id: "recent:mac-atelia:project-conversation",
                projectID: "project:mac-atelia",
                resourceID: "conversation:mac-atelia:secretary",
                title: "Project conversation",
                trailing: nil,
                leadingAffordance: .assistantConversation,
                surface: .projectConversation,
                action: .openProjectConversation
            ),
            ChatListItem(
                id: "recent:mac-atelia:package-management",
                projectID: "project:mac-atelia",
                resourceID: "packages:mac-atelia:installed",
                title: "Package inspection",
                trailing: nil,
                surface: .packageManagement,
                action: .inspectInstalledPackages
            ),
            ChatListItem(
                id: "recent:official-automations:surface-home",
                projectID: "project:mac-atelia",
                resourceID: "package-surface:official-automations:home",
                title: "Automations package",
                trailing: nil,
                surface: .officialAutomations,
                action: .openAutomationsPackage
            ),
            ChatListItem(
                id: "recent:official-review:surface-home",
                projectID: "project:mac-atelia",
                resourceID: "package-surface:official-review:home",
                title: "Review package",
                trailing: nil,
                surface: .officialReview,
                action: .openReviewPackage
            )
        ],
        changeSummary: ChangeSummary(
            filePath: "atelia-secretary-package-audit/crates/ateliad/src/rpc.rs",
            additions: 68,
            deletions: 9,
            collapsedFileCount: 1
        ),
        messages: [
            ChatMessage(
                id: "message:surface-fixture-request",
                text: "おっけー\npackage safety review の mock 表示を、baseline surface と bundled-official package surface が分かれる形に直してほしい。\n将来の実データに置き換えられるように、surface id、package id、action metadata、stable id を持たせて。",
                attachmentName: "standard-surfaces.md"
            )
        ],
        activity: ActivityBlock(
            duration: "36s",
            title: "Client mock surface fixture を更新しました。",
            bullets: [
                "navigation item を stable mock id と surface provenance で識別",
                "`package-management` と `permission-recovery` を baseline surface として明示",
                "`official.automations` は bundled-official package surface として available lifecycle に分離"
            ],
            document: DocumentPreview(title: "standard-surfaces.md", subtitle: "ドキュメント・MD"),
            review: ReviewPreview(title: "2 件のファイルを編集", additions: 50, deletions: 47)
        ),
        goal: GoalStatus(
            title: "一時停止中の目標 Package-Driven Atelia MDP: dynamic Mac client",
            elapsed: "33h 39m 21s"
        ),
        composer: ComposerConfiguration(
            routeKey: "composer:project-conversation:follow-up",
            selectedModel: ComposerModelSelection(
                id: "model:atelia-balanced",
                routeKey: "models/atelia-balanced",
                displayName: "5.5 中"
            ),
            permissionMode: ComposerPermissionMode(
                id: "permission:full-access",
                routeKey: "permissions/full-access",
                permissionScope: "workspace.full-access",
                displayName: "フルアクセス"
            )
        )
    )

    private var navigationItems: [ChatListItem] {
        workspaceGroups.flatMap { $0.items + $0.settings } + recentChats
    }
}

public struct ClientMockActiveSelection: Hashable, Sendable {
    public var projectID: String
    public var surfacePackageID: String
    public var surfaceID: String
    public var resourceID: String

    public init(projectID: String, surfacePackageID: String, surfaceID: String, resourceID: String) {
        self.projectID = projectID
        self.surfacePackageID = surfacePackageID
        self.surfaceID = surfaceID
        self.resourceID = resourceID
    }

    public func matches(_ item: ChatListItem) -> Bool {
        projectID == item.projectID
            && surfacePackageID == item.surface.packageID
            && surfaceID == item.surface.surfaceID
            && resourceID == item.resourceID
    }
}

public struct ClientConversationFixture: Identifiable, Sendable {
    public var id: String
    public var title: String
    public var turns: [ClientConversationTurnFixture]

    public init(id: String, title: String, turns: [ClientConversationTurnFixture]) {
        self.id = id
        self.title = title
        self.turns = turns
    }
}

public struct ClientConversationTurnFixture: Identifiable, Sendable {
    public var id: String
    public var actor: ClientConversationActor
    public var blocks: [ClientConversationBlockFixture]

    public init(
        id: String,
        actor: ClientConversationActor,
        blocks: [ClientConversationBlockFixture]
    ) {
        self.id = id
        self.actor = actor
        self.blocks = blocks
    }
}

public enum ClientConversationActor: Sendable {
    case user
    case secretary
}

public enum ClientConversationBlockFixture: Identifiable, Sendable {
    case message(ChatMessage)
    case activity(ClientConversationActivityFixture)
    case toolOutput(ClientConversationToolOutputFixture)
    case changeSet(ClientConversationChangeSetFixture)

    public var id: String {
        switch self {
        case .message(let message):
            message.id
        case .activity(let activity):
            activity.id
        case .toolOutput(let toolOutput):
            toolOutput.id
        case .changeSet(let changeSet):
            changeSet.id
        }
    }
}

public struct ClientConversationActivityFixture: Identifiable, Sendable {
    public var id: String
    public var duration: String
    public var status: String
    public var title: String
    public var bullets: [String]

    public init(id: String, duration: String, status: String, title: String, bullets: [String]) {
        self.id = id
        self.duration = duration
        self.status = status
        self.title = title
        self.bullets = bullets
    }
}

public struct ClientConversationToolOutputFixture: Identifiable, Sendable {
    public enum Status: Sendable {
        case succeeded
        case failed
        case running
    }

    public var id: String
    public var toolName: String
    public var command: String
    public var status: Status
    public var output: [String]

    public init(
        id: String,
        toolName: String,
        command: String,
        status: Status,
        output: [String]
    ) {
        self.id = id
        self.toolName = toolName
        self.command = command
        self.status = status
        self.output = output
    }
}

public struct ClientConversationChangeSetFixture: Identifiable, Sendable {
    public var id: String
    public var title: String
    public var summary: String
    public var isExpandedByDefault: Bool
    public var files: [ClientConversationChangedFileFixture]

    public init(
        id: String,
        title: String,
        summary: String,
        isExpandedByDefault: Bool = false,
        files: [ClientConversationChangedFileFixture]
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.isExpandedByDefault = isExpandedByDefault
        self.files = files
    }
}

public struct ClientConversationChangedFileFixture: Identifiable, Sendable {
    public var id: String
    public var path: String
    public var additions: Int
    public var deletions: Int
    public var hunks: [ClientConversationDiffHunkFixture]

    public init(
        id: String,
        path: String,
        additions: Int,
        deletions: Int,
        hunks: [ClientConversationDiffHunkFixture]
    ) {
        self.id = id
        self.path = path
        self.additions = additions
        self.deletions = deletions
        self.hunks = hunks
    }
}

public struct ClientConversationDiffHunkFixture: Identifiable, Sendable {
    public var id: String
    public var header: String
    public var lines: [ClientConversationDiffLineFixture]

    public init(id: String, header: String, lines: [ClientConversationDiffLineFixture]) {
        self.id = id
        self.header = header
        self.lines = lines
    }
}

public struct ClientConversationDiffLineFixture: Identifiable, Sendable {
    public enum Kind: Sendable {
        case added
        case removed
        case context
    }

    public var id: String
    public var kind: Kind
    public var text: String

    public init(id: String, kind: Kind, text: String) {
        self.id = id
        self.kind = kind
        self.text = text
    }

    public static func added(id: String, _ text: String) -> ClientConversationDiffLineFixture {
        ClientConversationDiffLineFixture(id: id, kind: .added, text: text)
    }

    public static func removed(id: String, _ text: String) -> ClientConversationDiffLineFixture {
        ClientConversationDiffLineFixture(id: id, kind: .removed, text: text)
    }

    public static func context(id: String, _ text: String) -> ClientConversationDiffLineFixture {
        ClientConversationDiffLineFixture(id: id, kind: .context, text: text)
    }

    public static func rawUnifiedDiff(id: String, kind: Kind, text: String) -> ClientConversationDiffLineFixture {
        ClientConversationDiffLineFixture(id: id, kind: kind, text: normalizedText(text, kind: kind))
    }

    private static func normalizedText(_ text: String, marker: Character) -> String {
        guard text.first == marker else {
            return text
        }

        return String(text.dropFirst())
    }

    private static func normalizedText(_ text: String, kind: Kind) -> String {
        switch kind {
        case .added:
            normalizedText(text, marker: "+")
        case .removed:
            normalizedText(text, marker: "-")
        case .context:
            normalizedText(text, marker: " ")
        }
    }
}

public extension ClientConversationFixture {
    static let mdpRenderingReference = ClientConversationFixture(
        id: "conversation.mdp-rendering.reference",
        title: "Secretary による Package MDP 更新",
        turns: [
            ClientConversationTurnFixture(
                id: "turn.user.package-mdp-request",
                actor: .user,
                blocks: [
                    .message(
                        ChatMessage(
                            id: "message.user.package-mdp-request",
                            text: "Package MDP のレンダリングを Mac client 側で確認できるようにしたい。Secretary の実行、activity、tool output、change set、diff が会話上で意味を持って読める状態まで寄せて。",
                            attachmentName: "AGENTS.md"
                        )
                    )
                ]
            ),
            ClientConversationTurnFixture(
                id: "turn.secretary.audit",
                actor: .secretary,
                blocks: [
                    .activity(
                        ClientConversationActivityFixture(
                            id: "activity.secretary.audit",
                            duration: "36s",
                            status: "完了",
                            title: "Package MDP の差分表示を確認しました。",
                            bullets: [
                                "semantic renderer 用の deterministic conversation model を追加",
                                "Secretary activity と tool output を時系列で表示",
                                "change set は collapsed default、展開時に scrollable diff を表示"
                            ]
                        )
                    ),
                    .toolOutput(
                        ClientConversationToolOutputFixture(
                            id: "tool.output.swift-build",
                            toolName: "swift build",
                            command: "swift build --product AteliaMacClient",
                            status: .succeeded,
                            output: [
                                "Building for debugging...",
                                "Build complete! (semantic mock verified)"
                            ]
                        )
                    ),
                    .changeSet(
                        ClientConversationChangeSetFixture(
                            id: "change-set.conversation-mdp-rendering",
                            title: "Conversation MDP semantic mock",
                            summary: "Mac client conversation surface now renders Atelia-shaped activity, tool output, change set, and diff semantics.",
                            files: [
                                ClientConversationChangedFileFixture(
                                    id: "changed-file.models",
                                    path: "Sources/AteliaMacClient/Models/AteliaConversationModels.swift",
                                    additions: 156,
                                    deletions: 0,
                                    hunks: [
                                        ClientConversationDiffHunkFixture(
                                            id: "diff-hunk.models.schema",
                                            header: "@@ new semantic conversation schema @@",
                                            lines: [
                                                .added(id: "diff-line.models.schema.001", "struct AteliaConversation: Identifiable {"),
                                                .added(id: "diff-line.models.schema.002", "    var id: String"),
                                                .added(id: "diff-line.models.schema.003", "    var turns: [AteliaConversationTurn]"),
                                                .context(id: "diff-line.models.schema.004", "}")
                                            ]
                                        )
                                    ]
                                ),
                                ClientConversationChangedFileFixture(
                                    id: "changed-file.view",
                                    path: "Sources/AteliaMacClient/Views/ConversationView.swift",
                                    additions: 244,
                                    deletions: 0,
                                    hunks: [
                                        ClientConversationDiffHunkFixture(
                                            id: "diff-hunk.view.renderer",
                                            header: "@@ render activity, tool output, and change set @@",
                                            lines: [
                                                .added(id: "diff-line.view.renderer.001", "AteliaActivityView(activity: activity)"),
                                                .added(id: "diff-line.view.renderer.002", "AteliaToolOutputView(toolOutput: toolOutput)"),
                                                .added(id: "diff-line.view.renderer.003", "AteliaChangeSetView(changeSet: changeSet)"),
                                                .context(id: "diff-line.view.renderer.004", "ComposerView(goal: goal)")
                                            ]
                                        )
                                    ]
                                )
                            ]
                        )
                    )
                ]
            )
        ]
    )
}

public struct MockSurfaceReference: Hashable, Identifiable, Sendable {
    public var packageID: String
    public var surfaceID: String
    public var lifecycle: MockSurfaceLifecycle
    public var trust: MockSurfaceTrust
    public var criticality: MockSurfaceCriticality
    public var schemaVersion: String

    public var id: String {
        "\(packageID)#\(surfaceID)"
    }

    public static let hostPackageID = "host.bootstrap.macos"

    public init(
        packageID: String,
        surfaceID: String,
        lifecycle: MockSurfaceLifecycle,
        trust: MockSurfaceTrust,
        criticality: MockSurfaceCriticality,
        schemaVersion: String
    ) {
        self.packageID = packageID
        self.surfaceID = surfaceID
        self.lifecycle = lifecycle
        self.trust = trust
        self.criticality = criticality
        self.schemaVersion = schemaVersion
    }
}

public enum MockSurfaceLifecycle: String, Hashable, Sendable {
    case available
    case mounted
    case active
    case suspended
    case degraded
    case destroyed
}

public enum MockSurfaceTrust: String, Hashable, Sendable {
    case hostShippedBuiltIn = "host-shipped-built-in"
    case bundledOfficial = "bundled-official"
}

public enum MockSurfaceCriticality: String, Hashable, Sendable {
    case hostRequired = "host-required"
    case userRemovable = "user-removable"
    case optional
}

public enum MockRiskTier: String, Hashable, Sendable {
    case r0 = "R0"
    case r1 = "R1"
    case r2 = "R2"
    case r3 = "R3"
    case r4 = "R4"
}

public enum MockActionInvocation: Hashable, Sendable {
    case service(service: String, method: String)
    case broker(family: String, operation: String)
    case tool(tool: String)
}

public enum MockActionExecutionPath: String, Hashable, Sendable {
    case serviceBroker = "service_broker"
    case hostBroker = "host_broker"
    case secretaryTool = "secretary_tool"
    case secretaryBackendService = "secretary_backend_service"
}

public enum MockResolverCorrelationHandling: String, Hashable, Sendable {
    case resolverMintedRequired = "resolver-minted-required"
}

public struct MockActionReference: Hashable, Sendable {
    public var actionID: String
    public var label: String
    public var packageID: String
    public var surfaceID: String
    public var actionOwnerComponentID: String
    public var capabilityCallerComponentID: String
    public var callerCapabilityID: String
    public var componentProfile: String
    public var requiredPermissions: [String]
    public var risk: MockRiskTier
    public var invokes: MockActionInvocation
    public var executionPath: MockActionExecutionPath
    public var resolverCorrelationHandling: MockResolverCorrelationHandling
    public var confirmationRequired: Bool
    public var redactionProjection: String
    public var auditEvent: String

    public var declaredByPackageID: String { packageID }
    public var declaredBySurfaceID: String { surfaceID }
    public var permissionScope: String { requiredPermissions.joined(separator: " ") }

    public init(
        actionID: String,
        label: String,
        packageID: String,
        surfaceID: String,
        actionOwnerComponentID: String,
        capabilityCallerComponentID: String,
        callerCapabilityID: String,
        componentProfile: String,
        requiredPermissions: [String],
        risk: MockRiskTier,
        invokes: MockActionInvocation,
        executionPath: MockActionExecutionPath,
        resolverCorrelationHandling: MockResolverCorrelationHandling = .resolverMintedRequired,
        confirmationRequired: Bool,
        redactionProjection: String,
        auditEvent: String
    ) {
        self.actionID = actionID
        self.label = label
        self.packageID = packageID
        self.surfaceID = surfaceID
        self.actionOwnerComponentID = actionOwnerComponentID
        self.capabilityCallerComponentID = capabilityCallerComponentID
        self.callerCapabilityID = callerCapabilityID
        self.componentProfile = componentProfile
        self.requiredPermissions = requiredPermissions
        self.risk = risk
        self.invokes = invokes
        self.executionPath = executionPath
        self.resolverCorrelationHandling = resolverCorrelationHandling
        self.confirmationRequired = confirmationRequired
        self.redactionProjection = redactionProjection
        self.auditEvent = auditEvent
    }
}

public struct ComposerConfiguration: Equatable, Sendable {
    public var routeKey: String
    public var selectedModel: ComposerModelSelection
    public var permissionMode: ComposerPermissionMode

    public init(
        routeKey: String = "",
        selectedModel: ComposerModelSelection,
        permissionMode: ComposerPermissionMode
    ) {
        self.routeKey = routeKey
        self.selectedModel = selectedModel
        self.permissionMode = permissionMode
    }
}

public struct ComposerModelSelection: Equatable, Sendable {
    public var id: String
    public var routeKey: String
    public var displayName: String

    public init(id: String = "", routeKey: String = "", displayName: String) {
        self.id = id
        self.routeKey = routeKey
        self.displayName = displayName
    }
}

public struct ComposerPermissionMode: Equatable, Sendable {
    public var id: String
    public var routeKey: String
    public var permissionScope: String
    public var displayName: String

    public init(
        id: String = "",
        routeKey: String = "",
        permissionScope: String = "",
        displayName: String
    ) {
        self.id = id
        self.routeKey = routeKey
        self.permissionScope = permissionScope
        self.displayName = displayName
    }
}

public extension MockSurfaceReference {
    static let projectHome = MockSurfaceReference(
        packageID: hostPackageID,
        surfaceID: "project-home",
        lifecycle: .mounted,
        trust: .hostShippedBuiltIn,
        criticality: .hostRequired,
        schemaVersion: "surface.mock.v1"
    )

    static let projectConversation = MockSurfaceReference(
        packageID: hostPackageID,
        surfaceID: "project-conversation",
        lifecycle: .mounted,
        trust: .hostShippedBuiltIn,
        criticality: .hostRequired,
        schemaVersion: "surface.mock.v1"
    )

    static let globalSecretary = MockSurfaceReference(
        packageID: "dev.atelia.packages.official.secretary",
        surfaceID: "global-secretary",
        lifecycle: .available,
        trust: .bundledOfficial,
        criticality: .userRemovable,
        schemaVersion: "surface.mock.v1"
    )

    static let globalSearch = MockSurfaceReference(
        packageID: "dev.atelia.packages.official.search",
        surfaceID: "global-search",
        lifecycle: .available,
        trust: .bundledOfficial,
        criticality: .userRemovable,
        schemaVersion: "surface.mock.v1"
    )

    static let packageManagement = MockSurfaceReference(
        packageID: hostPackageID,
        surfaceID: "package-management",
        lifecycle: .mounted,
        trust: .hostShippedBuiltIn,
        criticality: .hostRequired,
        schemaVersion: "surface.mock.v1"
    )

    static let permissionRecovery = MockSurfaceReference(
        packageID: hostPackageID,
        surfaceID: "permission-recovery",
        lifecycle: .mounted,
        trust: .hostShippedBuiltIn,
        criticality: .hostRequired,
        schemaVersion: "surface.mock.v1"
    )

    static let settings = MockSurfaceReference(
        packageID: hostPackageID,
        surfaceID: "settings",
        lifecycle: .mounted,
        trust: .hostShippedBuiltIn,
        criticality: .hostRequired,
        schemaVersion: "surface.mock.v1"
    )

    static let officialAutomations = MockSurfaceReference(
        packageID: "dev.atelia.packages.official.automations",
        surfaceID: "automations-home",
        lifecycle: .available,
        trust: .bundledOfficial,
        criticality: .userRemovable,
        schemaVersion: "surface.mock.v1"
    )

    static let officialReview = MockSurfaceReference(
        packageID: "dev.atelia.packages.official.review",
        surfaceID: "review-home",
        lifecycle: .available,
        trust: .bundledOfficial,
        criticality: .userRemovable,
        schemaVersion: "surface.mock.v1"
    )
}

public extension MockActionReference {
    static let openProjectConversation = MockActionReference(
        actionID: "action.project-conversation.open",
        label: "Open project conversation",
        packageID: MockSurfaceReference.hostPackageID,
        surfaceID: "project-conversation",
        actionOwnerComponentID: "project-shell",
        capabilityCallerComponentID: "host-navigation",
        callerCapabilityID: "host_broker.open_surface",
        componentProfile: "ConversationListItem.v1",
        requiredPermissions: ["project.conversation.read"],
        risk: .r1,
        invokes: .broker(family: "surface", operation: "open"),
        executionPath: .hostBroker,
        confirmationRequired: false,
        redactionProjection: "project_default",
        auditEvent: "project_conversation.opened"
    )

    static let inspectDelegatedWork = MockActionReference(
        actionID: "action.project-home.inspect-delegated-work",
        label: "Inspect delegated work",
        packageID: MockSurfaceReference.hostPackageID,
        surfaceID: "project-home",
        actionOwnerComponentID: "project-shell",
        capabilityCallerComponentID: "host-navigation",
        callerCapabilityID: "host_broker.open_surface",
        componentProfile: "NavigationListItem.v1",
        requiredPermissions: ["project.work.read"],
        risk: .r1,
        invokes: .broker(family: "surface", operation: "open"),
        executionPath: .hostBroker,
        confirmationRequired: false,
        redactionProjection: "project_default",
        auditEvent: "project_work.inspected"
    )

    static let inspectInstalledPackages = MockActionReference(
        actionID: "action.package-management.inspect-installed",
        label: "Inspect installed packages",
        packageID: MockSurfaceReference.hostPackageID,
        surfaceID: "package-management",
        actionOwnerComponentID: "package-inspector",
        capabilityCallerComponentID: "host-navigation",
        callerCapabilityID: "host_broker.open_surface",
        componentProfile: "NavigationListItem.v1",
        requiredPermissions: ["packages.inspect"],
        risk: .r1,
        invokes: .broker(family: "surface", operation: "open"),
        executionPath: .hostBroker,
        confirmationRequired: false,
        redactionProjection: "project_default",
        auditEvent: "packages.inspected"
    )

    static let reviewPermissions = MockActionReference(
        actionID: "action.permission-recovery.review",
        label: "Review permissions",
        packageID: MockSurfaceReference.hostPackageID,
        surfaceID: "permission-recovery",
        actionOwnerComponentID: "permission-recovery",
        capabilityCallerComponentID: "host-navigation",
        callerCapabilityID: "host_broker.open_surface",
        componentProfile: "NavigationListItem.v1",
        requiredPermissions: ["permissions.review"],
        risk: .r1,
        invokes: .broker(family: "surface", operation: "open"),
        executionPath: .hostBroker,
        confirmationRequired: false,
        redactionProjection: "project_default",
        auditEvent: "permissions.reviewed"
    )

    static let openProjectSettings = MockActionReference(
        actionID: "action.settings.open-project",
        label: "Open project settings",
        packageID: MockSurfaceReference.hostPackageID,
        surfaceID: "settings",
        actionOwnerComponentID: "project-settings",
        capabilityCallerComponentID: "host-navigation",
        callerCapabilityID: "host_broker.open_surface",
        componentProfile: "NavigationListItem.v1",
        requiredPermissions: ["project.settings.read"],
        risk: .r1,
        invokes: .broker(family: "surface", operation: "open"),
        executionPath: .hostBroker,
        confirmationRequired: false,
        redactionProjection: "project_default",
        auditEvent: "project_settings.opened"
    )

    static let startNewThread = MockActionReference(
        actionID: "action.project-conversation.start-new-thread",
        label: "Start new thread",
        packageID: MockSurfaceReference.hostPackageID,
        surfaceID: "project-conversation",
        actionOwnerComponentID: "project-shell",
        capabilityCallerComponentID: "host-navigation",
        callerCapabilityID: "host_broker.open_surface",
        componentProfile: "PrimaryNavigationCommand.v1",
        requiredPermissions: ["project.conversation.write"],
        risk: .r1,
        invokes: .broker(family: "surface", operation: "open"),
        executionPath: .hostBroker,
        confirmationRequired: false,
        redactionProjection: "project_default",
        auditEvent: "project_conversation.started"
    )

    static let openGlobalSecretary = MockActionReference(
        actionID: "action.global-secretary.open",
        label: "Open Global Secretary",
        packageID: "dev.atelia.packages.official.secretary",
        surfaceID: "global-secretary",
        actionOwnerComponentID: "global-secretary",
        capabilityCallerComponentID: "global-secretary-backend",
        callerCapabilityID: "service.global_secretary.read",
        componentProfile: "GlobalNavigationListItem.v1",
        requiredPermissions: ["workspace.secretary.read"],
        risk: .r1,
        invokes: .service(service: "global-secretary.surface.v1", method: "open"),
        executionPath: .serviceBroker,
        confirmationRequired: false,
        redactionProjection: "workspace_default",
        auditEvent: "global_secretary.opened"
    )

    static let searchAllProjects = MockActionReference(
        actionID: "action.global-search.search-all-projects",
        label: "Search all projects",
        packageID: "dev.atelia.packages.official.search",
        surfaceID: "global-search",
        actionOwnerComponentID: "global-search",
        capabilityCallerComponentID: "global-search-backend",
        callerCapabilityID: "service.global_search.read",
        componentProfile: "PrimaryNavigationCommand.v1",
        requiredPermissions: ["workspace.search.read"],
        risk: .r1,
        invokes: .service(service: "global-search.surface.v1", method: "open"),
        executionPath: .serviceBroker,
        confirmationRequired: false,
        redactionProjection: "workspace_default",
        auditEvent: "global_search.opened"
    )

    static let openMobileSetup = MockActionReference(
        actionID: "action.mobile-setup.open",
        label: "Open mobile setup",
        packageID: MockSurfaceReference.hostPackageID,
        surfaceID: "settings",
        actionOwnerComponentID: "settings-mobile",
        capabilityCallerComponentID: "host-navigation",
        callerCapabilityID: "host_broker.open_surface",
        componentProfile: "GlobalNavigationListItem.v1",
        requiredPermissions: ["workspace.mobile.setup"],
        risk: .r1,
        invokes: .broker(family: "surface", operation: "open"),
        executionPath: .hostBroker,
        confirmationRequired: false,
        redactionProjection: "workspace_default",
        auditEvent: "mobile_setup.opened"
    )

    static let openAutomationsPackage = MockActionReference(
        actionID: "action.official-automations.open",
        label: "Open automations package",
        packageID: "dev.atelia.packages.official.automations",
        surfaceID: "automations-home",
        actionOwnerComponentID: "automations-surface",
        capabilityCallerComponentID: "automations-backend",
        callerCapabilityID: "service.automations.read",
        componentProfile: "PackageSurfaceListItem.v1",
        requiredPermissions: ["packages.official.automations.read"],
        risk: .r1,
        invokes: .service(service: "automations.surface.v1", method: "open"),
        executionPath: .serviceBroker,
        confirmationRequired: false,
        redactionProjection: "package_default",
        auditEvent: "package_surface.opened"
    )

    static let openReviewPackage = MockActionReference(
        actionID: "action.official-review.open",
        label: "Open review package",
        packageID: "dev.atelia.packages.official.review",
        surfaceID: "review-home",
        actionOwnerComponentID: "review-surface",
        capabilityCallerComponentID: "review-backend",
        callerCapabilityID: "service.review.read",
        componentProfile: "PackageSurfaceListItem.v1",
        requiredPermissions: ["packages.official.review.read"],
        risk: .r1,
        invokes: .service(service: "review.surface.v1", method: "open"),
        executionPath: .serviceBroker,
        confirmationRequired: false,
        redactionProjection: "package_default",
        auditEvent: "package_surface.opened"
    )
}

public struct WorkspaceGroup: Identifiable, Sendable {
    public enum Status: Sendable {
        case warning
    }

    public var id: String
    public var title: String
    public var subtitle: String?
    public var surface: MockSurfaceReference
    public var items: [ChatListItem]
    public var settings: [ChatListItem] = []
    public var status: Status?
    public var emptyText: String?

    public init(
        id: String,
        title: String,
        subtitle: String?,
        surface: MockSurfaceReference,
        items: [ChatListItem],
        settings: [ChatListItem] = [],
        status: Status? = nil,
        emptyText: String? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.surface = surface
        self.items = items
        self.settings = settings
        self.status = status
        self.emptyText = emptyText
    }
}

public struct ChatListItem: Identifiable, Sendable {
    public var id: String
    public var projectID: String
    public var resourceID: String
    public var title: String
    public var trailing: String?
    public var leadingAffordance: LeadingAffordanceRole?
    public var surface: MockSurfaceReference
    public var action: MockActionReference?

    public init(
        id: String,
        projectID: String,
        resourceID: String,
        title: String,
        trailing: String?,
        leadingAffordance: LeadingAffordanceRole? = nil,
        surface: MockSurfaceReference,
        action: MockActionReference? = nil
    ) {
        self.id = id
        self.projectID = projectID
        self.resourceID = resourceID
        self.title = title
        self.trailing = trailing
        self.leadingAffordance = leadingAffordance
        self.surface = surface
        self.action = action
    }
}

public enum LeadingAffordanceRole: Hashable, Sendable {
    case activity
    case assistantConversation
    case delegatedWork
    case packageInstall
}

public enum LeadingAffordancePresentation: Hashable, Sendable {
    case statusDot
    case assistantMark
    case branchGlyph
    case addGlyph
}

public extension LeadingAffordanceRole {
    var presentation: LeadingAffordancePresentation {
        switch self {
        case .activity:
            return .statusDot
        case .assistantConversation:
            return .assistantMark
        case .delegatedWork:
            return .branchGlyph
        case .packageInstall:
            return .addGlyph
        }
    }
}

public struct ClientMockProjection: Sendable {
    public var projectSectionHeader: ProjectSectionHeaderViewData
    public var workspaceGroups: [WorkspaceGroupViewData]
    public var recentChats: [ChatListItemViewData]

    public init(
        projectSectionHeader: ProjectSectionHeaderViewData,
        workspaceGroups: [WorkspaceGroupViewData],
        recentChats: [ChatListItemViewData]
    ) {
        self.projectSectionHeader = projectSectionHeader
        self.workspaceGroups = workspaceGroups
        self.recentChats = recentChats
    }
}

public struct ProjectSectionHeaderViewData: Sendable, Equatable {
    public var title: String
    public var actions: [ProjectSectionHeaderActionViewData]

    public init(title: String, actions: [ProjectSectionHeaderActionViewData]) {
        self.title = title
        self.actions = actions
    }
}

public struct ProjectSectionHeaderActionViewData: Identifiable, Hashable, Sendable {
    public enum Kind: String, Hashable, Sendable {
        case createFolder = "create-folder"
        case useExistingFolder = "use-existing-folder"
    }

    public var id: String
    public var kind: Kind
    public var title: String
    public var symbolName: String
    public var accessibilityLabel: String

    public init(
        id: String,
        kind: Kind,
        title: String,
        symbolName: String,
        accessibilityLabel: String
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.symbolName = symbolName
        self.accessibilityLabel = accessibilityLabel
    }
}

public struct WorkspaceGroupViewData: Identifiable, Sendable {
    public var id: String
    public var title: String
    public var subtitle: String?
    public var surface: MockSurfaceReference
    public var items: [ChatListItemViewData]
    public var settings: [ChatListItemViewData]
    public var status: WorkspaceGroup.Status?
    public var emptyText: String?

    public init(
        id: String,
        title: String,
        subtitle: String?,
        surface: MockSurfaceReference,
        items: [ChatListItemViewData],
        settings: [ChatListItemViewData],
        status: WorkspaceGroup.Status?,
        emptyText: String?
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.surface = surface
        self.items = items
        self.settings = settings
        self.status = status
        self.emptyText = emptyText
    }
}

public struct ChatListItemViewData: Identifiable, Sendable {
    public var id: String
    public var projectID: String
    public var resourceID: String
    public var title: String
    public var trailing: String?
    public var isSelected: Bool
    public var leadingAffordance: LeadingAffordanceRole?
    public var leadingPresentation: LeadingAffordancePresentation?
    public var surface: MockSurfaceReference
    public var action: MockActionReference?

    public init(item: ChatListItem, activeSelection: ClientMockActiveSelection) {
        id = item.id
        projectID = item.projectID
        resourceID = item.resourceID
        title = item.title
        trailing = item.trailing
        isSelected = activeSelection.matches(item)
        leadingAffordance = item.leadingAffordance
        leadingPresentation = item.leadingAffordance?.presentation
        surface = item.surface
        action = item.action
    }
}

public extension ClientMockState {
    var projection: ClientMockProjection {
        ClientMockProjection(
            projectSectionHeader: .projectSectionHeader,
            workspaceGroups: workspaceGroups.map { group in
                WorkspaceGroupViewData(
                    id: group.id,
                    title: group.title,
                    subtitle: group.subtitle,
                    surface: group.surface,
                    items: group.items.map {
                        ChatListItemViewData(item: $0, activeSelection: activeSelection)
                    },
                    settings: group.settings.map {
                        ChatListItemViewData(item: $0, activeSelection: activeSelection)
                    },
                    status: group.status,
                    emptyText: group.emptyText
                )
            },
            recentChats: recentChats.map {
                ChatListItemViewData(item: $0, activeSelection: activeSelection)
            }
        )
    }
}

public extension ProjectSectionHeaderViewData {
    static let projectSectionHeader = ProjectSectionHeaderViewData(
        title: "プロジェクト",
        actions: [
            ProjectSectionHeaderActionViewData(
                id: "project:add:create-folder",
                kind: .createFolder,
                title: "新規フォルダを作成",
                symbolName: "folder.badge.plus",
                accessibilityLabel: "新規フォルダを作成"
            ),
            ProjectSectionHeaderActionViewData(
                id: "project:add:use-existing-folder",
                kind: .useExistingFolder,
                title: "既存のフォルダを使用",
                symbolName: "folder",
                accessibilityLabel: "既存のフォルダを使用"
            )
        ]
    )
}

public struct ChangeSummary: Sendable {
    public var filePath: String
    public var additions: Int
    public var deletions: Int
    public var collapsedFileCount: Int

    public init(filePath: String, additions: Int, deletions: Int, collapsedFileCount: Int) {
        self.filePath = filePath
        self.additions = additions
        self.deletions = deletions
        self.collapsedFileCount = collapsedFileCount
    }
}

public struct ChatMessage: Identifiable, Sendable {
    public var id: String
    public var text: String
    public var attachmentName: String?

    public init(id: String, text: String, attachmentName: String? = nil) {
        self.id = id
        self.text = text
        self.attachmentName = attachmentName
    }
}

public struct ActivityBlock: Sendable {
    public var duration: String
    public var title: String
    public var bullets: [String]
    public var document: DocumentPreview
    public var review: ReviewPreview

    public init(
        duration: String,
        title: String,
        bullets: [String],
        document: DocumentPreview,
        review: ReviewPreview
    ) {
        self.duration = duration
        self.title = title
        self.bullets = bullets
        self.document = document
        self.review = review
    }
}

public struct DocumentPreview: Sendable {
    public var title: String
    public var subtitle: String

    public init(title: String, subtitle: String) {
        self.title = title
        self.subtitle = subtitle
    }
}

public struct ReviewPreview: Sendable {
    public var title: String
    public var additions: Int
    public var deletions: Int

    public init(title: String, additions: Int, deletions: Int) {
        self.title = title
        self.additions = additions
        self.deletions = deletions
    }
}

public struct GoalStatus: Sendable {
    public var title: String
    public var elapsed: String

    public init(title: String, elapsed: String) {
        self.title = title
        self.elapsed = elapsed
    }
}
