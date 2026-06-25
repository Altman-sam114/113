import Foundation

@main
enum LogicSmoke {
    @MainActor
    static func main() {
        var failures: [String] = []

        func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
            if condition() == false {
                failures.append(message)
            }
        }

        let catalog = ModelCatalog()
        expect(catalog.selectedModel.name == "Gemma 1.5B Local", "default model should be Gemma 1.5B Local")
        expect(catalog.selectedModel.parameterCount == "1.5B", "default Gemma parameter count should be 1.5B")
        expect(catalog.selectedModel.installState == .simulated, "default Gemma model should use simulation state")
        expect(catalog.selectedModel.summary.contains("不下载") || catalog.selectedModel.summary.contains("暂未下载"), "default summary should say real weights are not downloaded")
        expect(catalog.selectedModel.artifactManifest.allowsNetworkDownload == false, "default Gemma model should not auto-download weights")
        expect(catalog.selectedModel.artifactManifest.requiredFiles.contains("gemma-1.5b-it-q4.mlmodelc"), "Gemma manifest should name the compiled model package")
        expect(catalog.validation(for: catalog.selectedModel).availability == .missing, "catalog should start with missing local artifacts")

        let missingValidation = LocalArtifactValidator.validate(
            manifest: catalog.selectedModel.artifactManifest,
            presentFiles: []
        )
        expect(missingValidation.availability == .missing, "missing validation should report missing artifacts")
        expect(missingValidation.missingFiles == catalog.selectedModel.artifactManifest.requiredFiles, "missing validation should list required files")
        expect(missingValidation.canPromoteToRealRuntime == false, "missing validation should not promote real runtime")

        let stagedValidation = LocalArtifactValidator.validate(
            manifest: catalog.selectedModel.artifactManifest,
            presentFiles: Set(catalog.selectedModel.artifactManifest.requiredFiles)
        )
        expect(stagedValidation.availability == .staged, "Gemma files without a concrete hash should be staged")
        expect(stagedValidation.hasRequiredFiles == true, "staged validation should have required files")
        expect(stagedValidation.hasConcreteExpectedHash == false, "default Gemma manifest should require manual hash registration")
        expect(stagedValidation.canPromoteToRealRuntime == false, "staged validation should not promote real runtime")

        let concreteHash = String(repeating: "b", count: 64)
        let concreteManifest = ModelArtifactManifest(
            modelFileName: "logic-gemma.mlmodelc",
            tokenizerFileName: "logic-tokenizer.model",
            fileFormat: "Core ML compiled package",
            storageDirectory: "Application Support/LocalModels",
            expectedSHA256: concreteHash,
            allowsNetworkDownload: false,
            importInstruction: "手动导入测试模型。"
        )
        let verifiedValidation = LocalArtifactValidator.validate(
            manifest: concreteManifest,
            presentFiles: Set(concreteManifest.requiredFiles),
            observedSHA256: concreteHash
        )
        expect(verifiedValidation.availability == .verified, "matching concrete hash should verify artifacts")
        expect(verifiedValidation.hasVerifiedHash == true, "verified validation should record hash success")
        expect(verifiedValidation.canPromoteToRealRuntime == true, "verified validation should promote real runtime")

        let diskDirectoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("LocalGemmaSmoke-\(UUID().uuidString)", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: diskDirectoryURL, withIntermediateDirectories: true)
            let modelFileName = "disk-gemma.bin"
            let tokenizerFileName = "disk-tokenizer.model"
            try Data("abc".utf8).write(to: diskDirectoryURL.appendingPathComponent(modelFileName))
            try Data("tokenizer".utf8).write(to: diskDirectoryURL.appendingPathComponent(tokenizerFileName))
            let diskManifest = ModelArtifactManifest(
                modelFileName: modelFileName,
                tokenizerFileName: tokenizerFileName,
                fileFormat: "Core ML compiled package",
                storageDirectory: diskDirectoryURL.path,
                expectedSHA256: "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
                allowsNetworkDownload: false,
                importInstruction: "手动导入测试模型。"
            )
            let diskValidation = ModelArtifactStore.validate(
                manifest: diskManifest,
                directoryURL: diskDirectoryURL
            )
            expect(diskValidation.availability == .verified, "disk scan should verify matching SHA-256")
            expect(diskValidation.observedSHA256 == diskManifest.expectedSHA256, "disk scan should record computed SHA-256")
            expect(Set(diskValidation.presentFiles) == Set(diskManifest.requiredFiles), "disk scan should list present artifact files")
        } catch {
            failures.append("disk artifact smoke setup failed: \(error)")
        }
        try? FileManager.default.removeItem(at: diskDirectoryURL)

        let importSourceURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("LocalGemmaImportSmokeSource-\(UUID().uuidString)", isDirectory: true)
        let importDestinationURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("LocalGemmaImportSmokeDestination-\(UUID().uuidString)", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: importSourceURL, withIntermediateDirectories: true)
            let modelFileName = "import-gemma.bin"
            let tokenizerFileName = "import-tokenizer.model"
            let modelURL = importSourceURL.appendingPathComponent(modelFileName)
            let tokenizerURL = importSourceURL.appendingPathComponent(tokenizerFileName)
            try Data("abc".utf8).write(to: modelURL)
            try Data("tokenizer".utf8).write(to: tokenizerURL)
            let importManifest = ModelArtifactManifest(
                modelFileName: modelFileName,
                tokenizerFileName: tokenizerFileName,
                fileFormat: "Core ML compiled package",
                storageDirectory: importDestinationURL.path,
                expectedSHA256: "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
                allowsNetworkDownload: false,
                importInstruction: "手动导入测试模型。"
            )
            let importValidation = try ModelArtifactStore.importArtifacts(
                manifest: importManifest,
                sourceURLs: [modelURL, tokenizerURL],
                destinationDirectoryURL: importDestinationURL
            )
            expect(importValidation.availability == .verified, "manual import should copy and verify matching artifacts")
            expect(FileManager.default.fileExists(atPath: importDestinationURL.appendingPathComponent(modelFileName).path), "manual import should copy model file")
            expect(FileManager.default.fileExists(atPath: importDestinationURL.appendingPathComponent(tokenizerFileName).path), "manual import should copy tokenizer file")

            let removalValidation = try ModelArtifactStore.removeArtifacts(
                manifest: importManifest,
                destinationDirectoryURL: importDestinationURL
            )
            expect(removalValidation.availability == .missing, "artifact removal should return missing validation")
            expect(FileManager.default.fileExists(atPath: importDestinationURL.appendingPathComponent(modelFileName).path) == false, "artifact removal should delete model file")
            expect(FileManager.default.fileExists(atPath: importDestinationURL.appendingPathComponent(tokenizerFileName).path) == false, "artifact removal should delete tokenizer file")
        } catch {
            failures.append("manual import smoke setup failed: \(error)")
        }
        try? FileManager.default.removeItem(at: importSourceURL)
        try? FileManager.default.removeItem(at: importDestinationURL)

        let packageSourceURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("LocalGemmaPackageSmokeSource-\(UUID().uuidString)", isDirectory: true)
        let packageDestinationURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("LocalGemmaPackageSmokeDestination-\(UUID().uuidString)", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: packageSourceURL, withIntermediateDirectories: true)
            let modelFileName = "package-gemma.mlmodelc"
            let tokenizerFileName = "package-tokenizer.model"
            let modelPackageURL = packageSourceURL.appendingPathComponent(modelFileName, isDirectory: true)
            try FileManager.default.createDirectory(at: modelPackageURL, withIntermediateDirectories: true)
            try Data("compiled-coreml".utf8).write(to: modelPackageURL.appendingPathComponent("model.mil"))
            try Data("metadata".utf8).write(to: modelPackageURL.appendingPathComponent("metadata.json"))
            let tokenizerURL = packageSourceURL.appendingPathComponent(tokenizerFileName)
            try Data("tokenizer".utf8).write(to: tokenizerURL)
            if let expectedHash = ModelArtifactHasher.sha256Hex(for: modelPackageURL) {
                let packageManifest = ModelArtifactManifest(
                    modelFileName: modelFileName,
                    tokenizerFileName: tokenizerFileName,
                    fileFormat: "Core ML compiled package",
                    storageDirectory: packageDestinationURL.path,
                    expectedSHA256: expectedHash,
                    allowsNetworkDownload: false,
                    importInstruction: "手动导入测试模型。"
                )
                let packageValidation = try ModelArtifactStore.importArtifacts(
                    manifest: packageManifest,
                    sourceURLs: [modelPackageURL, tokenizerURL],
                    destinationDirectoryURL: packageDestinationURL
                )
                expect(packageValidation.availability == .verified, "package import should verify copied Core ML directory")
                expect(packageValidation.observedSHA256 == expectedHash, "package import should preserve directory hash")
            } else {
                failures.append("package import smoke could not hash source package")
            }
        } catch {
            failures.append("package import smoke setup failed: \(error)")
        }
        try? FileManager.default.removeItem(at: packageSourceURL)
        try? FileManager.default.removeItem(at: packageDestinationURL)

        let missingReport = LocalRuntimePlanner.preparationReport(for: catalog.selectedModel)
        expect(missingReport.canRunRealWeights == false, "missing artifacts should keep real runtime disabled")
        expect(missingReport.activeBackend == .coreMLANE, "Gemma should prefer Core ML + ANE")
        expect(missingReport.fallbackBackend == .metalPerformanceShaders, "Gemma should fall back to Metal")

        let stagedReport = LocalRuntimePlanner.preparationReport(for: catalog.selectedModel, validation: stagedValidation)
        expect(stagedReport.canRunRealWeights == false, "staged artifacts should keep real runtime disabled")
        expect(stagedReport.blockers.joined().contains("SHA-256"), "staged report should require hash verification")

        catalog.stageManualImportPreview(for: catalog.selectedModel)
        expect(catalog.validation(for: catalog.selectedModel).availability == .staged, "manual import preview should stage selected model")
        expect(catalog.selectedModel.installState == .simulated, "staged manual import should keep simulation state")
        expect(catalog.selectedModel.summary.contains("SHA-256"), "staged model summary should mention hash verification")

        let defaultGemma = catalog.selectedModel
        let qwen = catalog.models[1]
        expect(catalog.deploymentState(for: defaultGemma) == .stopped, "catalog deployment should start stopped")
        catalog.startDeployment(for: defaultGemma)
        expect(catalog.isDeploymentRunning(for: defaultGemma), "catalog should start deployment for selected model")
        catalog.startDeployment(for: qwen)
        expect(catalog.isDeploymentRunning(for: defaultGemma) == false, "starting another model should stop previous deployment")
        expect(catalog.isDeploymentRunning(for: qwen), "catalog should run the newly selected deployment")
        catalog.toggleDeployment(for: qwen)
        expect(catalog.deploymentState(for: qwen) == .stopped, "deployment toggle should stop a running model")
        catalog.simulateDownload(for: defaultGemma)
        expect(catalog.validation(for: defaultGemma).availability == .staged, "simulated download should stage model artifacts")
        expect(catalog.models.first(where: { $0.id == defaultGemma.id })?.installState == .simulated, "simulated download should keep simulation install state")
        catalog.select(defaultGemma)

        let autoScanURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("LocalGemmaAutoScanSmoke-\(UUID().uuidString)", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: autoScanURL, withIntermediateDirectories: true)
            for fileName in ModelCatalog.defaultModels[0].artifactManifest.requiredFiles {
                let url = autoScanURL.appendingPathComponent(fileName)
                if fileName.hasSuffix(".mlmodelc") {
                    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
                    try Data("compiled-gemma".utf8).write(to: url.appendingPathComponent("model.mil"))
                } else {
                    try Data("tokenizer".utf8).write(to: url)
                }
            }
            let autoScanCatalog = ModelCatalog(
                models: [ModelCatalog.defaultModels[0]],
                autoScanLocalArtifacts: true,
                artifactDirectoryURL: autoScanURL
            )
            expect(autoScanCatalog.validation(for: autoScanCatalog.selectedModel).availability == .staged, "auto-scan should restore existing local artifacts")
            expect(autoScanCatalog.selectedModel.summary.contains("SHA-256"), "auto-scan should keep staged artifacts behind hash verification")
        } catch {
            failures.append("auto-scan smoke setup failed: \(error)")
        }
        try? FileManager.default.removeItem(at: autoScanURL)

        let verifiedReport = LocalRuntimePlanner.preparationReport(for: catalog.selectedModel, availability: .verified)
        expect(verifiedReport.canRunRealWeights == true, "verified artifacts should enable real runtime plan")
        expect(verifiedReport.networkDownloadAllowed == false, "verified artifacts should still avoid network downloads")

        let simulatedResult = SimulatedGemmaRuntime().generate(
            InferenceRequest(prompt: "说明本地部署", model: catalog.selectedModel)
        )
        expect(simulatedResult.isSimulated == true, "simulated runtime should mark results as simulated")
        expect(simulatedResult.backend == .coreMLANE, "simulated runtime should report the planned primary backend")

        let realMissingResult = RealGemmaRuntimePlaceholder().generate(
            InferenceRequest(prompt: "启动真实模型", model: catalog.selectedModel)
        )
        expect(realMissingResult.isSimulated == true, "real runtime placeholder should stay simulated when artifacts are missing")
        expect(realMissingResult.backend == .metalPerformanceShaders, "missing real runtime should use fallback backend")
        expect(realMissingResult.text.contains("不会下载模型"), "real runtime placeholder should refuse downloads")

        let realVerifiedResult = RealGemmaRuntimePlaceholder().generate(
            InferenceRequest(prompt: "启动真实模型", model: catalog.selectedModel, artifactAvailability: .verified)
        )
        expect(realVerifiedResult.isSimulated == false, "verified real runtime placeholder should expose real runtime readiness")
        expect(realVerifiedResult.backend == .coreMLANE, "verified real runtime should use primary backend")

        let provider = GemmaSimulationProvider()
        let deploymentAnswer = provider.response(for: "说明 iPhone 芯片部署优化和 Metal 路径", model: catalog.selectedModel)
        expect(deploymentAnswer.contains("模拟"), "deployment answer should disclose simulation mode")
        expect(deploymentAnswer.contains("Metal"), "deployment answer should mention Metal")
        expect(deploymentAnswer.contains("Gemma"), "deployment answer should mention Gemma")

        let privacyAnswer = provider.response(for: "说明本地隐私安全模式", model: catalog.selectedModel)
        expect(privacyAnswer.contains("本地") || privacyAnswer.contains("设备"), "privacy answer should emphasize local device execution")

        let optimizer = DeviceOptimizer()
        let initialReadiness = optimizer.deploymentReadiness
        let firstSwitch = optimizer.switches[0]
        optimizer.toggle(firstSwitch)
        expect(optimizer.deploymentReadiness != initialReadiness, "optimizer readiness should change after toggling a strategy")
        expect(optimizer.switches[0].isEnabled == false, "first optimizer switch should toggle off")

        let templates = PromptTemplateLibrary.defaultTemplates
        expect(templates.count >= 6, "prompt template library should provide several templates")
        expect(Set(templates.map(\.category)) == Set(PromptTemplateCategory.allCases), "prompt template library should cover every category")
        expect(PromptTemplateLibrary.templates(in: .privacy).allSatisfy { $0.category == .privacy }, "prompt category filtering should only return matching templates")

        let engine = InferenceEngine()
        let initialMessageCount = engine.messages.count
        engine.inputText = "   "
        engine.send(using: catalog.selectedModel)
        expect(engine.messages.count == initialMessageCount, "empty prompts should not append chat messages")
        expect(engine.isGenerating == false, "empty prompts should not start generation")

        let firstTemplate = templates[0]
        engine.applyTemplate(firstTemplate)
        expect(engine.inputText == firstTemplate.prompt, "applying a template should fill the composer")
        expect(engine.messages.count == initialMessageCount, "applying a template should not send a message")

        let troubleshootingTemplate = templates.first { $0.category == .troubleshooting } ?? firstTemplate
        engine.useTemplate(troubleshootingTemplate, model: catalog.selectedModel, availability: .staged)
        engine.stop()
        expect(engine.inputText.isEmpty, "using a template should clear the composer after sending")
        expect(engine.messages.contains { $0.role == .user && $0.text == troubleshootingTemplate.prompt }, "using a template should append the template prompt as a user message")
        expect(engine.lastPreparationReport?.availability == .staged, "template sends should record selected artifact availability")

        let originalSession = engine.sessions[0]
        let sessionID = engine.createSession(title: "部署讨论")
        expect(engine.sessions.count >= 2, "creating a session should append session state")
        expect(engine.activeSessionID == sessionID, "new session should become active")
        expect(engine.activeSessionTitle == "部署讨论", "new session should keep its assigned name")
        engine.inputText = "请说明本地部署和隐私保护"
        engine.send(using: catalog.selectedModel, availability: .staged)
        engine.stop()
        expect(engine.activeSessionTitle.contains("部署讨论") || engine.activeSessionTitle.contains("请说明本地部署"), "session should have a readable name")
        let exportedSession = engine.exportActiveSessionText(modelName: catalog.selectedModel.name)
        expect(exportedSession.contains("## 用户"), "export should include user messages")
        expect(exportedSession.contains(catalog.selectedModel.name), "export should include model name")
        let exportDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("LocalGemmaSmokeExport-\(UUID().uuidString)", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: exportDirectory, withIntermediateDirectories: true)
            let exportURL = try engine.exportActiveSessionMarkdownFile(
                modelName: catalog.selectedModel.name,
                directoryURL: exportDirectory
            )
            expect(exportURL.pathExtension == "md", "exported conversation file should be Markdown")
            expect(FileManager.default.fileExists(atPath: exportURL.path), "exported conversation file should exist")
        } catch {
            failures.append("conversation export smoke failed: \(error)")
        }
        try? FileManager.default.removeItem(at: exportDirectory)
        engine.selectSession(originalSession)
        expect(engine.activeSessionID == originalSession.id, "selecting a session should restore its id")

        engine.inputText = "启动真实模型"
        engine.send(using: catalog.selectedModel, availability: catalog.validation(for: catalog.selectedModel).availability)
        engine.stop()
        expect(engine.lastPreparationReport?.availability == .staged, "inference should record selected artifact availability")
        expect(engine.lastPreparationReport?.canRunRealWeights == false, "staged inference should keep real weights disabled")
        expect(engine.lastResultWasSimulated == true, "default runtime should mark staged inference as simulated")
        expect(engine.currentBackend == .coreMLANE, "default runtime should report the planned Core ML backend")

        engine.inputText = "说明本地模型"
        engine.send(using: catalog.selectedModel)
        engine.resetConversation()
        expect(engine.messages.count == 2, "reset conversation should restore welcome messages")
        expect(engine.inputText.isEmpty, "reset conversation should clear composer text")
        expect(engine.isGenerating == false, "reset conversation should stop generation")
        expect(engine.lastPreparationReport == nil, "reset conversation should clear preparation report")

        if failures.isEmpty {
            print("Logic smoke passed")
        } else {
            for failure in failures {
                FileHandle.standardError.write(Data("FAIL: \(failure)\n".utf8))
            }
            Foundation.exit(1)
        }
    }
}
