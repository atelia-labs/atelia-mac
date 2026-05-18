public enum ClientUnifiedDiffLineMarker: Sendable {
    case added
    case removed
    case context

    var character: Character {
        switch self {
        case .added:
            "+"
        case .removed:
            "-"
        case .context:
            " "
        }
    }
}

public enum ClientUnifiedDiffText {
    public static func normalized(_ text: String, marker: ClientUnifiedDiffLineMarker) -> String {
        guard text.first == marker.character else {
            return text
        }

        return String(text.dropFirst())
    }
}
