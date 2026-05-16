import AppKit
import Foundation

@MainActor
enum ProjectFolderPicker {
    static func chooseExistingFolder() -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        panel.resolvesAliases = true
        panel.title = "既存のフォルダを使用"
        panel.message = "Atelia で使うフォルダを選択してください。"
        panel.prompt = "選択"

        return panel.runModal() == .OK ? panel.url : nil
    }
}
