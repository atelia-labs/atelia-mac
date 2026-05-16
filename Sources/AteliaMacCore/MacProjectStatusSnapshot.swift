import AteliaKit

/// Mac-facing projection of a shared project-status snapshot.
public struct MacProjectStatusSnapshot: Sendable, Equatable {
    /// Compact summary for a recent job row.
    public struct RecentJobSummary: Sendable, Equatable, Identifiable {
        public let id: String
        public let statusLabel: String
        public let requesterLabel: String
        public let kindLabel: String
        public let goalLabel: String
        public let latestEventId: String?

        init(job: AteliaJob) {
            self.id = job.jobId
            self.statusLabel = Self.statusLabel(for: job.status)
            self.requesterLabel = Self.requesterLabel(for: job.requester)
            self.kindLabel = job.kind
            self.goalLabel = job.goal
            self.latestEventId = job.latestEventId
        }

        private static func statusLabel(for status: AteliaJob.Status) -> String {
            switch status {
            case .queued:
                return "Queued"
            case .running:
                return "Running"
            case .succeeded:
                return "Succeeded"
            case .failed:
                return "Failed"
            case .blocked:
                return "Blocked"
            case .canceled:
                return "Canceled"
            case .unknown:
                return "Unknown"
            case .unrecognized(let rawValue):
                return "Unknown: \(rawValue)"
            }
        }

        private static func requesterLabel(for requester: AteliaActor) -> String {
            switch requester {
            case .user(_, let displayName):
                if let displayName, !displayName.isEmpty {
                    return displayName
                }
                return "User"
            case .agent(_, let displayName):
                if let displayName, !displayName.isEmpty {
                    return displayName
                }
                return "Agent"
            case .extension(let id):
                return "Extension \(id)"
            case .system(let id):
                return "System \(id)"
            case .unknown(let rawValue, let id, let displayName):
                if let displayName, !displayName.isEmpty {
                    return displayName
                }
                return "Unknown \(rawValue) \(id)"
            }
        }
    }

    /// Compact summary for a recent policy-decision row.
    public struct RecentPolicyDecisionSummary: Sendable, Equatable, Identifiable {
        public let id: String
        public let outcomeLabel: String
        public let riskTierLabel: String
        public let requestedCapabilityLabel: String
        public let reasonCodeLabel: String
        public let reasonLabel: String

        init(policyDecision: AteliaPolicyDecision) {
            self.id = policyDecision.decisionId
            self.outcomeLabel = Self.outcomeLabel(for: policyDecision.outcome)
            self.riskTierLabel = policyDecision.riskTier.rawValue
            self.requestedCapabilityLabel = policyDecision.requestedCapability
            self.reasonCodeLabel = policyDecision.reasonCode
            self.reasonLabel = policyDecision.reason
        }

        private static func outcomeLabel(for outcome: AteliaPolicyDecision.Outcome) -> String {
            switch outcome {
            case .allowed:
                return "Allowed"
            case .audited:
                return "Audited"
            case .needsApproval:
                return "Needs approval"
            case .blocked:
                return "Blocked"
            case .unknown(let rawValue):
                return "Unknown: \(rawValue)"
            }
        }
    }

    /// Repository identifier carried by Secretary.
    public let repositoryId: String
    /// Repository display name from the shared project-status model.
    public let repositoryDisplayName: String
    /// Repository root path from the shared project-status model.
    public let repositoryRootPath: String
    /// Latest daemon label for presentation surfaces.
    public let daemonLabel: String
    /// Whether the daemon reports typed readiness.
    public let isDaemonReady: Bool
    /// Latest storage label for presentation surfaces.
    public let storageLabel: String
    /// Whether storage reports typed readiness.
    public let isStorageReady: Bool
    /// Whether daemon and storage are both ready.
    public let isReady: Bool
    /// Latest event cursor, if available.
    public let latestCursor: AteliaEventCursor?
    /// Presentation-safe cursor label, if available.
    public let latestCursorLabel: String?
    /// Recent job summaries in response order.
    public let recentJobs: [RecentJobSummary]
    /// Recent policy-decision summaries in response order.
    public let recentPolicyDecisions: [RecentPolicyDecisionSummary]

    /// Creates a Mac project-status snapshot from the shared AteliaKit model.
    public init(status: AteliaProjectStatus) {
        self.repositoryId = status.repository.repositoryId
        self.repositoryDisplayName = status.repository.displayName
        self.repositoryRootPath = status.repository.rootPath
        self.daemonLabel = Self.label(
            prefix: "Daemon",
            version: status.metadata.daemonVersion,
            status: Self.daemonStatusLabel(for: status.daemonStatus)
        )
        self.isDaemonReady = status.daemonStatus == .ready
        self.storageLabel = Self.label(
            prefix: "Storage",
            version: status.metadata.storageVersion,
            status: Self.storageStatusLabel(for: status.storageStatus)
        )
        self.isStorageReady = status.storageStatus == .ready
        self.isReady = isDaemonReady && isStorageReady
        self.latestCursor = status.latestCursor
        self.latestCursorLabel = status.latestCursor.map(Self.latestCursorLabel(for:))
        self.recentJobs = status.recentJobs.map(RecentJobSummary.init(job:))
        self.recentPolicyDecisions = status.recentPolicyDecisions.map(RecentPolicyDecisionSummary.init(policyDecision:))
    }

    private static func label(prefix: String, version: String, status: String) -> String {
        "\(prefix) \(version) | \(status)"
    }

    private static func daemonStatusLabel(for status: AteliaHealthResponse.DaemonStatus) -> String {
        switch status {
        case .starting:
            return "Starting"
        case .running:
            return "Running"
        case .ready:
            return "Ready"
        case .degraded:
            return "Degraded"
        case .stopping:
            return "Stopping"
        case .unknown(let rawValue):
            return "Unknown: \(rawValue)"
        }
    }

    private static func storageStatusLabel(for status: AteliaHealthResponse.StorageStatus) -> String {
        switch status {
        case .ready:
            return "Ready"
        case .migrating:
            return "Migrating"
        case .readOnly:
            return "Read-only"
        case .unavailable:
            return "Unavailable"
        case .unknown(let rawValue):
            return "Unknown: \(rawValue)"
        }
    }

    private static func latestCursorLabel(for cursor: AteliaEventCursor) -> String {
        "Sequence \(cursor.sequence) | Event \(cursor.eventId)"
    }
}
