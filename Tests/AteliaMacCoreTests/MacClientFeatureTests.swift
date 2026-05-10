import Testing
@testable import AteliaMacCore

@Test func initialScopeMatchesDocumentedMacBaseline() {
    let initialIds = Set(MacClientFeature.initial.map(\.id))

    #expect(initialIds == [
        "project-space",
        "project-home",
        "project-conversation",
        "project-navigation",
        "secretary-connection",
        "permission-recovery",
        "package-management",
        "presentation-renderer",
        "settings"
    ])
}

@Test func richProductAreasAreNotInitialClientCore() {
    let initialIds = Set(MacClientFeature.initial.map(\.id))

    #expect(initialIds.isDisjoint(with: [
        "browser",
        "git",
        "terminal",
        "voice",
        "extensions"
    ]))
}

@Test func packageManagementIncludesSafeMode() {
    #expect(MacClientFeature.initial.contains {
        $0.id == "package-management" &&
            $0.title.contains("safe mode")
    })
}
