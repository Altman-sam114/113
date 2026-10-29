import SwiftUI
import UIKit

enum ChatMessagePresentationPolicy {
    static let compactHeaderSpacing: CGFloat = 8
    static var compactHeaderTrailingInset: CGFloat {
        ChatMessageCopyActionPolicy.actionButtonSize + compactHeaderSpacing
    }

    static func showsSurface(for role: ChatMessage.Role, isCompact: Bool) -> Bool {
        !isCompact || role != .assistant
    }
}

struct ChatBubble: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.compactWorkbench) private var isCompact
    @State private var didCopy = false
    let message: ChatMessage
    let availableWidth: CGFloat
    let isGenerating: Bool

    var body: some View {
        let textPlan = ChatBubbleTextLayoutPolicy.resolve(dynamicTypeSize: dynamicTypeSize)
        let placeholder = ChatGenerationPlaceholderPresentationPolicy.resolve(
            message: message, isGenerating: isGenerating
        )
        let messageLayout = isCompact
            ? AnyLayout(ZStackLayout(alignment: .topTrailing))
            : AnyLayout(VStackLayout(alignment: bubbleAlignment, spacing: 6))
        let showsSurface = ChatMessagePresentationPolicy.showsSurface(for: message.role, isCompact: isCompact)

        HStack(alignment: .bottom, spacing: textPlan.horizontalSpacing) {
            if message.role == .user {
                Spacer(minLength: ChatBubbleLayoutPolicy.horizontalReserve(
                    for: message.role, usesExpandedTextLayout: textPlan.usesExpandedWidth
                ))
            }

            messageLayout {
                ChatMessageContent(
                    message: message, placeholder: placeholder, textPlan: textPlan,
                    roleTitle: roleTitle, roleTint: roleTint, alignment: bubbleAlignment,
                    isCompact: isCompact, reduceMotion: reduceMotion
                )
                ChatMessageActions(
                    message: message, isGenerating: isGenerating, isCompact: isCompact,
                    metadataLineLimit: textPlan.metadataLineLimit, reduceMotion: reduceMotion,
                    didCopy: $didCopy
                )
            }
            .fixedSize(horizontal: false, vertical: isCompact)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background {
                if showsSurface {
                    RoundedRectangle(cornerRadius: 16, style: .continuous).fill(bubbleBackground)
                }
            }
            .overlay {
                if showsSurface {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(theme.subtleBorder, lineWidth: 1)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
            .frame(
                maxWidth: ChatBubbleLayoutPolicy.maxWidth(
                    for: message.role, availableWidth: availableWidth,
                    usesExpandedTextLayout: textPlan.usesExpandedWidth
                ),
                alignment: message.role == .user ? .trailing : .leading
            )

            if message.role != .user {
                Spacer(minLength: ChatBubbleLayoutPolicy.horizontalReserve(
                    for: message.role, usesExpandedTextLayout: textPlan.usesExpandedWidth
                ))
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var roleTitle: String {
        switch message.role {
        case .user: return "你"
        case .assistant: return "助手"
        case .system: return "状态"
        }
    }

    private var roleTint: Color {
        switch message.role {
        case .user: return theme.secondaryText
        case .assistant: return theme.accent
        case .system: return theme.warning
        }
    }

    private var bubbleAlignment: HorizontalAlignment {
        message.role == .user ? .trailing : .leading
    }

    private var bubbleBackground: LinearGradient {
        let colors: [Color]
        switch message.role {
        case .user:
            colors = [theme.accent.opacity(theme.isDark ? 0.14 : 0.09), theme.accent.opacity(theme.isDark ? 0.09 : 0.05)]
        case .assistant:
            colors = [theme.surface, theme.surface]
        case .system:
            colors = [theme.warning.opacity(0.12), theme.surface]
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

private struct ChatMessageContent: View {
    @Environment(\.appTheme) private var theme
    let message: ChatMessage
    let placeholder: ChatGenerationPlaceholderPresentation
    let textPlan: ChatBubbleTextLayoutPlan
    let roleTitle: String
    let roleTint: Color
    let alignment: HorizontalAlignment
    let isCompact: Bool
    let reduceMotion: Bool

    var body: some View {
        VStack(alignment: alignment, spacing: 6) {
            Text(roleTitle)
                .font(.caption.weight(.semibold))
                .foregroundStyle(roleTint.opacity(0.82))
                .lineLimit(textPlan.roleLineLimit)
                .fixedSize(horizontal: false, vertical: true)
                .frame(minHeight: isCompact ? ChatMessageCopyActionPolicy.actionButtonSize : nil)
                .padding(.trailing, isCompact ? ChatMessagePresentationPolicy.compactHeaderTrailingInset : 0)

            if message.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                if ChatGenerationPlaceholderPresentationPolicy.showsIndicator(for: placeholder) {
                    GenerationIndicatorView(reduceMotion: reduceMotion)
                } else if placeholder == .cancelled {
                    Text("已停止")
                        .font(.footnote)
                        .foregroundStyle(theme.secondaryText)
                }
            } else {
                Text(message.text)
                    .font(.body)
                    .lineSpacing(ChatBubbleTextLayoutPolicy.bodyLineSpacing)
                    .foregroundStyle(message.role == .system ? theme.secondaryText : theme.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(ChatMessageAccessibilityMetadata.label(for: message))
        .accessibilityValue(ChatMessageAccessibilityMetadata.value(for: message, placeholderPresentation: placeholder))
        .accessibilityHint(ChatMessageAccessibilityMetadata.hint)
        .accessibilityInputLabels(ChatMessageAccessibilityMetadata.inputLabels(for: message))
        .accessibilityIdentifier(ChatMessageAccessibilityMetadata.identifier(for: message))
    }
}

private struct ChatMessageActions: View {
    @Environment(\.appTheme) private var theme
    let message: ChatMessage
    let isGenerating: Bool
    let isCompact: Bool
    let metadataLineLimit: Int
    let reduceMotion: Bool
    @Binding var didCopy: Bool

    var body: some View {
        HStack(spacing: 4) {
            if !isCompact {
                HStack(spacing: 4) {
                    Image(systemName: "number").font(.caption.weight(.bold))
                    Text("\(message.tokens) tokens")
                        .font(.caption.weight(.semibold))
                        .lineLimit(metadataLineLimit)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundStyle(theme.tertiaryText)
                .accessibilityHidden(true)
            }

            Button(action: copyMessage) {
                Image(systemName: didCopy ? "checkmark" : "doc.on.doc")
                    .font(isCompact ? .system(size: 16, weight: .medium) : .body.weight(.semibold))
                    .frame(width: ChatMessageCopyActionPolicy.actionButtonSize, height: ChatMessageCopyActionPolicy.actionButtonSize)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(didCopy ? theme.success : theme.secondaryText)
            .disabled(!ChatMessageCopyActionPolicy.canCopy(message, isGenerating: isGenerating))
            .help("复制消息")
            .accessibilityLabel(ChatMessageCopyActionAccessibilityMetadata.label)
            .accessibilityValue(ChatMessageCopyActionAccessibilityMetadata.value(
                for: message, isGenerating: isGenerating, didCopy: didCopy
            ))
            .accessibilityHint(ChatMessageCopyActionAccessibilityMetadata.hint)
            .accessibilityInputLabels(ChatMessageCopyActionAccessibilityMetadata.inputLabels(for: message))
            .accessibilityIdentifier(ChatMessageCopyActionAccessibilityMetadata.identifier(for: message))
        }
    }

    private func copyMessage() {
        guard let payload = ChatMessageCopyActionPolicy.payload(for: message, isGenerating: isGenerating) else { return }
        UIPasteboard.general.string = payload
        withAnimation(AppMotionAccessibilityPolicy.animation(
            .spring(response: 0.26, dampingFraction: 0.82), for: .copyConfirmation, reduceMotion: reduceMotion
        )) {
            didCopy = true
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
