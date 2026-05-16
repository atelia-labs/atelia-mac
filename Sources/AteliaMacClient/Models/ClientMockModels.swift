import Foundation

struct ClientMockState {
    var activeConversationTitle: String
    var workspaceGroups: [WorkspaceGroup]
    var recentChats: [ChatListItem]
    var changeSummary: ChangeSummary
    var messages: [ChatMessage]
    var activity: ActivityBlock
    var goal: GoalStatus

    static let codexReference = ClientMockState(
        activeConversationTitle: "Atelia docsを同期",
        workspaceGroups: [
            WorkspaceGroup(
                title: "presentations",
                subtitle: nil,
                items: []
            ),
            WorkspaceGroup(
                title: "Mac Atelia",
                subtitle: nil,
                items: [
                    ChatListItem(title: "Atelia docsを同期", trailing: "7時間", isSelected: true),
                    ChatListItem(title: "Sync docs to Atelia canon", trailing: "3日"),
                    ChatListItem(title: "Review surface-protocol ...", trailing: "5日"),
                    ChatListItem(title: "Review codex/surface-pr...", trailing: "1週間"),
                    ChatListItem(title: "Review codex/surface-pr...", trailing: "4日")
                ]
            ),
            WorkspaceGroup(
                title: "atelia-la...",
                subtitle: "wsl-co...",
                items: [],
                status: .warning,
                emptyText: "チャットはありません"
            ),
            WorkspaceGroup(
                title: "Aspiral",
                subtitle: nil,
                items: [
                    ChatListItem(title: "Aspiral Main 4/26", trailing: "2週間", leadingStatus: .green)
                ]
            ),
            WorkspaceGroup(title: "papers", subtitle: nil, items: [], emptyText: "チャットはありません"),
            WorkspaceGroup(
                title: "metis",
                subtitle: "wsl-codex",
                items: [],
                status: .warning,
                emptyText: "チャットはありません"
            )
        ],
        recentChats: [
            ChatListItem(title: "GLM Coding Planをサブエ...", trailing: "2日"),
            ChatListItem(title: "Codexマルウェアを調査", trailing: "3日"),
            ChatListItem(title: "Codex Appで/goalを有効化", trailing: "3日")
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
            title: "一時停止中の目標 Package-Driven Atelia MDP: merge existing At...",
            elapsed: "33h 39m 21s"
        )
    )
}

struct WorkspaceGroup: Identifiable {
    enum Status {
        case warning
    }

    var id = UUID()
    var title: String
    var subtitle: String?
    var items: [ChatListItem]
    var status: Status?
    var emptyText: String?
}

struct ChatListItem: Identifiable {
    enum LeadingStatus {
        case green
    }

    var id = UUID()
    var title: String
    var trailing: String
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
