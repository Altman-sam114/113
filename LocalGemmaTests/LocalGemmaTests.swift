import XCTest
@testable import LocalGemma

@MainActor
final class LocalGemmaTests: XCTestCase {
    func testDefaultCatalogStartsWithGemmaSimulation() {
        let catalog = ModelCatalog()

        XCTAssertEqual(catalog.selectedModel.name, "Gemma 1.5B Local")
        XCTAssertEqual(catalog.selectedModel.parameterCount, "1.5B")
        XCTAssertEqual(catalog.selectedModel.installState, .simulated)
        XCTAssertTrue(catalog.selectedModel.summary.contains("不下载") || catalog.selectedModel.summary.contains("暂未下载"))
    }

    func testSimulationProviderMentionsNoRealWeights() {
        let model = ModelCatalog.defaultModels[0]
        let response = GemmaSimulationProvider().response(for: "说明 iPhone 芯片部署优化", model: model)

        XCTAssertTrue(response.contains("模拟"))
        XCTAssertTrue(response.contains("Metal"))
        XCTAssertTrue(response.contains("Gemma"))
    }

    func testGemmaManifestRequiresManualImport() {
        let model = ModelCatalog.defaultModels[0]
        let report = LocalRuntimePlanner.preparationReport(for: model)

        XCTAssertEqual(model.artifactManifest.allowsNetworkDownload, false)
        XCTAssertTrue(model.artifactManifest.requiredFiles.contains("gemma-1.5b-it-q4.mlmodelc"))
        XCTAssertEqual(report.canRunRealWeights, false)
        XCTAssertEqual(report.activeBackend, .coreMLANE)
        XCTAssertEqual(report.fallbackBackend, .metalPerformanceShaders)
        XCTAssertFalse(report.blockers.isEmpty)
    }

    func testArtifactValidatorReportsMissingFiles() {
        let model = ModelCatalog.defaultModels[0]
        let validation = LocalArtifactValidator.validate(
            manifest: model.artifactManifest,
            presentFiles: []
        )
        let report = LocalRuntimePlanner.preparationReport(for: model, validation: validation)

        XCTAssertEqual(validation.availability, .missing)
        XCTAssertEqual(validation.missingFiles, model.artifactManifest.requiredFiles)
        XCTAssertFalse(validation.hasRequiredFiles)
        XCTAssertFalse(validation.canPromoteToRealRuntime)
        XCTAssertTrue(validation.summary.contains("缺少"))
        XCTAssertFalse(report.canRunRealWeights)
        XCTAssertTrue(report.blockers[0].contains("缺少本地 artifact"))
    }

    func testArtifactValidatorStagesFilesWithoutTrustedHash() {
        let model = ModelCatalog.defaultModels[0]
        let validation = LocalArtifactValidator.validate(
            manifest: model.artifactManifest,
            presentFiles: Set(model.artifactManifest.requiredFiles)
        )
        let report = LocalRuntimePlanner.preparationReport(for: model, validation: validation)

        XCTAssertEqual(validation.availability, .staged)
        XCTAssertTrue(validation.hasRequiredFiles)
        XCTAssertFalse(validation.hasConcreteExpectedHash)
        XCTAssertFalse(validation.hasVerifiedHash)
        XCTAssertFalse(validation.canPromoteToRealRuntime)
        XCTAssertFalse(report.canRunRealWeights)
        XCTAssertTrue(report.blockers[0].contains("官方 SHA-256"))
    }

    func testArtifactValidatorVerifiesConcreteHash() {
        let expectedHash = String(repeating: "a", count: 64)
        let manifest = ModelArtifactManifest(
            modelFileName: "test-gemma.mlmodelc",
            tokenizerFileName: "test-tokenizer.model",
            fileFormat: "Core ML compiled package",
            storageDirectory: "Application Support/LocalModels",
            expectedSHA256: expectedHash,
            allowsNetworkDownload: false,
            importInstruction: "手动导入测试模型。"
        )
        let model = LocalModel(
            name: "Gemma Test",
            family: "Gemma",
            parameterCount: "1.5B",
            quantization: "4-bit",
            sizeOnDisk: "1 GB",
            contextLength: 4096,
            tokensPerSecond: 36,
            memoryFootprint: "1.8 GB",
            installState: .notDownloaded,
            summary: "Test model",
            capabilities: [],
            artifactManifest: manifest,
            deploymentProfile: AppleSiliconDeploymentProfile(
                preferredChipClass: "A17 Pro",
                recommendedMemoryBudget: "1.8 GB",
                primaryBackend: .coreMLANE,
                fallbackBackend: .metalPerformanceShaders,
                kvCachePolicy: "Paged KV cache",
                thermalStrategy: "Nominal",
                maxActiveTokens: 4096
            )
        )
        let validation = LocalArtifactValidator.validate(
            manifest: manifest,
            presentFiles: Set(manifest.requiredFiles),
            observedSHA256: expectedHash
        )
        let report = LocalRuntimePlanner.preparationReport(for: model, validation: validation)

        XCTAssertEqual(validation.availability, .verified)
        XCTAssertTrue(validation.hasConcreteExpectedHash)
        XCTAssertTrue(validation.hasVerifiedHash)
        XCTAssertTrue(validation.canPromoteToRealRuntime)
        XCTAssertTrue(report.canRunRealWeights)
        XCTAssertTrue(report.blockers.isEmpty)
        XCTAssertTrue(report.nextSteps.contains { $0.contains("预热") })
    }

    func testArtifactStoreVerifiesFilesFromDisk() throws {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("LocalGemmaTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: directoryURL)
        }

        let modelFileName = "disk-gemma.bin"
        let tokenizerFileName = "disk-tokenizer.model"
        try Data("abc".utf8).write(to: directoryURL.appendingPathComponent(modelFileName))
        try Data("tokenizer".utf8).write(to: directoryURL.appendingPathComponent(tokenizerFileName))

        let manifest = ModelArtifactManifest(
            modelFileName: modelFileName,
            tokenizerFileName: tokenizerFileName,
            fileFormat: "Core ML compiled package",
            storageDirectory: directoryURL.path,
            expectedSHA256: "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
            allowsNetworkDownload: false,
            importInstruction: "手动导入测试模型。"
        )

        let validation = ModelArtifactStore.validate(
            manifest: manifest,
            directoryURL: directoryURL
        )

        XCTAssertEqual(validation.availability, .verified)
        XCTAssertEqual(validation.observedSHA256, manifest.expectedSHA256)
        XCTAssertTrue(validation.hasVerifiedHash)
        XCTAssertTrue(validation.canPromoteToRealRuntime)
        XCTAssertEqual(Set(validation.presentFiles), Set(manifest.requiredFiles))
    }

    func testArtifactStoreImportsSelectedFilesIntoDestination() throws {
        let sourceDirectoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("LocalGemmaImportSource-\(UUID().uuidString)", isDirectory: true)
        let destinationDirectoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("LocalGemmaImportDestination-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: sourceDirectoryURL, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: sourceDirectoryURL)
            try? FileManager.default.removeItem(at: destinationDirectoryURL)
        }

        let modelFileName = "import-gemma.bin"
        let tokenizerFileName = "import-tokenizer.model"
        let modelURL = sourceDirectoryURL.appendingPathComponent(modelFileName)
        let tokenizerURL = sourceDirectoryURL.appendingPathComponent(tokenizerFileName)
        try Data("abc".utf8).write(to: modelURL)
        try Data("tokenizer".utf8).write(to: tokenizerURL)

        let manifest = ModelArtifactManifest(
            modelFileName: modelFileName,
            tokenizerFileName: tokenizerFileName,
            fileFormat: "Core ML compiled package",
            storageDirectory: destinationDirectoryURL.path,
            expectedSHA256: "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
            allowsNetworkDownload: false,
            importInstruction: "手动导入测试模型。"
        )

        let validation = try ModelArtifactStore.importArtifacts(
            manifest: manifest,
            sourceURLs: [modelURL, tokenizerURL],
            destinationDirectoryURL: destinationDirectoryURL
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: destinationDirectoryURL.appendingPathComponent(modelFileName).path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: destinationDirectoryURL.appendingPathComponent(tokenizerFileName).path))
        XCTAssertEqual(validation.availability, .verified)
        XCTAssertEqual(validation.observedSHA256, manifest.expectedSHA256)
        XCTAssertFalse(validation.networkDownloadAllowed)
    }

    func testArtifactStoreRemovesManagedFiles() throws {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("LocalGemmaRemoveDestination-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: directoryURL)
        }

        let modelFileName = "remove-gemma.bin"
        let tokenizerFileName = "remove-tokenizer.model"
        try Data("abc".utf8).write(to: directoryURL.appendingPathComponent(modelFileName))
        try Data("tokenizer".utf8).write(to: directoryURL.appendingPathComponent(tokenizerFileName))

        let manifest = ModelArtifactManifest(
            modelFileName: modelFileName,
            tokenizerFileName: tokenizerFileName,
            fileFormat: "Core ML compiled package",
            storageDirectory: directoryURL.path,
            expectedSHA256: String(repeating: "d", count: 64),
            allowsNetworkDownload: false,
            importInstruction: "手动导入测试模型。"
        )

        let validation = try ModelArtifactStore.removeArtifacts(
            manifest: manifest,
            destinationDirectoryURL: directoryURL
        )

        XCTAssertEqual(validation.availability, .missing)
        XCTAssertFalse(FileManager.default.fileExists(atPath: directoryURL.appendingPathComponent(modelFileName).path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: directoryURL.appendingPathComponent(tokenizerFileName).path))
        XCTAssertEqual(validation.missingFiles, manifest.requiredFiles)
    }

    func testArtifactStoreImportsCoreMLPackageDirectory() throws {
        let sourceDirectoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("LocalGemmaPackageSource-\(UUID().uuidString)", isDirectory: true)
        let destinationDirectoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("LocalGemmaPackageDestination-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: sourceDirectoryURL, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: sourceDirectoryURL)
            try? FileManager.default.removeItem(at: destinationDirectoryURL)
        }

        let modelFileName = "package-gemma.mlmodelc"
        let tokenizerFileName = "package-tokenizer.model"
        let modelPackageURL = sourceDirectoryURL.appendingPathComponent(modelFileName, isDirectory: true)
        try FileManager.default.createDirectory(at: modelPackageURL, withIntermediateDirectories: true)
        try Data("compiled-coreml".utf8).write(to: modelPackageURL.appendingPathComponent("model.mil"))
        try Data("metadata".utf8).write(to: modelPackageURL.appendingPathComponent("metadata.json"))
        let tokenizerURL = sourceDirectoryURL.appendingPathComponent(tokenizerFileName)
        try Data("tokenizer".utf8).write(to: tokenizerURL)

        let expectedHash = try XCTUnwrap(ModelArtifactHasher.sha256Hex(for: modelPackageURL))
        let manifest = ModelArtifactManifest(
            modelFileName: modelFileName,
            tokenizerFileName: tokenizerFileName,
            fileFormat: "Core ML compiled package",
            storageDirectory: destinationDirectoryURL.path,
            expectedSHA256: expectedHash,
            allowsNetworkDownload: false,
            importInstruction: "手动导入测试模型。"
        )

        let validation = try ModelArtifactStore.importArtifacts(
            manifest: manifest,
            sourceURLs: [modelPackageURL, tokenizerURL],
            destinationDirectoryURL: destinationDirectoryURL
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: destinationDirectoryURL.appendingPathComponent(modelFileName).path))
        XCTAssertEqual(validation.availability, .verified)
        XCTAssertEqual(validation.observedSHA256, expectedHash)
        XCTAssertTrue(validation.fileStatuses.first(where: { $0.fileName == modelFileName })?.isDirectory == true)
    }

    func testArtifactStoreRejectsIncompleteImportSelection() throws {
        let sourceDirectoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("LocalGemmaIncompleteSource-\(UUID().uuidString)", isDirectory: true)
        let destinationDirectoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("LocalGemmaIncompleteDestination-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: sourceDirectoryURL, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: sourceDirectoryURL)
            try? FileManager.default.removeItem(at: destinationDirectoryURL)
        }

        let modelURL = sourceDirectoryURL.appendingPathComponent("missing-tokenizer-gemma.bin")
        try Data("abc".utf8).write(to: modelURL)
        let manifest = ModelArtifactManifest(
            modelFileName: "missing-tokenizer-gemma.bin",
            tokenizerFileName: "missing-tokenizer.model",
            fileFormat: "Core ML compiled package",
            storageDirectory: destinationDirectoryURL.path,
            expectedSHA256: String(repeating: "c", count: 64),
            allowsNetworkDownload: false,
            importInstruction: "手动导入测试模型。"
        )

        XCTAssertThrowsError(
            try ModelArtifactStore.importArtifacts(
                manifest: manifest,
                sourceURLs: [modelURL],
                destinationDirectoryURL: destinationDirectoryURL
            )
        ) { error in
            XCTAssertEqual(error as? ArtifactImportError, .missingRequiredFiles(["missing-tokenizer.model"]))
        }
        XCTAssertFalse(FileManager.default.fileExists(atPath: destinationDirectoryURL.path))
    }

    func testCatalogStagesManualImportPreview() {
        let catalog = ModelCatalog()
        let model = catalog.selectedModel

        XCTAssertEqual(catalog.validation(for: model).availability, .missing)

        catalog.stageManualImportPreview(for: model)

        XCTAssertEqual(catalog.validation(for: catalog.selectedModel).availability, .staged)
        XCTAssertEqual(catalog.selectedModel.installState, .simulated)
        XCTAssertTrue(catalog.selectedModel.summary.contains("SHA-256"))
        XCTAssertFalse(
            LocalRuntimePlanner
                .preparationReport(for: catalog.selectedModel, validation: catalog.validation(for: catalog.selectedModel))
                .canRunRealWeights
        )
    }

    func testCatalogDeploymentRunsOnlySelectedModel() {
        let catalog = ModelCatalog()
        let gemma = catalog.selectedModel
        let qwen = catalog.models[1]

        XCTAssertEqual(catalog.deploymentState(for: gemma), .stopped)

        catalog.startDeployment(for: gemma)

        XCTAssertTrue(catalog.isDeploymentRunning(for: gemma))
        XCTAssertEqual(catalog.selectedModel.id, gemma.id)

        catalog.startDeployment(for: qwen)

        XCTAssertFalse(catalog.isDeploymentRunning(for: gemma))
        XCTAssertTrue(catalog.isDeploymentRunning(for: qwen))
        XCTAssertEqual(catalog.selectedModel.id, qwen.id)

        catalog.toggleDeployment(for: qwen)

        XCTAssertEqual(catalog.deploymentState(for: qwen), .stopped)
    }

    func testCatalogUninstallStopsDeploymentAndMarksModelUndownloaded() throws {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("LocalGemmaCatalogUninstall-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: directoryURL)
        }

        let model = ModelCatalog.defaultModels[0]
        for fileName in model.artifactManifest.requiredFiles {
            let url = directoryURL.appendingPathComponent(fileName)
            if fileName.hasSuffix(".mlmodelc") {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
                try Data("compiled-gemma".utf8).write(to: url.appendingPathComponent("model.mil"))
            } else {
                try Data("tokenizer".utf8).write(to: url)
            }
        }

        let catalog = ModelCatalog(
            models: [model],
            autoScanLocalArtifacts: true,
            artifactDirectoryURL: directoryURL
        )

        catalog.startDeployment(for: catalog.selectedModel)
        XCTAssertTrue(catalog.isDeploymentRunning(for: catalog.selectedModel))

        try catalog.uninstallArtifacts(for: catalog.selectedModel)

        XCTAssertEqual(catalog.deploymentState(for: catalog.selectedModel), .stopped)
        XCTAssertEqual(catalog.validation(for: catalog.selectedModel).availability, .missing)
        XCTAssertEqual(catalog.selectedModel.installState, .notDownloaded)
        XCTAssertTrue(catalog.selectedModel.summary.contains("未下载"))
    }

    func testCatalogAutoScanRestoresExistingLocalArtifacts() throws {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("LocalGemmaAutoScan-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: directoryURL)
        }

        let model = ModelCatalog.defaultModels[0]
        for fileName in model.artifactManifest.requiredFiles {
            let url = directoryURL.appendingPathComponent(fileName)
            if fileName.hasSuffix(".mlmodelc") {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
                try Data("compiled-gemma".utf8).write(to: url.appendingPathComponent("model.mil"))
            } else {
                try Data("tokenizer".utf8).write(to: url)
            }
        }

        let catalog = ModelCatalog(
            models: [model],
            autoScanLocalArtifacts: true,
            artifactDirectoryURL: directoryURL
        )

        XCTAssertEqual(catalog.validation(for: catalog.selectedModel).availability, .staged)
        XCTAssertEqual(catalog.selectedModel.installState, .simulated)
        XCTAssertTrue(catalog.selectedModel.summary.contains("SHA-256"))
    }

    func testVerifiedArtifactsEnableRealRuntimePlan() {
        let model = ModelCatalog.defaultModels[0]
        let report = LocalRuntimePlanner.preparationReport(for: model, availability: .verified)

        XCTAssertTrue(report.canRunRealWeights)
        XCTAssertFalse(report.networkDownloadAllowed)
        XCTAssertTrue(report.blockers.isEmpty)
        XCTAssertTrue(report.nextSteps.contains { $0.contains("预热") })
    }

    func testSimulationRuntimeUsesLocalSimulation() {
        let model = ModelCatalog.defaultModels[0]
        let result = SimulatedGemmaRuntime().generate(
            InferenceRequest(prompt: "说明本地部署", model: model)
        )

        XCTAssertTrue(result.isSimulated)
        XCTAssertEqual(result.backend, .coreMLANE)
        XCTAssertTrue(result.text.contains("模拟"))
        XCTAssertFalse(result.preparationReport.networkDownloadAllowed)
    }

    func testRealRuntimePlaceholderDoesNotRunWithoutVerifiedArtifacts() {
        let model = ModelCatalog.defaultModels[0]
        let result = RealGemmaRuntimePlaceholder().generate(
            InferenceRequest(prompt: "启动真实模型", model: model)
        )

        XCTAssertTrue(result.isSimulated)
        XCTAssertEqual(result.backend, .metalPerformanceShaders)
        XCTAssertTrue(result.text.contains("不会下载模型"))
        XCTAssertFalse(result.preparationReport.canRunRealWeights)
    }

    func testRealRuntimePlaceholderHonorsVerifiedArtifacts() {
        let model = ModelCatalog.defaultModels[0]
        let result = RealGemmaRuntimePlaceholder().generate(
            InferenceRequest(prompt: "启动真实模型", model: model, artifactAvailability: .verified)
        )

        XCTAssertFalse(result.isSimulated)
        XCTAssertEqual(result.backend, .coreMLANE)
        XCTAssertTrue(result.preparationReport.canRunRealWeights)
    }

    func testOptimizerTogglesChangeReadiness() {
        let optimizer = DeviceOptimizer()
        let initialReadiness = optimizer.deploymentReadiness
        let firstSwitch = optimizer.switches[0]

        optimizer.toggle(firstSwitch)

        XCTAssertNotEqual(optimizer.deploymentReadiness, initialReadiness)
        XCTAssertFalse(optimizer.switches[0].isEnabled)
    }

    func testChipReadinessCardDescribesPrivacyGuardAndAccessibilityMetadata() {
        let optimizer = DeviceOptimizer()

        XCTAssertTrue(optimizer.isOfflinePrivacyGuardEnabled)
        XCTAssertEqual(
            ChipReadinessAccessibilityMetadata.summary(
                thermalState: optimizer.thermalState,
                privacyGuardEnabled: optimizer.isOfflinePrivacyGuardEnabled
            ),
            "热状态 Nominal · 模拟 Metal 预热 · 离线隐私保护开启"
        )
        XCTAssertEqual(ChipReadinessAccessibilityMetadata.percent(for: optimizer.deploymentReadiness), 76)
        XCTAssertEqual(ChipReadinessAccessibilityMetadata.percent(for: -0.3), 0)
        XCTAssertEqual(ChipReadinessAccessibilityMetadata.percent(for: 1.3), 100)

        let value = ChipReadinessAccessibilityMetadata.cardValue(
            progress: optimizer.deploymentReadiness,
            thermalState: optimizer.thermalState,
            privacyGuardEnabled: optimizer.isOfflinePrivacyGuardEnabled
        )
        XCTAssertTrue(value.contains("准备度 76%"))
        XCTAssertTrue(value.contains("热状态 Nominal"))
        XCTAssertTrue(value.contains("模拟 Metal 预热"))
        XCTAssertTrue(value.contains("离线隐私保护开启"))

        XCTAssertEqual(ChipReadinessAccessibilityMetadata.cardLabel, "芯片部署准备度")
        XCTAssertEqual(ChipReadinessAccessibilityMetadata.cardIdentifier, "chip-readiness-card")
        XCTAssertTrue(ChipReadinessAccessibilityMetadata.cardInputLabels.contains("芯片准备度"))
        XCTAssertTrue(ChipReadinessAccessibilityMetadata.cardInputLabels.contains("Apple Silicon 准备度"))

        let cardHint = ChipReadinessAccessibilityMetadata.cardHint
        XCTAssertTrue(cardHint.contains("本地芯片准备度"))
        XCTAssertTrue(cardHint.contains("不会下载模型权重"))
        XCTAssertTrue(cardHint.contains("不会启动真实 runtime"))
        XCTAssertTrue(cardHint.contains("不会发送到云端服务"))

        XCTAssertEqual(ChipReadinessAccessibilityMetadata.ringLabel, "部署准备度圆环")
        XCTAssertEqual(ChipReadinessAccessibilityMetadata.ringValue(progress: optimizer.deploymentReadiness), "准备度 76%")
        XCTAssertTrue(ChipReadinessAccessibilityMetadata.ringInputLabels.contains("准备度圆环"))
        XCTAssertTrue(ChipReadinessAccessibilityMetadata.ringInputLabels.contains("芯片准备度圆环"))
        XCTAssertEqual(ChipReadinessAccessibilityMetadata.headerRingIdentifier, "header-readiness-ring")
        XCTAssertEqual(ChipReadinessAccessibilityMetadata.chipRingIdentifier, "chip-readiness-ring")
        XCTAssertTrue(ChipReadinessAccessibilityMetadata.ringHint.contains("本地模拟部署准备度"))
        XCTAssertTrue(ChipReadinessAccessibilityMetadata.ringHint.contains("不会下载模型权重"))

        guard let privacyGuard = optimizer.switches.first(where: { $0.title == DeviceOptimizer.offlinePrivacyGuardTitle }) else {
            XCTFail("Default optimizer switches should include Offline privacy guard.")
            return
        }

        optimizer.toggle(privacyGuard)

        XCTAssertFalse(optimizer.isOfflinePrivacyGuardEnabled)
        let disabledSummary = ChipReadinessAccessibilityMetadata.summary(
            thermalState: optimizer.thermalState,
            privacyGuardEnabled: optimizer.isOfflinePrivacyGuardEnabled
        )
        XCTAssertTrue(disabledSummary.contains("离线隐私保护关闭"))
        XCTAssertFalse(disabledSummary.contains("离线隐私保护开启"))
    }

    func testOptimizationToggleRowsExposeAccessibilityMetadata() {
        let optimizer = DeviceOptimizer()
        let switches = optimizer.switches

        XCTAssertEqual(switches.count, 4)
        XCTAssertEqual(
            switches.map { OptimizationToggleAccessibilityMetadata.identifier(for: $0) },
            [
                "optimizer-toggle-metal-graph-prewarm",
                "optimizer-toggle-paged-kv-cache",
                "optimizer-toggle-adaptive-token-budget",
                "optimizer-toggle-offline-privacy-guard"
            ]
        )

        for item in switches {
            XCTAssertEqual(
                OptimizationToggleAccessibilityMetadata.label(for: item),
                "运行策略 \(item.title)"
            )
            XCTAssertTrue(
                OptimizationToggleAccessibilityMetadata.value(for: item).contains("已开启"),
                "Enabled value should describe on state for \(item.title)."
            )
            XCTAssertTrue(
                OptimizationToggleAccessibilityMetadata.value(for: item).contains(item.subtitle),
                "Value should include subtitle for \(item.title)."
            )

            let hint = OptimizationToggleAccessibilityMetadata.hint(for: item)
            XCTAssertTrue(hint.contains("只切换本地运行策略"))
            XCTAssertTrue(hint.contains("不会下载模型权重"))
            XCTAssertTrue(hint.contains("不会启动真实 runtime"))
            XCTAssertTrue(hint.contains("不会发送到云端服务"))

            let inputLabels = OptimizationToggleAccessibilityMetadata.inputLabels(for: item)
            XCTAssertFalse(inputLabels.isEmpty)
            XCTAssertTrue(inputLabels.contains(item.title))
            XCTAssertTrue(inputLabels.contains("关闭 \(item.title)"))

            var disabledItem = item
            disabledItem.isEnabled = false
            XCTAssertTrue(
                OptimizationToggleAccessibilityMetadata.value(for: disabledItem).contains("已关闭"),
                "Disabled value should describe off state for \(item.title)."
            )
            XCTAssertTrue(
                OptimizationToggleAccessibilityMetadata.inputLabels(for: disabledItem)
                    .contains("开启 \(item.title)")
            )
        }

        let firstSwitch = switches[0]
        optimizer.toggle(firstSwitch)
        XCTAssertTrue(
            OptimizationToggleAccessibilityMetadata.value(for: optimizer.switches[0]).contains("已关闭")
        )
    }

    func testOptimizerMetricCardsExposeAccessibilityMetadata() {
        let optimizer = DeviceOptimizer()
        let metrics = optimizer.metrics

        XCTAssertEqual(metrics.count, 4)
        XCTAssertEqual(
            metrics.map { OptimizerMetricAccessibilityMetadata.identifier(for: $0) },
            [
                "optimizer-metric-neural-engine",
                "optimizer-metric-metal-kernels",
                "optimizer-metric-memory-budget",
                "optimizer-metric-battery-profile"
            ]
        )
        XCTAssertEqual(OptimizerMetricAccessibilityMetadata.percent(for: metrics[0].progress), 62)
        XCTAssertEqual(OptimizerMetricAccessibilityMetadata.percent(for: -0.2), 0)
        XCTAssertEqual(OptimizerMetricAccessibilityMetadata.percent(for: 1.2), 100)

        for metric in metrics {
            XCTAssertEqual(
                OptimizerMetricAccessibilityMetadata.label(for: metric),
                "优化指标 \(metric.label)"
            )

            let value = OptimizerMetricAccessibilityMetadata.value(for: metric)
            XCTAssertTrue(value.contains(metric.value))
            XCTAssertTrue(value.contains(metric.detail))
            XCTAssertTrue(value.contains("进度 \(OptimizerMetricAccessibilityMetadata.percent(for: metric.progress))%"))

            let inputLabels = OptimizerMetricAccessibilityMetadata.inputLabels(for: metric)
            XCTAssertTrue(inputLabels.contains(metric.label))
            XCTAssertTrue(inputLabels.contains("\(metric.label) 指标"))
            XCTAssertTrue(inputLabels.contains("查看 \(metric.label)"))
        }

        XCTAssertTrue(
            OptimizerMetricAccessibilityMetadata.value(for: metrics[0]).contains("Core ML 编译后启用 ANE")
        )

        let hint = OptimizerMetricAccessibilityMetadata.hint
        XCTAssertTrue(hint.contains("本地 Apple Silicon 优化指标摘要"))
        XCTAssertTrue(hint.contains("不会下载模型权重"))
        XCTAssertTrue(hint.contains("不会启动真实 runtime"))
        XCTAssertTrue(hint.contains("不会发送到云端服务"))
        XCTAssertTrue(hint.contains("verified 门禁"))
    }

    func testPromptTemplateLibraryProvidesMultipleCategories() {
        let templates = PromptTemplateLibrary.defaultTemplates
        let categories = Set(templates.map(\.category))

        XCTAssertGreaterThanOrEqual(templates.count, 6)
        XCTAssertEqual(categories, Set(PromptTemplateCategory.allCases))
        XCTAssertTrue(templates.contains { $0.title == "部署方案" && $0.prompt.contains("Gemma 1.5B") })
        XCTAssertTrue(templates.contains { $0.title == "排障清单" && $0.prompt.contains("SHA-256") })
        XCTAssertEqual(PromptTemplateLibrary.templates(in: nil), templates)
        XCTAssertTrue(PromptTemplateLibrary.templates(in: .privacy).allSatisfy { $0.category == .privacy })
    }

    func testPromptCategoryAccessibilityMetadataDescribesFilterSelectionAndInputLabels() {
        XCTAssertEqual(PromptCategoryAccessibilityMetadata.allCategoryTitle, "全部")
        XCTAssertEqual(PromptCategoryAccessibilityMetadata.title(for: nil), "全部")
        XCTAssertEqual(
            PromptCategoryAccessibilityMetadata.label(for: nil),
            "筛选提示词 全部"
        )
        XCTAssertEqual(
            PromptCategoryAccessibilityMetadata.identifier(for: nil),
            "prompt-category-all"
        )
        XCTAssertEqual(
            PromptCategoryAccessibilityMetadata.value(isSelected: true),
            "当前筛选"
        )
        XCTAssertEqual(
            PromptCategoryAccessibilityMetadata.value(isSelected: false),
            "未选中"
        )
        XCTAssertEqual(
            PromptCategoryAccessibilityMetadata.hint(for: nil),
            "显示全部提示词模板。"
        )
        XCTAssertEqual(
            PromptCategoryAccessibilityMetadata.inputLabels(for: nil),
            ["全部提示词", "筛选全部", "显示全部模板"]
        )
        XCTAssertEqual(
            PromptTemplateCategory.allCases.map(\.title),
            ["部署", "隐私", "性能", "写作", "产品", "排障"]
        )
        XCTAssertEqual(
            Set(
                PromptTemplateCategory.allCases.map {
                    PromptCategoryAccessibilityMetadata.identifier(for: $0)
                }
            ).count,
            PromptTemplateCategory.allCases.count
        )
        XCTAssertTrue(
            PromptTemplateCategory.allCases.allSatisfy {
                !PromptCategoryAccessibilityMetadata.label(for: $0).isEmpty
                    && !PromptCategoryAccessibilityMetadata.identifier(for: $0).isEmpty
                    && !PromptCategoryAccessibilityMetadata.hint(for: $0).isEmpty
                    && !PromptCategoryAccessibilityMetadata.inputLabels(for: $0).isEmpty
            }
        )
        XCTAssertEqual(
            PromptCategoryAccessibilityMetadata.label(for: .privacy),
            "筛选提示词 隐私"
        )
        XCTAssertEqual(
            PromptCategoryAccessibilityMetadata.identifier(for: .privacy),
            "prompt-category-privacy"
        )
        XCTAssertEqual(
            PromptCategoryAccessibilityMetadata.hint(for: .privacy),
            "显示隐私分类的提示词模板。"
        )
        XCTAssertEqual(
            PromptCategoryAccessibilityMetadata.inputLabels(for: .privacy),
            ["筛选隐私", "隐私提示词", "显示隐私模板"]
        )
    }

    func testPromptTemplateActionsExposeAccessibilityMetadata() {
        let templates = PromptTemplateLibrary.defaultTemplates

        XCTAssertEqual(PromptTemplateActionAccessibilityMetadata.Action.allCases, [.apply, .send])

        var identifiers = Set<String>()
        for template in templates {
            let applyLabel = PromptTemplateActionAccessibilityMetadata.label(for: .apply, template: template)
            let sendLabel = PromptTemplateActionAccessibilityMetadata.label(for: .send, template: template)
            XCTAssertEqual(applyLabel, "填入提示词模板 \(template.title)")
            XCTAssertEqual(sendLabel, "发送提示词模板 \(template.title)")

            XCTAssertEqual(
                PromptTemplateActionAccessibilityMetadata.value(for: .apply, isGenerating: false),
                "可填入输入框"
            )
            XCTAssertEqual(
                PromptTemplateActionAccessibilityMetadata.value(for: .send, isGenerating: false),
                "可直接发送"
            )
            for action in PromptTemplateActionAccessibilityMetadata.Action.allCases {
                XCTAssertEqual(
                    PromptTemplateActionAccessibilityMetadata.value(for: action, isGenerating: true),
                    "生成中，暂不可用"
                )
            }

            let applyHint = PromptTemplateActionAccessibilityMetadata.hint(for: .apply, template: template)
            XCTAssertTrue(applyHint.contains("composer"))
            XCTAssertTrue(applyHint.contains("聚焦输入框"))
            XCTAssertTrue(applyHint.contains("不会发送 prompt"))
            XCTAssertTrue(applyHint.contains("不会下载模型权重"))
            XCTAssertTrue(applyHint.contains("不会启动真实 runtime"))
            XCTAssertTrue(applyHint.contains("不会发送到云端服务"))

            let sendHint = PromptTemplateActionAccessibilityMetadata.hint(for: .send, template: template)
            XCTAssertTrue(sendHint.contains("本地模拟 runtime"))
            XCTAssertTrue(sendHint.contains("聚焦输入框"))
            XCTAssertTrue(sendHint.contains("不会下载模型权重"))
            XCTAssertTrue(sendHint.contains("不会启动真实 runtime"))
            XCTAssertTrue(sendHint.contains("不会发送到云端服务"))
            XCTAssertTrue(sendHint.contains("verified 门禁"))

            XCTAssertEqual(
                PromptTemplateActionAccessibilityMetadata.inputLabels(for: .apply, template: template),
                ["填入\(template.title)", "\(template.title)填入", "使用\(template.title)模板"]
            )
            XCTAssertEqual(
                PromptTemplateActionAccessibilityMetadata.inputLabels(for: .send, template: template),
                ["发送\(template.title)", "\(template.title)发送", "直接发送\(template.title)模板"]
            )

            for action in PromptTemplateActionAccessibilityMetadata.Action.allCases {
                let identifier = PromptTemplateActionAccessibilityMetadata.identifier(
                    for: action,
                    template: template
                )
                XCTAssertTrue(identifier.contains(template.id))
                XCTAssertTrue(identifier.hasSuffix(action.rawValue))
                XCTAssertTrue(identifiers.insert(identifier).inserted)
            }
        }

        XCTAssertEqual(identifiers.count, templates.count * 2)
    }

    func testInferenceIgnoresEmptyPrompt() {
        let engine = InferenceEngine()
        let initialCount = engine.messages.count

        engine.inputText = "   "
        engine.send(using: ModelCatalog.defaultModels[0])

        XCTAssertEqual(engine.messages.count, initialCount)
        XCTAssertFalse(engine.isGenerating)
    }

    func testInferenceAppliesPromptTemplateWithoutSending() {
        let engine = InferenceEngine()
        let template = PromptTemplateLibrary.defaultTemplates[0]
        let initialCount = engine.messages.count

        engine.applyTemplate(template)

        XCTAssertEqual(engine.inputText, template.prompt)
        XCTAssertEqual(engine.messages.count, initialCount)
        XCTAssertFalse(engine.isGenerating)
        XCTAssertNil(engine.lastPreparationReport)
    }

    func testInferenceUsesPromptTemplateForGeneration() {
        let engine = InferenceEngine()
        let model = ModelCatalog.defaultModels[0]
        let template = PromptTemplateLibrary.defaultTemplates.first { $0.category == .troubleshooting }!

        engine.useTemplate(template, model: model, availability: .staged)
        engine.stop()

        XCTAssertEqual(engine.inputText, "")
        XCTAssertTrue(engine.messages.contains { $0.role == .user && $0.text == template.prompt })
        XCTAssertEqual(engine.lastPreparationReport?.availability, .staged)
        XCTAssertEqual(engine.lastPreparationReport?.canRunRealWeights, false)
    }

    func testChatMessagesExposeAccessibilityMetadata() {
        let userMessage = ChatMessage(
            id: UUID(uuidString: "12345678-1234-5678-9ABC-123456789ABC")!,
            role: .user,
            text: "说明端侧部署",
            tokens: 8
        )
        let assistantMessage = ChatMessage(
            id: UUID(uuidString: "ABCDEF12-1234-5678-9ABC-123456789ABC")!,
            role: .assistant,
            text: "本地模拟输出",
            tokens: 16
        )
        let generatingMessage = ChatMessage(
            id: UUID(uuidString: "87654321-1234-5678-9ABC-123456789ABC")!,
            role: .assistant,
            text: "  \n",
            tokens: 0
        )
        let systemMessage = ChatMessage(
            id: UUID(uuidString: "FACEB00C-1234-5678-9ABC-123456789ABC")!,
            role: .system,
            text: "当前为模拟运行",
            tokens: 0
        )

        XCTAssertEqual(ChatMessageAccessibilityMetadata.label(for: userMessage), "用户消息")
        XCTAssertEqual(ChatMessageAccessibilityMetadata.label(for: assistantMessage), "本地模型消息")
        XCTAssertEqual(ChatMessageAccessibilityMetadata.label(for: systemMessage), "系统状态消息")

        let userValue = ChatMessageAccessibilityMetadata.value(for: userMessage)
        XCTAssertTrue(userValue.contains("说明端侧部署"))
        XCTAssertTrue(userValue.contains("8 tokens"))
        XCTAssertTrue(userValue.contains("本地会话消息"))

        let assistantValue = ChatMessageAccessibilityMetadata.value(for: assistantMessage)
        XCTAssertTrue(assistantValue.contains("本地模拟输出"))
        XCTAssertTrue(assistantValue.contains("16 tokens"))

        let generatingValue = ChatMessageAccessibilityMetadata.value(for: generatingMessage)
        XCTAssertTrue(generatingValue.contains("正在生成"))
        XCTAssertTrue(generatingValue.contains("本地模型正在写入模拟输出"))
        XCTAssertTrue(generatingValue.contains("0 tokens"))

        let hint = ChatMessageAccessibilityMetadata.hint
        XCTAssertTrue(hint.contains("只展示本地会话内容"))
        XCTAssertTrue(hint.contains("不会下载模型权重"))
        XCTAssertTrue(hint.contains("不会启动真实 runtime"))
        XCTAssertTrue(hint.contains("不会发送到云端服务"))
        XCTAssertTrue(hint.contains("verified 门禁"))

        XCTAssertEqual(
            ChatMessageAccessibilityMetadata.inputLabels(for: userMessage),
            ["用户消息", "查看用户消息", "消息 12345678"]
        )
        XCTAssertEqual(
            ChatMessageAccessibilityMetadata.inputLabels(for: assistantMessage),
            ["本地模型消息", "查看本地模型消息", "消息 abcdef12"]
        )

        XCTAssertEqual(
            ChatMessageAccessibilityMetadata.identifier(for: userMessage),
            "chat-message-user-12345678"
        )
        XCTAssertEqual(
            ChatMessageAccessibilityMetadata.identifier(for: assistantMessage),
            "chat-message-assistant-abcdef12"
        )
        XCTAssertEqual(
            ChatMessageAccessibilityMetadata.identifier(for: systemMessage),
            "chat-message-system-faceb00c"
        )
        XCTAssertFalse(
            ChatMessageAccessibilityMetadata.identifier(for: userMessage)
                .contains(userMessage.text)
        )
        XCTAssertEqual(
            Set(
                [userMessage, assistantMessage, generatingMessage, systemMessage].map {
                    ChatMessageAccessibilityMetadata.identifier(for: $0)
                }
            ).count,
            4
        )
    }

    func testInferenceCreatesSelectsAndDeletesNamedSessions() {
        let engine = InferenceEngine()
        let firstSession = engine.sessions[0]

        let secondID = engine.createSession(title: "部署讨论")

        XCTAssertEqual(engine.sessions.count, 2)
        XCTAssertEqual(engine.activeSessionID, secondID)
        XCTAssertEqual(engine.activeSessionTitle, "部署讨论")

        engine.selectSession(firstSession)

        XCTAssertEqual(engine.activeSessionID, firstSession.id)
        XCTAssertEqual(engine.messages, firstSession.messages)

        guard let secondSession = engine.sessions.first(where: { $0.id == secondID }) else {
            return XCTFail("second session should exist")
        }
        engine.deleteSession(secondSession)

        XCTAssertEqual(engine.sessions.count, 1)
        XCTAssertEqual(engine.sessions[0].id, firstSession.id)
    }

    func testInferenceAutoNamesAndExportsActiveSession() {
        let engine = InferenceEngine()
        let model = ModelCatalog.defaultModels[0]

        engine.inputText = "请说明本地部署和隐私保护的组合方案"
        engine.send(using: model, availability: .staged)
        engine.stop()

        XCTAssertNotEqual(engine.activeSessionTitle, "新对话")
        XCTAssertTrue(engine.activeSessionTitle.contains("请说明本地部署"))

        let exported = engine.exportActiveSessionText(modelName: model.name)
        XCTAssertTrue(exported.contains("# \(engine.activeSessionTitle)"))
        XCTAssertTrue(exported.contains("模型：\(model.name)"))
        XCTAssertTrue(exported.contains("## 用户"))
        XCTAssertTrue(exported.contains("请说明本地部署"))

        let exportDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("LocalGemmaExport-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: exportDirectory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: exportDirectory)
        }

        let exportURL = try? engine.exportActiveSessionMarkdownFile(
            modelName: model.name,
            directoryURL: exportDirectory
        )
        XCTAssertEqual(exportURL?.pathExtension, "md")
        XCTAssertTrue(FileManager.default.fileExists(atPath: exportURL?.path ?? ""))
        XCTAssertEqual(try? String(contentsOf: exportURL ?? exportDirectory), exported)
    }

    func testInferenceResetConversationRestoresWelcomeState() {
        let engine = InferenceEngine()
        let model = ModelCatalog.defaultModels[0]

        engine.inputText = "说明本地模型"
        engine.send(using: model)
        engine.resetConversation()

        XCTAssertEqual(engine.messages.count, 2)
        XCTAssertEqual(engine.inputText, "")
        XCTAssertFalse(engine.isGenerating)
        XCTAssertNil(engine.lastPreparationReport)
        XCTAssertTrue(engine.lastResultWasSimulated)
        XCTAssertEqual(engine.currentBackend, .coreMLANE)
        XCTAssertTrue(engine.messages[0].text.contains("模拟运行"))
    }

    func testInferenceRecordsSelectedArtifactAvailability() {
        let engine = InferenceEngine()
        let model = ModelCatalog.defaultModels[0]

        engine.inputText = "启动真实模型"
        engine.send(using: model, availability: .staged)
        engine.stop()

        XCTAssertEqual(engine.lastPreparationReport?.availability, .staged)
        XCTAssertEqual(engine.lastPreparationReport?.canRunRealWeights, false)
        XCTAssertEqual(engine.lastPreparationReport?.activeBackend, .coreMLANE)
    }

    func testWorkspaceTabsExposeKeyboardShortcuts() {
        let shortcutMap = Dictionary(
            uniqueKeysWithValues: WorkspaceTab.allCases.map { ($0.title, $0.shortcutKey) }
        )

        XCTAssertEqual(WorkspaceTab.allCases.map(\.title), ["推理", "模型", "提示词", "设置"])
        XCTAssertEqual(shortcutMap["推理"], "1")
        XCTAssertEqual(shortcutMap["模型"], "2")
        XCTAssertEqual(shortcutMap["提示词"], "3")
        XCTAssertEqual(shortcutMap["设置"], "4")
    }

    func testWorkspaceCommandMenuCoversWorkspaceTabs() {
        let commandItems = WorkspaceTab.commandItems

        XCTAssertEqual(WorkspaceTab.commandMenuTitle, "工作区")
        XCTAssertEqual(commandItems.map(\.tab), WorkspaceTab.allCases)
        XCTAssertEqual(commandItems.map(\.title), ["推理", "模型", "提示词", "设置"])
        XCTAssertEqual(commandItems.map(\.title), WorkspaceTab.allCases.map(\.title))
        XCTAssertEqual(commandItems.map { String($0.shortcutKey) }, ["1", "2", "3", "4"])
    }

    func testSessionCommandMenuCoversFocusedSessionActions() {
        let commandItems = SessionCommandAction.commandItems

        XCTAssertEqual(SessionCommandAction.commandMenuTitle, "会话")
        XCTAssertEqual(commandItems.map(\.action), SessionCommandAction.allCases)
        XCTAssertEqual(commandItems.map(\.title), ["新建会话", "导出当前会话"])
        XCTAssertEqual(commandItems.map { String($0.shortcutKey) }, ["n", "e"])
        XCTAssertEqual(commandItems.map(\.requiresShift), [false, true])
        XCTAssertEqual(SessionCommandAction.createSession.focusReason, .createSession)
        XCTAssertNil(SessionCommandAction.exportSession.focusReason)
        XCTAssertTrue(
            Set(SessionCommandAction.commandItems.map(\.shortcutKey)).isDisjoint(
                with: Set(WorkspaceTab.commandItems.map(\.shortcutKey))
            )
        )
    }

    func testSessionCommandFocusedRouteDescribesAvailabilityAndFocusPolicy() {
        var performedActions: [SessionCommandAction] = []
        let actions = SessionCommandActions(
            createSession: {
                performedActions.append(.createSession)
            },
            exportSession: {
                performedActions.append(.exportSession)
            }
        )

        XCTAssertFalse(SessionCommandRoutingPolicy.isEnabled(hasFocusedActions: false))
        XCTAssertTrue(SessionCommandRoutingPolicy.isEnabled(hasFocusedActions: true))
        XCTAssertTrue(
            SessionCommandRoutingPolicy.requestsComposerFocus(after: .createSession)
        )
        XCTAssertFalse(
            SessionCommandRoutingPolicy.requestsComposerFocus(after: .exportSession)
        )

        actions.perform(.createSession)
        actions.perform(.exportSession)

        XCTAssertEqual(performedActions, [.createSession, .exportSession])
    }

    func testSessionBarActionsExposeAccessibilityMetadata() {
        let createLabel = SessionBarActionAccessibilityMetadata.label(for: .createSession)
        let exportLabel = SessionBarActionAccessibilityMetadata.label(for: .exportSession)

        XCTAssertEqual(createLabel, SessionCommandAction.createSession.title)
        XCTAssertEqual(exportLabel, SessionCommandAction.exportSession.title)
        XCTAssertEqual(
            SessionBarActionAccessibilityMetadata.identifier(for: .createSession),
            "session-bar-action-createSession"
        )
        XCTAssertEqual(
            SessionBarActionAccessibilityMetadata.identifier(for: .exportSession),
            "session-bar-action-exportSession"
        )

        let createValue = SessionBarActionAccessibilityMetadata.value(for: .createSession)
        let createHint = SessionBarActionAccessibilityMetadata.hint(for: .createSession)
        XCTAssertTrue(createValue.contains("Command N"))
        XCTAssertTrue(createValue.contains("本地会话"))
        XCTAssertTrue(createHint.contains("输入焦点"))
        XCTAssertTrue(createHint.contains("composer"))
        XCTAssertTrue(createHint.contains("不会发送 prompt"))
        XCTAssertTrue(
            SessionCommandRoutingPolicy.requestsComposerFocus(after: .createSession)
        )
        XCTAssertTrue(
            SessionBarActionAccessibilityMetadata.inputLabels(for: .createSession)
                .contains("新建会话")
        )

        let exportValue = SessionBarActionAccessibilityMetadata.value(for: .exportSession)
        let exportHint = SessionBarActionAccessibilityMetadata.hint(for: .exportSession)
        XCTAssertTrue(exportValue.contains("Command Shift E"))
        XCTAssertTrue(exportValue.contains("当前本地会话"))
        XCTAssertTrue(exportHint.contains("本地 Markdown"))
        XCTAssertTrue(exportHint.contains("文本分享兜底"))
        XCTAssertTrue(exportHint.contains("不会把会话发送到云端服务"))
        XCTAssertFalse(
            SessionCommandRoutingPolicy.requestsComposerFocus(after: .exportSession)
        )
        XCTAssertTrue(
            SessionBarActionAccessibilityMetadata.inputLabels(for: .exportSession)
                .contains("导出当前会话")
        )

        XCTAssertTrue(
            SessionCommandAction.allCases.allSatisfy {
                !SessionBarActionAccessibilityMetadata.label(for: $0).isEmpty
                    && !SessionBarActionAccessibilityMetadata.value(for: $0).isEmpty
                    && !SessionBarActionAccessibilityMetadata.hint(for: $0).isEmpty
                    && !SessionBarActionAccessibilityMetadata.inputLabels(for: $0).isEmpty
                    && !SessionBarActionAccessibilityMetadata.identifier(for: $0).isEmpty
            }
        )
    }

    func testSessionChipActionsExposeAccessibilityMetadata() {
        let defaultSession = ChatSession(
            id: UUID(uuidString: "11111111-2222-3333-4444-555555555555")!,
            title: "新对话",
            messages: [
                ChatMessage(role: .system, text: "模拟运行", tokens: 2),
                ChatMessage(role: .assistant, text: "准备就绪", tokens: 4)
            ]
        )
        let namedSession = ChatSession(
            id: UUID(uuidString: "ABCDEF12-2222-3333-4444-555555555555")!,
            title: "部署方案",
            messages: defaultSession.messages + [
                ChatMessage(role: .user, text: "解释部署", tokens: 6)
            ]
        )

        XCTAssertEqual(SessionChipActionAccessibilityMetadata.Action.allCases, [.select, .delete])
        XCTAssertFalse(
            SessionChipActionAccessibilityMetadata.canDelete(
                session: defaultSession,
                isActive: true
            )
        )
        XCTAssertTrue(
            SessionChipActionAccessibilityMetadata.canDelete(
                session: defaultSession,
                isActive: false
            )
        )
        XCTAssertTrue(
            SessionChipActionAccessibilityMetadata.canDelete(
                session: namedSession,
                isActive: true
            )
        )

        XCTAssertEqual(
            SessionChipActionAccessibilityMetadata.label(for: .select, session: namedSession),
            "选择会话 部署方案"
        )
        XCTAssertEqual(
            SessionChipActionAccessibilityMetadata.label(for: .delete, session: namedSession),
            "删除会话 部署方案"
        )

        let selectValue = SessionChipActionAccessibilityMetadata.value(
            for: .select,
            session: namedSession,
            isActive: true,
            canDelete: true
        )
        XCTAssertTrue(selectValue.contains("当前本地会话"))
        XCTAssertTrue(selectValue.contains("3 条消息"))
        XCTAssertTrue(
            SessionChipActionAccessibilityMetadata.value(
                for: .select,
                session: namedSession,
                isActive: false,
                canDelete: true
            ).contains("未选中本地会话")
        )

        let selectHint = SessionChipActionAccessibilityMetadata.hint(
            for: .select,
            session: namedSession,
            isActive: false,
            canDelete: true
        )
        XCTAssertTrue(selectHint.contains("切换到这个本地会话"))
        XCTAssertTrue(selectHint.contains("composer"))
        XCTAssertTrue(selectHint.contains("不会发送 prompt"))
        XCTAssertTrue(selectHint.contains("不会下载模型权重"))
        XCTAssertTrue(selectHint.contains("不会启动真实 runtime"))
        XCTAssertTrue(selectHint.contains("不会发送到云端服务"))
        XCTAssertTrue(selectHint.contains("verified 门禁"))

        let disabledDeleteValue = SessionChipActionAccessibilityMetadata.value(
            for: .delete,
            session: defaultSession,
            isActive: true,
            canDelete: false
        )
        XCTAssertTrue(disabledDeleteValue.contains("不可删除"))
        XCTAssertTrue(disabledDeleteValue.contains("默认空白当前会话"))

        let disabledDeleteHint = SessionChipActionAccessibilityMetadata.hint(
            for: .delete,
            session: defaultSession,
            isActive: true,
            canDelete: false
        )
        XCTAssertTrue(disabledDeleteHint.contains("默认空白当前会话不可删除"))
        XCTAssertTrue(disabledDeleteHint.contains("不删除模型 artifact 或权重"))
        XCTAssertTrue(disabledDeleteHint.contains("不发送到云端服务"))
        XCTAssertTrue(disabledDeleteHint.contains("verified 门禁"))

        let enabledDeleteValue = SessionChipActionAccessibilityMetadata.value(
            for: .delete,
            session: namedSession,
            isActive: true,
            canDelete: true
        )
        XCTAssertTrue(enabledDeleteValue.contains("可删除当前本地会话"))
        XCTAssertTrue(enabledDeleteValue.contains("3 条消息"))
        XCTAssertTrue(
            SessionChipActionAccessibilityMetadata.value(
                for: .delete,
                session: namedSession,
                isActive: false,
                canDelete: true
            ).contains("可删除未选中本地会话")
        )

        let enabledDeleteHint = SessionChipActionAccessibilityMetadata.hint(
            for: .delete,
            session: namedSession,
            isActive: true,
            canDelete: true
        )
        XCTAssertTrue(enabledDeleteHint.contains("只删除会话记录"))
        XCTAssertTrue(enabledDeleteHint.contains("不删除模型 artifact 或权重"))
        XCTAssertTrue(enabledDeleteHint.contains("不改变 artifact verified 门禁"))

        XCTAssertEqual(
            SessionChipActionAccessibilityMetadata.inputLabels(for: .select, session: namedSession),
            ["选择部署方案", "部署方案会话", "切换会话 abcdef12"]
        )
        XCTAssertEqual(
            SessionChipActionAccessibilityMetadata.inputLabels(for: .delete, session: namedSession),
            ["删除部署方案", "移除部署方案会话", "删除会话 abcdef12"]
        )

        let selectIdentifier = SessionChipActionAccessibilityMetadata.identifier(
            for: .select,
            session: namedSession
        )
        let deleteIdentifier = SessionChipActionAccessibilityMetadata.identifier(
            for: .delete,
            session: namedSession
        )
        XCTAssertEqual(selectIdentifier, "session-chip-select-abcdef12")
        XCTAssertEqual(deleteIdentifier, "session-chip-delete-abcdef12")
        XCTAssertFalse(selectIdentifier.contains(namedSession.title))
        XCTAssertFalse(deleteIdentifier.contains(namedSession.title))
    }

    func testSelectionAccessibilityMetadataDescribesWorkspaceAndSessions() {
        XCTAssertFalse(WorkspaceLayoutMode.portrait.usesDetailedSidebar)
        XCTAssertFalse(WorkspaceLayoutMode.landscapeCompact.usesDetailedSidebar)
        XCTAssertTrue(WorkspaceLayoutMode.landscapeRegular.usesDetailedSidebar)

        XCTAssertEqual(
            WorkspaceTab.allCases.map(\.sidebarSubtitle),
            ["本地对话与导出", "模型与部署状态", "提示词模板", "外观与芯片策略"]
        )
        XCTAssertTrue(WorkspaceTab.allCases.map(\.sidebarSubtitle).allSatisfy { !$0.isEmpty })
        XCTAssertEqual(
            WorkspaceTab.allCases.map { SelectionAccessibilityMetadata.workspaceLabel(for: $0) },
            ["推理工作区", "模型工作区", "提示词工作区", "设置工作区"]
        )
        XCTAssertEqual(SelectionAccessibilityMetadata.selectionValue(isSelected: true), "已选中")
        XCTAssertEqual(SelectionAccessibilityMetadata.selectionValue(isSelected: false), "未选中")
        XCTAssertEqual(SelectionAccessibilityMetadata.sessionSelectLabel(title: "部署方案"), "选择会话 部署方案")
        XCTAssertEqual(SelectionAccessibilityMetadata.sessionDeleteLabel(title: "部署方案"), "删除会话 部署方案")
        XCTAssertEqual(SelectionAccessibilityMetadata.sessionValue(isActive: true), "当前会话")
        XCTAssertEqual(SelectionAccessibilityMetadata.sessionValue(isActive: false), "未选中")
    }

    func testWorkspaceNavigationAccessibilityMetadataDescribesShortcutsAndVoiceControl() {
        XCTAssertEqual(WorkspaceNavigationAccessibilityMetadata.value(isSelected: true), "已选中")
        XCTAssertEqual(WorkspaceNavigationAccessibilityMetadata.value(isSelected: false), "未选中")

        for tab in WorkspaceTab.allCases {
            XCTAssertEqual(
                WorkspaceNavigationAccessibilityMetadata.label(for: tab),
                expectedWorkspaceNavigationLabel(for: tab),
                "Unexpected workspace navigation label for \(tab.rawValue)."
            )
            XCTAssertEqual(
                WorkspaceNavigationAccessibilityMetadata.compactIdentifier(for: tab),
                expectedCompactWorkspaceIdentifier(for: tab),
                "Unexpected compact workspace identifier for \(tab.rawValue)."
            )
            XCTAssertEqual(
                WorkspaceNavigationAccessibilityMetadata.sidebarIdentifier(for: tab),
                expectedSidebarWorkspaceIdentifier(for: tab),
                "Unexpected sidebar workspace identifier for \(tab.rawValue)."
            )

            let hint = WorkspaceNavigationAccessibilityMetadata.hint(for: tab)
            XCTAssertFalse(hint.isEmpty, "Hint should not be empty for \(tab.rawValue).")
            XCTAssertTrue(
                hint.contains("Command \(tab.shortcutKey)"),
                "Hint should include shortcut for \(tab.rawValue)."
            )
            XCTAssertTrue(
                hint.contains(tab.sidebarSubtitle),
                "Hint should include sidebar subtitle for \(tab.rawValue)."
            )
            XCTAssertTrue(
                hint.contains("只切换本地工作区"),
                "Hint should describe local workspace switching for \(tab.rawValue)."
            )
            XCTAssertTrue(
                hint.contains("不会下载模型权重"),
                "Hint should preserve no model download boundary for \(tab.rawValue)."
            )
            XCTAssertTrue(
                hint.contains("真实 runtime"),
                "Hint should preserve runtime boundary for \(tab.rawValue)."
            )

            let inputLabels = WorkspaceNavigationAccessibilityMetadata.inputLabels(for: tab)
            XCTAssertFalse(
                inputLabels.isEmpty,
                "Input labels should not be empty for \(tab.rawValue)."
            )
            XCTAssertTrue(
                inputLabels.contains("\(tab.title)工作区"),
                "Input labels should include workspace title for \(tab.rawValue)."
            )
        }
    }

    private func expectedWorkspaceNavigationLabel(for tab: WorkspaceTab) -> String {
        switch tab {
        case .chat:
            return "推理工作区"
        case .models:
            return "模型工作区"
        case .prompts:
            return "提示词工作区"
        case .settings:
            return "设置工作区"
        }
    }

    private func expectedCompactWorkspaceIdentifier(for tab: WorkspaceTab) -> String {
        switch tab {
        case .chat:
            return "workspace-tab-chat"
        case .models:
            return "workspace-tab-models"
        case .prompts:
            return "workspace-tab-prompts"
        case .settings:
            return "workspace-tab-settings"
        }
    }

    private func expectedSidebarWorkspaceIdentifier(for tab: WorkspaceTab) -> String {
        switch tab {
        case .chat:
            return "workspace-sidebar-tab-chat"
        case .models:
            return "workspace-sidebar-tab-models"
        case .prompts:
            return "workspace-sidebar-tab-prompts"
        case .settings:
            return "workspace-sidebar-tab-settings"
        }
    }

    func testComposerInputMetadataAndFocusPolicyDescribeEntryPoints() {
        XCTAssertEqual(ComposerInputMetadata.textFieldLabel, "本地模型输入")
        XCTAssertTrue(ComposerInputMetadata.textFieldHint.contains("Command Return"))
        XCTAssertTrue(ComposerInputMetadata.textFieldInputLabels.contains("输入 prompt"))
        XCTAssertEqual(ComposerInputMetadata.textFieldIdentifier, "composer-input-field")

        XCTAssertEqual(ComposerInputMetadata.actionLabel(isGenerating: false), "发送提示词")
        XCTAssertEqual(ComposerInputMetadata.actionLabel(isGenerating: true), "停止生成")
        XCTAssertTrue(ComposerInputMetadata.actionInputLabels(isGenerating: false).contains("发送提示词"))
        XCTAssertTrue(ComposerInputMetadata.actionInputLabels(isGenerating: true).contains("停止生成"))
        XCTAssertEqual(ComposerInputMetadata.actionIdentifier(isGenerating: false), "composer-send-button")
        XCTAssertEqual(ComposerInputMetadata.actionIdentifier(isGenerating: true), "composer-stop-button")
        XCTAssertEqual(
            ComposerInputMetadata.actionValue(text: "   ", isGenerating: false),
            "输入为空"
        )
        XCTAssertEqual(
            ComposerInputMetadata.actionValue(text: "说明端侧部署", isGenerating: false),
            "可发送"
        )
        XCTAssertEqual(
            ComposerInputMetadata.actionValue(text: "", isGenerating: true),
            "生成中"
        )
        XCTAssertTrue(ComposerInputMetadata.isActionDisabled(text: "  \n", isGenerating: false))
        XCTAssertFalse(ComposerInputMetadata.isActionDisabled(text: "说明端侧部署", isGenerating: false))
        XCTAssertFalse(ComposerInputMetadata.isActionDisabled(text: "", isGenerating: true))

        let composerActionHints = [
            ComposerInputMetadata.actionHint(text: "   ", isGenerating: false),
            ComposerInputMetadata.actionHint(text: "说明端侧部署", isGenerating: false),
            ComposerInputMetadata.actionHint(text: "", isGenerating: true)
        ]
        XCTAssertTrue(composerActionHints[0].contains("输入内容后可发送"))
        XCTAssertTrue(composerActionHints[1].contains("发送当前输入给本地模拟 runtime"))
        XCTAssertTrue(composerActionHints[2].contains("停止当前模拟生成"))
        for hint in composerActionHints {
            XCTAssertTrue(hint.contains("不会下载模型权重"))
            XCTAssertTrue(hint.contains("不会启动真实 runtime"))
            XCTAssertTrue(hint.contains("不会发送到云端服务"))
            XCTAssertTrue(hint.contains("verified 门禁"))
        }

        XCTAssertEqual(
            ComposerFocusReason.allCases,
            [.openChatWorkspace, .createSession, .selectSession, .applyTemplate, .sendTemplate]
        )
        XCTAssertTrue(ComposerFocusPolicy.requestsComposerFocus(afterSelecting: .chat))
        XCTAssertFalse(ComposerFocusPolicy.requestsComposerFocus(afterSelecting: .models))
        XCTAssertTrue(
            ComposerFocusReason.allCases.allSatisfy {
                ComposerFocusPolicy.requestsComposerFocus(after: $0)
            }
        )

        let templateRequest = ComposerFocusRequest.initial.next(for: .applyTemplate)
        XCTAssertEqual(templateRequest.sequence, 1)
        XCTAssertEqual(templateRequest.reason, .applyTemplate)
        XCTAssertTrue(templateRequest.shouldFocus)
        XCTAssertEqual(templateRequest.next(for: .selectSession).sequence, 2)
        XCTAssertFalse(ComposerFocusRequest.initial.shouldFocus)
    }

    func testWorkspaceLayoutModeResolvesLandscapeVariants() {
        XCTAssertEqual(
            WorkspaceLayoutMode.resolve(for: CGSize(width: 390, height: 844)),
            .portrait
        )
        XCTAssertEqual(
            WorkspaceLayoutMode.resolve(for: CGSize(width: 430, height: 932)),
            .portrait
        )
        XCTAssertEqual(
            WorkspaceLayoutMode.resolve(for: CGSize(width: 844, height: 390)),
            .landscapeCompact
        )
        XCTAssertEqual(
            WorkspaceLayoutMode.resolve(for: CGSize(width: 1180, height: 820)),
            .landscapeRegular
        )
    }

    func testWorkspaceLayoutModeSupportsIPadWideContainers() {
        let iPadProPortrait = WorkspaceLayoutMode.resolve(
            for: CGSize(width: 1024, height: 1366)
        )
        let largeWindow = WorkspaceLayoutMode.resolve(
            for: CGSize(width: 1000, height: 760)
        )
        let mediumPortrait = WorkspaceLayoutMode.resolve(
            for: CGSize(width: 820, height: 1180)
        )

        XCTAssertEqual(iPadProPortrait, .landscapeRegular)
        XCTAssertTrue(iPadProPortrait.usesSidebar)
        XCTAssertEqual(largeWindow, .landscapeRegular)
        XCTAssertTrue(largeWindow.usesSidebar)
        XCTAssertEqual(mediumPortrait, .landscapeCompact)
        XCTAssertTrue(mediumPortrait.usesSidebar)
    }

    func testWorkspaceLayoutModeSupportsDesktopWindowSizes() {
        let desktopWide = WorkspaceLayoutMode.resolve(
            for: CGSize(width: 1280, height: 800)
        )
        let desktopStandard = WorkspaceLayoutMode.resolve(
            for: CGSize(width: 1024, height: 768)
        )
        let narrowDesktop = WorkspaceLayoutMode.resolve(
            for: CGSize(width: 760, height: 720)
        )
        let splitWindow = WorkspaceLayoutMode.resolve(
            for: CGSize(width: 680, height: 900)
        )
        let desktopSidebarWidth = desktopWide.sidebarWidth(
            for: CGSize(width: 1280, height: 800)
        )

        XCTAssertEqual(desktopWide, .landscapeRegular)
        XCTAssertTrue(desktopWide.usesSidebar)
        XCTAssertEqual(desktopStandard, .landscapeRegular)
        XCTAssertTrue(desktopStandard.usesSidebar)
        XCTAssertEqual(narrowDesktop, .landscapeCompact)
        XCTAssertTrue(narrowDesktop.usesSidebar)
        XCTAssertEqual(splitWindow, .portrait)
        XCTAssertFalse(splitWindow.usesSidebar)
        XCTAssertGreaterThanOrEqual(desktopSidebarWidth, 320)
        XCTAssertLessThanOrEqual(desktopSidebarWidth, 390)
    }

    func testSessionSidebarLayoutPolicyConstrainsWideChatHistory() {
        let phonePortrait = CGSize(width: 390, height: 844)
        let compactLandscape = CGSize(width: 700, height: 390)
        let iPadRegular = CGSize(width: 1024, height: 768)
        let desktopRegular = CGSize(width: 1366, height: 900)

        XCTAssertEqual(
            SessionSidebarLayoutPolicy.width(
                for: phonePortrait,
                layoutMode: WorkspaceLayoutMode.resolve(for: phonePortrait)
            ),
            0
        )
        XCTAssertEqual(
            SessionSidebarLayoutPolicy.width(
                for: compactLandscape,
                layoutMode: WorkspaceLayoutMode.resolve(for: compactLandscape)
            ),
            SessionSidebarLayoutPolicy.minimumWidth
        )
        XCTAssertEqual(
            SessionSidebarLayoutPolicy.width(
                for: iPadRegular,
                layoutMode: WorkspaceLayoutMode.resolve(for: iPadRegular)
            ),
            286.72,
            accuracy: 0.01
        )
        XCTAssertEqual(
            SessionSidebarLayoutPolicy.width(
                for: desktopRegular,
                layoutMode: WorkspaceLayoutMode.resolve(for: desktopRegular)
            ),
            SessionSidebarLayoutPolicy.maximumWidth
        )

        let sidebarSizes = [
            CGSize(width: 700, height: 390),
            CGSize(width: 980, height: 700),
            CGSize(width: 1180, height: 820),
            CGSize(width: 1440, height: 960)
        ]

        for size in sidebarSizes {
            let width = SessionSidebarLayoutPolicy.width(
                for: size,
                layoutMode: WorkspaceLayoutMode.resolve(for: size)
            )
            XCTAssertGreaterThanOrEqual(width, SessionSidebarLayoutPolicy.minimumWidth)
            XCTAssertLessThanOrEqual(width, SessionSidebarLayoutPolicy.maximumWidth)
        }
    }

    func testModelLibraryLayoutModeSupportsWideModelWorkflows() {
        let phonePortrait = ModelLibraryLayoutMode.resolve(
            for: CGSize(width: 390, height: 844)
        )
        let narrowSplit = ModelLibraryLayoutMode.resolve(
            for: CGSize(width: 680, height: 900)
        )
        let widePortraitPane = ModelLibraryLayoutMode.resolve(
            for: CGSize(width: 820, height: 1180)
        )
        let wideDesktopPane = ModelLibraryLayoutMode.resolve(
            for: CGSize(width: 1000, height: 760)
        )
        let desktopWide = ModelLibraryLayoutMode.resolve(
            for: CGSize(width: 1280, height: 800)
        )

        XCTAssertEqual(phonePortrait, .singleColumn)
        XCTAssertEqual(narrowSplit, .singleColumn)
        XCTAssertEqual(widePortraitPane, .twoColumn)
        XCTAssertEqual(wideDesktopPane, .twoColumn)
        XCTAssertEqual(desktopWide, .twoColumn)
        XCTAssertEqual(
            phonePortrait.controlColumnWidth(for: CGSize(width: 390, height: 844)),
            0
        )
        XCTAssertGreaterThanOrEqual(
            widePortraitPane.controlColumnWidth(for: CGSize(width: 820, height: 1180)),
            300
        )
        XCTAssertLessThanOrEqual(
            wideDesktopPane.controlColumnWidth(for: CGSize(width: 1280, height: 800)),
            390
        )
    }

    func testModelCapsuleExposesOverallAccessibilityMetadata() {
        let model = ModelCatalog.defaultModels[0]

        XCTAssertEqual(
            ModelCapsuleAccessibilityMetadata.label(model: model),
            "当前模型 Gemma 1.5B Local"
        )
        XCTAssertEqual(ModelCapsuleAccessibilityMetadata.identifier, "header-model-capsule")
        XCTAssertEqual(
            ModelCapsuleAccessibilityMetadata.inputLabels(model: model),
            ["模型状态", "当前模型", "Gemma 1.5B Local 状态"]
        )

        let hint = ModelCapsuleAccessibilityMetadata.hint
        XCTAssertTrue(hint.contains("本地模型状态摘要"))
        XCTAssertTrue(hint.contains("不会下载模型权重"))
        XCTAssertTrue(hint.contains("不会启动真实 runtime"))
        XCTAssertTrue(hint.contains("不会发送到云端服务"))
        XCTAssertTrue(hint.contains("不会绕过 verified 门禁"))

        XCTAssertEqual(ModelCapsuleAccessibilityMetadata.speedValue(36), "36.0 tok/s")
        XCTAssertEqual(ModelCapsuleAccessibilityMetadata.memoryValue(768), "768M")
        XCTAssertEqual(ModelCapsuleAccessibilityMetadata.memoryValue(1536), "1.5G")
        XCTAssertEqual(
            ModelCapsuleAccessibilityMetadata.artifactDescription(.missing),
            "artifact missing，缺少本地模型文件"
        )
        XCTAssertEqual(
            ModelCapsuleAccessibilityMetadata.artifactDescription(.staged),
            "artifact staged，文件已暂存但等待 SHA-256 校验"
        )
        XCTAssertEqual(
            ModelCapsuleAccessibilityMetadata.artifactDescription(.verified),
            "artifact verified，已通过本地校验"
        )

        let missingValue = ModelCapsuleAccessibilityMetadata.value(
            model: model,
            readiness: 0.76,
            tokensPerSecond: 36,
            memoryUsageMB: 512,
            backend: .coreMLANE,
            availability: .missing,
            isGenerating: false,
            isSimulated: true
        )
        XCTAssertTrue(missingValue.contains("Gemma 1.5B Local"))
        XCTAssertTrue(missingValue.contains("1.5B"))
        XCTAssertTrue(missingValue.contains("4-bit"))
        XCTAssertTrue(missingValue.contains("安装状态 Simulation"))
        XCTAssertTrue(missingValue.contains("运行标记 SIM"))
        XCTAssertTrue(missingValue.contains("本地模拟输出"))
        XCTAssertTrue(missingValue.contains("artifact missing"))
        XCTAssertTrue(missingValue.contains("生成状态 待导入"))
        XCTAssertTrue(missingValue.contains("后端 Core ML + ANE"))
        XCTAssertTrue(missingValue.contains("速度 36.0 tok/s"))
        XCTAssertTrue(missingValue.contains("内存 512M"))
        XCTAssertTrue(missingValue.contains("准备度 76%"))

        let stagedGeneratingValue = ModelCapsuleAccessibilityMetadata.value(
            model: model,
            readiness: 0.87,
            tokensPerSecond: 42.4,
            memoryUsageMB: 1800,
            backend: .metalPerformanceShaders,
            availability: .staged,
            isGenerating: true,
            isSimulated: true
        )
        XCTAssertTrue(stagedGeneratingValue.contains("artifact staged"))
        XCTAssertTrue(stagedGeneratingValue.contains("生成状态 生成中"))
        XCTAssertTrue(stagedGeneratingValue.contains("后端 Metal fallback"))
        XCTAssertTrue(stagedGeneratingValue.contains("速度 42.4 tok/s"))
        XCTAssertTrue(stagedGeneratingValue.contains("内存 1.8G"))
        XCTAssertTrue(stagedGeneratingValue.contains("准备度 87%"))

        let verifiedRealValue = ModelCapsuleAccessibilityMetadata.value(
            model: model,
            readiness: 1,
            tokensPerSecond: 53.2,
            memoryUsageMB: 2048,
            backend: .coreMLANE,
            availability: .verified,
            isGenerating: false,
            isSimulated: false
        )
        XCTAssertTrue(verifiedRealValue.contains("运行标记 REAL"))
        XCTAssertTrue(verifiedRealValue.contains("artifact verified"))
        XCTAssertTrue(verifiedRealValue.contains("生成状态 已就绪"))
        XCTAssertTrue(verifiedRealValue.contains("准备度 100%"))
        XCTAssertTrue(verifiedRealValue.contains("需 artifact verified 后才可进入真实运行计划"))
    }

    func testModelDetailColumnExposesAccessibilityMetadata() {
        let model = ModelCatalog.defaultModels[0]
        let missingValidation = LocalArtifactValidator.validate(
            manifest: model.artifactManifest,
            presentFiles: []
        )
        let missingReport = LocalRuntimePlanner.preparationReport(
            for: model,
            validation: missingValidation
        )

        XCTAssertEqual(
            ModelDetailAccessibilityMetadata.label(model: model),
            "模型详情 Gemma 1.5B Local"
        )
        XCTAssertEqual(ModelDetailAccessibilityMetadata.identifier, "model-detail-summary")
        XCTAssertEqual(
            ModelDetailAccessibilityMetadata.inputLabels(model: model),
            ["模型详情", "查看模型详情", "Gemma 1.5B Local 详情"]
        )

        let hint = ModelDetailAccessibilityMetadata.hint
        XCTAssertTrue(hint.contains("本地模型详情"))
        XCTAssertTrue(hint.contains("不会下载模型权重"))
        XCTAssertTrue(hint.contains("不会启动真实 runtime"))
        XCTAssertTrue(hint.contains("不会发送到云端服务"))
        XCTAssertTrue(hint.contains("verified 门禁"))

        let missingValue = ModelDetailAccessibilityMetadata.value(
            model: model,
            validation: missingValidation,
            report: missingReport
        )
        XCTAssertTrue(missingValue.contains("Gemma 1.5B Local"))
        XCTAssertTrue(missingValue.contains(model.family))
        XCTAssertTrue(missingValue.contains(model.parameterCount))
        XCTAssertTrue(missingValue.contains(model.quantization))
        XCTAssertTrue(missingValue.contains("\(model.contextLength) tokens"))
        XCTAssertTrue(missingValue.contains(model.artifactManifest.fileFormat))
        XCTAssertTrue(missingValue.contains(model.sizeOnDisk))
        XCTAssertTrue(missingValue.contains("artifact missing"))
        XCTAssertTrue(missingValue.contains("缺少"))
        XCTAssertTrue(missingValue.contains("预计速度 36.0 tok/s"))
        XCTAssertTrue(missingValue.contains(model.memoryFootprint))
        XCTAssertTrue(missingValue.contains("主后端 Core ML + ANE"))
        XCTAssertTrue(missingValue.contains("回退后端 Metal fallback"))
        XCTAssertTrue(missingValue.contains("KV cache \(model.deploymentProfile.kvCachePolicy)"))
        XCTAssertTrue(missingValue.contains("真实 runtime 计划不可用"))
        XCTAssertTrue(missingValue.contains("verified 门禁"))
        XCTAssertTrue(missingValue.contains("阻塞项 缺少本地 artifact"))
        XCTAssertTrue(missingValue.contains("下一步"))
        XCTAssertTrue(missingValue.contains(model.artifactManifest.storageDirectory))

        let stagedValidation = LocalArtifactValidator.validate(
            manifest: model.artifactManifest,
            presentFiles: Set(model.artifactManifest.requiredFiles)
        )
        let stagedReport = LocalRuntimePlanner.preparationReport(
            for: model,
            validation: stagedValidation
        )
        let stagedValue = ModelDetailAccessibilityMetadata.value(
            model: model,
            validation: stagedValidation,
            report: stagedReport
        )
        XCTAssertTrue(stagedValue.contains("artifact staged"))
        XCTAssertTrue(stagedValue.contains("等待登记官方 SHA-256"))
        XCTAssertTrue(stagedValue.contains("manifest 还没有登记"))
        XCTAssertTrue(stagedValue.contains("真实 runtime 计划不可用"))

        let verifiedManifest = ModelArtifactManifest(
            modelFileName: "verified-gemma.mlmodelc",
            tokenizerFileName: "verified-tokenizer.model",
            fileFormat: "Core ML compiled package",
            storageDirectory: "Application Support/LocalModels",
            expectedSHA256: String(repeating: "c", count: 64),
            allowsNetworkDownload: false,
            importInstruction: "手动导入测试模型。"
        )
        var verifiedModel = model
        verifiedModel.artifactManifest = verifiedManifest
        let verifiedValidation = LocalArtifactValidator.validate(
            manifest: verifiedManifest,
            presentFiles: Set(verifiedManifest.requiredFiles),
            observedSHA256: verifiedManifest.expectedSHA256
        )
        let verifiedReport = LocalRuntimePlanner.preparationReport(
            for: verifiedModel,
            validation: verifiedValidation
        )
        let verifiedValue = ModelDetailAccessibilityMetadata.value(
            model: verifiedModel,
            validation: verifiedValidation,
            report: verifiedReport
        )
        XCTAssertTrue(verifiedValue.contains("artifact verified"))
        XCTAssertTrue(verifiedValue.contains("本地 artifact 已通过校验"))
        XCTAssertTrue(verifiedValue.contains("真实 runtime 计划可用"))
        XCTAssertTrue(verifiedValue.contains("阻塞项 无"))
        XCTAssertTrue(verifiedValue.contains("预热 Core ML + ANE"))
        XCTAssertTrue(verifiedValue.contains("启用 \(verifiedModel.deploymentProfile.kvCachePolicy)"))
    }

    func testModelSelectorExposesAccessibilityMetadata() {
        let model = ModelCatalog.defaultModels[0]
        let modelCount = ModelCatalog.defaultModels.count
        let missingValidation = LocalArtifactValidator.validate(
            manifest: model.artifactManifest,
            presentFiles: []
        )
        let verifiedManifest = ModelArtifactManifest(
            modelFileName: "verified-gemma.mlmodelc",
            tokenizerFileName: "verified-tokenizer.model",
            fileFormat: "Core ML compiled package",
            storageDirectory: "Application Support/LocalModels",
            expectedSHA256: String(repeating: "b", count: 64),
            allowsNetworkDownload: false,
            importInstruction: "手动导入测试模型。"
        )
        let verifiedValidation = LocalArtifactValidator.validate(
            manifest: verifiedManifest,
            presentFiles: Set(verifiedManifest.requiredFiles),
            observedSHA256: verifiedManifest.expectedSHA256
        )

        XCTAssertEqual(
            ModelDeploymentControlAccessibilityMetadata.modelSelectorLabel,
            "选择当前模型"
        )
        XCTAssertEqual(
            ModelDeploymentControlAccessibilityMetadata.modelSelectorIdentifier,
            "model-selector-picker"
        )

        let missingValue = ModelDeploymentControlAccessibilityMetadata.modelSelectorValue(
            selectedModel: model,
            validation: missingValidation,
            deploymentState: .stopped,
            modelCount: modelCount
        )
        XCTAssertTrue(missingValue.contains("Gemma 1.5B Local"))
        XCTAssertTrue(missingValue.contains("1.5B"))
        XCTAssertTrue(missingValue.contains("4-bit"))
        XCTAssertTrue(missingValue.contains("Simulation"))
        XCTAssertTrue(missingValue.contains("\(modelCount) 个候选"))
        XCTAssertTrue(missingValue.contains("缺少本地 artifact"))
        XCTAssertTrue(missingValue.contains("未启动"))

        let verifiedValue = ModelDeploymentControlAccessibilityMetadata.modelSelectorValue(
            selectedModel: model,
            validation: verifiedValidation,
            deploymentState: .running,
            modelCount: modelCount
        )
        XCTAssertTrue(verifiedValue.contains("artifact 已 verified"))
        XCTAssertTrue(verifiedValue.contains("运行中"))

        let hint = ModelDeploymentControlAccessibilityMetadata.modelSelectorHint(modelCount: modelCount)
        XCTAssertTrue(hint.contains("切换当前模型"))
        XCTAssertTrue(hint.contains("不下载模型权重"))
        XCTAssertTrue(hint.contains("不启动真实 runtime"))
        XCTAssertTrue(hint.contains("verified 门禁"))

        let singleCandidateHint = ModelDeploymentControlAccessibilityMetadata.modelSelectorHint(modelCount: 1)
        XCTAssertTrue(singleCandidateHint.contains("当前只有 1 个候选"))
        XCTAssertTrue(singleCandidateHint.contains("不会下载模型权重"))

        XCTAssertEqual(
            ModelDeploymentControlAccessibilityMetadata.modelSelectorInputLabels(selectedModel: model),
            ["选择模型", "切换模型", "选择Gemma 1.5B Local"]
        )
    }

    func testModelDeploymentControlsExposeAccessibilityMetadata() {
        let model = ModelCatalog.defaultModels[0]
        let missingValidation = LocalArtifactValidator.validate(
            manifest: model.artifactManifest,
            presentFiles: []
        )
        let verifiedManifest = ModelArtifactManifest(
            modelFileName: "verified-gemma.mlmodelc",
            tokenizerFileName: "verified-tokenizer.model",
            fileFormat: "Core ML compiled package",
            storageDirectory: "Application Support/LocalModels",
            expectedSHA256: String(repeating: "a", count: 64),
            allowsNetworkDownload: false,
            importInstruction: "手动导入测试模型。"
        )
        let verifiedValidation = LocalArtifactValidator.validate(
            manifest: verifiedManifest,
            presentFiles: Set(verifiedManifest.requiredFiles),
            observedSHA256: verifiedManifest.expectedSHA256
        )

        XCTAssertEqual(
            ModelDeploymentControlAccessibilityMetadata.powerLabel(
                model: model,
                deploymentState: .stopped
            ),
            "启动模型部署 Gemma 1.5B Local"
        )
        XCTAssertEqual(
            ModelDeploymentControlAccessibilityMetadata.powerLabel(
                model: model,
                deploymentState: .running
            ),
            "关闭模型部署 Gemma 1.5B Local"
        )

        let missingValue = ModelDeploymentControlAccessibilityMetadata.powerValue(
            model: model,
            validation: missingValidation,
            deploymentState: .stopped
        )
        XCTAssertTrue(missingValue.contains("未启动"))
        XCTAssertTrue(missingValue.contains("缺少本地 artifact"))
        XCTAssertTrue(missingValue.contains("本地模拟部署"))
        XCTAssertFalse(missingValue.contains("真实 runtime 计划可用"))

        let missingHint = ModelDeploymentControlAccessibilityMetadata.powerHint(
            validation: missingValidation,
            deploymentState: .stopped
        )
        XCTAssertTrue(missingHint.contains("本地模拟部署"))
        XCTAssertTrue(missingHint.contains("不会运行真实权重"))

        let verifiedValue = ModelDeploymentControlAccessibilityMetadata.powerValue(
            model: model,
            validation: verifiedValidation,
            deploymentState: .running
        )
        XCTAssertTrue(verifiedValue.contains("运行中"))
        XCTAssertTrue(verifiedValue.contains("artifact 已 verified"))
        XCTAssertTrue(verifiedValue.contains("真实 runtime 计划可用"))
        XCTAssertFalse(verifiedValue.contains("联网下载"))

        let verifiedHint = ModelDeploymentControlAccessibilityMetadata.powerHint(
            validation: verifiedValidation,
            deploymentState: .running
        )
        XCTAssertTrue(verifiedHint.contains("verified artifact 门禁"))

        XCTAssertEqual(
            ModelDeploymentControlAccessibilityMetadata.powerInputLabels(
                model: model,
                deploymentState: .stopped
            ),
            ["启动模型部署", "运行模型部署", "启动Gemma 1.5B Local"]
        )
        XCTAssertEqual(
            ModelDeploymentControlAccessibilityMetadata.ArtifactAction.allCases,
            [.download, .uninstall, .scan, .importFiles]
        )

        XCTAssertEqual(
            ModelDeploymentControlAccessibilityMetadata.artifactActionLabel(.download),
            "模拟暂存模型文件"
        )
        XCTAssertEqual(
            ModelDeploymentControlAccessibilityMetadata.artifactActionIdentifier(.download),
            "model-artifact-action-download"
        )
        XCTAssertTrue(
            ModelDeploymentControlAccessibilityMetadata.artifactActionValue(
                .download,
                availability: .missing
            ).contains("不联网下载")
        )
        XCTAssertTrue(
            ModelDeploymentControlAccessibilityMetadata.artifactActionHint(
                .download,
                availability: .missing
            ).contains("不会联网下载真实权重")
        )
        XCTAssertTrue(
            ModelDeploymentControlAccessibilityMetadata.artifactActionInputLabels(.download)
                .contains("模拟暂存模型")
        )
        XCTAssertEqual(
            ModelDeploymentControlAccessibilityMetadata.artifactActionIdentifier(.uninstall),
            "model-artifact-action-uninstall"
        )
        XCTAssertTrue(
            ModelDeploymentControlAccessibilityMetadata.artifactActionValue(
                .uninstall,
                availability: .verified
            ).contains("artifact 已 verified")
        )
        XCTAssertTrue(
            ModelDeploymentControlAccessibilityMetadata.artifactActionHint(
                .uninstall,
                availability: .verified
            ).contains("停止当前模型部署")
        )
        XCTAssertEqual(
            ModelDeploymentControlAccessibilityMetadata.artifactActionIdentifier(.scan),
            "model-artifact-action-scan"
        )
        XCTAssertTrue(
            ModelDeploymentControlAccessibilityMetadata.artifactActionValue(
                .scan,
                availability: .staged
            ).contains("artifact 已暂存但未校验")
        )
        XCTAssertTrue(
            ModelDeploymentControlAccessibilityMetadata.artifactActionHint(
                .scan,
                availability: .staged
            ).contains("SHA-256")
        )
        XCTAssertEqual(
            ModelDeploymentControlAccessibilityMetadata.artifactActionIdentifier(.importFiles),
            "model-artifact-action-import"
        )
        XCTAssertTrue(
            ModelDeploymentControlAccessibilityMetadata.artifactActionValue(
                .importFiles,
                availability: .missing
            ).contains("手动选择本地文件")
        )
        XCTAssertTrue(
            ModelDeploymentControlAccessibilityMetadata.artifactActionHint(
                .importFiles,
                availability: .missing
            ).contains("不会从网络下载模型")
        )
        XCTAssertTrue(
            ModelDeploymentControlAccessibilityMetadata.ArtifactAction.allCases.allSatisfy {
                !ModelDeploymentControlAccessibilityMetadata.artifactActionLabel($0).isEmpty
                    && !ModelDeploymentControlAccessibilityMetadata.artifactActionValue(
                        $0,
                        availability: .missing
                    ).isEmpty
                    && !ModelDeploymentControlAccessibilityMetadata.artifactActionHint(
                        $0,
                        availability: .missing
                    ).isEmpty
                    && !ModelDeploymentControlAccessibilityMetadata.artifactActionInputLabels($0).isEmpty
                    && !ModelDeploymentControlAccessibilityMetadata.artifactActionIdentifier($0).isEmpty
            }
        )
    }

    func testWorkspaceLayoutModeConstrainsSidebarWidth() {
        let compactWidth = WorkspaceLayoutMode.landscapeCompact.sidebarWidth(
            for: CGSize(width: 844, height: 390)
        )
        let regularWidth = WorkspaceLayoutMode.landscapeRegular.sidebarWidth(
            for: CGSize(width: 1366, height: 1024)
        )
        let iPadPortraitWidth = WorkspaceLayoutMode.landscapeRegular.sidebarWidth(
            for: CGSize(width: 1024, height: 1366)
        )

        XCTAssertGreaterThanOrEqual(compactWidth, 250)
        XCTAssertLessThanOrEqual(compactWidth, 310)
        XCTAssertGreaterThanOrEqual(regularWidth, 320)
        XCTAssertLessThanOrEqual(regularWidth, 390)
        XCTAssertGreaterThanOrEqual(iPadPortraitWidth, 320)
        XCTAssertLessThanOrEqual(iPadPortraitWidth, 390)
        XCTAssertEqual(
            WorkspaceLayoutMode.portrait.sidebarWidth(for: CGSize(width: 390, height: 844)),
            0
        )
    }

    func testWallpaperProcessorScalesImagesWithoutUpscaling() {
        let large = WallpaperImageProcessor.scaledPixelSize(
            width: 4000,
            height: 2000,
            maxPixel: 1800
        )
        let small = WallpaperImageProcessor.scaledPixelSize(
            width: 900,
            height: 600,
            maxPixel: 1800
        )

        XCTAssertEqual(large.width, 1800)
        XCTAssertEqual(large.height, 900)
        XCTAssertEqual(small.width, 900)
        XCTAssertEqual(small.height, 600)
    }

    func testWallpaperPreferenceControlsExposeAccessibilityMetadata() {
        XCTAssertEqual(
            WallpaperPreferenceAccessibilityMetadata.identifier(for: .choosePhoto),
            "wallpaper-action-choose-photo"
        )
        XCTAssertEqual(
            WallpaperPreferenceAccessibilityMetadata.identifier(for: .clearCustomWallpaper),
            "wallpaper-action-clear-custom"
        )
        XCTAssertEqual(
            WallpaperPreferenceAccessibilityMetadata.label(for: .choosePhoto),
            "选择相册壁纸"
        )
        XCTAssertEqual(
            WallpaperPreferenceAccessibilityMetadata.label(for: .clearCustomWallpaper),
            "恢复系统背景"
        )

        let chooseSystemValue = WallpaperPreferenceAccessibilityMetadata.value(
            for: .choosePhoto,
            hasCustomWallpaper: false,
            isImporting: false
        )
        let chooseCustomValue = WallpaperPreferenceAccessibilityMetadata.value(
            for: .choosePhoto,
            hasCustomWallpaper: true,
            isImporting: false
        )
        let chooseImportingValue = WallpaperPreferenceAccessibilityMetadata.value(
            for: .choosePhoto,
            hasCustomWallpaper: true,
            isImporting: true
        )
        let chooseHint = WallpaperPreferenceAccessibilityMetadata.hint(
            for: .choosePhoto,
            hasCustomWallpaper: false,
            isImporting: false
        )
        XCTAssertTrue(chooseSystemValue.contains("系统背景"))
        XCTAssertTrue(chooseSystemValue.contains("系统相册"))
        XCTAssertTrue(chooseCustomValue.contains("相册图片已启用"))
        XCTAssertTrue(chooseImportingValue.contains("正在处理相册图片"))
        XCTAssertTrue(chooseHint.contains("系统相册"))
        XCTAssertTrue(chooseHint.contains("本地压缩"))
        XCTAssertTrue(chooseHint.contains("不会下载模型权重"))
        XCTAssertTrue(chooseHint.contains("真实 runtime"))
        XCTAssertTrue(chooseHint.contains("不会发送到云端服务"))
        XCTAssertTrue(
            WallpaperPreferenceAccessibilityMetadata.inputLabels(for: .choosePhoto)
                .contains("打开相册")
        )

        let clearSystemValue = WallpaperPreferenceAccessibilityMetadata.value(
            for: .clearCustomWallpaper,
            hasCustomWallpaper: false,
            isImporting: false
        )
        let clearCustomValue = WallpaperPreferenceAccessibilityMetadata.value(
            for: .clearCustomWallpaper,
            hasCustomWallpaper: true,
            isImporting: false
        )
        let clearImportingHint = WallpaperPreferenceAccessibilityMetadata.hint(
            for: .clearCustomWallpaper,
            hasCustomWallpaper: true,
            isImporting: true
        )
        let clearEnabledHint = WallpaperPreferenceAccessibilityMetadata.hint(
            for: .clearCustomWallpaper,
            hasCustomWallpaper: true,
            isImporting: false
        )
        XCTAssertTrue(clearSystemValue.contains("系统背景"))
        XCTAssertTrue(clearSystemValue.contains("没有自定义壁纸"))
        XCTAssertTrue(clearCustomValue.contains("相册图片已启用"))
        XCTAssertTrue(clearCustomValue.contains("恢复系统背景"))
        XCTAssertTrue(clearEnabledHint.contains("不会删除相册原图"))
        XCTAssertTrue(clearEnabledHint.contains("不会下载模型权重"))
        XCTAssertTrue(clearEnabledHint.contains("真实 runtime"))
        XCTAssertTrue(clearEnabledHint.contains("不会发送到云端服务"))
        XCTAssertTrue(clearImportingHint.contains("等待本地压缩完成"))
        XCTAssertTrue(
            WallpaperPreferenceAccessibilityMetadata.inputLabels(for: .clearCustomWallpaper)
                .contains("清空壁纸")
        )

        XCTAssertTrue(
            WallpaperPreferenceAccessibilityMetadata.Action.allCases.allSatisfy {
                !WallpaperPreferenceAccessibilityMetadata.label(for: $0).isEmpty
                    && !WallpaperPreferenceAccessibilityMetadata.value(
                        for: $0,
                        hasCustomWallpaper: false,
                        isImporting: false
                    ).isEmpty
                    && !WallpaperPreferenceAccessibilityMetadata.hint(
                        for: $0,
                        hasCustomWallpaper: true,
                        isImporting: true
                    ).isEmpty
                    && !WallpaperPreferenceAccessibilityMetadata.inputLabels(for: $0).isEmpty
                    && !WallpaperPreferenceAccessibilityMetadata.identifier(for: $0).isEmpty
            }
        )
    }

    func testHeaderAndThemePreferenceActionsExposeAccessibilityMetadata() {
        XCTAssertEqual(
            HeaderActionAccessibilityMetadata.headerThemeToggleIdentifier,
            "header-action-toggle-theme"
        )
        XCTAssertEqual(
            HeaderActionAccessibilityMetadata.settingsThemeToggleIdentifier,
            "settings-action-toggle-theme"
        )
        XCTAssertEqual(
            HeaderActionAccessibilityMetadata.modelLibraryIdentifier,
            "header-action-open-model-library"
        )

        let darkThemeValue = HeaderActionAccessibilityMetadata.themeToggleValue(themeMode: .dark)
        let darkThemeHint = HeaderActionAccessibilityMetadata.themeToggleHint(themeMode: .dark)
        XCTAssertEqual(
            HeaderActionAccessibilityMetadata.themeToggleLabel(themeMode: .dark),
            "切换外观主题"
        )
        XCTAssertTrue(darkThemeValue.contains("当前暗色主题"))
        XCTAssertTrue(darkThemeValue.contains("切换到亮色主题"))
        XCTAssertTrue(darkThemeHint.contains("本地 UI 外观"))
        XCTAssertTrue(darkThemeHint.contains("亮色主题"))
        XCTAssertTrue(darkThemeHint.contains("不会下载模型权重"))
        XCTAssertTrue(darkThemeHint.contains("真实 runtime"))
        XCTAssertTrue(darkThemeHint.contains("不会发送到云端服务"))
        XCTAssertTrue(
            HeaderActionAccessibilityMetadata.themeToggleInputLabels(themeMode: .dark)
                .contains("切换主题")
        )

        let lightThemeValue = HeaderActionAccessibilityMetadata.themeToggleValue(themeMode: .light)
        let lightThemeHint = HeaderActionAccessibilityMetadata.themeToggleHint(themeMode: .light)
        XCTAssertTrue(lightThemeValue.contains("当前亮色主题"))
        XCTAssertTrue(lightThemeValue.contains("切换到暗色主题"))
        XCTAssertTrue(lightThemeHint.contains("暗色主题"))
        XCTAssertTrue(
            HeaderActionAccessibilityMetadata.themeToggleInputLabels(themeMode: .light)
                .contains("切换到暗色主题")
        )

        XCTAssertEqual(
            HeaderActionAccessibilityMetadata.modelLibraryLabel,
            "打开模型工作区"
        )
        XCTAssertTrue(HeaderActionAccessibilityMetadata.modelLibraryValue.contains("模型工作区"))
        XCTAssertTrue(HeaderActionAccessibilityMetadata.modelLibraryValue.contains("artifact"))
        XCTAssertTrue(HeaderActionAccessibilityMetadata.modelLibraryHint.contains("本地工作区"))
        XCTAssertTrue(HeaderActionAccessibilityMetadata.modelLibraryHint.contains("不会下载模型权重"))
        XCTAssertTrue(HeaderActionAccessibilityMetadata.modelLibraryHint.contains("真实 runtime"))
        XCTAssertTrue(HeaderActionAccessibilityMetadata.modelLibraryHint.contains("verified 门禁"))
        XCTAssertTrue(
            HeaderActionAccessibilityMetadata.modelLibraryInputLabels.contains("打开模型库")
        )
    }

    func testExportPayloadOnlySharesExistingFileURL() throws {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("LocalGemmaPayload-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: directoryURL)
        }

        let fileURL = directoryURL.appendingPathComponent("conversation.md")
        let missingURL = directoryURL.appendingPathComponent("missing.md")
        try Data("hello".utf8).write(to: fileURL)

        XCTAssertEqual(
            ExportPayload(title: "A", messageCount: 1, text: "hello", fileURL: fileURL).existingFileURL,
            fileURL
        )
        XCTAssertNil(
            ExportPayload(title: "B", messageCount: 1, text: "hello", fileURL: missingURL).existingFileURL
        )
        XCTAssertNil(
            ExportPayload(title: "C", messageCount: 1, text: "hello", fileURL: nil).existingFileURL
        )
    }

    func testExportSessionActionsExposeAccessibilityMetadata() {
        XCTAssertEqual(
            ExportSessionActionAccessibilityMetadata.identifier(for: .shareMarkdownFile),
            "export-session-action-share-markdown-file"
        )
        XCTAssertEqual(
            ExportSessionActionAccessibilityMetadata.identifier(for: .shareTextFallback),
            "export-session-action-share-text-fallback"
        )
        XCTAssertEqual(
            ExportSessionActionAccessibilityMetadata.identifier(for: .copyFullText),
            "export-session-action-copy-full-text"
        )

        let markdownValue = ExportSessionActionAccessibilityMetadata.value(
            for: .shareMarkdownFile,
            messageCount: 3
        )
        let markdownHint = ExportSessionActionAccessibilityMetadata.hint(for: .shareMarkdownFile)
        XCTAssertEqual(
            ExportSessionActionAccessibilityMetadata.label(for: .shareMarkdownFile),
            "分享 Markdown 文件"
        )
        XCTAssertTrue(markdownValue.contains("本地 Markdown"))
        XCTAssertTrue(markdownValue.contains("3 条消息"))
        XCTAssertTrue(markdownHint.contains("本地生成"))
        XCTAssertTrue(markdownHint.contains("不会发送到云端服务"))
        XCTAssertTrue(
            ExportSessionActionAccessibilityMetadata.inputLabels(for: .shareMarkdownFile)
                .contains("分享 Markdown 文件")
        )

        let textValue = ExportSessionActionAccessibilityMetadata.value(
            for: .shareTextFallback,
            messageCount: 3
        )
        let textHint = ExportSessionActionAccessibilityMetadata.hint(for: .shareTextFallback)
        XCTAssertEqual(
            ExportSessionActionAccessibilityMetadata.label(for: .shareTextFallback),
            "分享文本内容"
        )
        XCTAssertTrue(textValue.contains("文本分享兜底"))
        XCTAssertTrue(textValue.contains("3 条消息"))
        XCTAssertTrue(textHint.contains("Markdown 文件不存在"))
        XCTAssertTrue(textHint.contains("不会发送到云端服务"))
        XCTAssertTrue(
            ExportSessionActionAccessibilityMetadata.inputLabels(for: .shareTextFallback)
                .contains("文本分享兜底")
        )

        let copyValue = ExportSessionActionAccessibilityMetadata.value(
            for: .copyFullText,
            messageCount: 3
        )
        let copyHint = ExportSessionActionAccessibilityMetadata.hint(for: .copyFullText)
        XCTAssertEqual(
            ExportSessionActionAccessibilityMetadata.label(for: .copyFullText),
            "复制全文"
        )
        XCTAssertTrue(copyValue.contains("3 条消息"))
        XCTAssertTrue(copyHint.contains("剪贴板"))
        XCTAssertTrue(copyHint.contains("不会发送到云端服务"))
        XCTAssertTrue(
            ExportSessionActionAccessibilityMetadata.inputLabels(for: .copyFullText)
                .contains("复制全文")
        )

        XCTAssertTrue(
            ExportSessionActionAccessibilityMetadata.Action.allCases.allSatisfy {
                !ExportSessionActionAccessibilityMetadata.label(for: $0).isEmpty
                    && !ExportSessionActionAccessibilityMetadata.value(
                        for: $0,
                        messageCount: 1
                    ).isEmpty
                    && !ExportSessionActionAccessibilityMetadata.hint(for: $0).isEmpty
                    && !ExportSessionActionAccessibilityMetadata.inputLabels(for: $0).isEmpty
                    && !ExportSessionActionAccessibilityMetadata.identifier(for: $0).isEmpty
            }
        )
    }
}
