import Foundation
import PhotosUI
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct ModelLibraryView: View {
    @EnvironmentObject private var catalog: ModelCatalog
    @Environment(\.appTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.compactWorkbench) private var isCompact
    var isModal = false
    @State private var importTargetModel: LocalModel?
    @State private var pendingLicenseModel: LocalModel?
    @State private var approvedLicenseImportModel: LocalModel?
    @State private var pendingUninstallModel: LocalModel?
    @State private var isShowingFileImporter = false
    @State private var operationErrorTitle = "操作失败"
    @State private var operationErrorMessage: String?
    @State private var showsModelDetails = false
    @State private var showsModelLicenseLinks = false

    var body: some View {
        ZStack {
            if isModal {
                theme.canvas.ignoresSafeArea()
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
                        .padding(.top, isCompact ? 16 : WorkbenchPresentationPolicy.pageTopInset)
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
        .sheet(item: $pendingLicenseModel, onDismiss: continueApprovedLicenseImport) { model in
            ModelImportLicenseReview(
                model: model,
                confirm: {
                    approvedLicenseImportModel = model
                    pendingLicenseModel = nil
                },
                cancel: {
                    approvedLicenseImportModel = nil
                    pendingLicenseModel = nil
                }
            )
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

            if let operation = catalog.artifactOperation {
                ArtifactOperationStatusRow(operation: operation) { catalog.cancelArtifactImport() }
            }

            if ModelImportLicensePolicy.requiresConfirmation(for: model) {
                VStack(alignment: .leading, spacing: 0) {
                    Button { showsModelLicenseLinks.toggle() } label: {
                        HStack(spacing: 12) {
                            Label("模型许可与固定版本来源", systemImage: "doc.text")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(theme.primaryText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Image(systemName: showsModelLicenseLinks ? "chevron.down" : "chevron.right")
                                .font(.caption)
                                .foregroundStyle(theme.secondaryText)
                                .accessibilityHidden(true)
                        }
                        .frame(minHeight: ModelImportLicensePolicy.minimumActionHeight)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityValue(showsModelLicenseLinks ? "已展开" : "已折叠")
                    .accessibilityHint("展开后可主动打开官方许可、使用限制和固定版本来源；不会自动下载或加载模型。")
                    .accessibilityInputLabels(["模型许可与固定版本来源", "模型许可"])
                    .accessibilityIdentifier("model-license-sources")
                    if showsModelLicenseLinks {
                        ModelImportLicenseLinks().padding(.top, 8)
                    }
                }
            }

            if isCompact {
                ModelSelectorPanel(
                    models: catalog.models, selectedModelID: selectedModelID, selectedModel: model,
                    validation: validation, deploymentState: deploymentState
                )
                CompactModelFilesPanel(
                    validation: validation,
                    download: { catalog.simulateDownload(for: model) },
                    uninstall: { requestUninstall(model) },
                    scan: { Task { await catalog.refreshArtifactStatus(for: model) } },
                    importFiles: { requestImport(model) }
                )
                .disabled(catalog.isArtifactOperationInProgress)
                DeploymentPowerButton(
                    model: model, validation: validation, deploymentState: deploymentState,
                    toggle: { catalog.toggleDeployment(for: model) }
                )
                DisclosureGroup(isExpanded: $showsModelDetails) {
                    ModelDetailColumn(
                        model: model, validation: validation, report: report,
                        panelContentWidth: ModelDetailRowLayoutPolicy.panelContentWidth(forPanelWidth: size.width)
                    )
                    .padding(.top, 12)
                } label: {
                    Label("参数与运行计划", systemImage: "slider.horizontal.3")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(theme.primaryText)
                        .frame(minHeight: 44)
                }
                .tint(theme.secondaryText)
                .accessibilityIdentifier("compact-model-details")
            } else if layoutMode == .twoColumn {
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
                            scan: { Task { await catalog.refreshArtifactStatus(for: model) } },
                            importFiles: { requestImport(model) }
                        )
                        .disabled(catalog.isArtifactOperationInProgress)
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
                    scan: { Task { await catalog.refreshArtifactStatus(for: model) } },
                    importFiles: { requestImport(model) }
                )
                .disabled(catalog.isArtifactOperationInProgress)

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

    private func requestImport(_ model: LocalModel) {
        guard !catalog.isArtifactOperationInProgress else { return }
        approvedLicenseImportModel = nil
        if ModelImportLicensePolicy.requiresConfirmation(for: model) {
            pendingLicenseModel = model
        } else {
            presentFileImporter(for: model, didConfirmLicense: false)
        }
    }

    private func continueApprovedLicenseImport() {
        guard let model = approvedLicenseImportModel else { return }
        approvedLicenseImportModel = nil
        // The system file picker is presented only after the review sheet is gone.
        presentFileImporter(for: model, didConfirmLicense: true)
    }

    private func presentFileImporter(for model: LocalModel, didConfirmLicense: Bool) {
        guard !catalog.isArtifactOperationInProgress,
              ModelImportLicensePolicy.permitsFileImporter(for: model, didConfirmLicense: didConfirmLicense) else { return }
        importTargetModel = model
        isShowingFileImporter = true
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
            // This operation belongs to the catalog, not the selected page's
            // appearance task: navigating away must not cancel a file import.
            Task {
                do {
                    try await catalog.importArtifacts(for: targetModel, sourceURLs: urls)
                } catch is CancellationError {
                    return
                } catch {
                    operationErrorTitle = "导入失败"
                    operationErrorMessage = error.localizedDescription
                }
            }
        } catch {
            if (error as? CocoaError)?.code == .userCancelled { return }
            operationErrorTitle = "导入失败"
            operationErrorMessage = error.localizedDescription
        }
    }

    private func requestUninstall(_ model: LocalModel) {
        pendingUninstallModel = model
    }

    private func uninstall(_ model: LocalModel) {
        Task {
            do {
                try await catalog.uninstallArtifacts(for: model)
            } catch {
                operationErrorTitle = "卸载失败"
                operationErrorMessage = error.localizedDescription
            }
        }
    }
}

enum ModelImportLicensePolicy {
    static let minimumActionHeight: CGFloat = 48
    static let title = "导入前确认模型许可"
    static let notice = "模型不随 App 提供，也不会自动下载。请自行取得指定版本的模型文件，并在导入前阅读官方 Gemma 许可与使用限制。"
    static let confirmation = "我已阅读并同意适用的 Gemma 许可与使用限制，并自行确认有权使用该模型。"
    static let boundary = "本次确认只继续选择本地文件，不代表 App 授予模型许可，也不会下载、加载模型或启动推理。文件仍须通过可信 SHA-256 校验。"

    static func requiresConfirmation(for model: LocalModel) -> Bool {
        PinnedTextModel.supports(model)
    }

    static func permitsFileImporter(for model: LocalModel, didConfirmLicense: Bool) -> Bool {
        !requiresConfirmation(for: model) || didConfirmLicense
    }

    static func tokenizerDescription(for manifest: ModelArtifactManifest) -> String {
        manifest.tokenizerIsEmbedded ? "GGUF 内嵌词表" : manifest.tokenizerFileName
    }
}

private struct ModelImportLicenseLinks: View {
    @Environment(\.appTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            sourceLink("Gemma 官方许可", destination: PinnedTextModel.licenseURL, identifier: "model-license-terms")
            sourceLink("Gemma 官方使用限制", destination: PinnedTextModel.usePolicyURL, identifier: "model-license-use-policy")
            sourceLink("固定版本模型来源", destination: PinnedTextModel.sourceURL, identifier: "model-license-fixed-source")
            Text("来源：Hugging Face · ggml-org/gemma-3-1b-it-GGUF\n版本：\(PinnedTextModel.revision)")
                .font(.caption)
                .foregroundStyle(theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 6)
        }
        .accessibilityElement(children: .contain)
    }

    private func sourceLink(_ title: String, destination: URL, identifier: String) -> some View {
        Link(destination: destination) {
            Label(title, systemImage: "arrow.up.right.square")
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, minHeight: ModelImportLicensePolicy.minimumActionHeight, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(theme.accent)
        .accessibilityHint("仅在你点按后打开外部网页；不会附带对话、草稿或模型文件，不会在 App 中自动下载模型。")
        .accessibilityInputLabels([title])
        .accessibilityIdentifier(identifier)
    }
}

private struct ModelImportLicenseReview: View {
    @Environment(\.appTheme) private var theme
    let model: LocalModel
    let confirm: () -> Void
    let cancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                Text(ModelImportLicensePolicy.title)
                    .font(.headline)
                    .foregroundStyle(theme.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityAddTraits(.isHeader)
                Button(action: cancel) {
                    Text("取消")
                        .font(.subheadline.weight(.semibold))
                        .frame(minWidth: 48, minHeight: ModelImportLicensePolicy.minimumActionHeight)
                        .contentShape(Rectangle())
                }
                    .buttonStyle(.plain)
                    .accessibilityLabel("取消模型导入许可确认")
                    .accessibilityHint("关闭说明，不选择文件，不修改或加载模型。")
                    .accessibilityIdentifier("model-license-cancel")
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(model.name)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(theme.primaryText)
                        .accessibilityIdentifier("model-license-model-name")
                    Text(ModelImportLicensePolicy.notice)
                        .foregroundStyle(theme.secondaryText)
                    ModelImportLicenseLinks()
                    Text("仅接受文件：\(PinnedTextModel.fileName)\nSHA-256：\(PinnedTextModel.sha256)")
                        .font(.caption.monospaced())
                        .foregroundStyle(theme.secondaryText)
                    Text(ModelImportLicensePolicy.confirmation)
                        .font(.body.weight(.medium))
                        .foregroundStyle(theme.primaryText)
                    Text(ModelImportLicensePolicy.boundary)
                        .font(.footnote)
                        .foregroundStyle(theme.secondaryText)
                }
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 680, alignment: .leading)
                .padding(18)
                .frame(maxWidth: .infinity)
            }

            Button(action: confirm) {
                Text("我已阅读并同意，选择本地文件")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, minHeight: ModelImportLicensePolicy.minimumActionHeight)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(theme.accent, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(theme.canvas)
            }
            .buttonStyle(.plain)
            .accessibilityHint("确认你已自行阅读并同意模型许可后，打开系统 Files 选择器；不自动下载、不启动推理，不绕过文件校验。")
            .accessibilityInputLabels(["同意并选择文件", "选择本地文件"])
            .accessibilityIdentifier("model-license-confirm-import")
            .padding(18)
        }
        .background(theme.canvas)
        .tint(theme.accent)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .accessibilityIdentifier("model-license-review")
    }
}

struct ArtifactOperationStatusRow: View {
    @Environment(\.appTheme) private var theme
    let operation: ArtifactOperation
    let cancel: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            ProgressView()
                .tint(theme.accent)
                .accessibilityHidden(true)
            Text(operation.title)
                .font(.subheadline)
                .foregroundStyle(theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityLabel("\(operation.modelName)，\(operation.title)")
                .accessibilityIdentifier("artifact-operation-progress")
            if operation.kind == .importing {
                Button("取消", action: cancel)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(theme.accent)
                    .frame(minWidth: 44, minHeight: 44)
                    .disabled(!operation.canCancel)
                    .accessibilityLabel("取消导入")
                    .accessibilityHint("取消尚未提交的导入，保留原模型文件。")
                    .accessibilityInputLabels(["取消导入", "取消"])
                    .accessibilityIdentifier("artifact-import-cancel")
            }
        }
        .frame(minHeight: 44)
        .accessibilityElement(children: .contain)
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
    @Environment(\.compactWorkbench) private var isCompact
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let models: [LocalModel]
    @Binding var selectedModelID: UUID
    let selectedModel: LocalModel
    let validation: ArtifactValidationResult
    let deploymentState: ModelDeploymentState

    var body: some View {
        let badgesLayout = isCompact && dynamicTypeSize >= .xxxLarge
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(spacing: 8))

        VStack(alignment: .leading, spacing: 12) {
            if !isCompact {
                HStack(spacing: 10) {
                    Label("选择模型", systemImage: "slider.horizontal.3")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(theme.primaryText)

                    Spacer()

                    Text("\(models.count) 个候选")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(theme.tertiaryText)
                }
            }

            Group {
                if isCompact {
                    Menu {
                        Picker("选择模型", selection: $selectedModelID) {
                            ForEach(models) { model in
                                Text(CompactWorkbenchPolicy.modelTitle(model)).tag(model.id)
                            }
                        }
                    } label: {
                        CompactModelSelectionLabel(model: selectedModel)
                    }
                } else {
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
                }
            }
            .tint(theme.primaryText)
            .frame(
                maxWidth: .infinity,
                minHeight: ModelDeploymentControlLayoutPolicy.modelSelectorMinHeight,
                alignment: .leading
            )
            .padding(.horizontal, isCompact ? 0 : 12)
            .padding(.vertical, isCompact ? 2 : 12)
            .background(isCompact ? Color.clear : theme.recessedSurface,
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                if !isCompact {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(theme.accent.opacity(0.24), lineWidth: 1)
                }
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

            badgesLayout {
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
        .panelStyle(border: isCompact ? theme.border : theme.accent.opacity(0.24))
    }
}

private struct CompactModelSelectionLabel: View {
    @Environment(\.appTheme) private var theme
    let model: LocalModel

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "cpu")
                .font(.title3.weight(.medium))
                .foregroundStyle(theme.accent)
                .frame(width: 40, height: 40)
                .background(theme.chipSurface, in: RoundedRectangle(cornerRadius: 12))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 5) {
                Text(CompactWorkbenchPolicy.modelTitle(model))
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(theme.primaryText)
                    .lineLimit(ModelSelectorTextLayoutPolicy.nameLineLimit)
                Text("\(model.quantization) · \(model.sizeOnDisk)")
                    .font(.caption)
                    .foregroundStyle(theme.secondaryText)
                    .lineLimit(ModelSelectorTextLayoutPolicy.specLineLimit)
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "chevron.up.chevron.down")
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.secondaryText)
                .accessibilityHidden(true)
        }
        .contentShape(Rectangle())
    }
}

struct AvailabilityBadge: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.compactWorkbench) private var isCompact

    let availability: ArtifactAvailability
    var exposesAccessibility: Bool = true

    var body: some View {
        Text(isCompact ? CompactWorkbenchPolicy.fileStatus(availability) : availability.title)
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
    @Environment(\.compactWorkbench) private var isCompact

    let state: ModelDeploymentState
    var exposesAccessibility: Bool = true

    var body: some View {
        Text(isCompact ? state.localizedTitle : state.title)
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
    @Environment(\.appTheme) private var theme
    @Environment(\.compactWorkbench) private var isCompact

    let model: LocalModel
    let validation: ArtifactValidationResult
    let deploymentState: ModelDeploymentState
    let toggle: () -> Void

    private var isRunning: Bool {
        deploymentState == .running
    }

    var body: some View {
        let palette = theme.actionPalette(for: isRunning ? .destructive : .primary)

        Button(action: toggle) {
            HStack(spacing: isCompact ? 12 : 14) {
                ZStack {
                    Circle()
                        .fill(palette.iconSurface)
                    Image(systemName: isRunning ? "stop.fill" : "power")
                        .font(isCompact ? .title3.weight(.medium) : .title.weight(.semibold))
                }
                .frame(width: isCompact ? 36 : 58, height: isCompact ? 36 : 58)
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: ModelDeploymentPowerTextLayoutPolicy.verticalSpacing) {
                    Text(isCompact ? (isRunning ? "停止预览" : "启动预览") : (isRunning ? "关闭模型部署" : "启动模型部署"))
                        .font(isCompact ? .headline : .title3.weight(.semibold))
                        .lineLimit(ModelDeploymentPowerTextLayoutPolicy.titleLineLimit)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(isCompact ? "模拟推理" : deploymentSubtitle)
                        .font(.footnote)
                        .lineLimit(ModelDeploymentPowerTextLayoutPolicy.subtitleLineLimit)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundStyle(theme.secondaryText)
                }

                Spacer(minLength: 0)

                if !isCompact {
                    Image(systemName: isRunning ? "pause.circle.fill" : "play.circle.fill")
                        .font(.title2)
                        .opacity(0.84)
                }
            }
            .foregroundStyle(palette.foreground)
            .padding(isCompact ? 14 : 16)
            .frame(
                maxWidth: .infinity,
                minHeight: ModelDeploymentControlLayoutPolicy.powerButtonMinHeight
            )
            .background(isCompact ? theme.surface : palette.fill,
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isCompact ? theme.border : palette.border, lineWidth: 1)
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

    private var deploymentSubtitle: String {
        isRunning ? "正在展示本地模拟部署，不执行真实推理" : "启动本地模拟部署预览，不加载真实权重"
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
    @Environment(\.appTheme) private var theme

    let metadataAction: ModelDeploymentControlAccessibilityMetadata.ArtifactAction
    let availability: ArtifactAvailability
    let title: String
    let subtitle: String
    let icon: String
    let isDestructive: Bool
    let action: () -> Void

    var body: some View {
        let palette = theme.actionPalette(for: isDestructive ? .destructive : .secondary)

        Button(action: action) {
            VStack(alignment: .leading, spacing: ModelArtifactActionTextLayoutPolicy.verticalSpacing) {
                Image(systemName: icon)
                    .font(.system(size: 23, weight: .semibold))
                    .background {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(palette.iconSurface)
                            .padding(-5)
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                    }
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(ModelArtifactActionTextLayoutPolicy.titleLineLimit)
                    .fixedSize(horizontal: false, vertical: true)
                Text(subtitle)
                    .font(.caption2.weight(.bold))
                    .lineLimit(ModelArtifactActionTextLayoutPolicy.subtitleLineLimit)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundStyle(theme.secondaryText)
            }
            .foregroundStyle(palette.foreground)
            .frame(
                maxWidth: .infinity,
                minHeight: ModelArtifactActionTextLayoutPolicy.minimumHeight,
                alignment: .leading
            )
            .padding(12)
            .fixedSize(horizontal: false, vertical: true)
            .background(palette.fill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(palette.border, lineWidth: 1)
            }
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

    private var iconFill: Color {
        theme.actionPalette(for: model.family == "Gemma" ? .primary : .secondary).iconSurface
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
            if model.artifactManifest.tokenizerIsEmbedded {
                DetailRow(
                    title: "词表",
                    value: ModelImportLicensePolicy.tokenizerDescription(for: model.artifactManifest),
                    panelContentWidth: panelContentWidth
                )
            }
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

