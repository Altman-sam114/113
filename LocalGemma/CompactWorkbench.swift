import SwiftUI

private struct CompactWorkbenchKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var compactWorkbench: Bool {
        get { self[CompactWorkbenchKey.self] }
        set { self[CompactWorkbenchKey.self] = newValue }
    }
}

enum CompactWorkbenchPolicy {
    static let minimumTouchTarget: CGFloat = 44
    static let navigationItemHeight: CGFloat = 56
    static let surfaceCornerRadius: CGFloat = 20
    static let headerActionSymbolSize: CGFloat = 18
    static let headerChevronSymbolSize: CGFloat = 12

    static func runtimeTitle(isSimulated: Bool) -> String {
        isSimulated ? "模拟预览" : "运行计划"
    }

    static func runtimeAccessibilityValue(isSimulated: Bool) -> String {
        isSimulated ? "本地模拟预览，未执行真实推理" : "本地运行计划，不代表真实推理已接入"
    }

    static func usesCompactChrome(for plan: WorkspaceRootLayoutPlan) -> Bool {
        plan.chrome == .topNavigation
    }

    static func stacksHeaderControls(dynamicTypeSize: DynamicTypeSize) -> Bool {
        dynamicTypeSize >= .xxxLarge
    }

    static func showsNavigation(isCompact: Bool, selectedTab: WorkspaceTab, isEditing: Bool) -> Bool {
        isCompact && (selectedTab != .chat || !isEditing)
    }

    static func title(for tab: WorkspaceTab) -> String {
        switch tab {
        case .chat: return "对话"
        case .models: return "模型"
        case .prompts: return "模板"
        case .settings: return "设置"
        }
    }

    static func modelTitle(_ model: LocalModel) -> String {
        model.name.hasSuffix(" Local") ? String(model.name.dropLast(6)) : model.name
    }

    static func fileStatus(_ availability: ArtifactAvailability) -> String {
        switch availability {
        case .missing: return "尚未导入"
        case .staged: return "待校验"
        case .verified: return "已校验"
        }
    }

    static func installTitle(_ state: ModelInstallState) -> String {
        switch state {
        case .ready: return "已准备"
        case .simulated: return "模拟"
        case .notDownloaded: return "未安装"
        }
    }

    static func toggleTitle(_ item: OptimizationSwitch) -> String {
        switch item.title {
        case "Metal graph prewarm": return "图执行预热"
        case "Paged KV cache": return "分页缓存"
        case "Adaptive token budget": return "自适应生成长度"
        case "Offline privacy guard": return "离线隐私保护"
        default: return item.title
        }
    }
}

struct CompactChatHeaderActions {
    let sessionTitle: String
    let showHistory: () -> Void
    let create: () -> Void
    let export: () -> Void
}

struct CompactWorkbenchHeader: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let model: LocalModel
    let isSimulated: Bool
    let themeMode: AppThemeMode
    let openSummary: () -> Void
    let toggleTheme: () -> Void
    var chatActions: CompactChatHeaderActions? = nil

    var body: some View {
        let layout = CompactWorkbenchPolicy.stacksHeaderControls(dynamicTypeSize: dynamicTypeSize)
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
            : AnyLayout(HStackLayout(spacing: 8))

        layout {
            Button(action: openSummary) {
                HStack(spacing: 6) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(CompactWorkbenchPolicy.modelTitle(model))
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(theme.primaryText)
                            .lineLimit(2)
                        HStack(spacing: 5) {
                            Circle().fill(theme.accent).frame(width: 4, height: 4)
                                .accessibilityHidden(true)
                            Text(CompactWorkbenchPolicy.runtimeTitle(isSimulated: isSimulated))
                                .font(.caption)
                                .foregroundStyle(theme.secondaryText)
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    Image(systemName: "chevron.down")
                        .font(.system(size: CompactWorkbenchPolicy.headerChevronSymbolSize, weight: .semibold))
                        .foregroundStyle(theme.secondaryText)
                        .accessibilityHidden(true)
                }
                .frame(minHeight: CompactWorkbenchPolicy.minimumTouchTarget, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("当前模型，\(model.name)")
            .accessibilityValue(CompactWorkbenchPolicy.runtimeAccessibilityValue(isSimulated: isSimulated))
            .accessibilityHint("打开当前模型运行摘要；只展示本地状态，不下载权重或启动真实 runtime。")
            .accessibilityInputLabels(["当前模型", "模型摘要", model.name])
            .accessibilityIdentifier("compact-model-summary")

            if let chatActions {
                CompactChatTools(actions: chatActions, themeMode: themeMode, toggleTheme: toggleTheme)
                    .frame(maxWidth: CompactWorkbenchPolicy.stacksHeaderControls(dynamicTypeSize: dynamicTypeSize)
                           ? .infinity : nil, alignment: .trailing)
            } else {
                Button(action: toggleTheme) {
                    Image(systemName: themeMode.icon)
                        .font(.system(size: CompactWorkbenchPolicy.headerActionSymbolSize, weight: .medium))
                        .frame(width: CompactWorkbenchPolicy.minimumTouchTarget, height: CompactWorkbenchPolicy.minimumTouchTarget)
                }
                .buttonStyle(WorkbenchIconButtonStyle())
                .accessibilityLabel(HeaderActionAccessibilityMetadata.themeToggleLabel(themeMode: themeMode))
                .accessibilityValue(HeaderActionAccessibilityMetadata.themeToggleValue(themeMode: themeMode))
                .accessibilityHint(HeaderActionAccessibilityMetadata.themeToggleHint(themeMode: themeMode))
                .accessibilityInputLabels(HeaderActionAccessibilityMetadata.themeToggleInputLabels(themeMode: themeMode))
                .accessibilityIdentifier(HeaderActionAccessibilityMetadata.headerThemeToggleIdentifier)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 8)
    }
}

private struct CompactChatTools: View {
    @Environment(\.appTheme) private var theme
    let actions: CompactChatHeaderActions
    let themeMode: AppThemeMode
    let toggleTheme: () -> Void

    var body: some View {
        HStack(spacing: 2) {
            Button(action: actions.showHistory) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: CompactWorkbenchPolicy.headerActionSymbolSize, weight: .medium))
                    .frame(width: CompactWorkbenchPolicy.minimumTouchTarget, height: CompactWorkbenchPolicy.minimumTouchTarget)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("会话记录")
            .accessibilityValue("当前会话，\(actions.sessionTitle)")
            .accessibilityHint("打开本机会话列表，可选择或删除会话，不会发送到云端服务。")
            .accessibilityInputLabels(["会话记录", "历史会话", actions.sessionTitle])
            .accessibilityIdentifier("compact-session-history")

            Button(action: actions.create) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: CompactWorkbenchPolicy.headerActionSymbolSize, weight: .medium))
                    .frame(width: CompactWorkbenchPolicy.minimumTouchTarget, height: CompactWorkbenchPolicy.minimumTouchTarget)
                    .contentShape(Rectangle())
            }
            .modifier(CompactSessionActionAccessibility(action: .createSession))

            Menu {
                Button(action: actions.export) {
                    Label("导出会话", systemImage: "square.and.arrow.up")
                }
                .modifier(CompactSessionActionAccessibility(action: .exportSession))
                Button(action: toggleTheme) {
                    Label("切换为\(themeMode.toggled.title)", systemImage: themeMode.icon)
                }
                .accessibilityLabel(HeaderActionAccessibilityMetadata.themeToggleLabel(themeMode: themeMode))
                .accessibilityValue(HeaderActionAccessibilityMetadata.themeToggleValue(themeMode: themeMode))
                .accessibilityHint(HeaderActionAccessibilityMetadata.themeToggleHint(themeMode: themeMode))
                .accessibilityInputLabels(HeaderActionAccessibilityMetadata.themeToggleInputLabels(themeMode: themeMode))
                .accessibilityIdentifier(HeaderActionAccessibilityMetadata.headerThemeToggleIdentifier)
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: CompactWorkbenchPolicy.headerActionSymbolSize, weight: .medium))
                    .frame(width: CompactWorkbenchPolicy.minimumTouchTarget, height: CompactWorkbenchPolicy.minimumTouchTarget)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("更多会话操作")
            .accessibilityHint("导出当前会话或切换外观。")
            .accessibilityInputLabels(["更多会话操作", "更多", "导出会话"])
            .accessibilityIdentifier("compact-chat-more")
        }
        .font(.body.weight(.medium))
        .buttonStyle(.plain)
        .foregroundStyle(theme.secondaryText)
    }
}

private struct CompactSessionActionAccessibility: ViewModifier {
    let action: SessionCommandAction

    func body(content: Content) -> some View {
        content
            .accessibilityLabel(SessionBarActionAccessibilityMetadata.label(for: action))
            .accessibilityValue(SessionBarActionAccessibilityMetadata.value(for: action))
            .accessibilityHint(SessionBarActionAccessibilityMetadata.hint(for: action))
            .accessibilityInputLabels(SessionBarActionAccessibilityMetadata.inputLabels(for: action))
            .accessibilityIdentifier(SessionBarActionAccessibilityMetadata.identifier(for: action))
    }
}

struct CompactWorkspaceNavigation: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var selection: WorkspaceTab

    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            ForEach(WorkspaceTab.allCases) { tab in
                Button {
                    withAnimation(AppMotionAccessibilityPolicy.animation(
                        .spring(response: 0.3, dampingFraction: 0.82),
                        for: .workspaceNavigation, reduceMotion: reduceMotion
                    )) {
                        selection = tab
                    }
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 18, weight: .medium))
                            .frame(width: 42, height: 24)
                            .accessibilityHidden(true)
                            .background {
                                if selection == tab {
                                    Capsule().fill(theme.accent.opacity(theme.isDark ? 0.12 : 0.08))
                                }
                            }
                        Text(CompactWorkbenchPolicy.title(for: tab))
                            .font(.caption.weight(selection == tab ? .semibold : .regular))
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, minHeight: CompactWorkbenchPolicy.navigationItemHeight)
                    .foregroundStyle(selection == tab ? theme.accent : theme.secondaryText)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .keyboardShortcut(KeyEquivalent(tab.shortcutKey), modifiers: [.command])
                .accessibilityLabel(WorkspaceNavigationAccessibilityMetadata.label(for: tab))
                .accessibilityValue(WorkspaceNavigationAccessibilityMetadata.value(isSelected: selection == tab))
                .accessibilityHint(WorkspaceNavigationAccessibilityMetadata.hint(for: tab))
                .accessibilityInputLabels(WorkspaceNavigationAccessibilityMetadata.inputLabels(for: tab)
                    + [CompactWorkbenchPolicy.title(for: tab)])
                .accessibilityAddTraits(selection == tab ? .isSelected : [])
                .accessibilityIdentifier(WorkspaceNavigationAccessibilityMetadata.compactIdentifier(for: tab))
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 5)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(theme.surface)
                .shadow(color: .black.opacity(theme.isDark ? 0.18 : 0.06), radius: 12, y: 4)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(theme.subtleBorder, lineWidth: 0.5)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 18)
        .padding(.top, 4)
        .padding(.bottom, 6)
    }
}

struct CompactSessionToolbar: View {
    @Environment(\.appTheme) private var theme
    let title: String
    let showHistory: () -> Void
    let create: () -> Void
    let export: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: showHistory) {
                HStack(spacing: 8) {
                    Image(systemName: "clock.arrow.circlepath")
                    Text(title)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .font(.subheadline)
                .frame(minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(theme.secondaryText)
            .accessibilityLabel("会话记录")
            .accessibilityValue("当前会话，\(title)")
            .accessibilityHint("打开本机会话列表，可选择或删除会话，不会发送到云端服务。")
            .accessibilityInputLabels(["会话记录", "历史会话", title])
            .accessibilityIdentifier("compact-session-history")

            Spacer(minLength: 0)
            sessionAction(.exportSession, icon: "square.and.arrow.up", action: export)
            sessionAction(.createSession, icon: "square.and.pencil", action: create)
        }
        .padding(.horizontal, 18)
    }

    private func sessionAction(_ item: SessionCommandAction, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.body)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(theme.primaryText)
        .accessibilityLabel(SessionBarActionAccessibilityMetadata.label(for: item))
        .accessibilityValue(SessionBarActionAccessibilityMetadata.value(for: item))
        .accessibilityHint(SessionBarActionAccessibilityMetadata.hint(for: item))
        .accessibilityInputLabels(SessionBarActionAccessibilityMetadata.inputLabels(for: item))
        .accessibilityIdentifier(SessionBarActionAccessibilityMetadata.identifier(for: item))
    }
}

struct CompactModelFilesPanel: View {
    @Environment(\.appTheme) private var theme
    let validation: ArtifactValidationResult
    let download: () -> Void
    let uninstall: () -> Void
    let scan: () -> Void
    let importFiles: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            fileAction(.importFiles, title: "导入模型文件", icon: "square.and.arrow.down", action: importFiles)
                .frame(maxWidth: .infinity, minHeight: 48)
                .foregroundStyle(theme.inverseText)
                .background(theme.accent, in: RoundedRectangle(cornerRadius: 13))

            HStack(spacing: 12) {
                fileAction(.scan, title: "扫描本地", icon: "folder", action: scan)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                Menu {
                    fileAction(.download, title: "模拟暂存", icon: "shippingbox", action: download)
                    Button(role: .destructive, action: uninstall) {
                        Label("卸载模型", systemImage: "trash")
                    }
                    .modifier(CompactArtifactAccessibility(action: .uninstall, availability: validation.availability))
                } label: {
                    Image(systemName: "ellipsis")
                        .frame(width: 44, height: 44)
                        .background(theme.chipSurface, in: RoundedRectangle(cornerRadius: 12))
                }
                .accessibilityLabel("更多文件操作")
                .accessibilityHint("可模拟暂存或打开卸载确认，不会联网下载权重。")
                .accessibilityInputLabels(["更多文件操作", "更多"])
                .accessibilityIdentifier("compact-model-files-more")
            }
            .foregroundStyle(theme.secondaryText)
        }
        .panelStyle()
        .accessibilityElement(children: .contain)
        .accessibilityLabel(ModelArtifactPanelAccessibilityMetadata.label)
        .accessibilityValue(ModelArtifactPanelAccessibilityMetadata.value(validation: validation))
        .accessibilityHint(ModelArtifactPanelAccessibilityMetadata.hint)
        .accessibilityInputLabels(ModelArtifactPanelAccessibilityMetadata.inputLabels)
        .accessibilityIdentifier(ModelArtifactPanelAccessibilityMetadata.identifier)
    }

    private func fileAction(
        _ action: ModelDeploymentControlAccessibilityMetadata.ArtifactAction,
        title: String, icon: String, action perform: @escaping () -> Void
    ) -> some View {
        Button(action: perform) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .center)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .modifier(CompactArtifactAccessibility(action: action, availability: validation.availability))
    }
}

private struct CompactArtifactAccessibility: ViewModifier {
    let action: ModelDeploymentControlAccessibilityMetadata.ArtifactAction
    let availability: ArtifactAvailability

    func body(content: Content) -> some View {
        content
            .accessibilityLabel(ModelDeploymentControlAccessibilityMetadata.artifactActionLabel(action))
            .accessibilityValue(ModelDeploymentControlAccessibilityMetadata.artifactActionValue(action, availability: availability))
            .accessibilityHint(ModelDeploymentControlAccessibilityMetadata.artifactActionHint(action, availability: availability))
            .accessibilityInputLabels(ModelDeploymentControlAccessibilityMetadata.artifactActionInputLabels(action)
                + (action == .importFiles ? ["导入模型文件"] : action == .download ? ["模拟暂存"] : []))
            .accessibilityIdentifier(ModelDeploymentControlAccessibilityMetadata.artifactActionIdentifier(action))
    }
}
