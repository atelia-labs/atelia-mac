import AteliaMacClientModels
import AppKit
import CoreGraphics
import Foundation

struct AteliaConversation: Identifiable {
    var id: String
    var title: String
    var turns: [AteliaConversationTurn]

    init(fixture: ClientConversationFixture) {
        id = fixture.id
        title = fixture.title
        turns = fixture.turns.map(AteliaConversationTurn.init(fixture:))
    }

    static let mdpRenderingReference = AteliaConversation(fixture: .mdpRenderingReference)
}

struct AteliaConversationTurn: Identifiable {
    enum Actor {
        case user
        case secretary
    }

    var id: String
    var actor: Actor
    var blocks: [AteliaConversationBlock]

    init(id: String, actor: Actor, blocks: [AteliaConversationBlock]) {
        self.id = id
        self.actor = actor
        self.blocks = blocks
    }

    init(fixture: ClientConversationTurnFixture) {
        id = fixture.id
        switch fixture.actor {
        case .user:
            actor = .user
        case .secretary:
            actor = .secretary
        }
        blocks = fixture.blocks.map(AteliaConversationBlock.init(fixture:))
    }
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

    init(fixture: ClientConversationBlockFixture) {
        switch fixture {
        case .message(let message):
            self = .message(
                AteliaMessageBlock(
                    id: message.id,
                    text: message.text,
                    attachmentName: message.attachmentName
                )
            )
        case .activity(let activity):
            self = .activity(AteliaActivityBlock(fixture: activity))
        case .toolOutput(let toolOutput):
            self = .toolOutput(AteliaToolOutputBlock(fixture: toolOutput))
        case .changeSet(let changeSet):
            self = .changeSet(AteliaChangeSetBlock(fixture: changeSet))
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
    var identifiedBullets: [AteliaIdentifiedTextLine] {
        AteliaIdentifiedTextLine.rows(parentID: id, role: "bullet", texts: bullets)
    }

    init(id: String, duration: String, status: String, title: String, bullets: [String]) {
        self.id = id
        self.duration = duration
        self.status = status
        self.title = title
        self.bullets = bullets
    }

    init(fixture: ClientConversationActivityFixture) {
        self.init(
            id: fixture.id,
            duration: fixture.duration,
            status: fixture.status,
            title: fixture.title,
            bullets: fixture.bullets
        )
    }
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
    var identifiedOutputLines: [AteliaIdentifiedTextLine] {
        AteliaIdentifiedTextLine.rows(parentID: id, role: "output", texts: output)
    }

    init(id: String, toolName: String, command: String, status: Status, output: [String]) {
        self.id = id
        self.toolName = toolName
        self.command = command
        self.status = status
        self.output = output
    }

    init(fixture: ClientConversationToolOutputFixture) {
        let mappedStatus: Status
        switch fixture.status {
        case .succeeded:
            mappedStatus = .succeeded
        case .failed:
            mappedStatus = .failed
        case .running:
            mappedStatus = .running
        }
        self.init(
            id: fixture.id,
            toolName: fixture.toolName,
            command: fixture.command,
            status: mappedStatus,
            output: fixture.output
        )
    }
}

struct AteliaIdentifiedTextLine: Identifiable, Equatable {
    var id: String
    var text: String

    static func rows(parentID: String, role: String, texts: [String]) -> [AteliaIdentifiedTextLine] {
        var occurrenceByFingerprint: [String: Int] = [:]

        return texts.map { text in
            let fingerprint = stableFingerprint(for: text)
            let occurrence = occurrenceByFingerprint[fingerprint, default: 0]
            occurrenceByFingerprint[fingerprint] = occurrence + 1
            return AteliaIdentifiedTextLine(
                id: "\(parentID).\(role).\(fingerprint).\(occurrence)",
                text: text
            )
        }
    }

    private static func stableFingerprint(for text: String) -> String {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in text.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001b3
        }
        return String(hash, radix: 16)
    }
}

struct AteliaChangeSetBlock: Identifiable {
    var id: String
    var title: String
    var summary: String
    var isExpandedByDefault: Bool
    var files: [AteliaChangedFile]

    init(
        id: String,
        title: String,
        summary: String,
        isExpandedByDefault: Bool = false,
        files: [AteliaChangedFile]
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.isExpandedByDefault = isExpandedByDefault
        self.files = files
    }

    init(fixture: ClientConversationChangeSetFixture) {
        self.init(
            id: fixture.id,
            title: fixture.title,
            summary: fixture.summary,
            isExpandedByDefault: fixture.isExpandedByDefault,
            files: fixture.files.map(AteliaChangedFile.init(fixture:))
        )
    }

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

    init(id: String, path: String, additions: Int, deletions: Int, hunks: [AteliaDiffHunk]) {
        self.id = id
        self.path = path
        self.additions = additions
        self.deletions = deletions
        self.hunks = hunks
    }

    init(fixture: ClientConversationChangedFileFixture) {
        self.init(
            id: fixture.id,
            path: fixture.path,
            additions: fixture.additions,
            deletions: fixture.deletions,
            hunks: fixture.hunks.map(AteliaDiffHunk.init(fixture:))
        )
    }
}

struct AteliaDiffHunk: Identifiable {
    var id: String
    var header: String
    var lines: [AteliaDiffLine]

    init(id: String, header: String, lines: [AteliaDiffLine]) {
        self.id = id
        self.header = header
        self.lines = lines
    }

    init(fixture: ClientConversationDiffHunkFixture) {
        self.init(
            id: fixture.id,
            header: fixture.header,
            lines: fixture.lines.map(AteliaDiffLine.init(fixture:))
        )
    }
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
        AteliaDiffLine(id: id, kind: .added, text: text)
    }

    static func removed(id: String, _ text: String) -> AteliaDiffLine {
        AteliaDiffLine(id: id, kind: .removed, text: text)
    }

    static func context(id: String, _ text: String) -> AteliaDiffLine {
        AteliaDiffLine(id: id, kind: .context, text: text)
    }

    static func rawUnifiedDiff(id: String, kind: Kind, text: String) -> AteliaDiffLine {
        AteliaDiffLine(
            id: id,
            kind: kind,
            text: ClientUnifiedDiffText.normalized(text, marker: kind.unifiedDiffMarker)
        )
    }

    init(id: String, kind: Kind, text: String) {
        self.id = id
        self.kind = kind
        self.text = text
    }

    init(fixture: ClientConversationDiffLineFixture) {
        let mappedKind: Kind
        switch fixture.kind {
        case .added:
            mappedKind = .added
        case .removed:
            mappedKind = .removed
        case .context:
            mappedKind = .context
        }
        self.init(id: fixture.id, kind: mappedKind, text: fixture.text)
    }

}

private extension AteliaDiffLine.Kind {
    var unifiedDiffMarker: ClientUnifiedDiffLineMarker {
        switch self {
        case .added:
            .added
        case .removed:
            .removed
        case .context:
            .context
        }
    }
}

struct AteliaDiffScrollModel {
    static let minimumContentWidth: CGFloat = 960
    static let lineChromeWidth: CGFloat = 64
    static let hunkHeaderChromeWidth: CGFloat = 44
    static let fileHeaderChromeWidth: CGFloat = 144

    var files: [AteliaChangedFile]

    var allowsHorizontalScrolling: Bool { true }
    var allowsVerticalScrolling: Bool { true }
    var wrapsLines: Bool { false }

    var contentWidth: CGFloat {
        let diffMonospacedFont = AteliaClientFont.monospacedNSFont(size: 11)
        let lineWidth = files
            .flatMap(\.hunks)
            .flatMap(\.lines)
            .map { Self.renderedWidth(for: $0.text, font: diffMonospacedFont) + Self.lineChromeWidth }
            .max() ?? 0
        let hunkHeaderWidth = files
            .flatMap(\.hunks)
            .map { Self.renderedWidth(for: $0.header, font: diffMonospacedFont) + Self.hunkHeaderChromeWidth }
            .max() ?? 0
        let fileHeaderWidth = files
            .map { Self.renderedWidth(for: $0.path, font: .systemFont(ofSize: 12, weight: .medium)) + Self.fileHeaderChromeWidth }
            .max() ?? 0

        return ceil(max(Self.minimumContentWidth, lineWidth, hunkHeaderWidth, fileHeaderWidth))
    }

    private static func renderedWidth(for text: String, font: NSFont) -> CGFloat {
        (text as NSString).size(withAttributes: [.font: font]).width
    }
}
