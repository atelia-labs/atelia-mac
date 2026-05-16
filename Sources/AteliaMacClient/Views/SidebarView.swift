import AteliaMacClientModels
import SwiftUI

struct SidebarView: View {
    let activeTitle: String
    let groups: [WorkspaceGroup]
    let globalItems: [ChatListItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SidebarToolbar()
                .frame(height: 48)

            PrimaryNavigation()
                .padding(.top, 0)
                .padding(.bottom, 8)

            FadingSidebarScroll {
                VStack(alignment: .leading, spacing: 14) {
                    GlobalSecretaryView(items: globalItems)

                    SidebarSectionLabel(title: "プロジェクト")

                    ForEach(groups) { group in
                        WorkspaceGroupView(group: group)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.top, 12)
                .padding(.bottom, 20)
            }

            SettingsRow()
                .padding(.horizontal, 14)
                .frame(height: 54)
        }
        .frame(width: CodexLayout.sidebarWidth)
        .background {
            SidebarBackground()
        }
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
    private let rows = [
        (SidebarGlyph.Kind.compose, "新しいスレッド"),
        (.search, "検索")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(rows, id: \.1) { icon, title in
                SidebarRow(icon: icon, title: title)
            }
        }
    }
}

private struct WorkspaceGroupView: View {
    let group: WorkspaceGroup

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
                SidebarChatRow(item: item)
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
                        SidebarChatRow(item: item)
                    }
                }
                .padding(.top, 2)
            }
        }
    }
}

private struct SidebarRow: View {
    let icon: SidebarGlyph.Kind
    let title: String

    var body: some View {
        HStack(spacing: 9) {
            SidebarGlyph(icon)
                .offset(y: -1.25)

            Text(title)
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
    }
}

private struct SidebarChatRow: View {
    let item: ChatListItem

    var body: some View {
        HStack(spacing: 9) {
            if let leadingStatus = item.leadingStatus {
                Image(systemName: symbolName(for: leadingStatus))
                    .font(.system(size: symbolSize(for: leadingStatus), weight: .regular))
                    .foregroundStyle(Color.clientSidebarIcon)
                    .overlay(alignment: .bottomTrailing) {
                        if leadingStatus == .green {
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
                .foregroundStyle(item.isSelected ? Color.clientText : Color.clientSidebarText)
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
                .fill(item.isSelected ? Color.clientSidebarSelected : .clear)
        )
        .padding(.leading, 6)
        .padding(.trailing, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(item.isSelected ? "選択中" : "")
        .accessibilityAddTraits(.isButton)
    }

    private var accessibilityLabel: String {
        if let trailing = item.trailing {
            "\(item.title), \(trailing)"
        } else {
            item.title
        }
    }

    private func symbolName(for status: ChatListItem.LeadingStatus) -> String {
        switch status {
        case .green:
            "point.3.connected.trianglepath.dotted"
        case .secretary:
            "sparkles"
        case .branch:
            "arrow.triangle.branch"
        case .plus:
            "plus.circle"
        }
    }

    private func symbolSize(for status: ChatListItem.LeadingStatus) -> CGFloat {
        switch status {
        case .green:
            10
        case .secretary, .branch:
            12.25
        case .plus:
            12
        }
    }
}

private struct GlobalSecretaryView: View {
    let items: [ChatListItem]

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
                SidebarChatRow(item: item)
            }
        }
        .padding(.top, 2)
    }
}

private struct SettingsRow: View {
    var body: some View {
        HStack(spacing: 9) {
            SidebarGlyph(.gear)

            Text("設定")
                .font(.atelia(13.25))
                .tracking(0.25)
                .foregroundStyle(Color.clientSidebarText)

            Spacer()
        }
        .frame(height: 32)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("設定")
        .accessibilityAddTraits(.isButton)
    }
}
