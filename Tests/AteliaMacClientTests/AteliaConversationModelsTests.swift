import AppKit
import Testing
@testable import AteliaMacClient

@Test func conversationReferenceFixtureUsesStableIdsAndSemanticStatus() {
    let conversation = AteliaConversation.mdpRenderingReference

    #expect(conversation.id == "conversation.mdp-rendering.reference")
    #expect(conversation.turns.map(\.id) == [
        "turn.user.package-mdp-request",
        "turn.secretary.audit"
    ])
    #expect(Set(conversation.turns.map(\.id)).count == conversation.turns.count)

    let blocks = conversation.turns.flatMap(\.blocks)
    #expect(blocks.map(\.id) == [
        "message.user.package-mdp-request",
        "activity.secretary.audit",
        "tool.output.swift-build",
        "change-set.conversation-mdp-rendering"
    ])
    #expect(Set(blocks.map(\.id)).count == blocks.count)

    guard case .activity(let activity) = blocks[1] else {
        Issue.record("Expected the second reference block to be activity.")
        return
    }
    #expect(activity.status == "完了")
}

@Test func conversationBlockIdsForwardWrappedModelIds() {
    let message = AteliaMessageBlock(id: "message.id", text: "Message", attachmentName: nil)
    let activity = AteliaActivityBlock(id: "activity.id", duration: "1s", status: "完了", title: "Done", bullets: [])
    let toolOutput = AteliaToolOutputBlock(id: "tool.id", toolName: "swift test", command: "swift test", status: .running, output: [])
    let changeSet = AteliaChangeSetBlock(id: "change.id", title: "Change", summary: "Summary", files: [])

    #expect(AteliaConversationBlock.message(message).id == message.id)
    #expect(AteliaConversationBlock.activity(activity).id == activity.id)
    #expect(AteliaConversationBlock.toolOutput(toolOutput).id == toolOutput.id)
    #expect(AteliaConversationBlock.changeSet(changeSet).id == changeSet.id)
}

@Test func diffLineFactoriesNormalizeUnifiedDiffMarkers() {
    let added = AteliaDiffLine.added(id: "line.added", "+let next = value")
    let removed = AteliaDiffLine.removed(id: "line.removed", "-let old = value")
    let context = AteliaDiffLine.context(id: "line.context", " let stable = value")

    #expect(added.marker == "+")
    #expect(added.text == "let next = value")
    #expect(removed.marker == "-")
    #expect(removed.text == "let old = value")
    #expect(context.marker == " ")
    #expect(context.text == "let stable = value")
}

@Test func conversationReferenceDiffLinesCarryIdsWithoutEmbeddedMarkers() {
    let changeSets = AteliaConversation.mdpRenderingReference.turns
        .flatMap(\.blocks)
        .compactMap { block -> AteliaChangeSetBlock? in
            guard case .changeSet(let changeSet) = block else {
                return nil
            }
            return changeSet
        }
    let files = changeSets.flatMap(\.files)
    let hunks = files.flatMap(\.hunks)
    let lines = hunks.flatMap(\.lines)

    #expect(files.allSatisfy { !$0.id.isEmpty })
    #expect(hunks.allSatisfy { !$0.id.isEmpty })
    #expect(lines.allSatisfy { !$0.id.isEmpty })
    #expect(Set(lines.map(\.id)).count == lines.count)

    for line in lines {
        switch line.kind {
        case .added:
            #expect(!line.text.hasPrefix("+"))
        case .removed:
            #expect(!line.text.hasPrefix("-"))
        case .context:
            #expect(!line.text.hasPrefix(" "))
        }
    }
}

@Test func monospacedClientFontUsesBundledPostScriptName() {
    ClientFontRegistrar.registerBundledFonts()

    let font = AteliaClientFont.monospacedNSFont(size: 12)

    #expect(font.fontName == ClientFontRegistrar.jetBrainsMonoRegularPostScriptName)
}
