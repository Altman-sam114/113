import Foundation
import PhotosUI
import SwiftUI
import UIKit
import UniformTypeIdentifiers

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
                        title: "灵感，从这里开始",
                        subtitle: "精选提示词，帮你把问题问得更好。选择模板，继续你的对话。"
                    )

                    PromptCategorySelector(selectedCategory: $selectedCategory)

                    PromptTemplateGrid(
                        templates: templates,
                        availableWidth: PromptTemplatesWorkspaceLayoutPolicy.contentWidth(
                            forContainerWidth: proxy.size.width
                        ),
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
                .padding(.top, WorkbenchPresentationPolicy.pageTopInset)
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
    let availableWidth: CGFloat
    let isGenerating: Bool
    let apply: (PresetPromptTemplate) -> Void
    let send: (PresetPromptTemplate) -> Void

    var body: some View {
        templateGrid(
            columnCount: PromptTemplateGridLayoutPolicy.columnCount(for: availableWidth)
        )
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
                        .font(.system(size: 17, weight: .semibold))
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
                .stroke(theme.border, lineWidth: 1)
        }
        .disabled(isGenerating)
        .opacity(isGenerating ? 0.5 : 1)
    }

    private var templateBackground: some ShapeStyle {
        theme.surface
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
