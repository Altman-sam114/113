import Foundation

struct StreamingInferenceRequest: Equatable, Sendable {
    let model: LocalModel
    let availability: ArtifactAvailability
    let modelFileURL: URL
    let messages: [ChatMessage]
    let maximumOutputTokens: Int
}

struct InferenceStreamMetrics: Equatable, Sendable {
    let promptTokens: Int
    let outputTokens: Int
    let tokensPerSecond: Double
    let reachedOutputLimit: Bool
}

enum InferenceStreamEvent: Equatable, Sendable {
    case text(String)
    case completed(InferenceStreamMetrics)
}

protocol LocalStreamingInferenceRuntime: Sendable {
    func supports(_ model: LocalModel) -> Bool
    func stream(_ request: StreamingInferenceRequest) -> AsyncThrowingStream<InferenceStreamEvent, Error>
}

enum StreamingInferenceError: Error, LocalizedError, Sendable {
    case unverifiedArtifact
    case unsupportedModel
    case backendUnavailable
    case incompleteStream
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .unverifiedArtifact:
            return "模型文件尚未通过可信 SHA-256 校验，未启动真实推理。"
        case .unsupportedModel:
            return "当前模型格式尚不支持真实文本推理，请选择已登记的 GGUF 模型。"
        case .backendUnavailable:
            return "此构建未包含本地推理后端，不能把模拟回复当作模型回答。"
        case .incompleteStream:
            return "本地推理未完整结束；已收到的文字仍保留，可重新发送。"
        case .emptyResponse:
            return "本地模型没有返回可显示的文字。问题仍保留，请重试或新建会话。"
        }
    }
}

enum PinnedTextModel {
    // A new model identity prevents the former 1B entry from inheriting trust.
    static let id = UUID(uuidString: "5D5BA6B9-6EBC-43A9-A7B6-21FA9332C270")!
    static let fileName = "gemma-3-270m-it-qat-Q4_0.gguf"
    static let sha256 = "3626e245220ca4a1c5911eb4010b3ecb7bdbf5bc53c79403c21355354d1e2dc6"
    static let byteCount: Int64 = 241_410_624
    static let revision = sha256
    static let sourceName = "用户提供的本地 GGUF"
    // This is model documentation, not a claimed download source for the bytes.
    static let sourceURL = URL(string: "https://ai.google.dev/gemma/docs/core/model_card_3")!
    static let licenseURL = URL(string: "https://ai.google.dev/gemma/terms")!
    static let usePolicyURL = URL(string: "https://ai.google.dev/gemma/prohibited_use_policy")!

    static var model: LocalModel {
        LocalModel(
            id: id,
            name: "Gemma 3 270M",
            family: "Gemma",
            parameterCount: "270M",
            quantization: "QAT Q4_0",
            sizeOnDisk: "241 MB",
            contextLength: 4096,
            tokensPerSecond: 0,
            memoryFootprint: "取决于设备与上下文；尚未实测",
            installState: .notDownloaded,
            summary: "手动导入指定 GGUF 后在本机执行文本推理。模型不随 App 提供，不自动下载；使用前请阅读并同意 Gemma 许可与使用限制。",
            capabilities: ["本地文本对话", "多轮上下文", "可停止生成"],
            artifactManifest: ModelArtifactManifest(
                modelFileName: fileName,
                tokenizerFileName: "",
                fileFormat: "GGUF",
                storageDirectory: "Application Support/LocalModels",
                expectedSHA256: sha256,
                tokenizerIsEmbedded: true,
                allowsNetworkDownload: false,
                importInstruction: "阅读 Gemma 许可与使用限制后，自行取得 \(fileName) 并从 Files 手动导入。仅接受登记摘要的版本；单个 GGUF 已包含 tokenizer。"
            ),
            deploymentProfile: AppleSiliconDeploymentProfile(
                preferredChipClass: "具备足够可用内存的 iPhone / iPad / Mac",
                recommendedMemoryBudget: "模型约 241 MB，另需上下文及计算内存；以实机结果为准",
                primaryBackend: .llamaCpp,
                fallbackBackend: .llamaCpp,
                kvCachePolicy: "单会话独立 KV cache；最多 4096 tokens",
                thermalStrategy: "一次只生成一条回复，输出最多 512 tokens",
                maxActiveTokens: 4096
            )
        )
    }

    static func supports(_ model: LocalModel) -> Bool {
        model.id == id && model.artifactManifest.modelFileName == fileName
            && model.artifactManifest.expectedSHA256 == sha256
            && model.artifactManifest.fileFormat == "GGUF"
            && model.artifactManifest.tokenizerIsEmbedded
            && !model.artifactManifest.allowsNetworkDownload
    }
}

struct VerifiedLlamaRuntime: LocalStreamingInferenceRuntime {
    func supports(_ model: LocalModel) -> Bool {
        PinnedTextModel.supports(model)
    }

    func stream(_ request: StreamingInferenceRequest) -> AsyncThrowingStream<InferenceStreamEvent, Error> {
        guard supports(request.model) else { return failed(.unsupportedModel) }
        guard request.availability == .verified else { return failed(.unverifiedArtifact) }
        #if canImport(llama)
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let nativeRequest = LlamaTextRequest(
                        modelURL: request.modelFileURL,
                        expectedSHA256: request.model.artifactManifest.expectedSHA256,
                        messages: request.messages.map { LlamaTextMessage(role: $0.role.rawValue, content: $0.text) },
                        contextLength: request.model.contextLength,
                        maximumOutputTokens: request.maximumOutputTokens
                    )
                    for try await event in LlamaTextRuntime().stream(nativeRequest) {
                        try Task.checkCancellation()
                        switch event {
                        case .text(let delta):
                            continuation.yield(.text(delta))
                        case .completed(let metrics):
                            continuation.yield(.completed(InferenceStreamMetrics(
                                promptTokens: metrics.promptTokens,
                                outputTokens: metrics.outputTokens,
                                tokensPerSecond: metrics.tokensPerSecond,
                                reachedOutputLimit: metrics.finishReason == .outputLimit
                            )))
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
        #else
        return failed(.backendUnavailable)
        #endif
    }

    private func failed(_ error: StreamingInferenceError) -> AsyncThrowingStream<InferenceStreamEvent, Error> {
        AsyncThrowingStream { $0.finish(throwing: error) }
    }
}
