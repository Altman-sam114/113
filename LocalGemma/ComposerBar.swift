import Foundation
import PhotosUI
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct ComposerBar: View {
    @Environment(\.appTheme) private var theme
    @FocusState private var focusedField: ComposerFocusedField?

    @Binding var text: String
    let isGenerating: Bool
    let isChatActive: Bool
    let focusRequest: ComposerFocusRequest
    let clearFocusRequest: () -> Void
    let send: () -> Void
    let stop: () -> Void

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            HStack(alignment: .bottom, spacing: 10) {
                Image(systemName: "bubble.left.and.text.bubble.right.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(theme.accent)
                    .frame(width: 24, height: 24)
                    .padding(.bottom, 10)
                    .accessibilityHidden(true)

                TextField("问本地模型任何问题", text: $text, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(ComposerInputTextLayoutPolicy.semanticFont)
                    .foregroundStyle(theme.primaryText)
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
            .background(theme.recessedSurface, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .stroke(
                        inputFieldBorderColor,
                        lineWidth: ComposerFocusGlowStylePolicy.lineWidth(isFocused: isInputFocused)
                    )
                    .shadow(
                        color: theme.accent.opacity(
                            ComposerFocusGlowStylePolicy.glowOpacity(
                                isFocused: isInputFocused,
                                isDark: theme.isDark
                            )
                        ),
                        radius: ComposerFocusGlowStylePolicy.glowRadius,
                        x: 0,
                        y: 0
                    )
            }

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
            .buttonStyle(.plain)
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
        .padding(8)
        .background(theme.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(isGenerating ? theme.success.opacity(0.32) : theme.accent.opacity(0.18), lineWidth: 1)
        }
        .onAppear(perform: updateFocus)
        .onChange(
            of: ComposerFocusLifecycleID(
                isChatActive: isChatActive,
                requestSequence: focusRequest.sequence
            )
        ) {
            updateFocus()
        }
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
        isGenerating ? Color.red : theme.accent
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

