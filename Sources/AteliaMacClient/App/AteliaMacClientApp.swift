import AteliaMacClientModels
import AteliaMacCore
import SwiftUI

@main
struct AteliaMacClientApp: App {
    init() {
        ClientFontRegistrar.registerBundledFonts()
    }

    var body: some Scene {
        WindowGroup {
            ClientShellView(state: .ateliaReference)
                .frame(minWidth: 960, minHeight: 640)
                .preferredColorScheme(AteliaClientDesign.supportsLightColorSchemeOnly ? .light : nil)
        }
        .windowStyle(.hiddenTitleBar)
    }
}

private struct ClientBootstrapView: View {
    private var featureSummary: String {
        MacClientFeature.initial.map(\.title).joined(separator: ", ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Atelia Mac")
                .font(.atelia(22, weight: .medium))
                .foregroundStyle(Color.clientStrongText)

            Text("Client shell bootstrap")
                .font(.atelia(14))
                .foregroundStyle(Color.clientMutedText)

            Text("Core features: \(featureSummary)")
                .font(.atelia(12))
                .foregroundStyle(Color.clientSubtleText)
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.clientSurfaceSofter)
    }
}
