import Foundation
import SwiftUI

enum ModelInstallState: String, CaseIterable, Identifiable, Sendable {
    case ready
    case simulated
    case notDownloaded

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ready:
            return "Ready"
        case .simulated:
            return "Simulation"
        case .notDownloaded:
            return "Not downloaded"
        }
    }

    var tint: Color {
        switch self {
        case .ready:
            return .green
        case .simulated:
            return .cyan
        case .notDownloaded:
            return .orange
        }
    }
}

enum ModelDeploymentState: String, Equatable, Sendable {
    case stopped
    case running

    var title: String {
        switch self {
        case .stopped:
            return "Stopped"
        case .running:
            return "Running"
        }
    }

    var localizedTitle: String {
        switch self {
        case .stopped:
            return "未启动"
        case .running:
            return "运行中"
        }
    }
}

struct LocalModel: Identifiable, Equatable, Sendable {
    let id: UUID
    var name: String
    var family: String
    var parameterCount: String
    var quantization: String
    var sizeOnDisk: String
    var contextLength: Int
    var tokensPerSecond: Double
    var memoryFootprint: String
    var installState: ModelInstallState
    var summary: String
    var capabilities: [String]
    var artifactManifest: ModelArtifactManifest
    var deploymentProfile: AppleSiliconDeploymentProfile

    init(
        id: UUID = UUID(),
        name: String,
        family: String,
        parameterCount: String,
        quantization: String,
        sizeOnDisk: String,
        contextLength: Int,
        tokensPerSecond: Double,
        memoryFootprint: String,
        installState: ModelInstallState,
        summary: String,
        capabilities: [String],
        artifactManifest: ModelArtifactManifest,
        deploymentProfile: AppleSiliconDeploymentProfile
    ) {
        self.id = id
        self.name = name
        self.family = family
        self.parameterCount = parameterCount
        self.quantization = quantization
        self.sizeOnDisk = sizeOnDisk
        self.contextLength = contextLength
        self.tokensPerSecond = tokensPerSecond
        self.memoryFootprint = memoryFootprint
        self.installState = installState
        self.summary = summary
        self.capabilities = capabilities
        self.artifactManifest = artifactManifest
        self.deploymentProfile = deploymentProfile
    }
}

struct ChatMessage: Identifiable, Codable, Equatable, Sendable {
    enum Role: String, Codable, Equatable, Sendable {
        case user
        case assistant
        case system
    }

    let id: UUID
    let role: Role
    var text: String
    var timestamp: Date
    var tokens: Int

    init(id: UUID = UUID(), role: Role, text: String, timestamp: Date = Date(), tokens: Int = 0) {
        self.id = id
        self.role = role
        self.text = text
        self.timestamp = timestamp
        self.tokens = tokens
    }
}

struct ChatSession: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var title: String
    var messages: [ChatMessage]
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        messages: [ChatMessage],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.messages = messages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

enum PromptTemplateCategory: String, CaseIterable, Identifiable, Sendable {
    case deployment
    case privacy
    case performance
    case writing
    case product
    case troubleshooting

    var id: String { rawValue }

    var title: String {
        switch self {
        case .deployment:
            return "部署"
        case .privacy:
            return "隐私"
        case .performance:
            return "性能"
        case .writing:
            return "写作"
        case .product:
            return "产品"
        case .troubleshooting:
            return "排障"
        }
    }

    var icon: String {
        switch self {
        case .deployment:
            return "bolt.horizontal.fill"
        case .privacy:
            return "lock.shield.fill"
        case .performance:
            return "cpu.fill"
        case .writing:
            return "pencil.and.scribble"
        case .product:
            return "shippingbox.fill"
        case .troubleshooting:
            return "wrench.and.screwdriver.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .deployment:
            return .cyan
        case .privacy:
            return .green
        case .performance:
            return .blue
        case .writing:
            return .orange
        case .product:
            return .mint
        case .troubleshooting:
            return .red
        }
    }
}

struct PresetPromptTemplate: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let category: PromptTemplateCategory
    let icon: String
    let prompt: String
    let requiresInput: Bool

    init(
        id: String, title: String, subtitle: String, category: PromptTemplateCategory,
        icon: String, prompt: String, requiresInput: Bool = false
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.category = category
        self.icon = icon
        self.prompt = prompt
        self.requiresInput = requiresInput
    }
}

enum PromptTemplateLibrary {
    static let everydayTemplates: [PresetPromptTemplate] = [
        PresetPromptTemplate(
            id: "everyday-polish", title: "润色文字", subtitle: "表达自然，保留原意",
            category: .writing, icon: "pencil.and.outline",
            prompt: "请润色下面的文字，保留原意，让表达更自然、简洁。直接给出修改后的版本：\n\n",
            requiresInput: true
        ),
        PresetPromptTemplate(
            id: "everyday-summary", title: "总结要点", subtitle: "长文变成清晰重点",
            category: .writing, icon: "text.alignleft",
            prompt: "请总结下面的内容：先用一句话概括，再列出关键要点。只依据原文，不补充未经证实的信息：\n\n",
            requiresInput: true
        ),
        PresetPromptTemplate(
            id: "everyday-translate", title: "中英互译", subtitle: "准确翻译，自然表达",
            category: .writing, icon: "character.bubble",
            prompt: "请将下面的中文翻译成英文，或将英文翻译成简体中文。保留原文的语气和格式，直接给出译文：\n\n",
            requiresInput: true
        ),
        PresetPromptTemplate(
            id: "everyday-plan", title: "行动计划", subtitle: "把想法拆成下一步",
            category: .product, icon: "checklist",
            prompt: "请根据下面的目标和限制，整理一份简洁可执行的行动计划，列出优先级和第一步。信息不足时先问必要的问题：\n\n",
            requiresInput: true
        )
    ]

    static let technicalTemplates: [PresetPromptTemplate] = [
        PresetPromptTemplate(
            id: "iphone-deployment-plan",
            title: "部署方案",
            subtitle: "端侧 runtime 规划",
            category: .deployment,
            icon: "bolt.horizontal.fill",
            prompt: "请给我一份 iPhone 本地部署 Gemma 1.5B 的执行方案，包含模型格式、加载流程、内存预算、后端选择和主要风险。"
        ),
        PresetPromptTemplate(
            id: "offline-privacy-review",
            title: "隐私评审",
            subtitle: "离线安全说明",
            category: .privacy,
            icon: "lock.shield.fill",
            prompt: "请从产品和工程角度说明这个本地大模型功能的隐私保护策略，覆盖提示词、上下文、模型文件、日志和网络访问。"
        ),
        PresetPromptTemplate(
            id: "ane-metal-optimization",
            title: "芯片优化",
            subtitle: "ANE / Metal 策略",
            category: .performance,
            icon: "cpu.fill",
            prompt: "请列出在 A17 Pro 或 M 系列芯片上优化端侧大模型推理的方案，重点说明 Core ML、ANE、Metal fallback、KV cache 和热状态调度。"
        ),
        PresetPromptTemplate(
            id: "technical-summary",
            title: "技术总结",
            subtitle: "结构化输出",
            category: .writing,
            icon: "doc.text.fill",
            prompt: "请把下面主题整理成一份清晰的技术总结，使用目标、方案、权衡、风险、下一步这五个部分来组织：iPhone 本地部署小模型。"
        ),
        PresetPromptTemplate(
            id: "product-copy",
            title: "产品文案",
            subtitle: "发布说明草稿",
            category: .product,
            icon: "megaphone.fill",
            prompt: "请为一个 iPhone 本地大模型 App 写一段简洁的产品发布文案，强调离线、隐私、低延迟和可控部署，不要夸大真实能力。"
        ),
        PresetPromptTemplate(
            id: "runtime-debug-checklist",
            title: "排障清单",
            subtitle: "导入与运行检查",
            category: .troubleshooting,
            icon: "wrench.and.screwdriver.fill",
            prompt: "请给我一份本地模型无法启动时的排障清单，覆盖模型文件、tokenizer、SHA-256 校验、后端选择、内存预算和模拟回退。"
        )
    ]

    static let defaultTemplates = everydayTemplates + technicalTemplates

    static func templates(in category: PromptTemplateCategory?) -> [PresetPromptTemplate] {
        guard let category else {
            return defaultTemplates
        }
        return defaultTemplates.filter { $0.category == category }
    }
}

struct OptimizerMetric: Identifiable {
    let id = UUID()
    let label: String
    let value: String
    let detail: String
    let progress: Double
    let tint: Color
}

struct OptimizationSwitch: Identifiable, Equatable, Sendable {
    let id = UUID()
    let title: String
    let subtitle: String
    var isEnabled: Bool
}

enum ComputeBackend: String, CaseIterable, Identifiable, Sendable {
    case coreMLANE
    case metalPerformanceShaders
    case mlxSwift
    case llamaCpp

    var id: String { rawValue }

    var title: String {
        switch self {
        case .coreMLANE:
            return "Core ML + ANE"
        case .metalPerformanceShaders:
            return "Metal fallback"
        case .mlxSwift:
            return "MLX Swift"
        case .llamaCpp:
            return "llama.cpp"
        }
    }

    var shortTitle: String {
        switch self {
        case .coreMLANE:
            return "ANE"
        case .metalPerformanceShaders:
            return "Metal"
        case .mlxSwift:
            return "MLX"
        case .llamaCpp:
            return "llama.cpp"
        }
    }
}

enum ArtifactAvailability: String, Equatable, Sendable {
    case missing
    case staged
    case verified

    var title: String {
        switch self {
        case .missing:
            return "Missing"
        case .staged:
            return "Staged"
        case .verified:
            return "Verified"
        }
    }
}

struct ModelArtifactManifest: Equatable, Sendable {
    let modelFileName: String
    let tokenizerFileName: String
    let fileFormat: String
    let storageDirectory: String
    let expectedSHA256: String
    let allowsNetworkDownload: Bool
    let importInstruction: String

    var requiredFiles: [String] {
        [modelFileName, tokenizerFileName]
    }
}

struct ArtifactFileStatus: Equatable, Sendable {
    let fileName: String
    let exists: Bool
    let byteCount: Int64?
    let isDirectory: Bool

    init(fileName: String, exists: Bool, byteCount: Int64? = nil, isDirectory: Bool = false) {
        self.fileName = fileName
        self.exists = exists
        self.byteCount = byteCount
        self.isDirectory = isDirectory
    }
}

struct ArtifactValidationResult: Equatable, Sendable {
    let availability: ArtifactAvailability
    let fileStatuses: [ArtifactFileStatus]
    let expectedSHA256: String
    let observedSHA256: String?
    let hasConcreteExpectedHash: Bool
    let hasVerifiedHash: Bool
    let networkDownloadAllowed: Bool

    var missingFiles: [String] {
        fileStatuses.filter { $0.exists == false }.map(\.fileName)
    }

    var presentFiles: [String] {
        fileStatuses.filter(\.exists).map(\.fileName)
    }

    var hasRequiredFiles: Bool {
        missingFiles.isEmpty
    }

    var canPromoteToRealRuntime: Bool {
        availability == .verified
    }

    var summary: String {
        switch availability {
        case .missing:
            return "缺少 \(missingFiles.joined(separator: ", "))"
        case .staged:
            return hasConcreteExpectedHash ? "等待 SHA-256 校验通过" : "等待登记官方 SHA-256"
        case .verified:
            return "本地 artifact 已通过校验"
        }
    }
}

enum LocalArtifactValidator {
    static func validate(
        manifest: ModelArtifactManifest,
        presentFiles: Set<String>,
        observedSHA256: String? = nil
    ) -> ArtifactValidationResult {
        let fileStatuses = manifest.requiredFiles.map { fileName in
            ArtifactFileStatus(fileName: fileName, exists: presentFiles.contains(fileName))
        }

        return validate(
            manifest: manifest,
            fileStatuses: fileStatuses,
            observedSHA256: observedSHA256
        )
    }

    static func validate(
        manifest: ModelArtifactManifest,
        in directoryURL: URL,
        observedSHA256: String? = nil,
        fileManager: FileManager = .default
    ) -> ArtifactValidationResult {
        let fileStatuses = manifest.requiredFiles.map { fileName in
            let url = directoryURL.appendingPathComponent(fileName)
            var isDirectory = ObjCBool(false)
            let exists = fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory)
            let attributes = exists ? try? fileManager.attributesOfItem(atPath: url.path) : nil
            let byteCount = (attributes?[.size] as? NSNumber)?.int64Value
            return ArtifactFileStatus(
                fileName: fileName,
                exists: exists,
                byteCount: byteCount,
                isDirectory: isDirectory.boolValue
            )
        }

        return validate(
            manifest: manifest,
            fileStatuses: fileStatuses,
            observedSHA256: observedSHA256
        )
    }

    static func validate(
        manifest: ModelArtifactManifest,
        fileStatuses: [ArtifactFileStatus],
        observedSHA256: String? = nil
    ) -> ArtifactValidationResult {
        let requiredFileNames = Set(manifest.requiredFiles)
        let relevantStatuses = fileStatuses.filter { requiredFileNames.contains($0.fileName) }
        let missingFileNames = manifest.requiredFiles.filter { fileName in
            relevantStatuses.contains { $0.fileName == fileName && $0.exists } == false
        }

        let normalizedExpectedHash = manifest.expectedSHA256.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let normalizedObservedHash = observedSHA256?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let hasConcreteExpectedHash = isConcreteSHA256(normalizedExpectedHash)
        let hasVerifiedHash = hasConcreteExpectedHash && normalizedObservedHash == normalizedExpectedHash

        let availability: ArtifactAvailability
        if missingFileNames.isEmpty == false {
            availability = .missing
        } else if hasVerifiedHash {
            availability = .verified
        } else {
            availability = .staged
        }

        let statusesByName = Dictionary(uniqueKeysWithValues: relevantStatuses.map { ($0.fileName, $0) })
        let orderedStatuses = manifest.requiredFiles.map { fileName in
            statusesByName[fileName] ?? ArtifactFileStatus(fileName: fileName, exists: false)
        }

        return ArtifactValidationResult(
            availability: availability,
            fileStatuses: orderedStatuses,
            expectedSHA256: manifest.expectedSHA256,
            observedSHA256: observedSHA256,
            hasConcreteExpectedHash: hasConcreteExpectedHash,
            hasVerifiedHash: hasVerifiedHash,
            networkDownloadAllowed: manifest.allowsNetworkDownload
        )
    }

    static func isConcreteSHA256(_ value: String) -> Bool {
        value.range(of: #"^[0-9a-fA-F]{64}$"#, options: .regularExpression) != nil
    }
}

struct AppleSiliconDeploymentProfile: Equatable, Sendable {
    let preferredChipClass: String
    let recommendedMemoryBudget: String
    let primaryBackend: ComputeBackend
    let fallbackBackend: ComputeBackend
    let kvCachePolicy: String
    let thermalStrategy: String
    let maxActiveTokens: Int
}

struct RuntimePreparationReport: Equatable, Sendable {
    let modelName: String
    let availability: ArtifactAvailability
    let canRunRealWeights: Bool
    let networkDownloadAllowed: Bool
    let activeBackend: ComputeBackend
    let fallbackBackend: ComputeBackend
    let requiredFiles: [String]
    let blockers: [String]
    let nextSteps: [String]
}

struct InferenceRequest: Equatable, Sendable {
    let prompt: String
    let model: LocalModel
    let artifactAvailability: ArtifactAvailability

    init(prompt: String, model: LocalModel, artifactAvailability: ArtifactAvailability = .missing) {
        self.prompt = prompt
        self.model = model
        self.artifactAvailability = artifactAvailability
    }
}

struct InferenceResult: Equatable, Sendable {
    let text: String
    let isSimulated: Bool
    let backend: ComputeBackend
    let preparationReport: RuntimePreparationReport
}

protocol LocalInferenceRuntime: Sendable {
    var runtimeName: String { get }
    func prepare(for model: LocalModel, availability: ArtifactAvailability) -> RuntimePreparationReport
    func generate(_ request: InferenceRequest) -> InferenceResult
}

enum LocalRuntimePlanner {
    static func preparationReport(
        for model: LocalModel,
        availability: ArtifactAvailability = .missing
    ) -> RuntimePreparationReport {
        let canRunRealWeights = availability == .verified
        let blockers: [String]
        let nextSteps: [String]

        switch availability {
        case .missing:
            blockers = ["真实权重和 tokenizer 尚未导入，保持模拟推理。"]
            nextSteps = [
                model.artifactManifest.importInstruction,
                "导入后校验 SHA-256，再切换到 \(model.deploymentProfile.primaryBackend.title)。"
            ]
        case .staged:
            blockers = ["模型文件已暂存，但完整性哈希尚未验证。"]
            nextSteps = [
                "校验 \(model.artifactManifest.expectedSHA256)",
                "验证通过后启用 \(model.deploymentProfile.primaryBackend.title)。"
            ]
        case .verified:
            blockers = []
            nextSteps = [
                "预热 \(model.deploymentProfile.primaryBackend.title) 执行图。",
                "启用 \(model.deploymentProfile.kvCachePolicy) 并按热状态调整 token budget。"
            ]
        }

        return RuntimePreparationReport(
            modelName: model.name,
            availability: availability,
            canRunRealWeights: canRunRealWeights,
            networkDownloadAllowed: model.artifactManifest.allowsNetworkDownload,
            activeBackend: model.deploymentProfile.primaryBackend,
            fallbackBackend: model.deploymentProfile.fallbackBackend,
            requiredFiles: model.artifactManifest.requiredFiles,
            blockers: blockers,
            nextSteps: nextSteps
        )
    }

    static func preparationReport(
        for model: LocalModel,
        validation: ArtifactValidationResult
    ) -> RuntimePreparationReport {
        let blockers: [String]
        let nextSteps: [String]

        switch validation.availability {
        case .missing:
            blockers = ["缺少本地 artifact：\(validation.missingFiles.joined(separator: ", "))。"]
            nextSteps = [
                model.artifactManifest.importInstruction,
                "将文件放入 \(model.artifactManifest.storageDirectory)，再重新扫描 artifact。"
            ]
        case .staged:
            if validation.hasConcreteExpectedHash {
                blockers = ["已找到模型文件，但 SHA-256 尚未匹配 \(validation.expectedSHA256)。"]
                nextSteps = [
                    "对 \(model.artifactManifest.modelFileName) 计算 SHA-256。",
                    "校验通过后启用 \(model.deploymentProfile.primaryBackend.title)。"
                ]
            } else {
                blockers = ["已找到模型文件，但 manifest 还没有登记可校验的官方 SHA-256。"]
                nextSteps = [
                    "登记 Gemma 1.5B artifact 的官方 SHA-256。",
                    "完成哈希校验后再允许真实 runtime 启动。"
                ]
            }
        case .verified:
            blockers = []
            nextSteps = [
                "预热 \(model.deploymentProfile.primaryBackend.title) 执行图。",
                "启用 \(model.deploymentProfile.kvCachePolicy) 并按热状态调整 token budget。"
            ]
        }

        return RuntimePreparationReport(
            modelName: model.name,
            availability: validation.availability,
            canRunRealWeights: validation.canPromoteToRealRuntime,
            networkDownloadAllowed: validation.networkDownloadAllowed,
            activeBackend: model.deploymentProfile.primaryBackend,
            fallbackBackend: model.deploymentProfile.fallbackBackend,
            requiredFiles: model.artifactManifest.requiredFiles,
            blockers: blockers,
            nextSteps: nextSteps
        )
    }
}

@MainActor
final class ModelCatalog: ObservableObject {
    @Published var selectedModel: LocalModel
    @Published var models: [LocalModel]
    @Published private var artifactValidations: [UUID: ArtifactValidationResult]
    @Published private var deploymentStates: [UUID: ModelDeploymentState]
    @Published private(set) var artifactOperation: ArtifactOperation?

    private let artifactDirectoryURL: URL
    private let fileAccess: ArtifactFileAccess
    private var importControl: ArtifactImportControl?
    private var initialScanTask: Task<Void, Never>?

    var isArtifactOperationInProgress: Bool { artifactOperation != nil }

    init(
        models: [LocalModel] = ModelCatalog.defaultModels,
        autoScanLocalArtifacts: Bool = false,
        artifactDirectoryURL: URL = ModelArtifactStore.defaultDirectoryURL(),
        fileManager: FileManager = .default
    ) {
        let resolvedModels = models.isEmpty ? ModelCatalog.defaultModels : models
        self.artifactDirectoryURL = artifactDirectoryURL
        self.fileAccess = ArtifactFileAccess(fileManager)
        self.models = resolvedModels
        self.selectedModel = resolvedModels[0]
        self.artifactValidations = Dictionary(
            uniqueKeysWithValues: resolvedModels.map { model in
                (
                    model.id,
                    LocalArtifactValidator.validate(
                        manifest: model.artifactManifest,
                        presentFiles: []
                    )
                )
            }
        )
        self.deploymentStates = Dictionary(
            uniqueKeysWithValues: resolvedModels.map { model in
                (model.id, ModelDeploymentState.stopped)
            }
        )

        if autoScanLocalArtifacts {
            initialScanTask = Task { [weak self] in
                await self?.refreshAllArtifactStatuses()
            }
        }
    }

    func select(_ model: LocalModel) {
        guard let updated = models.first(where: { $0.id == model.id }) else { return }
        selectedModel = updated
    }

    func markSimulationReady(for model: LocalModel) {
        guard let index = models.firstIndex(where: { $0.id == model.id }) else { return }
        models[index].installState = .simulated
        models[index].summary = "模型权重暂未下载，当前使用本地模拟器验证界面、流式输出和部署路径。"
        selectedModel = models[index]
    }

    func validation(for model: LocalModel) -> ArtifactValidationResult {
        artifactValidations[model.id] ?? LocalArtifactValidator.validate(
            manifest: model.artifactManifest,
            presentFiles: []
        )
    }

    func deploymentState(for model: LocalModel) -> ModelDeploymentState {
        deploymentStates[model.id] ?? .stopped
    }

    func isDeploymentRunning(for model: LocalModel) -> Bool {
        deploymentState(for: model) == .running
    }

    func startDeployment(for model: LocalModel) {
        guard models.contains(where: { $0.id == model.id }) else { return }

        var updatedStates = Dictionary(
            uniqueKeysWithValues: models.map { listedModel in
                (listedModel.id, ModelDeploymentState.stopped)
            }
        )
        updatedStates[model.id] = .running
        deploymentStates = updatedStates
        select(model)
    }

    func stopDeployment(for model: LocalModel) {
        var updatedStates = deploymentStates
        updatedStates[model.id] = .stopped
        deploymentStates = updatedStates
    }

    func toggleDeployment(for model: LocalModel) {
        if isDeploymentRunning(for: model) {
            stopDeployment(for: model)
        } else {
            startDeployment(for: model)
        }
    }

    func waitForInitialArtifactScan() async {
        await initialScanTask?.value
    }

    func refreshArtifactStatus(for model: LocalModel) async {
        guard !isArtifactOperationInProgress else { return }
        artifactOperation = ArtifactOperation(modelID: model.id, modelName: model.name, kind: .scanning)
        defer { artifactOperation = nil }
        let validation = await ArtifactIOWorker.shared.validate(
            model: model, directory: artifactDirectoryURL,
            fileAccess: fileAccess
        )
        apply(validation: validation, to: model)
    }

    func refreshAllArtifactStatuses() async {
        guard !isArtifactOperationInProgress else { return }
        artifactOperation = ArtifactOperation(modelID: selectedModel.id, modelName: "本地模型", kind: .scanning)
        defer { artifactOperation = nil }
        for model in models {
            let validation = await ArtifactIOWorker.shared.validate(
                model: model, directory: artifactDirectoryURL, fileAccess: fileAccess
            )
            apply(validation: validation, to: model)
        }
    }

    func importArtifacts(for model: LocalModel, sourceURLs: [URL]) async throws {
        guard !isArtifactOperationInProgress else { throw ArtifactImportError.operationInProgress }
        let operation = ArtifactOperation(modelID: model.id, modelName: model.name, kind: .importing)
        let control = ArtifactImportControl()
        artifactOperation = operation
        importControl = control
        defer {
            artifactOperation = nil
            importControl = nil
        }
        let validation = try await withTaskCancellationHandler {
            try await ArtifactIOWorker.shared.importArtifacts(
                manifest: model.artifactManifest, sources: sourceURLs, destination: artifactDirectoryURL,
                fileAccess: fileAccess, control: control
            ) { [weak self] progress in
                Task { @MainActor in
                    guard let self, var current = self.artifactOperation, current.id == operation.id,
                          progress.phase.rawValue >= current.progress.phase.rawValue else { return }
                    if progress.phase == current.progress.phase,
                       progress.completedBytes < current.progress.completedBytes { return }
                    current.progress = progress
                    self.artifactOperation = current
                }
            }
        } onCancel: {
            control.cancel()
        }
        apply(validation: validation, to: model)
    }

    @discardableResult
    func cancelArtifactImport() -> Bool {
        importControl?.cancel() ?? false
    }

    func uninstallArtifacts(for model: LocalModel) async throws {
        guard !isArtifactOperationInProgress else { throw ArtifactImportError.operationInProgress }
        artifactOperation = ArtifactOperation(modelID: model.id, modelName: model.name, kind: .uninstalling)
        defer { artifactOperation = nil }
        let validation = try await ArtifactIOWorker.shared.remove(
            model: model, directory: artifactDirectoryURL,
            fileAccess: fileAccess
        )
        stopDeployment(for: model)
        apply(
            validation: validation,
            to: model,
            summary: "已移除本机托管的模型文件；当前模型回到未下载状态，不会自动联网获取权重。",
            installState: .notDownloaded
        )
    }

    func stageManualImportPreview(for model: LocalModel) {
        guard !isArtifactOperationInProgress else { return }
        let validation = LocalArtifactValidator.validate(
            manifest: model.artifactManifest,
            presentFiles: Set(model.artifactManifest.requiredFiles)
        )
        apply(
            validation: validation,
            to: model,
            summary: "已模拟把本地文件放入 \(model.artifactManifest.storageDirectory)，但还没有通过 SHA-256 校验；推理继续走本地模拟输出。",
            installState: .simulated
        )
    }

    func simulateDownload(for model: LocalModel) {
        guard !isArtifactOperationInProgress else { return }
        let validation = LocalArtifactValidator.validate(
            manifest: model.artifactManifest,
            presentFiles: Set(model.artifactManifest.requiredFiles)
        )
        apply(
            validation: validation,
            to: model,
            summary: "已模拟下载并暂存模型文件；当前仍需 SHA-256 校验，真实权重不会自动联网下载。",
            installState: .simulated
        )
    }

    private func apply(
        validation: ArtifactValidationResult,
        to model: LocalModel,
        summary: String? = nil,
        installState: ModelInstallState? = nil
    ) {
        artifactValidations[model.id] = validation
        guard let index = models.firstIndex(where: { $0.id == model.id }) else { return }

        switch validation.availability {
        case .missing:
            models[index].installState = installState ?? models[index].installState
            models[index].summary = summary ?? "未在 \(model.artifactManifest.storageDirectory) 找到必需文件；当前保持模拟推理，不会自动下载权重。"
        case .staged:
            models[index].installState = installState ?? .simulated
            models[index].summary = summary ?? "本地文件已暂存，但缺少可验证 SHA-256；当前保持模拟推理，等待手动校验。"
        case .verified:
            models[index].installState = installState ?? .ready
            models[index].summary = summary ?? "本地 artifact 已通过校验，可以切换到真实端侧 runtime 接入点。"
        }

        if selectedModel.id == model.id {
            selectedModel = models[index]
        }
    }

    nonisolated private static func artifactManifest(
        modelFileName: String,
        tokenizerFileName: String,
        fileFormat: String,
        expectedSHA256: String
    ) -> ModelArtifactManifest {
        ModelArtifactManifest(
            modelFileName: modelFileName,
            tokenizerFileName: tokenizerFileName,
            fileFormat: fileFormat,
            storageDirectory: "Application Support/LocalModels",
            expectedSHA256: expectedSHA256,
            allowsNetworkDownload: false,
            importInstruction: "通过 Finder、Files 或 Xcode 手动导入模型文件；当前版本不会自动下载权重。"
        )
    }

    nonisolated private static func deploymentProfile(
        primary: ComputeBackend,
        fallback: ComputeBackend,
        memoryBudget: String,
        maxActiveTokens: Int
    ) -> AppleSiliconDeploymentProfile {
        AppleSiliconDeploymentProfile(
            preferredChipClass: "A17 Pro / M 系列",
            recommendedMemoryBudget: memoryBudget,
            primaryBackend: primary,
            fallbackBackend: fallback,
            kvCachePolicy: "Paged KV cache",
            thermalStrategy: "根据 ProcessInfo thermalState 动态降低输出长度和并发",
            maxActiveTokens: maxActiveTokens
        )
    }

    nonisolated static let defaultModels: [LocalModel] = [
        LocalModel(
            name: "Gemma 1.5B Local",
            family: "Gemma",
            parameterCount: "1.5B",
            quantization: "4-bit Q4_K_M",
            sizeOnDisk: "约 1.1 GB",
            contextLength: 4096,
            tokensPerSecond: 36,
            memoryFootprint: "1.8 GB unified memory",
            installState: .simulated,
            summary: "主打 iPhone 端本地推理。当前不下载权重，使用模拟引擎预留 Core ML / Metal 加速接入点。",
            capabilities: ["离线对话", "中文优化", "隐私本地", "Metal 预热"],
            artifactManifest: artifactManifest(
                modelFileName: "gemma-1.5b-it-q4.mlmodelc",
                tokenizerFileName: "gemma-tokenizer.model",
                fileFormat: "Core ML compiled package",
                expectedSHA256: "manual-import-required"
            ),
            deploymentProfile: deploymentProfile(
                primary: .coreMLANE,
                fallback: .metalPerformanceShaders,
                memoryBudget: "1.8 GB unified memory",
                maxActiveTokens: 4096
            )
        ),
        LocalModel(
            name: "Qwen3 0.6B",
            family: "Qwen",
            parameterCount: "0.6B",
            quantization: "4-bit Int4",
            sizeOnDisk: "约 550 MB",
            contextLength: 8192,
            tokensPerSecond: 52,
            memoryFootprint: "1.2 GB unified memory",
            installState: .notDownloaded,
            summary: "轻量模型候选，用于低内存设备快速响应。",
            capabilities: ["文本生成", "快速启动", "低功耗"],
            artifactManifest: artifactManifest(
                modelFileName: "qwen3-0.6b-int4.mlmodelc",
                tokenizerFileName: "qwen-tokenizer.json",
                fileFormat: "Core ML compiled package",
                expectedSHA256: "manual-import-required"
            ),
            deploymentProfile: deploymentProfile(
                primary: .coreMLANE,
                fallback: .metalPerformanceShaders,
                memoryBudget: "1.2 GB unified memory",
                maxActiveTokens: 8192
            )
        ),
        LocalModel(
            name: "LFM2 1.2B",
            family: "LFM",
            parameterCount: "1.2B",
            quantization: "Q5",
            sizeOnDisk: "约 1.4 GB",
            contextLength: 4096,
            tokensPerSecond: 29,
            memoryFootprint: "2.1 GB unified memory",
            installState: .notDownloaded,
            summary: "多模型扩展位，展示下载源、部署策略和推理能力。",
            capabilities: ["工具调用", "长文本", "私有知识"],
            artifactManifest: artifactManifest(
                modelFileName: "lfm2-1.2b-q5.gguf",
                tokenizerFileName: "lfm2-tokenizer.json",
                fileFormat: "GGUF",
                expectedSHA256: "manual-import-required"
            ),
            deploymentProfile: deploymentProfile(
                primary: .llamaCpp,
                fallback: .metalPerformanceShaders,
                memoryBudget: "2.1 GB unified memory",
                maxActiveTokens: 4096
            )
        )
    ]
}

@MainActor
final class DeviceOptimizer: ObservableObject {
    static let offlinePrivacyGuardTitle = "Offline privacy guard"

    @Published var metrics: [OptimizerMetric]
    @Published var switches: [OptimizationSwitch]
    @Published var thermalState: String
    @Published var deploymentReadiness: Double

    var isOfflinePrivacyGuardEnabled: Bool {
        switches.first { $0.title == Self.offlinePrivacyGuardTitle }?.isEnabled ?? false
    }

    init() {
        self.metrics = [
            OptimizerMetric(
                label: "Neural Engine",
                value: "规划中",
                detail: "Core ML 编译后启用 ANE 分层调度",
                progress: 0.62,
                tint: .cyan
            ),
            OptimizerMetric(
                label: "Metal Kernels",
                value: "已预热",
                detail: "模拟 KV cache 与矩阵算子预热流程",
                progress: 0.82,
                tint: .blue
            ),
            OptimizerMetric(
                label: "Memory Budget",
                value: "1.8 GB",
                detail: "统一内存预算适配 A17 / M 系列芯片",
                progress: 0.72,
                tint: .green
            ),
            OptimizerMetric(
                label: "Battery Profile",
                value: "均衡",
                detail: "响应速度与续航之间动态切换",
                progress: 0.68,
                tint: .orange
            )
        ]
        self.switches = [
            OptimizationSwitch(title: "Metal graph prewarm", subtitle: "首次生成前预热图执行路径", isEnabled: true),
            OptimizationSwitch(title: "Paged KV cache", subtitle: "长上下文时降低内存峰值", isEnabled: true),
            OptimizationSwitch(title: "Adaptive token budget", subtitle: "根据热状态调整生成长度", isEnabled: true),
            OptimizationSwitch(title: Self.offlinePrivacyGuardTitle, subtitle: "默认禁用网络模型请求", isEnabled: true)
        ]
        self.thermalState = "Nominal"
        self.deploymentReadiness = 0.76
    }

    func toggle(_ item: OptimizationSwitch) {
        guard let index = switches.firstIndex(where: { $0.id == item.id }) else { return }
        switches[index].isEnabled.toggle()
        let enabledCount = switches.filter(\.isEnabled).count
        deploymentReadiness = 0.54 + Double(enabledCount) * 0.11
    }
}

@MainActor
final class InferenceEngine: ObservableObject {
    @Published var sessions: [ChatSession]
    @Published var activeSessionID: UUID
    @Published var messages: [ChatMessage]
    @Published var inputText: String {
        didSet {
            guard !isApplyingArchive else { return }
            guard !conversationPersistenceState.blocksEditing else {
                // @Published re-enters didSet during rollback as well.
                isApplyingArchive = true
                inputText = oldValue
                isApplyingArchive = false
                return
            }
            drafts[activeSessionID] = inputText
            requestConversationSave()
        }
    }
    @Published var isGenerating: Bool
    @Published var currentTokensPerSecond: Double
    @Published var memoryUsageMB: Int
    @Published var cpuLoad: Double
    @Published var lastPreparationReport: RuntimePreparationReport?
    @Published var lastResultWasSimulated: Bool
    @Published var currentBackend: ComputeBackend
    @Published private(set) var conversationPersistenceState: ConversationPersistenceState

    private var generationTask: Task<Void, Never>?
    private let runtime: LocalInferenceRuntime
    private let conversationStorage: (any ConversationStorage)?
    private var drafts: [UUID: String] = [:]
    private var restoreTask: Task<Void, Never>?
    private var saveTask: Task<Void, Never>?
    private var pendingArchive: ConversationArchive?
    private var isApplyingArchive = false

    init(runtime: LocalInferenceRuntime = SimulatedGemmaRuntime(), conversationStorage: (any ConversationStorage)? = nil) {
        self.runtime = runtime
        self.conversationStorage = conversationStorage
        self.conversationPersistenceState = conversationStorage == nil ? .memoryOnly : .loading
        let initialSession = ChatSession(
            title: "新对话",
            messages: Self.defaultMessages()
        )
        self.sessions = [initialSession]
        self.activeSessionID = initialSession.id
        self.messages = initialSession.messages
        self.inputText = ""
        self.isGenerating = false
        self.currentTokensPerSecond = 36
        self.memoryUsageMB = 1840
        self.cpuLoad = 21
        self.lastPreparationReport = nil
        self.lastResultWasSimulated = true
        self.currentBackend = .coreMLANE
        if let conversationStorage {
            restoreTask = Task { [weak self] in
                do {
                    let archive = try await conversationStorage.load()
                    guard let self else { return }
                    if let archive {
                        try archive.validate()
                        guard let active = archive.sessions.first(where: { $0.id == archive.activeSessionID }) else {
                            throw ConversationStoreError.invalidArchive
                        }
                        self.isApplyingArchive = true
                        self.sessions = archive.sessions
                        self.activeSessionID = archive.activeSessionID
                        self.messages = active.messages
                        self.drafts = archive.drafts
                        self.inputText = archive.drafts[archive.activeSessionID] ?? ""
                        self.isApplyingArchive = false
                    }
                    self.conversationPersistenceState = .saved
                } catch {
                    self?.conversationPersistenceState = .readFailed
                }
            }
        }
    }

    private static func defaultMessages() -> [ChatMessage] {
        []
    }

    var activeSession: ChatSession? {
        sessions.first { $0.id == activeSessionID }
    }

    var activeSessionTitle: String {
        activeSession?.title ?? "新对话"
    }

    func send(using model: LocalModel, availability: ArtifactAvailability = .missing) {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false, isGenerating == false,
              !conversationPersistenceState.blocksEditing else { return }

        inputText = ""
        messages.append(ChatMessage(role: .user, text: trimmed, tokens: estimateTokens(trimmed)))
        let placeholderID = UUID()
        messages.append(ChatMessage(id: placeholderID, role: .assistant, text: "", tokens: 0))
        syncActiveSession(titlePrompt: trimmed)
        isGenerating = true
        memoryUsageMB = model.family == "Gemma" ? 1870 : 1420
        cpuLoad = 48

        let result = runtime.generate(
            InferenceRequest(prompt: trimmed, model: model, artifactAvailability: availability)
        )
        lastPreparationReport = result.preparationReport
        lastResultWasSimulated = result.isSimulated
        currentBackend = result.backend
        let fullResponse = result.text
        generationTask = Task { [weak self] in
            guard let self else { return }
            var generated = ""
            for chunk in fullResponse.streamingChunks() {
                try? await Task.sleep(for: .milliseconds(34))
                guard Task.isCancelled == false else { return }
                generated += chunk
                if let index = self.messages.firstIndex(where: { $0.id == placeholderID }) {
                    self.messages[index].text = generated
                    self.messages[index].tokens = self.estimateTokens(generated)
                    self.syncActiveSession()
                }
                self.currentTokensPerSecond = Double.random(in: 31...44)
                self.cpuLoad = Double.random(in: 33...64)
            }
            self.isGenerating = false
            self.cpuLoad = 18
            self.currentTokensPerSecond = model.tokensPerSecond
            self.syncActiveSession()
        }
    }

    func stop() {
        generationTask?.cancel()
        generationTask = nil
        isGenerating = false
        cpuLoad = 16
        requestConversationSave()
    }

    func resetConversation() {
        guard !conversationPersistenceState.blocksEditing else { return }
        stop()
        inputText = ""
        messages = Self.defaultMessages()
        syncActiveSession(title: "新对话")
        lastPreparationReport = nil
        lastResultWasSimulated = true
        currentBackend = .coreMLANE
        currentTokensPerSecond = 36
        memoryUsageMB = 1840
    }

    func usePrompt(_ prompt: String, model: LocalModel, availability: ArtifactAvailability = .missing) {
        guard isGenerating == false, !conversationPersistenceState.blocksEditing else { return }
        inputText = prompt
        send(using: model, availability: availability)
    }

    func applyTemplate(_ template: PresetPromptTemplate) {
        guard isGenerating == false, !conversationPersistenceState.blocksEditing else { return }
        inputText = template.prompt
    }

    func useTemplate(_ template: PresetPromptTemplate, model: LocalModel, availability: ArtifactAvailability = .missing) {
        guard isGenerating == false, !conversationPersistenceState.blocksEditing else { return }
        inputText = template.prompt
        send(using: model, availability: availability)
    }

    @discardableResult
    func createSession(title: String? = nil) -> UUID {
        guard !conversationPersistenceState.blocksEditing else { return activeSessionID }
        stop()
        let session = ChatSession(
            title: title ?? nextSessionTitle(),
            messages: Self.defaultMessages()
        )
        sessions.insert(session, at: 0)
        activeSessionID = session.id
        messages = session.messages
        inputText = ""
        lastPreparationReport = nil
        lastResultWasSimulated = true
        currentBackend = .coreMLANE
        currentTokensPerSecond = 36
        memoryUsageMB = 1840
        requestConversationSave()
        return session.id
    }

    func selectSession(_ session: ChatSession) {
        guard !conversationPersistenceState.blocksEditing,
              let current = sessions.first(where: { $0.id == session.id }) else { return }
        stop()
        activeSessionID = current.id
        messages = current.messages
        inputText = drafts[current.id] ?? ""
        requestConversationSave()
    }

    func deleteSession(_ session: ChatSession) {
        guard !conversationPersistenceState.blocksEditing else { return }
        let wasActive = session.id == activeSessionID
        if wasActive {
            stop()
        }

        sessions.removeAll { $0.id == session.id }
        drafts[session.id] = nil
        if sessions.isEmpty {
            createSession(title: "新对话")
            return
        }

        if wasActive {
            activeSessionID = sessions[0].id
            messages = sessions[0].messages
            inputText = drafts[activeSessionID] ?? ""
        }
        requestConversationSave()
    }

    func exportActiveSessionText(modelName: String? = nil) -> String {
        guard let session = activeSession else { return "" }

        var lines: [String] = []
        lines.append("# \(session.title)")
        if let modelName {
            lines.append("模型：\(modelName)")
        }
        lines.append("导出时间：\(Self.exportDateFormatter.string(from: Date()))")

        for message in session.messages {
            lines.append("## \(exportRoleTitle(for: message.role))")
            if !message.text.isEmpty {
                lines.append(message.text)
            } else if message.role == .assistant {
                lines.append(isGenerating && message.id == messages.last?.id ? "（生成中）" : "（已停止）")
            } else {
                lines.append("（空消息）")
            }
        }

        return lines.joined(separator: "\n\n")
    }

    func exportActiveSessionMarkdownFile(
        modelName: String? = nil,
        directoryURL: URL = FileManager.default.temporaryDirectory
    ) throws -> URL {
        let text = exportActiveSessionText(modelName: modelName)
        let title = sanitizedFileName(activeSessionTitle)
        let fileURL = directoryURL.appendingPathComponent("\(title).md")
        try Data(text.utf8).write(to: fileURL, options: .atomic)
        return fileURL
    }

    func estimateTokens(_ text: String) -> Int {
        max(1, Int(ceil(Double(text.count) / 1.8)))
    }

    private func syncActiveSession(title: String? = nil, titlePrompt: String? = nil) {
        guard let index = sessions.firstIndex(where: { $0.id == activeSessionID }) else { return }
        sessions[index].messages = messages
        sessions[index].updatedAt = Date()

        if let title {
            sessions[index].title = title
        } else if let titlePrompt, sessions[index].title.hasPrefix("新对话") {
            sessions[index].title = Self.sessionTitle(from: titlePrompt)
        }
        requestConversationSave()
    }

    func waitForConversationRestore() async {
        await restoreTask?.value
    }

    @discardableResult
    func flushConversationHistory() async -> Bool {
        await waitForConversationRestore()
        guard conversationStorage != nil else { return true }
        guard conversationPersistenceState != .readFailed,
              !conversationPersistenceState.blocksEditing else { return false }
        pendingArchive = conversationArchive()
        startConversationSave()
        while let task = saveTask { await task.value }
        return conversationPersistenceState == .saved
    }

    func repairConversationHistory() async {
        guard conversationPersistenceState == .readFailed, let conversationStorage else { return }
        let archive = conversationArchive()
        conversationPersistenceState = .repairing
        do {
            try await conversationStorage.repair(with: archive)
            pendingArchive = nil
            conversationPersistenceState = .saved
        } catch {
            conversationPersistenceState = .readFailed
        }
    }

    private func conversationArchive() -> ConversationArchive {
        var snapshot = sessions
        if let index = snapshot.firstIndex(where: { $0.id == activeSessionID }) {
            snapshot[index].messages = messages
        }
        return ConversationArchive(sessions: snapshot, activeSessionID: activeSessionID, drafts: drafts)
    }

    private func requestConversationSave() {
        guard conversationStorage != nil, !isApplyingArchive,
              !conversationPersistenceState.blocksEditing else { return }
        pendingArchive = conversationArchive()
        guard conversationPersistenceState != .readFailed,
              conversationPersistenceState != .writeFailed else { return }
        startConversationSave()
    }

    private func startConversationSave() {
        guard saveTask == nil, let conversationStorage else { return }
        conversationPersistenceState = .saving
        // One ordered writer coalesces typing/streaming snapshots without
        // cancelling an in-flight disk commit or encoding on the UI executor.
        saveTask = Task { [weak self] in
            guard let self else { return }
            while self.pendingArchive != nil {
                try? await Task.sleep(for: .milliseconds(180))
                guard let archive = self.pendingArchive else { break }
                self.pendingArchive = nil
                do {
                    try await conversationStorage.save(archive)
                } catch {
                    if self.pendingArchive == nil { self.pendingArchive = archive }
                    self.conversationPersistenceState = .writeFailed
                    self.saveTask = nil
                    return
                }
            }
            self.conversationPersistenceState = .saved
            self.saveTask = nil
        }
    }

    private func nextSessionTitle() -> String {
        "新对话 \(sessions.count + 1)"
    }

    private static func sessionTitle(from prompt: String) -> String {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return "新对话" }
        let prefix = trimmed.prefix(18)
        return prefix.count == trimmed.count ? String(prefix) : "\(prefix)..."
    }

    private func sanitizedFileName(_ value: String) -> String {
        let allowed = CharacterSet.alphanumerics
            .union(.whitespaces)
            .union(CharacterSet(charactersIn: "-_"))
        let scalars = value.unicodeScalars.map { scalar in
            allowed.contains(scalar) ? Character(scalar) : "-"
        }
        let collapsed = String(scalars)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "-")
        return collapsed.isEmpty ? "LocalGemma-Conversation" : collapsed
    }

    private func exportRoleTitle(for role: ChatMessage.Role) -> String {
        switch role {
        case .user:
            return "用户"
        case .assistant:
            return "本地模型"
        case .system:
            return "系统"
        }
    }

    private static let exportDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

protocol SimulatedResponseProviding: Sendable {
    func response(for prompt: String, model: LocalModel) -> String
}

struct SimulatedGemmaRuntime: LocalInferenceRuntime {
    let provider: SimulatedResponseProviding

    init(provider: SimulatedResponseProviding = GemmaSimulationProvider()) {
        self.provider = provider
    }

    var runtimeName: String {
        "Gemma Simulation Runtime"
    }

    func prepare(for model: LocalModel, availability: ArtifactAvailability = .missing) -> RuntimePreparationReport {
        LocalRuntimePlanner.preparationReport(for: model, availability: availability)
    }

    func generate(_ request: InferenceRequest) -> InferenceResult {
        let report = prepare(for: request.model, availability: request.artifactAvailability)
        return InferenceResult(
            text: provider.response(for: request.prompt, model: request.model),
            isSimulated: true,
            backend: report.activeBackend,
            preparationReport: report
        )
    }
}

struct RealGemmaRuntimePlaceholder: LocalInferenceRuntime {
    var runtimeName: String {
        "Real Gemma Runtime Placeholder"
    }

    func prepare(for model: LocalModel, availability: ArtifactAvailability = .missing) -> RuntimePreparationReport {
        LocalRuntimePlanner.preparationReport(for: model, availability: availability)
    }

    func generate(_ request: InferenceRequest) -> InferenceResult {
        let report = prepare(for: request.model, availability: request.artifactAvailability)
        if report.canRunRealWeights == false {
            return InferenceResult(
                text: """
                真实 Gemma 1.5B runtime 尚未启动。

                当前缺少已校验的 \(request.model.artifactManifest.modelFileName) 和 \(request.model.artifactManifest.tokenizerFileName)，所以保持本地模拟模式，不会下载模型，也不会发起网络请求。

                下一步：\(report.nextSteps.joined(separator: " "))
                """,
                isSimulated: true,
                backend: report.fallbackBackend,
                preparationReport: report
            )
        }

        return InferenceResult(
            text: """
            真实 Gemma runtime 接入点已就绪：\(request.model.deploymentProfile.primaryBackend.title)。

            这里是占位实现，用于保护工程边界。导入真实权重后，需要在此处接入 Core ML / ANE 执行图、tokenizer、paged KV cache 和热状态调度。
            """,
            isSimulated: false,
            backend: report.activeBackend,
            preparationReport: report
        )
    }
}

struct GemmaSimulationProvider: SimulatedResponseProviding {
    func response(for prompt: String, model: LocalModel) -> String {
        let normalized = prompt.lowercased()
        if normalized.contains("部署") || normalized.contains("芯片") || normalized.contains("metal") || normalized.contains("ane") {
            return """
            \(model.name) · 模拟部署示例

            先导入并校验模型文件，再接入实际推理后端。

            当前仅为界面预览，尚未执行 Core ML / Metal 真实推理。
            """
        }

        if normalized.contains("隐私") || normalized.contains("安全") || normalized.contains("本地") {
            return """
            对话和草稿留在本机，不会主动发送到云端。

            这是模拟说明，尚未接入真实模型。
            """
        }

        return """
        这是一段模拟回复，用于预览逐字显示、停止和复制。

        真实模型尚未接入，不会实际改写、翻译或总结你的内容。
        """
    }
}

private extension String {
    func streamingChunks() -> [String] {
        var chunks: [String] = []
        var current = ""
        for character in self {
            current.append(character)
            if current.count >= 2 || character == "\n" {
                chunks.append(current)
                current = ""
            }
        }
        if current.isEmpty == false {
            chunks.append(current)
        }
        return chunks
    }
}
