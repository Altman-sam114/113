import SwiftUI

enum CompactModelSummaryLayoutPolicy {
    static let horizontalPadding: CGFloat = 18
    static let maximumContentWidth: CGFloat = 520
    static let managementMinimumHeight: CGFloat = 48
    static let closeButtonSize: CGFloat = 48
    static let disclosureMinimumHeight: CGFloat = 48

    static func prefersLargeDetent(dynamicTypeSize: DynamicTypeSize) -> Bool {
        CompactWorkbenchPolicy.stacksHeaderControls(dynamicTypeSize: dynamicTypeSize)
    }

    static func contentWidth(for containerWidth: CGFloat) -> CGFloat {
        guard containerWidth.isFinite, containerWidth > 0 else { return 0 }
        return min(max(containerWidth - horizontalPadding * 2, 0), maximumContentWidth)
    }
}

struct CompactModelSummarySnapshot: Equatable {
    let model: LocalModel
    let readiness: Double
    let tokensPerSecond: Double
    let memoryUsageMB: Int
    let backend: ComputeBackend
    let availability: ArtifactAvailability
    let deploymentState: ModelDeploymentState
    let isGenerating: Bool
    let isSimulated: Bool

    var modeTitle: String { CompactWorkbenchPolicy.runtimeTitle(isSimulated: isSimulated) }
    var activityTitle: String { isGenerating ? "正在生成" : "空闲" }
    var fileTitle: String { CompactWorkbenchPolicy.fileStatus(availability) }
    var deploymentLabel: String { isSimulated ? "模拟部署" : "计划状态" }
    var deploymentTitle: String {
        if isSimulated { return deploymentState == .running ? "已启动" : "未启动" }
        return deploymentState == .running ? "已启用" : "未启用"
    }
    var overviewValue: String {
        "\(model.parameterCount)，\(model.quantization)。\(modeTitle)。\(activityTitle)"
    }
}

struct CompactModelSummarySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var showsRuntimeDetails = false
    @State private var selectedDetent: PresentationDetent = .medium

    let model: LocalModel
    let readiness: Double
    let tokensPerSecond: Double
    let memoryUsageMB: Int
    let backend: ComputeBackend
    let availability: ArtifactAvailability
    let deploymentState: ModelDeploymentState
    let isGenerating: Bool
    let isSimulated: Bool
    let showModels: () -> Void

    private var snapshot: CompactModelSummarySnapshot {
        CompactModelSummarySnapshot(
            model: model, readiness: readiness, tokensPerSecond: tokensPerSecond,
            memoryUsageMB: memoryUsageMB, backend: backend, availability: availability,
            deploymentState: deploymentState, isGenerating: isGenerating, isSimulated: isSimulated
        )
    }

    var body: some View {
        CompactModelSummaryPage(
            snapshot: snapshot, showsRuntimeDetails: $showsRuntimeDetails,
            close: { dismiss() }, showModels: showModels
        )
        .presentationDetents([.medium, .large], selection: $selectedDetent)
        .presentationDragIndicator(.visible)
        .onChange(of: dynamicTypeSize, initial: true) { _, size in
            if CompactModelSummaryLayoutPolicy.prefersLargeDetent(dynamicTypeSize: size) {
                selectedDetent = .large
            }
        }
        .onChange(of: showsRuntimeDetails) { _, expanded in
            if expanded { selectedDetent = .large }
        }
    }
}

struct CompactModelSummaryPage: View {
    @Environment(\.appTheme) private var theme
    let snapshot: CompactModelSummarySnapshot
    @Binding var showsRuntimeDetails: Bool
    let close: () -> Void
    let showModels: () -> Void

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let width = CompactModelSummaryLayoutPolicy.contentWidth(for: geometry.size.width)
                ScrollView {
                    CompactModelSummaryContent(snapshot: snapshot, availableWidth: width, showsRuntimeDetails: $showsRuntimeDetails)
                        .frame(width: width, alignment: .leading)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 24)
                }
                .accessibilityIdentifier("compact-model-summary-scroll")
                .scrollIndicators(.hidden)
                .safeAreaInset(edge: .top, spacing: 0) {
                    CompactModelSummaryHeader(close: close)
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    CompactModelSummaryManageAction(showModels: showModels)
                        .frame(width: width)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(theme.canvas)
                }
            }
            .background(theme.canvas)
            .navigationTitle("运行摘要")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
        }
        .tint(theme.accent)
    }
}

private struct CompactModelSummaryHeader: View {
    @Environment(\.appTheme) private var theme
    let close: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text("运行摘要")
                .font(.headline).foregroundStyle(theme.primaryText)
                .lineLimit(2).fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("compact-model-summary-heading")
            Button(action: close) {
                Image(systemName: "xmark")
                    .font(.system(size: CompactWorkbenchPolicy.headerActionSymbolSize, weight: .medium))
                    .frame(width: CompactModelSummaryLayoutPolicy.closeButtonSize, height: CompactModelSummaryLayoutPolicy.closeButtonSize)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain).foregroundStyle(theme.secondaryText)
            .accessibilityLabel("关闭运行摘要")
            .accessibilityInputLabels(["关闭运行摘要", "关闭"])
            .accessibilityIdentifier("compact-model-summary-close")
        }
        .padding(.horizontal, CompactModelSummaryLayoutPolicy.horizontalPadding)
        .padding(.vertical, 6)
        .background(theme.canvas)
    }
}

struct CompactModelSummaryContent: View {
    @Environment(\.appTheme) private var theme
    let snapshot: CompactModelSummarySnapshot
    let availableWidth: CGFloat
    @Binding var showsRuntimeDetails: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            CompactModelSummaryIdentity(snapshot: snapshot)

            VStack(spacing: 16) {
                CompactModelSummaryStatusRow(title: "模型文件", value: snapshot.fileTitle)
                    .accessibilityIdentifier("compact-model-file-status")
                Rectangle().fill(theme.subtleBorder).frame(height: 1).accessibilityHidden(true)
                CompactModelSummaryStatusRow(title: snapshot.deploymentLabel, value: snapshot.deploymentTitle)
                    .accessibilityIdentifier("compact-model-deployment-status")
            }

            DisclosureGroup(isExpanded: $showsRuntimeDetails) {
                ModelCapsule(
                    model: snapshot.model, readiness: snapshot.readiness,
                    tokensPerSecond: snapshot.tokensPerSecond, memoryUsageMB: snapshot.memoryUsageMB,
                    backend: snapshot.backend, availability: snapshot.availability,
                    deploymentState: snapshot.deploymentState, isGenerating: snapshot.isGenerating,
                    isSimulated: snapshot.isSimulated, availableWidth: availableWidth, layoutMode: .portrait
                )
                .padding(.top, 12)
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("更多运行信息").font(.subheadline.weight(.medium)).foregroundStyle(theme.primaryText)
                    Text("参考指标 · 非实测").font(.caption).foregroundStyle(theme.secondaryText)
                }
                .fixedSize(horizontal: false, vertical: true)
                .frame(minHeight: CompactWorkbenchPolicy.minimumTouchTarget, alignment: .leading)
            }
            .disclosureGroupStyle(CompactModelSummaryDisclosureStyle())
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

private struct CompactModelSummaryDisclosureStyle: DisclosureGroupStyle {
    @Environment(\.appTheme) private var theme

    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                configuration.isExpanded.toggle()
            } label: {
                HStack(spacing: 12) {
                    configuration.label.frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: configuration.isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: CompactWorkbenchPolicy.headerChevronSymbolSize, weight: .semibold))
                        .foregroundStyle(theme.secondaryText)
                        .accessibilityHidden(true)
                }
                .frame(minHeight: CompactModelSummaryLayoutPolicy.disclosureMinimumHeight)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("更多运行信息")
            .accessibilityValue(configuration.isExpanded ? "已展开" : "已折叠")
            .accessibilityHint(ModelCapsuleAccessibilityMetadata.hint)
            .accessibilityInputLabels(["更多运行信息", "参考指标"])
            .accessibilityIdentifier("compact-model-runtime-details")

            if configuration.isExpanded {
                configuration.content
            }
        }
    }
}

private struct CompactModelSummaryIdentity: View {
    @Environment(\.appTheme) private var theme
    let snapshot: CompactModelSummarySnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "cpu")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(theme.accent)
                    .frame(width: 52, height: 52)
                    .background(theme.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 5) {
                    Text(CompactWorkbenchPolicy.modelTitle(snapshot.model))
                        .font(.title2.weight(.semibold)).foregroundStyle(theme.primaryText)
                        .lineLimit(2)
                    Text(snapshot.model.quantization)
                        .font(.subheadline).foregroundStyle(theme.secondaryText)
                }
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 10) {
                Text(snapshot.modeTitle)
                    .font(.footnote.weight(.medium)).foregroundStyle(theme.accent)
                    .padding(.horizontal, 9).padding(.vertical, 5)
                    .background(theme.accent.opacity(0.08), in: Capsule())
                if snapshot.isGenerating {
                    Text(snapshot.activityTitle).font(.footnote).foregroundStyle(theme.secondaryText)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(ModelCapsuleAccessibilityMetadata.label(model: snapshot.model))
        .accessibilityValue(snapshot.overviewValue)
        .accessibilityHint(ModelCapsuleAccessibilityMetadata.hint)
        .accessibilityInputLabels(ModelCapsuleAccessibilityMetadata.inputLabels(model: snapshot.model))
        .accessibilityIdentifier("compact-model-overview")
    }
}

private struct CompactModelSummaryStatusRow: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let title: String
    let value: String

    var body: some View {
        let expanded = CompactWorkbenchPolicy.stacksHeaderControls(dynamicTypeSize: dynamicTypeSize)
        let layout = expanded
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 6))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 12))
        layout {
            Text(title).font(.subheadline).foregroundStyle(theme.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(value).font(.subheadline.weight(.semibold)).foregroundStyle(theme.primaryText)
                .frame(maxWidth: .infinity, alignment: expanded ? .leading : .trailing)
        }
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
    }
}

struct CompactModelSummaryManageAction: View {
    @Environment(\.appTheme) private var theme
    let showModels: () -> Void

    var body: some View {
        Button(action: showModels) {
            Text("管理模型")
                .font(.headline).lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 16).padding(.vertical, 12)
                .frame(maxWidth: .infinity, minHeight: CompactModelSummaryLayoutPolicy.managementMinimumHeight)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(theme.inverseText)
        .background(theme.accent, in: RoundedRectangle(cornerRadius: 14))
        .accessibilityLabel(HeaderActionAccessibilityMetadata.modelLibraryLabel)
        .accessibilityValue(HeaderActionAccessibilityMetadata.modelLibraryValue)
        .accessibilityHint(HeaderActionAccessibilityMetadata.modelLibraryHint)
        .accessibilityInputLabels(HeaderActionAccessibilityMetadata.modelLibraryInputLabels + ["管理模型"])
        .accessibilityIdentifier(HeaderActionAccessibilityMetadata.modelLibraryIdentifier)
    }
}
