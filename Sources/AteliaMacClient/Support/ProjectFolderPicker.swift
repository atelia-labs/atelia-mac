import AppKit
import Foundation

@MainActor
protocol ProjectFolderSelectionProviding {
    func chooseExistingFolder() -> URL?
    func createNewFolder() -> URL?
}

@MainActor
struct ProjectFolderPicker: ProjectFolderSelectionProviding {
    func chooseExistingFolder() -> URL? {
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

    func createNewFolder() -> URL? {
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.isExtensionHidden = true
        panel.nameFieldLabel = "フォルダ名"
        panel.nameFieldStringValue = "新しいプロジェクト"
        panel.title = "新規フォルダを作成"
        panel.message = "Atelia で使うフォルダ名と保存先を指定してください。"
        panel.prompt = "作成"

        guard panel.runModal() == .OK, let folderURL = panel.url else {
            return nil
        }

        do {
            return try ProjectFolderCreation.ensureDirectory(at: folderURL)
        } catch {
            NSAlert(error: error).runModal()
            return nil
        }
    }
}

enum ProjectFolderCreation {
    static func ensureDirectory(
        at url: URL,
        fileManager: FileManager = .default
    ) throws -> URL {
        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) {
            guard isDirectory.boolValue else {
                throw CocoaError(.fileWriteFileExists)
            }
            return url
        }

        try fileManager.createDirectory(
            at: url,
            withIntermediateDirectories: true,
            attributes: nil
        )
        return url
    }
}
