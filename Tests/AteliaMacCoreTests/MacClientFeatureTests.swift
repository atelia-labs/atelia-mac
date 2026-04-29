import Testing
@testable import AteliaMacCore

@Test func initialScopeIncludesGitSurface() {
    #expect(MacClientFeature.initial.contains { $0.id == "git" && $0.isInitialScope })
}

@Test func initialScopeIncludesWorkplaceSurfaces() {
    #expect(MacClientFeature.initial.contains { $0.id == "atelia" && $0.title == "Atelia surface" && $0.isInitialScope })
    #expect(MacClientFeature.initial.contains { $0.id == "extensions" && $0.isInitialScope })
}

@Test func initialScopeIncludesVoiceOperation() {
    #expect(MacClientFeature.initial.contains { $0.id == "voice" && $0.title == "Voice operation" && $0.isInitialScope })
}
