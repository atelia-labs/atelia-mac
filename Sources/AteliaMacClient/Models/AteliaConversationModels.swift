import Foundation

struct AteliaConversation: Identifiable {
    var id: String
    var title: String
    var turns: [AteliaConversationTurn]

    static let mdpRenderingReference = AteliaConversation(
        id: "conversation.mdp-rendering.reference",
        title: "Secretary による Package MDP 更新",
        turns: [
            AteliaConversationTurn(
                id: "turn.user.package-mdp-request",
                actor: .user,
                blocks: [
                    .message(
                        AteliaMessageBlock(
                            id: "message.user.package-mdp-request",
                            text: "Package MDP のレンダリングを Mac client 側で確認できるようにしたい。Secretary の実行、activity、tool output、change set、diff が会話上で意味を持って読める状態まで寄せて。",
                            attachmentName: "AGENTS.md"
                        )
                    )
                ]
            ),
            AteliaConversationTurn(
                id: "turn.secretary.audit",
                actor: .secretary,
                blocks: [
                    .activity(
                        AteliaActivityBlock(
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
                        AteliaToolOutputBlock(
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
                        AteliaChangeSetBlock(
                            id: "change-set.conversation-mdp-rendering",
                            title: "Conversation MDP semantic mock",
                            summary: "Mac client conversation surface now renders Atelia-shaped activity, tool output, change set, and diff semantics.",
                            files: [
                                AteliaChangedFile(
                                    id: "changed-file.models",
                                    path: "Sources/AteliaMacClient/Models/AteliaConversationModels.swift",
                                    additions: 156,
                                    deletions: 0,
                                    hunks: [
                                        AteliaDiffHunk(
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
                                AteliaChangedFile(
                                    id: "changed-file.view",
                                    path: "Sources/AteliaMacClient/Views/ConversationView.swift",
                                    additions: 244,
                                    deletions: 0,
                                    hunks: [
                                        AteliaDiffHunk(
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

struct AteliaConversationTurn: Identifiable {
    enum Actor {
        case user
        case secretary
    }

    var id: String
    var actor: Actor
    var blocks: [AteliaConversationBlock]
}

enum AteliaConversationBlock: Identifiable {
    case message(AteliaMessageBlock)
    case activity(AteliaActivityBlock)
    case toolOutput(AteliaToolOutputBlock)
    case changeSet(AteliaChangeSetBlock)

    var id: String {
        switch self {
        case .message(let block):
            block.id
        case .activity(let block):
            block.id
        case .toolOutput(let block):
            block.id
        case .changeSet(let block):
            block.id
        }
    }
}

struct AteliaMessageBlock: Identifiable {
    var id: String
    var text: String
    var attachmentName: String?
}

struct AteliaActivityBlock: Identifiable {
    var id: String
    var duration: String
    var status: String
    var title: String
    var bullets: [String]
}

struct AteliaToolOutputBlock: Identifiable {
    enum Status {
        case succeeded
        case failed
        case running
    }

    var id: String
    var toolName: String
    var command: String
    var status: Status
    var output: [String]
}

struct AteliaChangeSetBlock: Identifiable {
    var id: String
    var title: String
    var summary: String
    var files: [AteliaChangedFile]

    var additions: Int {
        files.reduce(0) { $0 + $1.additions }
    }

    var deletions: Int {
        files.reduce(0) { $0 + $1.deletions }
    }
}

struct AteliaChangedFile: Identifiable {
    var id: String
    var path: String
    var additions: Int
    var deletions: Int
    var hunks: [AteliaDiffHunk]
}

struct AteliaDiffHunk: Identifiable {
    var id: String
    var header: String
    var lines: [AteliaDiffLine]
}

struct AteliaDiffLine: Identifiable {
    enum Kind {
        case added
        case removed
        case context
    }

    var id: String
    var kind: Kind
    var text: String

    var marker: String {
        switch kind {
        case .added:
            "+"
        case .removed:
            "-"
        case .context:
            " "
        }
    }

    static func added(id: String, _ text: String) -> AteliaDiffLine {
        AteliaDiffLine(id: id, kind: .added, text: normalizedText(text, marker: "+"))
    }

    static func removed(id: String, _ text: String) -> AteliaDiffLine {
        AteliaDiffLine(id: id, kind: .removed, text: normalizedText(text, marker: "-"))
    }

    static func context(id: String, _ text: String) -> AteliaDiffLine {
        AteliaDiffLine(id: id, kind: .context, text: normalizedText(text, marker: " "))
    }

    private static func normalizedText(_ text: String, marker: Character) -> String {
        guard text.first == marker else {
            return text
        }

        return String(text.dropFirst())
    }
}
