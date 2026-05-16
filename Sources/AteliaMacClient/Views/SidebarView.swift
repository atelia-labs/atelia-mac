import AteliaMacClientModels
import SwiftUI

enum SidebarAction {
    case command(id: String, title: String, surface: MockSurfaceReference, action: MockActionReference)
    case chatItem(id: String, projectID: String, resourceID: String, title: String, surface: MockSurfaceReference, action: MockActionReference)
    case projectSectionHeaderAction(ProjectSectionHeaderActionViewData)
    case dismissProjectAddCandidate
}

struct SidebarView: View {
    let activeSelection: ClientMockActiveSelection
    let activeNavigationItemID: String
    let activePrimaryCommandID: String?
    let projectSectionHeader: ProjectSectionHeaderViewData
    let projectAddCandidateLabel: String?
    let groups: [WorkspaceGroup]
    let globalItems: [ChatListItem]
    var onAction: (SidebarAction) -> Void = { _ in }

    var body: some View {
        let selection = SidebarSelection(
            activeSelection: activeSelection,
            activeNavigationItemID: activeNavigationItemID
        )

        VStack(alignment: .leading, spacing: 0) {
            SidebarToolbar()
                .frame(height: 48)

            PrimaryNavigation(activePrimaryCommandID: activePrimaryCommandID, onAction: onAction)
                .padding(.top, 0)
                .padding(.bottom, 8)

            FadingSidebarScroll {
                VStack(alignment: .leading, spacing: 14) {
                    GlobalSecretaryView(items: globalItems, selection: selection, onAction: onAction)

                    ProjectSectionHeaderView(
                        header: projectSectionHeader,
                        onAction: onAction
                    )

                    if let projectAddCandidateLabel {
                        ProjectAddCandidateView(label: projectAddCandidateLabel) {
                            onAction(.dismissProjectAddCandidate)
                        }
                    }

                    ForEach(groups) { group in
                        WorkspaceGroupView(group: group, selection: selection, onAction: onAction)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.top, 12)
                .padding(.bottom, 20)
            }

            SettingsRow(isSelected: activeNavigationItemID == "global:settings", onAction: onAction)
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
    let activeSelection: ClientMockActiveSelection
    let activeNavigationItemID: String

    func contains(_ item: ChatListItem) -> Bool {
        if !activeNavigationItemID.isEmpty {
            return item.id == activeNavigationItemID
        }
        return activeSelection.matches(item)
    }
}

private struct SidebarBackground: View {
    var body: some View {
        VisualEffectView(material: .sidebar, blendingMode: .behindWindow)
            .overlay(Color.white.opacity(0.80))
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
        case folderAdd
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
        case .folderAdd:
            "folder.badge.plus"
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
        case .folder, .folderAdd, .globe:
            13.25
        default:
            13.75
        }
    }
}

private struct PrimaryNavigation: View {
    let activePrimaryCommandID: String?
    let onAction: (SidebarAction) -> Void

    private let commands = [
        SidebarCommand(
            id: "primary:new-thread",
            title: "新しいスレッド",
            icon: SidebarGlyph.Kind.compose,
            surface: .projectConversation,
            action: .startNewThread
        ),
        SidebarCommand(
            id: "primary:global-search",
            title: "検索",
            icon: .search,
            surface: .globalSearch,
            action: .searchAllProjects
        )
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(commands) { command in
                SidebarCommandRow(
                    command: command,
                    isSelected: activePrimaryCommandID == command.id,
                    onAction: onAction
                )
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
    let title: String
    let icon: SidebarGlyph.Kind
    let surface: MockSurfaceReference
    let action: MockActionReference?
}

private struct SidebarCommandRow: View {
    let command: SidebarCommand
    let isSelected: Bool
    let onAction: (SidebarAction) -> Void

    var body: some View {
        if let action = command.action {
            Button {
                onAction(.command(id: command.id, title: command.title, surface: command.surface, action: action))
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
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(isSelected ? Color.clientSidebarSelected : .clear)
        )
        .padding(.leading, 6)
        .padding(.trailing, 8)
    }
}

private struct SidebarChatRow: View {
    let item: ChatListItem
    let isSelected: Bool
    let onAction: (SidebarAction) -> Void

    private var isPlaceholder: Bool {
        item.action == nil
    }

    var body: some View {
        if let action = item.action {
            Button {
                onAction(.chatItem(
                    id: item.id,
                    projectID: item.projectID,
                    resourceID: item.resourceID,
                    title: item.title,
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
                .accessibilityHint("準備中の項目です")
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
                .foregroundStyle(
                    isPlaceholder
                        ? Color.clientSubtleText
                        : (isSelected ? Color.clientText : Color.clientSidebarText)
                )
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

private struct ProjectSectionHeaderView: View {
    let header: ProjectSectionHeaderViewData
    let onAction: (SidebarAction) -> Void
    @State private var isHovered = false
    @FocusState private var isFocused: Bool

    var body: some View {
        let isProjectAddMenuVisible = isHovered || isFocused

        HStack(spacing: 8) {
            Text(header.title)
                .font(.atelia(14.25))
                .foregroundStyle(Color.clientMutedText)
                .lineLimit(1)

            Spacer(minLength: 8)

            if !header.actions.isEmpty {
                Menu {
                    ForEach(header.actions) { action in
                        Button {
                            onAction(.projectSectionHeaderAction(action))
                        } label: {
                            Label(action.title, systemImage: action.symbolName)
                        }
                        .accessibilityLabel(action.accessibilityLabel)
                    }
                } label: {
                    SidebarGlyph(.folderAdd)
                        .frame(width: 22, height: 22)
                }
                .menuStyle(.borderlessButton)
                .focused($isFocused)
                .opacity(isProjectAddMenuVisible ? 1 : 0)
                .allowsHitTesting(isProjectAddMenuVisible)
                .accessibilityHidden(!isProjectAddMenuVisible)
                .accessibilityLabel("プロジェクトを追加")
            }
        }
        .frame(height: 32)
        .padding(.leading, 14)
        .padding(.trailing, 8)
        .projectSectionHeaderAccessibilityActions(header: header, onAction: onAction)
        .onHover { hovered in
            withAnimation(.easeOut(duration: 0.12)) {
                isHovered = hovered
            }
        }
    }
}

private extension View {
    @ViewBuilder
    func projectSectionHeaderAccessibilityActions(
        header: ProjectSectionHeaderViewData,
        onAction: @escaping (SidebarAction) -> Void
    ) -> some View {
        if header.actions.isEmpty {
            self
        } else {
            self
                .accessibilityElement(children: .combine)
                .accessibilityLabel(header.title)
                .accessibilityAction(named: Text("新規フォルダを作成")) {
                    if let action = header.actions.first(where: { $0.kind == .createFolder }) {
                        onAction(.projectSectionHeaderAction(action))
                    }
                }
                .accessibilityAction(named: Text("既存のフォルダを使用")) {
                    if let action = header.actions.first(where: { $0.kind == .useExistingFolder }) {
                        onAction(.projectSectionHeaderAction(action))
                    }
                }
        }
    }
}

private struct ProjectAddCandidateView: View {
    let label: String
    let onDismiss: () -> Void

    private let dismissButtonSize: CGFloat = 16

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 8) {
                    SidebarGlyph(.folderAdd)

                    Text("追加候補")
                        .font(.atelia(12.25))
                        .tracking(0.25)
                        .foregroundStyle(Color.clientMutedText)

                    Text(label)
                        .font(.atelia(12.25))
                        .tracking(0.25)
                        .foregroundStyle(Color.clientSidebarText)
                        .lineLimit(1)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("追加候補")
                .accessibilityValue(label)
                .accessibilityHint("選択中のフォルダ候補")
            }

            Spacer(minLength: 0)

            Button(action: onDismiss) {
                Image(systemName: "xmark.circle")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(Color.clientMutedText)
                    .frame(width: dismissButtonSize, height: dismissButtonSize)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("候補を閉じる")
            .accessibilityHint("追加候補を非表示にします")
        }
        .frame(height: 26)
        .padding(.leading, 14)
        .padding(.trailing, 8)
    }
}

private struct SettingsRow: View {
    let isSelected: Bool
    let onAction: (SidebarAction) -> Void

    private let command = SidebarCommand(
        id: "global:settings",
        title: "設定",
        icon: .gear,
        surface: .settings,
        action: .openProjectSettings
    )

    var body: some View {
        SidebarCommandRow(command: command, isSelected: isSelected, onAction: onAction)
    }
}
