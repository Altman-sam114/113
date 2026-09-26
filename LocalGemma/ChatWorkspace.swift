import Foundation
import PhotosUI
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct ChatWorkspace: View {
    @EnvironmentObject private var catalog: ModelCatalog
    @EnvironmentObject private var inference: InferenceEngine
    @Environment(\.appTheme) private var theme
    @State private var exportPayload: ExportPayload?

    let isActive: Bool
    let composerFocusRequest: ComposerFocusRequest
    let requestComposerFocus: (ComposerFocusReason) -> Void
    let clearComposerFocusRequest: () -> Void

    init(
        isActive: Bool = true,
        composerFocusRequest: ComposerFocusRequest = .initial,
        requestComposerFocus: @escaping (ComposerFocusReason) -> Void = { _ in },
        clearComposerFocusRequest: @escaping () -> Void = {}
    ) {
        self.isActive = isActive
        self.composerFocusRequest = composerFocusRequest
        self.requestComposerFocus = requestComposerFocus
        self.clearComposerFocusRequest = clearComposerFocusRequest
    }

    var body: some View {
        GeometryReader { proxy in
            let paneLayout = ChatWorkspacePaneLayoutPolicy.resolve(for: proxy.size)
            let usesSessionSidebar = paneLayout.mode == .split
            let workspaceLayout = usesSessionSidebar
                ? AnyLayout(HStackLayout(spacing: 0))
                : AnyLayout(VStackLayout(spacing: 10))

            workspaceLayout {
                SessionBar(
                    sessions: inference.sessions,
                    activeSessionID: inference.activeSessionID,
                    layout: usesSessionSidebar ? .vertical : .horizontal,
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
                .padding(.horizontal, usesSessionSidebar ? 14 : 18)
                .padding(.vertical, usesSessionSidebar ? 14 : 0)
                .padding(.top, usesSessionSidebar ? 0 : 12)
                .frame(width: usesSessionSidebar ? paneLayout.sessionSidebarWidth : nil)
                .background {
                    if usesSessionSidebar {
                        Rectangle().fill(theme.surface)
                    }
                }
                .overlay(alignment: .trailing) {
                    if usesSessionSidebar {
                        Rectangle()
                            .fill(theme.border)
                            .frame(width: WorkbenchVisualStylePolicy.hairlineWidth)
                    }
                }

                chatSurface
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .sheet(item: $exportPayload) { payload in
            ExportSessionView(payload: payload)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .modifier(
            SessionCommandFocusModifier(
                route: SessionCommandFocusedRoute(
                    actions: SessionCommandFocusPolicy.focusedActions(
                        isChatActive: isActive,
                        actions: sessionCommandActions
                    )
                )
            )
        )
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

        return VStack(spacing: 0) {
            ChatWorkspaceHeading(title: inference.activeSessionTitle)
            ChatTranscript(
                messages: inference.messages,
                isGenerating: inference.isGenerating,
                applyStarter: { template in
                    inference.applyTemplate(template)
                    requestComposerFocus(.applyTemplate)
                }
            )

            ComposerBar(
                text: $inference.inputText,
                isGenerating: inference.isGenerating,
                isChatActive: isActive,
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
            .padding(.top, 12)
            .padding(.bottom, 8)
            Label("模拟预览 · 内容在本机生成", systemImage: "lock")
                .font(.caption)
                .foregroundStyle(theme.secondaryText)
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

struct SessionCommandFocusModifier: ViewModifier {
    let route: SessionCommandFocusedRoute

    func body(content: Content) -> some View {
        content.focusedSceneValue(\.sessionCommandFocusedRoute, route)
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

struct SessionChipSidebarMetadataPlan: Equatable {
    enum Presentation: Equatable {
        case hidden
        case vertical
    }

    let presentation: Presentation
    let messageCount: Int
    let previewText: String?

    var isVisible: Bool {
        presentation == .vertical
    }

    var metadataText: String? {
        guard isVisible else {
            return nil
        }

        let countText = "\(messageCount) 条消息"
        guard let previewText, !previewText.isEmpty else {
            return countText
        }
        return "\(countText) · \(previewText)"
    }
}

enum SessionChipSidebarMetadataPolicy {
    static let maximumPreviewCharacters = 40
    private static let truncationSuffix = "..."

    static func resolve(
        session: ChatSession,
        layout: SessionBarLayout
    ) -> SessionChipSidebarMetadataPlan {
        guard layout == .vertical else {
            return SessionChipSidebarMetadataPlan(
                presentation: .hidden,
                messageCount: 0,
                previewText: nil
            )
        }

        var previewText: String?
        for message in session.messages.reversed() {
            guard let normalizedText = normalizedText(from: message.text) else {
                continue
            }
            previewText = truncatedPreview(normalizedText)
            break
        }

        return SessionChipSidebarMetadataPlan(
            presentation: .vertical,
            messageCount: session.messages.count,
            previewText: previewText
        )
    }

    private static func normalizedText(from text: String) -> String? {
        var normalized = ""
        var hasPendingWhitespace = false

        for character in text {
            if character.isWhitespace {
                hasPendingWhitespace = !normalized.isEmpty
                continue
            }

            if hasPendingWhitespace {
                normalized.append(" ")
            }
            normalized.append(character)
            hasPendingWhitespace = false
        }

        return normalized.isEmpty ? nil : normalized
    }

    private static func truncatedPreview(_ text: String) -> String {
        guard text.count > maximumPreviewCharacters else {
            return text
        }

        return String(text.prefix(maximumPreviewCharacters - truncationSuffix.count))
            + truncationSuffix
    }
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
                Label("会话记录", systemImage: "clock.arrow.circlepath")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(theme.primaryText)

                Spacer(minLength: 0)

                Button(action: export) {
                    Label(
                        SessionBarActionAccessibilityMetadata.label(for: .exportSession),
                        systemImage: "square.and.arrow.up.fill"
                    )
                        .labelStyle(.iconOnly)
                        .font(.system(size: 13, weight: .semibold))
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
                        .font(.system(size: 13, weight: .semibold))
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

enum SessionChipTextLayoutPolicy {
    static let titleLineLimit = 2

    static var allowsMultilineTitle: Bool { titleLineLimit > 1 }
}

struct SessionChipVisualStylePlan: Equatable {
    let usesSidebarRowShape: Bool
    let usesMutedSelectionSurface: Bool
    let usesInverseForeground: Bool
    let showsSelectionIndicator: Bool
}

enum SessionChipVisualStylePolicy {
    static let sidebarCornerRadius: CGFloat = WorkbenchVisualStylePolicy.controlCornerRadius
    static let selectionIndicatorWidth: CGFloat =
        WorkbenchVisualStylePolicy.sidebarSelectionIndicatorWidth
    static let selectionIndicatorVerticalInset: CGFloat =
        WorkbenchVisualStylePolicy.sidebarSelectionIndicatorVerticalInset
    static let borderWidth: CGFloat = WorkbenchVisualStylePolicy.hairlineWidth
    static let unselectedSidebarSurfaceOpacity = 0.34

    static func resolve(
        layout: SessionBarLayout,
        isSelected: Bool
    ) -> SessionChipVisualStylePlan {
        let usesSidebarRowShape = layout == .vertical
        return SessionChipVisualStylePlan(
            usesSidebarRowShape: usesSidebarRowShape,
            usesMutedSelectionSurface: usesSidebarRowShape && isSelected,
            usesInverseForeground: usesSidebarRowShape == false && isSelected,
            showsSelectionIndicator: usesSidebarRowShape && isSelected
        )
    }
}

enum SessionChipHoverStylePolicy {
    static let lightHoverSurfaceOpacity = 0.06
    static let darkHoverSurfaceOpacity = 0.10

    static func usesHoverSurface(
        layout: SessionBarLayout,
        isSelected: Bool,
        isHovered: Bool
    ) -> Bool {
        layout == .vertical && isSelected == false && isHovered
    }

    static func hoverSurfaceOpacity(isDark: Bool) -> Double {
        isDark ? darkHoverSurfaceOpacity : lightHoverSurfaceOpacity
    }
}

struct SessionChip: View {
    @Environment(\.appTheme) private var theme

    @State private var isHovered: Bool

    let session: ChatSession
    let isActive: Bool
    var layout: SessionBarLayout = .horizontal
    let select: () -> Void
    let delete: () -> Void

    init(
        session: ChatSession,
        isActive: Bool,
        layout: SessionBarLayout = .horizontal,
        select: @escaping () -> Void,
        delete: @escaping () -> Void,
        initialHoverState: Bool = false
    ) {
        self.session = session
        self.isActive = isActive
        self.layout = layout
        self.select = select
        self.delete = delete
        _isHovered = State(initialValue: initialHoverState)
    }

    var body: some View {
        let visualStyle = SessionChipVisualStylePolicy.resolve(
            layout: layout,
            isSelected: isActive
        )
        let metadataPlan = SessionChipSidebarMetadataPolicy.resolve(
            session: session,
            layout: layout
        )

        HStack(spacing: 8) {
            Button(action: select) {
                HStack(alignment: .top, spacing: 7) {
                    Image(systemName: isActive ? "message.fill" : "message")
                        .font(.system(size: 11, weight: .bold))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(session.title)
                            .font(.footnote.weight(.semibold))
                            .lineLimit(SessionChipTextLayoutPolicy.titleLineLimit)
                            .fixedSize(horizontal: false, vertical: true)

                        if let metadataText = metadataPlan.metadataText {
                            Text(metadataText)
                                .font(.caption2)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                                .foregroundStyle(theme.secondaryText)
                        }
                    }

                    if layout == .vertical {
                        Spacer(minLength: 0)
                    }
                }
                .frame(
                    maxWidth: layout == .vertical ? .infinity : 160,
                    minHeight: SessionChipActionLayoutPolicy.selectButtonMinHeight,
                    alignment: .leading
                )
                .foregroundStyle(
                    visualStyle.usesInverseForeground
                        ? theme.inverseText
                        : theme.primaryText
                )
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
                    .foregroundStyle(
                        visualStyle.usesInverseForeground
                            ? theme.inverseText.opacity(0.82)
                            : theme.warning
                    )
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
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .background {
            if visualStyle.usesSidebarRowShape {
                RoundedRectangle(
                    cornerRadius: SessionChipVisualStylePolicy.sidebarCornerRadius,
                    style: .continuous
                )
                .fill(
                    visualStyle.usesMutedSelectionSurface
                        ? theme.accent.opacity(
                            WorkbenchVisualStylePolicy.selectedSurfaceOpacity(
                                isDark: theme.isDark
                            )
                        )
                        : theme.chipSurface.opacity(
                            SessionChipVisualStylePolicy.unselectedSidebarSurfaceOpacity
                        )
                )
                .overlay {
                    if SessionChipHoverStylePolicy.usesHoverSurface(
                        layout: layout,
                        isSelected: isActive,
                        isHovered: isHovered
                    ) {
                        RoundedRectangle(
                            cornerRadius: SessionChipVisualStylePolicy.sidebarCornerRadius,
                            style: .continuous
                        )
                        .fill(
                            theme.accent.opacity(
                                SessionChipHoverStylePolicy.hoverSurfaceOpacity(
                                    isDark: theme.isDark
                                )
                            )
                        )
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                    }
                }
            } else {
                Capsule()
                    .fill(isActive ? theme.accent : theme.chipSurface)
            }
        }
        .overlay {
            if visualStyle.usesSidebarRowShape {
                RoundedRectangle(
                    cornerRadius: SessionChipVisualStylePolicy.sidebarCornerRadius,
                    style: .continuous
                )
                .stroke(
                    isActive
                        ? theme.accent.opacity(
                            WorkbenchVisualStylePolicy.selectedBorderOpacity
                        )
                        : theme.border.opacity(0.7),
                    lineWidth: SessionChipVisualStylePolicy.borderWidth
                )
            } else {
                Capsule()
                    .stroke(
                        isActive ? theme.accent.opacity(0.7) : theme.border,
                        lineWidth: SessionChipVisualStylePolicy.borderWidth
                    )
            }
        }
        .overlay(alignment: .leading) {
            if visualStyle.showsSelectionIndicator {
                RoundedRectangle(cornerRadius: 1, style: .continuous)
                    .fill(theme.accent)
                    .frame(width: SessionChipVisualStylePolicy.selectionIndicatorWidth)
                    .padding(
                        .vertical,
                        SessionChipVisualStylePolicy.selectionIndicatorVerticalInset
                    )
                    .accessibilityHidden(true)
            }
        }
    }

    private var canDelete: Bool {
        SessionChipActionAccessibilityMetadata.canDelete(session: session, isActive: isActive)
    }
}

struct ChatTranscript: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let messages: [ChatMessage]
    let isGenerating: Bool
    var applyStarter: ((PresetPromptTemplate) -> Void)? = nil

    var body: some View {
        GeometryReader { geometry in
            let trackWidth = ChatTranscriptTrackLayoutPolicy.contentWidth(
                forContainerWidth: geometry.size.width
            )
            let verticalLayout = ChatTranscriptVerticalLayoutPolicy.resolve(
                viewportHeight: geometry.size.height,
                messageCount: messages.count
            )

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if let applyStarter,
                           WorkbenchPresentationPolicy.showsWelcome(messages: messages, isGenerating: isGenerating) {
                            ChatWelcomeView(availableWidth: trackWidth, apply: applyStarter)
                        }

                        ForEach(messages) { message in
                            ChatBubble(
                                message: message,
                                availableWidth: trackWidth,
                                isGenerating: isGenerating
                                    && message.id == messages.last?.id
                                    && message.role == .assistant
                            )
                            .id(message.id)
                        }
                    }
                    .frame(width: trackWidth)
                    .frame(
                        minHeight: verticalLayout.minimumContentHeight,
                        alignment: verticalLayout.anchorsContentToBottom ? .bottom : .top
                    )
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, ChatTranscriptVerticalLayoutPolicy.verticalPadding)
                }
                .scrollIndicators(.hidden)
                .accessibilityElement(children: .contain)
                .accessibilityLabel(ChatTranscriptAccessibilityMetadata.label)
                .accessibilityValue(
                    ChatTranscriptAccessibilityMetadata.value(
                        for: messages,
                        isGenerating: isGenerating
                    )
                )
                .accessibilityHint(ChatTranscriptAccessibilityMetadata.hint)
                .accessibilityInputLabels(ChatTranscriptAccessibilityMetadata.inputLabels)
                .accessibilityIdentifier(ChatTranscriptAccessibilityMetadata.identifier)
                .onChange(of: messages) { _, messages in
                    guard let last = messages.last else { return }
                    withAnimation(
                        AppMotionAccessibilityPolicy.animation(
                            .easeOut(duration: 0.22),
                            for: .transcriptAutoScroll,
                            reduceMotion: reduceMotion
                        )
                    ) {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }
}

enum ExportSessionTitleTextLayoutPolicy {
    static let verticalSpacing: CGFloat = 4
    static let titleLineLimit = 2
    static let metaLineLimit = 2

    static var allowsMultilineTitle: Bool { titleLineLimit > 1 }
    static var allowsMultilineMeta: Bool { metaLineLimit > 1 }
}

enum ExportSessionBodyTextLayoutPolicy {
    static let contentPadding: CGFloat = 18
    static let bodyLineSpacing: CGFloat = 3
    static let preservesFullText = true

    static var usesSemanticMonospacedFont: Bool {
        true
    }
}

struct ExportSessionView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
                            .font(.body.monospaced())
                            .foregroundStyle(theme.primaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                            .lineSpacing(ExportSessionBodyTextLayoutPolicy.bodyLineSpacing)
                            .padding(ExportSessionBodyTextLayoutPolicy.contentPadding)
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
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(theme.accent)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: ExportSessionTitleTextLayoutPolicy.verticalSpacing) {
                Text(payload.title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(theme.primaryText)
                    .lineLimit(ExportSessionTitleTextLayoutPolicy.titleLineLimit)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\(payload.messageCount) 条消息 · Markdown")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(theme.secondaryText)
                    .lineLimit(ExportSessionTitleTextLayoutPolicy.metaLineLimit)
                    .fixedSize(horizontal: false, vertical: true)
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
                        .font(.system(size: 15, weight: .semibold))
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
                        .font(.system(size: 15, weight: .semibold))
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
                withAnimation(
                    AppMotionAccessibilityPolicy.animation(
                        .spring(response: 0.26, dampingFraction: 0.82),
                        for: .copyConfirmation,
                        reduceMotion: reduceMotion
                    )
                ) {
                    didCopyText = true
                }
            } label: {
                Label(didCopyText ? "已复制" : "复制全文", systemImage: didCopyText ? "checkmark.circle.fill" : "doc.on.doc.fill")
                    .font(.system(size: 13, weight: .semibold))
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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var didCopy = false
    let message: ChatMessage
    let availableWidth: CGFloat
    let isGenerating: Bool

    var body: some View {
        let textLayoutPlan = ChatBubbleTextLayoutPolicy.resolve(dynamicTypeSize: dynamicTypeSize)
        let placeholderPresentation = ChatGenerationPlaceholderPresentationPolicy.resolve(
            message: message,
            isGenerating: isGenerating
        )

        HStack(alignment: .bottom, spacing: textLayoutPlan.horizontalSpacing) {
            if message.role == .user {
                Spacer(
                    minLength: ChatBubbleLayoutPolicy.horizontalReserve(
                        for: message.role,
                        usesExpandedTextLayout: textLayoutPlan.usesExpandedWidth
                    )
                )
            }

            VStack(alignment: bubbleAlignment, spacing: 6) {
                VStack(alignment: bubbleAlignment, spacing: 6) {
                    Text(roleTitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(roleTint.opacity(0.82))
                        .lineLimit(textLayoutPlan.roleLineLimit)
                        .fixedSize(horizontal: false, vertical: true)

                    if message.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        if ChatGenerationPlaceholderPresentationPolicy.showsIndicator(
                            for: placeholderPresentation
                        ) {
                            GenerationIndicatorView(reduceMotion: reduceMotion)
                        }
                    } else {
                        Text(message.text)
                            .font(.body.weight(.medium))
                            .lineSpacing(ChatBubbleTextLayoutPolicy.bodyLineSpacing)
                            .foregroundStyle(message.role == .system ? theme.secondaryText : theme.primaryText)
                            .fixedSize(horizontal: false, vertical: true)
                            .textSelection(.enabled)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(ChatMessageAccessibilityMetadata.label(for: message))
                .accessibilityValue(
                    ChatMessageAccessibilityMetadata.value(
                        for: message,
                        placeholderPresentation: placeholderPresentation
                    )
                )
                .accessibilityHint(ChatMessageAccessibilityMetadata.hint)
                .accessibilityInputLabels(ChatMessageAccessibilityMetadata.inputLabels(for: message))
                .accessibilityIdentifier(ChatMessageAccessibilityMetadata.identifier(for: message))

                HStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "number")
                            .font(.caption.weight(.bold))
                        Text("\(message.tokens) tokens")
                            .font(.caption.weight(.semibold))
                            .lineLimit(textLayoutPlan.metadataLineLimit)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .foregroundStyle(theme.tertiaryText)
                    .accessibilityHidden(true)

                    Button {
                        guard let payload = ChatMessageCopyActionPolicy.payload(
                            for: message,
                            isGenerating: isGenerating
                        ) else {
                            return
                        }
                        UIPasteboard.general.string = payload
                        withAnimation(
                            AppMotionAccessibilityPolicy.animation(
                                .spring(response: 0.26, dampingFraction: 0.82),
                                for: .copyConfirmation,
                                reduceMotion: reduceMotion
                            )
                        ) {
                            didCopy = true
                        }
                    } label: {
                        Image(systemName: didCopy ? "checkmark" : "doc.on.doc")
                            .font(.body.weight(.semibold))
                            .frame(
                                width: ChatMessageCopyActionPolicy.actionButtonSize,
                                height: ChatMessageCopyActionPolicy.actionButtonSize
                            )
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(didCopy ? theme.success : theme.secondaryText)
                    .disabled(
                        !ChatMessageCopyActionPolicy.canCopy(
                            message,
                            isGenerating: isGenerating
                        )
                    )
                    .help("复制消息")
                    .accessibilityLabel(ChatMessageCopyActionAccessibilityMetadata.label)
                    .accessibilityValue(
                        ChatMessageCopyActionAccessibilityMetadata.value(
                            for: message,
                            isGenerating: isGenerating,
                            didCopy: didCopy
                        )
                    )
                    .accessibilityHint(ChatMessageCopyActionAccessibilityMetadata.hint)
                    .accessibilityInputLabels(
                        ChatMessageCopyActionAccessibilityMetadata.inputLabels(for: message)
                    )
                    .accessibilityIdentifier(
                        ChatMessageCopyActionAccessibilityMetadata.identifier(for: message)
                    )
                }
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
                    availableWidth: availableWidth,
                    usesExpandedTextLayout: textLayoutPlan.usesExpandedWidth
                ),
                alignment: message.role == .user ? .trailing : .leading
            )

            if message.role != .user {
                Spacer(
                    minLength: ChatBubbleLayoutPolicy.horizontalReserve(
                        for: message.role,
                        usesExpandedTextLayout: textLayoutPlan.usesExpandedWidth
                    )
                )
            }
        }
        .accessibilityElement(children: .contain)
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

private struct GenerationIndicatorView: View {
    @Environment(\.appTheme) private var theme
    let reduceMotion: Bool
    @State private var isPulsing = false

    var body: some View {
        HStack(alignment: .center, spacing: GenerationIndicatorStylePolicy.dotSpacing) {
            Text("正在生成")
                .font(.body.weight(.medium))
                .foregroundStyle(theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(0..<GenerationIndicatorStylePolicy.dotCount, id: \.self) { index in
                Circle()
                    .fill(theme.accent)
                    .frame(
                        width: GenerationIndicatorStylePolicy.dotDiameter,
                        height: GenerationIndicatorStylePolicy.dotDiameter
                    )
                    .opacity(dotOpacity(forDotIndex: index))
                    .animation(dotAnimation(forDotIndex: index), value: isPulsing)
            }
        }
        .task(id: reduceMotion) {
            isPulsing = false
            guard GenerationIndicatorStylePolicy.isAnimated(reduceMotion: reduceMotion) else {
                return
            }
            await Task.yield()
            guard !Task.isCancelled else {
                return
            }
            isPulsing = true
        }
    }

    private func dotOpacity(forDotIndex index: Int) -> Double {
        guard GenerationIndicatorStylePolicy.isAnimated(reduceMotion: reduceMotion) else {
            return GenerationIndicatorStylePolicy.staticOpacity(forDotIndex: index)
        }
        return isPulsing
            ? GenerationIndicatorStylePolicy.maxOpacity
            : GenerationIndicatorStylePolicy.minOpacity
    }

    private func dotAnimation(forDotIndex index: Int) -> Animation? {
        guard GenerationIndicatorStylePolicy.isAnimated(reduceMotion: reduceMotion) else {
            return nil
        }
        return .easeInOut(duration: GenerationIndicatorStylePolicy.pulseDuration)
            .repeatForever(autoreverses: true)
            .delay(GenerationIndicatorStylePolicy.phaseDelay * Double(index))
    }
}

enum GenerationIndicatorStylePolicy {
    static let dotCount = 3
    static let dotDiameter: CGFloat = 5
    static let dotSpacing: CGFloat = 4
    static let minOpacity = 0.35
    static let maxOpacity = 1.0
    static let pulseDuration = 0.9
    static let phaseDelay = 0.15

    private static let staticOpacityGradient: [Double] = [0.35, 0.65, 1.0]

    static func isAnimated(reduceMotion: Bool) -> Bool {
        reduceMotion == false
    }

    static func staticOpacity(forDotIndex index: Int) -> Double {
        let clampedIndex = min(max(index, 0), staticOpacityGradient.count - 1)
        return staticOpacityGradient[clampedIndex]
    }
}

struct ChatBubbleTextLayoutPlan: Equatable {
    let usesExpandedWidth: Bool
    let horizontalSpacing: CGFloat
    let roleLineLimit: Int
    let metadataLineLimit: Int
}

enum ChatBubbleTextLayoutPolicy {
    static let regularHorizontalSpacing: CGFloat = 8
    static let roleLineLimit = 2
    static let metadataLineLimit = 2
    static let bodyLineSpacing: CGFloat = 4

    static func resolve(dynamicTypeSize: DynamicTypeSize) -> ChatBubbleTextLayoutPlan {
        let usesExpandedWidth = dynamicTypeSize >= .accessibility1
        return ChatBubbleTextLayoutPlan(
            usesExpandedWidth: usesExpandedWidth,
            horizontalSpacing: usesExpandedWidth ? 0 : regularHorizontalSpacing,
            roleLineLimit: roleLineLimit,
            metadataLineLimit: metadataLineLimit
        )
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

    static let userHorizontalReserve: CGFloat = 40
    static let assistantHorizontalReserve: CGFloat = 24

    static func contentWidth(forTranscriptWidth transcriptWidth: CGFloat) -> CGFloat {
        ChatTranscriptTrackLayoutPolicy.contentWidth(forContainerWidth: transcriptWidth)
    }

    static func maxWidth(
        for role: ChatMessage.Role,
        availableWidth: CGFloat,
        usesExpandedTextLayout: Bool = false
    ) -> CGFloat {
        let reserve = horizontalReserve(
            for: role,
            usesExpandedTextLayout: usesExpandedTextLayout
        )
        let validAvailableWidth = availableWidth.isFinite && availableWidth > 0
            ? availableWidth
            : minimumReadableWidth + reserve
        let effectiveAvailableWidth = max(validAvailableWidth, minimumReadableWidth + reserve)
        let usableWidth = max(minimumReadableWidth, effectiveAvailableWidth - reserve)
        let preferredWidth = usesExpandedTextLayout
            ? usableWidth
            : max(minimumReadableWidth, effectiveAvailableWidth * widthRatio(for: role))
        let unclampedWidth = usesExpandedTextLayout
            ? preferredWidth
            : max(compactUserWidth, preferredWidth)

        return min(usableWidth, min(maximumWidth(for: role), unclampedWidth))
    }

    static func horizontalReserve(
        for role: ChatMessage.Role,
        usesExpandedTextLayout: Bool
    ) -> CGFloat {
        guard usesExpandedTextLayout == false else {
            return 0
        }
        return role == .user ? userHorizontalReserve : assistantHorizontalReserve
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

enum ChatTranscriptTrackLayoutPolicy {
    static let horizontalPadding: CGFloat = 18
    static let minimumContentWidth: CGFloat = 280
    static let maximumContentWidth: CGFloat = 920

    static func contentWidth(forContainerWidth width: CGFloat) -> CGFloat {
        guard width.isFinite, width > 0 else {
            return minimumContentWidth
        }

        return min(
            max(width - horizontalPadding * 2, minimumContentWidth),
            maximumContentWidth
        )
    }
}

struct ChatTranscriptVerticalLayoutPlan: Equatable {
    let minimumContentHeight: CGFloat
    let anchorsContentToBottom: Bool
}

enum ChatTranscriptVerticalLayoutPolicy {
    static let verticalPadding: CGFloat = 10

    static func resolve(
        viewportHeight: CGFloat,
        messageCount: Int
    ) -> ChatTranscriptVerticalLayoutPlan {
        let validHeight = viewportHeight.isFinite && viewportHeight > 0
            ? viewportHeight
            : 0

        return ChatTranscriptVerticalLayoutPlan(
            minimumContentHeight: max(validHeight - verticalPadding * 2, 0),
            anchorsContentToBottom: messageCount > 0
        )
    }
}

