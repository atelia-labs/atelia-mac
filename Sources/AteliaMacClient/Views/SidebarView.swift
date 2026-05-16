import AteliaMacClientModels
import SwiftUI

enum SidebarAction {
    case command(id: String, surface: MockSurfaceReference, action: MockActionReference)
    case chatItem(id: String, projectID: String, resourceID: String, surface: MockSurfaceReference, action: MockActionReference)
}

struct SidebarView: View {
    let activeNavigationItemID: String
    let activeSurfaceID: String
    let groups: [WorkspaceGroup]
    let globalItems: [ChatListItem]
    var onAction: (SidebarAction) -> Void = { _ in }

    var body: some View {
        let selection = SidebarSelection(
            activeNavigationItemID: activeNavigationItemID,
            activeSurfaceID: activeSurfaceID
        )

        VStack(alignment: .leading, spacing: 0) {
            SidebarToolbar()
                .frame(height: 48)

            PrimaryNavigation(onAction: onAction)
                .padding(.top, 0)
                .padding(.bottom, 8)

            FadingSidebarScroll {
                VStack(alignment: .leading, spacing: 14) {
                    GlobalSecretaryView(items: globalItems, selection: selection, onAction: onAction)

                    SidebarSectionLabel(title: "プロジェクト")

                    ForEach(groups) { group in
                        WorkspaceGroupView(group: group, selection: selection, onAction: onAction)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.top, 12)
                .padding(.bottom, 20)
            }

            SettingsRow(onAction: onAction)
                .padding(.horizontal, 14)
                .frame(height: 54)
        }
        .frame(width: AteliaClientLayout.sidebarWidth)
        .background {
            SidebarBackground()
        }
    }
}

private struct SidebarSelection {
    let activeNavigationItemID: String
    let activeSurfaceID: String

    func contains(_ item: ChatListItem) -> Bool {
        if !activeNavigationItemID.isEmpty {
            return item.id == activeNavigationItemID
        }
        return item.surface.id == activeSurfaceID
    }
}

private struct SidebarBackground: View {
    var body: some View {
        VisualEffectView(material: .sidebar, blendingMode: .behindWindow)
            .overlay(Color.white.opacity(0.80))
    }
}

private struct SidebarSectionLabel: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.atelia(14.25))
            .foregroundStyle(Color.clientMutedText)
            .padding(.leading, 14)
            .frame(height: 32, alignment: .leading)
    }
}

private struct SidebarToolbar: View {
    var body: some View {
        HStack(spacing: 16) {
            Color.clear
                .frame(width: 70, height: 1)

            SidebarGlyph(.sidebar)
            SidebarGlyph(.back)
            SidebarGlyph(.forward)
        }
        .foregroundStyle(Color.clientSidebarIcon)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
    }
}

private struct FadingSidebarScroll<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            ClientScrollView {
                content
            }

            VStack(spacing: 0) {
                SidebarFadeOverlay(edge: .top)
                .frame(height: 32)

                Spacer(minLength: 0)

                SidebarFadeOverlay(edge: .bottom)
                .frame(height: 34)
            }
            .allowsHitTesting(false)
        }
        .clipped()
    }
}

private struct SidebarFadeOverlay: View {
    enum Edge {
        case top
        case bottom
    }

    let edge: Edge

    var body: some View {
        VisualEffectView(material: .sidebar, blendingMode: .behindWindow)
            .overlay(Color.white.opacity(0.80))
            .mask {
                LinearGradient(
                    colors: edge == .top ? [.black, .clear] : [.clear, .black],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
    }
}

private struct SidebarGlyph: View {
    enum Kind {
        case sidebar
        case back
        case forward
        case compose
        case search
        case plugins
        case automation
        case phone
        case folder
        case globe
        case gear
    }

    let kind: Kind

    init(_ kind: Kind) {
        self.kind = kind
    }

    var body: some View {
        Image(systemName: symbolName)
            .font(.system(size: symbolSize, weight: .regular))
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(Color.clientSidebarIcon)
            .frame(width: 18, height: 18)
            .accessibilityHidden(true)
    }

    private var symbolName: String {
        switch kind {
        case .sidebar:
            "sidebar.left"
        case .back:
            "chevron.left"
        case .forward:
            "chevron.right"
        case .compose:
            "square.and.pencil"
        case .search:
            "magnifyingglass"
        case .plugins:
            "circle.grid.2x2"
        case .automation:
            "clock"
        case .phone:
            "iphone"
        case .folder:
            "folder"
        case .globe:
            "globe"
        case .gear:
            "gearshape"
        }
    }

    private var symbolSize: CGFloat {
        switch kind {
        case .back, .forward:
            12.75
        case .sidebar:
            12.5
        case .folder, .globe:
            13.25
        default:
            13.75
        }
    }
}

private struct PrimaryNavigation: View {
    let onAction: (SidebarAction) -> Void

    private let commands = [
        SidebarCommand(
            id: "primary:new-thread",
            icon: SidebarGlyph.Kind.compose,
            title: "新しいスレッド",
            surface: .newThread,
            action: .startNewThread
        ),
        SidebarCommand(
            id: "primary:global-search",
            icon: .search,
            title: "検索",
            surface: .globalSearch,
            action: .searchAllProjects
        )
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(commands) { command in
                SidebarCommandRow(command: command, onAction: onAction)
            }
        }
    }
}

private struct WorkspaceGroupView: View {
    let group: WorkspaceGroup
    let selection: SidebarSelection
    let onAction: (SidebarAction) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 9) {
                SidebarGlyph(.folder)

                Text(group.title)
                    .font(.atelia(13.25))
                    .tracking(0.25)
                    .foregroundStyle(Color.clientSidebarText)
                    .lineLimit(1)

                if let subtitle = group.subtitle {
                    Text(subtitle)
                        .font(.atelia(12.25))
                        .tracking(0.25)
                        .foregroundStyle(Color.clientSubtleText)
                        .lineLimit(1)
                }

                Spacer()

                if group.status == .warning {
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: 10.5, weight: .regular))
                        .foregroundStyle(Color(hex: 0xff5f57))
                }
            }
            .frame(height: 32)
            .padding(.leading, 14)
            .padding(.trailing, 8)

            ForEach(group.items) { item in
                SidebarChatRow(item: item, isSelected: selection.contains(item), onAction: onAction)
            }

            if !group.settings.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    Rectangle()
                        .fill(Color.clientLineSoft)
                        .frame(height: 1)
                        .padding(.leading, 39)
                        .padding(.trailing, 8)
                        .padding(.bottom, 3)

                    Text("その他の設定")
                        .font(.atelia(12.75))
                        .tracking(0.25)
                        .foregroundStyle(Color.clientMutedText)
                        .padding(.leading, 39)
                        .frame(height: 29, alignment: .leading)

                    ForEach(group.settings) { item in
                        SidebarChatRow(item: item, isSelected: selection.contains(item), onAction: onAction)
                    }
                }
                .padding(.top, 2)
            }
        }
    }
}

private struct SidebarCommand: Identifiable {
    let id: String
    let icon: SidebarGlyph.Kind
    let title: String
    let surface: MockSurfaceReference
    let action: MockActionReference?
}

private struct SidebarCommandRow: View {
    let command: SidebarCommand
    let onAction: (SidebarAction) -> Void

    var body: some View {
        if let action = command.action {
            Button {
                onAction(.command(id: command.id, surface: command.surface, action: action))
            } label: {
                rowContent
            }
            .buttonStyle(.plain)
            .accessibilityLabel(command.title)
            .accessibilityHint("surface \(command.surface.id)")
        } else {
            rowContent
                .accessibilityElement(children: .combine)
                .accessibilityLabel(command.title)
        }
    }

    private var rowContent: some View {
        HStack(spacing: 9) {
            SidebarGlyph(command.icon)
                .offset(y: -1.25)

            Text(command.title)
                .font(.atelia(13.25))
                .tracking(0.25)
                .foregroundStyle(Color.clientSidebarText)
                .lineLimit(1)

            Spacer()
        }
        .frame(height: 32)
        .padding(.leading, 14)
        .padding(.trailing, 8)
        .padding(.horizontal, 6)
    }
}

private struct SidebarChatRow: View {
    let item: ChatListItem
    let isSelected: Bool
    let onAction: (SidebarAction) -> Void

    var body: some View {
        if let action = item.action {
            Button {
                onAction(.chatItem(
                    id: item.id,
                    projectID: item.projectID,
                    resourceID: item.resourceID,
                    surface: item.surface,
                    action: action
                ))
            } label: {
                rowContent
            }
            .buttonStyle(.plain)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityValue(isSelected ? "選択中" : "")
            .accessibilityHint("surface \(item.surface.id)")
        } else {
            rowContent
                .accessibilityElement(children: .combine)
                .accessibilityLabel(accessibilityLabel)
                .accessibilityValue(isSelected ? "選択中" : "")
        }
    }

    private var rowContent: some View {
        HStack(spacing: 9) {
            if let leadingPresentation = item.leadingAffordance?.presentation {
                Image(systemName: symbolName(for: leadingPresentation))
                    .font(.system(size: symbolSize(for: leadingPresentation), weight: .regular))
                    .foregroundStyle(Color.clientSidebarIcon)
                    .overlay(alignment: .bottomTrailing) {
                        if leadingPresentation == .statusDot {
                            Circle()
                                .fill(Color(hex: 0x34c759))
                                .frame(width: 5, height: 5)
                        }
                    }
                    .frame(width: 18, height: 18)
            } else {
                Color.clear.frame(width: 18, height: 18)
            }

            Text(item.title)
                .font(.atelia(13.25))
                .tracking(0.25)
                .foregroundStyle(isSelected ? Color.clientText : Color.clientSidebarText)
                .lineLimit(1)

            Spacer(minLength: 8)

            if let trailing = item.trailing {
                Text(trailing)
                    .font(.atelia(11.25))
                    .tracking(0.25)
                    .foregroundStyle(Color.clientMutedText)
                    .lineLimit(1)
            }
        }
        .frame(height: 32)
        .padding(.leading, 8)
        .padding(.trailing, 8)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(isSelected ? Color.clientSidebarSelected : .clear)
        )
        .padding(.leading, 6)
        .padding(.trailing, 8)
    }

    private var accessibilityLabel: String {
        if let trailing = item.trailing {
            "\(item.title), \(trailing)"
        } else {
            item.title
        }
    }

    private func symbolName(for presentation: LeadingAffordancePresentation) -> String {
        switch presentation {
        case .statusDot:
            "point.3.connected.trianglepath.dotted"
        case .assistantMark:
            "sparkles"
        case .branchGlyph:
            "arrow.triangle.branch"
        case .addGlyph:
            "plus.circle"
        }
    }

    private func symbolSize(for presentation: LeadingAffordancePresentation) -> CGFloat {
        switch presentation {
        case .statusDot:
            10
        case .assistantMark, .branchGlyph:
            12.25
        case .addGlyph:
            12
        }
    }
}

private struct GlobalSecretaryView: View {
    let items: [ChatListItem]
    let selection: SidebarSelection
    let onAction: (SidebarAction) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 9) {
                SidebarGlyph(.globe)

                Text("Global Secretary")
                    .font(.atelia(13.25))
                    .tracking(0.25)
                    .foregroundStyle(Color.clientSidebarText)

                Spacer()
            }
            .frame(height: 32)
            .padding(.leading, 14)
            .padding(.trailing, 8)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Global Secretary")

            Text("全プロジェクト")
                .font(.atelia(12.25))
                .tracking(0.25)
                .foregroundStyle(Color.clientMutedText)
                .padding(.leading, 39)
                .frame(height: 25, alignment: .leading)

            ForEach(items) { item in
                SidebarChatRow(item: item, isSelected: selection.contains(item), onAction: onAction)
            }
        }
        .padding(.top, 2)
    }
}

private struct SettingsRow: View {
    let onAction: (SidebarAction) -> Void

    private let command = SidebarCommand(
        id: "global:settings",
        icon: .gear,
        title: "設定",
        surface: .settings,
        action: .openProjectSettings
    )

    var body: some View {
        SidebarCommandRow(command: command, onAction: onAction)
    }
}
