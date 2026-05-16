import Foundation

struct ClientMockState {
    var activeConversationTitle: String
    var activeProjectTitle: String
    var workspaceGroups: [WorkspaceGroup]
    var recentChats: [ChatListItem]
    var changeSummary: ChangeSummary
    var messages: [ChatMessage]
    var activity: ActivityBlock
    var goal: GoalStatus

    static let ateliaReference = ClientMockState(
        activeConversationTitle: "Secretary による Package MDP 更新",
        activeProjectTitle: "Mac Atelia",
        workspaceGroups: [
            WorkspaceGroup(
                title: "Mac Atelia",
                subtitle: nil,
                items: [
                    ChatListItem(title: "Secretary", trailing: nil, isSelected: true, leadingStatus: .secretary),
                    ChatListItem(title: "サブエージェント", trailing: "3", leadingStatus: .branch)
                ],
                settings: [
                    ChatListItem(title: "拡張機能", trailing: nil, leadingStatus: .plus),
                    ChatListItem(title: "オートメーション", trailing: nil),
                    ChatListItem(title: "プロジェクト設定", trailing: nil)
                ]
            ),
            WorkspaceGroup(
                title: "atelia-secretary",
                subtitle: "Global Secretary",
                items: [
                    ChatListItem(title: "Secretary", trailing: nil, leadingStatus: .secretary),
                    ChatListItem(title: "オートメーション", trailing: "2")
                ],
                status: .warning
            ),
            WorkspaceGroup(
                title: "Aspiral",
                subtitle: nil,
                items: [
                    ChatListItem(title: "Secretary", trailing: nil, leadingStatus: .secretary)
                ]
            )
        ],
        recentChats: [
            ChatListItem(title: "Global Secretary", trailing: nil, leadingStatus: .secretary),
            ChatListItem(title: "検索", trailing: nil),
            ChatListItem(title: "拡張機能", trailing: nil),
            ChatListItem(title: "オートメーション", trailing: nil),
            ChatListItem(title: "Atelia Mobile を設定", trailing: nil)
        ],
        changeSummary: ChangeSummary(
            filePath: "atelia-secretary-package-audit/crates/ateliad/src/rpc.rs",
            additions: 68,
            deletions: 9,
            collapsedFileCount: 1
        ),
        messages: [
            ChatMessage(
                text: "おっけー\n新しいサブエージェントプロファイルとしてGLMが使えるようになったから、これからの調査・実装・修正・通常レビューは全部GLMにやらせることにしよう、Sparkとminiを置き換えって感じ\n一旦それで AGENTS.md を書き換えて欲しいかな\nフォールバックはGLM>Spark>miniで",
                attachmentName: "AGENTS.md"
            )
        ],
        activity: ActivityBlock(
            duration: "36s",
            title: "AGENTS.md を更新しました。",
            bullets: [
                "調査・実装・修正・通常レビューのデフォルトを glm sub-agent profile に変更",
                "fallback を glm → gpt-5.3-codex-spark → gpt-5.4-mini に明記",
                "final strict PR review は従来どおり gpt-5.5 medium のまま維持"
            ],
            document: DocumentPreview(title: "AGENTS.md", subtitle: "ドキュメント・MD"),
            review: ReviewPreview(title: "2 件のファイルを編集", additions: 50, deletions: 47)
        ),
        goal: GoalStatus(
            title: "一時停止中の目標 Package-Driven Atelia MDP: dynamic Mac client",
            elapsed: "33h 39m 21s"
        )
    )

    static let codexReference = ateliaReference
}

struct WorkspaceGroup: Identifiable {
    enum Status {
        case warning
    }

    var id = UUID()
    var title: String
    var subtitle: String?
    var items: [ChatListItem]
    var settings: [ChatListItem] = []
    var status: Status?
    var emptyText: String?
}

struct ChatListItem: Identifiable {
    enum LeadingStatus {
        case green
        case secretary
        case branch
        case plus
    }

    var id = UUID()
    var title: String
    var trailing: String?
    var isSelected = false
    var leadingStatus: LeadingStatus?
}

struct ChangeSummary {
    var filePath: String
    var additions: Int
    var deletions: Int
    var collapsedFileCount: Int
}

struct ChatMessage: Identifiable {
    var id = UUID()
    var text: String
    var attachmentName: String?
}

struct ActivityBlock {
    var duration: String
    var title: String
    var bullets: [String]
    var document: DocumentPreview
    var review: ReviewPreview
}

struct DocumentPreview {
    var title: String
    var subtitle: String
}

struct ReviewPreview {
    var title: String
    var additions: Int
    var deletions: Int
}

struct GoalStatus {
    var title: String
    var elapsed: String
}
