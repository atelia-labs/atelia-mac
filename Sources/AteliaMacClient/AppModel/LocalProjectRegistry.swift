import Foundation
import os

enum LocalProjectRegistrationSource: String, Codable, Equatable, Sendable {
    case newFolder
    case existingFolder
}

struct LocalProjectRegistration: Codable, Equatable, Identifiable, Sendable {
    var id: String
    var displayName: String
    var rootPath: String
    var source: LocalProjectRegistrationSource

    var projectID: String {
        "project:\(id)"
    }

    var subtitle: String? {
        let lastPathComponent = URL(fileURLWithPath: rootPath).lastPathComponent
        return lastPathComponent.isEmpty ? nil : lastPathComponent
    }

    var normalizedRootPath: String {
        Self.normalizedRootPath(rootPath)
    }

    static func make(folderURL: URL, source: LocalProjectRegistrationSource) -> LocalProjectRegistration {
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

    static func normalizedRootPath(_ path: String) -> String {
        URL(fileURLWithPath: path).standardizedFileURL.path.precomposedStringWithCanonicalMapping
    }

    func hasSameRootPath(as path: String) -> Bool {
        normalizedRootPath == Self.normalizedRootPath(path)
    }

    private static func stableProjectID(forPath path: String) -> String {
        // FNV-1a is only for stable local IDs; backend registration must replace this identity.
        let fnvOffsetBasis: UInt64 = 0xcbf29ce484222325
        let fnvPrime: UInt64 = 0x100000001b3
        let normalizedPath = Self.normalizedRootPath(path)
        var hash = fnvOffsetBasis

        for byte in normalizedPath.utf8 {
            hash ^= UInt64(byte)
            hash &*= fnvPrime
        }

        return "local_\(String(hash, radix: 16))"
    }
}

@MainActor
protocol LocalProjectRegistry: AnyObject {
    func listProjects() -> [LocalProjectRegistration]
    @discardableResult
    func registerProject(folderURL: URL, source: LocalProjectRegistrationSource) -> LocalProjectRegistration
    @discardableResult
    func removeProject(id: String) -> Bool
    func clearProjects()
}

@MainActor
final class UserDefaultsLocalProjectRegistry: LocalProjectRegistry {
    private let defaults: UserDefaults
    private let key: String
    private static let logger = Logger(subsystem: "com.atelia.mac.client", category: "LocalProjectRegistry")

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
    func registerProject(folderURL: URL, source: LocalProjectRegistrationSource) -> LocalProjectRegistration {
        let project = LocalProjectRegistration.make(folderURL: folderURL, source: source)
        var projects = listProjects().filter { $0.id != project.id }
        projects.append(project)
        persist(projects)
        return project
    }

    @discardableResult
    func removeProject(id: String) -> Bool {
        let projects = listProjects()
        let remainingProjects = projects.filter { $0.id != id }
        guard remainingProjects.count != projects.count else {
            return false
        }

        persist(remainingProjects)
        return true
    }

    func clearProjects() {
        defaults.removeObject(forKey: key)
    }

    private func persist(_ projects: [LocalProjectRegistration]) {
        do {
            let data = try JSONEncoder().encode(projects)
            defaults.set(data, forKey: key)
        } catch {
            Self.logger.error("Failed to persist local project registry: \(error.localizedDescription, privacy: .public)")
            #if DEBUG
            assertionFailure("Failed to persist local project registry: \(error)")
            #endif
        }
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
    func registerProject(folderURL: URL, source: LocalProjectRegistrationSource) -> LocalProjectRegistration {
        let project = LocalProjectRegistration.make(folderURL: folderURL, source: source)
        projects.removeAll { $0.id == project.id }
        projects.append(project)
        return project
    }

    @discardableResult
    func removeProject(id: String) -> Bool {
        let originalCount = projects.count
        projects.removeAll { $0.id == id }
        return projects.count != originalCount
    }

    func clearProjects() {
        projects = []
    }
}
