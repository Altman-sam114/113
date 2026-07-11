import Foundation
import PhotosUI
import SwiftUI
import UIKit
import UniformTypeIdentifiers

enum AppThemeMode: String, CaseIterable, Identifiable {
    case dark
    case light

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dark:
            return "sun.max.fill"
        case .light:
            return "moon.fill"
        }
    }

    var title: String {
        switch self {
        case .dark:
            return "暗色"
        case .light:
            return "亮色"
        }
    }

    var colorScheme: ColorScheme {
        switch self {
        case .dark:
            return .dark
        case .light:
            return .light
        }
    }

    var toggled: AppThemeMode {
        self == .dark ? .light : .dark
    }
}

struct AppThemePalette {
    let mode: AppThemeMode

    var isDark: Bool { mode == .dark }
    var primaryText: Color { isDark ? .white : Color(red: 0.08, green: 0.1, blue: 0.14) }
    var secondaryText: Color { primaryText.opacity(isDark ? 0.62 : 0.66) }
    var tertiaryText: Color { primaryText.opacity(isDark ? 0.42 : 0.46) }
    var inverseText: Color { isDark ? .black : .white }
    var accent: Color { isDark ? .cyan : Color(red: 0.0, green: 0.45, blue: 0.78) }
    var success: Color { isDark ? .green : Color(red: 0.03, green: 0.5, blue: 0.28) }
    var warning: Color { isDark ? .orange : Color(red: 0.78, green: 0.38, blue: 0.0) }
    var surface: Color { isDark ? Color.white.opacity(0.1) : Color.white.opacity(0.72) }
    var recessedSurface: Color { isDark ? Color.black.opacity(0.28) : Color.white.opacity(0.84) }
    var chipSurface: Color { isDark ? Color.white.opacity(0.08) : Color(red: 0.93, green: 0.96, blue: 1.0) }
    var border: Color { isDark ? Color.white.opacity(0.14) : Color.black.opacity(0.1) }
    var subtleBorder: Color { isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.06) }
    var grid: Color { isDark ? Color.white.opacity(0.12) : Color.black.opacity(0.06) }

    var backgroundColors: [Color] {
        if isDark {
            return [
                Color(red: 0.035, green: 0.046, blue: 0.078),
                Color(red: 0.02, green: 0.024, blue: 0.042),
                Color(red: 0.047, green: 0.058, blue: 0.092)
            ]
        }

        return [
            Color(red: 0.96, green: 0.985, blue: 1.0),
            Color(red: 0.925, green: 0.955, blue: 0.99),
            Color(red: 0.985, green: 0.99, blue: 0.97)
        ]
    }
}

enum WorkspaceLayoutMode: Equatable {
    case portrait
    case landscapeCompact
    case landscapeRegular

    private static let minimumSidebarWidth: CGFloat = 700
    private static let regularMinimumWidth: CGFloat = 980
    private static let regularMinimumHeight: CGFloat = 700

    static func resolve(for size: CGSize) -> WorkspaceLayoutMode {
        guard size.width >= minimumSidebarWidth else {
            return .portrait
        }

        if size.width >= regularMinimumWidth, size.height >= regularMinimumHeight {
            return .landscapeRegular
        }

        return .landscapeCompact
    }

    var usesSidebar: Bool {
        self != .portrait
    }

    var usesDetailedSidebar: Bool {
        self == .landscapeRegular
    }

    func sidebarWidth(for size: CGSize) -> CGFloat {
        switch self {
        case .portrait:
            return 0
        case .landscapeCompact:
            return min(max(size.width * 0.30, 250), 310)
        case .landscapeRegular:
            return min(max(size.width * 0.32, 320), 390)
        }
    }
}

enum SessionSidebarLayoutPolicy {
    static let minimumWidth: CGFloat = 240
    static let maximumWidth: CGFloat = 310
    static let widthRatio: CGFloat = 0.28

    static func width(for size: CGSize, layoutMode: WorkspaceLayoutMode) -> CGFloat {
        guard layoutMode.usesSidebar else {
            return 0
        }

        return min(max(size.width * widthRatio, minimumWidth), maximumWidth)
    }
}

enum ModelLibraryLayoutMode: Equatable {
    case singleColumn
    case twoColumn

    static let twoColumnMinimumWidth: CGFloat = 760
    static let minimumControlColumnWidth: CGFloat = 300
    static let maximumControlColumnWidth: CGFloat = 390

    static func resolve(for size: CGSize) -> ModelLibraryLayoutMode {
        size.width >= twoColumnMinimumWidth ? .twoColumn : .singleColumn
    }

    func controlColumnWidth(for size: CGSize) -> CGFloat {
        guard self == .twoColumn else {
            return 0
        }
        return min(
            max(size.width * 0.36, Self.minimumControlColumnWidth),
            Self.maximumControlColumnWidth
        )
    }
}

enum ModelDetailColumnLayoutPolicy {
    static let minimumReadableWidth: CGFloat = 320
    static let maximumReadableWidth: CGFloat = 680
    static let interColumnSpacing: CGFloat = 14

    static func width(for size: CGSize, layoutMode: ModelLibraryLayoutMode) -> CGFloat {
        guard layoutMode == .twoColumn, size.width.isFinite, size.width > 0 else {
            return 0
        }

        let controlColumnWidth = layoutMode.controlColumnWidth(for: size)
        guard controlColumnWidth.isFinite else {
            return 0
        }

        let availableWidth = size.width - controlColumnWidth - interColumnSpacing
        guard availableWidth.isFinite, availableWidth > 0 else {
            return 0
        }

        return min(
            max(availableWidth, minimumReadableWidth),
            maximumReadableWidth
        )
    }
}

enum ModelLibraryWorkspaceLayoutPolicy {
    static let horizontalPadding: CGFloat = 18
    static let minimumReadableWidth: CGFloat = 320
    static let maximumContentWidth: CGFloat = ModelLibraryLayoutMode.maximumControlColumnWidth
        + ModelDetailColumnLayoutPolicy.interColumnSpacing
        + ModelDetailColumnLayoutPolicy.maximumReadableWidth

    static func contentWidth(forContainerWidth containerWidth: CGFloat) -> CGFloat {
        guard containerWidth.isFinite, containerWidth > 0 else {
            return minimumReadableWidth
        }

        let paddedWidth = max(containerWidth - horizontalPadding * 2, 0)
        guard paddedWidth >= minimumReadableWidth else {
            return paddedWidth
        }

        return min(paddedWidth, maximumContentWidth)
    }
}

enum SectionHeaderTextLayoutPolicy {
    static let verticalSpacing: CGFloat = 6
    static let eyebrowTracking: CGFloat = 1.1
    static let eyebrowLineLimit = 1
    static let titleLineLimit = 2
    static let subtitleLineLimit = 3
    static let subtitleLineSpacing: CGFloat = 3

    static var allowsMultilineTitle: Bool {
        titleLineLimit > 1
    }
}

enum HeaderTitleTextLayoutPolicy {
    static let verticalSpacing: CGFloat = 4
    static let eyebrowTracking: CGFloat = 1.2
    static let eyebrowLineLimit = 1
    static let titleLineLimit = 2

    static var allowsMultilineTitle: Bool {
        titleLineLimit > 1
    }
}

enum WallpaperImportError: LocalizedError, Equatable {
    case unreadableImage
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .unreadableImage:
            return "无法读取这张图片，请换一张照片。"
        case .encodingFailed:
            return "壁纸压缩失败，请换一张照片。"
        }
    }
}

enum WallpaperImageProcessor {
    static let defaultMaxPixel: CGFloat = 1800
    static let defaultCompressionQuality: CGFloat = 0.78

    static func optimizedJPEGData(
        from data: Data,
        maxPixel: CGFloat = defaultMaxPixel,
        compressionQuality: CGFloat = defaultCompressionQuality
    ) throws -> Data {
        guard let image = UIImage(data: data) else {
            throw WallpaperImportError.unreadableImage
        }

        return try optimizedJPEGData(
            from: image,
            maxPixel: maxPixel,
            compressionQuality: compressionQuality
        )
    }

    static func optimizedJPEGData(
        from image: UIImage,
        maxPixel: CGFloat = defaultMaxPixel,
        compressionQuality: CGFloat = defaultCompressionQuality
    ) throws -> Data {
        let targetSize = scaledPixelSize(for: image, maxPixel: maxPixel)
        guard targetSize.width > 0, targetSize.height > 0 else {
            throw WallpaperImportError.unreadableImage
        }

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        let renderedImage = renderer.image { context in
            UIColor.black.setFill()
            context.fill(CGRect(origin: .zero, size: targetSize))
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }

        guard let jpegData = renderedImage.jpegData(compressionQuality: compressionQuality) else {
            throw WallpaperImportError.encodingFailed
        }

        return jpegData
    }

    static func scaledPixelSize(for image: UIImage, maxPixel: CGFloat = defaultMaxPixel) -> CGSize {
        let sourceSize: CGSize
        if let cgImage = image.cgImage {
            sourceSize = CGSize(width: cgImage.width, height: cgImage.height)
        } else {
            sourceSize = CGSize(width: image.size.width * image.scale, height: image.size.height * image.scale)
        }

        return scaledPixelSize(
            width: sourceSize.width,
            height: sourceSize.height,
            maxPixel: maxPixel
        )
    }

    static func scaledPixelSize(width: CGFloat, height: CGFloat, maxPixel: CGFloat = defaultMaxPixel) -> CGSize {
        guard width > 0, height > 0, maxPixel > 0 else {
            return .zero
        }

        let scale = min(1, maxPixel / max(width, height))
        return CGSize(
            width: max(1, (width * scale).rounded()),
            height: max(1, (height * scale).rounded())
        )
    }
}

private struct AppThemeKey: EnvironmentKey {
    static let defaultValue = AppThemePalette(mode: .dark)
}

extension EnvironmentValues {
    var appTheme: AppThemePalette {
        get { self[AppThemeKey.self] }
        set { self[AppThemeKey.self] = newValue }
    }
}

private struct WorkspaceTabSelectionFocusedKey: FocusedValueKey {
    typealias Value = Binding<WorkspaceTab>
}

private struct SessionCommandActionsFocusedKey: FocusedValueKey {
    typealias Value = SessionCommandActions
}

extension FocusedValues {
    var workspaceTabSelection: Binding<WorkspaceTab>? {
        get { self[WorkspaceTabSelectionFocusedKey.self] }
        set { self[WorkspaceTabSelectionFocusedKey.self] = newValue }
    }

    var sessionCommandActions: SessionCommandActions? {
        get { self[SessionCommandActionsFocusedKey.self] }
        set { self[SessionCommandActionsFocusedKey.self] = newValue }
    }
}

struct ContentView: View {
    @EnvironmentObject private var catalog: ModelCatalog
    @EnvironmentObject private var inference: InferenceEngine
    @EnvironmentObject private var optimizer: DeviceOptimizer

    @State private var selectedTab: WorkspaceTab = ContentView.initialTab
    @State private var composerFocusRequest = ComposerFocusRequest.initial
    @AppStorage("appThemeMode") private var themeModeStorage = AppThemeMode.dark.rawValue
    @AppStorage("customWallpaperImageData") private var wallpaperImageData: Data = Data()

    var body: some View {
        let themeMode = AppThemeMode(rawValue: themeModeStorage) ?? .dark
        let theme = AppThemePalette(mode: themeMode)
        let selectedValidation = catalog.validation(for: catalog.selectedModel)

        NavigationStack {
            ZStack {
                AppBackground(theme: theme, wallpaperData: wallpaperImageData)

                GeometryReader { proxy in
                    let layoutMode = WorkspaceLayoutMode.resolve(for: proxy.size)
                    if layoutMode.usesSidebar {
                        landscapeLayout(
                            themeMode: themeMode,
                            selectedValidation: selectedValidation,
                            size: proxy.size,
                            layoutMode: layoutMode
                        )
                    } else {
                        portraitLayout(themeMode: themeMode, selectedValidation: selectedValidation)
                    }
                }
            }
            .environment(\.appTheme, theme)
            .preferredColorScheme(themeMode.colorScheme)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
        }
        .focusedSceneValue(\.workspaceTabSelection, workspaceSelection)
    }

    private static var initialTab: WorkspaceTab {
        ProcessInfo.processInfo.arguments.contains("--open-models") ? .models : .chat
    }

    private var workspaceSelection: Binding<WorkspaceTab> {
        Binding(
            get: { selectedTab },
            set: { selectWorkspace($0) }
        )
    }

    private var currentTheme: AppThemePalette {
        AppThemePalette(mode: AppThemeMode(rawValue: themeModeStorage) ?? .dark)
    }

    private func selectWorkspace(
        _ tab: WorkspaceTab,
        focusReason: ComposerFocusReason? = nil
    ) {
        selectedTab = tab
        if ComposerFocusPolicy.requestsComposerFocus(afterSelecting: tab) {
            requestComposerFocus(for: focusReason ?? .openChatWorkspace)
        }
    }

    private func openChatAndFocus(_ reason: ComposerFocusReason) {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
            selectWorkspace(.chat, focusReason: reason)
        }
    }

    private func requestComposerFocus(for reason: ComposerFocusReason) {
        guard ComposerFocusPolicy.requestsComposerFocus(after: reason) else {
            return
        }
        composerFocusRequest = composerFocusRequest.next(for: reason)
    }

    private func clearComposerFocusRequest() {
        composerFocusRequest = .initial
    }

    private func headerView(themeMode: AppThemeMode, selectedValidation: ArtifactValidationResult) -> some View {
        HeaderView(
            model: catalog.selectedModel,
            readiness: optimizer.deploymentReadiness,
            tokensPerSecond: inference.currentTokensPerSecond,
            memoryUsageMB: inference.memoryUsageMB,
            backend: inference.currentBackend,
            availability: selectedValidation.availability,
            isGenerating: inference.isGenerating,
            isSimulated: inference.lastResultWasSimulated,
            themeMode: themeMode,
            toggleTheme: {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                    themeModeStorage = themeMode.toggled.rawValue
                }
            },
            showModels: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                    selectWorkspace(.models)
                }
            }
        )
    }

    private func portraitLayout(themeMode: AppThemeMode, selectedValidation: ArtifactValidationResult) -> some View {
        VStack(spacing: 0) {
            headerView(themeMode: themeMode, selectedValidation: selectedValidation)
                .padding(.horizontal, 18)
                .padding(.top, 8)

            tabPicker
                .padding(.horizontal, 18)
                .padding(.top, 14)

            workspacePages(themeMode: themeMode)
        }
    }

    private func landscapeLayout(
        themeMode: AppThemeMode,
        selectedValidation: ArtifactValidationResult,
        size: CGSize,
        layoutMode: WorkspaceLayoutMode
    ) -> some View {
        let theme = currentTheme
        let sidebarWidth = layoutMode.sidebarWidth(for: size)

        return HStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    headerView(themeMode: themeMode, selectedValidation: selectedValidation)
                    sidebarTabPicker(isDetailed: layoutMode.usesDetailedSidebar)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
            }
            .scrollIndicators(.hidden)
            .frame(width: sidebarWidth)
            .background(.ultraThinMaterial)
            .overlay(alignment: .trailing) {
                Rectangle()
                    .fill(theme.border)
                    .frame(width: 1)
            }

            workspacePageContent(themeMode: themeMode)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func workspacePages(themeMode: AppThemeMode) -> some View {
        TabView(selection: workspaceSelection) {
            ChatWorkspace(
                composerFocusRequest: composerFocusRequest,
                requestComposerFocus: requestComposerFocus,
                clearComposerFocusRequest: clearComposerFocusRequest
            )
                .tag(WorkspaceTab.chat)

            ModelLibraryView()
                .tag(WorkspaceTab.models)

            PromptTemplatesWorkspace(openChat: openChatAndFocus)
            .tag(WorkspaceTab.prompts)

            SettingsWorkspace(
                themeMode: themeMode,
                wallpaperData: wallpaperImageData,
                toggleTheme: {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        themeModeStorage = themeMode.toggled.rawValue
                    }
                },
                setWallpaperData: { data in
                    wallpaperImageData = data
                },
                clearWallpaper: {
                    wallpaperImageData = Data()
                }
            )
            .tag(WorkspaceTab.settings)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }

    @ViewBuilder
    private func workspacePageContent(themeMode: AppThemeMode) -> some View {
        switch selectedTab {
        case .chat:
            ChatWorkspace(
                composerFocusRequest: composerFocusRequest,
                requestComposerFocus: requestComposerFocus,
                clearComposerFocusRequest: clearComposerFocusRequest
            )
        case .models:
            ModelLibraryView()
        case .prompts:
            PromptTemplatesWorkspace(openChat: openChatAndFocus)
        case .settings:
            SettingsWorkspace(
                themeMode: themeMode,
                wallpaperData: wallpaperImageData,
                toggleTheme: {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        themeModeStorage = themeMode.toggled.rawValue
                    }
                },
                setWallpaperData: { data in
                    wallpaperImageData = data
                },
                clearWallpaper: {
                    wallpaperImageData = Data()
                }
            )
        }
    }

    private var tabPicker: some View {
        let theme = currentTheme

        return HStack(spacing: 8) {
            ForEach(WorkspaceTab.allCases) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                        selectWorkspace(tab)
                    }
                } label: {
                    Label(tab.title, systemImage: tab.icon)
                        .font(.system(size: 13, weight: .semibold))
                        .labelStyle(.titleAndIcon)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .frame(minHeight: WorkspaceNavigationActionLayoutPolicy.compactTabMinHeight)
                        .background {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(selectedTab == tab ? theme.accent.opacity(0.18) : theme.chipSurface)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(selectedTab == tab ? theme.accent.opacity(0.58) : theme.subtleBorder, lineWidth: 1)
                                }
                        }
                        .foregroundStyle(selectedTab == tab ? theme.primaryText : theme.secondaryText)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(KeyEquivalent(tab.shortcutKey), modifiers: [.command])
                .accessibilityLabel(WorkspaceNavigationAccessibilityMetadata.label(for: tab))
                .accessibilityValue(
                    WorkspaceNavigationAccessibilityMetadata.value(isSelected: selectedTab == tab)
                )
                .accessibilityHint(WorkspaceNavigationAccessibilityMetadata.hint(for: tab))
                .accessibilityInputLabels(WorkspaceNavigationAccessibilityMetadata.inputLabels(for: tab))
                .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
                .accessibilityIdentifier(WorkspaceNavigationAccessibilityMetadata.compactIdentifier(for: tab))
            }
        }
    }

    private func sidebarTabPicker(isDetailed: Bool) -> some View {
        let theme = currentTheme

        return VStack(spacing: 8) {
            ForEach(WorkspaceTab.allCases) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                        selectWorkspace(tab)
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 15, weight: .bold))
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: isDetailed ? 2 : 0) {
                            Text(tab.title)
                                .font(.system(size: 14, weight: .black))
                            if isDetailed {
                                Text(tab.sidebarSubtitle)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(selectedTab == tab ? theme.inverseText.opacity(0.78) : theme.secondaryText)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.78)
                            }
                        }

                        Spacer()
                        if selectedTab == tab {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .black))
                        }
                    }
                    .foregroundStyle(selectedTab == tab ? theme.inverseText : theme.primaryText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 11)
                    .frame(
                        minHeight: WorkspaceNavigationActionLayoutPolicy.sidebarTabMinHeight,
                        alignment: .leading
                    )
                    .background(selectedTab == tab ? theme.accent : theme.chipSurface, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .stroke(selectedTab == tab ? theme.accent.opacity(0.6) : theme.border, lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
                .keyboardShortcut(KeyEquivalent(tab.shortcutKey), modifiers: [.command])
                .accessibilityLabel(WorkspaceNavigationAccessibilityMetadata.label(for: tab))
                .accessibilityValue(
                    WorkspaceNavigationAccessibilityMetadata.value(isSelected: selectedTab == tab)
                )
                .accessibilityHint(WorkspaceNavigationAccessibilityMetadata.hint(for: tab))
                .accessibilityInputLabels(WorkspaceNavigationAccessibilityMetadata.inputLabels(for: tab))
                .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
                .accessibilityIdentifier(WorkspaceNavigationAccessibilityMetadata.sidebarIdentifier(for: tab))
            }
        }
    }
}

enum WorkspaceTab: String, CaseIterable, Identifiable {
    case chat
    case models
    case prompts
    case settings

    var id: String { rawValue }

    static let commandMenuTitle = "工作区"

    var shortcutKey: Character {
        switch self {
        case .chat:
            return "1"
        case .models:
            return "2"
        case .prompts:
            return "3"
        case .settings:
            return "4"
        }
    }

    var title: String {
        switch self {
        case .chat:
            return "推理"
        case .models:
            return "模型"
        case .prompts:
            return "提示词"
        case .settings:
            return "设置"
        }
    }

    var sidebarSubtitle: String {
        switch self {
        case .chat:
            return "本地对话与导出"
        case .models:
            return "模型与部署状态"
        case .prompts:
            return "提示词模板"
        case .settings:
            return "外观与芯片策略"
        }
    }

    var commandTitle: String {
        title
    }

    static var commandItems: [WorkspaceCommandItem] {
        allCases.map {
            WorkspaceCommandItem(
                tab: $0,
                title: $0.commandTitle,
                shortcutKey: $0.shortcutKey
            )
        }
    }

    var icon: String {
        switch self {
        case .chat:
            return "bubble.left.and.text.bubble.right.fill"
        case .models:
            return "square.stack.3d.up.fill"
        case .prompts:
            return "text.badge.plus"
        case .settings:
            return "gearshape.fill"
        }
    }
}

struct WorkspaceCommandItem: Identifiable, Equatable {
    let tab: WorkspaceTab
    let title: String
    let shortcutKey: Character

    var id: WorkspaceTab { tab }
}

enum SessionCommandAction: String, CaseIterable, Identifiable {
    case createSession
    case exportSession

    var id: String { rawValue }

    static let commandMenuTitle = "会话"

    var title: String {
        switch self {
        case .createSession:
            return "新建会话"
        case .exportSession:
            return "导出当前会话"
        }
    }

    var shortcutKey: Character {
        switch self {
        case .createSession:
            return "n"
        case .exportSession:
            return "e"
        }
    }

    var requiresShift: Bool {
        self == .exportSession
    }

    var focusReason: ComposerFocusReason? {
        switch self {
        case .createSession:
            return .createSession
        case .exportSession:
            return nil
        }
    }

    static var commandItems: [SessionCommandItem] {
        allCases.map {
            SessionCommandItem(
                action: $0,
                title: $0.title,
                shortcutKey: $0.shortcutKey,
                requiresShift: $0.requiresShift
            )
        }
    }
}

struct SessionCommandItem: Identifiable, Equatable {
    let action: SessionCommandAction
    let title: String
    let shortcutKey: Character
    let requiresShift: Bool

    var id: SessionCommandAction { action }
}

struct SessionCommandRoutingPolicy {
    static func isEnabled(hasFocusedActions: Bool) -> Bool {
        hasFocusedActions
    }

    static func requestsComposerFocus(after action: SessionCommandAction) -> Bool {
        action.focusReason.map(ComposerFocusPolicy.requestsComposerFocus(after:)) ?? false
    }
}

enum SessionBarActionAccessibilityMetadata {
    static func label(for action: SessionCommandAction) -> String {
        action.title
    }

    static func value(for action: SessionCommandAction) -> String {
        switch action {
        case .createSession:
            return "可创建新的本地会话。快捷键 Command N。"
        case .exportSession:
            return "可导出当前本地会话。快捷键 Command Shift E。"
        }
    }

    static func hint(for action: SessionCommandAction) -> String {
        switch action {
        case .createSession:
            return "新建本地会话并将输入焦点移到 composer；不会发送 prompt。"
        case .exportSession:
            return "打开本地 Markdown 导出和文本分享兜底；不会把会话发送到云端服务。"
        }
    }

    static func inputLabels(for action: SessionCommandAction) -> [String] {
        switch action {
        case .createSession:
            return ["新建会话", "创建会话", "开始新会话"]
        case .exportSession:
            return ["导出当前会话", "导出会话", "分享会话"]
        }
    }

    static func identifier(for action: SessionCommandAction) -> String {
        "session-bar-action-\(action.rawValue)"
    }
}

struct SessionCommandActions {
    let createSession: () -> Void
    let exportSession: () -> Void

    func perform(_ action: SessionCommandAction) {
        switch action {
        case .createSession:
            createSession()
        case .exportSession:
            exportSession()
        }
    }
}

enum WallpaperPreferenceAccessibilityMetadata {
    enum Action: CaseIterable, Identifiable {
        case choosePhoto
        case clearCustomWallpaper

        var id: String {
            WallpaperPreferenceAccessibilityMetadata.identifier(for: self)
        }
    }

    static func label(for action: Action) -> String {
        switch action {
        case .choosePhoto:
            return "选择相册壁纸"
        case .clearCustomWallpaper:
            return "恢复系统背景"
        }
    }

    static func value(
        for action: Action,
        hasCustomWallpaper: Bool,
        isImporting: Bool
    ) -> String {
        switch action {
        case .choosePhoto:
            if isImporting {
                return "正在处理相册图片，选择暂不可用。"
            }
            return hasCustomWallpaper
                ? "相册图片已启用，可重新选择系统相册图片。"
                : "当前使用系统背景，可选择系统相册图片。"
        case .clearCustomWallpaper:
            if isImporting {
                return "正在处理相册图片，恢复系统背景暂不可用。"
            }
            return hasCustomWallpaper
                ? "相册图片已启用，可清空自定义壁纸并恢复系统背景。"
                : "当前使用系统背景，没有自定义壁纸可清空。"
        }
    }

    static func hint(
        for action: Action,
        hasCustomWallpaper: Bool,
        isImporting: Bool
    ) -> String {
        switch action {
        case .choosePhoto:
            if isImporting {
                return "等待本地压缩完成后可再次选择；不会下载模型权重，不会触发真实 runtime，也不会发送到云端服务。"
            }
            return "打开系统相册选择图片，图片会在本地压缩后写入 App 背景数据；不会下载模型权重，不会触发真实 runtime，也不会发送到云端服务。"
        case .clearCustomWallpaper:
            if isImporting {
                return "等待本地压缩完成后才能恢复系统背景；不会下载模型权重，不会触发真实 runtime，也不会发送到云端服务。"
            }
            if hasCustomWallpaper {
                return "移除自定义壁纸并恢复系统背景；不会删除相册原图，不会下载模型权重，不会触发真实 runtime，也不会发送到云端服务。"
            }
            return "当前没有自定义壁纸，系统背景已经启用；不会下载模型权重，不会触发真实 runtime，也不会发送到云端服务。"
        }
    }

    static func inputLabels(for action: Action) -> [String] {
        switch action {
        case .choosePhoto:
            return ["选择相册壁纸", "选择壁纸", "打开相册"]
        case .clearCustomWallpaper:
            return ["恢复系统背景", "清空壁纸", "移除自定义壁纸"]
        }
    }

    static func identifier(for action: Action) -> String {
        switch action {
        case .choosePhoto:
            return "wallpaper-action-choose-photo"
        case .clearCustomWallpaper:
            return "wallpaper-action-clear-custom"
        }
    }
}

enum HeaderActionAccessibilityMetadata {
    static let headerThemeToggleIdentifier = "header-action-toggle-theme"
    static let settingsThemeToggleIdentifier = "settings-action-toggle-theme"
    static let modelLibraryIdentifier = "header-action-open-model-library"

    static func themeToggleLabel(themeMode: AppThemeMode) -> String {
        "切换外观主题"
    }

    static func themeToggleValue(themeMode: AppThemeMode) -> String {
        "当前\(themeMode.title)主题，激活后切换到\(themeMode.toggled.title)主题。"
    }

    static func themeToggleHint(themeMode: AppThemeMode) -> String {
        "只切换本地 UI 外观到\(themeMode.toggled.title)主题；不会下载模型权重，不会启动真实 runtime，也不会发送到云端服务。"
    }

    static func themeToggleInputLabels(themeMode: AppThemeMode) -> [String] {
        ["切换主题", "切换外观", "切换到\(themeMode.toggled.title)主题"]
    }

    static let modelLibraryLabel = "打开模型工作区"

    static let modelLibraryValue = "切换到模型工作区，可管理本地模型、artifact 和部署状态。"

    static let modelLibraryHint = "只切换本地工作区；不会下载模型权重，不会启动真实 runtime，也不会绕过 verified 门禁。"

    static let modelLibraryInputLabels = ["打开模型工作区", "打开模型库", "管理本地模型"]
}

enum HeaderActionLayoutPolicy {
    enum Action: CaseIterable {
        case toggleTheme
        case openModelLibrary
    }

    static let minimumTouchTarget: CGFloat = 44
    static let iconButtonSize: CGFloat = minimumTouchTarget

    static func usesMinimumTouchTarget(for action: Action) -> Bool {
        switch action {
        case .toggleTheme, .openModelLibrary:
            return iconButtonSize >= minimumTouchTarget
        }
    }
}

enum ModelCapsuleAccessibilityMetadata {
    static let identifier = "header-model-capsule"
    static let hint = "展示当前本地模型状态摘要；不会下载模型权重，不会启动真实 runtime，不会发送到云端服务，也不会绕过 verified 门禁。"

    static func label(model: LocalModel) -> String {
        "当前模型 \(model.name)"
    }

    static func value(
        model: LocalModel,
        readiness: Double,
        tokensPerSecond: Double,
        memoryUsageMB: Int,
        backend: ComputeBackend,
        availability: ArtifactAvailability,
        isGenerating: Bool,
        isSimulated: Bool
    ) -> String {
        [
            "\(model.name)，\(model.parameterCount)，\(model.quantization)",
            "安装状态 \(installStateDescription(model.installState))",
            runtimeModeDescription(isSimulated: isSimulated),
            artifactDescription(availability),
            generationDescription(isGenerating: isGenerating, availability: availability),
            "后端 \(backend.title)",
            "速度 \(speedValue(tokensPerSecond))",
            "内存 \(memoryValue(memoryUsageMB))",
            "准备度 \(ChipReadinessAccessibilityMetadata.percent(for: readiness))%"
        ].joined(separator: "。")
    }

    static func inputLabels(model: LocalModel) -> [String] {
        ["模型状态", "当前模型", "\(model.name) 状态"]
    }

    static func speedValue(_ tokensPerSecond: Double) -> String {
        String(format: "%.1f tok/s", tokensPerSecond)
    }

    static func memoryValue(_ memoryUsageMB: Int) -> String {
        memoryUsageMB >= 1000
            ? String(format: "%.1fG", Double(memoryUsageMB) / 1000)
            : "\(memoryUsageMB)M"
    }

    static func installStateDescription(_ state: ModelInstallState) -> String {
        switch state {
        case .ready:
            return "Ready"
        case .simulated:
            return "Simulation"
        case .notDownloaded:
            return "Not downloaded"
        }
    }

    static func runtimeModeDescription(isSimulated: Bool) -> String {
        isSimulated
            ? "运行标记 SIM，本地模拟输出"
            : "运行标记 REAL，需 artifact verified 后才可进入真实运行计划"
    }

    static func artifactDescription(_ availability: ArtifactAvailability) -> String {
        switch availability {
        case .missing:
            return "artifact missing，缺少本地模型文件"
        case .staged:
            return "artifact staged，文件已暂存但等待 SHA-256 校验"
        case .verified:
            return "artifact verified，已通过本地校验"
        }
    }

    static func generationDescription(
        isGenerating: Bool,
        availability: ArtifactAvailability
    ) -> String {
        if isGenerating {
            return "生成状态 生成中"
        }

        switch availability {
        case .missing:
            return "生成状态 待导入"
        case .staged:
            return "生成状态 待校验"
        case .verified:
            return "生成状态 已就绪"
        }
    }
}

enum ModelDetailAccessibilityMetadata {
    static let identifier = "model-detail-summary"
    static let hint = "汇总当前本地模型详情、artifact 状态和运行计划摘要；不会下载模型权重，不会启动真实 runtime，不会发送到云端服务，也不会绕过 verified 门禁。"

    static func label(model: LocalModel) -> String {
        "模型详情 \(model.name)"
    }

    static func value(
        model: LocalModel,
        validation: ArtifactValidationResult,
        report: RuntimePreparationReport
    ) -> String {
        [
            "\(model.name)，\(model.family)，\(model.parameterCount)，\(model.quantization)",
            "上下文长度 \(model.contextLength) tokens",
            "文件格式 \(model.artifactManifest.fileFormat)",
            "包体大小 \(model.sizeOnDisk)",
            artifactDescription(validation),
            "预计速度 \(ModelCapsuleAccessibilityMetadata.speedValue(model.tokensPerSecond))",
            "内存预算 \(model.memoryFootprint)",
            "主后端 \(report.activeBackend.title)",
            "回退后端 \(report.fallbackBackend.title)",
            "KV cache \(model.deploymentProfile.kvCachePolicy)",
            runtimeReadinessDescription(report),
            blockerSummary(report),
            nextStepSummary(report)
        ].joined(separator: "。")
    }

    static func inputLabels(model: LocalModel) -> [String] {
        ["模型详情", "查看模型详情", "\(model.name) 详情"]
    }

    static func artifactDescription(_ validation: ArtifactValidationResult) -> String {
        switch validation.availability {
        case .missing:
            return "artifact missing，\(validation.summary)"
        case .staged:
            return "artifact staged，\(validation.summary)"
        case .verified:
            return "artifact verified，\(validation.summary)"
        }
    }

    static func runtimeReadinessDescription(_ report: RuntimePreparationReport) -> String {
        report.canRunRealWeights
            ? "真实 runtime 计划可用，artifact verified"
            : "真实 runtime 计划不可用，等待 artifact verified 门禁"
    }

    static func blockerSummary(_ report: RuntimePreparationReport) -> String {
        guard report.blockers.isEmpty == false else {
            return "阻塞项 无"
        }
        return "阻塞项 \(report.blockers.joined(separator: "；"))"
    }

    static func nextStepSummary(_ report: RuntimePreparationReport) -> String {
        guard report.nextSteps.isEmpty == false else {
            return "下一步 无"
        }
        return "下一步 \(report.nextSteps.joined(separator: "；"))"
    }
}

enum ModelSummaryAccessibilityMetadata {
    static let identifier = "model-summary-panel"
    static let hint = "只展示本地模型概要、能力标签和 artifact 校验摘要；不会下载模型权重，不会启动真实 runtime，不会发送到云端服务，也不会绕过 artifact verified 门禁。"

    static func label(model: LocalModel) -> String {
        "模型概要 \(model.name)"
    }

    static func value(model: LocalModel, validation: ArtifactValidationResult) -> String {
        let capabilities = model.capabilities.isEmpty
            ? "无能力标签"
            : model.capabilities.joined(separator: "、")

        return [
            model.name,
            model.summary,
            "能力标签 \(capabilities)",
            "artifact \(validation.availability.title)：\(validation.summary)",
            "文件格式 \(model.artifactManifest.fileFormat)",
            "包体大小 \(model.sizeOnDisk)"
        ].joined(separator: "。")
    }

    static func inputLabels(model: LocalModel) -> [String] {
        ["模型概要", "查看模型概要", "\(model.name) 概要"]
    }
}

enum ModelDetailRowAccessibilityMetadata {
    enum AdviceKind: String, CaseIterable, Identifiable {
        case blocker
        case nextStep = "next-step"
        case chipStrategy = "chip-strategy"

        var id: String { rawValue }
    }

    static let hint = "只展示本地模型详情行；不会下载模型权重，不会启动真实 runtime，不会发送到云端服务，也不会绕过 artifact verified 门禁。"

    static func label(title: String) -> String {
        "模型详情行 \(title)"
    }

    static func value(title: String, value: String) -> String {
        "\(title)：\(value)"
    }

    static func inputLabels(title: String) -> [String] {
        ["查看\(title)", "\(title)详情", "模型\(title)"]
    }

    static func identifier(title: String) -> String {
        "model-detail-row-\(rowSlug(for: title))"
    }

    static func adviceLabel(kind: AdviceKind) -> String {
        switch kind {
        case .blocker:
            return "模型运行阻塞项"
        case .nextStep:
            return "模型下一步建议"
        case .chipStrategy:
            return "芯片策略建议"
        }
    }

    static func adviceValue(text: String) -> String {
        text.replacingOccurrences(of: "\n", with: " ")
    }

    static func adviceInputLabels(kind: AdviceKind) -> [String] {
        switch kind {
        case .blocker:
            return ["运行阻塞项", "查看阻塞项", "模型阻塞项"]
        case .nextStep:
            return ["下一步建议", "查看模型建议", "模型下一步"]
        case .chipStrategy:
            return ["芯片策略", "查看芯片策略", "模型芯片建议"]
        }
    }

    static func adviceIdentifier(kind: AdviceKind, sequence: Int = 1) -> String {
        "model-detail-advice-\(kind.rawValue)-\(max(sequence, 1))"
    }

    private static func rowSlug(for title: String) -> String {
        switch title {
        case "模型家族":
            return "family"
        case "参数规模":
            return "parameter-count"
        case "量化格式":
            return "quantization"
        case "上下文长度":
            return "context-length"
        case "文件格式":
            return "file-format"
        case "包体大小":
            return "size-on-disk"
        case "预计速度":
            return "estimated-speed"
        case "内存预算":
            return "memory-budget"
        case "主后端":
            return "primary-backend"
        case "回退后端":
            return "fallback-backend"
        case "KV cache":
            return "kv-cache"
        case "权重状态":
            return "artifact-availability"
        default:
            return "custom"
        }
    }
}

enum ModelStatusBadgeAccessibilityMetadata {
    static let hint = "只展示本地模型状态；不会下载模型权重，不会启动真实 runtime，不会发送到云端服务，也不会绕过 artifact verified 门禁。"

    static func label(for state: ModelInstallState) -> String {
        "模型安装状态 \(state.title)"
    }

    static func value(for state: ModelInstallState) -> String {
        switch state {
        case .ready:
            return "安装状态 Ready，模型已标记为可用。"
        case .simulated:
            return "安装状态 Simulation，当前使用本地模拟 runtime。"
        case .notDownloaded:
            return "安装状态 Not downloaded，模型文件尚未导入。"
        }
    }

    static func inputLabels(for state: ModelInstallState) -> [String] {
        ["安装状态", "模型安装状态", state.title]
    }

    static func identifier(for state: ModelInstallState) -> String {
        "model-status-badge-install-\(installStateSlug(for: state))"
    }

    static func label(for availability: ArtifactAvailability) -> String {
        "模型 artifact 状态 \(availability.title)"
    }

    static func value(for availability: ArtifactAvailability) -> String {
        switch availability {
        case .missing:
            return "artifact missing，缺少本地模型文件，真实 runtime 不可用。"
        case .staged:
            return "artifact staged，文件已暂存但等待 SHA-256 校验，真实 runtime 不可用。"
        case .verified:
            return "artifact verified，本地校验通过，允许进入真实 runtime 计划。"
        }
    }

    static func inputLabels(for availability: ArtifactAvailability) -> [String] {
        ["artifact 状态", "模型文件状态", availability.title]
    }

    static func identifier(for availability: ArtifactAvailability) -> String {
        "model-status-badge-artifact-\(availability.rawValue)"
    }

    static func label(for deploymentState: ModelDeploymentState) -> String {
        "模型部署状态 \(deploymentState.title)"
    }

    static func value(for deploymentState: ModelDeploymentState) -> String {
        switch deploymentState {
        case .stopped:
            return "部署状态 Stopped，当前未启动本地部署。"
        case .running:
            return "部署状态 Running，当前模型部署运行中。"
        }
    }

    static func inputLabels(for deploymentState: ModelDeploymentState) -> [String] {
        ["部署状态", "模型部署状态", deploymentState.localizedTitle]
    }

    static func identifier(for deploymentState: ModelDeploymentState) -> String {
        "model-status-badge-deployment-\(deploymentState.rawValue)"
    }

    private static func installStateSlug(for state: ModelInstallState) -> String {
        switch state {
        case .ready:
            return "ready"
        case .simulated:
            return "simulated"
        case .notDownloaded:
            return "not-downloaded"
        }
    }
}

enum SelectionAccessibilityMetadata {
    static func workspaceLabel(for tab: WorkspaceTab) -> String {
        "\(tab.title)工作区"
    }

    static func selectionValue(isSelected: Bool) -> String {
        isSelected ? "已选中" : "未选中"
    }

    static func sessionSelectLabel(title: String) -> String {
        "选择会话 \(title)"
    }

    static func sessionDeleteLabel(title: String) -> String {
        "删除会话 \(title)"
    }

    static func sessionValue(isActive: Bool) -> String {
        isActive ? "当前会话" : "未选中"
    }
}

enum SessionChipActionAccessibilityMetadata {
    enum Action: String, CaseIterable {
        case select
        case delete
    }

    static func canDelete(session: ChatSession, isActive: Bool) -> Bool {
        isDefaultEmptyActiveSession(session: session, isActive: isActive) == false
    }

    static func label(for action: Action, session: ChatSession) -> String {
        switch action {
        case .select:
            return "选择会话 \(session.title)"
        case .delete:
            return "删除会话 \(session.title)"
        }
    }

    static func value(
        for action: Action,
        session: ChatSession,
        isActive: Bool,
        canDelete: Bool
    ) -> String {
        switch action {
        case .select:
            let state = isActive ? "当前本地会话" : "未选中本地会话"
            return "\(state)，包含 \(session.messages.count) 条消息。"
        case .delete:
            if canDelete {
                let state = isActive ? "可删除当前本地会话" : "可删除未选中本地会话"
                return "\(state)，包含 \(session.messages.count) 条消息。"
            }
            return "不可删除，默认空白当前会话需保留。"
        }
    }

    static func hint(
        for action: Action,
        session: ChatSession,
        isActive: Bool,
        canDelete: Bool
    ) -> String {
        switch action {
        case .select:
            let actionSummary = isActive
                ? "保持当前本地会话并请求 composer 输入焦点"
                : "切换到这个本地会话并请求 composer 输入焦点"
            return "\(actionSummary)；不会发送 prompt，不会下载模型权重，不会启动真实 runtime，不会发送到云端服务，也不会绕过 artifact verified 门禁。"
        case .delete:
            if canDelete {
                return "执行现有本地会话删除流程；只删除会话记录，不删除模型 artifact 或权重，不发送到云端服务，也不改变 artifact verified 门禁。"
            }
            return "默认空白当前会话需要保留，当前不可删除；不删除模型 artifact 或权重，不发送到云端服务，也不改变 artifact verified 门禁。"
        }
    }

    static func inputLabels(for action: Action, session: ChatSession) -> [String] {
        let prefix = identifierPrefix(for: session)
        switch action {
        case .select:
            return ["选择\(session.title)", "\(session.title)会话", "切换会话 \(prefix)"]
        case .delete:
            return ["删除\(session.title)", "移除\(session.title)会话", "删除会话 \(prefix)"]
        }
    }

    static func identifier(for action: Action, session: ChatSession) -> String {
        "session-chip-\(action.rawValue)-\(identifierPrefix(for: session))"
    }

    private static func isDefaultEmptyActiveSession(session: ChatSession, isActive: Bool) -> Bool {
        isActive && session.messages.count <= 2 && session.title == "新对话"
    }

    private static func identifierPrefix(for session: ChatSession) -> String {
        String(session.id.uuidString.prefix(8)).lowercased()
    }
}

enum ChatMessageAccessibilityMetadata {
    static let hint = "只展示本地会话内容；不会下载模型权重，不会启动真实 runtime，不会发送到云端服务，也不会绕过 artifact verified 门禁。"

    static func label(for message: ChatMessage) -> String {
        roleTitle(for: message.role)
    }

    static func value(for message: ChatMessage) -> String {
        "\(spokenText(for: message))。\(message.tokens) tokens。本地会话消息。"
    }

    static func inputLabels(for message: ChatMessage) -> [String] {
        [
            roleTitle(for: message.role),
            "查看\(roleTitle(for: message.role))",
            "消息 \(identifierPrefix(for: message))"
        ]
    }

    static func identifier(for message: ChatMessage) -> String {
        "chat-message-\(roleSlug(for: message.role))-\(identifierPrefix(for: message))"
    }

    static func roleTitle(for role: ChatMessage.Role) -> String {
        switch role {
        case .user:
            return "用户消息"
        case .assistant:
            return "本地模型消息"
        case .system:
            return "系统状态消息"
        }
    }

    static func spokenText(for message: ChatMessage) -> String {
        let trimmedText = message.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedText.isEmpty {
            switch message.role {
            case .assistant:
                return "正在生成，本地模型正在写入模拟输出"
            case .user:
                return "空白用户消息"
            case .system:
                return "空白系统状态"
            }
        }
        return message.text.replacingOccurrences(of: "\n", with: " ")
    }

    private static func roleSlug(for role: ChatMessage.Role) -> String {
        switch role {
        case .user:
            return "user"
        case .assistant:
            return "assistant"
        case .system:
            return "system"
        }
    }

    private static func identifierPrefix(for message: ChatMessage) -> String {
        String(message.id.uuidString.prefix(8)).lowercased()
    }
}

enum ChatTranscriptAccessibilityMetadata {
    static let label = "聊天记录"
    static let hint = "浏览当前本地会话的消息列表；只展示本地消息，不会发送 prompt，不会下载模型权重，不会启动真实 runtime，不会发送到云端服务，也不会绕过 artifact verified 门禁。"
    static let inputLabels = ["聊天记录", "本地会话记录", "查看聊天记录"]
    static let identifier = "chat-transcript"

    static func value(for messages: [ChatMessage]) -> String {
        guard let latestMessage = messages.last else {
            return "空聊天记录，当前没有本地会话消息。"
        }

        let roleTitle = ChatMessageAccessibilityMetadata.roleTitle(for: latestMessage.role)
        let spokenText = ChatMessageAccessibilityMetadata.spokenText(for: latestMessage)
        return "聊天记录包含 \(messages.count) 条本地会话消息。最新\(roleTitle)：\(spokenText)。"
    }
}

enum WorkspaceNavigationAccessibilityMetadata {
    static func label(for tab: WorkspaceTab) -> String {
        SelectionAccessibilityMetadata.workspaceLabel(for: tab)
    }

    static func value(isSelected: Bool) -> String {
        SelectionAccessibilityMetadata.selectionValue(isSelected: isSelected)
    }

    static func hint(for tab: WorkspaceTab) -> String {
        "切换到\(tab.title)工作区：\(tab.sidebarSubtitle)。快捷键 Command \(tab.shortcutKey)。只切换本地工作区，不会下载模型权重，不启动真实 runtime。"
    }

    static func inputLabels(for tab: WorkspaceTab) -> [String] {
        [
            "\(tab.title)工作区",
            "打开\(tab.title)",
            "切换到\(tab.title)工作区"
        ]
    }

    static func compactIdentifier(for tab: WorkspaceTab) -> String {
        "workspace-tab-\(tab.rawValue)"
    }

    static func sidebarIdentifier(for tab: WorkspaceTab) -> String {
        "workspace-sidebar-tab-\(tab.rawValue)"
    }
}

enum WorkspaceNavigationActionLayoutPolicy {
    enum Placement: CaseIterable {
        case compactTab
        case sidebarTab
    }

    static let minimumTouchTarget: CGFloat = 44
    static let compactTabMinHeight: CGFloat = minimumTouchTarget
    static let sidebarTabMinHeight: CGFloat = minimumTouchTarget

    static func minimumHeight(for placement: Placement) -> CGFloat {
        switch placement {
        case .compactTab:
            compactTabMinHeight
        case .sidebarTab:
            sidebarTabMinHeight
        }
    }

    static func usesMinimumTouchTarget(for placement: Placement) -> Bool {
        minimumHeight(for: placement) >= minimumTouchTarget
    }
}

enum PromptCategoryAccessibilityMetadata {
    static let allCategoryTitle = "全部"
    static let allCategoryInputLabels = ["全部提示词", "筛选全部", "显示全部模板"]

    static func title(for category: PromptTemplateCategory?) -> String {
        category?.title ?? allCategoryTitle
    }

    static func label(for category: PromptTemplateCategory?) -> String {
        "筛选提示词 \(title(for: category))"
    }

    static func identifier(for category: PromptTemplateCategory?) -> String {
        "prompt-category-\(category?.rawValue ?? "all")"
    }

    static func value(isSelected: Bool) -> String {
        isSelected ? "当前筛选" : "未选中"
    }

    static func hint(for category: PromptTemplateCategory?) -> String {
        guard let category else {
            return "显示全部提示词模板。"
        }
        return "显示\(category.title)分类的提示词模板。"
    }

    static func inputLabels(for category: PromptTemplateCategory?) -> [String] {
        guard let category else {
            return allCategoryInputLabels
        }
        return ["筛选\(category.title)", "\(category.title)提示词", "显示\(category.title)模板"]
    }
}

enum PromptCategoryLayoutPolicy {
    static let minimumTouchTarget: CGFloat = 44
    static let horizontalSpacing: CGFloat = 8
    static let verticalSpacing: CGFloat = 8
    static let horizontalPadding: CGFloat = 12
    static let verticalPadding: CGFloat = 9
    static let minimumChipWidth: CGFloat = 74

    static func clampedAvailableWidth(_ width: CGFloat) -> CGFloat {
        guard width.isFinite, width > 0 else {
            return 0
        }
        return width
    }

    static func minimumSingleRowWidth(forCategoryCount categoryCount: Int) -> CGFloat {
        let clampedCount = max(categoryCount, 0)
        guard clampedCount > 0 else {
            return 0
        }

        return CGFloat(clampedCount) * minimumChipWidth
            + CGFloat(clampedCount - 1) * horizontalSpacing
    }

    static func usesWrapping(availableWidth: CGFloat, categoryCount: Int) -> Bool {
        let width = clampedAvailableWidth(availableWidth)
        guard width > 0 else {
            return categoryCount > 0
        }

        return width < minimumSingleRowWidth(forCategoryCount: categoryCount)
    }

    static func minimumRowCount(availableWidth: CGFloat, categoryCount: Int) -> Int {
        let clampedCount = max(categoryCount, 0)
        guard clampedCount > 0 else {
            return 0
        }

        let width = clampedAvailableWidth(availableWidth)
        guard width >= minimumChipWidth else {
            return clampedCount
        }

        let chipsPerRow = max(
            1,
            Int((width + horizontalSpacing) / (minimumChipWidth + horizontalSpacing))
        )
        return Int(ceil(Double(clampedCount) / Double(chipsPerRow)))
    }
}

enum PromptCategoryTextLayoutPolicy {
    static let labelLineLimit = 2

    static var allowsMultilineLabels: Bool {
        labelLineLimit > 1
    }
}

enum PromptTemplateActionAccessibilityMetadata {
    enum Action: String, CaseIterable, Identifiable {
        case apply
        case send

        var id: String { rawValue }
    }

    static func label(for action: Action, template: PresetPromptTemplate) -> String {
        switch action {
        case .apply:
            return "填入提示词模板 \(template.title)"
        case .send:
            return "发送提示词模板 \(template.title)"
        }
    }

    static func value(for action: Action, isGenerating: Bool) -> String {
        if isGenerating {
            return "生成中，暂不可用"
        }

        switch action {
        case .apply:
            return "可填入输入框"
        case .send:
            return "可直接发送"
        }
    }

    static func hint(for action: Action, template: PresetPromptTemplate) -> String {
        switch action {
        case .apply:
            return "将\(template.title)模板写入 composer，切回推理页并聚焦输入框；不会发送 prompt，不会下载模型权重，不会启动真实 runtime，也不会发送到云端服务。"
        case .send:
            return "将\(template.title)模板作为当前输入发送到本地模拟 runtime，切回推理页并聚焦输入框；不会下载模型权重，不会启动真实 runtime，不会发送到云端服务，也不会绕过 verified 门禁。"
        }
    }

    static func inputLabels(for action: Action, template: PresetPromptTemplate) -> [String] {
        switch action {
        case .apply:
            return ["填入\(template.title)", "\(template.title)填入", "使用\(template.title)模板"]
        case .send:
            return ["发送\(template.title)", "\(template.title)发送", "直接发送\(template.title)模板"]
        }
    }

    static func identifier(for action: Action, template: PresetPromptTemplate) -> String {
        "prompt-template-\(template.id)-\(action.rawValue)"
    }
}

enum ModelDeploymentControlAccessibilityMetadata {
    enum ArtifactAction: String, CaseIterable, Identifiable {
        case download
        case uninstall
        case scan
        case importFiles = "import"

        var id: String { rawValue }
    }

    static let modelSelectorLabel = "选择当前模型"
    static let modelSelectorIdentifier = "model-selector-picker"

    static func modelSelectorValue(
        selectedModel: LocalModel,
        validation: ArtifactValidationResult,
        deploymentState: ModelDeploymentState,
        modelCount: Int
    ) -> String {
        "\(selectedModel.name)，\(selectedModel.parameterCount)，\(selectedModel.quantization)，状态 \(selectedModel.installState.title)，\(modelCount) 个候选，\(availabilityDescription(for: validation.availability))，\(deploymentState.localizedTitle)。"
    }

    static func modelSelectorHint(modelCount: Int) -> String {
        if modelCount > 1 {
            return "切换当前模型。只更新本地模型选择，不下载模型权重，不启动真实 runtime，也不会绕过 verified 门禁。"
        }

        return "查看当前模型选择。当前只有 1 个候选；不会下载模型权重，不启动真实 runtime，也不会绕过 verified 门禁。"
    }

    static func modelSelectorInputLabels(selectedModel: LocalModel) -> [String] {
        ["选择模型", "切换模型", "选择\(selectedModel.name)"]
    }

    static func powerLabel(model: LocalModel, deploymentState: ModelDeploymentState) -> String {
        "\(deploymentState == .running ? "关闭" : "启动")模型部署 \(model.name)"
    }

    static func powerValue(
        model: LocalModel,
        validation: ArtifactValidationResult,
        deploymentState: ModelDeploymentState
    ) -> String {
        let runtimeSummary = validation.availability == .verified
            ? "artifact 已校验，真实 runtime 计划可用"
            : "artifact 未 verified，当前保持本地模拟部署"

        return "\(model.name)，\(deploymentState.localizedTitle)，\(availabilityDescription(for: validation.availability))，\(runtimeSummary)。"
    }

    static func powerHint(
        validation: ArtifactValidationResult,
        deploymentState: ModelDeploymentState
    ) -> String {
        if deploymentState == .running {
            return validation.availability == .verified
                ? "关闭当前部署。真实 runtime 计划只在 verified artifact 门禁后可用。"
                : "关闭当前模拟部署。artifact 未 verified，不会运行真实权重。"
        }

        return validation.availability == .verified
            ? "启动当前部署。只有已 verified 的本地 artifact 才会进入真实 runtime 计划。"
            : "启动本地模拟部署。artifact 未 verified，不会运行真实权重。"
    }

    static func powerInputLabels(model: LocalModel, deploymentState: ModelDeploymentState) -> [String] {
        if deploymentState == .running {
            return ["关闭模型部署", "停止模型部署", "停止\(model.name)"]
        }

        return ["启动模型部署", "运行模型部署", "启动\(model.name)"]
    }

    static func artifactActionLabel(_ action: ArtifactAction) -> String {
        switch action {
        case .download:
            return "模拟暂存模型文件"
        case .uninstall:
            return "打开卸载确认"
        case .scan:
            return "扫描本地模型文件"
        case .importFiles:
            return "导入本地模型文件"
        }
    }

    static func artifactActionHint(
        _ action: ArtifactAction,
        availability: ArtifactAvailability
    ) -> String {
        switch action {
        case .download:
            return availability == .missing
                ? "模拟把模型文件标记为暂存；不会联网下载真实权重。"
                : "重新执行模拟暂存；不会联网下载真实权重。"
        case .uninstall:
            return "打开卸载确认弹层；确认后移除 App 托管目录中的模型文件，并停止当前模型部署。"
        case .scan:
            return "扫描 App 本地模型目录，并按 manifest 和 SHA-256 更新 missing、staged 或 verified 状态。"
        case .importFiles:
            return "从 Files 选择 manifest 要求的本地模型文件和 tokenizer；不会从网络下载模型。"
        }
    }

    static func artifactActionValue(
        _ action: ArtifactAction,
        availability: ArtifactAvailability
    ) -> String {
        let availabilitySummary = availabilityDescription(for: availability)

        switch action {
        case .download:
            return "\(availabilitySummary)，模拟暂存，不联网下载。"
        case .uninstall:
            return "\(availabilitySummary)，打开确认后才会移除本地托管文件并停止部署。"
        case .scan:
            return "\(availabilitySummary)，执行后重新扫描本地 manifest 必需文件。"
        case .importFiles:
            return "\(availabilitySummary)，从 Files 手动选择本地文件。"
        }
    }

    static func artifactActionInputLabels(_ action: ArtifactAction) -> [String] {
        switch action {
        case .download:
            return ["模拟暂存模型", "下载模型", "暂存模型文件"]
        case .uninstall:
            return ["打开卸载确认", "卸载模型", "确认删除模型文件"]
        case .scan:
            return ["扫描本地", "扫描模型文件", "刷新模型状态"]
        case .importFiles:
            return ["导入文件", "导入模型文件", "选择本地模型"]
        }
    }

    static func artifactActionIdentifier(_ action: ArtifactAction) -> String {
        "model-artifact-action-\(action.rawValue)"
    }

    static func availabilityDescription(for availability: ArtifactAvailability) -> String {
        switch availability {
        case .missing:
            return "缺少本地 artifact"
        case .staged:
            return "artifact 已暂存但未校验"
        case .verified:
            return "artifact 已 verified"
        }
    }
}

enum ModelArtifactActionLayoutPolicy {
    enum UtilityAction: CaseIterable {
        case scan
        case importFiles

        var metadataAction: ModelDeploymentControlAccessibilityMetadata.ArtifactAction {
            switch self {
            case .scan:
                return .scan
            case .importFiles:
                return .importFiles
            }
        }
    }

    static let minimumTouchTarget: CGFloat = 44
    static let utilityButtonMinHeight: CGFloat = minimumTouchTarget

    static func usesMinimumTouchTarget(for action: UtilityAction) -> Bool {
        switch action {
        case .scan, .importFiles:
            return utilityButtonMinHeight >= minimumTouchTarget
        }
    }
}

enum ModelDeploymentControlLayoutPolicy {
    enum Control: CaseIterable {
        case modelSelector
        case powerButton
    }

    static let minimumTouchTarget: CGFloat = 44
    static let modelSelectorMinHeight: CGFloat = minimumTouchTarget
    static let powerButtonMinHeight: CGFloat = 92

    static func minimumHeight(for control: Control) -> CGFloat {
        switch control {
        case .modelSelector:
            return modelSelectorMinHeight
        case .powerButton:
            return powerButtonMinHeight
        }
    }

    static func usesMinimumTouchTarget(for control: Control) -> Bool {
        minimumHeight(for: control) >= minimumTouchTarget
    }

    static func identifier(for control: Control) -> String {
        switch control {
        case .modelSelector:
            return ModelDeploymentControlAccessibilityMetadata.modelSelectorIdentifier
        case .powerButton:
            return "model-deployment-power"
        }
    }
}

enum ModelArtifactPanelAccessibilityMetadata {
    static let label = "模型文件工作流"
    static let hint = "只管理本地模型文件工作流；不会联网下载模型权重，不会启动真实 runtime，不会发送到云端服务，也不会绕过 artifact verified 门禁。"
    static let inputLabels = ["模型文件", "模型文件工作流", "管理模型文件"]
    static let identifier = "model-artifact-panel"

    static func value(validation: ArtifactValidationResult) -> String {
        [
            ModelDeploymentControlAccessibilityMetadata.availabilityDescription(
                for: validation.availability
            ),
            "校验摘要 \(validation.summary)",
            "可模拟暂存、打开卸载确认、扫描本地目录、从 Files 手动导入模型文件和 tokenizer",
            "模拟暂存不联网下载，卸载确认后才删除本地托管文件，扫描只读取本地 manifest 必需文件"
        ].joined(separator: "。")
    }
}

enum ModelUninstallConfirmationAccessibilityMetadata {
    static let cancelLabel = "取消卸载"
    static let cancelHint = "关闭确认弹层，不删除任何本地模型文件。"
    static let cancelInputLabels = ["取消卸载", "保留模型文件", "关闭卸载确认"]
    static let cancelIdentifier = "model-uninstall-confirmation-cancel"

    static func title(model: LocalModel) -> String {
        "卸载 \(model.name) 本地文件？"
    }

    static func message(model: LocalModel) -> String {
        "确认后只会移除 App 托管目录中的 \(model.name) artifact 和 tokenizer，并停止当前模型部署；不会下载模型权重，不会启动真实 runtime，不会发送到云端服务，也不会绕过 artifact verified 门禁。"
    }

    static func confirmLabel(model: LocalModel) -> String {
        "确认卸载 \(model.name)"
    }

    static func confirmHint(model: LocalModel) -> String {
        "确认后删除 App 托管目录中的 \(model.name) 本地模型文件并停止部署；此操作不会删除系统 Files 中的原始文件。"
    }

    static func confirmInputLabels(model: LocalModel) -> [String] {
        ["确认卸载", "删除本地模型文件", "卸载\(model.name)"]
    }

    static func confirmIdentifier(model: LocalModel) -> String {
        "model-uninstall-confirmation-confirm-\(model.id.uuidString.prefix(8).lowercased())"
    }
}

enum ComposerFocusReason: String, CaseIterable {
    case openChatWorkspace
    case createSession
    case selectSession
    case applyTemplate
    case sendTemplate
}

struct ComposerFocusRequest: Equatable {
    let sequence: Int
    let reason: ComposerFocusReason?

    static let initial = ComposerFocusRequest(sequence: 0, reason: nil)

    var shouldFocus: Bool {
        sequence > 0 && reason != nil
    }

    func next(for reason: ComposerFocusReason) -> ComposerFocusRequest {
        ComposerFocusRequest(sequence: sequence + 1, reason: reason)
    }
}

enum ComposerFocusPolicy {
    static func requestsComposerFocus(after reason: ComposerFocusReason) -> Bool {
        switch reason {
        case .openChatWorkspace, .createSession, .selectSession, .applyTemplate, .sendTemplate:
            return true
        }
    }

    static func requestsComposerFocus(afterSelecting tab: WorkspaceTab) -> Bool {
        tab == .chat
    }
}

enum ComposerInputMetadata {
    static let textFieldLabel = "本地模型输入"
    static let textFieldHint = "输入 prompt。按 Command Return 发送，普通 Return 可继续换行。"
    static let textFieldInputLabels = ["本地模型输入", "输入 prompt", "问本地模型"]
    static let textFieldIdentifier = "composer-input-field"

    private static let localBoundaryHint = "本地边界：不会下载模型权重，不会启动真实 runtime，不会发送到云端服务，也不会绕过 artifact verified 门禁。"

    static func actionLabel(isGenerating: Bool) -> String {
        isGenerating ? "停止生成" : "发送提示词"
    }

    static func actionInputLabels(isGenerating: Bool) -> [String] {
        if isGenerating {
            return ["停止生成", "停止本地生成", "停止模拟生成"]
        }
        return ["发送提示词", "发送 prompt", "问本地模型"]
    }

    static func actionIdentifier(isGenerating: Bool) -> String {
        isGenerating ? "composer-stop-button" : "composer-send-button"
    }

    static func actionValue(text: String, isGenerating: Bool) -> String {
        if isGenerating {
            return "生成中"
        }
        return isActionDisabled(text: text, isGenerating: isGenerating) ? "输入为空" : "可发送"
    }

    static func actionHint(text: String, isGenerating: Bool) -> String {
        if isGenerating {
            return "停止当前模拟生成。\(localBoundaryHint)"
        }
        if isActionDisabled(text: text, isGenerating: isGenerating) {
            return "输入内容后可发送。\(localBoundaryHint)"
        }
        return "发送当前输入给本地模拟 runtime。\(localBoundaryHint)"
    }

    static func isActionDisabled(text: String, isGenerating: Bool) -> Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && isGenerating == false
    }
}

enum ComposerInputAction: CaseIterable {
    case send
    case stop

    var isGenerating: Bool {
        self == .stop
    }
}

enum ComposerInputActionLayoutPolicy {
    static let minimumTouchTarget: CGFloat = 44
    static let actionButtonSize: CGFloat = 48

    static func buttonSize(for action: ComposerInputAction) -> CGFloat {
        actionButtonSize
    }

    static func usesMinimumTouchTarget(for action: ComposerInputAction) -> Bool {
        buttonSize(for: action) >= minimumTouchTarget
    }
}

struct AppBackground: View {
    let theme: AppThemePalette
    var wallpaperData: Data = Data()

    var body: some View {
        ZStack {
            if let image = UIImage(data: wallpaperData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .overlay {
                        LinearGradient(
                            colors: [
                                (theme.isDark ? Color.black : Color.white).opacity(theme.isDark ? 0.64 : 0.58),
                                (theme.isDark ? Color.black : Color.white).opacity(theme.isDark ? 0.42 : 0.44)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
            } else {
                LinearGradient(
                    colors: theme.backgroundColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .ignoresSafeArea()
        .overlay(alignment: .topTrailing) {
            LinearGradient(
                colors: [theme.accent.opacity(theme.isDark ? 0.18 : 0.22), Color.clear],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
            .frame(height: 280)
            .rotationEffect(.degrees(-12))
            .allowsHitTesting(false)
        }
        .overlay(alignment: .bottomLeading) {
            LinearGradient(
                colors: [theme.success.opacity(theme.isDark ? 0.11 : 0.14), Color.clear],
                startPoint: .bottomLeading,
                endPoint: .topTrailing
            )
            .frame(height: 260)
            .rotationEffect(.degrees(10))
            .allowsHitTesting(false)
        }
        .overlay {
            GridTexture(color: theme.grid)
                .opacity(theme.isDark ? 0.18 : 0.28)
                .ignoresSafeArea()
        }
    }
}

struct GridTexture: View {
    let color: Color

    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 28
            var path = Path()

            var x: CGFloat = 0
            while x <= size.width {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                x += spacing
            }

            var y: CGFloat = 0
            while y <= size.height {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                y += spacing
            }

            context.stroke(path, with: .color(color), lineWidth: 0.35)
        }
    }
}

struct HeaderView: View {
    @Environment(\.appTheme) private var theme

    let model: LocalModel
    let readiness: Double
    let tokensPerSecond: Double
    let memoryUsageMB: Int
    let backend: ComputeBackend
    let availability: ArtifactAvailability
    let isGenerating: Bool
    let isSimulated: Bool
    let themeMode: AppThemeMode
    let toggleTheme: () -> Void
    let showModels: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: HeaderTitleTextLayoutPolicy.verticalSpacing) {
                    Text("LOCAL GEMMA")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(theme.accent)
                        .tracking(HeaderTitleTextLayoutPolicy.eyebrowTracking)
                        .lineLimit(HeaderTitleTextLayoutPolicy.eyebrowLineLimit)

                    Text("端侧大模型工作台")
                        .font(.title2.weight(.heavy))
                        .foregroundStyle(theme.primaryText)
                        .lineLimit(HeaderTitleTextLayoutPolicy.titleLineLimit)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Button(action: toggleTheme) {
                    Image(systemName: themeMode.icon)
                        .font(.system(size: 17, weight: .bold))
                        .frame(
                            width: HeaderActionLayoutPolicy.iconButtonSize,
                            height: HeaderActionLayoutPolicy.iconButtonSize
                        )
                        .background(theme.chipSurface, in: Circle())
                        .overlay(Circle().stroke(theme.border, lineWidth: 1))
                        .foregroundStyle(theme.primaryText)
                }
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
                .accessibilityIdentifier(HeaderActionAccessibilityMetadata.headerThemeToggleIdentifier)

                Button(action: showModels) {
                    Image(systemName: "square.stack.3d.up.fill")
                        .font(.system(size: 17, weight: .bold))
                        .frame(
                            width: HeaderActionLayoutPolicy.iconButtonSize,
                            height: HeaderActionLayoutPolicy.iconButtonSize
                        )
                        .background(theme.accent.opacity(0.2), in: Circle())
                        .overlay(Circle().stroke(theme.accent.opacity(0.45), lineWidth: 1))
                        .foregroundStyle(theme.primaryText)
                }
                .accessibilityLabel(HeaderActionAccessibilityMetadata.modelLibraryLabel)
                .accessibilityValue(HeaderActionAccessibilityMetadata.modelLibraryValue)
                .accessibilityHint(HeaderActionAccessibilityMetadata.modelLibraryHint)
                .accessibilityInputLabels(HeaderActionAccessibilityMetadata.modelLibraryInputLabels)
                .accessibilityIdentifier(HeaderActionAccessibilityMetadata.modelLibraryIdentifier)
            }

            ModelCapsule(
                model: model,
                readiness: readiness,
                tokensPerSecond: tokensPerSecond,
                memoryUsageMB: memoryUsageMB,
                backend: backend,
                availability: availability,
                isGenerating: isGenerating,
                isSimulated: isSimulated
            )
        }
    }
}

struct ModelCapsule: View {
    @Environment(\.appTheme) private var theme

    let model: LocalModel
    let readiness: Double
    let tokensPerSecond: Double
    let memoryUsageMB: Int
    let backend: ComputeBackend
    let availability: ArtifactAvailability
    let isGenerating: Bool
    let isSimulated: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(theme.accent.opacity(0.18))
                    Image(systemName: "bolt.horizontal.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(theme.accent)
                }
                .frame(width: 42, height: 42)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(model.name)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(theme.primaryText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        StatusBadge(state: model.installState)

                        Text(isSimulated ? "SIM" : "REAL")
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(isSimulated ? theme.accent : theme.success)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background((isSimulated ? theme.accent : theme.success).opacity(0.13), in: Capsule())
                    }

                    Text(statusText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(theme.secondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }

                Spacer(minLength: 0)

                ReadinessRing(progress: readiness)
                    .frame(width: 54, height: 54)
            }

            HStack(spacing: 8) {
                HeaderMetricChip(title: "速度", value: String(format: "%.1f tok/s", tokensPerSecond), icon: "speedometer", tint: theme.accent)
                HeaderMetricChip(title: "内存", value: compactMemoryValue, icon: "memorychip.fill", tint: theme.success)
                HeaderMetricChip(title: backend.shortTitle, value: availabilityMetricValue, icon: availabilityIcon, tint: statusTint)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(theme.border, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(ModelCapsuleAccessibilityMetadata.label(model: model))
        .accessibilityValue(
            ModelCapsuleAccessibilityMetadata.value(
                model: model,
                readiness: readiness,
                tokensPerSecond: tokensPerSecond,
                memoryUsageMB: memoryUsageMB,
                backend: backend,
                availability: availability,
                isGenerating: isGenerating,
                isSimulated: isSimulated
            )
        )
        .accessibilityHint(ModelCapsuleAccessibilityMetadata.hint)
        .accessibilityInputLabels(ModelCapsuleAccessibilityMetadata.inputLabels(model: model))
        .accessibilityIdentifier(ModelCapsuleAccessibilityMetadata.identifier)
    }

    private var compactMemoryValue: String {
        ModelCapsuleAccessibilityMetadata.memoryValue(memoryUsageMB)
    }

    private var availabilityMetricValue: String {
        if isGenerating {
            return "生成中"
        }

        switch availability {
        case .missing:
            return "待导入"
        case .staged:
            return "待校验"
        case .verified:
            return "已就绪"
        }
    }

    private var statusText: String {
        if isGenerating {
            return "\(backend.title) 正在流式输出"
        }

        switch availability {
        case .missing:
            return "\(model.parameterCount) · \(model.quantization) · 本地模拟"
        case .staged:
            return "\(model.parameterCount) · 文件暂存，等待校验"
        case .verified:
            return "\(backend.title) 已准备好"
        }
    }

    private var statusTint: Color {
        if isGenerating {
            return theme.success
        }

        switch availability {
        case .missing:
            return theme.warning
        case .staged:
            return theme.accent
        case .verified:
            return theme.success
        }
    }

    private var availabilityIcon: String {
        if isGenerating {
            return "bolt.fill"
        }

        switch availability {
        case .missing:
            return "tray"
        case .staged:
            return "checkmark.seal"
        case .verified:
            return "checkmark.seal.fill"
        }
    }
}

struct HeaderMetricChip: View {
    @Environment(\.appTheme) private var theme

    let title: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 8, weight: .black))
                    .foregroundStyle(theme.tertiaryText)
                Text(value)
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(theme.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 36)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(theme.recessedSurface, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
    }
}

struct StatusBadge: View {
    let state: ModelInstallState
    var exposesAccessibility: Bool = false

    var body: some View {
        Text(state.title)
            .font(.system(size: 9, weight: .black))
            .textCase(.uppercase)
            .foregroundStyle(state.tint)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(state.tint.opacity(0.12), in: Capsule())
            .overlay(Capsule().stroke(state.tint.opacity(0.35), lineWidth: 1))
            .modifier(InstallStatusBadgeAccessibilityModifier(state: state, isEnabled: exposesAccessibility))
    }
}

private struct InstallStatusBadgeAccessibilityModifier: ViewModifier {
    let state: ModelInstallState
    let isEnabled: Bool

    func body(content: Content) -> some View {
        if isEnabled {
            content
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(ModelStatusBadgeAccessibilityMetadata.label(for: state))
                .accessibilityValue(ModelStatusBadgeAccessibilityMetadata.value(for: state))
                .accessibilityHint(ModelStatusBadgeAccessibilityMetadata.hint)
                .accessibilityInputLabels(ModelStatusBadgeAccessibilityMetadata.inputLabels(for: state))
                .accessibilityIdentifier(ModelStatusBadgeAccessibilityMetadata.identifier(for: state))
        } else {
            content.accessibilityHidden(true)
        }
    }
}

struct ReadinessRing: View {
    @Environment(\.appTheme) private var theme

    let progress: Double
    let accessibilityIdentifier: String

    init(
        progress: Double,
        accessibilityIdentifier: String = ChipReadinessAccessibilityMetadata.headerRingIdentifier
    ) {
        self.progress = progress
        self.accessibilityIdentifier = accessibilityIdentifier
    }

    var body: some View {
        let clampedProgress = ChipReadinessAccessibilityMetadata.clampedProgress(progress)
        let readinessPercent = ChipReadinessAccessibilityMetadata.percent(for: progress)

        ZStack {
            Circle()
                .stroke(theme.border.opacity(0.7), lineWidth: 7)
            Circle()
                .trim(from: 0, to: clampedProgress)
                .stroke(
                    AngularGradient(colors: [.cyan, .green, .blue, .cyan], center: .center),
                    style: StrokeStyle(lineWidth: 7, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 1) {
                Text("\(readinessPercent)")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(theme.primaryText)
                Text("READY")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(theme.secondaryText)
            }
        }
        .frame(width: 66, height: 66)
        .accessibilityLabel(ChipReadinessAccessibilityMetadata.ringLabel)
        .accessibilityValue(ChipReadinessAccessibilityMetadata.ringValue(progress: progress))
        .accessibilityHint(ChipReadinessAccessibilityMetadata.ringHint)
        .accessibilityInputLabels(ChipReadinessAccessibilityMetadata.ringInputLabels)
        .accessibilityIdentifier(accessibilityIdentifier)
    }
}

struct ChatWorkspace: View {
    @EnvironmentObject private var catalog: ModelCatalog
    @EnvironmentObject private var inference: InferenceEngine
    @Environment(\.appTheme) private var theme
    @State private var exportPayload: ExportPayload?

    let composerFocusRequest: ComposerFocusRequest
    let requestComposerFocus: (ComposerFocusReason) -> Void
    let clearComposerFocusRequest: () -> Void

    init(
        composerFocusRequest: ComposerFocusRequest = .initial,
        requestComposerFocus: @escaping (ComposerFocusReason) -> Void = { _ in },
        clearComposerFocusRequest: @escaping () -> Void = {}
    ) {
        self.composerFocusRequest = composerFocusRequest
        self.requestComposerFocus = requestComposerFocus
        self.clearComposerFocusRequest = clearComposerFocusRequest
    }

    var body: some View {
        GeometryReader { proxy in
            let layoutMode = WorkspaceLayoutMode.resolve(for: proxy.size)
            let isLandscape = layoutMode.usesSidebar

            if isLandscape {
                HStack(spacing: 0) {
                    SessionBar(
                        sessions: inference.sessions,
                        activeSessionID: inference.activeSessionID,
                        layout: .vertical,
                        create: {
                            inference.createSession()
                            requestComposerFocus(.createSession)
                        },
                        select: { session in
                            inference.selectSession(session)
                            requestComposerFocus(.selectSession)
                        },
                        delete: { session in
                            inference.deleteSession(session)
                        },
                        export: prepareExport
                    )
                    .padding(14)
                    .frame(
                        width: SessionSidebarLayoutPolicy.width(
                            for: proxy.size,
                            layoutMode: layoutMode
                        )
                    )
                    .background(.ultraThinMaterial)
                    .overlay(alignment: .trailing) {
                        Rectangle()
                            .fill(theme.border)
                            .frame(width: 1)
                    }

                    chatSurface
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                VStack(spacing: 10) {
                    SessionBar(
                        sessions: inference.sessions,
                        activeSessionID: inference.activeSessionID,
                        layout: .horizontal,
                        create: {
                            inference.createSession()
                            requestComposerFocus(.createSession)
                        },
                        select: { session in
                            inference.selectSession(session)
                            requestComposerFocus(.selectSession)
                        },
                        delete: { session in
                            inference.deleteSession(session)
                        },
                        export: prepareExport
                    )
                    .padding(.horizontal, 18)
                    .padding(.top, 12)

                    chatSurface
                }
            }
        }
        .sheet(item: $exportPayload) { payload in
            ExportSessionView(payload: payload)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .focusedSceneValue(\.sessionCommandActions, sessionCommandActions)
    }

    private var sessionCommandActions: SessionCommandActions {
        SessionCommandActions(
            createSession: {
                inference.createSession()
                requestComposerFocus(.createSession)
            },
            exportSession: prepareExport
        )
    }

    private var chatSurface: some View {
        let selectedModel = catalog.selectedModel
        let selectedValidation = catalog.validation(for: catalog.selectedModel)

        return VStack(spacing: 10) {
            ChatTranscript(messages: inference.messages)

            ComposerBar(
                text: $inference.inputText,
                isGenerating: inference.isGenerating,
                focusRequest: composerFocusRequest,
                clearFocusRequest: clearComposerFocusRequest,
                send: {
                    inference.send(
                        using: selectedModel,
                        availability: selectedValidation.availability
                    )
                },
                stop: inference.stop
            )
            .frame(maxWidth: ComposerBarLayoutPolicy.maximumContentWidth)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, ComposerBarLayoutPolicy.horizontalPadding)
            .padding(.bottom, ComposerBarLayoutPolicy.bottomPadding)
        }
    }

    private func prepareExport() {
        let selectedModel = catalog.selectedModel
        let activeSession = inference.activeSession
        let fileURL = try? inference.exportActiveSessionMarkdownFile(modelName: selectedModel.name)
        exportPayload = ExportPayload(
            title: activeSession?.title ?? "会话",
            messageCount: activeSession?.messages.count ?? inference.messages.count,
            text: inference.exportActiveSessionText(modelName: selectedModel.name),
            fileURL: fileURL
        )
    }
}

struct ExportPayload: Identifiable {
    let id = UUID()
    let title: String
    let messageCount: Int
    let text: String
    let fileURL: URL?

    var existingFileURL: URL? {
        guard let fileURL, FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        return fileURL
    }
}

enum SessionChipActionLayoutPolicy {
    static let minimumTouchTarget: CGFloat = 44
    static let selectButtonMinHeight: CGFloat = minimumTouchTarget
    static let deleteButtonSize: CGFloat = minimumTouchTarget

    static func usesMinimumTouchTarget(for action: SessionChipActionAccessibilityMetadata.Action) -> Bool {
        switch action {
        case .select:
            return selectButtonMinHeight >= minimumTouchTarget
        case .delete:
            return deleteButtonSize >= minimumTouchTarget
        }
    }
}

enum ExportSessionActionAccessibilityMetadata {
    enum Action: CaseIterable, Identifiable {
        case shareMarkdownFile
        case shareTextFallback
        case copyFullText

        var id: String {
            ExportSessionActionAccessibilityMetadata.identifier(for: self)
        }
    }

    static func label(for action: Action) -> String {
        switch action {
        case .shareMarkdownFile:
            return "分享 Markdown 文件"
        case .shareTextFallback:
            return "分享文本内容"
        case .copyFullText:
            return "复制全文"
        }
    }

    static func value(for action: Action, messageCount: Int) -> String {
        switch action {
        case .shareMarkdownFile:
            return "本地 Markdown 文件，包含 \(messageCount) 条消息。"
        case .shareTextFallback:
            return "文本分享兜底，包含 \(messageCount) 条消息。"
        case .copyFullText:
            return "复制 \(messageCount) 条消息的导出文本。"
        }
    }

    static func hint(for action: Action) -> String {
        switch action {
        case .shareMarkdownFile:
            return "打开系统分享面板，分享本地生成的 Markdown 文件；不会发送到云端服务。"
        case .shareTextFallback:
            return "Markdown 文件不存在时分享本地文本内容；不会发送到云端服务。"
        case .copyFullText:
            return "将导出文本写入系统剪贴板；不会发送到云端服务。"
        }
    }

    static func inputLabels(for action: Action) -> [String] {
        switch action {
        case .shareMarkdownFile:
            return ["分享 Markdown 文件", "分享会话文件", "导出 Markdown"]
        case .shareTextFallback:
            return ["分享文本内容", "分享导出文本", "文本分享兜底"]
        case .copyFullText:
            return ["复制全文", "复制导出文本", "复制会话内容"]
        }
    }

    static func identifier(for action: Action) -> String {
        switch action {
        case .shareMarkdownFile:
            return "export-session-action-share-markdown-file"
        case .shareTextFallback:
            return "export-session-action-share-text-fallback"
        case .copyFullText:
            return "export-session-action-copy-full-text"
        }
    }
}

enum ExportSessionActionLayoutPolicy {
    enum Presentation: CaseIterable, Equatable {
        case bottomShareMarkdownFile
        case bottomShareTextFallback
        case bottomCopyFullText
        case toolbarShareMarkdownFile
        case toolbarShareTextFallback

        var metadataAction: ExportSessionActionAccessibilityMetadata.Action {
            switch self {
            case .bottomShareMarkdownFile, .toolbarShareMarkdownFile:
                return .shareMarkdownFile
            case .bottomShareTextFallback, .toolbarShareTextFallback:
                return .shareTextFallback
            case .bottomCopyFullText:
                return .copyFullText
            }
        }
    }

    static let minimumTouchTarget: CGFloat = 44
    static let bottomButtonMinHeight: CGFloat = minimumTouchTarget
    static let toolbarButtonSize: CGFloat = minimumTouchTarget

    static func usesMinimumTouchTarget(for presentation: Presentation) -> Bool {
        switch presentation {
        case .bottomShareMarkdownFile, .bottomShareTextFallback, .bottomCopyFullText:
            return bottomButtonMinHeight >= minimumTouchTarget
        case .toolbarShareMarkdownFile, .toolbarShareTextFallback:
            return toolbarButtonSize >= minimumTouchTarget
        }
    }

    static func presentations(
        for action: ExportSessionActionAccessibilityMetadata.Action
    ) -> [Presentation] {
        Presentation.allCases.filter { $0.metadataAction == action }
    }
}

enum ExportSessionLayoutPolicy {
    static let horizontalPadding: CGFloat = 18
    static let minimumReadableWidth: CGFloat = 320
    static let maximumContentWidth: CGFloat = 760

    static func contentWidth(forContainerWidth containerWidth: CGFloat) -> CGFloat {
        guard containerWidth.isFinite, containerWidth > 0 else {
            return minimumReadableWidth
        }

        let paddedWidth = max(containerWidth - horizontalPadding * 2, 0)
        guard paddedWidth >= minimumReadableWidth else {
            return paddedWidth
        }

        return min(paddedWidth, maximumContentWidth)
    }
}

enum SessionBarLayout {
    case horizontal
    case vertical
}

enum SessionBarActionLayoutPolicy {
    static let minimumTouchTarget: CGFloat = 44
    static let iconButtonSize: CGFloat = minimumTouchTarget

    static func usesMinimumTouchTarget(for action: SessionCommandAction) -> Bool {
        switch action {
        case .createSession, .exportSession:
            return iconButtonSize >= minimumTouchTarget
        }
    }
}

struct SessionBar: View {
    @Environment(\.appTheme) private var theme

    let sessions: [ChatSession]
    let activeSessionID: UUID
    var layout: SessionBarLayout = .horizontal
    let create: () -> Void
    let select: (ChatSession) -> Void
    let delete: (ChatSession) -> Void
    let export: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Label("会话", systemImage: "clock.arrow.circlepath")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(theme.primaryText)

                Spacer(minLength: 0)

                Button(action: export) {
                    Label(
                        SessionBarActionAccessibilityMetadata.label(for: .exportSession),
                        systemImage: "square.and.arrow.up.fill"
                    )
                        .labelStyle(.iconOnly)
                        .font(.system(size: 13, weight: .black))
                        .frame(
                            width: SessionBarActionLayoutPolicy.iconButtonSize,
                            height: SessionBarActionLayoutPolicy.iconButtonSize
                        )
                        .background(theme.chipSurface, in: Circle())
                        .overlay(Circle().stroke(theme.border, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .foregroundStyle(theme.primaryText)
                .accessibilityLabel(
                    SessionBarActionAccessibilityMetadata.label(for: .exportSession)
                )
                .accessibilityValue(
                    SessionBarActionAccessibilityMetadata.value(for: .exportSession)
                )
                .accessibilityHint(
                    SessionBarActionAccessibilityMetadata.hint(for: .exportSession)
                )
                .accessibilityInputLabels(
                    SessionBarActionAccessibilityMetadata.inputLabels(for: .exportSession)
                )
                .accessibilityIdentifier(
                    SessionBarActionAccessibilityMetadata.identifier(for: .exportSession)
                )

                Button(action: create) {
                    Label(
                        SessionBarActionAccessibilityMetadata.label(for: .createSession),
                        systemImage: "plus.message.fill"
                    )
                        .labelStyle(.iconOnly)
                        .font(.system(size: 13, weight: .black))
                        .frame(
                            width: SessionBarActionLayoutPolicy.iconButtonSize,
                            height: SessionBarActionLayoutPolicy.iconButtonSize
                        )
                        .background(theme.accent, in: Circle())
                        .foregroundStyle(theme.inverseText)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    SessionBarActionAccessibilityMetadata.label(for: .createSession)
                )
                .accessibilityValue(
                    SessionBarActionAccessibilityMetadata.value(for: .createSession)
                )
                .accessibilityHint(
                    SessionBarActionAccessibilityMetadata.hint(for: .createSession)
                )
                .accessibilityInputLabels(
                    SessionBarActionAccessibilityMetadata.inputLabels(for: .createSession)
                )
                .accessibilityIdentifier(
                    SessionBarActionAccessibilityMetadata.identifier(for: .createSession)
                )
            }

            sessionList
        }
    }

    @ViewBuilder
    private var sessionList: some View {
        if layout == .vertical {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(sessions) { session in
                        SessionChip(
                            session: session,
                            isActive: session.id == activeSessionID,
                            layout: .vertical,
                            select: { select(session) },
                            delete: { delete(session) }
                        )
                    }
                }
            }
            .scrollIndicators(.hidden)
        } else {
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(sessions) { session in
                        SessionChip(
                            session: session,
                            isActive: session.id == activeSessionID,
                            layout: .horizontal,
                            select: { select(session) },
                            delete: { delete(session) }
                        )
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }
}

struct SessionChip: View {
    @Environment(\.appTheme) private var theme

    let session: ChatSession
    let isActive: Bool
    var layout: SessionBarLayout = .horizontal
    let select: () -> Void
    let delete: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: select) {
                HStack(spacing: 7) {
                    Image(systemName: isActive ? "message.fill" : "message")
                        .font(.system(size: 11, weight: .bold))
                    Text(session.title)
                        .font(.system(size: 12, weight: .black))
                        .lineLimit(1)
                        .minimumScaleFactor(0.76)
                    if layout == .vertical {
                        Spacer(minLength: 0)
                    }
                }
                .frame(
                    maxWidth: layout == .vertical ? .infinity : 160,
                    minHeight: SessionChipActionLayoutPolicy.selectButtonMinHeight,
                    alignment: .leading
                )
                .foregroundStyle(isActive ? theme.inverseText : theme.primaryText)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                SessionChipActionAccessibilityMetadata.label(for: .select, session: session)
            )
            .accessibilityValue(
                SessionChipActionAccessibilityMetadata.value(
                    for: .select,
                    session: session,
                    isActive: isActive,
                    canDelete: canDelete
                )
            )
            .accessibilityHint(
                SessionChipActionAccessibilityMetadata.hint(
                    for: .select,
                    session: session,
                    isActive: isActive,
                    canDelete: canDelete
                )
            )
            .accessibilityInputLabels(
                SessionChipActionAccessibilityMetadata.inputLabels(for: .select, session: session)
            )
            .accessibilityIdentifier(
                SessionChipActionAccessibilityMetadata.identifier(for: .select, session: session)
            )
            .accessibilityAddTraits(isActive ? .isSelected : [])

            Button(action: delete) {
                Label(
                    SessionChipActionAccessibilityMetadata.label(for: .delete, session: session),
                    systemImage: "trash.fill"
                )
                    .labelStyle(.iconOnly)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(isActive ? theme.inverseText.opacity(0.82) : theme.warning)
                    .frame(
                        width: SessionChipActionLayoutPolicy.deleteButtonSize,
                        height: SessionChipActionLayoutPolicy.deleteButtonSize
                    )
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(canDelete == false)
            .opacity(canDelete ? 1 : 0.32)
            .accessibilityLabel(
                SessionChipActionAccessibilityMetadata.label(for: .delete, session: session)
            )
            .accessibilityValue(
                SessionChipActionAccessibilityMetadata.value(
                    for: .delete,
                    session: session,
                    isActive: isActive,
                    canDelete: canDelete
                )
            )
            .accessibilityHint(
                SessionChipActionAccessibilityMetadata.hint(
                    for: .delete,
                    session: session,
                    isActive: isActive,
                    canDelete: canDelete
                )
            )
            .accessibilityInputLabels(
                SessionChipActionAccessibilityMetadata.inputLabels(for: .delete, session: session)
            )
            .accessibilityIdentifier(
                SessionChipActionAccessibilityMetadata.identifier(for: .delete, session: session)
            )
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: layout == .vertical ? .infinity : nil, alignment: .leading)
        .background(isActive ? theme.accent : theme.chipSurface, in: Capsule())
        .overlay(Capsule().stroke(isActive ? theme.accent.opacity(0.7) : theme.border, lineWidth: 1))
    }

    private var canDelete: Bool {
        SessionChipActionAccessibilityMetadata.canDelete(session: session, isActive: isActive)
    }
}

struct ChatTranscript: View {
    let messages: [ChatMessage]

    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { message in
                            ChatBubble(
                                message: message,
                                availableWidth: ChatBubbleLayoutPolicy.contentWidth(
                                    forTranscriptWidth: geometry.size.width
                                )
                            )
                            .id(message.id)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                }
                .scrollIndicators(.hidden)
                .accessibilityElement(children: .contain)
                .accessibilityLabel(ChatTranscriptAccessibilityMetadata.label)
                .accessibilityValue(ChatTranscriptAccessibilityMetadata.value(for: messages))
                .accessibilityHint(ChatTranscriptAccessibilityMetadata.hint)
                .accessibilityInputLabels(ChatTranscriptAccessibilityMetadata.inputLabels)
                .accessibilityIdentifier(ChatTranscriptAccessibilityMetadata.identifier)
                .onChange(of: messages) { _, messages in
                    guard let last = messages.last else { return }
                    withAnimation(.easeOut(duration: 0.22)) {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }
}

struct ExportSessionView: View {
    @Environment(\.appTheme) private var theme
    let payload: ExportPayload
    @State private var didCopyText = false

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let contentWidth = ExportSessionLayoutPolicy.contentWidth(
                    forContainerWidth: proxy.size.width
                )

                VStack(spacing: 0) {
                    exportHeader

                    ScrollView {
                        Text(payload.text)
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundStyle(theme.primaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                            .padding(18)
                    }

                    exportActions
                }
                .frame(width: contentWidth)
                .frame(maxHeight: .infinity)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, ExportSessionLayoutPolicy.horizontalPadding)
            }
            .background(AppBackground(theme: theme))
            .navigationTitle("导出会话")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if let fileURL = payload.existingFileURL {
                        ShareLink(item: fileURL) {
                            Label(
                                ExportSessionActionAccessibilityMetadata.label(
                                    for: .shareMarkdownFile
                                ),
                                systemImage: "square.and.arrow.up.fill"
                            )
                            .labelStyle(.iconOnly)
                            .frame(
                                width: ExportSessionActionLayoutPolicy.toolbarButtonSize,
                                height: ExportSessionActionLayoutPolicy.toolbarButtonSize
                            )
                            .contentShape(Rectangle())
                        }
                        .accessibilityLabel(
                            ExportSessionActionAccessibilityMetadata.label(
                                for: .shareMarkdownFile
                            )
                        )
                        .accessibilityValue(
                            ExportSessionActionAccessibilityMetadata.value(
                                for: .shareMarkdownFile,
                                messageCount: payload.messageCount
                            )
                        )
                        .accessibilityHint(
                            ExportSessionActionAccessibilityMetadata.hint(
                                for: .shareMarkdownFile
                            )
                        )
                        .accessibilityInputLabels(
                            ExportSessionActionAccessibilityMetadata.inputLabels(
                                for: .shareMarkdownFile
                            )
                        )
                        .accessibilityIdentifier(
                            "\(ExportSessionActionAccessibilityMetadata.identifier(for: .shareMarkdownFile))-toolbar"
                        )
                    } else {
                        ShareLink(item: payload.text) {
                            Label(
                                ExportSessionActionAccessibilityMetadata.label(
                                    for: .shareTextFallback
                                ),
                                systemImage: "text.quote"
                            )
                            .labelStyle(.iconOnly)
                            .frame(
                                width: ExportSessionActionLayoutPolicy.toolbarButtonSize,
                                height: ExportSessionActionLayoutPolicy.toolbarButtonSize
                            )
                            .contentShape(Rectangle())
                        }
                        .accessibilityLabel(
                            ExportSessionActionAccessibilityMetadata.label(
                                for: .shareTextFallback
                            )
                        )
                        .accessibilityValue(
                            ExportSessionActionAccessibilityMetadata.value(
                                for: .shareTextFallback,
                                messageCount: payload.messageCount
                            )
                        )
                        .accessibilityHint(
                            ExportSessionActionAccessibilityMetadata.hint(
                                for: .shareTextFallback
                            )
                        )
                        .accessibilityInputLabels(
                            ExportSessionActionAccessibilityMetadata.inputLabels(
                                for: .shareTextFallback
                            )
                        )
                        .accessibilityIdentifier(
                            "\(ExportSessionActionAccessibilityMetadata.identifier(for: .shareTextFallback))-toolbar"
                        )
                    }
                }
            }
        }
    }

    private var exportHeader: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(theme.accent.opacity(0.16))
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 20, weight: .black))
                    .foregroundStyle(theme.accent)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 4) {
                Text(payload.title)
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(theme.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)
                Text("\(payload.messageCount) 条消息 · Markdown")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(theme.secondaryText)
            }

            Spacer()
        }
        .padding(18)
        .background(.ultraThinMaterial)
    }

    private var exportActions: some View {
        VStack(spacing: 10) {
            if let fileURL = payload.existingFileURL {
                ShareLink(item: fileURL) {
                    Label(
                        ExportSessionActionAccessibilityMetadata.label(
                            for: .shareMarkdownFile
                        ),
                        systemImage: "square.and.arrow.up.fill"
                    )
                        .font(.system(size: 15, weight: .black))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .frame(
                            minHeight: ExportSessionActionLayoutPolicy.bottomButtonMinHeight
                        )
                        .background(theme.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .foregroundStyle(theme.inverseText)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    ExportSessionActionAccessibilityMetadata.label(
                        for: .shareMarkdownFile
                    )
                )
                .accessibilityValue(
                    ExportSessionActionAccessibilityMetadata.value(
                        for: .shareMarkdownFile,
                        messageCount: payload.messageCount
                    )
                )
                .accessibilityHint(
                    ExportSessionActionAccessibilityMetadata.hint(
                        for: .shareMarkdownFile
                    )
                )
                .accessibilityInputLabels(
                    ExportSessionActionAccessibilityMetadata.inputLabels(
                        for: .shareMarkdownFile
                    )
                )
                .accessibilityIdentifier(
                    ExportSessionActionAccessibilityMetadata.identifier(
                        for: .shareMarkdownFile
                    )
                )
            } else {
                ShareLink(item: payload.text) {
                    Label(
                        ExportSessionActionAccessibilityMetadata.label(
                            for: .shareTextFallback
                        ),
                        systemImage: "text.quote"
                    )
                        .font(.system(size: 15, weight: .black))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .frame(
                            minHeight: ExportSessionActionLayoutPolicy.bottomButtonMinHeight
                        )
                        .background(theme.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .foregroundStyle(theme.inverseText)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    ExportSessionActionAccessibilityMetadata.label(
                        for: .shareTextFallback
                    )
                )
                .accessibilityValue(
                    ExportSessionActionAccessibilityMetadata.value(
                        for: .shareTextFallback,
                        messageCount: payload.messageCount
                    )
                )
                .accessibilityHint(
                    ExportSessionActionAccessibilityMetadata.hint(
                        for: .shareTextFallback
                    )
                )
                .accessibilityInputLabels(
                    ExportSessionActionAccessibilityMetadata.inputLabels(
                        for: .shareTextFallback
                    )
                )
                .accessibilityIdentifier(
                    ExportSessionActionAccessibilityMetadata.identifier(
                        for: .shareTextFallback
                    )
                )
            }

            Button {
                UIPasteboard.general.string = payload.text
                withAnimation(.spring(response: 0.26, dampingFraction: 0.82)) {
                    didCopyText = true
                }
            } label: {
                Label(didCopyText ? "已复制" : "复制全文", systemImage: didCopyText ? "checkmark.circle.fill" : "doc.on.doc.fill")
                    .font(.system(size: 13, weight: .black))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .frame(
                        minHeight: ExportSessionActionLayoutPolicy.bottomButtonMinHeight
                    )
                    .background(theme.chipSurface, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .stroke(theme.border, lineWidth: 1)
                    }
                    .foregroundStyle(theme.primaryText)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                ExportSessionActionAccessibilityMetadata.label(for: .copyFullText)
            )
            .accessibilityValue(
                ExportSessionActionAccessibilityMetadata.value(
                    for: .copyFullText,
                    messageCount: payload.messageCount
                )
            )
            .accessibilityHint(
                ExportSessionActionAccessibilityMetadata.hint(for: .copyFullText)
            )
            .accessibilityInputLabels(
                ExportSessionActionAccessibilityMetadata.inputLabels(for: .copyFullText)
            )
            .accessibilityIdentifier(
                ExportSessionActionAccessibilityMetadata.identifier(for: .copyFullText)
            )
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
}

struct ChatBubble: View {
    @Environment(\.appTheme) private var theme
    let message: ChatMessage
    let availableWidth: CGFloat

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.role == .user {
                Spacer(minLength: 40)
            }

            VStack(alignment: bubbleAlignment, spacing: 6) {
                Text(roleTitle)
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(roleTint.opacity(0.82))

                Text(message.text.isEmpty ? "正在生成..." : message.text)
                    .font(.system(size: 15, weight: .medium))
                    .lineSpacing(4)
                    .foregroundStyle(message.role == .system ? theme.secondaryText : theme.primaryText)
                    .textSelection(.enabled)

                HStack(spacing: 4) {
                    Image(systemName: "number")
                        .font(.system(size: 9, weight: .bold))
                Text("\(message.tokens) tokens")
                    .font(.system(size: 10, weight: .semibold))
            }
                .foregroundStyle(theme.tertiaryText)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(bubbleBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(roleTint.opacity(message.role == .system ? 0.12 : 0.32), lineWidth: 1)
            }
            .frame(
                maxWidth: ChatBubbleLayoutPolicy.maxWidth(
                    for: message.role,
                    availableWidth: availableWidth
                ),
                alignment: message.role == .user ? .trailing : .leading
            )

            if message.role != .user {
                Spacer(minLength: 24)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(ChatMessageAccessibilityMetadata.label(for: message))
        .accessibilityValue(ChatMessageAccessibilityMetadata.value(for: message))
        .accessibilityHint(ChatMessageAccessibilityMetadata.hint)
        .accessibilityInputLabels(ChatMessageAccessibilityMetadata.inputLabels(for: message))
        .accessibilityIdentifier(ChatMessageAccessibilityMetadata.identifier(for: message))
    }

    private var roleTitle: String {
        switch message.role {
        case .user:
            return "你"
        case .assistant:
            return "本地模型"
        case .system:
            return "状态"
        }
    }

    private var roleTint: Color {
        switch message.role {
        case .user:
            return .green
        case .assistant:
            return .cyan
        case .system:
            return .orange
        }
    }

    private var bubbleAlignment: HorizontalAlignment {
        message.role == .user ? .trailing : .leading
    }

    private var bubbleBackground: some ShapeStyle {
        switch message.role {
        case .user:
            return LinearGradient(colors: [theme.success.opacity(theme.isDark ? 0.28 : 0.16), theme.accent.opacity(theme.isDark ? 0.18 : 0.14)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .assistant:
            return LinearGradient(colors: [theme.surface, theme.accent.opacity(theme.isDark ? 0.08 : 0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .system:
            return LinearGradient(colors: [theme.warning.opacity(0.12), theme.surface], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

enum ChatBubbleLayoutPolicy {
    static let transcriptHorizontalPadding: CGFloat = 36
    static let minimumReadableWidth: CGFloat = 280
    static let compactUserWidth: CGFloat = 310
    static let maximumUserWidth: CGFloat = 520
    static let maximumAssistantWidth: CGFloat = 680
    static let maximumSystemWidth: CGFloat = 600
    static let userWidthRatio: CGFloat = 0.58
    static let assistantWidthRatio: CGFloat = 0.76
    static let systemWidthRatio: CGFloat = 0.72

    private static let userHorizontalReserve: CGFloat = 40
    private static let assistantHorizontalReserve: CGFloat = 24

    static func contentWidth(forTranscriptWidth transcriptWidth: CGFloat) -> CGFloat {
        max(minimumReadableWidth, transcriptWidth - transcriptHorizontalPadding)
    }

    static func maxWidth(for role: ChatMessage.Role, availableWidth: CGFloat) -> CGFloat {
        let reserve = horizontalReserve(for: role)
        let effectiveAvailableWidth = max(availableWidth, minimumReadableWidth + reserve)
        let usableWidth = max(minimumReadableWidth, effectiveAvailableWidth - reserve)
        let preferredWidth = max(minimumReadableWidth, effectiveAvailableWidth * widthRatio(for: role))
        let unclampedWidth = max(compactUserWidth, preferredWidth)

        return min(usableWidth, min(maximumWidth(for: role), unclampedWidth))
    }

    private static func horizontalReserve(for role: ChatMessage.Role) -> CGFloat {
        role == .user ? userHorizontalReserve : assistantHorizontalReserve
    }

    private static func maximumWidth(for role: ChatMessage.Role) -> CGFloat {
        switch role {
        case .user:
            return maximumUserWidth
        case .assistant:
            return maximumAssistantWidth
        case .system:
            return maximumSystemWidth
        }
    }

    private static func widthRatio(for role: ChatMessage.Role) -> CGFloat {
        switch role {
        case .user:
            return userWidthRatio
        case .assistant:
            return assistantWidthRatio
        case .system:
            return systemWidthRatio
        }
    }
}

struct PromptTemplatesWorkspace: View {
    @EnvironmentObject private var catalog: ModelCatalog
    @EnvironmentObject private var inference: InferenceEngine
    @Environment(\.appTheme) private var theme
    @State private var selectedCategory: PromptTemplateCategory?

    let openChat: (ComposerFocusReason) -> Void

    var body: some View {
        let model = catalog.selectedModel
        let validation = catalog.validation(for: model)
        let templates = PromptTemplateLibrary.templates(in: selectedCategory)

        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader(
                        eyebrow: "PROMPTS",
                        title: "预设提示词",
                        subtitle: "把常用本地部署、隐私、安全和产品表达整理成可复用模板。"
                    )

                    PromptCategorySelector(selectedCategory: $selectedCategory)

                    PromptTemplateGrid(
                        templates: templates,
                        isGenerating: inference.isGenerating,
                        apply: { template in
                            inference.applyTemplate(template)
                            openChat(.applyTemplate)
                        },
                        send: { template in
                            inference.useTemplate(
                                template,
                                model: model,
                                availability: validation.availability
                            )
                            openChat(.sendTemplate)
                        }
                    )
                }
                .frame(
                    width: PromptTemplatesWorkspaceLayoutPolicy.contentWidth(
                        forContainerWidth: proxy.size.width
                    ),
                    alignment: .leading
                )
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, PromptTemplatesWorkspaceLayoutPolicy.horizontalPadding)
                .padding(.top, 16)
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)
        }
    }
}

enum PromptTemplatesWorkspaceLayoutPolicy {
    static let horizontalPadding: CGFloat = 18
    static let minimumReadableWidth: CGFloat = 320
    static let maximumContentWidth: CGFloat = PromptTemplateGridLayoutPolicy.maximumWidth(
        forColumnCount: PromptTemplateGridLayoutPolicy.maxColumnCount
    )

    static func contentWidth(forContainerWidth containerWidth: CGFloat) -> CGFloat {
        guard containerWidth.isFinite, containerWidth > 0 else {
            return minimumReadableWidth
        }

        let paddedWidth = max(containerWidth - horizontalPadding * 2, 0)
        guard paddedWidth >= minimumReadableWidth else {
            return paddedWidth
        }

        return min(
            paddedWidth,
            maximumContentWidth
        )
    }
}

struct PromptTemplateGrid: View {
    let templates: [PresetPromptTemplate]
    let isGenerating: Bool
    let apply: (PresetPromptTemplate) -> Void
    let send: (PresetPromptTemplate) -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            templateGrid(columnCount: 4)
            templateGrid(columnCount: 3)
            templateGrid(columnCount: 2)
            templateGrid(columnCount: 1)
        }
    }

    private func templateGrid(columnCount: Int) -> some View {
        LazyVGrid(
            columns: PromptTemplateGridLayoutPolicy.columns(forColumnCount: columnCount),
            alignment: .leading,
            spacing: PromptTemplateGridLayoutPolicy.spacing
        ) {
            ForEach(templates) { template in
                PromptTemplateCard(
                    template: template,
                    isGenerating: isGenerating,
                    apply: { apply(template) },
                    send: { send(template) }
                )
            }
        }
        .frame(minWidth: PromptTemplateGridLayoutPolicy.minimumWidth(forColumnCount: columnCount))
    }
}

enum PromptTemplateGridLayoutPolicy {
    static let minimumCardWidth: CGFloat = 230
    static let maximumCardWidth: CGFloat = 320
    static let spacing: CGFloat = 12
    static let maxColumnCount = 4

    static var supportedColumnCounts: [Int] {
        Array(stride(from: maxColumnCount, through: 1, by: -1))
    }

    static func columnCount(for availableWidth: CGFloat) -> Int {
        supportedColumnCounts.first { availableWidth >= minimumWidth(forColumnCount: $0) } ?? 1
    }

    static func cardWidth(for availableWidth: CGFloat) -> CGFloat {
        let columnCount = columnCount(for: availableWidth)
        let totalSpacing = CGFloat(columnCount - 1) * spacing
        let availableCardWidth = (availableWidth - totalSpacing) / CGFloat(columnCount)
        return min(max(availableCardWidth, minimumCardWidth), maximumCardWidth)
    }

    static func columns(for availableWidth: CGFloat) -> [GridItem] {
        columns(forColumnCount: columnCount(for: availableWidth))
    }

    static func columns(forColumnCount columnCount: Int) -> [GridItem] {
        let clampedCount = min(max(columnCount, 1), maxColumnCount)
        return Array(
            repeating: GridItem(.flexible(minimum: minimumCardWidth, maximum: maximumCardWidth), spacing: spacing),
            count: clampedCount
        )
    }

    static func minimumWidth(forColumnCount columnCount: Int) -> CGFloat {
        let clampedCount = min(max(columnCount, 1), maxColumnCount)
        return CGFloat(clampedCount) * minimumCardWidth
            + CGFloat(clampedCount - 1) * spacing
    }

    static func maximumWidth(forColumnCount columnCount: Int) -> CGFloat {
        let clampedCount = min(max(columnCount, 1), maxColumnCount)
        return CGFloat(clampedCount) * maximumCardWidth
            + CGFloat(clampedCount - 1) * spacing
    }
}

struct PromptCategorySelector: View {
    @Environment(\.appTheme) private var theme
    @Binding var selectedCategory: PromptTemplateCategory?

    var body: some View {
        PromptCategoryFlowLayout {
            categoryButton(category: nil, icon: "square.grid.2x2.fill", isSelected: selectedCategory == nil) {
                selectedCategory = nil
            }

            ForEach(PromptTemplateCategory.allCases) { category in
                categoryButton(category: category, icon: category.icon, isSelected: selectedCategory == category) {
                    selectedCategory = category
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func categoryButton(category: PromptTemplateCategory?, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        let title = PromptCategoryAccessibilityMetadata.title(for: category)

        return Button(action: action) {
            Label(title, systemImage: icon)
                .font(.subheadline)
                .bold()
                .labelStyle(.titleAndIcon)
                .foregroundStyle(isSelected ? theme.inverseText : theme.secondaryText)
                .lineLimit(PromptCategoryTextLayoutPolicy.labelLineLimit)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, PromptCategoryLayoutPolicy.horizontalPadding)
                .padding(.vertical, PromptCategoryLayoutPolicy.verticalPadding)
                .frame(
                    minWidth: PromptCategoryLayoutPolicy.minimumChipWidth,
                    minHeight: PromptCategoryLayoutPolicy.minimumTouchTarget
                )
                .background(isSelected ? theme.accent : theme.chipSurface, in: Capsule())
                .overlay(Capsule().stroke(isSelected ? theme.accent.opacity(0.7) : theme.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(PromptCategoryAccessibilityMetadata.label(for: category))
        .accessibilityValue(PromptCategoryAccessibilityMetadata.value(isSelected: isSelected))
        .accessibilityHint(PromptCategoryAccessibilityMetadata.hint(for: category))
        .accessibilityInputLabels(PromptCategoryAccessibilityMetadata.inputLabels(for: category))
        .accessibilityIdentifier(PromptCategoryAccessibilityMetadata.identifier(for: category))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct PromptCategoryFlowLayout: Layout {
    var horizontalSpacing: CGFloat = PromptCategoryLayoutPolicy.horizontalSpacing
    var verticalSpacing: CGFloat = PromptCategoryLayoutPolicy.verticalSpacing

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let proposedWidth = proposal.width ?? .infinity
        let wraps = proposedWidth.isFinite && proposedWidth > 0
        let maxWidth = wraps ? proposedWidth : .infinity

        var lineWidth: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var measuredWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let spacing = lineWidth > 0 ? horizontalSpacing : 0

            if wraps, lineWidth > 0, lineWidth + spacing + size.width > maxWidth {
                measuredWidth = max(measuredWidth, lineWidth)
                totalHeight += lineHeight + verticalSpacing
                lineWidth = size.width
                lineHeight = size.height
            } else {
                lineWidth += spacing + size.width
                lineHeight = max(lineHeight, size.height)
            }
        }

        measuredWidth = max(measuredWidth, lineWidth)
        totalHeight += lineHeight

        return CGSize(
            width: wraps ? min(measuredWidth, maxWidth) : measuredWidth,
            height: totalHeight
        )
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        var origin = bounds.origin
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let spacing = origin.x > bounds.minX ? horizontalSpacing : 0
            let nextMaxX = origin.x + spacing + size.width

            if origin.x > bounds.minX, nextMaxX > bounds.maxX {
                origin.x = bounds.minX
                origin.y += lineHeight + verticalSpacing
                lineHeight = 0
            } else {
                origin.x += spacing
            }

            subview.place(
                at: origin,
                proposal: ProposedViewSize(width: size.width, height: size.height)
            )

            origin.x += size.width
            lineHeight = max(lineHeight, size.height)
        }
    }
}

struct PromptTemplateCard: View {
    @Environment(\.appTheme) private var theme

    let template: PresetPromptTemplate
    let isGenerating: Bool
    let apply: () -> Void
    let send: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(alignment: .top, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(template.category.accentColor.opacity(0.16))
                    Image(systemName: template.icon)
                        .font(.system(size: 17, weight: .black))
                        .foregroundStyle(template.category.accentColor)
                }
                .frame(width: 38, height: 38)

                VStack(alignment: .leading, spacing: PromptTemplateTextLayoutPolicy.headerTextSpacing) {
                    Text(template.title)
                        .font(.headline)
                        .bold()
                        .foregroundStyle(theme.primaryText)
                        .lineLimit(PromptTemplateTextLayoutPolicy.titleLineLimit)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(template.subtitle)
                        .font(.subheadline)
                        .bold()
                        .foregroundStyle(theme.tertiaryText)
                        .lineLimit(PromptTemplateTextLayoutPolicy.subtitleLineLimit)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Text(template.category.title)
                    .font(.caption)
                    .bold()
                    .foregroundStyle(template.category.accentColor)
                    .lineLimit(PromptTemplateTextLayoutPolicy.categoryLineLimit)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(template.category.accentColor.opacity(0.12), in: Capsule())
            }

            Text(template.prompt)
                .font(.callout)
                .lineSpacing(PromptTemplateTextLayoutPolicy.bodyLineSpacing)
                .foregroundStyle(theme.secondaryText)
                .lineLimit(PromptTemplateTextLayoutPolicy.promptLineLimit)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            HStack(spacing: PromptTemplateActionLayoutPolicy.spacing) {
                Button(action: apply) {
                    Label("填入", systemImage: "text.cursor")
                        .font(.subheadline)
                        .bold()
                        .foregroundStyle(theme.primaryText)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: PromptTemplateActionLayoutPolicy.minimumTouchTarget)
                        .padding(.vertical, 9)
                        .background(template.category.accentColor.opacity(0.18), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(template.category.accentColor.opacity(0.34), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    PromptTemplateActionAccessibilityMetadata.label(for: .apply, template: template)
                )
                .accessibilityValue(
                    PromptTemplateActionAccessibilityMetadata.value(for: .apply, isGenerating: isGenerating)
                )
                .accessibilityHint(
                    PromptTemplateActionAccessibilityMetadata.hint(for: .apply, template: template)
                )
                .accessibilityInputLabels(
                    PromptTemplateActionAccessibilityMetadata.inputLabels(for: .apply, template: template)
                )
                .accessibilityIdentifier(
                    PromptTemplateActionAccessibilityMetadata.identifier(for: .apply, template: template)
                )

                Button(action: send) {
                    Label("发送", systemImage: "paperplane.fill")
                        .labelStyle(.iconOnly)
                        .font(.body)
                        .bold()
                        .frame(
                            width: PromptTemplateActionLayoutPolicy.sendButtonSize,
                            height: PromptTemplateActionLayoutPolicy.sendButtonSize
                        )
                        .background(template.category.accentColor, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .foregroundStyle(theme.inverseText)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    PromptTemplateActionAccessibilityMetadata.label(for: .send, template: template)
                )
                .accessibilityValue(
                    PromptTemplateActionAccessibilityMetadata.value(for: .send, isGenerating: isGenerating)
                )
                .accessibilityHint(
                    PromptTemplateActionAccessibilityMetadata.hint(for: .send, template: template)
                )
                .accessibilityInputLabels(
                    PromptTemplateActionAccessibilityMetadata.inputLabels(for: .send, template: template)
                )
                .accessibilityIdentifier(
                    PromptTemplateActionAccessibilityMetadata.identifier(for: .send, template: template)
                )
            }
        }
        .foregroundStyle(theme.primaryText)
        .padding(PromptTemplateActionLayoutPolicy.cardPadding)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .frame(minHeight: PromptTemplateTextLayoutPolicy.minimumCardHeight, alignment: .topLeading)
        .background(templateBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(template.category.accentColor.opacity(0.24), lineWidth: 1)
        }
        .disabled(isGenerating)
        .opacity(isGenerating ? 0.5 : 1)
    }

    private var templateBackground: some ShapeStyle {
        LinearGradient(
            colors: [
                Color.white.opacity(0.1),
                template.category.accentColor.opacity(0.09),
                theme.isDark ? Color.black.opacity(0.18) : Color.white.opacity(0.82)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

enum PromptTemplateTextLayoutPolicy {
    static let titleLineLimit = 2
    static let subtitleLineLimit = 2
    static let promptLineLimit = 4
    static let categoryLineLimit = 1
    static let headerTextSpacing: CGFloat = 4
    static let bodyLineSpacing: CGFloat = 3
    static let minimumCardHeight: CGFloat = 204
}

enum PromptTemplateActionLayoutPolicy {
    static let minimumTouchTarget: CGFloat = 44
    static let spacing: CGFloat = 8
    static let cardPadding: CGFloat = 13
    static let sendButtonSize: CGFloat = minimumTouchTarget
    static let minimumApplyButtonWidth: CGFloat = 112

    static func minimumCardWidthForActionRow() -> CGFloat {
        cardPadding * 2
            + minimumApplyButtonWidth
            + spacing
            + sendButtonSize
    }

    static func actionRowFits(inCardWidth cardWidth: CGFloat) -> Bool {
        cardWidth >= minimumCardWidthForActionRow()
    }
}

struct ComposerBar: View {
    @Environment(\.appTheme) private var theme
    @FocusState private var focusedField: ComposerFocusedField?

    @Binding var text: String
    let isGenerating: Bool
    let focusRequest: ComposerFocusRequest
    let clearFocusRequest: () -> Void
    let send: () -> Void
    let stop: () -> Void

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            HStack(alignment: .bottom, spacing: 10) {
                Image(systemName: "bubble.left.and.text.bubble.right.fill")
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(theme.accent)
                    .frame(width: 24, height: 24)
                    .padding(.bottom, 10)
                    .accessibilityHidden(true)

                TextField("问本地模型任何问题", text: $text, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(theme.primaryText)
                    .lineLimit(1...4)
                    .padding(.vertical, 12)
                    .focused($focusedField, equals: .input)
                    .accessibilityLabel(ComposerInputMetadata.textFieldLabel)
                    .accessibilityHint(ComposerInputMetadata.textFieldHint)
                    .accessibilityInputLabels(ComposerInputMetadata.textFieldInputLabels)
                    .accessibilityIdentifier(ComposerInputMetadata.textFieldIdentifier)
            }
            .padding(.horizontal, 13)
            .background(theme.recessedSurface, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .stroke(theme.border, lineWidth: 1)
            }

            Button {
                isGenerating ? stop() : send()
            } label: {
                Label(
                    ComposerInputMetadata.actionLabel(isGenerating: isGenerating),
                    systemImage: isGenerating ? "stop.fill" : "arrow.up"
                )
                    .labelStyle(.iconOnly)
                    .font(.system(size: 16, weight: .black))
                    .frame(
                        width: ComposerInputActionLayoutPolicy.buttonSize(for: currentAction),
                        height: ComposerInputActionLayoutPolicy.buttonSize(for: currentAction)
                    )
                    .background(isGenerating ? Color.red.opacity(0.9) : theme.accent, in: Circle())
                    .foregroundStyle(theme.inverseText)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.return, modifiers: [.command])
            .disabled(isSendDisabled)
            .opacity(isSendDisabled ? 0.55 : 1)
            .accessibilityLabel(ComposerInputMetadata.actionLabel(isGenerating: isGenerating))
            .accessibilityValue(ComposerInputMetadata.actionValue(text: text, isGenerating: isGenerating))
            .accessibilityHint(ComposerInputMetadata.actionHint(text: text, isGenerating: isGenerating))
            .accessibilityInputLabels(ComposerInputMetadata.actionInputLabels(isGenerating: isGenerating))
            .accessibilityIdentifier(ComposerInputMetadata.actionIdentifier(isGenerating: isGenerating))
        }
        .padding(8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(isGenerating ? theme.success.opacity(0.32) : theme.accent.opacity(0.18), lineWidth: 1)
        }
        .onAppear {
            focusComposerIfNeeded()
        }
        .onChange(of: focusRequest.sequence) { _, _ in
            focusComposerIfNeeded()
        }
    }

    private var isSendDisabled: Bool {
        ComposerInputMetadata.isActionDisabled(text: text, isGenerating: isGenerating)
    }

    private var currentAction: ComposerInputAction {
        isGenerating ? .stop : .send
    }

    private func focusComposerIfNeeded() {
        guard focusRequest.shouldFocus else {
            return
        }
        Task { @MainActor in
            focusedField = .input
            clearFocusRequest()
        }
    }
}

enum ComposerBarLayoutPolicy {
    static let horizontalPadding: CGFloat = 18
    static let bottomPadding: CGFloat = 12
    static let minimumReadableWidth: CGFloat = 320
    static let maximumContentWidth: CGFloat = 760

    static func contentWidth(forContainerWidth containerWidth: CGFloat) -> CGFloat {
        min(
            max(containerWidth - horizontalPadding * 2, minimumReadableWidth),
            maximumContentWidth
        )
    }
}

private enum ComposerFocusedField: Hashable {
    case input
}

struct ModelLibraryView: View {
    @EnvironmentObject private var catalog: ModelCatalog
    var isModal = false
    @State private var importTargetModel: LocalModel?
    @State private var pendingUninstallModel: LocalModel?
    @State private var isShowingFileImporter = false
    @State private var operationErrorTitle = "操作失败"
    @State private var operationErrorMessage: String?

    var body: some View {
        ZStack {
            if isModal {
                Color(red: 0.045, green: 0.047, blue: 0.055).ignoresSafeArea()
            }

            GeometryReader { proxy in
                ScrollView {
                    let contentWidth = ModelLibraryWorkspaceLayoutPolicy.contentWidth(
                        forContainerWidth: proxy.size.width
                    )
                    deploymentContent(
                        size: CGSize(width: contentWidth, height: proxy.size.height)
                    )
                        .frame(width: contentWidth, alignment: .topLeading)
                        .padding(.horizontal, ModelLibraryWorkspaceLayoutPolicy.horizontalPadding)
                        .padding(.top, isModal ? 22 : 16)
                        .padding(.bottom, 28)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .scrollIndicators(.hidden)
            }
        }
        .fileImporter(
            isPresented: $isShowingFileImporter,
            allowedContentTypes: [.item],
            allowsMultipleSelection: true
        ) { result in
            handleImport(result)
        }
        .alert(
            operationErrorTitle,
            isPresented: Binding(
                get: { operationErrorMessage != nil },
                set: { isPresented in
                    if isPresented == false {
                        operationErrorMessage = nil
                    }
                }
            )
        ) {
            Button("好", role: .cancel) {}
        } message: {
            Text(operationErrorMessage ?? "")
        }
        .confirmationDialog(
            pendingUninstallModel.map {
                ModelUninstallConfirmationAccessibilityMetadata.title(model: $0)
            } ?? "卸载本地模型文件？",
            isPresented: Binding(
                get: { pendingUninstallModel != nil },
                set: { isPresented in
                    if isPresented == false {
                        pendingUninstallModel = nil
                    }
                }
            ),
            titleVisibility: .visible,
            presenting: pendingUninstallModel
        ) { model in
            Button(role: .destructive) {
                uninstall(model)
                pendingUninstallModel = nil
            } label: {
                Text(ModelUninstallConfirmationAccessibilityMetadata.confirmLabel(model: model))
            }
            .accessibilityLabel(
                ModelUninstallConfirmationAccessibilityMetadata.confirmLabel(model: model)
            )
            .accessibilityHint(
                ModelUninstallConfirmationAccessibilityMetadata.confirmHint(model: model)
            )
            .accessibilityInputLabels(
                ModelUninstallConfirmationAccessibilityMetadata.confirmInputLabels(model: model)
            )
            .accessibilityIdentifier(
                ModelUninstallConfirmationAccessibilityMetadata.confirmIdentifier(model: model)
            )

            Button(role: .cancel) {
                pendingUninstallModel = nil
            } label: {
                Text(ModelUninstallConfirmationAccessibilityMetadata.cancelLabel)
            }
            .accessibilityLabel(ModelUninstallConfirmationAccessibilityMetadata.cancelLabel)
            .accessibilityHint(ModelUninstallConfirmationAccessibilityMetadata.cancelHint)
            .accessibilityInputLabels(
                ModelUninstallConfirmationAccessibilityMetadata.cancelInputLabels
            )
            .accessibilityIdentifier(
                ModelUninstallConfirmationAccessibilityMetadata.cancelIdentifier
            )
        } message: { model in
            Text(ModelUninstallConfirmationAccessibilityMetadata.message(model: model))
        }
    }

    private var selectedModelID: Binding<UUID> {
        Binding(
            get: { catalog.selectedModel.id },
            set: { id in
                guard let model = catalog.models.first(where: { $0.id == id }) else { return }
                withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                    catalog.select(model)
                }
            }
        )
    }

    @ViewBuilder
    private func deploymentContent(size: CGSize) -> some View {
        let model = catalog.selectedModel
        let validation = catalog.validation(for: model)
        let report = LocalRuntimePlanner.preparationReport(for: model, validation: validation)
        let deploymentState = catalog.deploymentState(for: model)
        let layoutMode = ModelLibraryLayoutMode.resolve(for: size)

        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                eyebrow: "MODEL DEPLOY",
                title: "本地模型部署",
                subtitle: "面向 iPhone 的端侧 runtime 控制台，集中管理权重、性能预算和启动状态。"
            )

            if layoutMode == .twoColumn {
                let controlColumnWidth = layoutMode.controlColumnWidth(for: size)
                let detailColumnWidth = ModelDetailColumnLayoutPolicy.width(
                    for: size,
                    layoutMode: layoutMode
                )

                HStack(alignment: .top, spacing: ModelDetailColumnLayoutPolicy.interColumnSpacing) {
                    VStack(spacing: 14) {
                        ModelSelectorPanel(
                            models: catalog.models,
                            selectedModelID: selectedModelID,
                            selectedModel: model,
                            validation: validation,
                            deploymentState: deploymentState
                        )

                        DeploymentPowerButton(
                            model: model,
                            validation: validation,
                            deploymentState: deploymentState,
                            toggle: { catalog.toggleDeployment(for: model) }
                        )

                        ArtifactActionPanel(
                            validation: validation,
                            download: { catalog.simulateDownload(for: model) },
                            uninstall: { requestUninstall(model) },
                            scan: { catalog.refreshArtifactStatus(for: model) },
                            importFiles: {
                                importTargetModel = model
                                isShowingFileImporter = true
                            }
                        )
                    }
                    .frame(width: controlColumnWidth)

                    ModelDetailColumn(model: model, validation: validation, report: report)
                        .frame(width: detailColumnWidth, alignment: .topLeading)

                    Spacer(minLength: 0)
                }
            } else {
                ModelSelectorPanel(
                    models: catalog.models,
                    selectedModelID: selectedModelID,
                    selectedModel: model,
                    validation: validation,
                    deploymentState: deploymentState
                )

                DeploymentPowerButton(
                    model: model,
                    validation: validation,
                    deploymentState: deploymentState,
                    toggle: { catalog.toggleDeployment(for: model) }
                )

                ArtifactActionPanel(
                    validation: validation,
                    download: { catalog.simulateDownload(for: model) },
                    uninstall: { requestUninstall(model) },
                    scan: { catalog.refreshArtifactStatus(for: model) },
                    importFiles: {
                        importTargetModel = model
                        isShowingFileImporter = true
                    }
                )

                ModelDetailColumn(model: model, validation: validation, report: report)
            }
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        defer {
            importTargetModel = nil
        }

        guard let targetModel = importTargetModel else {
            operationErrorTitle = "导入失败"
            operationErrorMessage = "没有选中要导入的模型。"
            return
        }

        do {
            let urls = try result.get()
            try catalog.importArtifacts(for: targetModel, sourceURLs: urls)
        } catch let error as ArtifactImportError {
            operationErrorTitle = "导入失败"
            operationErrorMessage = error.message
        } catch {
            operationErrorTitle = "导入失败"
            operationErrorMessage = error.localizedDescription
        }
    }

    private func requestUninstall(_ model: LocalModel) {
        pendingUninstallModel = model
    }

    private func uninstall(_ model: LocalModel) {
        do {
            try catalog.uninstallArtifacts(for: model)
        } catch {
            operationErrorTitle = "卸载失败"
            operationErrorMessage = error.localizedDescription
        }
    }
}

struct ModelSelectorPanel: View {
    @Environment(\.appTheme) private var theme

    let models: [LocalModel]
    @Binding var selectedModelID: UUID
    let selectedModel: LocalModel
    let validation: ArtifactValidationResult
    let deploymentState: ModelDeploymentState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Label("选择模型", systemImage: "slider.horizontal.3")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(theme.primaryText)

                Spacer()

                Text("\(models.count) 个候选")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(theme.tertiaryText)
            }

            Picker(selection: $selectedModelID) {
                ForEach(models) { model in
                    Text(model.name).tag(model.id)
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "chevron.down.circle.fill")
                        .font(.system(size: 17, weight: .bold))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(selectedModel.name)
                            .font(.system(size: 17, weight: .black, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.74)
                        Text("\(selectedModel.parameterCount) · \(selectedModel.quantization)")
                            .font(.system(size: 11, weight: .semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.74)
                    }
                    Spacer()
                }
            }
            .pickerStyle(.menu)
            .tint(theme.primaryText)
            .frame(
                maxWidth: .infinity,
                minHeight: ModelDeploymentControlLayoutPolicy.modelSelectorMinHeight,
                alignment: .leading
            )
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(theme.recessedSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(theme.accent.opacity(0.24), lineWidth: 1)
            }
            .accessibilityLabel(ModelDeploymentControlAccessibilityMetadata.modelSelectorLabel)
            .accessibilityValue(
                ModelDeploymentControlAccessibilityMetadata.modelSelectorValue(
                    selectedModel: selectedModel,
                    validation: validation,
                    deploymentState: deploymentState,
                    modelCount: models.count
                )
            )
            .accessibilityHint(
                ModelDeploymentControlAccessibilityMetadata.modelSelectorHint(modelCount: models.count)
            )
            .accessibilityInputLabels(
                ModelDeploymentControlAccessibilityMetadata.modelSelectorInputLabels(selectedModel: selectedModel)
            )
            .accessibilityIdentifier(ModelDeploymentControlAccessibilityMetadata.modelSelectorIdentifier)

            HStack(spacing: 8) {
                StatusBadge(state: selectedModel.installState, exposesAccessibility: true)
                AvailabilityBadge(availability: validation.availability)
                DeploymentBadge(state: deploymentState)
            }
        }
        .panelStyle(border: theme.accent.opacity(0.24))
    }
}

struct AvailabilityBadge: View {
    let availability: ArtifactAvailability

    var body: some View {
        Text(availability.title)
            .font(.system(size: 9, weight: .black))
            .textCase(.uppercase)
            .foregroundStyle(tint)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(tint.opacity(0.12), in: Capsule())
            .overlay(Capsule().stroke(tint.opacity(0.34), lineWidth: 1))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(ModelStatusBadgeAccessibilityMetadata.label(for: availability))
            .accessibilityValue(ModelStatusBadgeAccessibilityMetadata.value(for: availability))
            .accessibilityHint(ModelStatusBadgeAccessibilityMetadata.hint)
            .accessibilityInputLabels(ModelStatusBadgeAccessibilityMetadata.inputLabels(for: availability))
            .accessibilityIdentifier(ModelStatusBadgeAccessibilityMetadata.identifier(for: availability))
    }

    private var tint: Color {
        switch availability {
        case .missing:
            return .orange
        case .staged:
            return .cyan
        case .verified:
            return .green
        }
    }
}

struct DeploymentBadge: View {
    let state: ModelDeploymentState

    var body: some View {
        Text(state.title)
            .font(.system(size: 9, weight: .black))
            .textCase(.uppercase)
            .foregroundStyle(state == .running ? .green : .white.opacity(0.58))
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background((state == .running ? Color.green : Color.white).opacity(state == .running ? 0.14 : 0.08), in: Capsule())
            .overlay(Capsule().stroke((state == .running ? Color.green : Color.white).opacity(0.26), lineWidth: 1))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(ModelStatusBadgeAccessibilityMetadata.label(for: state))
            .accessibilityValue(ModelStatusBadgeAccessibilityMetadata.value(for: state))
            .accessibilityHint(ModelStatusBadgeAccessibilityMetadata.hint)
            .accessibilityInputLabels(ModelStatusBadgeAccessibilityMetadata.inputLabels(for: state))
            .accessibilityIdentifier(ModelStatusBadgeAccessibilityMetadata.identifier(for: state))
    }
}

struct DeploymentPowerButton: View {
    let model: LocalModel
    let validation: ArtifactValidationResult
    let deploymentState: ModelDeploymentState
    let toggle: () -> Void

    private var isRunning: Bool {
        deploymentState == .running
    }

    var body: some View {
        Button(action: toggle) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(iconBackground)
                    Image(systemName: isRunning ? "stop.fill" : "power")
                        .font(.system(size: 25, weight: .black))
                }
                .frame(width: 58, height: 58)

                VStack(alignment: .leading, spacing: 5) {
                    Text(isRunning ? "关闭模型部署" : "启动模型部署")
                        .font(.system(size: 21, weight: .heavy, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                    Text(deploymentSubtitle)
                        .font(.system(size: 12, weight: .bold))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Image(systemName: isRunning ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 26, weight: .bold))
                    .opacity(0.84)
            }
            .foregroundStyle(isRunning ? .white : .black)
            .padding(16)
            .frame(
                maxWidth: .infinity,
                minHeight: ModelDeploymentControlLayoutPolicy.powerButtonMinHeight
            )
            .background(buttonFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isRunning ? Color.red.opacity(0.36) : Color.white.opacity(0.42), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            ModelDeploymentControlAccessibilityMetadata.powerLabel(
                model: model,
                deploymentState: deploymentState
            )
        )
        .accessibilityValue(
            ModelDeploymentControlAccessibilityMetadata.powerValue(
                model: model,
                validation: validation,
                deploymentState: deploymentState
            )
        )
        .accessibilityHint(
            ModelDeploymentControlAccessibilityMetadata.powerHint(
                validation: validation,
                deploymentState: deploymentState
            )
        )
        .accessibilityInputLabels(
            ModelDeploymentControlAccessibilityMetadata.powerInputLabels(
                model: model,
                deploymentState: deploymentState
            )
        )
        .accessibilityIdentifier("model-deployment-power")
    }

    private var buttonFill: some ShapeStyle {
        LinearGradient(
            colors: isRunning
                ? [Color.red.opacity(0.92), Color.orange.opacity(0.72)]
                : [Color.cyan, Color.green.opacity(0.88)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var iconBackground: Color {
        isRunning ? Color.black.opacity(0.2) : Color.white.opacity(0.4)
    }

    private var deploymentSubtitle: String {
        if isRunning {
            return "\(model.name) 正在\(validation.availability == .verified ? "真实 runtime" : "模拟 runtime")运行"
        }
        return validation.availability == .verified
            ? "已校验权重，启动后接入 \(model.deploymentProfile.primaryBackend.shortTitle)"
            : "未校验权重，启动后走本地模拟部署"
    }
}

struct ArtifactActionPanel: View {
    @Environment(\.appTheme) private var theme

    let validation: ArtifactValidationResult
    let download: () -> Void
    let uninstall: () -> Void
    let scan: () -> Void
    let importFiles: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("模型文件")
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(theme.primaryText)

            HStack(spacing: 10) {
                ArtifactActionButton(
                    metadataAction: .download,
                    availability: validation.availability,
                    title: "下载模型",
                    subtitle: validation.availability == .missing ? "模拟暂存" : "重新暂存",
                    icon: "arrow.down.circle.fill",
                    isDestructive: false,
                    action: download
                )

                ArtifactActionButton(
                    metadataAction: .uninstall,
                    availability: validation.availability,
                    title: "卸载模型",
                    subtitle: "移除本地文件",
                    icon: "trash.circle.fill",
                    isDestructive: true,
                    action: uninstall
                )
            }

            HStack(spacing: 10) {
                Button(action: scan) {
                    Label("扫描本地", systemImage: "folder.badge.gearshape")
                        .frame(maxWidth: .infinity)
                }
                .compactUtilityStyle()
                .frame(minHeight: ModelArtifactActionLayoutPolicy.utilityButtonMinHeight)
                .contentShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                .accessibilityLabel(
                    ModelDeploymentControlAccessibilityMetadata.artifactActionLabel(.scan)
                )
                .accessibilityValue(
                    ModelDeploymentControlAccessibilityMetadata.artifactActionValue(
                        .scan,
                        availability: validation.availability
                    )
                )
                .accessibilityHint(
                    ModelDeploymentControlAccessibilityMetadata.artifactActionHint(
                        .scan,
                        availability: validation.availability
                    )
                )
                .accessibilityInputLabels(
                    ModelDeploymentControlAccessibilityMetadata.artifactActionInputLabels(.scan)
                )
                .accessibilityIdentifier(
                    ModelDeploymentControlAccessibilityMetadata.artifactActionIdentifier(.scan)
                )

                Button(action: importFiles) {
                    Label("导入文件", systemImage: "square.and.arrow.down.fill")
                        .frame(maxWidth: .infinity)
                }
                .compactUtilityStyle()
                .frame(minHeight: ModelArtifactActionLayoutPolicy.utilityButtonMinHeight)
                .contentShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                .accessibilityLabel(
                    ModelDeploymentControlAccessibilityMetadata.artifactActionLabel(.importFiles)
                )
                .accessibilityValue(
                    ModelDeploymentControlAccessibilityMetadata.artifactActionValue(
                        .importFiles,
                        availability: validation.availability
                    )
                )
                .accessibilityHint(
                    ModelDeploymentControlAccessibilityMetadata.artifactActionHint(
                        .importFiles,
                        availability: validation.availability
                    )
                )
                .accessibilityInputLabels(
                    ModelDeploymentControlAccessibilityMetadata.artifactActionInputLabels(.importFiles)
                )
                .accessibilityIdentifier(
                    ModelDeploymentControlAccessibilityMetadata.artifactActionIdentifier(.importFiles)
                )
            }
        }
        .panelStyle()
        .accessibilityElement(children: .contain)
        .accessibilityLabel(ModelArtifactPanelAccessibilityMetadata.label)
        .accessibilityValue(
            ModelArtifactPanelAccessibilityMetadata.value(validation: validation)
        )
        .accessibilityHint(ModelArtifactPanelAccessibilityMetadata.hint)
        .accessibilityInputLabels(ModelArtifactPanelAccessibilityMetadata.inputLabels)
        .accessibilityIdentifier(ModelArtifactPanelAccessibilityMetadata.identifier)
    }
}

struct ArtifactActionButton: View {
    let metadataAction: ModelDeploymentControlAccessibilityMetadata.ArtifactAction
    let availability: ArtifactAvailability
    let title: String
    let subtitle: String
    let icon: String
    let isDestructive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 23, weight: .black))
                Spacer(minLength: 0)
                Text(title)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.74)
                Text(subtitle)
                    .font(.system(size: 10, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                    .opacity(0.68)
            }
            .foregroundStyle(isDestructive ? .white : .black)
            .frame(maxWidth: .infinity, minHeight: 86, alignment: .leading)
            .padding(12)
            .background(
                LinearGradient(
                    colors: isDestructive
                        ? [Color.red.opacity(0.88), Color.red.opacity(0.55)]
                        : [Color.cyan, Color.green.opacity(0.78)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            ModelDeploymentControlAccessibilityMetadata.artifactActionLabel(metadataAction)
        )
        .accessibilityValue(
            ModelDeploymentControlAccessibilityMetadata.artifactActionValue(
                metadataAction,
                availability: availability
            )
        )
        .accessibilityHint(
            ModelDeploymentControlAccessibilityMetadata.artifactActionHint(
                metadataAction,
                availability: availability
            )
        )
        .accessibilityInputLabels(
            ModelDeploymentControlAccessibilityMetadata.artifactActionInputLabels(metadataAction)
        )
        .accessibilityIdentifier(
            ModelDeploymentControlAccessibilityMetadata.artifactActionIdentifier(metadataAction)
        )
    }
}

struct ModelDetailColumn: View {
    let model: LocalModel
    let validation: ArtifactValidationResult
    let report: RuntimePreparationReport

    var body: some View {
        VStack(spacing: 14) {
            ModelSummaryPanel(model: model, validation: validation)
            ModelParametersPanel(model: model)
            ModelPerformancePanel(model: model, validation: validation, report: report)
            ModelAdvicePanel(model: model, report: report)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(ModelDetailAccessibilityMetadata.label(model: model))
        .accessibilityValue(
            ModelDetailAccessibilityMetadata.value(
                model: model,
                validation: validation,
                report: report
            )
        )
        .accessibilityHint(ModelDetailAccessibilityMetadata.hint)
        .accessibilityInputLabels(ModelDetailAccessibilityMetadata.inputLabels(model: model))
        .accessibilityIdentifier(ModelDetailAccessibilityMetadata.identifier)
    }
}

struct ModelSummaryPanel: View {
    @Environment(\.appTheme) private var theme

    let model: LocalModel
    let validation: ArtifactValidationResult

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(iconFill)
                    Image(systemName: model.family == "Gemma" ? "sparkles" : "cube.transparent.fill")
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(model.family == "Gemma" ? theme.accent : theme.secondaryText)
                }
                .frame(width: 50, height: 50)

                VStack(alignment: .leading, spacing: 5) {
                    Text(model.name)
                        .font(.system(size: 19, weight: .heavy, design: .rounded))
                        .foregroundStyle(theme.primaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    Text(model.summary)
                        .font(.system(size: 12, weight: .medium))
                        .lineSpacing(2)
                        .foregroundStyle(theme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            FlowLayout(items: model.capabilities) { capability in
                Text(capability)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(theme.secondaryText)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.08), in: Capsule())
            }

            Text(validation.summary)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(theme.secondaryText)
                .lineLimit(2)
        }
        .panelStyle(border: theme.border)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(ModelSummaryAccessibilityMetadata.label(model: model))
        .accessibilityValue(
            ModelSummaryAccessibilityMetadata.value(model: model, validation: validation)
        )
        .accessibilityHint(ModelSummaryAccessibilityMetadata.hint)
        .accessibilityInputLabels(ModelSummaryAccessibilityMetadata.inputLabels(model: model))
        .accessibilityIdentifier(ModelSummaryAccessibilityMetadata.identifier)
    }

    private var iconFill: some ShapeStyle {
        LinearGradient(
            colors: model.family == "Gemma"
                ? [Color.cyan.opacity(0.22), Color.green.opacity(0.14)]
                : [theme.surface, theme.chipSurface],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct ModelParametersPanel: View {
    let model: LocalModel

    var body: some View {
        DetailPanel(title: "参数", icon: "number.square.fill") {
            DetailRow(title: "模型家族", value: model.family)
            DetailRow(title: "参数规模", value: model.parameterCount)
            DetailRow(title: "量化格式", value: model.quantization)
            DetailRow(title: "上下文长度", value: "\(model.contextLength) tokens")
            DetailRow(title: "文件格式", value: model.artifactManifest.fileFormat)
            DetailRow(title: "包体大小", value: model.sizeOnDisk)
        }
    }
}

struct ModelPerformancePanel: View {
    let model: LocalModel
    let validation: ArtifactValidationResult
    let report: RuntimePreparationReport

    var body: some View {
        DetailPanel(title: "性能", icon: "speedometer") {
            DetailRow(title: "预计速度", value: String(format: "%.1f tok/s", model.tokensPerSecond))
            DetailRow(title: "内存预算", value: model.memoryFootprint)
            DetailRow(title: "主后端", value: report.activeBackend.title)
            DetailRow(title: "回退后端", value: report.fallbackBackend.title)
            DetailRow(title: "KV cache", value: model.deploymentProfile.kvCachePolicy)
            DetailRow(title: "权重状态", value: validation.availability.title)
        }
    }
}

struct ModelAdvicePanel: View {
    let model: LocalModel
    let report: RuntimePreparationReport

    var body: some View {
        DetailPanel(title: "建议", icon: "lightbulb.fill") {
            if report.blockers.isEmpty == false {
                ForEach(report.blockers.indices, id: \.self) { index in
                    AdviceRow(
                        text: report.blockers[index],
                        icon: "exclamationmark.triangle.fill",
                        tint: .orange,
                        kind: .blocker,
                        sequence: index + 1
                    )
                }
            }

            ForEach(report.nextSteps.indices, id: \.self) { index in
                AdviceRow(
                    text: report.nextSteps[index],
                    icon: "checkmark.seal.fill",
                    tint: .green,
                    kind: .nextStep,
                    sequence: index + 1
                )
            }

            AdviceRow(
                text: "建议在 \(model.deploymentProfile.preferredChipClass) 上使用 \(model.deploymentProfile.thermalStrategy)。",
                icon: "cpu.fill",
                tint: .cyan,
                kind: .chipStrategy
            )
        }
    }
}

struct DetailPanel<Content: View>: View {
    @Environment(\.appTheme) private var theme

    let title: String
    let icon: String
    let content: Content

    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(theme.primaryText)

            VStack(spacing: 9) {
                content
            }
        }
        .panelStyle()
    }
}

struct DetailRow: View {
    @Environment(\.appTheme) private var theme

    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(theme.tertiaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.76)

            Spacer(minLength: 12)

            Text(value)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(theme.primaryText)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, minHeight: 24)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(ModelDetailRowAccessibilityMetadata.label(title: title))
        .accessibilityValue(ModelDetailRowAccessibilityMetadata.value(title: title, value: value))
        .accessibilityHint(ModelDetailRowAccessibilityMetadata.hint)
        .accessibilityInputLabels(ModelDetailRowAccessibilityMetadata.inputLabels(title: title))
        .accessibilityIdentifier(ModelDetailRowAccessibilityMetadata.identifier(title: title))
    }
}

struct AdviceRow: View {
    @Environment(\.appTheme) private var theme

    let text: String
    let icon: String
    let tint: Color
    let kind: ModelDetailRowAccessibilityMetadata.AdviceKind
    var sequence: Int = 1

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 16)

            Text(text)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(theme.secondaryText)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(ModelDetailRowAccessibilityMetadata.adviceLabel(kind: kind))
        .accessibilityValue(ModelDetailRowAccessibilityMetadata.adviceValue(text: text))
        .accessibilityHint(ModelDetailRowAccessibilityMetadata.hint)
        .accessibilityInputLabels(ModelDetailRowAccessibilityMetadata.adviceInputLabels(kind: kind))
        .accessibilityIdentifier(
            ModelDetailRowAccessibilityMetadata.adviceIdentifier(kind: kind, sequence: sequence)
        )
    }
}

struct SettingsWorkspace: View {
    @EnvironmentObject private var optimizer: DeviceOptimizer
    @Environment(\.appTheme) private var theme
    @State private var selectedWallpaperItem: PhotosPickerItem?
    @State private var isImportingWallpaper = false
    @State private var wallpaperImportError: String?

    let themeMode: AppThemeMode
    let wallpaperData: Data
    let toggleTheme: () -> Void
    let setWallpaperData: (Data) -> Void
    let clearWallpaper: () -> Void

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader(
                        eyebrow: "SETTINGS",
                        title: "设置",
                        subtitle: "集中管理外观、端侧运行策略、内存预算和离线隐私保护。"
                    )

                    ThemePreferencePanel(themeMode: themeMode, toggleTheme: toggleTheme)
                    WallpaperPreferencePanel(
                        wallpaperData: wallpaperData,
                        selectedItem: $selectedWallpaperItem,
                        isImporting: isImportingWallpaper,
                        clearWallpaper: clearWallpaper
                    )

                    SectionHeader(
                        eyebrow: "APPLE SILICON",
                        title: "芯片部署优化",
                        subtitle: "面向 iPhone 统一内存、Metal 预热、热状态和离线推理路径。"
                    )

                    ChipReadinessCard(
                        progress: optimizer.deploymentReadiness,
                        thermalState: optimizer.thermalState,
                        privacyGuardEnabled: optimizer.isOfflinePrivacyGuardEnabled
                    )

                    OptimizerMetricGrid(metrics: optimizer.metrics)

                    OptimizationToggleGrid(
                        items: optimizer.switches,
                        border: theme.border,
                        toggle: { optimizer.toggle($0) }
                    )
                }
                .frame(
                    width: SettingsWorkspaceLayoutPolicy.contentWidth(
                        forContainerWidth: proxy.size.width
                    ),
                    alignment: .leading
                )
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, SettingsWorkspaceLayoutPolicy.horizontalPadding)
                .padding(.top, 16)
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
    }
}

enum SettingsWorkspaceLayoutPolicy {
    static let horizontalPadding: CGFloat = 18
    static let minimumReadableWidth: CGFloat = 320
    static let maximumContentWidth: CGFloat = 760

    static func contentWidth(forContainerWidth containerWidth: CGFloat) -> CGFloat {
        guard containerWidth.isFinite, containerWidth > 0 else {
            return minimumReadableWidth
        }

        let paddedWidth = max(containerWidth - horizontalPadding * 2, 0)
        guard paddedWidth >= minimumReadableWidth else {
            return paddedWidth
        }

        return min(paddedWidth, maximumContentWidth)
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

struct ThemePreferencePanel: View {
    @Environment(\.appTheme) private var theme

    let themeMode: AppThemeMode
    let toggleTheme: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(theme.accent.opacity(0.16))
                Image(systemName: themeMode.icon)
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(theme.accent)
            }
            .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 5) {
                Text("外观模式")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(theme.primaryText)
                Text(themeMode.title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(theme.secondaryText)
            }

            Spacer()

            Button(action: toggleTheme) {
                Image(systemName: themeMode.icon)
                    .font(.system(size: 15, weight: .black))
                    .frame(
                        width: SettingsIconActionLayoutPolicy.iconButtonSize,
                        height: SettingsIconActionLayoutPolicy.iconButtonSize
                    )
                    .background(theme.accent, in: Circle())
                    .foregroundStyle(theme.inverseText)
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
        .panelStyle(border: theme.accent.opacity(0.26))
    }
}

struct WallpaperPreferencePanel: View {
    @Environment(\.appTheme) private var theme

    let wallpaperData: Data
    @Binding var selectedItem: PhotosPickerItem?
    let isImporting: Bool
    let clearWallpaper: () -> Void

    var body: some View {
        let hasCustomWallpaper = wallpaperData.isEmpty == false
        let pickerAccent = theme.accent
        let pickerForeground = theme.inverseText

        HStack(spacing: 14) {
            wallpaperPreview

            VStack(alignment: .leading, spacing: 5) {
                Text("壁纸")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(theme.primaryText)
                Text(statusText)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(theme.secondaryText)
            }

            Spacer()

            HStack(spacing: 8) {
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    ZStack {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 14, weight: .black))
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
                .disabled(isImporting)
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
                        .font(.system(size: 12, weight: .black))
                        .frame(
                            width: SettingsIconActionLayoutPolicy.iconButtonSize,
                            height: SettingsIconActionLayoutPolicy.iconButtonSize
                        )
                        .background(theme.chipSurface, in: Circle())
                        .overlay(Circle().stroke(theme.border, lineWidth: 1))
                        .foregroundStyle(theme.primaryText)
                }
                .buttonStyle(.plain)
                .disabled(wallpaperData.isEmpty || isImporting)
                .opacity(wallpaperData.isEmpty || isImporting ? 0.42 : 1)
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
        .panelStyle(border: theme.border)
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
                    .frame(width: 58, height: 58)
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
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(theme.accent)
                }
                .frame(width: 58, height: 58)
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
        ZStack {
            if isModal {
                Color(red: 0.045, green: 0.047, blue: 0.055).ignoresSafeArea()
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader(
                        eyebrow: "APPLE SILICON",
                        title: "芯片部署优化",
                        subtitle: "面向 iPhone 统一内存、Metal 预热、热状态和离线推理路径。"
                    )

                    ChipReadinessCard(
                        progress: optimizer.deploymentReadiness,
                        thermalState: optimizer.thermalState,
                        privacyGuardEnabled: optimizer.isOfflinePrivacyGuardEnabled
                    )

                    OptimizerMetricGrid(metrics: optimizer.metrics)

                    OptimizationToggleGrid(
                        items: optimizer.switches,
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

struct ChipReadinessCard: View {
    @Environment(\.appTheme) private var theme

    let progress: Double
    let thermalState: String
    let privacyGuardEnabled: Bool

    var body: some View {
        HStack(spacing: 16) {
            ReadinessRing(
                progress: progress,
                accessibilityIdentifier: ChipReadinessAccessibilityMetadata.chipRingIdentifier
            )
                .frame(width: 86, height: 86)

            VStack(alignment: .leading, spacing: 8) {
                Text("A17 Pro / M 系列准备度")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(theme.primaryText)

                Text(
                    ChipReadinessAccessibilityMetadata.summary(
                        thermalState: thermalState,
                        privacyGuardEnabled: privacyGuardEnabled
                    )
                )
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(theme.secondaryText)
                    .lineSpacing(2)

                ProgressView(value: progress)
                    .tint(.cyan)
            }
        }
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
                .font(.title3.weight(.heavy))
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

    var body: some View {
        ViewThatFits(in: .horizontal) {
            metricGrid(columnCount: OptimizerMetricGridLayoutPolicy.maxColumnCount)
            metricGrid(columnCount: 1)
        }
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

struct OptimizationToggleGrid: View {
    @Environment(\.appTheme) private var theme

    let items: [OptimizationSwitch]
    var titleColor: Color?
    var border: Color = Color.primary.opacity(0.12)
    let toggle: (OptimizationSwitch) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("运行策略")
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(titleColor ?? theme.primaryText)

            ViewThatFits(in: .horizontal) {
                toggleGrid(columnCount: OptimizationToggleGridLayoutPolicy.maxColumnCount)
                toggleGrid(columnCount: 1)
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

    let item: OptimizationSwitch
    let toggle: () -> Void

    var body: some View {
        Button(action: toggle) {
            HStack(spacing: 12) {
                Image(systemName: item.isEnabled ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(item.isEnabled ? theme.success : theme.tertiaryText)

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(theme.primaryText)
                    Text(item.subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(theme.secondaryText)
                        .lineLimit(2)
                }

                Spacer()
            }
            .padding(12)
            .frame(minHeight: OptimizationToggleRowLayoutPolicy.rowMinHeight)
            .background(theme.recessedSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(OptimizationToggleAccessibilityMetadata.label(for: item))
        .accessibilityValue(OptimizationToggleAccessibilityMetadata.value(for: item))
        .accessibilityHint(OptimizationToggleAccessibilityMetadata.hint(for: item))
        .accessibilityInputLabels(OptimizationToggleAccessibilityMetadata.inputLabels(for: item))
        .accessibilityAddTraits(item.isEnabled ? .isSelected : [])
        .accessibilityIdentifier(OptimizationToggleAccessibilityMetadata.identifier(for: item))
    }
}

struct SectionHeader: View {
    @Environment(\.appTheme) private var theme

    let eyebrow: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: SectionHeaderTextLayoutPolicy.verticalSpacing) {
            Text(eyebrow)
                .font(.caption.weight(.black))
                .foregroundStyle(theme.accent)
                .tracking(SectionHeaderTextLayoutPolicy.eyebrowTracking)
                .lineLimit(SectionHeaderTextLayoutPolicy.eyebrowLineLimit)
            Text(title)
                .font(.title2.weight(.heavy))
                .foregroundStyle(theme.primaryText)
                .lineLimit(SectionHeaderTextLayoutPolicy.titleLineLimit)
                .fixedSize(horizontal: false, vertical: true)
            Text(subtitle)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(theme.secondaryText)
                .lineLimit(SectionHeaderTextLayoutPolicy.subtitleLineLimit)
                .lineSpacing(SectionHeaderTextLayoutPolicy.subtitleLineSpacing)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct FlowLayout<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let items: Data
    let content: (Data.Element) -> Content

    init(items: Data, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.items = items
        self.content = content
    }

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(Array(items), id: \.self) { item in
                content(item)
            }
        }
    }
}

extension View {
    func panelStyle(border: Color = Color.primary.opacity(0.12)) -> some View {
        self
            .padding(14)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(border, lineWidth: 1)
            }
    }

    func primaryActionStyle(isActive: Bool) -> some View {
        self
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(isActive ? .black : Color.primary)
            .padding(.vertical, 11)
            .background(isActive ? Color.cyan : Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isActive ? Color.cyan.opacity(0.6) : Color.primary.opacity(0.12), lineWidth: 1)
            }
            .buttonStyle(.plain)
    }

    func secondaryActionStyle() -> some View {
        self
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(Color.primary)
            .padding(.vertical, 11)
            .background(Color.green.opacity(0.16), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.green.opacity(0.32), lineWidth: 1)
            }
            .buttonStyle(.plain)
    }

    func compactUtilityStyle() -> some View {
        self
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(Color.primary.opacity(0.86))
            .padding(.vertical, 10)
            .background(Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .stroke(Color.primary.opacity(0.14), lineWidth: 1)
            }
            .buttonStyle(.plain)
    }
}
