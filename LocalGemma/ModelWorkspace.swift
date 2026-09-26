import Foundation
import PhotosUI
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct ModelLibraryView: View {
    @EnvironmentObject private var catalog: ModelCatalog
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
                        .padding(.top, WorkbenchPresentationPolicy.pageTopInset)
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
                withAnimation(
                    AppMotionAccessibilityPolicy.animation(
                        .spring(response: 0.28, dampingFraction: 0.86),
                        for: .modelSelection,
                        reduceMotion: reduceMotion
                    )
                ) {
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
                eyebrow: "MODEL LIBRARY",
                title: "模型库",
                subtitle: "模型与文件，一处管理。导入本地文件，查看校验与运行准备状态。"
            )

            if layoutMode == .twoColumn {
                let controlColumnWidth = layoutMode.controlColumnWidth(for: size)
                let detailColumnWidth = ModelDetailColumnLayoutPolicy.width(
                    for: size,
                    layoutMode: layoutMode
                )
                let detailPanelContentWidth = ModelDetailRowLayoutPolicy.panelContentWidth(
                    forPanelWidth: detailColumnWidth
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

                    ModelDetailColumn(
                        model: model,
                        validation: validation,
                        report: report,
                        panelContentWidth: detailPanelContentWidth
                    )
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

                ModelDetailColumn(
                    model: model,
                    validation: validation,
                    report: report,
                    panelContentWidth: ModelDetailRowLayoutPolicy.panelContentWidth(
                        forPanelWidth: size.width
                    )
                )
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

enum ModelSelectorTextLayoutPolicy {
    static let verticalSpacing: CGFloat = 2
    static let nameLineLimit = 2
    static let specLineLimit = 2

    static var allowsMultilineName: Bool { nameLineLimit > 1 }
    static var allowsMultilineSpec: Bool { specLineLimit > 1 }
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
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(theme.primaryText)

                Spacer()

                Text("\(models.count) 个候选")
                    .font(.system(size: 10, weight: .semibold))
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
                    VStack(alignment: .leading, spacing: ModelSelectorTextLayoutPolicy.verticalSpacing) {
                        Text(selectedModel.name)
                            .font(.headline.weight(.semibold))
                            .lineLimit(ModelSelectorTextLayoutPolicy.nameLineLimit)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("\(selectedModel.parameterCount) · \(selectedModel.quantization)")
                            .font(.caption.weight(.semibold))
                            .lineLimit(ModelSelectorTextLayoutPolicy.specLineLimit)
                            .fixedSize(horizontal: false, vertical: true)
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
                StatusBadge(
                    state: selectedModel.installState,
                    exposesAccessibility: ModelStatusBadgeAccessibilityPresentationPolicy
                        .exposesIndependentBadge(for: .modelSelector)
                )
                AvailabilityBadge(
                    availability: validation.availability,
                    exposesAccessibility: ModelStatusBadgeAccessibilityPresentationPolicy
                        .exposesIndependentBadge(for: .modelSelector)
                )
                DeploymentBadge(
                    state: deploymentState,
                    exposesAccessibility: ModelStatusBadgeAccessibilityPresentationPolicy
                        .exposesIndependentBadge(for: .modelSelector)
                )
            }
        }
        .panelStyle(border: theme.accent.opacity(0.24))
    }
}

struct AvailabilityBadge: View {
    @Environment(\.appTheme) private var theme

    let availability: ArtifactAvailability
    var exposesAccessibility: Bool = true

    var body: some View {
        Text(availability.title)
            .modifier(
                ModelStatusBadgeAppearanceModifier(
                    style: ModelStatusBadgeStylePolicy.style(
                        for: .artifact(availability),
                        theme: theme.mode
                    )
                )
            )
            .modifier(
                ArtifactStatusBadgeAccessibilityModifier(
                    availability: availability,
                    isEnabled: exposesAccessibility
                )
            )
    }
}

struct DeploymentBadge: View {
    @Environment(\.appTheme) private var theme

    let state: ModelDeploymentState
    var exposesAccessibility: Bool = true

    var body: some View {
        Text(state.title)
            .modifier(
                ModelStatusBadgeAppearanceModifier(
                    style: ModelStatusBadgeStylePolicy.style(
                        for: .deployment(state),
                        theme: theme.mode
                    )
                )
            )
            .modifier(
                DeploymentStatusBadgeAccessibilityModifier(
                    state: state,
                    isEnabled: exposesAccessibility
                )
            )
    }
}

enum ModelDeploymentPowerTextLayoutPolicy {
    static let verticalSpacing: CGFloat = 5
    static let titleLineLimit = 2
    static let subtitleLineLimit = 2

    static var allowsMultilineTitle: Bool { titleLineLimit > 1 }
    static var allowsMultilineSubtitle: Bool { subtitleLineLimit > 1 }
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
                        .font(.system(size: 25, weight: .semibold))
                }
                .frame(width: 58, height: 58)

                VStack(alignment: .leading, spacing: ModelDeploymentPowerTextLayoutPolicy.verticalSpacing) {
                    Text(isRunning ? "关闭模型部署" : "启动模型部署")
                        .font(.title3.weight(.semibold))
                        .lineLimit(ModelDeploymentPowerTextLayoutPolicy.titleLineLimit)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(deploymentSubtitle)
                        .font(.footnote.weight(.bold))
                        .lineLimit(ModelDeploymentPowerTextLayoutPolicy.subtitleLineLimit)
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
                .font(.system(size: 14, weight: .semibold))
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
                        .font(.footnote.weight(.bold))
                        .lineLimit(ModelArtifactUtilityTextLayoutPolicy.titleLineLimit)
                        .lineSpacing(ModelArtifactUtilityTextLayoutPolicy.titleLineSpacing)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity)
                }
                .compactUtilityStyle()
                .frame(minHeight: ModelArtifactUtilityTextLayoutPolicy.minimumHeight)
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
                        .font(.footnote.weight(.bold))
                        .lineLimit(ModelArtifactUtilityTextLayoutPolicy.titleLineLimit)
                        .lineSpacing(ModelArtifactUtilityTextLayoutPolicy.titleLineSpacing)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity)
                }
                .compactUtilityStyle()
                .frame(minHeight: ModelArtifactUtilityTextLayoutPolicy.minimumHeight)
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

enum ModelArtifactActionTextLayoutPolicy {
    static let verticalSpacing: CGFloat = 8
    static let titleLineLimit = 2
    static let subtitleLineLimit = 2
    static let minimumHeight: CGFloat = 86

    static var allowsMultilineTitle: Bool { titleLineLimit > 1 }
    static var allowsMultilineSubtitle: Bool { subtitleLineLimit > 1 }
}

enum ModelArtifactUtilityTextLayoutPolicy {
    static let titleLineLimit = 2
    static let titleLineSpacing: CGFloat = 1
    static let verticalPadding: CGFloat = 10
    static let minimumHeight: CGFloat = ModelArtifactActionLayoutPolicy.utilityButtonMinHeight

    static var allowsMultilineTitle: Bool {
        titleLineLimit > 1
    }

    static var usesSemanticTitleFont: Bool {
        true
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
            VStack(alignment: .leading, spacing: ModelArtifactActionTextLayoutPolicy.verticalSpacing) {
                Image(systemName: icon)
                    .font(.system(size: 23, weight: .semibold))
                Spacer(minLength: 0)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(ModelArtifactActionTextLayoutPolicy.titleLineLimit)
                    .fixedSize(horizontal: false, vertical: true)
                Text(subtitle)
                    .font(.caption2.weight(.bold))
                    .lineLimit(ModelArtifactActionTextLayoutPolicy.subtitleLineLimit)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(0.68)
            }
            .foregroundStyle(isDestructive ? .white : .black)
            .frame(
                maxWidth: .infinity,
                minHeight: ModelArtifactActionTextLayoutPolicy.minimumHeight,
                alignment: .leading
            )
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
    let panelContentWidth: CGFloat?

    init(
        model: LocalModel,
        validation: ArtifactValidationResult,
        report: RuntimePreparationReport,
        panelContentWidth: CGFloat? = nil
    ) {
        self.model = model
        self.validation = validation
        self.report = report
        self.panelContentWidth = panelContentWidth
    }

    var body: some View {
        VStack(spacing: 14) {
            ModelSummaryPanel(model: model, validation: validation)
            ModelParametersPanel(model: model, panelContentWidth: panelContentWidth)
            ModelPerformancePanel(
                model: model,
                validation: validation,
                report: report,
                panelContentWidth: panelContentWidth
            )
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

enum ModelSummaryTextLayoutPolicy {
    static let titleSummarySpacing: CGFloat = 5
    static let nameLineLimit = 2
    static let summaryLineLimit = 4
    static let summaryLineSpacing: CGFloat = 2
    static let capabilityLineLimit = 2
    static let capabilityLineSpacing: CGFloat = 1
    static let capabilityHorizontalPadding: CGFloat = 9
    static let capabilityVerticalPadding: CGFloat = 6
    static let validationLineLimit = 3
    static let validationLineSpacing: CGFloat = 1

    static var capabilityFont: Font {
        .caption2.weight(.bold)
    }

    static var validationFont: Font {
        .caption2.weight(.bold)
    }

    static var usesSemanticDynamicTypeFont: Bool { true }

    static var allowsMultilineName: Bool { nameLineLimit > 1 }
    static var allowsMultilineSummary: Bool { summaryLineLimit > 1 }
    static var allowsMultilineCapability: Bool { capabilityLineLimit > 1 }
    static var allowsMultilineValidation: Bool { validationLineLimit > 1 }

    enum ThemeRole: Equatable {
        case chipSurface
        case secondaryText
        case subtleBorder
    }

    static let capabilityBackgroundRole = ThemeRole.chipSurface
    static let capabilityForegroundRole = ThemeRole.secondaryText
    static let capabilityBorderRole = ThemeRole.subtleBorder
    static let validationForegroundRole = ThemeRole.secondaryText
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
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(model.family == "Gemma" ? theme.accent : theme.secondaryText)
                }
                .frame(width: 50, height: 50)

                VStack(alignment: .leading, spacing: ModelSummaryTextLayoutPolicy.titleSummarySpacing) {
                    Text(model.name)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(theme.primaryText)
                        .lineLimit(ModelSummaryTextLayoutPolicy.nameLineLimit)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(model.summary)
                        .font(.footnote.weight(.medium))
                        .lineSpacing(ModelSummaryTextLayoutPolicy.summaryLineSpacing)
                        .lineLimit(ModelSummaryTextLayoutPolicy.summaryLineLimit)
                        .foregroundStyle(theme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            FlowLayout(items: model.capabilities) { capability in
                Text(capability)
                    .font(ModelSummaryTextLayoutPolicy.capabilityFont)
                    .foregroundStyle(theme.secondaryText)
                    .lineSpacing(ModelSummaryTextLayoutPolicy.capabilityLineSpacing)
                    .lineLimit(ModelSummaryTextLayoutPolicy.capabilityLineLimit)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, ModelSummaryTextLayoutPolicy.capabilityHorizontalPadding)
                    .padding(.vertical, ModelSummaryTextLayoutPolicy.capabilityVerticalPadding)
                    .background(theme.chipSurface, in: Capsule())
                    .overlay {
                        Capsule()
                            .stroke(theme.subtleBorder, lineWidth: 1)
                    }
            }

            Text(validation.summary)
                .font(ModelSummaryTextLayoutPolicy.validationFont)
                .lineSpacing(ModelSummaryTextLayoutPolicy.validationLineSpacing)
                .lineLimit(ModelSummaryTextLayoutPolicy.validationLineLimit)
                .foregroundStyle(theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
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
    let panelContentWidth: CGFloat?

    init(model: LocalModel, panelContentWidth: CGFloat? = nil) {
        self.model = model
        self.panelContentWidth = panelContentWidth
    }

    var body: some View {
        DetailPanel(title: "参数", icon: "number.square.fill") {
            DetailRow(title: "模型家族", value: model.family, panelContentWidth: panelContentWidth)
            DetailRow(title: "参数规模", value: model.parameterCount, panelContentWidth: panelContentWidth)
            DetailRow(title: "量化格式", value: model.quantization, panelContentWidth: panelContentWidth)
            DetailRow(
                title: "上下文长度",
                value: "\(model.contextLength) tokens",
                panelContentWidth: panelContentWidth
            )
            DetailRow(
                title: "文件格式",
                value: model.artifactManifest.fileFormat,
                panelContentWidth: panelContentWidth
            )
            DetailRow(title: "包体大小", value: model.sizeOnDisk, panelContentWidth: panelContentWidth)
        }
    }
}

struct ModelPerformancePanel: View {
    let model: LocalModel
    let validation: ArtifactValidationResult
    let report: RuntimePreparationReport
    let panelContentWidth: CGFloat?

    init(
        model: LocalModel,
        validation: ArtifactValidationResult,
        report: RuntimePreparationReport,
        panelContentWidth: CGFloat? = nil
    ) {
        self.model = model
        self.validation = validation
        self.report = report
        self.panelContentWidth = panelContentWidth
    }

    var body: some View {
        DetailPanel(title: "性能", icon: "speedometer") {
            DetailRow(
                title: "预计速度",
                value: String(format: "%.1f tok/s", model.tokensPerSecond),
                panelContentWidth: panelContentWidth
            )
            DetailRow(title: "内存预算", value: model.memoryFootprint, panelContentWidth: panelContentWidth)
            DetailRow(title: "主后端", value: report.activeBackend.title, panelContentWidth: panelContentWidth)
            DetailRow(
                title: "回退后端",
                value: report.fallbackBackend.title,
                panelContentWidth: panelContentWidth
            )
            DetailRow(
                title: "KV cache",
                value: model.deploymentProfile.kvCachePolicy,
                panelContentWidth: panelContentWidth
            )
            DetailRow(
                title: "权重状态",
                value: validation.availability.title,
                panelContentWidth: panelContentWidth
            )
        }
    }
}

struct ModelAdvicePanel: View {
    let model: LocalModel
    let report: RuntimePreparationReport

    init(
        model: LocalModel,
        report: RuntimePreparationReport
    ) {
        self.model = model
        self.report = report
    }

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

enum ModelDetailPanelTextLayoutPolicy {
    static let titleLineLimit = 2
    static let titleLineSpacing: CGFloat = 1
    static let titleContentSpacing: CGFloat = 12

    static var allowsMultilineTitle: Bool {
        titleLineLimit > 1
    }

    static var usesSemanticTitleFont: Bool {
        true
    }
}

enum ModelDetailRowLayoutMode: Equatable {
    case stacked
    case horizontal
}

struct ModelDetailRowLayoutPlan: Equatable {
    let mode: ModelDetailRowLayoutMode
    let contentWidth: CGFloat
    let allowsHorizontal: Bool
}

enum ModelDetailRowLayoutPolicy {
    static let minimumTitleColumnWidth: CGFloat = 84
    static let minimumValueColumnWidth: CGFloat = 264
    static let horizontalSpacing: CGFloat = ModelDetailRowTextLayoutPolicy.horizontalSpacing
    static let stackedSpacing: CGFloat = 4
    static let panelHorizontalPadding: CGFloat = WorkbenchVisualStylePolicy.panelPadding

    static var horizontalContentWidthThreshold: CGFloat {
        minimumTitleColumnWidth + minimumValueColumnWidth + horizontalSpacing
    }

    static func panelContentWidth(forPanelWidth panelWidth: CGFloat) -> CGFloat {
        guard panelWidth.isFinite, panelWidth > 0 else {
            return 0
        }

        return max(panelWidth - panelHorizontalPadding * 2, 0)
    }

    static func resolve(
        contentWidth: CGFloat,
        dynamicTypeSize: DynamicTypeSize
    ) -> ModelDetailRowLayoutPlan {
        let validWidth = contentWidth.isFinite && contentWidth > 0 ? contentWidth : 0
        let allowsHorizontal = validWidth >= horizontalContentWidthThreshold
            && dynamicTypeSize < .xxxLarge

        return ModelDetailRowLayoutPlan(
            mode: allowsHorizontal ? .horizontal : .stacked,
            contentWidth: validWidth,
            allowsHorizontal: allowsHorizontal
        )
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
        VStack(
            alignment: .leading,
            spacing: ModelDetailPanelTextLayoutPolicy.titleContentSpacing
        ) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(theme.primaryText)
                .lineSpacing(ModelDetailPanelTextLayoutPolicy.titleLineSpacing)
                .lineLimit(ModelDetailPanelTextLayoutPolicy.titleLineLimit)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 9) {
                content
            }
        }
        .panelStyle()
    }
}

enum ModelDetailRowTextLayoutPolicy {
    static let horizontalSpacing: CGFloat = 12
    static let adviceIconSpacing: CGFloat = 9
    static let titleLineLimit = 2
    static let valueLineLimit = 2
    static let adviceLineLimit = 4
    static let adviceLineSpacing: CGFloat = 2
    static let minimumRowHeight: CGFloat = 28

    static var allowsMultilineTitle: Bool { titleLineLimit > 1 }
    static var allowsMultilineValue: Bool { valueLineLimit > 1 }
    static var allowsMultilineAdvice: Bool { adviceLineLimit > 1 }
}

struct DetailRow: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let title: String
    let value: String
    let panelContentWidth: CGFloat?

    init(title: String, value: String, panelContentWidth: CGFloat? = nil) {
        self.title = title
        self.value = value
        self.panelContentWidth = panelContentWidth
    }

    var body: some View {
        let plan = ModelDetailRowLayoutPolicy.resolve(
            contentWidth: panelContentWidth ?? 0,
            dynamicTypeSize: dynamicTypeSize
        )
        let layout = plan.mode == .horizontal
            ? AnyLayout(
                HStackLayout(
                    alignment: .firstTextBaseline,
                    spacing: ModelDetailRowLayoutPolicy.horizontalSpacing
                )
            )
            : AnyLayout(
                VStackLayout(
                    alignment: .leading,
                    spacing: ModelDetailRowLayoutPolicy.stackedSpacing
                )
            )

        layout {
            titleText(
                minWidth: plan.mode == .horizontal
                    ? ModelDetailRowLayoutPolicy.minimumTitleColumnWidth
                    : 0
            )
            valueText(
                textAlignment: plan.mode == .horizontal ? .trailing : .leading,
                frameAlignment: plan.mode == .horizontal ? .trailing : .leading,
                minWidth: plan.mode == .horizontal
                    ? ModelDetailRowLayoutPolicy.minimumValueColumnWidth
                    : 0
            )
        }
        .frame(maxWidth: .infinity, minHeight: ModelDetailRowTextLayoutPolicy.minimumRowHeight)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(ModelDetailRowAccessibilityMetadata.label(title: title))
        .accessibilityValue(ModelDetailRowAccessibilityMetadata.value(title: title, value: value))
        .accessibilityHint(ModelDetailRowAccessibilityMetadata.hint)
        .accessibilityInputLabels(ModelDetailRowAccessibilityMetadata.inputLabels(title: title))
        .accessibilityIdentifier(ModelDetailRowAccessibilityMetadata.identifier(title: title))
    }

    private func titleText(minWidth: CGFloat) -> some View {
        Text(title)
            .font(.caption.weight(.bold))
            .foregroundStyle(theme.tertiaryText)
            .lineLimit(ModelDetailRowTextLayoutPolicy.titleLineLimit)
            .fixedSize(horizontal: false, vertical: true)
            .frame(minWidth: minWidth, alignment: .leading)
    }

    private func valueText(
        textAlignment: TextAlignment,
        frameAlignment: Alignment,
        minWidth: CGFloat
    ) -> some View {
        Text(value)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(theme.primaryText)
            .multilineTextAlignment(textAlignment)
            .lineLimit(ModelDetailRowTextLayoutPolicy.valueLineLimit)
            .fixedSize(horizontal: false, vertical: true)
            .frame(minWidth: minWidth, maxWidth: .infinity, alignment: frameAlignment)
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
        HStack(alignment: .top, spacing: ModelDetailRowTextLayoutPolicy.adviceIconSpacing) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(tint)
                .frame(width: 16)

            Text(text)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(theme.secondaryText)
                .lineSpacing(ModelDetailRowTextLayoutPolicy.adviceLineSpacing)
                .lineLimit(ModelDetailRowTextLayoutPolicy.adviceLineLimit)
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

