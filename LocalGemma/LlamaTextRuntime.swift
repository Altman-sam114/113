import CryptoKit
import Darwin
import Foundation
#if canImport(llama)
@preconcurrency import llama
#endif

struct LlamaTextMessage: Equatable, Sendable {
    let role: String
    let content: String
}

struct LlamaTextRequest: Equatable, Sendable {
    let modelURL: URL
    let expectedSHA256: String
    let messages: [LlamaTextMessage]
    var contextLength: Int = 2_048
    var maximumOutputTokens: Int = 256

    func validate() throws {
        guard modelURL.isFileURL, modelURL.pathExtension.lowercased() == "gguf",
              !modelURL.path.utf8.contains(0), !modelURL.path.split(separator: "/").contains("..") else {
            throw LlamaTextRuntimeError.unsafeModelFile
        }
        let expected = expectedSHA256.trimmingCharacters(in: .whitespacesAndNewlines)
        guard expected.utf8.count == 64,
              expected.utf8.allSatisfy({ (48...57).contains($0) || (65...70).contains($0) || (97...102).contains($0) }) else {
            throw LlamaTextRuntimeError.unverifiedModel
        }
        guard (128...4_096).contains(contextLength), (1...512).contains(maximumOutputTokens),
              maximumOutputTokens < contextLength else {
            throw LlamaTextRuntimeError.invalidTokenBudget
        }
        guard !messages.isEmpty, messages.count <= 256, messages.last?.role == "user" else {
            throw LlamaTextRuntimeError.invalidMessages
        }
        var bytes = 0
        for message in messages {
            guard ["system", "user", "assistant"].contains(message.role),
                  !message.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  !message.content.utf8.contains(0), message.content.utf8.count <= 1_048_576 - bytes else {
                throw LlamaTextRuntimeError.invalidMessages
            }
            bytes += message.content.utf8.count
        }
    }
}

enum LlamaTextFinishReason: Equatable, Sendable {
    case endOfGeneration
    case outputLimit
}

struct LlamaTextMetrics: Equatable, Sendable {
    let promptTokens: Int
    let outputTokens: Int
    let loadSeconds: Double
    let prefillSeconds: Double
    let generationSeconds: Double
    let finishReason: LlamaTextFinishReason

    var tokensPerSecond: Double {
        guard generationSeconds > 0 else { return 0 }
        return Double(outputTokens) / generationSeconds
    }
}

enum LlamaTextEvent: Equatable, Sendable {
    case text(String)
    case completed(LlamaTextMetrics)
}

enum LlamaTextRuntimeError: Error, Equatable, LocalizedError, Sendable {
    case backendUnavailable
    case unsafeModelFile
    case modelFileUnavailable
    case modelChanged
    case unverifiedModel
    case hashMismatch
    case invalidTokenBudget
    case invalidMessages
    case modelLoadFailed
    case unsupportedModel
    case missingChatTemplate
    case unsupportedChatTemplate
    case tokenizationFailed
    case contextBudgetExceeded(input: Int, output: Int, capacity: Int)
    case contextCreationFailed
    case allocationFailed
    case insufficientMemory(requiredBytes: UInt64, availableBytes: UInt64)
    case decodeFailed
    case invalidOutputEncoding

    var errorDescription: String? {
        switch self {
        case .backendUnavailable: "The native local inference backend is not linked in this build."
        case .unsafeModelFile: "The model must be a regular local GGUF file without symbolic links."
        case .modelFileUnavailable: "The local model file could not be read. Import or scan it again."
        case .modelChanged: "The model changed during verification or loading. Import or scan it again."
        case .unverifiedModel: "A concrete, trusted SHA-256 is required before native inference."
        case .hashMismatch: "The actual model SHA-256 does not match the trusted manifest."
        case .invalidTokenBudget: "The requested context or output token budget is not supported."
        case .invalidMessages: "The complete conversation is empty, unsupported, or too large. Nothing was truncated."
        case .modelLoadFailed: "The verified file could not be loaded as a native GGUF text model."
        case .unsupportedModel: "This model is not a supported decoder-only text model."
        case .missingChatTemplate: "The model has no embedded chat template. No guessed template was used."
        case .unsupportedChatTemplate: "The native backend cannot safely apply this model's chat template."
        case .tokenizationFailed: "The model tokenizer could not encode the complete conversation."
        case .contextBudgetExceeded(let input, let output, let capacity):
            "The complete conversation needs \(input) input plus \(output) output tokens, exceeding the \(capacity)-token context. Nothing was truncated."
        case .contextCreationFailed: "The local inference context could not be allocated."
        case .allocationFailed: "The local inference batch or sampler could not be allocated."
        case .insufficientMemory(let required, let available):
            "Local inference needs at least \(required / 1_048_576) MiB of conservative headroom; only \(available / 1_048_576) MiB is currently available. This preflight does not guarantee allocation or device support."
        case .decodeFailed: "The local model could not continue generation."
        case .invalidOutputEncoding: "The model produced an invalid UTF-8 sequence. Invalid bytes were not displayed."
        }
    }
}

enum LlamaTextMemoryPolicy {
    static func requiredAvailableBytes(modelBytes: UInt64, contextLength: Int) throws -> UInt64 {
        guard modelBytes <= 8 * 1_024 * 1_024 * 1_024, (128...4_096).contains(contextLength) else {
            throw LlamaTextRuntimeError.invalidTokenBudget
        }
        // Conservative admission estimate, not a measured working set or an allocation guarantee.
        let workingReserve = UInt64(256 * 1_024 * 1_024) + UInt64(contextLength) * 128 * 1_024
        return modelBytes + workingReserve
    }

    static func validate(modelBytes: UInt64, contextLength: Int, availableBytes: UInt64) throws {
        let required = try requiredAvailableBytes(modelBytes: modelBytes, contextLength: contextLength)
        guard availableBytes >= required else {
            throw LlamaTextRuntimeError.insufficientMemory(requiredBytes: required, availableBytes: availableBytes)
        }
    }
}

final class LlamaTextCancellation: @unchecked Sendable {
    private let lock = NSLock()
    private var cancelled = false

    var isCancelled: Bool { lock.withLock { cancelled } }
    func cancel() { lock.withLock { cancelled = true } }
    func check() throws {
        if isCancelled { throw CancellationError() }
    }
}

struct LlamaTextUTF8Buffer {
    private var pending: [UInt8] = []

    mutating func append(_ bytes: [UInt8]) throws -> String {
        pending.append(contentsOf: bytes)
        for suffixCount in 0...min(3, pending.count) {
            let boundary = pending.count - suffixCount
            guard let text = String(bytes: pending.prefix(boundary), encoding: .utf8),
                  Self.isIncompleteScalar(pending.suffix(suffixCount)) else { continue }
            pending = Array(pending.suffix(suffixCount))
            return text
        }
        throw LlamaTextRuntimeError.invalidOutputEncoding
    }

    mutating func finish() throws -> String {
        guard let text = String(bytes: pending, encoding: .utf8) else {
            throw LlamaTextRuntimeError.invalidOutputEncoding
        }
        pending.removeAll(keepingCapacity: false)
        return text
    }

    private static func isIncompleteScalar(_ suffix: ArraySlice<UInt8>) -> Bool {
        guard let first = suffix.first else { return true }
        let required: Int
        switch first {
        case 0xC2...0xDF: required = 2
        case 0xE0...0xEF: required = 3
        case 0xF0...0xF4: required = 4
        default: return false
        }
        guard suffix.count < required, suffix.dropFirst().allSatisfy({ (0x80...0xBF).contains($0) }) else {
            return false
        }
        if suffix.count > 1 {
            let second = suffix[suffix.index(after: suffix.startIndex)]
            if first == 0xE0 && second < 0xA0 { return false }
            if first == 0xED && second > 0x9F { return false }
            if first == 0xF0 && second < 0x90 { return false }
            if first == 0xF4 && second > 0x8F { return false }
        }
        return true
    }
}

struct LlamaTextRuntime: Sendable {
    // The backend has process-global state. Even separate runtime values share one owner.
    private static let worker = DispatchQueue(label: "agentx.native-text-runtime", qos: .userInitiated)

    func stream(_ request: LlamaTextRequest) -> AsyncThrowingStream<LlamaTextEvent, Error> {
        AsyncThrowingStream { continuation in
            let cancellation = LlamaTextCancellation()
            continuation.onTermination = { @Sendable _ in cancellation.cancel() }
            Self.worker.async {
                do {
                    try cancellation.check()
                    try request.validate()
#if canImport(llama)
                    let metrics = try Self.generate(request, cancellation: cancellation) { delta in
                        try cancellation.check()
                        if case .terminated = continuation.yield(.text(delta)) {
                            cancellation.cancel()
                            throw CancellationError()
                        }
                    }
                    // Native synchronization and all frees finish before completion is visible.
                    try cancellation.check()
                    continuation.yield(.completed(metrics))
                    continuation.finish()
#else
                    throw LlamaTextRuntimeError.backendUnavailable
#endif
                } catch {
                    continuation.finish(throwing: cancellation.isCancelled ? CancellationError() : error)
                }
            }
        }
    }

#if canImport(llama)
    private static let batchCapacity = 64

    private static func generate(
        _ request: LlamaTextRequest,
        cancellation: LlamaTextCancellation,
        emit: (String) throws -> Void
    ) throws -> LlamaTextMetrics {
        let loadStart = DispatchTime.now().uptimeNanoseconds
        let file = try openVerifiedModel(request, cancellation: cancellation)
        defer { fclose(file) }
        defer { withExtendedLifetime(cancellation) {} }
        let originalIdentity = try identity(fileno(file))
        try checkAvailableMemory(modelBytes: UInt64(originalIdentity.size), contextLength: request.contextLength)

        // Model metadata and native diagnostics must not leak paths or user text to logs.
        llama_log_set({ _, _, _ in }, nil)
        llama_backend_init()
        defer { llama_backend_free() }

        let opaqueCancellation = Unmanaged.passUnretained(cancellation).toOpaque()
        var modelParameters = llama_model_default_params()
#if targetEnvironment(simulator) || targetEnvironment(macCatalyst)
        modelParameters.n_gpu_layers = 0
#else
        modelParameters.n_gpu_layers = -1
#endif
        modelParameters.progress_callback_user_data = opaqueCancellation
        modelParameters.progress_callback = { _, data in
            guard let data else { return false }
            return !Unmanaged<LlamaTextCancellation>.fromOpaque(data).takeUnretainedValue().isCancelled
        }
        guard let model = llama_model_load_from_file_ptr(file, modelParameters) else {
            try cancellation.check()
            throw LlamaTextRuntimeError.modelLoadFailed
        }
        defer { llama_model_free(model) }
        try cancellation.check()
        guard originalIdentity == (try identity(fileno(file))) else { throw LlamaTextRuntimeError.modelChanged }
        guard !llama_model_has_encoder(model), llama_model_has_decoder(model) else {
            throw LlamaTextRuntimeError.unsupportedModel
        }
        guard request.contextLength <= Int(llama_model_n_ctx_train(model)) else {
            throw LlamaTextRuntimeError.invalidTokenBudget
        }
        guard let vocabulary = llama_model_get_vocab(model),
              let templatePointer = llama_model_chat_template(model, nil), templatePointer.pointee != 0 else {
            throw LlamaTextRuntimeError.missingChatTemplate
        }
        let rendered = try render(request.messages, template: templatePointer, cancellation: cancellation)
        let tokens = try tokenize(rendered, vocabulary: vocabulary)
        try checkBudget(input: tokens.count, output: request.maximumOutputTokens, capacity: request.contextLength)
        try checkAvailableMemory(modelBytes: 0, contextLength: request.contextLength)

        var contextParameters = llama_context_default_params()
        contextParameters.n_ctx = UInt32(request.contextLength)
        contextParameters.n_batch = UInt32(batchCapacity)
        contextParameters.n_ubatch = UInt32(batchCapacity)
        contextParameters.n_seq_max = 1
        let threads = Int32(max(1, min(4, ProcessInfo.processInfo.activeProcessorCount - 1)))
        contextParameters.n_threads = threads
        contextParameters.n_threads_batch = threads
#if targetEnvironment(simulator) || targetEnvironment(macCatalyst)
        contextParameters.offload_kqv = false
        contextParameters.op_offload = false
#endif
        contextParameters.abort_callback_data = opaqueCancellation
        contextParameters.abort_callback = { data in
            guard let data else { return true }
            return Unmanaged<LlamaTextCancellation>.fromOpaque(data).takeUnretainedValue().isCancelled
        }
        guard let context = llama_init_from_model(model, contextParameters) else {
            try cancellation.check()
            throw LlamaTextRuntimeError.contextCreationFailed
        }
        defer {
            // The CPU abort hook does not guarantee interruption of already submitted Metal work.
            llama_synchronize(context)
            llama_free(context)
        }
        try cancellation.check()
        guard originalIdentity == (try identity(fileno(file))) else { throw LlamaTextRuntimeError.modelChanged }
        let capacity = min(request.contextLength, Int(llama_n_ctx(context)))
        try checkBudget(input: tokens.count, output: request.maximumOutputTokens, capacity: capacity)
        guard let sampler = llama_sampler_init_greedy() else { throw LlamaTextRuntimeError.allocationFailed }
        defer { llama_sampler_free(sampler) }
        var batch = llama_batch_init(Int32(batchCapacity), 0, 1)
        defer { llama_batch_free(batch) }
        guard batch.token != nil, batch.pos != nil, batch.n_seq_id != nil,
              batch.seq_id != nil, batch.logits != nil else { throw LlamaTextRuntimeError.allocationFailed }
        let loadSeconds = elapsed(since: loadStart)
        let prefillStart = DispatchTime.now().uptimeNanoseconds
        var offset = 0
        while offset < tokens.count {
            try cancellation.check()
            let end = min(offset + batchCapacity, tokens.count)
            try fill(&batch, tokens: tokens[offset..<end], startingPosition: offset, needsLogits: end == tokens.count)
            try decode(batch, context: context, cancellation: cancellation)
            offset = end
        }
        llama_synchronize(context)
        try cancellation.check()
        let prefillSeconds = elapsed(since: prefillStart)
        let generationStart = DispatchTime.now().uptimeNanoseconds
        var utf8 = LlamaTextUTF8Buffer()
        var outputTokens = 0
        var finishReason = LlamaTextFinishReason.outputLimit
        while outputTokens < request.maximumOutputTokens {
            try cancellation.check()
            // llama_sampler_sample also accepts the sampled token; do not accept it twice.
            let token = llama_sampler_sample(sampler, context, -1)
            if llama_vocab_is_eog(vocabulary, token) {
                let tail = try utf8.finish()
                if !tail.isEmpty { try emit(tail) }
                finishReason = .endOfGeneration
                break
            }
            let piece = try tokenBytes(token, vocabulary: vocabulary)
            let delta = try utf8.append(piece)
            try cancellation.check()
            if !delta.isEmpty { try emit(delta) }
            outputTokens += 1
            if outputTokens < request.maximumOutputTokens {
                try fill(&batch, tokens: [token][...], startingPosition: tokens.count + outputTokens - 1, needsLogits: true)
                try decode(batch, context: context, cancellation: cancellation)
            }
        }
        try cancellation.check()
        guard originalIdentity == (try identity(fileno(file))) else { throw LlamaTextRuntimeError.modelChanged }
        // A length limit is not EOS. An unfinished UTF-8 tail is never published as replacement text.
        return LlamaTextMetrics(
            promptTokens: tokens.count, outputTokens: outputTokens, loadSeconds: loadSeconds,
            prefillSeconds: prefillSeconds, generationSeconds: elapsed(since: generationStart),
            finishReason: finishReason
        )
    }

    private struct FileIdentity: Equatable {
        let device: dev_t
        let inode: ino_t
        let size: off_t
        let modifiedSeconds: Int
        let modifiedNanos: Int
        let changedSeconds: Int
        let changedNanos: Int

        init(_ info: stat) {
            device = info.st_dev
            inode = info.st_ino
            size = info.st_size
            modifiedSeconds = info.st_mtimespec.tv_sec
            modifiedNanos = info.st_mtimespec.tv_nsec
            changedSeconds = info.st_ctimespec.tv_sec
            changedNanos = info.st_ctimespec.tv_nsec
        }
    }

    private static func identity(_ descriptor: Int32) throws -> FileIdentity {
        var info = stat()
        guard fstat(descriptor, &info) == 0 else { throw LlamaTextRuntimeError.modelFileUnavailable }
        guard (info.st_mode & S_IFMT) == S_IFREG, info.st_size > 0,
              info.st_size <= 8 * 1_024 * 1_024 * 1_024 else { throw LlamaTextRuntimeError.unsafeModelFile }
        return FileIdentity(info)
    }

    private static func openVerifiedModel(
        _ request: LlamaTextRequest, cancellation: LlamaTextCancellation
    ) throws -> UnsafeMutablePointer<FILE> {
        var path = request.modelURL.standardizedFileURL.path
        // Only canonicalize Apple's published aliases, not user-controlled symbolic links.
        if path.hasPrefix("/var/") || path.hasPrefix("/tmp/") { path = "/private" + path }
        let descriptor = open(path, O_RDONLY | O_CLOEXEC | O_NONBLOCK | O_NOFOLLOW_ANY)
        guard descriptor >= 0 else {
            throw errno == ELOOP || errno == ENOTDIR
                ? LlamaTextRuntimeError.unsafeModelFile : LlamaTextRuntimeError.modelFileUnavailable
        }
        var transferred = false
        defer { if !transferred { close(descriptor) } }
        let before = try identity(descriptor)
        var hasher = SHA256()
        var total: off_t = 0
        var buffer = [UInt8](repeating: 0, count: 1_048_576)
        while true {
            try cancellation.check()
            let count = buffer.withUnsafeMutableBytes { Darwin.read(descriptor, $0.baseAddress, $0.count) }
            if count == 0 { break }
            if count < 0, errno == EINTR { continue }
            guard count > 0 else { throw LlamaTextRuntimeError.modelFileUnavailable }
            total += off_t(count)
            guard total <= before.size else { throw LlamaTextRuntimeError.modelChanged }
            hasher.update(data: Data(buffer.prefix(count)))
        }
        try cancellation.check()
        guard total == before.size, before == (try identity(descriptor)) else {
            throw LlamaTextRuntimeError.modelChanged
        }
        let digest = hasher.finalize().map { String(format: "%02x", $0) }.joined()
        guard digest == request.expectedSHA256.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() else {
            throw LlamaTextRuntimeError.hashMismatch
        }
        guard lseek(descriptor, 0, SEEK_SET) == 0, let file = fdopen(descriptor, "rb") else {
            throw LlamaTextRuntimeError.modelFileUnavailable
        }
        transferred = true
        return file
    }

    private static func render(
        _ messages: [LlamaTextMessage], template: UnsafePointer<CChar>, cancellation: LlamaTextCancellation
    ) throws -> String {
        var strings: [UnsafeMutablePointer<CChar>] = []
        defer { strings.forEach { free($0) } }
        var chat: [llama_chat_message] = []
        for message in messages {
            try cancellation.check()
            guard let role = strdup(message.role) else { throw LlamaTextRuntimeError.allocationFailed }
            strings.append(role)
            guard let content = strdup(message.content) else { throw LlamaTextRuntimeError.allocationFailed }
            strings.append(content)
            chat.append(llama_chat_message(role: UnsafePointer(role), content: UnsafePointer(content)))
        }
        return try chat.withUnsafeBufferPointer { chat in
            let required = llama_chat_apply_template(template, chat.baseAddress, chat.count, true, nil, 0)
            guard required > 0, required < 2_097_152 else { throw LlamaTextRuntimeError.unsupportedChatTemplate }
            var buffer = [CChar](repeating: 0, count: Int(required) + 1)
            let written = buffer.withUnsafeMutableBufferPointer {
                llama_chat_apply_template(template, chat.baseAddress, chat.count, true, $0.baseAddress, Int32($0.count))
            }
            guard written == required,
                  let prompt = String(bytes: buffer.prefix(Int(written)).map({ UInt8(bitPattern: $0) }), encoding: .utf8),
                  !prompt.isEmpty else { throw LlamaTextRuntimeError.unsupportedChatTemplate }
            return prompt
        }
    }

    private static func tokenize(_ prompt: String, vocabulary: OpaquePointer) throws -> [llama_token] {
        guard let length = Int32(exactly: prompt.utf8.count) else { throw LlamaTextRuntimeError.tokenizationFailed }
        return try prompt.withCString { text in
            let sizing = llama_tokenize(vocabulary, text, length, nil, 0, true, true)
            guard sizing < 0, sizing != Int32.min, -sizing <= 2_097_152 else {
                throw LlamaTextRuntimeError.tokenizationFailed
            }
            var tokens = [llama_token](repeating: 0, count: Int(-sizing))
            let count = tokens.withUnsafeMutableBufferPointer {
                llama_tokenize(vocabulary, text, length, $0.baseAddress, Int32($0.count), true, true)
            }
            guard count > 0, count <= tokens.count else { throw LlamaTextRuntimeError.tokenizationFailed }
            return Array(tokens.prefix(Int(count)))
        }
    }

    private static func checkBudget(input: Int, output: Int, capacity: Int) throws {
        guard input <= capacity - output else {
            throw LlamaTextRuntimeError.contextBudgetExceeded(input: input, output: output, capacity: capacity)
        }
    }

    private static func checkAvailableMemory(modelBytes: UInt64, contextLength: Int) throws {
#if os(iOS) && !targetEnvironment(simulator)
        // This API is a fresh app-limit snapshot, not device RAM. Zero fails closed.
        // Simulator has no representative jetsam limit; its runs do not validate this device gate.
        try LlamaTextMemoryPolicy.validate(
            modelBytes: modelBytes, contextLength: contextLength,
            availableBytes: UInt64(os_proc_available_memory())
        )
#endif
    }

    private static func fill(
        _ batch: inout llama_batch, tokens: ArraySlice<llama_token>, startingPosition: Int, needsLogits: Bool
    ) throws {
        batch.n_tokens = Int32(tokens.count)
        for (index, token) in tokens.enumerated() {
            guard let sequence = batch.seq_id[index] else { throw LlamaTextRuntimeError.allocationFailed }
            batch.token[index] = token
            batch.pos[index] = Int32(startingPosition + index)
            batch.n_seq_id[index] = 1
            sequence[0] = 0
            batch.logits[index] = needsLogits && index == tokens.count - 1 ? 1 : 0
        }
    }

    private static func decode(
        _ batch: llama_batch, context: OpaquePointer, cancellation: LlamaTextCancellation
    ) throws {
        try cancellation.check()
        let result = llama_decode(context, batch)
        try cancellation.check()
        guard result == 0 else { throw LlamaTextRuntimeError.decodeFailed }
    }

    private static func tokenBytes(_ token: llama_token, vocabulary: OpaquePointer) throws -> [UInt8] {
        var buffer = [CChar](repeating: 0, count: 32)
        var count = buffer.withUnsafeMutableBufferPointer {
            llama_token_to_piece(vocabulary, token, $0.baseAddress, Int32($0.count), 0, false)
        }
        if count < 0 {
            guard count != Int32.min, -count <= 65_536 else { throw LlamaTextRuntimeError.invalidOutputEncoding }
            buffer = [CChar](repeating: 0, count: Int(-count))
            count = buffer.withUnsafeMutableBufferPointer {
                llama_token_to_piece(vocabulary, token, $0.baseAddress, Int32($0.count), 0, false)
            }
        }
        guard count >= 0, count <= buffer.count else { throw LlamaTextRuntimeError.invalidOutputEncoding }
        return buffer.prefix(Int(count)).map { UInt8(bitPattern: $0) }
    }

    private static func elapsed(since start: UInt64) -> Double {
        Double(DispatchTime.now().uptimeNanoseconds - start) / 1_000_000_000
    }
#endif
}
