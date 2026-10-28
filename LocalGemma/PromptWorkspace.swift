import Foundation
import PhotosUI
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct PromptTemplatesWorkspace: View {
    @EnvironmentObject private var catalog: ModelCatalog
    @EnvironmentObject private var inference: InferenceEngine
    @Environment(\.appTheme) private var theme
    @Environment(\.compactWorkbench) private var isCompact
    @State private var selectedCategory: PromptTemplateCategory?
    @State private var selectedCollection: CompactPromptCollection

    let openChat: (ComposerFocusReason) -> Void

    init(
        initialCollection: CompactPromptCollection = .everyday,
        openChat: @escaping (ComposerFocusReason) -> Void
    ) {
        _selectedCollection = State(initialValue: initialCollection)
        self.openChat = openChat
    }

    var body: some View {
        let model = catalog.selectedModel
        let validation = catalog.validation(for: model)
        let templates = isCompact ? selectedCollection.templates : PromptTemplateLibrary.templates(in: selectedCategory)

        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader(
                        eyebrow: "PROMPTS",
                        title: isCompact ? "模板" : "灵感，从这里开始",
                        subtitle: "精选提示词，帮你把问题问得更好。选择模板，继续你的对话。"
                    )

                    if isCompact {
                        CompactPromptCollectionPicker(selection: $selectedCollection)
                    } else {
                        PromptCategorySelector(selectedCategory: $selectedCategory)
                    }

                    PromptTemplateGrid(
                        templates: templates,
                        availableWidth: PromptTemplatesWorkspaceLayoutPolicy.contentWidth(
                            forContainerWidth: proxy.size.width
                        ),
                        isGenerating: inference.isGenerating,
                        apply: { template in
                            guard !inference.conversationPersistenceState.blocksEditing else { return }
                            inference.applyTemplate(template)
                            openChat(.applyTemplate)
                        },
                        send: { template in
                            guard !inference.conversationPersistenceState.blocksEditing else { return }
                            inference.useTemplate(
                                template,
                                model: model,
                                availability: validation.availability
                            )
                            openChat(.sendTemplate)
                        }
                    )
                    .disabled(inference.conversationPersistenceState.blocksEditing)
                }
                .frame(
                    width: PromptTemplatesWorkspaceLayoutPolicy.contentWidth(
                        forContainerWidth: proxy.size.width
                    ),
                    alignment: .leading
                )
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, PromptTemplatesWorkspaceLayoutPolicy.horizontalPadding)
                .padding(.top, isCompact ? 16 : WorkbenchPresentationPolicy.pageTopInset)
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
    @Environment(\.compactWorkbench) private var isCompact
    let templates: [PresetPromptTemplate]
    let availableWidth: CGFloat
    let isGenerating: Bool
    let apply: (PresetPromptTemplate) -> Void
    let send: (PresetPromptTemplate) -> Void

    var body: some View {
        templateGrid(
            columnCount: isCompact ? 1 : PromptTemplateGridLayoutPolicy.columnCount(for: availableWidth)
        )
    }

    private func templateGrid(columnCount: Int) -> some View {
        LazyVGrid(
            columns: isCompact ? [GridItem(.flexible(minimum: 0))]
                : PromptTemplateGridLayoutPolicy.columns(forColumnCount: columnCount),
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
        .frame(minWidth: isCompact ? 0 : PromptTemplateGridLayoutPolicy.minimumWidth(forColumnCount: columnCount))
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
    @Environment(\.compactWorkbench) private var isCompact
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
        let primary = theme.actionPalette(for: .primary)
        let secondary = theme.actionPalette(for: .secondary)

        return Button(action: action) {
            HStack(spacing: 6) {
                if !isCompact {
                    Image(systemName: icon)
                }
                Text(title)
            }
                .font(.subheadline)
                .fontWeight(isCompact ? .medium : .bold)
                .foregroundStyle(isSelected ? primary.prominentForeground : secondary.foreground)
                .lineLimit(PromptCategoryTextLayoutPolicy.labelLineLimit)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, isCompact ? CompactPromptPresentationPolicy.categoryHorizontalPadding
                         : PromptCategoryLayoutPolicy.horizontalPadding)
                .padding(.vertical, PromptCategoryLayoutPolicy.verticalPadding)
                .frame(
                    minWidth: isCompact ? CompactPromptPresentationPolicy.categoryMinimumWidth
                        : PromptCategoryLayoutPolicy.minimumChipWidth,
                    minHeight: PromptCategoryLayoutPolicy.minimumTouchTarget
                )
                .background(isSelected ? primary.prominentFill : secondary.fill, in: Capsule())
                .overlay(Capsule().stroke(isSelected ? primary.border : secondary.border, lineWidth: 1))
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
    @Environment(\.compactWorkbench) private var isCompact

    let template: PresetPromptTemplate
    let isGenerating: Bool
    let apply: () -> Void
    let send: () -> Void

    var body: some View {
        Group {
            if isCompact {
                CompactPromptTemplateRow(template: template, isGenerating: isGenerating, apply: apply, send: send)
            } else {
                expandedCard
            }
        }
    }

    private var expandedCard: some View {
        let categoryTint = theme.categoryTint(for: template.category)
        let primary = theme.actionPalette(for: .primary)
        let secondary = theme.actionPalette(for: .secondary)

        return VStack(alignment: .leading, spacing: 11) {
            HStack(alignment: .top, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(categoryTint.opacity(0.10))
                    Image(systemName: template.icon)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(categoryTint)
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
                    .foregroundStyle(categoryTint)
                    .lineLimit(PromptTemplateTextLayoutPolicy.categoryLineLimit)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(categoryTint.opacity(0.10), in: Capsule())
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
                        .foregroundStyle(secondary.foreground)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: PromptTemplateActionLayoutPolicy.minimumTouchTarget)
                        .padding(.vertical, 9)
                        .background(secondary.fill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(secondary.border, lineWidth: 1)
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

                if PromptTemplateInteractionPolicy.showsDirectSend(for: template) {
                    Button(action: send) {
                        Label("发送", systemImage: "paperplane.fill")
                            .labelStyle(.iconOnly)
                            .font(.body)
                            .bold()
                            .frame(
                                width: PromptTemplateActionLayoutPolicy.sendButtonSize,
                                height: PromptTemplateActionLayoutPolicy.sendButtonSize
                            )
                            .background(primary.prominentFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .foregroundStyle(primary.prominentForeground)
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

enum CompactPromptPresentationPolicy {
    static let categoryMinimumWidth: CGFloat = 56
    static let categoryHorizontalPadding: CGFloat = 10
    static let rowMinimumHeight: CGFloat = 76

    static func summary(for template: PresetPromptTemplate) -> String {
        template.subtitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? template.prompt : template.subtitle
    }
}

enum PromptTemplateInteractionPolicy {
    static func showsDirectSend(for template: PresetPromptTemplate) -> Bool {
        !template.requiresInput
    }
}

enum CompactPromptCollection: String, CaseIterable, Identifiable {
    case everyday
    case technical

    var id: String { rawValue }
    var title: String { self == .everyday ? "日常" : "进阶" }
    var icon: String { self == .everyday ? "sparkles" : "terminal" }
    var templates: [PresetPromptTemplate] {
        self == .everyday ? PromptTemplateLibrary.everydayTemplates : PromptTemplateLibrary.technicalTemplates
    }
    var accessibilityHint: String {
        "显示\(title)模板。只筛选本机内容，不填入或发送提示词，不下载权重，也不启动真实 runtime。"
    }
    var inputLabels: [String] { ["\(title)模板", "筛选\(title)", "显示\(title)模板"] }
    var accessibilityIdentifier: String { "prompt-collection-\(rawValue)" }
}

struct CompactPromptCollectionPicker: View {
    @Environment(\.appTheme) private var theme
    @Binding var selection: CompactPromptCollection

    var body: some View {
        HStack(spacing: 4) {
            ForEach(CompactPromptCollection.allCases) { collection in
                Button { selection = collection } label: {
                    Label(collection.title, systemImage: collection.icon)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, minHeight: CompactWorkbenchPolicy.minimumTouchTarget)
                        .padding(.vertical, 2)
                        .foregroundStyle(selection == collection ? theme.accent : theme.secondaryText)
                        .background {
                            if selection == collection {
                                Capsule().fill(theme.surface)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(collection.title)模板")
                .accessibilityValue(PromptCategoryAccessibilityMetadata.value(isSelected: selection == collection))
                .accessibilityHint(collection.accessibilityHint)
                .accessibilityInputLabels(collection.inputLabels)
                .accessibilityIdentifier(collection.accessibilityIdentifier)
                .accessibilityAddTraits(selection == collection ? .isSelected : [])
            }
        }
        .padding(4)
        .background(theme.chipSurface, in: Capsule())
    }
}

struct CompactPromptTemplateRow: View {
    @Environment(\.appTheme) private var theme

    let template: PresetPromptTemplate
    let isGenerating: Bool
    let apply: () -> Void
    let send: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: apply) {
                HStack(spacing: 10) {
                    Image(systemName: template.icon)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(theme.categoryTint(for: template.category))
                        .frame(width: 34, height: 34)
                        .background(theme.chipSurface, in: RoundedRectangle(cornerRadius: 10))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(template.title)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(theme.primaryText)
                            .lineLimit(PromptTemplateTextLayoutPolicy.titleLineLimit)
                        Text(CompactPromptPresentationPolicy.summary(for: template))
                            .font(.subheadline)
                            .foregroundStyle(theme.secondaryText)
                            .lineLimit(PromptTemplateTextLayoutPolicy.subtitleLineLimit)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    if template.requiresInput {
                        Image(systemName: "arrow.up.left")
                            .font(.body.weight(.medium))
                            .foregroundStyle(theme.accent)
                            .accessibilityHidden(true)
                    }
                }
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity, minHeight: CompactPromptPresentationPolicy.rowMinimumHeight,
                       alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(PromptTemplateActionAccessibilityMetadata.label(for: .apply, template: template))
            .accessibilityValue(PromptTemplateActionAccessibilityMetadata.value(for: .apply, isGenerating: isGenerating))
            .accessibilityHint(PromptTemplateActionAccessibilityMetadata.hint(for: .apply, template: template))
            .accessibilityInputLabels(PromptTemplateActionAccessibilityMetadata.inputLabels(for: .apply, template: template)
                + ["使用模板", template.title])
            .accessibilityIdentifier(PromptTemplateActionAccessibilityMetadata.identifier(for: .apply, template: template))

            if PromptTemplateInteractionPolicy.showsDirectSend(for: template) {
                Button(action: send) {
                    Image(systemName: "paperplane")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(theme.accent)
                        .frame(width: PromptTemplateActionLayoutPolicy.sendButtonSize,
                               height: PromptTemplateActionLayoutPolicy.sendButtonSize)
                        .background(theme.chipSurface, in: RoundedRectangle(cornerRadius: 13))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(PromptTemplateActionAccessibilityMetadata.label(for: .send, template: template))
                .accessibilityValue(PromptTemplateActionAccessibilityMetadata.value(for: .send, isGenerating: isGenerating))
                .accessibilityHint(PromptTemplateActionAccessibilityMetadata.hint(for: .send, template: template))
                .accessibilityInputLabels(PromptTemplateActionAccessibilityMetadata.inputLabels(for: .send, template: template))
                .accessibilityIdentifier(PromptTemplateActionAccessibilityMetadata.identifier(for: .send, template: template))
            }
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(theme.border, lineWidth: 1)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
        .disabled(isGenerating)
        .opacity(isGenerating ? 0.5 : 1)
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
