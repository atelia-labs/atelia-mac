import Testing
@testable import AteliaMacCore

@Test func baselineFeaturesMatchDocumentedMacBaseline() {
    let initialIds = Set(MacClientFeature.initial.map(\.id))

    #expect(initialIds == Set([
        "project-space",
        "project-home",
        "project-conversation",
        "project-navigation",
        "secretary-connection",
        "permission-recovery",
        "package-management",
        "presentation-renderer",
        "settings"
    ]))
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
            $0.title == "Package installation, inspection, disabling, rollback, and safe mode"
    })
}

@Test func featureIdentityUsesIdOnly() {
    let original = MacClientFeature(id: "settings", title: "Settings")
    let renamed = MacClientFeature(id: "settings", title: "Preferences")

    #expect(original == renamed)
    #expect(Set([original, renamed]).count == 1)
}

@available(*, deprecated, message: "Exercises deprecated compatibility API.")
@Test func deprecatedInitialScopeCompatibilityAlwaysReportsBaselineScope() {
    let feature = MacClientFeature(id: "test", title: "Test", isInitialScope: false)

    #expect(feature.isInitialScope)
}
