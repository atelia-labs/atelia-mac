import Testing
@testable import AteliaMacCore

@Test func baselineFeaturesMatchDocumentedMacBaseline() {
    let initialIds = Set(MacClientFeature.initial.map(\.id))

    #expect(initialIds == Set([
        "project-space",
        "project-home",
        "project-conversation",
        "project-selection-onboarding",
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
        "atelia",
        "browser",
        "projects",
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

@Test func baselineInitSetsIdAndTitle() {
    let feature = MacClientFeature(id: "settings", title: "Settings")

    #expect(feature.id == "settings")
    #expect(feature.title == "Settings")
}

@Test func valueEqualityIncludesTitleAndDeprecatedScope() {
    let original = MacClientFeature(id: "settings", title: "Settings")
    let renamed = MacClientFeature(id: "settings", title: "Preferences")

    #expect(original != renamed)
    #expect(Set([original, renamed]).count == 2)
    #expect(original.sameIdentity(as: renamed))
}

@available(*, deprecated, message: "Exercises deprecated compatibility API.")
@Test func deprecatedInitialScopeCompatibilityPreservesReadWriteSemantics() {
    let baselineFeature = MacClientFeature(id: "settings", title: "Settings")
    var feature = MacClientFeature(id: "test", title: "Test", isInitialScope: false)
    let futureFeature = MacClientFeature(id: "test", title: "Test", isInitialScope: false)
    let initialFeature = MacClientFeature(id: "test", title: "Test", isInitialScope: true)

    #expect(baselineFeature.isInitialScope)
    #expect(!feature.isInitialScope)
    #expect(futureFeature != initialFeature)

    feature.isInitialScope = true
    #expect(feature.isInitialScope)
    #expect(feature == initialFeature)

    feature.isInitialScope = false

    #expect(!feature.isInitialScope)
}
