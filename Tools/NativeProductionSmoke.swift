import Foundation

private struct NativeProductionFailure: Error, CustomStringConvertible {
    let description: String
}

@MainActor
enum NativeProductionSmoke {
    private static func require(_ condition: Bool, _ message: String) throws {
        if !condition { throw NativeProductionFailure(description: message) }
    }

    // A headless test of the same state objects used by the App. UI permission
    // and Files presentation remain covered separately; no UI state is injected.
    static func run(modelURL: URL, directory: URL) async throws -> [String: Any] {
        let model = PinnedTextModel.model
        try require(modelURL.lastPathComponent == PinnedTextModel.fileName,
                    "The production import must use the actual registered filename")
        let catalog = ModelCatalog(models: [model], artifactDirectoryURL: directory)
        let engine = InferenceEngine(streamingRuntime: VerifiedLlamaRuntime())
        try require(catalog.validation(for: model).availability == .missing,
                    "A fresh catalogue must not inherit verified fixture state")
        let preservedDraft = "  Keep this unverified draft\n"
        engine.inputText = preservedDraft
        engine.send(using: model, availability: catalog.validation(for: model).availability,
                    artifactDirectoryURL: directory)
        try require(engine.inputText == preservedDraft && engine.messages.isEmpty
                    && !engine.isGenerating && engine.generationError != nil,
                    "The production missing-artifact gate consumed a draft or started work")

        try await catalog.importArtifacts(for: model, sourceURLs: [modelURL])
        try require(catalog.validation(for: model).availability == .verified
                    && !catalog.isArtifactOperationInProgress,
                    "The real production importer did not verify the registered file")
        let managedFile = directory.appendingPathComponent(PinnedTextModel.fileName)
        try require(managedFile != modelURL && ModelArtifactHasher.sha256Hex(for: managedFile) == PinnedTextModel.sha256,
                    "Managed model bytes differ from the trusted source")
        let excluded = try directory.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup
        try require(excluded == true, "The production model directory must exclude system backup")

        let question = "The secret word is ORCHID. Reply with that word only."
        let first = try await answer(question, engine: engine, catalog: catalog, model: model)
        try require(engine.messages.map(\.role) == [.user, .assistant],
                    "The first production turn must contain only the actual question and answer")
        let firstSession = engine.activeSessionID
        let secondQuestion = "What is the secret word? Reply with the word only."
        let second = try await answer(secondQuestion, engine: engine, catalog: catalog, model: model)
        try require(engine.messages.map(\.role) == [.user, .assistant, .user, .assistant]
                    && engine.messages[0].text == question && engine.messages[2].text == secondQuestion,
                    "The production state flow did not preserve ordered complete history")
        let exported = engine.exportActiveSessionText(modelName: model.name)
        try require(exported.contains(question) && exported.contains(secondQuestion)
                    && exported.contains(first["text"] as! String) && exported.contains(second["text"] as! String),
                    "Production export dropped the original multi-turn text")

        let stoppedSession = engine.createSession()
        engine.inputText = "Write a long story about a quiet garden."
        engine.send(using: model, availability: catalog.validation(for: model).availability,
                    artifactDirectoryURL: directory)
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: .seconds(20))
        while engine.isGenerating && !hasNativeText(engine) && clock.now < deadline {
            try await Task.sleep(for: .milliseconds(10))
        }
        try require(engine.isGenerating && hasNativeText(engine) && !engine.lastResultWasSimulated,
                    "Stop must interrupt actual ongoing native text, not an empty placeholder")
        engine.stop()
        let stoppedText = engine.messages.last(where: { $0.role == .assistant })?.text
        let reloadedSession = engine.createSession()
        engine.inputText = "Keep the new session draft"
        await engine.waitForCurrentGeneration()
        try require(engine.activeSessionID == reloadedSession && engine.messages.isEmpty
                    && engine.inputText == "Keep the new session draft"
                    && engine.sessions.first(where: { $0.id == stoppedSession })?.messages.last(where: { $0.role == .assistant })?.text == stoppedText,
                    "Cancelled native events changed a different production session or its draft")
        let reloaded = try await answer(question, engine: engine, catalog: catalog, model: model)
        try require(engine.sessions.first(where: { $0.id == firstSession })?.messages.count == 4,
                    "Reloading must preserve the earlier multi-turn session")

        // Change only the managed test copy after its verified snapshot, then
        // exercise the real runtime's independent hash gate through InferenceEngine.
        try Data("GGUF changed after validation".utf8).write(to: managedFile, options: .atomic)
        engine.createSession()
        engine.inputText = "Preserve the question when verified bytes change"
        engine.send(using: model, availability: catalog.validation(for: model).availability,
                    artifactDirectoryURL: directory)
        await engine.waitForCurrentGeneration()
        try require(!engine.isGenerating && engine.lastResultWasSimulated
                    && engine.generationError == LlamaTextRuntimeError.hashMismatch.localizedDescription
                    && engine.messages.first?.text == "Preserve the question when verified bytes change"
                    && !engine.messages.contains(where: { $0.role == .assistant }),
                    "Stale verified UI state bypassed the actual file hash or lost the question")
        await catalog.refreshArtifactStatus(for: model)
        try require(catalog.validation(for: model).availability != .verified,
                    "A scan must withdraw verified after a managed file changes")
        try require(ModelArtifactHasher.sha256Hex(for: modelURL) == PinnedTextModel.sha256,
                    "The importer or failure test modified the supplied source file")
        try await catalog.importArtifacts(for: model, sourceURLs: [modelURL])
        engine.createSession()
        let recovered = try await answer(question, engine: engine, catalog: catalog, model: model)

        engine.createSession()
        let longQuestion = String(repeating: "context word ", count: 3_000)
        engine.inputText = longQuestion
        engine.send(using: model, availability: catalog.validation(for: model).availability,
                    artifactDirectoryURL: directory)
        await engine.waitForCurrentGeneration()
        try require(!engine.isGenerating && engine.lastResultWasSimulated
                    && engine.generationError?.contains("Nothing was truncated") == true
                    && engine.messages.first?.text == longQuestion.trimmingCharacters(in: .whitespacesAndNewlines)
                    && !engine.messages.contains(where: { $0.role == .assistant }),
                    "Production context rejection must retain the complete question without a fake answer")
        return [
            "source": "headless-production-ModelCatalog-VerifiedLlamaRuntime-InferenceEngine",
            "modelID": model.id.uuidString, "modelName": model.name,
            "fileName": PinnedTextModel.fileName, "sha256": PinnedTextModel.sha256,
            "importedAndVerified": true, "backupExcluded": true, "unverifiedDraftPreserved": true,
            "turns": [first, second], "exportPreservesFullHistory": true,
            "stoppedAfterActualText": true, "lateEventsIsolated": true, "reloadAfterStop": reloaded,
            "changedManagedFileRejected": true, "sourceUnmodified": true, "reimportRecovery": recovered,
            "fullContextRejectedWithoutTruncation": true,
            "UIFilePickerExercised": false, "deviceMemoryOrMetalVerified": false
        ]
    }

    private static func hasNativeText(_ engine: InferenceEngine) -> Bool {
        engine.messages.contains { $0.role == .assistant && !$0.text.isEmpty }
    }

    private static func answer(
        _ question: String, engine: InferenceEngine, catalog: ModelCatalog, model: LocalModel
    ) async throws -> [String: Any] {
        engine.inputText = question
        engine.send(using: model, availability: catalog.validation(for: model).availability,
                    artifactDirectoryURL: catalog.artifactDirectoryURL)
        await engine.waitForCurrentGeneration()
        guard let message = engine.messages.last, message.role == .assistant else {
            throw NativeProductionFailure(description: "No actual assistant answer: \(engine.generationError ?? "missing")")
        }
        try require(!engine.isGenerating && engine.generationError == nil && !engine.lastResultWasSimulated
                    && engine.currentBackend == .llamaCpp && message.text.uppercased().contains("ORCHID")
                    && message.tokens > 0 && engine.currentTokensPerSecond.isFinite && engine.currentTokensPerSecond > 0
                    && engine.memoryUsageMB == 0 && engine.cpuLoad == 0,
                    "Production native answer, actual metrics or unknown-resource semantics failed")
        return ["text": message.text, "outputTokens": message.tokens,
                "tokensPerSecond": engine.currentTokensPerSecond, "simulated": engine.lastResultWasSimulated,
                "backend": engine.currentBackend.rawValue]
    }
}
