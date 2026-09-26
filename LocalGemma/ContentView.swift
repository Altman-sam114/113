import Foundation
import PhotosUI
import SwiftUI
import UIKit
import UniformTypeIdentifiers

enum AppMotionEffect: CaseIterable, Hashable {
    case workspaceNavigation
    case transcriptAutoScroll
    case modelSelection
    case themeChange
    case copyConfirmation

    var isLargeSpatial: Bool {
        switch self {
        case .workspaceNavigation, .transcriptAutoScroll, .modelSelection:
            return true
        case .themeChange, .copyConfirmation:
            return false
        }
    }

}

enum AppMotionAccessibilityPolicy {
    static let reducedFeedbackDuration = 0.12

    static func animation(
        _ standardAnimation: Animation,
        for effect: AppMotionEffect,
        reduceMotion: Bool
    ) -> Animation? {
        guard reduceMotion else {
            return standardAnimation
        }

        guard effect.isLargeSpatial == false else {
            return nil
        }

        return .easeOut(duration: reducedFeedbackDuration)
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
            return min(max(size.width * 0.25, 224), 256)
        case .landscapeRegular:
            return min(max(size.width * 0.22, 260), 288)
        }
    }
}

enum WorkspaceRootAxis: Equatable {
    case vertical
    case horizontal
}

enum WorkspaceChromePresentation: Equatable {
    case topNavigation
    case compactSidebar
    case detailedSidebar
}

struct WorkspaceRootLayoutPlan: Equatable {
    let mode: WorkspaceLayoutMode
    let axis: WorkspaceRootAxis
    let chrome: WorkspaceChromePresentation
    let sidebarWidth: CGFloat
}

enum WorkspaceRootLayoutPolicy {
    static func resolve(for size: CGSize) -> WorkspaceRootLayoutPlan {
        let mode = WorkspaceLayoutMode.resolve(for: size)

        switch mode {
        case .portrait:
            return WorkspaceRootLayoutPlan(
                mode: mode,
                axis: .vertical,
                chrome: .topNavigation,
                sidebarWidth: 0
            )
        case .landscapeCompact:
            return WorkspaceRootLayoutPlan(
                mode: mode,
                axis: .horizontal,
                chrome: .compactSidebar,
                sidebarWidth: mode.sidebarWidth(for: size)
            )
        case .landscapeRegular:
            return WorkspaceRootLayoutPlan(
                mode: mode,
                axis: .horizontal,
                chrome: .detailedSidebar,
                sidebarWidth: mode.sidebarWidth(for: size)
            )
        }
    }
}

struct WorkspaceRootShell<Chrome: View, Content: View>: View {
    let plan: WorkspaceRootLayoutPlan
    let chrome: Chrome
    let content: Content

    init(
        plan: WorkspaceRootLayoutPlan,
        @ViewBuilder chrome: () -> Chrome,
        @ViewBuilder content: () -> Content
    ) {
        self.plan = plan
        self.chrome = chrome()
        self.content = content()
    }

    var body: some View {
        let rootLayout = plan.axis == .horizontal
            ? AnyLayout(HStackLayout(spacing: 0))
            : AnyLayout(VStackLayout(spacing: 0))

        rootLayout {
            chrome
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct WorkspacePagePresentation: Equatable {
    let opacity: Double
    let allowsHitTesting: Bool
    let isDisabled: Bool
    let isAccessibilityHidden: Bool
    let zIndex: Double
}

enum WorkspacePagesInteractionPolicy {
    static func presentation(
        for page: WorkspaceTab,
        selectedTab: WorkspaceTab
    ) -> WorkspacePagePresentation {
        let isSelected = page == selectedTab

        return WorkspacePagePresentation(
            opacity: isSelected ? 1 : 0,
            allowsHitTesting: isSelected,
            isDisabled: !isSelected,
            isAccessibilityHidden: !isSelected,
            zIndex: isSelected ? 1 : 0
        )
    }
}

struct WorkspacePagesShell<Chat: View, Models: View, Prompts: View, Settings: View>: View {
    let selectedTab: WorkspaceTab
    let chat: Chat
    let models: Models
    let prompts: Prompts
    let settings: Settings

    init(
        selectedTab: WorkspaceTab,
        @ViewBuilder chat: () -> Chat,
        @ViewBuilder models: () -> Models,
        @ViewBuilder prompts: () -> Prompts,
        @ViewBuilder settings: () -> Settings
    ) {
        self.selectedTab = selectedTab
        self.chat = chat()
        self.models = models()
        self.prompts = prompts()
        self.settings = settings()
    }

    var body: some View {
        ZStack {
            page(chat, tab: .chat)
            page(models, tab: .models)
            page(prompts, tab: .prompts)
            page(settings, tab: .settings)
        }
    }

    private func page<Page: View>(_ page: Page, tab: WorkspaceTab) -> some View {
        let presentation = WorkspacePagesInteractionPolicy.presentation(
            for: tab,
            selectedTab: selectedTab
        )

        return page
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .opacity(presentation.opacity)
            .allowsHitTesting(presentation.allowsHitTesting)
            .disabled(presentation.isDisabled)
            .accessibilityHidden(presentation.isAccessibilityHidden)
            .zIndex(presentation.zIndex)
    }
}

enum SessionSidebarLayoutPolicy {
    static let minimumWidth: CGFloat = 240
    static let maximumWidth: CGFloat = 310
    static let widthRatio: CGFloat = 0.28

    static func preferredWidth(forContainerWidth width: CGFloat) -> CGFloat {
        guard width.isFinite, width > 0 else {
            return 0
        }

        return min(max(width * widthRatio, minimumWidth), maximumWidth)
    }

    static func width(for size: CGSize, layoutMode: WorkspaceLayoutMode) -> CGFloat {
        guard layoutMode.usesSidebar else {
            return 0
        }

        return preferredWidth(forContainerWidth: size.width)
    }
}

enum ChatWorkspacePaneMode: Equatable {
    case stacked
    case split
}

struct ChatWorkspacePaneLayout: Equatable {
    let mode: ChatWorkspacePaneMode
    let sessionSidebarWidth: CGFloat
    let chatSurfaceWidth: CGFloat
}

enum ChatWorkspacePaneLayoutPolicy {
    static let minimumChatSurfaceWidth: CGFloat = 620

    static var minimumSplitContainerWidth: CGFloat {
        minimumChatSurfaceWidth + SessionSidebarLayoutPolicy.minimumWidth
    }

    static func resolve(for size: CGSize) -> ChatWorkspacePaneLayout {
        let containerWidth = size.width
        guard containerWidth.isFinite, containerWidth > 0 else {
            return ChatWorkspacePaneLayout(
                mode: .stacked,
                sessionSidebarWidth: 0,
                chatSurfaceWidth: 0
            )
        }

        guard containerWidth >= minimumSplitContainerWidth else {
            return ChatWorkspacePaneLayout(
                mode: .stacked,
                sessionSidebarWidth: 0,
                chatSurfaceWidth: containerWidth
            )
        }

        let preferredSidebarWidth = SessionSidebarLayoutPolicy.preferredWidth(
            forContainerWidth: containerWidth
        )
        let availableSidebarWidth = containerWidth - minimumChatSurfaceWidth
        let sessionSidebarWidth = min(preferredSidebarWidth, availableSidebarWidth)

        guard sessionSidebarWidth >= SessionSidebarLayoutPolicy.minimumWidth else {
            return ChatWorkspacePaneLayout(
                mode: .stacked,
                sessionSidebarWidth: 0,
                chatSurfaceWidth: containerWidth
            )
        }

        return ChatWorkspacePaneLayout(
            mode: .split,
            sessionSidebarWidth: sessionSidebarWidth,
            chatSurfaceWidth: containerWidth - sessionSidebarWidth
        )
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

struct SessionCommandFocusedRoute {
    let actions: SessionCommandActions?
}

private struct SessionCommandFocusedRouteKey: FocusedValueKey {
    typealias Value = SessionCommandFocusedRoute
}

extension FocusedValues {
    var workspaceTabSelection: Binding<WorkspaceTab>? {
        get { self[WorkspaceTabSelectionFocusedKey.self] }
        set { self[WorkspaceTabSelectionFocusedKey.self] = newValue }
    }

    var sessionCommandFocusedRoute: SessionCommandFocusedRoute? {
        get { self[SessionCommandFocusedRouteKey.self] }
        set { self[SessionCommandFocusedRouteKey.self] = newValue }
    }
}

struct ContentView: View {
    @EnvironmentObject private var catalog: ModelCatalog
    @EnvironmentObject private var inference: InferenceEngine
    @EnvironmentObject private var optimizer: DeviceOptimizer
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
                    let layoutPlan = WorkspaceRootLayoutPolicy.resolve(for: proxy.size)

                    WorkspaceRootShell(plan: layoutPlan) {
                        workspaceChrome(
                            themeMode: themeMode,
                            selectedValidation: selectedValidation,
                            layoutPlan: layoutPlan,
                            rootSize: proxy.size
                        )
                    } content: {
                        workspacePages(themeMode: themeMode)
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
        WorkbenchPresentationPolicy.initialWorkspace(arguments: ProcessInfo.processInfo.arguments)
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
        withAnimation(
            AppMotionAccessibilityPolicy.animation(
                .spring(response: 0.28, dampingFraction: 0.84),
                for: .workspaceNavigation,
                reduceMotion: reduceMotion
            )
        ) {
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

    private func headerView(
        themeMode: AppThemeMode,
        selectedValidation: ArtifactValidationResult,
        capsuleAvailableWidth: CGFloat,
        layoutMode: WorkspaceLayoutMode
    ) -> some View {
        HeaderView(
            model: catalog.selectedModel,
            readiness: optimizer.deploymentReadiness,
            tokensPerSecond: inference.currentTokensPerSecond,
            memoryUsageMB: inference.memoryUsageMB,
            backend: inference.currentBackend,
            availability: selectedValidation.availability,
            deploymentState: catalog.deploymentState(for: catalog.selectedModel),
            isGenerating: inference.isGenerating,
            isSimulated: inference.lastResultWasSimulated,
            capsuleAvailableWidth: capsuleAvailableWidth,
            layoutMode: layoutMode,
            themeMode: themeMode,
            toggleTheme: {
                withAnimation(
                    AppMotionAccessibilityPolicy.animation(
                        .spring(response: 0.28, dampingFraction: 0.82),
                        for: .themeChange,
                        reduceMotion: reduceMotion
                    )
                ) {
                    themeModeStorage = themeMode.toggled.rawValue
                }
            },
            showModels: {
                withAnimation(
                    AppMotionAccessibilityPolicy.animation(
                        .spring(response: 0.3, dampingFraction: 0.82),
                        for: .workspaceNavigation,
                        reduceMotion: reduceMotion
                    )
                ) {
                    selectWorkspace(.models)
                }
            }
        )
    }

    @ViewBuilder
    private func workspaceChrome(
        themeMode: AppThemeMode,
        selectedValidation: ArtifactValidationResult,
        layoutPlan: WorkspaceRootLayoutPlan,
        rootSize: CGSize
    ) -> some View {
        switch layoutPlan.chrome {
        case .topNavigation:
            VStack(spacing: 0) {
                headerView(
                    themeMode: themeMode,
                    selectedValidation: selectedValidation,
                    capsuleAvailableWidth: ModelCapsuleLayoutPolicy.availableWidth(
                        forChromeWidth: rootSize.width
                    ),
                    layoutMode: layoutPlan.mode
                )
                    .padding(.horizontal, 18)
                    .padding(.top, 8)

                tabPicker
                    .padding(.horizontal, 18)
                    .padding(.top, 14)
            }
        case .compactSidebar, .detailedSidebar:
            sidebarChrome(
                themeMode: themeMode,
                selectedValidation: selectedValidation,
                sidebarWidth: layoutPlan.sidebarWidth,
                isDetailed: layoutPlan.chrome == .detailedSidebar
            )
        }
    }

    private func sidebarChrome(
        themeMode: AppThemeMode,
        selectedValidation: ArtifactValidationResult,
        sidebarWidth: CGFloat,
        isDetailed: Bool
    ) -> some View {
        let theme = currentTheme

        return GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerView(
                        themeMode: themeMode,
                        selectedValidation: selectedValidation,
                        capsuleAvailableWidth: ModelCapsuleLayoutPolicy.availableWidth(forChromeWidth: sidebarWidth),
                        layoutMode: isDetailed ? .landscapeRegular : .landscapeCompact
                    )
                    VStack(alignment: .leading, spacing: 12) {
                        Text("工作空间")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(theme.secondaryText)
                            .padding(.leading, 12)
                        sidebarTabPicker(isDetailed: isDetailed)
                    }
                    Spacer(minLength: 12)
                    VStack(alignment: .leading, spacing: 14) {
                        Text("当前模型")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(theme.secondaryText)
                        ModelCapsule(
                            model: catalog.selectedModel,
                            readiness: optimizer.deploymentReadiness,
                            tokensPerSecond: inference.currentTokensPerSecond,
                            memoryUsageMB: inference.memoryUsageMB,
                            backend: inference.currentBackend,
                            availability: selectedValidation.availability,
                            deploymentState: catalog.deploymentState(for: catalog.selectedModel),
                            isGenerating: inference.isGenerating,
                            isSimulated: inference.lastResultWasSimulated,
                            availableWidth: ModelCapsuleLayoutPolicy.availableWidth(forChromeWidth: sidebarWidth),
                            layoutMode: isDetailed ? .landscapeRegular : .landscapeCompact
                        )
                        WorkbenchSidebarFooter()
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 22)
                .frame(minHeight: geometry.size.height, alignment: .topLeading)
            }
            .scrollIndicators(.hidden)
        }
        .frame(width: sidebarWidth)
        .background(theme.recessedSurface)
        .overlay(alignment: .trailing) { theme.subtleBorder.frame(width: 1) }
    }

    private func workspacePages(themeMode: AppThemeMode) -> some View {
        WorkspacePagesShell(selectedTab: selectedTab) {
            ChatWorkspace(
                isActive: selectedTab == .chat,
                composerFocusRequest: composerFocusRequest,
                requestComposerFocus: requestComposerFocus,
                clearComposerFocusRequest: clearComposerFocusRequest
            )
        } models: {
            ModelLibraryView()
        } prompts: {
            PromptTemplatesWorkspace(openChat: openChatAndFocus)
        } settings: {
            SettingsWorkspace(
                themeMode: themeMode,
                wallpaperData: wallpaperImageData,
                toggleTheme: {
                    withAnimation(
                        AppMotionAccessibilityPolicy.animation(
                            .spring(response: 0.28, dampingFraction: 0.82),
                            for: .themeChange,
                            reduceMotion: reduceMotion
                        )
                    ) {
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

        return HStack(spacing: WorkbenchVisualStylePolicy.compactNavigationSpacing) {
            ForEach(WorkspaceTab.allCases) { tab in
                Button {
                    withAnimation(
                        AppMotionAccessibilityPolicy.animation(
                            .spring(response: 0.3, dampingFraction: 0.82),
                            for: .workspaceNavigation,
                            reduceMotion: reduceMotion
                        )
                    ) {
                        selectWorkspace(tab)
                    }
                } label: {
                    Label(tab.title, systemImage: tab.icon)
                        .font(.subheadline.weight(.semibold))
                        .labelStyle(.titleOnly)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .frame(minHeight: WorkspaceNavigationActionLayoutPolicy.compactTabMinHeight)
                        .background {
                            RoundedRectangle(
                                cornerRadius: WorkbenchVisualStylePolicy.controlCornerRadius,
                                style: .continuous
                            )
                            .fill(
                                selectedTab == tab
                                    ? theme.accent.opacity(
                                        WorkbenchVisualStylePolicy.selectedSurfaceOpacity(
                                            isDark: theme.isDark
                                        )
                                    )
                                    : Color.clear
                            )
                        }
                        .overlay(alignment: .bottom) {
                            if WorkbenchVisualStylePolicy.usesSelectionIndicator(
                                isSelected: selectedTab == tab
                            ) {
                                RoundedRectangle(cornerRadius: 1, style: .continuous)
                                    .fill(theme.accent)
                                    .frame(
                                        width: WorkbenchVisualStylePolicy.compactSelectionIndicatorWidth,
                                        height: WorkbenchVisualStylePolicy.compactSelectionIndicatorHeight
                                    )
                                    .padding(.bottom, 4)
                                    .accessibilityHidden(true)
                            }
                        }
                        .foregroundStyle(selectedTab == tab ? theme.primaryText : theme.secondaryText)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
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
        .padding(WorkbenchVisualStylePolicy.compactNavigationInset)
        .background {
            ZStack {
                RoundedRectangle(
                    cornerRadius: WorkbenchVisualStylePolicy.controlCornerRadius,
                    style: .continuous
                )
                .fill(theme.surface)
                RoundedRectangle(
                    cornerRadius: WorkbenchVisualStylePolicy.controlCornerRadius,
                    style: .continuous
                )
                .fill(
                    theme.recessedSurface.opacity(
                        WorkbenchVisualStylePolicy.sidebarTintOpacity(isDark: theme.isDark)
                    )
                )
            }
        }
        .overlay {
            RoundedRectangle(
                cornerRadius: WorkbenchVisualStylePolicy.controlCornerRadius,
                style: .continuous
            )
            .stroke(theme.border, lineWidth: WorkbenchVisualStylePolicy.hairlineWidth)
        }
    }

    private func sidebarTabPicker(isDetailed: Bool) -> some View {
        let theme = currentTheme

        return VStack(spacing: WorkbenchVisualStylePolicy.sidebarNavigationSpacing) {
            ForEach(WorkspaceTab.allCases) { tab in
                Button {
                    withAnimation(
                        AppMotionAccessibilityPolicy.animation(
                            .spring(response: 0.3, dampingFraction: 0.82),
                            for: .workspaceNavigation,
                            reduceMotion: reduceMotion
                        )
                    ) {
                        selectWorkspace(tab)
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: tab.icon)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(selectedTab == tab ? theme.accent : theme.tertiaryText)
                            .frame(
                                width: WorkbenchVisualStylePolicy.sidebarIconSize,
                                height: WorkbenchVisualStylePolicy.sidebarIconSize
                            )
                            .background(
                                selectedTab == tab
                                    ? theme.accent.opacity(
                                        WorkbenchVisualStylePolicy.selectedSurfaceOpacity(
                                            isDark: theme.isDark
                                        )
                                    )
                                    : theme.surface.opacity(
                                        WorkbenchVisualStylePolicy.unselectedIconSurfaceOpacity
                                    ),
                                in: RoundedRectangle(
                                    cornerRadius: WorkbenchVisualStylePolicy.iconCornerRadius,
                                    style: .continuous
                                )
                            )

                        VStack(alignment: .leading, spacing: isDetailed ? WorkspaceSidebarTextLayoutPolicy.titleSubtitleSpacing : 0) {
                            Text(tab.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(selectedTab == tab ? theme.primaryText : theme.secondaryText)
                                .lineLimit(WorkspaceSidebarTextLayoutPolicy.titleLineLimit)
                                .fixedSize(horizontal: false, vertical: true)
                            if isDetailed {
                                Text(tab.sidebarSubtitle)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(theme.secondaryText)
                                    .lineLimit(WorkspaceSidebarTextLayoutPolicy.subtitleLineLimit)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                        Spacer()
                        if selectedTab == tab {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(theme.accent)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 11)
                    .frame(
                        minHeight: WorkspaceNavigationActionLayoutPolicy.sidebarTabMinHeight,
                        alignment: .leading
                    )
                    .background(
                        selectedTab == tab
                            ? theme.accent.opacity(
                                WorkbenchVisualStylePolicy.selectedSurfaceOpacity(
                                    isDark: theme.isDark
                                )
                            )
                            : Color.clear,
                        in: RoundedRectangle(
                            cornerRadius: WorkbenchVisualStylePolicy.controlCornerRadius,
                            style: .continuous
                        )
                    )
                    .overlay {
                        RoundedRectangle(
                            cornerRadius: WorkbenchVisualStylePolicy.controlCornerRadius,
                            style: .continuous
                        )
                        .stroke(
                            selectedTab == tab
                                ? theme.accent.opacity(
                                    WorkbenchVisualStylePolicy.selectedBorderOpacity
                                )
                                : Color.clear,
                            lineWidth: WorkbenchVisualStylePolicy.hairlineWidth
                        )
                    }
                    .overlay(alignment: .leading) {
                        if WorkbenchVisualStylePolicy.usesSelectionIndicator(
                            isSelected: selectedTab == tab
                        ) {
                            RoundedRectangle(cornerRadius: 1, style: .continuous)
                                .fill(theme.accent)
                                .frame(width: WorkbenchVisualStylePolicy.sidebarSelectionIndicatorWidth)
                                .padding(
                                    .vertical,
                                    WorkbenchVisualStylePolicy.sidebarSelectionIndicatorVerticalInset
                                )
                                .accessibilityHidden(true)
                        }
                    }
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
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

enum SessionCommandFocusPolicy {
    static func focusedActions(
        isChatActive: Bool,
        actions: SessionCommandActions
    ) -> SessionCommandActions? {
        isChatActive ? actions : nil
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
        deploymentState: ModelDeploymentState,
        isGenerating: Bool,
        isSimulated: Bool
    ) -> String {
        [
            "\(model.name)，\(model.parameterCount)，\(model.quantization)",
            "安装状态 \(installStateDescription(model.installState))",
            runtimeModeDescription(isSimulated: isSimulated),
            artifactDescription(availability),
            ModelStatusBadgeAccessibilityMetadata.value(for: deploymentState),
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

enum ModelStatusBadgeColorRole: String, CaseIterable, Equatable {
    case primaryText
    case secondaryText
    case accent
    case success
    case warning
    case chipSurface
    case border
}

enum ModelStatusBadgeVisualState: Equatable {
    case install(ModelInstallState)
    case artifact(ArtifactAvailability)
    case deployment(ModelDeploymentState)
    case runtime(isSimulated: Bool)
}

enum ModelStatusBadgeAccessibilityScope: Equatable {
    case modelCapsule
    case modelSelector
}

enum ModelStatusBadgeAccessibilityPresentationPolicy {
    static func exposesIndependentBadge(
        for scope: ModelStatusBadgeAccessibilityScope
    ) -> Bool {
        switch scope {
        case .modelCapsule:
            return false
        case .modelSelector:
            return true
        }
    }
}

struct ModelStatusBadgeStyle: Equatable {
    let themeMode: AppThemeMode
    let foreground: ModelStatusBadgeColorRole
    let background: ModelStatusBadgeColorRole
    let border: ModelStatusBadgeColorRole
    let backgroundOpacity: Double
    let borderOpacity: Double

    func color(
        for role: ModelStatusBadgeColorRole,
        in theme: AppThemePalette
    ) -> Color {
        switch role {
        case .primaryText:
            return theme.primaryText
        case .secondaryText:
            return theme.secondaryText
        case .accent:
            return theme.accent
        case .success:
            return theme.success
        case .warning:
            return theme.warning
        case .chipSurface:
            return theme.chipSurface
        case .border:
            return theme.border
        }
    }

    func foregroundColor(in theme: AppThemePalette) -> Color {
        color(for: foreground, in: theme)
    }

    func backgroundColor(in theme: AppThemePalette) -> Color {
        color(for: background, in: theme).opacity(backgroundOpacity)
    }

    func borderColor(in theme: AppThemePalette) -> Color {
        color(for: border, in: theme).opacity(borderOpacity)
    }
}

enum ModelStatusBadgeStylePolicy {
    static func style(
        for state: ModelStatusBadgeVisualState,
        theme: AppThemeMode
    ) -> ModelStatusBadgeStyle {
        switch state {
        case .install(.ready), .artifact(.verified), .deployment(.running), .runtime(isSimulated: false):
            return semanticStyle(theme: theme, role: .success)
        case .install(.simulated), .artifact(.staged), .runtime(isSimulated: true):
            return semanticStyle(theme: theme, role: .accent)
        case .install(.notDownloaded), .artifact(.missing):
            return semanticStyle(theme: theme, role: .warning)
        case .deployment(.stopped):
            return ModelStatusBadgeStyle(
                themeMode: theme,
                foreground: .primaryText,
                background: .chipSurface,
                border: .border,
                backgroundOpacity: 1,
                borderOpacity: 1
            )
        }
    }

    private static func semanticStyle(
        theme: AppThemeMode,
        role: ModelStatusBadgeColorRole
    ) -> ModelStatusBadgeStyle {
        ModelStatusBadgeStyle(
            themeMode: theme,
            foreground: role,
            background: role,
            border: role,
            backgroundOpacity: 0.13,
            borderOpacity: 0.35
        )
    }
}

enum ModelStatusBadgeTextLayoutPolicy {
    static let lineLimit = 2
    static let lineSpacing: CGFloat = 1
    static let horizontalPadding: CGFloat = 6
    static let verticalPadding: CGFloat = 3

    static var font: Font {
        .caption2.weight(.semibold)
    }

    static var usesSemanticDynamicTypeFont: Bool { true }
    static var allowsMultiline: Bool { lineLimit > 1 }
}

enum ModelStatusBadgeRowLayoutMode: Equatable {
    case horizontal
    case stacked
}

struct ModelStatusBadgeRowLayoutPlan: Equatable {
    let mode: ModelStatusBadgeRowLayoutMode
}

enum ModelStatusBadgeRowLayoutPolicy {
    static let horizontalMinimumWidth: CGFloat = 220
    static let horizontalSpacing: CGFloat = 6
    static let stackedSpacing: CGFloat = 4

    static func resolve(
        availableWidth: CGFloat,
        dynamicTypeSize: DynamicTypeSize
    ) -> ModelStatusBadgeRowLayoutPlan {
        guard availableWidth.isFinite, availableWidth > 0 else {
            return ModelStatusBadgeRowLayoutPlan(mode: .stacked)
        }

        guard dynamicTypeSize < .xxxLarge else {
            return ModelStatusBadgeRowLayoutPlan(mode: .stacked)
        }

        return ModelStatusBadgeRowLayoutPlan(
            mode: availableWidth >= horizontalMinimumWidth ? .horizontal : .stacked
        )
    }
}

struct ModelStatusBadgeAppearanceModifier: ViewModifier {
    @Environment(\.appTheme) private var theme

    let style: ModelStatusBadgeStyle

    func body(content: Content) -> some View {
        content
            .font(ModelStatusBadgeTextLayoutPolicy.font)
            .textCase(.uppercase)
            .lineLimit(ModelStatusBadgeTextLayoutPolicy.lineLimit)
            .lineSpacing(ModelStatusBadgeTextLayoutPolicy.lineSpacing)
            .fixedSize(horizontal: false, vertical: true)
            .foregroundStyle(style.foregroundColor(in: theme))
            .padding(.horizontal, ModelStatusBadgeTextLayoutPolicy.horizontalPadding)
            .padding(.vertical, ModelStatusBadgeTextLayoutPolicy.verticalPadding)
            .background(style.backgroundColor(in: theme), in: Capsule())
            .overlay(
                Capsule().stroke(style.borderColor(in: theme), lineWidth: 1)
            )
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

enum ChatGenerationPlaceholderPresentation: Equatable {
    case active
    case completed
    case cancelled
}

enum ChatGenerationPlaceholderPresentationPolicy {
    static func resolve(
        message: ChatMessage,
        isGenerating: Bool,
        isLatestMessage: Bool = true
    ) -> ChatGenerationPlaceholderPresentation {
        let isEmpty = message.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        guard message.role == .assistant else {
            return .completed
        }

        guard isEmpty else {
            return .completed
        }

        return isGenerating && isLatestMessage ? .active : .cancelled
    }

    static func showsIndicator(
        for presentation: ChatGenerationPlaceholderPresentation
    ) -> Bool {
        presentation == .active
    }
}

enum ChatMessageAccessibilityMetadata {
    static let hint = "只展示本地会话内容；不会下载模型权重，不会启动真实 runtime，不会发送到云端服务，也不会绕过 artifact verified 门禁。"

    static func label(for message: ChatMessage) -> String {
        roleTitle(for: message.role)
    }

    static func value(for message: ChatMessage) -> String {
        value(for: message, placeholderPresentation: .active)
    }

    static func value(
        for message: ChatMessage,
        placeholderPresentation: ChatGenerationPlaceholderPresentation
    ) -> String {
        "\(spokenText(for: message, placeholderPresentation: placeholderPresentation))。\(message.tokens) tokens。本地会话消息。"
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
        spokenText(for: message, placeholderPresentation: .active)
    }

    static func spokenText(
        for message: ChatMessage,
        placeholderPresentation: ChatGenerationPlaceholderPresentation
    ) -> String {
        let trimmedText = message.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedText.isEmpty {
            switch message.role {
            case .assistant:
                switch placeholderPresentation {
                case .active:
                    return "正在生成，本地模型正在写入模拟输出"
                case .completed:
                    return "没有消息正文"
                case .cancelled:
                    return "已停止生成，未产生消息正文"
                }
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

enum ChatMessageCopyActionPolicy {
    static let minimumTouchTarget: CGFloat = 44
    static let actionButtonSize: CGFloat = 44

    static func payload(for message: ChatMessage, isGenerating: Bool) -> String? {
        guard !isGenerating else {
            return nil
        }
        guard !message.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        return message.text
    }

    static func canCopy(_ message: ChatMessage, isGenerating: Bool) -> Bool {
        payload(for: message, isGenerating: isGenerating) != nil
    }
}

enum ChatMessageCopyActionAccessibilityMetadata {
    static let label = "复制消息"
    static let hint = "将原始消息正文写入系统剪贴板；不会发送到云端服务，不会下载模型权重，不会启动真实 runtime，也不会绕过 artifact verified 门禁。"

    static func value(for message: ChatMessage, isGenerating: Bool, didCopy: Bool) -> String {
        guard ChatMessageCopyActionPolicy.canCopy(message, isGenerating: isGenerating) else {
            return isGenerating ? "生成中，不可复制" : "消息正文为空，不可复制"
        }
        return didCopy ? "已复制到系统剪贴板" : "可复制"
    }

    static func inputLabels(for message: ChatMessage) -> [String] {
        ["复制消息", "拷贝消息", "复制消息 \(identifierPrefix(for: message))"]
    }

    static func identifier(for message: ChatMessage) -> String {
        "chat-message-copy-\(identifierPrefix(for: message))"
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
        value(for: messages, isGenerating: true)
    }

    static func value(for messages: [ChatMessage], isGenerating: Bool) -> String {
        guard let latestMessage = messages.last else {
            return "空聊天记录，当前没有本地会话消息。"
        }

        let roleTitle = ChatMessageAccessibilityMetadata.roleTitle(for: latestMessage.role)
        let placeholderPresentation = ChatGenerationPlaceholderPresentationPolicy.resolve(
            message: latestMessage,
            isGenerating: isGenerating,
            isLatestMessage: true
        )
        let spokenText = ChatMessageAccessibilityMetadata.spokenText(
            for: latestMessage,
            placeholderPresentation: placeholderPresentation
        )
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

enum WorkspaceSidebarTextLayoutPolicy {
    static let titleSubtitleSpacing: CGFloat = 2
    static let titleLineLimit = 2
    static let subtitleLineLimit = 2

    static var allowsMultilineTitle: Bool { titleLineLimit > 1 }
    static var allowsMultilineSubtitle: Bool { subtitleLineLimit > 1 }
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

    static func shouldFocus(
        isChatActive: Bool,
        request: ComposerFocusRequest
    ) -> Bool {
        isChatActive && request.shouldFocus
    }

    static func shouldReleaseFocus(isChatActive: Bool) -> Bool {
        !isChatActive
    }
}

struct ComposerFocusLifecycleID: Equatable {
    let isChatActive: Bool
    let requestSequence: Int
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

enum ComposerInputTextLayoutPolicy {
    static let usesSemanticFont = true
    static let semanticFont = Font.subheadline.weight(.semibold)
    static let minimumLineCount = 1
    static let maximumLineCount = 4
    static let verticalPadding: CGFloat = 12
    static let lineSpacing: CGFloat = 0

    static var allowsMultiline: Bool {
        maximumLineCount > minimumLineCount
    }

    static let allowsNaturalVerticalGrowth = true
}

struct HeaderView: View {
    @Environment(\.appTheme) private var theme

    let model: LocalModel
    let readiness: Double
    let tokensPerSecond: Double
    let memoryUsageMB: Int
    let backend: ComputeBackend
    let availability: ArtifactAvailability
    let deploymentState: ModelDeploymentState
    let isGenerating: Bool
    let isSimulated: Bool
    let capsuleAvailableWidth: CGFloat
    let layoutMode: WorkspaceLayoutMode
    let themeMode: AppThemeMode
    let toggleTheme: () -> Void
    let showModels: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            WorkbenchBrandHeader(themeMode: themeMode, isSidebar: layoutMode.usesSidebar,
                                 toggleTheme: toggleTheme, showModels: showModels)
            if !layoutMode.usesSidebar {
                DisclosureGroup {
                    ModelCapsule(
                        model: model, readiness: readiness, tokensPerSecond: tokensPerSecond,
                        memoryUsageMB: memoryUsageMB, backend: backend, availability: availability,
                        deploymentState: deploymentState, isGenerating: isGenerating,
                        isSimulated: isSimulated, availableWidth: capsuleAvailableWidth,
                        layoutMode: layoutMode
                    )
                    .padding(.top, 8)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "cpu").foregroundStyle(theme.accent)
                        Text(model.name).foregroundStyle(theme.primaryText)
                        Spacer(minLength: 4)
                        Text(isSimulated ? "SIM" : "REAL")
                            .font(.caption.monospaced())
                            .foregroundStyle(theme.accent)
                    }
                    .font(.subheadline.weight(.medium))
                    .frame(minHeight: 44)
                }
                .tint(theme.secondaryText)
                .accessibilityLabel("当前模型，展开运行摘要")
            }
        }
    }
}

enum ModelCapsuleHeaderPresentation: Equatable {
    case horizontal
    case stacked
}

struct ModelCapsuleLayoutPlan: Equatable {
    let headerPresentation: ModelCapsuleHeaderPresentation
    let metricColumnCount: Int
}

enum ModelCapsuleLayoutPolicy {
    static let chromeHorizontalPadding: CGFloat = 18
    static let capsuleHorizontalPadding: CGFloat = 12
    static let metricSpacing: CGFloat = 8
    static let minimumMetricWidth: CGFloat = 108
    static let minimumThreeColumnMetricWidth: CGFloat = 132
    static let readinessDiameter: CGFloat = 54

    static var twoColumnMinimumWidth: CGFloat {
        capsuleHorizontalPadding * 2 + minimumMetricWidth * 2 + metricSpacing
    }

    static var threeColumnMinimumWidth: CGFloat {
        capsuleHorizontalPadding * 2 + minimumThreeColumnMetricWidth * 3 + metricSpacing * 2
    }

    static func availableWidth(forChromeWidth chromeWidth: CGFloat) -> CGFloat {
        guard chromeWidth.isFinite, chromeWidth > 0 else {
            return 0
        }

        return max(chromeWidth - chromeHorizontalPadding * 2, 0)
    }

    static func resolve(
        availableWidth: CGFloat,
        layoutMode: WorkspaceLayoutMode,
        usesExpandedTextLayout: Bool
    ) -> ModelCapsuleLayoutPlan {
        guard availableWidth.isFinite, availableWidth > 0, usesExpandedTextLayout == false else {
            return ModelCapsuleLayoutPlan(
                headerPresentation: .stacked,
                metricColumnCount: 1
            )
        }

        let maximumColumnCount = layoutMode == .portrait ? 3 : 2
        let fittedColumnCount: Int
        if availableWidth >= threeColumnMinimumWidth {
            fittedColumnCount = 3
        } else if availableWidth >= twoColumnMinimumWidth {
            fittedColumnCount = 2
        } else {
            fittedColumnCount = 1
        }

        return ModelCapsuleLayoutPlan(
            headerPresentation: layoutMode == .portrait && availableWidth >= threeColumnMinimumWidth
                ? .horizontal
                : .stacked,
            metricColumnCount: min(fittedColumnCount, maximumColumnCount)
        )
    }
}

enum ModelCapsuleTextLayoutPolicy {
    static let verticalSpacing: CGFloat = 11
    static let titleStatusSpacing: CGFloat = 4
    static let metricStackSpacing: CGFloat = 1
    static let nameLineLimit = 2
    static let statusLineLimit = 2
    static let metricTitleLineLimit = 1
    static let metricValueLineLimit = 2
    static let metricMinHeight: CGFloat = 36

    static var allowsMultilineName: Bool { nameLineLimit > 1 }
    static var allowsMultilineStatus: Bool { statusLineLimit > 1 }
    static var allowsMultilineMetricValue: Bool { metricValueLineLimit > 1 }
}

struct ModelCapsule: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let model: LocalModel
    let readiness: Double
    let tokensPerSecond: Double
    let memoryUsageMB: Int
    let backend: ComputeBackend
    let availability: ArtifactAvailability
    let deploymentState: ModelDeploymentState
    let isGenerating: Bool
    let isSimulated: Bool
    let availableWidth: CGFloat
    let layoutMode: WorkspaceLayoutMode

    var body: some View {
        let layoutPlan = ModelCapsuleLayoutPolicy.resolve(
            availableWidth: availableWidth,
            layoutMode: layoutMode,
            usesExpandedTextLayout: dynamicTypeSize >= .xxxLarge
        )

        VStack(alignment: .leading, spacing: ModelCapsuleTextLayoutPolicy.verticalSpacing) {
            capsuleHeader(layoutPlan)
            metricGrid(columnCount: layoutPlan.metricColumnCount)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(theme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
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
                deploymentState: deploymentState,
                isGenerating: isGenerating,
                isSimulated: isSimulated
            )
        )
        .accessibilityHint(ModelCapsuleAccessibilityMetadata.hint)
        .accessibilityInputLabels(ModelCapsuleAccessibilityMetadata.inputLabels(model: model))
        .accessibilityIdentifier(ModelCapsuleAccessibilityMetadata.identifier)
    }

    @ViewBuilder
    private func capsuleHeader(_ layoutPlan: ModelCapsuleLayoutPlan) -> some View {
        switch layoutPlan.headerPresentation {
        case .horizontal:
            HStack(spacing: 12) {
                modelIcon
                VStack(alignment: .leading, spacing: ModelCapsuleTextLayoutPolicy.titleStatusSpacing) {
                    HStack(spacing: 6) {
                        modelName
                        modelBadges(layoutMode: badgeRowLayoutMode)
                    }
                    modelStatus
                }
                Spacer(minLength: 0)
                readinessRing
            }
        case .stacked:
            VStack(alignment: .leading, spacing: ModelCapsuleTextLayoutPolicy.titleStatusSpacing) {
                HStack(spacing: 12) {
                    modelIcon
                    modelName
                    Spacer(minLength: 0)
                }
                HStack(spacing: 8) {
                    modelBadges(layoutMode: badgeRowLayoutMode)
                    Spacer(minLength: 0)
                    readinessRing
                }
                modelStatus
            }
        }
    }

    private var badgeRowLayoutMode: ModelStatusBadgeRowLayoutMode {
        let badgeContentWidth = max(
            availableWidth
                - ModelCapsuleLayoutPolicy.capsuleHorizontalPadding * 2
                - ModelCapsuleLayoutPolicy.readinessDiameter
                - 8,
            0
        )
        return ModelStatusBadgeRowLayoutPolicy.resolve(
            availableWidth: badgeContentWidth,
            dynamicTypeSize: dynamicTypeSize
        ).mode
    }

    @ViewBuilder
    private func metricGrid(columnCount: Int) -> some View {
        switch columnCount {
        case 3:
            HStack(spacing: ModelCapsuleLayoutPolicy.metricSpacing) {
                speedMetric
                memoryMetric
                availabilityMetric
            }
        case 2:
            Grid(
                horizontalSpacing: ModelCapsuleLayoutPolicy.metricSpacing,
                verticalSpacing: ModelCapsuleLayoutPolicy.metricSpacing
            ) {
                GridRow {
                    speedMetric
                    memoryMetric
                }
                GridRow {
                    availabilityMetric
                        .gridCellColumns(2)
                }
            }
        default:
            VStack(spacing: ModelCapsuleLayoutPolicy.metricSpacing) {
                speedMetric
                memoryMetric
                availabilityMetric
            }
        }
    }

    private var modelIcon: some View {
        ZStack {
            Circle()
                .fill(theme.accent.opacity(0.18))
            Image(systemName: "bolt.horizontal.circle.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(theme.accent)
        }
        .frame(width: 42, height: 42)
        .accessibilityHidden(true)
    }

    private var modelName: some View {
        Text(model.name)
            .font(.subheadline.weight(.bold))
            .foregroundStyle(theme.primaryText)
            .lineLimit(ModelCapsuleTextLayoutPolicy.nameLineLimit)
            .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private func modelBadges(layoutMode: ModelStatusBadgeRowLayoutMode) -> some View {
        let layout = layoutMode == .horizontal
            ? AnyLayout(HStackLayout(spacing: ModelStatusBadgeRowLayoutPolicy.horizontalSpacing))
            : AnyLayout(
                VStackLayout(
                    alignment: .leading,
                    spacing: ModelStatusBadgeRowLayoutPolicy.stackedSpacing
                )
            )

        layout {
            StatusBadge(state: model.installState)
            DeploymentBadge(
                state: deploymentState,
                exposesAccessibility: ModelStatusBadgeAccessibilityPresentationPolicy
                    .exposesIndependentBadge(for: .modelCapsule)
            )
            Text(isSimulated ? "SIM" : "REAL")
                .modifier(
                    ModelStatusBadgeAppearanceModifier(
                        style: ModelStatusBadgeStylePolicy.style(
                            for: .runtime(isSimulated: isSimulated),
                            theme: theme.mode
                        )
                    )
                )
        }
    }

    private var modelStatus: some View {
        Text(statusText)
            .font(.footnote.weight(.medium))
            .foregroundStyle(theme.secondaryText)
            .lineLimit(ModelCapsuleTextLayoutPolicy.statusLineLimit)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var readinessRing: some View {
        ReadinessRing(
            progress: readiness,
            diameter: ModelCapsuleLayoutPolicy.readinessDiameter
        )
    }

    private var speedMetric: some View {
        HeaderMetricChip(
            title: "速度",
            value: String(format: "%.1f tok/s", tokensPerSecond),
            icon: "speedometer",
            tint: theme.accent
        )
    }

    private var memoryMetric: some View {
        HeaderMetricChip(
            title: "内存",
            value: compactMemoryValue,
            icon: "memorychip.fill",
            tint: theme.success
        )
    }

    private var availabilityMetric: some View {
        HeaderMetricChip(
            title: backend.shortTitle,
            value: availabilityMetricValue,
            icon: availabilityIcon,
            tint: statusTint
        )
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
                .font(.caption.weight(.semibold))
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: ModelCapsuleTextLayoutPolicy.metricStackSpacing) {
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(theme.tertiaryText)
                    .lineLimit(ModelCapsuleTextLayoutPolicy.metricTitleLineLimit)
                Text(value)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(theme.primaryText)
                    .lineLimit(ModelCapsuleTextLayoutPolicy.metricValueLineLimit)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: ModelCapsuleTextLayoutPolicy.metricMinHeight)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(theme.recessedSurface, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
    }
}

struct StatusBadge: View {
    @Environment(\.appTheme) private var theme

    let state: ModelInstallState
    var exposesAccessibility: Bool = false

    var body: some View {
        Text(state.title)
            .modifier(
                ModelStatusBadgeAppearanceModifier(
                    style: ModelStatusBadgeStylePolicy.style(
                        for: .install(state),
                        theme: theme.mode
                    )
                )
            )
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

struct ArtifactStatusBadgeAccessibilityModifier: ViewModifier {
    let availability: ArtifactAvailability
    let isEnabled: Bool

    func body(content: Content) -> some View {
        if isEnabled {
            content
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(ModelStatusBadgeAccessibilityMetadata.label(for: availability))
                .accessibilityValue(ModelStatusBadgeAccessibilityMetadata.value(for: availability))
                .accessibilityHint(ModelStatusBadgeAccessibilityMetadata.hint)
                .accessibilityInputLabels(ModelStatusBadgeAccessibilityMetadata.inputLabels(for: availability))
                .accessibilityIdentifier(ModelStatusBadgeAccessibilityMetadata.identifier(for: availability))
        } else {
            content.accessibilityHidden(true)
        }
    }
}

struct DeploymentStatusBadgeAccessibilityModifier: ViewModifier {
    let state: ModelDeploymentState
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
    let diameter: CGFloat
    let accessibilityIdentifier: String

    init(
        progress: Double,
        diameter: CGFloat = 66,
        accessibilityIdentifier: String = ChipReadinessAccessibilityMetadata.headerRingIdentifier
    ) {
        self.progress = progress
        self.diameter = diameter
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
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.primaryText)
                Text("READY")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(theme.secondaryText)
            }
        }
        .frame(width: diameter, height: diameter)
        .accessibilityLabel(ChipReadinessAccessibilityMetadata.ringLabel)
        .accessibilityValue(ChipReadinessAccessibilityMetadata.ringValue(progress: progress))
        .accessibilityHint(ChipReadinessAccessibilityMetadata.ringHint)
        .accessibilityInputLabels(ChipReadinessAccessibilityMetadata.ringInputLabels)
        .accessibilityIdentifier(accessibilityIdentifier)
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
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.accent)
                .tracking(SectionHeaderTextLayoutPolicy.eyebrowTracking)
                .lineLimit(SectionHeaderTextLayoutPolicy.eyebrowLineLimit)
            Text(title)
                .font(.largeTitle.weight(.semibold))
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
        .padding(.bottom, 8)
        .accessibilityAddTraits(.isHeader)
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
