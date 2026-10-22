import SwiftUI

enum ChatContentPresentation: Equatable {
    case welcome
    case transcript
}

/// Presentation constants shared by the desktop shell and compact workspace.
enum WorkbenchPresentationPolicy {
    static let pageTopInset: CGFloat = 28
    static let sectionSpacing: CGFloat = 24
    static let heroMaximumWidth: CGFloat = 680
    static let minimumActionHeight: CGFloat = 44

    static func starterColumnCount(width: CGFloat, expandedText: Bool) -> Int {
        guard width.isFinite, width >= 480, !expandedText else { return 1 }
        return 2
    }

    static func showsWelcome(messages: [ChatMessage], isGenerating: Bool) -> Bool {
        chatPresentation(messages: messages, isGenerating: isGenerating, hasStarter: true) == .welcome
    }

    static func chatPresentation(
        messages: [ChatMessage],
        isGenerating: Bool,
        hasStarter: Bool
    ) -> ChatContentPresentation {
        hasStarter && !isGenerating && !messages.contains { $0.role == .user }
            ? .welcome
            : .transcript
    }

    static func welcomeContentWidth(for availableWidth: CGFloat) -> CGFloat {
        guard availableWidth.isFinite, availableWidth > 0 else { return 0 }
        return min(availableWidth, heroMaximumWidth)
    }

    static func initialWorkspace(arguments: [String]) -> WorkspaceTab {
        #if DEBUG
        if let index = arguments.firstIndex(of: "--ui-workspace"),
           arguments.indices.contains(index + 1),
           let tab = WorkspaceTab(rawValue: arguments[index + 1]) {
            return tab
        }
        #endif
        return arguments.contains("--open-models") ? .models : .chat
    }
}

struct WorkbenchBrandMark: View {
    @Environment(\.appTheme) private var theme

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient(colors: [theme.accent, theme.secondaryAccent],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
            Image(systemName: "sparkle")
                .font(.title2.weight(.medium))
                .foregroundStyle(theme.inverseText)
        }
        .frame(width: 42, height: 42)
        .accessibilityHidden(true)
    }
}

struct WorkbenchBrandHeader: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let themeMode: AppThemeMode
    var isSidebar = false
    let toggleTheme: () -> Void
    let showModels: () -> Void

    var body: some View {
        let layout = isSidebar || dynamicTypeSize >= .xxxLarge
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
            : AnyLayout(HStackLayout(alignment: .center, spacing: 8))

        layout {
            HStack(spacing: 10) {
                WorkbenchBrandMark()
                VStack(alignment: .leading, spacing: 2) {
                    Text("LOCAL INTELLIGENCE")
                        .font(.caption2.weight(.medium).monospaced())
                        .tracking(0.8)
                        .foregroundStyle(theme.secondaryText)
                    Text("Gemma")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(theme.primaryText)
                }
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            HStack(spacing: 8) {
                Button(action: toggleTheme) {
                    Label("切换外观", systemImage: themeMode.icon)
                        .labelStyle(.iconOnly)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(WorkbenchIconButtonStyle())
                .accessibilityLabel(HeaderActionAccessibilityMetadata.themeToggleLabel(themeMode: themeMode))
                .accessibilityValue(HeaderActionAccessibilityMetadata.themeToggleValue(themeMode: themeMode))
                .accessibilityHint(HeaderActionAccessibilityMetadata.themeToggleHint(themeMode: themeMode))
                .accessibilityInputLabels(HeaderActionAccessibilityMetadata.themeToggleInputLabels(themeMode: themeMode))
                .accessibilityIdentifier(HeaderActionAccessibilityMetadata.headerThemeToggleIdentifier)
                .help("切换为\(themeMode.toggled.title)外观")

                Button(action: showModels) {
                    Label("模型库", systemImage: "square.stack.3d.up")
                        .labelStyle(.iconOnly)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(WorkbenchIconButtonStyle())
                .accessibilityLabel(HeaderActionAccessibilityMetadata.modelLibraryLabel)
                .accessibilityValue(HeaderActionAccessibilityMetadata.modelLibraryValue)
                .accessibilityHint(HeaderActionAccessibilityMetadata.modelLibraryHint)
                .accessibilityInputLabels(HeaderActionAccessibilityMetadata.modelLibraryInputLabels)
                .accessibilityIdentifier(HeaderActionAccessibilityMetadata.modelLibraryIdentifier)
                .help("打开本地模型库 · ⌘2")
                if isSidebar {
                    Spacer(minLength: 0)
                    Text("ON DEVICE")
                        .font(.caption2.monospaced())
                        .foregroundStyle(theme.secondaryText)
                        .accessibilityHidden(true)
                }
            }
        }
    }
}

struct WorkbenchIconButtonStyle: ButtonStyle {
    @Environment(\.appTheme) private var theme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.medium))
            .foregroundStyle(theme.primaryText)
            .background(configuration.isPressed ? theme.accent.opacity(0.16) : theme.chipSurface,
                        in: RoundedRectangle(cornerRadius: 10))
            .contentShape(RoundedRectangle(cornerRadius: 10))
            .hoverEffect(.highlight)
    }
}

struct WorkbenchSidebarFooter: View {
    @Environment(\.appTheme) private var theme

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "lock.shield")
                .foregroundStyle(theme.accent)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text("私密，始终在本机")
                    .foregroundStyle(theme.primaryText)
                Text("模拟预览 · 无云端推理")
                    .foregroundStyle(theme.secondaryText)
            }
        }
        .font(.caption)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
    }
}

struct ChatWorkspaceHeading: View {
    @Environment(\.appTheme) private var theme
    let title: String

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center) {
                heading
                Spacer(minLength: 16)
                runtimeLabel
            }
            VStack(alignment: .leading, spacing: 8) {
                heading
                runtimeLabel
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.surface.opacity(0.7))
        .overlay(alignment: .bottom) { theme.subtleBorder.frame(height: 1) }
    }

    private var heading: some View {
        Text(title)
            .font(.headline)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
            .foregroundStyle(theme.primaryText)
            .accessibilityAddTraits(.isHeader)
    }

    private var runtimeLabel: some View {
        Label("本地模拟", systemImage: "circle.dotted")
            .font(.caption.weight(.medium))
            .foregroundStyle(theme.accent)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(theme.accent.opacity(0.08), in: Capsule())
            .fixedSize()
    }
}

struct ChatWelcomeView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let availableWidth: CGFloat
    let apply: (PresetPromptTemplate) -> Void

    var body: some View {
        let contentWidth = WorkbenchPresentationPolicy.welcomeContentWidth(for: availableWidth)

        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "cpu")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(theme.accent)
                    .frame(width: 42, height: 42)
                    .background(theme.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(theme.accent.opacity(0.2), lineWidth: 1)
                    }
                VStack(alignment: .leading, spacing: 3) {
                    Text("ON-DEVICE WORKSPACE")
                        .font(.caption2.weight(.medium).monospaced())
                        .tracking(0.8)
                    Text("本地模拟 · 无云端推理")
                        .font(.caption)
                }
                .foregroundStyle(theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text("让想法，在此发生。")
                    .font(.title.weight(.semibold))
                    .foregroundStyle(theme.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Text("从一个问题开始，探索私密的端侧工作空间。")
                    .font(.subheadline)
                    .lineSpacing(2)
                    .foregroundStyle(theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), alignment: .topLeading),
                                    count: WorkbenchPresentationPolicy.starterColumnCount(
                                        width: contentWidth, expandedText: dynamicTypeSize >= .xxxLarge)),
                      alignment: .leading, spacing: 8) {
                ForEach(Array(PromptTemplateLibrary.defaultTemplates.prefix(2))) { template in
                    Button { apply(template) } label: {
                        HStack(spacing: 10) {
                            Image(systemName: template.icon)
                                .font(.body)
                                .foregroundStyle(theme.accent)
                                .frame(width: 28, height: 28)
                                .background(theme.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(template.title)
                                    .font(.subheadline.weight(.medium))
                                    .fixedSize(horizontal: false, vertical: true)
                                    .foregroundStyle(theme.primaryText)
                                Text(template.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(theme.secondaryText)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            Image(systemName: "arrow.up.left")
                                .font(.caption)
                                .foregroundStyle(theme.secondaryText)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, minHeight: WorkbenchPresentationPolicy.minimumActionHeight,
                               alignment: .leading)
                        .background(theme.surface, in: RoundedRectangle(cornerRadius: 8))
                        .overlay { RoundedRectangle(cornerRadius: 8).stroke(theme.border, lineWidth: 1) }
                    }
                    .buttonStyle(.plain)
                    .hoverEffect(.highlight)
                    .accessibilityLabel(PromptTemplateActionAccessibilityMetadata.label(for: .apply, template: template))
                    .accessibilityValue(PromptTemplateActionAccessibilityMetadata.value(for: .apply, isGenerating: false))
                    .accessibilityHint(PromptTemplateActionAccessibilityMetadata.hint(for: .apply, template: template))
                    .accessibilityInputLabels(PromptTemplateActionAccessibilityMetadata.inputLabels(for: .apply, template: template))
                    .accessibilityIdentifier("welcome.apply.\(template.id)")
                }
            }

            Label("模拟预览，尚未接入真实模型推理。", systemImage: "info.circle")
                .font(.caption)
                .foregroundStyle(theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 12)
        .frame(width: contentWidth, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity)
    }
}

enum ChatWelcomeAccessibilityMetadata {
    static let label = "本地工作区欢迎页"
    static let value = "当前为本地模拟预览，可选择部署方案或隐私评审模板。模板只填入输入框并聚焦，不自动发送；尚未接入真实模型推理。"
    static let hint = "浏览本地欢迎内容或选择起始模板；不会发送 prompt，不会下载模型权重，不会启动真实 runtime，不会发送到云端服务，也不会绕过 artifact verified 门禁。"
    static let inputLabels = ["欢迎页", "本地工作区欢迎页", "开始本地会话"]
}
