import Foundation
import PhotosUI
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct SettingsWorkspace: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.compactWorkbench) private var isCompact
    @Environment(\.isEnabled) private var isEnabled
    @State private var selectedWallpaperItem: PhotosPickerItem?
    @State private var isImportingWallpaper = false
    @State private var wallpaperImportError: String?
    @State private var showsHelp = false

    let themeMode: AppThemeMode
    let wallpaperData: Data
    let toggleTheme: () -> Void
    let setWallpaperData: (Data) -> Void
    let clearWallpaper: () -> Void

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                let plan = SettingsWorkspaceLayoutPolicy.resolve(
                    forContainerWidth: proxy.size.width,
                    dynamicTypeSize: dynamicTypeSize
                )

                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader(
                        eyebrow: "SETTINGS",
                        title: isCompact ? "设置" : "偏好设置",
                        subtitle: "让工作空间，更适合你。外观、设备策略与隐私，一目了然。"
                    )

                    SettingsSectionsShell(plan: plan) {
                        SettingsAppearanceSection(
                            themeMode: themeMode,
                            wallpaperData: wallpaperData,
                            selectedItem: $selectedWallpaperItem,
                            isImporting: isImportingWallpaper,
                            availableWidth: plan.preferenceWidth,
                            showsPreview: plan.mode == .columns,
                            toggleTheme: toggleTheme,
                            clearWallpaper: clearWallpaper
                        )
                    } runtime: {
                        SettingsRuntimeSection(availableWidth: plan.runtimeWidth)
                    }

                    SettingsHelpButton { showsHelp = true }
                }
                .frame(width: plan.contentWidth, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, SettingsWorkspaceLayoutPolicy.horizontalPadding)
                .padding(.top, isCompact ? 16 : WorkbenchPresentationPolicy.pageTopInset)
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)
        }
        .onChange(of: selectedWallpaperItem) { _, item in
            guard let item else { return }
            Task {
                await MainActor.run {
                    isImportingWallpaper = true
                    wallpaperImportError = nil
                }

                do {
                    guard let data = try await item.loadTransferable(type: Data.self) else {
                        throw WallpaperImportError.unreadableImage
                    }
                    let jpegData = try WallpaperImageProcessor.optimizedJPEGData(from: data)
                    await MainActor.run {
                        setWallpaperData(jpegData)
                        selectedWallpaperItem = nil
                        isImportingWallpaper = false
                    }
                } catch {
                    await MainActor.run {
                        selectedWallpaperItem = nil
                        isImportingWallpaper = false
                        wallpaperImportError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                    }
                }
            }
        }
        .alert(
            "壁纸导入失败",
            isPresented: Binding(
                get: { wallpaperImportError != nil },
                set: { isPresented in
                    if isPresented == false {
                        wallpaperImportError = nil
                    }
                }
            )
        ) {
            Button("好", role: .cancel) {}
        } message: {
            Text(wallpaperImportError ?? "")
        }
        .sheet(isPresented: $showsHelp) {
            SettingsHelpSheet()
                .environment(\.appTheme, theme)
                .preferredColorScheme(theme.mode.colorScheme)
        }
        .onChange(of: isEnabled) { _, enabled in
            if !enabled { showsHelp = false }
        }
    }
}

struct SettingsHelpSection: Identifiable, Sendable {
    let id: String
    let title: String
    let body: String
}

enum SettingsHelpContent {
    static let title = "关于、隐私与帮助"
    static let minimumTouchTarget: CGFloat = 48
    static let buttonIdentifier = "settings-help-open"
    static let closeIdentifier = "settings-help-close"
    static let supportIdentifier = "settings-help-repository"
    static let repositoryURL = URL(string: "https://github.com/Altman-sam114/113")
    static let sections = [
        SettingsHelpSection(
            id: "capabilities", title: "当前能力",
            body: "当前版本是本地 AI 工作台原型，默认使用模拟回复，不会实际改写、翻译或总结输入。模型文件校验为 verified 只说明文件通过校验，不代表真实推理已接入；参考速度、内存和设备预算并非实测。"
        ),
        SettingsHelpSection(
            id: "privacy", title: "App 不主动上传",
            body: "App 不发起对话、草稿、模型或壁纸的网络上传，不收集使用分析，不用于广告跟踪，也不自动下载模型权重。运行策略中的隐私开关不代表开启任何云端服务。"
        ),
        SettingsHelpSection(
            id: "storage", title: "本机保存与系统备份",
            body: "对话和逐会话草稿保存在 App 的本机目录；App 为会话目录（含修复原件）和托管模型目录设置不参与系统备份的标记。会话和新导入模型设置失败时会报错；既有托管模型扫描时尝试迁移，系统拒绝设置时不能保证排除。卸载 App 会失去未导出的对话。壁纸会在本机压缩后与外观偏好保存，仍可能进入系统备份。系统备份、设备迁移与剪贴板同步由系统设置决定，“App 不主动上传”不等于关闭这些系统功能。"
        ),
        SettingsHelpSection(
            id: "sharing", title: "分享由你决定",
            body: "导出生成本机 Markdown 文件；文件不可用时可分享文本。只有你操作分享或复制后，内容才交给系统分享面板或剪贴板。接收 App 的网络行为和系统剪贴板能力不由本 App 控制；请勿分享不希望外传的内容。"
        ),
        SettingsHelpSection(
            id: "deletion", title: "删除、恢复与修复",
            body: "在会话记录中删除并确认，可移除相应本机对话和草稿；模型页卸载并确认只删除 App 托管副本，不删除 Files 中的原始文件。设置中恢复系统背景可移除 App 保存的自定义壁纸。读取失败时，只有明确选择“保留原件并修复”才会重建记录，原件备份仍保留在不参与系统备份的会话目录。已导出文件、既有系统备份和其他 App 的副本需分别管理。"
        ),
        SettingsHelpSection(
            id: "models", title: "模型与授权",
            body: "App 不附带可运行的真实模型权重。手动导入前请确认文件来源、格式和相应模型许可；模拟文件不是真实权重。模型名称与参数只用于本地部署计划展示，不代表相关模型提供方的认可。"
        ),
        SettingsHelpSection(
            id: "support", title: "帮助与反馈",
            body: "遇到问题时，可记录 App 版本、设备系统版本、操作步骤与错误提示。请自行去除对话、文件路径或图片中的敏感内容；App 不自动附带会话、草稿、模型文件或诊断信息。下方链接仅在你点按后由系统打开外部项目页面，网络访问遵循浏览器和网站的规则。"
        )
    ]

    static func versionDescription(info: [String: Any]) -> String {
        func value(_ key: String) -> String {
            guard let text = info[key] as? String,
                  !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return "未提供" }
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return "版本 \(value("CFBundleShortVersionString")) · 构建 \(value("CFBundleVersion"))"
    }
}

struct SettingsHelpButton: View {
    @Environment(\.appTheme) private var theme
    let open: () -> Void

    var body: some View {
        Button(action: open) {
            HStack(spacing: 12) {
                Image(systemName: "info.circle")
                    .font(.system(size: 18, weight: .medium))
                    .accessibilityHidden(true)
                Text(SettingsHelpContent.title)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .accessibilityHidden(true)
            }
            .foregroundStyle(theme.primaryText)
            .frame(maxWidth: .infinity, minHeight: SettingsHelpContent.minimumTouchTarget, alignment: .leading)
            .padding(.horizontal, 14)
            .background(theme.surface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(SettingsHelpContent.title)
        .accessibilityHint("打开本地说明、隐私边界和版本信息，不发送内容或启动真实推理。")
        .accessibilityInputLabels([SettingsHelpContent.title, "隐私与帮助", "关于"])
        .accessibilityIdentifier(SettingsHelpContent.buttonIdentifier)
    }
}

struct SettingsHelpSheet: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text(SettingsHelpContent.title)
                    .font(.title2.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityAddTraits(.isHeader)
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: SettingsHelpContent.minimumTouchTarget, height: SettingsHelpContent.minimumTouchTarget)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("关闭隐私与帮助")
                .accessibilityInputLabels(["关闭隐私与帮助", "关闭"])
                .accessibilityIdentifier(SettingsHelpContent.closeIdentifier)
            }
            .foregroundStyle(theme.primaryText)
            .padding(.horizontal, 18)
            .padding(.top, 12)

            ScrollView {
                SettingsHelpBody(versionDescription: SettingsHelpContent.versionDescription(info: Bundle.main.infoDictionary ?? [:]))
                    .padding(18)
                    .frame(maxWidth: 760, alignment: .leading)
                    .frame(maxWidth: .infinity)
            }
        }
        .background(theme.canvas)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

struct SettingsHelpBody: View {
    @Environment(\.appTheme) private var theme
    let versionDescription: String

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(versionDescription)
                .font(.subheadline.monospaced())
                .foregroundStyle(theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(SettingsHelpContent.sections) { section in
                VStack(alignment: .leading, spacing: 8) {
                    Text(section.title)
                        .font(.headline)
                        .foregroundStyle(theme.primaryText)
                        .accessibilityAddTraits(.isHeader)
                    Text(section.body)
                        .font(.body)
                        .foregroundStyle(theme.secondaryText)
                        .lineSpacing(3)
                        .textSelection(.enabled)
                }
                .fixedSize(horizontal: false, vertical: true)
            }

            if let url = SettingsHelpContent.repositoryURL {
                Link(destination: url) {
                    Label("在浏览器中查看项目", systemImage: "arrow.up.right.square")
                        .font(.body.weight(.medium))
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, minHeight: SettingsHelpContent.minimumTouchTarget, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .foregroundStyle(theme.accent)
                .accessibilityHint("由系统打开外部项目页面；不会自动附带对话、草稿、模型文件或诊断信息。")
                .accessibilityInputLabels(["在浏览器中查看项目", "项目页面"])
                .accessibilityIdentifier(SettingsHelpContent.supportIdentifier)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

enum SettingsPreferenceTextLayoutPolicy {
    static let verticalSpacing: CGFloat = 5
    static let titleLineLimit = 2
    static let statusLineLimit = 2

    static var allowsMultilineTitle: Bool {
        titleLineLimit > 1
    }

    static var allowsMultilineStatus: Bool {
        statusLineLimit > 1
    }
}

enum SettingsIconActionLayoutPolicy {
    enum Action: CaseIterable {
        case toggleTheme
        case choosePhoto
        case clearCustomWallpaper
    }

    static let minimumTouchTarget: CGFloat = 44
    static let iconButtonSize: CGFloat = minimumTouchTarget

    static func usesMinimumTouchTarget(for action: Action) -> Bool {
        switch action {
        case .toggleTheme, .choosePhoto, .clearCustomWallpaper:
            return iconButtonSize >= minimumTouchTarget
        }
    }
}

enum SettingsPreferenceRowLayoutMode: Equatable {
    case stacked
    case horizontal
}

struct SettingsPreferenceRowLayoutPlan: Equatable {
    let mode: SettingsPreferenceRowLayoutMode
    let contentWidth: CGFloat
    let allowsHorizontal: Bool
}

enum SettingsPreferenceRowLayoutPolicy {
    static let previewSize: CGFloat = 58
    static let compactPreviewSize: CGFloat = 40
    static let minimumTextWidth: CGFloat = 88
    static let horizontalSpacing: CGFloat = 14
    static let compactHorizontalSpacing: CGFloat = 10
    static let stackedSpacing: CGFloat = 12
    static let actionSpacing: CGFloat = 8
    static let actionCount = 2
    static let minimumTouchTarget: CGFloat = SettingsIconActionLayoutPolicy.minimumTouchTarget

    static var actionRowMinimumWidth: CGFloat {
        minimumTouchTarget * CGFloat(actionCount) + actionSpacing
    }

    static var horizontalContentWidthThreshold: CGFloat {
        previewSize
            + minimumTextWidth
            + actionRowMinimumWidth
            + horizontalSpacing * 2
    }

    static var compactHorizontalContentWidthThreshold: CGFloat {
        compactPreviewSize
            + minimumTextWidth
            + actionRowMinimumWidth
            + compactHorizontalSpacing * 2
    }

    static func panelContentWidth(forPanelWidth panelWidth: CGFloat) -> CGFloat {
        guard panelWidth.isFinite, panelWidth > 0 else { return 0 }
        return max(
            panelWidth - WorkbenchVisualStylePolicy.panelPadding * 2,
            0
        )
    }

    static func isChooseActionDisabled(isImporting: Bool) -> Bool {
        isImporting
    }

    static func isClearActionDisabled(
        hasCustomWallpaper: Bool,
        isImporting: Bool
    ) -> Bool {
        hasCustomWallpaper == false || isImporting
    }

    static func resolve(
        contentWidth: CGFloat,
        dynamicTypeSize: DynamicTypeSize,
        isCompact: Bool = false
    ) -> SettingsPreferenceRowLayoutPlan {
        let safeContentWidth = contentWidth.isFinite && contentWidth > 0 ? contentWidth : 0
        let threshold = isCompact ? compactHorizontalContentWidthThreshold : horizontalContentWidthThreshold
        let allowsHorizontal = safeContentWidth >= threshold
            && dynamicTypeSize < .xxxLarge

        return SettingsPreferenceRowLayoutPlan(
            mode: allowsHorizontal ? .horizontal : .stacked,
            contentWidth: safeContentWidth,
            allowsHorizontal: allowsHorizontal
        )
    }
}

struct ThemePreferencePanel: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.compactWorkbench) private var isCompact

    let themeMode: AppThemeMode
    let toggleTheme: () -> Void

    var body: some View {
        HStack(spacing: isCompact ? 12 : 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(theme.accent.opacity(0.16))
                Image(systemName: isCompact ? "circle.lefthalf.filled" : themeMode.icon)
                    .font(.system(size: isCompact ? 19 : 22, weight: .semibold))
                    .foregroundStyle(theme.accent)
            }
            .frame(width: isCompact ? 40 : 52, height: isCompact ? 40 : 52)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: SettingsPreferenceTextLayoutPolicy.verticalSpacing) {
                Text("外观模式")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(theme.primaryText)
                    .lineLimit(SettingsPreferenceTextLayoutPolicy.titleLineLimit)
                    .fixedSize(horizontal: false, vertical: true)
                if !isCompact {
                    Text(themeMode.title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(theme.secondaryText)
                        .lineLimit(SettingsPreferenceTextLayoutPolicy.statusLineLimit)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer()

            Button(action: toggleTheme) {
                Group {
                    if isCompact {
                        Text(themeMode.title)
                            .font(.subheadline.weight(.semibold))
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 14)
                            .frame(minWidth: 44, minHeight: 44)
                            .foregroundStyle(theme.accent)
                            .background(theme.chipSurface, in: Capsule())
                    } else {
                        Image(systemName: themeMode.icon)
                            .font(.system(size: 15, weight: .semibold))
                            .frame(
                                width: SettingsIconActionLayoutPolicy.iconButtonSize,
                                height: SettingsIconActionLayoutPolicy.iconButtonSize
                            )
                            .background(theme.accent, in: Circle())
                            .foregroundStyle(theme.inverseText)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                HeaderActionAccessibilityMetadata.themeToggleLabel(themeMode: themeMode)
            )
            .accessibilityValue(
                HeaderActionAccessibilityMetadata.themeToggleValue(themeMode: themeMode)
            )
            .accessibilityHint(
                HeaderActionAccessibilityMetadata.themeToggleHint(themeMode: themeMode)
            )
            .accessibilityInputLabels(
                HeaderActionAccessibilityMetadata.themeToggleInputLabels(themeMode: themeMode)
            )
            .accessibilityIdentifier(HeaderActionAccessibilityMetadata.settingsThemeToggleIdentifier)
        }
        .panelStyle(border: isCompact ? theme.border : theme.accent.opacity(0.26))
    }
}

struct WallpaperPreferencePanel: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.compactWorkbench) private var isCompact
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let wallpaperData: Data
    @Binding var selectedItem: PhotosPickerItem?
    let isImporting: Bool
    let panelContentWidth: CGFloat
    let clearWallpaper: () -> Void

    var body: some View {
        let hasCustomWallpaper = wallpaperData.isEmpty == false
        let pickerAccent = theme.accent
        let pickerForeground = theme.inverseText
        let plan = SettingsPreferenceRowLayoutPolicy.resolve(
            contentWidth: panelContentWidth,
            dynamicTypeSize: dynamicTypeSize,
            isCompact: isCompact
        )
        let layout = plan.mode == .horizontal
            ? AnyLayout(
                HStackLayout(
                    alignment: .top,
                    spacing: isCompact
                        ? SettingsPreferenceRowLayoutPolicy.compactHorizontalSpacing
                        : SettingsPreferenceRowLayoutPolicy.horizontalSpacing
                )
            )
            : AnyLayout(
                VStackLayout(
                    alignment: .leading,
                    spacing: SettingsPreferenceRowLayoutPolicy.stackedSpacing
                )
            )

        layout {
            wallpaperPreview
            wallpaperText
            wallpaperActions(
                hasCustomWallpaper: hasCustomWallpaper,
                pickerAccent: pickerAccent,
                pickerForeground: pickerForeground
            )
            .frame(
                maxWidth: plan.mode == .stacked ? .infinity : nil,
                alignment: .trailing
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .frame(minHeight: previewSize)
        .panelStyle(border: theme.border)
    }

    private var previewSize: CGFloat {
        isCompact ? SettingsPreferenceRowLayoutPolicy.compactPreviewSize
            : SettingsPreferenceRowLayoutPolicy.previewSize
    }

    private var wallpaperText: some View {
        VStack(alignment: .leading, spacing: SettingsPreferenceTextLayoutPolicy.verticalSpacing) {
            Text("壁纸")
                .font(.headline.weight(.semibold))
                .foregroundStyle(theme.primaryText)
                .lineLimit(SettingsPreferenceTextLayoutPolicy.titleLineLimit)
                .fixedSize(horizontal: false, vertical: true)
            Text(statusText)
                .font(isCompact ? .caption : .subheadline.weight(.bold))
                .foregroundStyle(theme.secondaryText)
                .lineLimit(SettingsPreferenceTextLayoutPolicy.statusLineLimit)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(
            minWidth: SettingsPreferenceRowLayoutPolicy.minimumTextWidth,
            maxWidth: .infinity,
            alignment: .leading
        )
    }

    @ViewBuilder
    private func wallpaperActions(
        hasCustomWallpaper: Bool,
        pickerAccent: Color,
        pickerForeground: Color
    ) -> some View {
        HStack(spacing: SettingsPreferenceRowLayoutPolicy.actionSpacing) {
            PhotosPicker(selection: $selectedItem, matching: .images) {
                ZStack {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 14, weight: .semibold))
                        .opacity(isImporting ? 0 : 1)
                    if isImporting {
                        ProgressView()
                            .tint(pickerForeground)
                    }
                }
                .frame(
                    width: SettingsIconActionLayoutPolicy.iconButtonSize,
                    height: SettingsIconActionLayoutPolicy.iconButtonSize
                )
                .background(pickerAccent, in: Circle())
                .foregroundStyle(pickerForeground)
            }
            .buttonStyle(.plain)
            .disabled(
                SettingsPreferenceRowLayoutPolicy.isChooseActionDisabled(
                    isImporting: isImporting
                )
            )
            .accessibilityLabel(
                WallpaperPreferenceAccessibilityMetadata.label(for: .choosePhoto)
            )
            .accessibilityValue(
                WallpaperPreferenceAccessibilityMetadata.value(
                    for: .choosePhoto,
                    hasCustomWallpaper: hasCustomWallpaper,
                    isImporting: isImporting
                )
            )
            .accessibilityHint(
                WallpaperPreferenceAccessibilityMetadata.hint(
                    for: .choosePhoto,
                    hasCustomWallpaper: hasCustomWallpaper,
                    isImporting: isImporting
                )
            )
            .accessibilityInputLabels(
                WallpaperPreferenceAccessibilityMetadata.inputLabels(for: .choosePhoto)
            )
            .accessibilityIdentifier(
                WallpaperPreferenceAccessibilityMetadata.identifier(for: .choosePhoto)
            )

            Button(action: clearWallpaper) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .frame(
                        width: SettingsIconActionLayoutPolicy.iconButtonSize,
                        height: SettingsIconActionLayoutPolicy.iconButtonSize
                    )
                    .background(theme.chipSurface, in: Circle())
                    .overlay(Circle().stroke(theme.border, lineWidth: 1))
                    .foregroundStyle(theme.primaryText)
            }
            .buttonStyle(.plain)
            .disabled(
                SettingsPreferenceRowLayoutPolicy.isClearActionDisabled(
                    hasCustomWallpaper: hasCustomWallpaper,
                    isImporting: isImporting
                )
            )
            .opacity(
                SettingsPreferenceRowLayoutPolicy.isClearActionDisabled(
                    hasCustomWallpaper: hasCustomWallpaper,
                    isImporting: isImporting
                ) ? 0.42 : 1
            )
            .accessibilityLabel(
                WallpaperPreferenceAccessibilityMetadata.label(for: .clearCustomWallpaper)
            )
            .accessibilityValue(
                WallpaperPreferenceAccessibilityMetadata.value(
                    for: .clearCustomWallpaper,
                    hasCustomWallpaper: hasCustomWallpaper,
                    isImporting: isImporting
                )
            )
            .accessibilityHint(
                WallpaperPreferenceAccessibilityMetadata.hint(
                    for: .clearCustomWallpaper,
                    hasCustomWallpaper: hasCustomWallpaper,
                    isImporting: isImporting
                )
            )
            .accessibilityInputLabels(
                WallpaperPreferenceAccessibilityMetadata.inputLabels(for: .clearCustomWallpaper)
            )
            .accessibilityIdentifier(
                WallpaperPreferenceAccessibilityMetadata.identifier(for: .clearCustomWallpaper)
            )
        }
    }

    private var statusText: String {
        if isImporting {
            return "正在处理相册图片"
        }
        return wallpaperData.isEmpty ? "系统背景" : "相册图片已启用"
    }

    @ViewBuilder
    private var wallpaperPreview: some View {
        Group {
            if let image = UIImage(data: wallpaperData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: previewSize,
                        height: previewSize
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(theme.border, lineWidth: 1)
                    }
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: theme.backgroundColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Image(systemName: "photo.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(theme.accent)
                }
                .frame(
                    width: previewSize,
                    height: previewSize
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(theme.border, lineWidth: 1)
                }
            }
        }
        .accessibilityHidden(true)
    }
}

struct OptimizerDashboard: View {
    @EnvironmentObject private var optimizer: DeviceOptimizer
    var isModal = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if isModal {
                    Color(red: 0.045, green: 0.047, blue: 0.055).ignoresSafeArea()
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(
                            eyebrow: "APPLE SILICON",
                            title: "芯片部署优化",
                            subtitle: "Apple Silicon 运行计划与模拟预算，非实时设备性能测量。"
                        )

                        ChipReadinessCard(
                            progress: optimizer.deploymentReadiness,
                            thermalState: optimizer.thermalState,
                            privacyGuardEnabled: optimizer.isOfflinePrivacyGuardEnabled,
                            panelContentWidth: ChipReadinessLayoutPolicy.panelContentWidth(
                                forPanelWidth: max(geometry.size.width - 36, 0)
                            )
                        )

                        OptimizerMetricGrid(
                            metrics: optimizer.metrics, availableWidth: max(geometry.size.width - 36, 0)
                        )

                        OptimizationToggleGrid(
                            items: optimizer.switches,
                            availableWidth: max(geometry.size.width - 36, 0),
                            titleColor: .white,
                            toggle: { optimizer.toggle($0) }
                        )
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, isModal ? 22 : 16)
                    .padding(.bottom, 28)
                }
            }
        }
    }
}

struct ChipReadinessCard: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let progress: Double
    let thermalState: String
    let privacyGuardEnabled: Bool
    let panelContentWidth: CGFloat

    var body: some View {
        let plan = ChipReadinessLayoutPolicy.resolve(
            contentWidth: panelContentWidth,
            usesAccessibilityDynamicType: dynamicTypeSize >= .accessibility1
        )
        let layout = plan.mode == .horizontal
            ? AnyLayout(HStackLayout(spacing: ChipReadinessLayoutPolicy.horizontalSpacing))
            : AnyLayout(VStackLayout(alignment: .leading, spacing: ChipReadinessLayoutPolicy.stackedSpacing))

        layout {
            ReadinessRing(
                progress: progress,
                diameter: ChipReadinessLayoutPolicy.ringDiameter,
                accessibilityIdentifier: ChipReadinessAccessibilityMetadata.chipRingIdentifier
            )
                .frame(
                    width: ChipReadinessLayoutPolicy.ringSlot,
                    height: ChipReadinessLayoutPolicy.ringSlot
                )
                .layoutPriority(1)

            VStack(alignment: .leading, spacing: 8) {
                Text("A17 Pro / M 系列准备度")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(theme.primaryText)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(
                    ChipReadinessAccessibilityMetadata.summary(
                        thermalState: thermalState,
                        privacyGuardEnabled: privacyGuardEnabled
                    )
                )
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(theme.secondaryText)
                    .lineLimit(4)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)

                ProgressView(value: progress)
                    .tint(.cyan)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(
            maxWidth: .infinity,
            minHeight: ChipReadinessLayoutPolicy.ringSlot,
            alignment: .leading
        )
        .panelStyle(border: theme.accent.opacity(0.3))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(ChipReadinessAccessibilityMetadata.cardLabel)
        .accessibilityValue(
            ChipReadinessAccessibilityMetadata.cardValue(
                progress: progress,
                thermalState: thermalState,
                privacyGuardEnabled: privacyGuardEnabled
            )
        )
        .accessibilityHint(ChipReadinessAccessibilityMetadata.cardHint)
        .accessibilityInputLabels(ChipReadinessAccessibilityMetadata.cardInputLabels)
        .accessibilityIdentifier(ChipReadinessAccessibilityMetadata.cardIdentifier)
    }
}

enum ChipReadinessLayoutMode: Equatable {
    case stacked
    case horizontal
}

struct ChipReadinessLayoutPlan: Equatable {
    let mode: ChipReadinessLayoutMode
    let ringSlot: CGFloat
    let ringDiameter: CGFloat
}

enum ChipReadinessLayoutPolicy {
    static let horizontalContentWidthThreshold: CGFloat = 354
    static let ringSlot: CGFloat = 86
    static let ringDiameter: CGFloat = 66
    static let horizontalSpacing: CGFloat = 16
    static let stackedSpacing: CGFloat = 12

    static func panelContentWidth(forPanelWidth width: CGFloat) -> CGFloat {
        guard width.isFinite, width > 0 else { return 0 }
        return max(width - WorkbenchVisualStylePolicy.panelPadding * 2, 0)
    }

    static func resolve(
        contentWidth: CGFloat,
        usesAccessibilityDynamicType: Bool
    ) -> ChipReadinessLayoutPlan {
        let isValidWidth = contentWidth.isFinite && contentWidth > 0
        let canUseHorizontal = isValidWidth
            && contentWidth >= horizontalContentWidthThreshold
            && usesAccessibilityDynamicType == false

        return ChipReadinessLayoutPlan(
            mode: canUseHorizontal ? .horizontal : .stacked,
            ringSlot: ringSlot,
            ringDiameter: ringDiameter
        )
    }
}

enum ChipReadinessAccessibilityMetadata {
    static let cardLabel = "芯片部署准备度"
    static let cardHint = "显示本地芯片准备度和运行策略摘要；不会下载模型权重，不会启动真实 runtime，也不会发送到云端服务。"
    static let cardInputLabels = ["芯片准备度", "部署准备度", "Apple Silicon 准备度"]
    static let cardIdentifier = "chip-readiness-card"
    static let ringLabel = "部署准备度圆环"
    static let ringHint = "表示本地模拟部署准备度；不会下载模型权重，不会启动真实 runtime，也不会发送到云端服务。"
    static let ringInputLabels = ["准备度圆环", "部署准备度", "芯片准备度圆环"]
    static let headerRingIdentifier = "header-readiness-ring"
    static let chipRingIdentifier = "chip-readiness-ring"

    static func clampedProgress(_ progress: Double) -> Double {
        min(max(progress, 0), 1)
    }

    static func percent(for progress: Double) -> Int {
        Int((clampedProgress(progress) * 100).rounded())
    }

    static func summary(thermalState: String, privacyGuardEnabled: Bool) -> String {
        "热状态 \(thermalState) · 模拟 Metal 预热 · \(privacyGuardStatus(isEnabled: privacyGuardEnabled))"
    }

    static func cardValue(
        progress: Double,
        thermalState: String,
        privacyGuardEnabled: Bool
    ) -> String {
        "准备度 \(percent(for: progress))%。\(summary(thermalState: thermalState, privacyGuardEnabled: privacyGuardEnabled))。"
    }

    static func ringValue(progress: Double) -> String {
        "准备度 \(percent(for: progress))%"
    }

    static func privacyGuardStatus(isEnabled: Bool) -> String {
        isEnabled ? "离线隐私保护开启" : "离线隐私保护关闭"
    }
}

enum OptimizerMetricTextLayoutPolicy {
    static let verticalSpacing: CGFloat = 10
    static let indicatorSize: CGFloat = 8
    static let labelLineLimit = 2
    static let valueLineLimit = 2
    static let detailLineLimit = 3
    static let detailLineSpacing: CGFloat = 2
    static let minimumCardHeight: CGFloat = 158

    static var allowsMultilineLabel: Bool {
        labelLineLimit > 1
    }

    static var allowsMultilineValue: Bool {
        valueLineLimit > 1
    }

    static var allowsMultilineDetail: Bool {
        detailLineLimit > 1
    }
}

struct OptimizerMetricCard: View {
    @Environment(\.appTheme) private var theme

    let metric: OptimizerMetric

    var body: some View {
        VStack(alignment: .leading, spacing: OptimizerMetricTextLayoutPolicy.verticalSpacing) {
            HStack(alignment: .top) {
                Text(metric.label)
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(theme.secondaryText)
                    .lineLimit(OptimizerMetricTextLayoutPolicy.labelLineLimit)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                Circle()
                    .fill(metric.tint)
                    .frame(
                        width: OptimizerMetricTextLayoutPolicy.indicatorSize,
                        height: OptimizerMetricTextLayoutPolicy.indicatorSize
                    )
            }

            Text(metric.value)
                .font(.title3.weight(.semibold))
                .foregroundStyle(theme.primaryText)
                .lineLimit(OptimizerMetricTextLayoutPolicy.valueLineLimit)
                .fixedSize(horizontal: false, vertical: true)

            Text(metric.detail)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(theme.secondaryText)
                .lineLimit(OptimizerMetricTextLayoutPolicy.detailLineLimit)
                .lineSpacing(OptimizerMetricTextLayoutPolicy.detailLineSpacing)
                .fixedSize(horizontal: false, vertical: true)

            ProgressView(value: metric.progress)
                .tint(metric.tint)
        }
        .frame(
            maxWidth: .infinity,
            minHeight: OptimizerMetricTextLayoutPolicy.minimumCardHeight,
            alignment: .topLeading
        )
        .panelStyle()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(OptimizerMetricAccessibilityMetadata.label(for: metric))
        .accessibilityValue(OptimizerMetricAccessibilityMetadata.value(for: metric))
        .accessibilityHint(OptimizerMetricAccessibilityMetadata.hint)
        .accessibilityInputLabels(OptimizerMetricAccessibilityMetadata.inputLabels(for: metric))
        .accessibilityIdentifier(OptimizerMetricAccessibilityMetadata.identifier(for: metric))
    }
}

struct OptimizerMetricGrid: View {
    let metrics: [OptimizerMetric]
    let availableWidth: CGFloat

    var body: some View {
        metricGrid(columnCount: OptimizerMetricGridLayoutPolicy.columnCount(for: availableWidth))
    }

    private func metricGrid(columnCount: Int) -> some View {
        LazyVGrid(
            columns: OptimizerMetricGridLayoutPolicy.columns(forColumnCount: columnCount),
            spacing: OptimizerMetricGridLayoutPolicy.spacing
        ) {
            ForEach(metrics) { metric in
                OptimizerMetricCard(metric: metric)
            }
        }
        .frame(minWidth: OptimizerMetricGridLayoutPolicy.minimumWidth(forColumnCount: columnCount))
    }
}

enum OptimizerMetricGridLayoutPolicy {
    static let minimumCardWidth: CGFloat = 170
    static let spacing: CGFloat = 10
    static let maxColumnCount = 2

    static var twoColumnThreshold: CGFloat {
        minimumWidth(forColumnCount: maxColumnCount)
    }

    static func columnCount(for availableWidth: CGFloat) -> Int {
        availableWidth >= twoColumnThreshold ? maxColumnCount : 1
    }

    static func columns(for availableWidth: CGFloat) -> [GridItem] {
        columns(forColumnCount: columnCount(for: availableWidth))
    }

    static func columns(forColumnCount columnCount: Int) -> [GridItem] {
        let clampedCount = min(max(columnCount, 1), maxColumnCount)
        return Array(
            repeating: GridItem(.flexible(minimum: minimumCardWidth), spacing: spacing),
            count: clampedCount
        )
    }

    static func minimumWidth(forColumnCount columnCount: Int) -> CGFloat {
        let clampedCount = min(max(columnCount, 1), maxColumnCount)
        return CGFloat(clampedCount) * minimumCardWidth
            + CGFloat(clampedCount - 1) * spacing
    }
}

enum OptimizerMetricAccessibilityMetadata {
    static let hint = "显示本地 Apple Silicon 优化指标摘要；不会下载模型权重，不会启动真实 runtime，不会发送到云端服务，也不会绕过 artifact verified 门禁。"

    static func label(for metric: OptimizerMetric) -> String {
        "优化指标 \(metric.label)"
    }

    static func value(for metric: OptimizerMetric) -> String {
        "\(metric.value)。进度 \(percent(for: metric.progress))%。\(metric.detail)。"
    }

    static func inputLabels(for metric: OptimizerMetric) -> [String] {
        [metric.label, "\(metric.label) 指标", "查看 \(metric.label)"]
    }

    static func identifier(for metric: OptimizerMetric) -> String {
        "optimizer-metric-\(slug(for: metric.label))"
    }

    static func percent(for progress: Double) -> Int {
        Int((min(max(progress, 0), 1) * 100).rounded())
    }

    private static func slug(for label: String) -> String {
        var result = ""
        var previousWasSeparator = false

        for scalar in label.lowercased().unicodeScalars {
            if CharacterSet.alphanumerics.contains(scalar) {
                result.unicodeScalars.append(scalar)
                previousWasSeparator = false
            } else if previousWasSeparator == false {
                result.append("-")
                previousWasSeparator = true
            }
        }

        return result.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }
}

enum OptimizationToggleAccessibilityMetadata {
    static func label(for item: OptimizationSwitch) -> String {
        "运行策略 \(item.title)"
    }

    static func value(for item: OptimizationSwitch) -> String {
        "\(item.isEnabled ? "已开启" : "已关闭")。\(item.subtitle)"
    }

    static func hint(for item: OptimizationSwitch) -> String {
        "只切换本地运行策略 \(item.title)；不会下载模型权重，不会启动真实 runtime，也不会发送到云端服务。"
    }

    static func inputLabels(for item: OptimizationSwitch) -> [String] {
        [
            item.title,
            "\(item.isEnabled ? "关闭" : "开启") \(item.title)",
            "切换 \(item.title)"
        ]
    }

    static func identifier(for item: OptimizationSwitch) -> String {
        let slug = item.title
            .lowercased()
            .split { !$0.isLetter && !$0.isNumber }
            .joined(separator: "-")
        return "optimizer-toggle-\(slug)"
    }
}

enum OptimizationToggleTextLayoutPolicy {
    static let gridTitleLineLimit = 2
    static let rowTitleLineLimit = 2
    static let subtitleLineLimit = 2
    static let rowVerticalSpacing: CGFloat = 3
    static let subtitleLineSpacing: CGFloat = 2

    static var allowsMultilineGridTitle: Bool {
        gridTitleLineLimit > 1
    }

    static var allowsMultilineRowTitle: Bool {
        rowTitleLineLimit > 1
    }

    static var allowsMultilineSubtitle: Bool {
        subtitleLineLimit > 1
    }
}

struct OptimizationToggleGrid: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.compactWorkbench) private var isCompact

    let items: [OptimizationSwitch]
    let availableWidth: CGFloat
    var titleColor: Color?
    var border: Color = Color.primary.opacity(0.12)
    let toggle: (OptimizationSwitch) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("运行策略")
                .font(.headline.weight(.semibold))
                .foregroundStyle(titleColor ?? theme.primaryText)
                .lineLimit(OptimizationToggleTextLayoutPolicy.gridTitleLineLimit)
                .fixedSize(horizontal: false, vertical: true)

            if isCompact {
                VStack(spacing: 0) {
                    ForEach(items) { item in
                        OptimizationToggleRow(item: item, toggle: { toggle(item) })
                        if item.id != items.last?.id {
                            Divider().overlay(theme.border)
                                .padding(.leading, 32)
                        }
                    }
                }
            } else {
                toggleGrid(columnCount: OptimizationToggleGridLayoutPolicy.columnCount(
                    for: max(availableWidth - WorkbenchVisualStylePolicy.panelPadding * 2, 0)
                ))
            }
        }
        .panelStyle(border: border)
    }

    private func toggleGrid(columnCount: Int) -> some View {
        LazyVGrid(
            columns: OptimizationToggleGridLayoutPolicy.columns(forColumnCount: columnCount),
            spacing: OptimizationToggleGridLayoutPolicy.spacing
        ) {
            ForEach(items) { item in
                OptimizationToggleRow(
                    item: item,
                    toggle: { toggle(item) }
                )
            }
        }
        .frame(minWidth: OptimizationToggleGridLayoutPolicy.minimumWidth(forColumnCount: columnCount))
    }
}

enum OptimizationToggleGridLayoutPolicy {
    static let minimumCardWidth: CGFloat = 250
    static let spacing: CGFloat = 10
    static let maxColumnCount = 2

    static var twoColumnThreshold: CGFloat {
        minimumWidth(forColumnCount: maxColumnCount)
    }

    static func columnCount(for availableWidth: CGFloat) -> Int {
        availableWidth >= twoColumnThreshold ? maxColumnCount : 1
    }

    static func columns(for availableWidth: CGFloat) -> [GridItem] {
        columns(forColumnCount: columnCount(for: availableWidth))
    }

    static func columns(forColumnCount columnCount: Int) -> [GridItem] {
        let clampedCount = min(max(columnCount, 1), maxColumnCount)
        return Array(
            repeating: GridItem(.flexible(minimum: minimumCardWidth), spacing: spacing),
            count: clampedCount
        )
    }

    static func minimumWidth(forColumnCount columnCount: Int) -> CGFloat {
        let clampedCount = min(max(columnCount, 1), maxColumnCount)
        return CGFloat(clampedCount) * minimumCardWidth
            + CGFloat(clampedCount - 1) * spacing
    }
}

enum OptimizationToggleRowLayoutPolicy {
    static let minimumTouchTarget: CGFloat = 44
    static let rowMinHeight: CGFloat = minimumTouchTarget

    static func usesMinimumTouchTarget() -> Bool {
        rowMinHeight >= minimumTouchTarget
    }
}

struct OptimizationToggleRow: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.compactWorkbench) private var isCompact

    let item: OptimizationSwitch
    let toggle: () -> Void

    var body: some View {
        Button(action: toggle) {
            HStack(spacing: 12) {
                Image(systemName: item.isEnabled ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(item.isEnabled ? theme.success : theme.tertiaryText)

                VStack(
                    alignment: .leading,
                    spacing: OptimizationToggleTextLayoutPolicy.rowVerticalSpacing
                ) {
                    Text(isCompact ? CompactWorkbenchPolicy.toggleTitle(item) : item.title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(theme.primaryText)
                        .lineLimit(OptimizationToggleTextLayoutPolicy.rowTitleLineLimit)
                        .fixedSize(horizontal: false, vertical: true)
                    if !isCompact {
                        Text(item.subtitle)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(theme.secondaryText)
                            .lineLimit(OptimizationToggleTextLayoutPolicy.subtitleLineLimit)
                            .lineSpacing(OptimizationToggleTextLayoutPolicy.subtitleLineSpacing)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, isCompact ? 0 : 12)
            .padding(.vertical, 12)
            .frame(minHeight: OptimizationToggleRowLayoutPolicy.rowMinHeight)
            .contentShape(Rectangle())
            .background(isCompact ? Color.clear : theme.recessedSurface,
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(OptimizationToggleAccessibilityMetadata.label(for: item))
        .accessibilityValue(OptimizationToggleAccessibilityMetadata.value(for: item))
        .accessibilityHint(OptimizationToggleAccessibilityMetadata.hint(for: item))
        .accessibilityInputLabels(OptimizationToggleAccessibilityMetadata.inputLabels(for: item)
            + (isCompact ? [CompactWorkbenchPolicy.toggleTitle(item)] : []))
        .accessibilityAddTraits(item.isEnabled ? .isSelected : [])
        .accessibilityIdentifier(OptimizationToggleAccessibilityMetadata.identifier(for: item))
    }
}

