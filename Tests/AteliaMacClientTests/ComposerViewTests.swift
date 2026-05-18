import AteliaMacClientModels
import Testing
@testable import AteliaMacClient

@Test func composerVisibleContextSelectionsSeedSendContract() {
    let configuration = ComposerConfiguration(
        routeKey: "composer:test",
        selectedModel: ComposerModelSelection(displayName: "Test"),
        permissionMode: ComposerPermissionMode(displayName: "Allowed"),
        contextReferences: [
            ComposerContextReference(
                id: "context:file:brief",
                kind: .file,
                title: "ファイル",
                subtitle: "brief.md",
                systemImageName: "paperclip"
            ),
            ComposerContextReference(
                id: "context:extension:review",
                kind: .packageExtension,
                title: "拡張機能",
                subtitle: "review",
                systemImageName: "puzzlepiece.extension"
            )
        ],
        attachmentPreview: ComposerAttachmentPreview(
            id: "attachment:brief",
            contextReferenceID: "context:file:brief",
            title: "brief.md",
            subtitle: "ファイル文脈"
        )
    )

    #expect(configuration.visibleContextSelections == [
        ComposerContextSelection(id: "context:file:brief", kind: .file),
        ComposerContextSelection(id: "context:extension:review", kind: .packageExtension)
    ])
}

@Test func composerVisibleContextSelectionsDoNotDuplicateAttachmentContext() {
    let state = ClientMockState.ateliaReference

    #expect(state.composer.attachmentPreview?.contextReferenceID == "context:file:standard-surfaces")
    #expect(state.composer.visibleContextSelections == [
        ComposerContextSelection(id: "context:file:standard-surfaces", kind: .file),
        ComposerContextSelection(id: "context:extension:surface-protocol", kind: .packageExtension)
    ])
}

@Test func composerVisibleContextSelectionsIncludeStandaloneAttachmentPreview() {
    let configuration = ComposerConfiguration(
        routeKey: "composer:test",
        selectedModel: ComposerModelSelection(displayName: "Test"),
        permissionMode: ComposerPermissionMode(displayName: "Allowed"),
        attachmentPreview: ComposerAttachmentPreview(
            id: "attachment:standalone",
            title: "standalone.md",
            subtitle: "ファイル文脈"
        )
    )

    #expect(configuration.visibleContextSelections == [
        ComposerContextSelection(id: "attachment:standalone", kind: .file)
    ])
}

@Test func composerAttachmentVisibilityFollowsCurrentConfigurationOrOverride() {
    let emptyConfiguration = ComposerConfiguration(
        routeKey: "composer:test",
        selectedModel: ComposerModelSelection(displayName: "Test"),
        permissionMode: ComposerPermissionMode(displayName: "Allowed")
    )
    let attachmentConfiguration = ComposerConfiguration(
        routeKey: "composer:test",
        selectedModel: ComposerModelSelection(displayName: "Test"),
        permissionMode: ComposerPermissionMode(displayName: "Allowed"),
        attachmentPreview: ComposerAttachmentPreview(
            id: "attachment:standalone",
            title: "standalone.md",
            subtitle: "ファイル文脈"
        )
    )

    #expect(!composerShowsAttachment(hasAttachment: false, configuration: emptyConfiguration))
    #expect(composerShowsAttachment(hasAttachment: true, configuration: emptyConfiguration))
    #expect(composerShowsAttachment(hasAttachment: false, configuration: attachmentConfiguration))
}

@Test func composerInsertMentionNormalizesSpacingForEmptyDraft() {
    #expect(
        composerTextAfterInsertingMention(draftText: "", mention: "@Secretary") == "@Secretary "
    )
}

@Test func composerInsertMentionAddsOneSpaceForNonWhitespaceSuffix() {
    #expect(
        composerTextAfterInsertingMention(draftText: "analyze", mention: "@Secretary")
            == "analyze @Secretary "
    )
}

@Test func composerInsertMentionNormalizesSingleOrMultipleTrailingWhitespace() {
    #expect(
        composerTextAfterInsertingMention(draftText: "analyze ", mention: "@Secretary")
            == "analyze @Secretary "
    )
    #expect(
        composerTextAfterInsertingMention(draftText: "analyze  ", mention: "@Secretary")
            == "analyze @Secretary "
    )
}
