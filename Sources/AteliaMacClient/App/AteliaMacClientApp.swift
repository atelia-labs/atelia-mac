import AteliaMacCore
import SwiftUI

@main
struct AteliaMacClientApp: App {
    var body: some Scene {
        WindowGroup {
            ClientBootstrapView()
                .frame(minWidth: 960, minHeight: 640)
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
                .font(.system(size: 22, weight: .medium))

            Text("Client shell bootstrap")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)

            Text("Core features: \(featureSummary)")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.background)
    }
}
