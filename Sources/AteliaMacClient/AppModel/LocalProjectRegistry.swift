import Foundation

struct LocalProjectRegistration: Codable, Equatable, Identifiable, Sendable {
    var id: String
    var displayName: String
    var rootPath: String
    var source: ProjectAddSelection.Source

    var projectID: String {
        "project:\(id)"
    }

    var subtitle: String? {
        let lastPathComponent = URL(fileURLWithPath: rootPath).lastPathComponent
        return lastPathComponent.isEmpty ? nil : lastPathComponent
    }

    static func make(folderURL: URL, source: ProjectAddSelection.Source) -> LocalProjectRegistration {
        let standardizedURL = folderURL.standardizedFileURL
        let path = standardizedURL.path
        let folderName = standardizedURL.lastPathComponent
        return LocalProjectRegistration(
            id: Self.stableProjectID(forPath: path),
            displayName: folderName.isEmpty ? path : folderName,
            rootPath: path,
            source: source
        )
    }

    private static func stableProjectID(forPath path: String) -> String {
        let normalizedPath = path.precomposedStringWithCanonicalMapping
        var hash: UInt64 = 0xcbf29ce484222325

        for byte in normalizedPath.utf8 {
            hash ^= UInt64(byte)
            hash &*= 0x100000001b3
        }

        return "local_\(String(hash, radix: 16))"
    }
}

@MainActor
protocol LocalProjectRegistry: AnyObject {
    func listProjects() -> [LocalProjectRegistration]
    @discardableResult
    func registerProject(folderURL: URL, source: ProjectAddSelection.Source) -> LocalProjectRegistration
    func clearProjects()
}

@MainActor
final class UserDefaultsLocalProjectRegistry: LocalProjectRegistry {
    private let defaults: UserDefaults
    private let key: String

    init(
        defaults: UserDefaults = .standard,
        key: String = "atelia.mac.client.local-projects.v1"
    ) {
        self.defaults = defaults
        self.key = key
    }

    func listProjects() -> [LocalProjectRegistration] {
        guard let data = defaults.data(forKey: key) else {
            return []
        }

        return (try? JSONDecoder().decode([LocalProjectRegistration].self, from: data)) ?? []
    }

    @discardableResult
    func registerProject(folderURL: URL, source: ProjectAddSelection.Source) -> LocalProjectRegistration {
        let project = LocalProjectRegistration.make(folderURL: folderURL, source: source)
        var projects = listProjects().filter { $0.id != project.id }
        projects.append(project)
        persist(projects)
        return project
    }

    func clearProjects() {
        defaults.removeObject(forKey: key)
    }

    private func persist(_ projects: [LocalProjectRegistration]) {
        guard let data = try? JSONEncoder().encode(projects) else {
            return
        }

        defaults.set(data, forKey: key)
    }
}

@MainActor
final class InMemoryLocalProjectRegistry: LocalProjectRegistry {
    private var projects: [LocalProjectRegistration]

    init(projects: [LocalProjectRegistration] = []) {
        self.projects = projects
    }

    func listProjects() -> [LocalProjectRegistration] {
        projects
    }

    @discardableResult
    func registerProject(folderURL: URL, source: ProjectAddSelection.Source) -> LocalProjectRegistration {
        let project = LocalProjectRegistration.make(folderURL: folderURL, source: source)
        projects.removeAll { $0.id == project.id }
        projects.append(project)
        return project
    }

    func clearProjects() {
        projects = []
    }
}
