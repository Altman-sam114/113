import Foundation
import PhotosUI
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct ComposerBar: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.compactWorkbench) private var isCompact
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.isEnabled) private var isEnabled
    @State private var clearedDraft: ComposerClearedDraft?
    @FocusState private var focusedField: ComposerFocusedField?

    @Binding var text: String
    let isGenerating: Bool
    let isChatActive: Bool
    let focusRequest: ComposerFocusRequest
    let clearFocusRequest: () -> Void
    let send: () -> Void
    let stop: () -> Void
    var editingChanged: (Bool) -> Void = { _ in }
    var showsDraftTools = false
    var compactEditingChanged: (Bool) -> Void = { _ in }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .bottom, spacing: 10) {
                HStack(alignment: .bottom, spacing: 10) {
                    if !isCompact {
                        Image(systemName: "sparkle")
                            .font(.body)
                            .foregroundStyle(theme.accent)
                            .frame(width: 24, height: 24)
                            .padding(.bottom, 10)
                            .accessibilityHidden(true)
                    }

                    TextField("输入消息", text: $text, prompt: Text("输入消息").foregroundStyle(theme.secondaryText), axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(ComposerInputTextLayoutPolicy.semanticFont)
                        .foregroundStyle(theme.primaryText)
                        .tint(theme.accent)
                        .lineLimit(ComposerInputTextLayoutPolicy.minimumLineCount...ComposerInputTextLayoutPolicy.maximumLineCount)
                        .lineSpacing(ComposerInputTextLayoutPolicy.lineSpacing)
                        .fixedSize(
                            horizontal: false,
                            vertical: ComposerInputTextLayoutPolicy.allowsNaturalVerticalGrowth
                        )
                        .padding(.vertical, ComposerInputTextLayoutPolicy.verticalPadding)
                        .focused($focusedField, equals: .input)
                        .accessibilityLabel(ComposerInputMetadata.textFieldLabel)
                        .accessibilityHint(ComposerInputMetadata.textFieldHint)
                        .accessibilityInputLabels(ComposerInputMetadata.textFieldInputLabels)
                        .accessibilityIdentifier(ComposerInputMetadata.textFieldIdentifier)
                }
                .padding(.horizontal, 13)

                Button {
                    isGenerating ? stop() : send()
                } label: {
                    Label(
                        ComposerInputMetadata.actionLabel(isGenerating: isGenerating),
                        systemImage: isGenerating ? "stop.fill" : "arrow.up"
                    )
                        .labelStyle(.iconOnly)
                        .font(.system(size: 16, weight: .semibold))
                        .frame(
                            width: ComposerInputActionLayoutPolicy.buttonSize(for: currentAction),
                            height: ComposerInputActionLayoutPolicy.buttonSize(for: currentAction)
                        )
                        .background(actionFillGradient, in: Circle())
                        .foregroundStyle(theme.inverseText)
                }
                .buttonStyle(WorkbenchPressFeedbackStyle())
                .keyboardShortcut(.return, modifiers: [.command])
                .disabled(isSendDisabled)
                .opacity(isSendDisabled ? 0.55 : 1)
                .shadow(
                    color: actionBaseColor.opacity(
                        ComposerFocusGlowStylePolicy.sendGlowOpacity(
                            isEnabled: !isSendDisabled,
                            isDark: theme.isDark
                        )
                    ),
                    radius: ComposerFocusGlowStylePolicy.sendGlowRadius,
                    x: 0,
                    y: 0
                )
                .accessibilityLabel(ComposerInputMetadata.actionLabel(isGenerating: isGenerating))
                .accessibilityValue(ComposerInputMetadata.actionValue(text: text, isGenerating: isGenerating))
                .accessibilityHint(ComposerInputMetadata.actionHint(text: text, isGenerating: isGenerating))
                .accessibilityInputLabels(ComposerInputMetadata.actionInputLabels(isGenerating: isGenerating))
                .accessibilityIdentifier(ComposerInputMetadata.actionIdentifier(isGenerating: isGenerating))
            }
            if showsDraftTools && (isInputFocused || !text.isEmpty || clearedDraft != nil) {
                ComposerDraftTools(
                    isChatActive: isChatActive,
                    sharedUndo: $clearedDraft,
                    dismissKeyboard: isInputFocused && isChatActive ? { focusedField = nil } : nil
                )
                .padding(.horizontal, 4)
            }
        }
        .padding(8)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(theme.surface)
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(
                            inputFieldBorderColor,
                            lineWidth: ComposerFocusGlowStylePolicy.lineWidth(isFocused: isInputFocused)
                        )
                        .shadow(
                            color: theme.accent.opacity(ComposerFocusGlowStylePolicy.glowOpacity(
                                isFocused: isInputFocused, isDark: theme.isDark
                            )),
                            radius: ComposerFocusGlowStylePolicy.glowRadius
                        )
                }
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
        .onAppear(perform: updateFocus)
        .onChange(of: isInputFocused) { _, isFocused in
            editingChanged(isFocused)
        }
        .onDisappear {
            editingChanged(false)
            compactEditingChanged(false)
        }
        .onChange(of: condensesHeaderForEditing, initial: true) { _, condenses in
            compactEditingChanged(condenses)
        }
        .onChange(of: isChatActive) { _, active in
            if !active { clearedDraft = nil }
        }
        .onChange(of: isEnabled) { _, enabled in
            if !enabled { clearedDraft = nil }
        }
        .onChange(of: isGenerating) { _, generating in
            if generating { clearedDraft = nil }
        }
        .onChange(
            of: ComposerFocusLifecycleID(
                isChatActive: isChatActive,
                requestSequence: focusRequest.sequence
            )
        ) {
            updateFocus()
        }
    }

    private var condensesHeaderForEditing: Bool {
#if targetEnvironment(macCatalyst)
        false
#else
        isCompact && dynamicTypeSize.isAccessibilitySize && isInputFocused && isChatActive
#endif
    }

    private var isSendDisabled: Bool {
        ComposerInputMetadata.isActionDisabled(text: text, isGenerating: isGenerating)
    }

    private var currentAction: ComposerInputAction {
        isGenerating ? .stop : .send
    }

    private var isInputFocused: Bool {
        focusedField == .input
    }

    private func updateFocus() {
        if ComposerFocusPolicy.shouldReleaseFocus(isChatActive: isChatActive) {
            focusedField = nil
            clearFocusRequest()
            return
        }

        guard ComposerFocusPolicy.shouldFocus(
            isChatActive: isChatActive,
            request: focusRequest
        ) else {
            return
        }

        focusedField = .input
        clearFocusRequest()
    }

    private var inputFieldBorderColor: Color {
        if ComposerFocusGlowStylePolicy.usesAccentBorder(isFocused: isInputFocused) {
            return theme.accent.opacity(ComposerFocusGlowStylePolicy.focusedBorderOpacity)
        }
        return theme.border
    }

    private var actionBaseColor: Color {
        isGenerating ? theme.danger : theme.accent
    }

    private var actionFillGradient: LinearGradient {
        let topOpacity = isGenerating
            ? ComposerFocusGlowStylePolicy.stopGradientTopOpacity
            : ComposerFocusGlowStylePolicy.gradientTopOpacity
        let bottomOpacity = isGenerating
            ? ComposerFocusGlowStylePolicy.stopGradientBottomOpacity
            : ComposerFocusGlowStylePolicy.gradientBottomOpacity
        return LinearGradient(
            colors: [
                actionBaseColor.opacity(topOpacity),
                actionBaseColor.opacity(bottomOpacity)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

}

enum ComposerFocusGlowStylePolicy {
    static let focusedBorderOpacity = 0.55
    static let glowRadius: CGFloat = 10
    static let sendGlowRadius: CGFloat = 8
    static let gradientTopOpacity = 1.0
    static let gradientBottomOpacity = 0.78
    static let stopGradientTopOpacity = 0.9
    static let stopGradientBottomOpacity = 0.7

    static func usesAccentBorder(isFocused: Bool) -> Bool {
        isFocused
    }

    static func lineWidth(isFocused: Bool) -> CGFloat {
        isFocused ? 1.5 : 1
    }

    static func glowOpacity(isFocused: Bool, isDark: Bool) -> Double {
        guard isFocused else {
            return 0
        }
        return isDark ? 0.35 : 0.20
    }

    static func sendGlowOpacity(isEnabled: Bool, isDark: Bool) -> Double {
        guard isEnabled else {
            return 0
        }
        return isDark ? 0.45 : 0.28
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


/// Native paste reads only after the user's tap; a late provider must still match
/// both the workspace lifetime and the exact session/draft revision it started in.
struct ComposerClearedDraft {
    let text: String
    let emptySnapshot: ComposerDraftSnapshot
}

struct ComposerDraftTools: View {
    @EnvironmentObject private var inference: InferenceEngine
    @Environment(\.appTheme) private var theme
    @Environment(\.isEnabled) private var isEnabled
    @State private var pasteEpoch = UUID()
    @State private var acceptsPaste = false
    @State private var localUndo: ComposerClearedDraft?

    let isChatActive: Bool
    var sharedUndo: Binding<ComposerClearedDraft?>? = nil
    var dismissKeyboard: (() -> Void)? = nil

    private var undo: ComposerClearedDraft? {
        get {
            if let sharedUndo { return sharedUndo.wrappedValue }
            return localUndo
        }
        nonmutating set {
            if let sharedUndo { sharedUndo.wrappedValue = newValue }
            else { localUndo = newValue }
        }
    }

    private var canEdit: Bool {
        isEnabled && isChatActive && !inference.isGenerating
            && !inference.conversationPersistenceState.blocksEditing
    }

    var body: some View {
        let snapshot = inference.composerDraftSnapshot
        let epoch = pasteEpoch
        HStack(spacing: 4) {
            ComposerPasteControl(isEnabled: canEdit) { value in
                guard acceptsPaste, pasteEpoch == epoch else { return }
                _ = inference.pasteIntoComposer([value], matching: snapshot)
            }
            .frame(width: 44, height: 44)
            .help("粘贴文字到当前草稿")

            ComposerToolButton(
                symbol: "xmark.circle", title: "清空草稿", identifier: "composer-clear",
                hint: "只清空当前未发送文字，可用撤销恢复，不删除会话。",
                inputLabels: ["清空草稿", "清空输入"], tint: UIColor(theme.secondaryText),
                isEnabled: canEdit && !snapshot.text.isEmpty
            ) {
                guard canEdit, !snapshot.text.isEmpty,
                      inference.replaceComposerDraft("", matching: snapshot) else { return }
                undo = ComposerClearedDraft(text: snapshot.text, emptySnapshot: inference.composerDraftSnapshot)
            }
            .frame(width: 44, height: 44)
            .help("清空草稿，可撤销")

            ComposerToolButton(
                symbol: "arrow.uturn.backward", title: "撤销清空", identifier: "composer-undo-clear",
                hint: "恢复刚清空的草稿；切换会话或继续编辑后不覆盖新的输入。",
                inputLabels: ["撤销清空", "恢复草稿"], tint: UIColor(theme.secondaryText),
                isEnabled: canEdit && undo?.emptySnapshot == snapshot
            ) {
                guard canEdit, let previous = undo else { return }
                if inference.replaceComposerDraft(previous.text, matching: previous.emptySnapshot) {
                    undo = nil
                }
            }
            .frame(width: 44, height: 44)
            .help("恢复刚清空的草稿")

            Spacer(minLength: 4)
            if let dismissKeyboard {
                ComposerToolButton(
                    symbol: "keyboard.chevron.compact.down", title: "收起键盘", identifier: "composer-keyboard-done",
                    hint: "收起键盘并保留当前草稿。", inputLabels: ["完成", "收起键盘"],
                    tint: UIColor(theme.secondaryText), isEnabled: isEnabled, perform: dismissKeyboard
                )
                .frame(width: 44, height: 44)
                .help("收起键盘")
            } else {
                Text(snapshot.text.isEmpty ? "未发送草稿" : "\(snapshot.text.count) 字符")
                    .font(.caption)
                    .foregroundStyle(theme.secondaryText)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel("当前草稿，\(snapshot.text.count) 个字符")
                    .accessibilityIdentifier("composer-draft-count")
            }
        }
        .font(.body)
        .foregroundStyle(theme.secondaryText)
        .onAppear { acceptsPaste = canEdit }
        .onDisappear { invalidatePaste() }
        .onChange(of: canEdit) { _, enabled in
            invalidatePaste()
            acceptsPaste = enabled
            if !enabled { undo = nil }
        }
        .onChange(of: snapshot) { _, current in
            if undo?.emptySnapshot != current { undo = nil }
        }
    }

    private func invalidatePaste() {
        pasteEpoch = UUID()
        acceptsPaste = false
    }
}

private struct ComposerToolButton: UIViewRepresentable {
    let symbol: String
    let title: String
    let identifier: String
    let hint: String
    let inputLabels: [String]
    let tint: UIColor
    let isEnabled: Bool
    let perform: () -> Void

    func makeUIView(context: Context) -> ToolButton {
        let button = ToolButton(type: .system)
        button.addAction(UIAction { [weak button] _ in button?.perform?() }, for: .touchUpInside)
        return button
    }

    func updateUIView(_ button: ToolButton, context: Context) {
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: symbol, withConfiguration: UIImage.SymbolConfiguration(
            pointSize: 18, weight: .medium
        ))
        configuration.baseForegroundColor = tint
        configuration.contentInsets = .zero
        button.configuration = configuration
        button.isEnabled = isEnabled
        button.accessibilityLabel = title
        button.accessibilityIdentifier = identifier
        button.accessibilityHint = hint
        button.accessibilityUserInputLabels = inputLabels
        button.perform = perform
    }

    final class ToolButton: UIButton {
        var perform: (() -> Void)?
    }
}

/// The visible control and paste authorization both belong to UIKit. The
/// receiver never reads the pasteboard outside an authorized paste action.
private struct ComposerPasteControl: UIViewRepresentable {
    let isEnabled: Bool
    let onPaste: @MainActor @Sendable (String) -> Void

    func makeUIView(context: Context) -> PasteTarget {
        PasteTarget()
    }

    func updateUIView(_ view: PasteTarget, context: Context) {
        view.onPaste = onPaste
        view.control.target = isEnabled ? view : nil
        view.control.isEnabled = isEnabled
    }

    static func dismantleUIView(_ view: PasteTarget, coordinator: ()) {
        view.control.target = nil
        view.onPaste = nil
    }

    final class PasteTarget: UIView {
        let control: UIPasteControl
        var onPaste: (@MainActor @Sendable (String) -> Void)?

        init() {
            let configuration = UIPasteControl.Configuration()
            configuration.baseBackgroundColor = .secondarySystemFill
            configuration.baseForegroundColor = .label
            configuration.cornerStyle = .capsule
            configuration.displayMode = .iconOnly
            control = UIPasteControl(configuration: configuration)
            super.init(frame: .zero)
            traitOverrides.preferredContentSizeCategory = .large
            pasteConfiguration = UIPasteConfiguration(forAccepting: NSString.self)
            control.accessibilityIdentifier = "composer-paste"
            control.accessibilityLabel = "粘贴文字"
            control.accessibilityHint = "点按后读取系统粘贴的文字，追加到当前草稿，不自动发送。"
            control.accessibilityUserInputLabels = ["粘贴文字", "粘贴"]
            control.translatesAutoresizingMaskIntoConstraints = false
            addSubview(control)
            NSLayoutConstraint.activate([
                control.leadingAnchor.constraint(equalTo: leadingAnchor),
                control.trailingAnchor.constraint(equalTo: trailingAnchor),
                control.topAnchor.constraint(equalTo: topAnchor),
                control.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])
        }

        required init?(coder: NSCoder) { nil }

        override func paste(itemProviders: [NSItemProvider]) {
            guard let onPaste, control.isEnabled,
                  let provider = itemProviders.first(where: { $0.canLoadObject(ofClass: NSString.self) }) else { return }
            provider.loadObject(ofClass: NSString.self) { value, _ in
                guard let text = value as? String else { return }
                Task { @MainActor in onPaste(text) }
            }
        }
    }
}
