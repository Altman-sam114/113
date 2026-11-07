import CryptoKit
import Foundation
import SwiftUI
import UIKit
import XCTest
@testable import LocalGemma

@MainActor
final class RuntimeStreamingTests: XCTestCase {
    func testPinnedGGUFUsesOneTrustedFileWithoutNetworkDownload() {
        let model = PinnedTextModel.model
        XCTAssertEqual(model.name, "Gemma 3 270M")
        XCTAssertEqual(model.parameterCount, "270M")
        XCTAssertEqual(model.quantization, "QAT Q4_0")
        XCTAssertEqual(PinnedTextModel.byteCount, 241_410_624)
        XCTAssertEqual(PinnedTextModel.fileName, "gemma-3-270m-it-qat-Q4_0.gguf")
        XCTAssertEqual(PinnedTextModel.sha256, "3626e245220ca4a1c5911eb4010b3ecb7bdbf5bc53c79403c21355354d1e2dc6")
        XCTAssertEqual(model.artifactManifest.requiredFiles, [PinnedTextModel.fileName])
        XCTAssertEqual(model.artifactManifest.expectedSHA256, PinnedTextModel.sha256)
        XCTAssertTrue(model.artifactManifest.tokenizerIsEmbedded)
        XCTAssertFalse(model.artifactManifest.allowsNetworkDownload)
        XCTAssertTrue(VerifiedLlamaRuntime().supports(model))
        XCTAssertFalse(VerifiedLlamaRuntime().supports(ModelCatalog.defaultModels[0]))
        var changed = model
        changed = LocalModel(
            id: UUID(uuidString: "A6E8926E-E8A0-4FDB-9A34-E90C7475029B")!,
            name: changed.name, family: changed.family, parameterCount: changed.parameterCount,
            quantization: changed.quantization, sizeOnDisk: changed.sizeOnDisk,
            contextLength: changed.contextLength, tokensPerSecond: changed.tokensPerSecond,
            memoryFootprint: changed.memoryFootprint, installState: changed.installState,
            summary: changed.summary, capabilities: changed.capabilities,
            artifactManifest: changed.artifactManifest, deploymentProfile: changed.deploymentProfile
        )
        XCTAssertFalse(VerifiedLlamaRuntime().supports(changed), "Another catalogue identity cannot inherit native trust")
        XCTAssertNotEqual(PinnedTextModel.id, changed.id, "The former 1B identity cannot become a 270M model")
        var formerManifest = model
        formerManifest.artifactManifest = ModelArtifactManifest(
            modelFileName: "gemma-3-1b-it-Q4_K_M.gguf", tokenizerFileName: "", fileFormat: "GGUF",
            storageDirectory: model.artifactManifest.storageDirectory,
            expectedSHA256: "8ccc5cd1f1b3602548715ae25a66ed73fd5dc68a210412eea643eb20eb75a135",
            tokenizerIsEmbedded: true, allowsNetworkDownload: false, importInstruction: "Former 1B file"
        )
        XCTAssertFalse(VerifiedLlamaRuntime().supports(formerManifest), "The new identity cannot trust the former 1B file")
        XCTAssertEqual(PinnedTextModel.sourceURL.scheme, "https")
        XCTAssertEqual(PinnedTextModel.sourceURL.host, "ai.google.dev")
        XCTAssertEqual(PinnedTextModel.sourceURL.path, "/gemma/docs/core/model_card_3")
        XCTAssertEqual(PinnedTextModel.revision, PinnedTextModel.sha256, "The local bytes are pinned by their digest, not an unverified upstream revision")
    }

    func testNativeSendRejectsUnverifiedFilesWithoutConsumingDraft() {
        let runtime = ControlledStreamingRuntime()
        let engine = InferenceEngine(streamingRuntime: runtime)
        for availability in [ArtifactAvailability.missing, .staged] {
            engine.inputText = "  Preserve this draft\n"
            engine.send(using: PinnedTextModel.model, availability: availability,
                        artifactDirectoryURL: URL(fileURLWithPath: "/unused"))
            XCTAssertEqual(engine.inputText, "  Preserve this draft\n")
            XCTAssertTrue(engine.messages.isEmpty)
            XCTAssertFalse(engine.isGenerating)
            XCTAssertNotNil(engine.generationError)
            XCTAssertTrue(runtime.requests.isEmpty)
            XCTAssertTrue(engine.lastResultWasSimulated)
        }
    }

    func testNativeStreamPreservesOrderedHistoryAndUsesActualCompletionMetrics() async throws {
        let first = expectation(description: "first native request")
        let second = expectation(description: "second native request")
        let runtime = ControlledStreamingRuntime(onRequest: { index in
            (index == 0 ? first : second).fulfill()
        })
        let engine = InferenceEngine(streamingRuntime: runtime)
        let directory = URL(fileURLWithPath: "/unused-native-fixture", isDirectory: true)
        engine.inputText = "First question"
        engine.send(using: PinnedTextModel.model, availability: .verified, artifactDirectoryURL: directory)
        let firstResult = await XCTWaiter.fulfillment(of: [first], timeout: 3)
        XCTAssertEqual(firstResult, .completed)
        guard firstResult == .completed else { engine.stop(); return }
        XCTAssertTrue(engine.lastResultWasSimulated, "No native token has been produced while loading")
        runtime.emit(.text("  Exact answer\n"), request: 0)
        runtime.emit(.completed(InferenceStreamMetrics(promptTokens: 9, outputTokens: 4,
                                                      tokensPerSecond: 12.5, reachedOutputLimit: false)), request: 0)
        runtime.finish(request: 0)
        await engine.waitForCurrentGeneration()
        XCTAssertFalse(engine.isGenerating)
        XCTAssertFalse(engine.lastResultWasSimulated)
        XCTAssertEqual(engine.messages.last?.text, "  Exact answer\n")
        XCTAssertEqual(engine.messages.last?.tokens, 4)
        XCTAssertEqual(engine.currentTokensPerSecond, 12.5)
        XCTAssertEqual(engine.currentBackend, .llamaCpp)

        engine.inputText = "Next question"
        engine.send(using: PinnedTextModel.model, availability: .verified, artifactDirectoryURL: directory)
        let secondResult = await XCTWaiter.fulfillment(of: [second], timeout: 3)
        XCTAssertEqual(secondResult, .completed)
        guard secondResult == .completed else { engine.stop(); return }
        let request = try XCTUnwrap(runtime.requests.last)
        XCTAssertEqual(request.messages.map(\.role), [.user, .assistant, .user])
        XCTAssertEqual(request.messages.map(\.text), ["First question", "  Exact answer\n", "Next question"])
        XCTAssertEqual(request.modelFileURL, directory.appendingPathComponent(PinnedTextModel.fileName))
        XCTAssertEqual(request.maximumOutputTokens, 512)
        engine.stop()
    }

    func testStoppedNativeGenerationCannotWriteIntoAnotherSession() async throws {
        let entered = expectation(description: "native request entered")
        let runtime = ControlledStreamingRuntime(onRequest: { _ in entered.fulfill() })
        let engine = InferenceEngine(streamingRuntime: runtime)
        engine.inputText = "Old session question"
        engine.send(using: PinnedTextModel.model, availability: .verified,
                    artifactDirectoryURL: URL(fileURLWithPath: "/unused"))
        let result = await XCTWaiter.fulfillment(of: [entered], timeout: 3)
        XCTAssertEqual(result, .completed)
        guard result == .completed else { engine.stop(); return }
        let oldID = engine.activeSessionID
        let newID = engine.createSession()
        engine.inputText = "New session draft"
        runtime.emit(.text("Late old token"), request: 0)
        runtime.finish(request: 0)
        await engine.waitForCurrentGeneration()
        XCTAssertNotEqual(newID, oldID)
        XCTAssertEqual(engine.activeSessionID, newID)
        XCTAssertTrue(engine.messages.isEmpty)
        XCTAssertEqual(engine.inputText, "New session draft")
        XCTAssertFalse(engine.sessions.first(where: { $0.id == oldID })?.messages
            .contains(where: { $0.text.contains("Late old token") }) ?? true)
        XCTAssertFalse(engine.isGenerating)
    }

    func testFailedNativeLoadKeepsQuestionAndReportsLocalError() async throws {
        let entered = expectation(description: "native load requested")
        let runtime = ControlledStreamingRuntime(onRequest: { _ in entered.fulfill() })
        let engine = InferenceEngine(streamingRuntime: runtime)
        engine.inputText = "Keep my question"
        engine.send(using: PinnedTextModel.model, availability: .verified,
                    artifactDirectoryURL: URL(fileURLWithPath: "/unused"))
        let result = await XCTWaiter.fulfillment(of: [entered], timeout: 3)
        XCTAssertEqual(result, .completed)
        guard result == .completed else { engine.stop(); return }
        runtime.finish(request: 0, error: CocoaError(.fileReadCorruptFile))
        await engine.waitForCurrentGeneration()
        XCTAssertFalse(engine.isGenerating)
        XCTAssertTrue(engine.lastResultWasSimulated, "A failed loader cannot set REAL")
        XCTAssertNotNil(engine.generationError)
        XCTAssertEqual(engine.messages.first?.text, "Keep my question")
        XCTAssertEqual(engine.messages.last?.role, .system)
        XCTAssertFalse(engine.messages.last?.text.isEmpty ?? true)
    }

    func testUnterminatedNativeStreamCannotReportSuccessfulGeneration() async throws {
        let entered = expectation(description: "native request entered")
        let runtime = ControlledStreamingRuntime(onRequest: { _ in entered.fulfill() })
        let engine = InferenceEngine(streamingRuntime: runtime)
        engine.inputText = "Question"
        engine.send(using: PinnedTextModel.model, availability: .verified,
                    artifactDirectoryURL: URL(fileURLWithPath: "/unused"))
        let result = await XCTWaiter.fulfillment(of: [entered], timeout: 3)
        XCTAssertEqual(result, .completed)
        guard result == .completed else { engine.stop(); return }
        runtime.emit(.text("Keep partial answer"), request: 0)
        runtime.finish(request: 0)
        await engine.waitForCurrentGeneration()
        XCTAssertNotNil(engine.generationError)
        XCTAssertTrue(engine.messages.contains(where: { $0.text == "Keep partial answer" }))
        XCTAssertEqual(engine.messages.last?.role, .system)
        XCTAssertFalse(engine.isGenerating)
    }

    func testFailedNativeRetryBranchesExactContextAndPreservesOriginalDraftAndPartialAnswer() async throws {
        let started = (0..<3).map { expectation(description: "native attempt \($0)") }
        let runtime = ControlledStreamingRuntime(onRequest: { index in
            guard started.indices.contains(index) else { XCTFail("Unexpected attempt"); return }
            started[index].fulfill()
        })
        let engine = InferenceEngine(streamingRuntime: runtime)
        let model = PinnedTextModel.model
        let directory = URL(fileURLWithPath: "/original-fixture")
        engine.inputText = "Earlier question"
        engine.send(using: model, availability: .verified, artifactDirectoryURL: directory)
        var result = await XCTWaiter.fulfillment(of: [started[0]], timeout: 3)
        XCTAssertEqual(result, .completed)
        guard result == .completed else { engine.stop(); return }
        runtime.emit(.text("Earlier answer"), request: 0)
        runtime.emit(.completed(InferenceStreamMetrics(promptTokens: 3, outputTokens: 2,
                                                      tokensPerSecond: 10, reachedOutputLimit: false)), request: 0)
        runtime.finish(request: 0)
        await engine.waitForCurrentGeneration()
        engine.inputText = "Retry this question"
        engine.send(using: model, availability: .verified, artifactDirectoryURL: directory)
        result = await XCTWaiter.fulfillment(of: [started[1]], timeout: 3)
        XCTAssertEqual(result, .completed)
        guard result == .completed else { engine.stop(); return }
        runtime.emit(.text("  Unfinished answer\n"), request: 1)
        runtime.finish(request: 1, error: CocoaError(.fileReadCorruptFile))
        await engine.waitForCurrentGeneration()
        XCTAssertTrue(engine.canRetryNativeGeneration(using: model, availability: .verified))
        engine.inputText = "  Another unsent draft\n"
        let originalSession = try XCTUnwrap(engine.activeSession)
        let originalExport = engine.exportActiveSessionText()
        let originalRequest = runtime.requests[1]
        let newDirectory = URL(fileURLWithPath: "/revalidated-fixture")
        XCTAssertTrue(engine.retryNativeGeneration(using: model, availability: .verified,
                                                   artifactDirectoryURL: newDirectory))
        XCTAssertNotEqual(engine.activeSessionID, originalSession.id)
        XCTAssertEqual(engine.sessions.first(where: { $0.id == originalSession.id }), originalSession)
        XCTAssertEqual(engine.messages.dropLast(), originalRequest.messages[...])
        XCTAssertEqual(engine.messages.filter { $0.role == .user }.count, 2)
        XCTAssertFalse(engine.messages.contains { $0.text == "  Unfinished answer\n" || $0.isRuntimeStatus == true })
        XCTAssertEqual(engine.inputText, "")
        let retryMessages = engine.messages
        XCTAssertFalse(engine.retryNativeGeneration(using: model, availability: .verified,
                                                    artifactDirectoryURL: newDirectory), "A double activation cannot create another session")
        XCTAssertEqual(engine.messages, retryMessages)
        XCTAssertEqual(engine.sessions.count, 2)
        result = await XCTWaiter.fulfillment(of: [started[2]], timeout: 3)
        XCTAssertEqual(result, .completed)
        guard result == .completed else { engine.stop(); return }
        XCTAssertEqual(runtime.requests[2].messages, originalRequest.messages)
        XCTAssertEqual(runtime.requests[2].modelFileURL, newDirectory.appendingPathComponent(PinnedTextModel.fileName))
        runtime.emit(.text("Recovered answer"), request: 2)
        runtime.emit(.completed(InferenceStreamMetrics(promptTokens: 12, outputTokens: 3,
                                                      tokensPerSecond: 9, reachedOutputLimit: false)), request: 2)
        runtime.finish(request: 2)
        await engine.waitForCurrentGeneration()
        XCTAssertNil(engine.generationError)
        XCTAssertEqual(engine.messages.last?.text, "Recovered answer")
        XCTAssertFalse(engine.canRetryNativeGeneration(using: model, availability: .verified))
        engine.selectSession(originalSession)
        XCTAssertEqual(engine.messages, originalSession.messages)
        XCTAssertEqual(engine.inputText, "  Another unsent draft\n")
        // Export time may advance, but every original message is still present.
        for message in originalSession.messages { XCTAssertTrue(originalExport.contains(message.text)) }
    }

    func testFailedNativeRetryRequiresCurrentVerifiedModelAndInvalidatesAcrossSessionChanges() async throws {
        let entered = expectation(description: "failed load")
        let runtime = ControlledStreamingRuntime(onRequest: { _ in entered.fulfill() })
        let engine = InferenceEngine(streamingRuntime: runtime)
        let model = PinnedTextModel.model
        let directory = URL(fileURLWithPath: "/fixture")
        engine.inputText = "Original question"
        engine.send(using: model, availability: .verified, artifactDirectoryURL: directory)
        let result = await XCTWaiter.fulfillment(of: [entered], timeout: 3)
        XCTAssertEqual(result, .completed)
        guard result == .completed else { engine.stop(); return }
        runtime.finish(request: 0, error: CocoaError(.fileReadCorruptFile))
        await engine.waitForCurrentGeneration()
        engine.inputText = "Keep this draft"
        let original = try XCTUnwrap(engine.activeSession)
        for availability in [ArtifactAvailability.missing, .staged] {
            XCTAssertFalse(engine.retryNativeGeneration(using: model, availability: availability,
                                                        artifactDirectoryURL: directory))
        }
        XCTAssertFalse(engine.retryNativeGeneration(using: model, availability: .verified, artifactDirectoryURL: nil))
        XCTAssertFalse(engine.retryNativeGeneration(using: ModelCatalog.defaultModels[0], availability: .verified,
                                                    artifactDirectoryURL: directory))
        XCTAssertEqual(engine.sessions, [original])
        XCTAssertEqual(engine.inputText, "Keep this draft")
        XCTAssertEqual(runtime.requests.count, 1)
        XCTAssertTrue(engine.canRetryNativeGeneration(using: model, availability: .verified))
        engine.createSession()
        engine.selectSession(original)
        XCTAssertFalse(engine.canRetryNativeGeneration(using: model, availability: .verified), "A stale retry cannot follow navigation")
        XCTAssertEqual(engine.inputText, "Keep this draft")
        XCTAssertEqual(engine.messages, original.messages)
    }

    func testNativeRetryCanFailAgainAndDoesNotFollowModelChangeOrReset() async throws {
        let first = expectation(description: "first failure")
        let second = expectation(description: "retry failure")
        let runtime = ControlledStreamingRuntime(onRequest: { index in
            (index == 0 ? first : second).fulfill()
        })
        let engine = InferenceEngine(streamingRuntime: runtime)
        let model = PinnedTextModel.model
        let directory = URL(fileURLWithPath: "/fixture")
        engine.inputText = "Question"
        engine.send(using: model, availability: .verified, artifactDirectoryURL: directory)
        let firstResult = await XCTWaiter.fulfillment(of: [first], timeout: 3)
        XCTAssertEqual(firstResult, .completed)
        guard firstResult == .completed else { engine.stop(); return }
        runtime.finish(request: 0, error: CocoaError(.fileReadCorruptFile))
        await engine.waitForCurrentGeneration()
        XCTAssertTrue(engine.retryNativeGeneration(using: model, availability: .verified,
                                                   artifactDirectoryURL: directory))
        let secondResult = await XCTWaiter.fulfillment(of: [second], timeout: 3)
        XCTAssertEqual(secondResult, .completed)
        guard secondResult == .completed else { engine.stop(); return }
        runtime.finish(request: 1, error: CocoaError(.fileReadCorruptFile))
        await engine.waitForCurrentGeneration()
        XCTAssertTrue(engine.canRetryNativeGeneration(using: model, availability: .verified))
        XCTAssertEqual(engine.sessions.count, 2)
        XCTAssertEqual(runtime.requests[0].messages, runtime.requests[1].messages)
        engine.stopNativeGeneration(ifModelChangedTo: ModelCatalog.defaultModels[0].id)
        engine.stopNativeGeneration(ifModelChangedTo: model.id)
        XCTAssertFalse(engine.canRetryNativeGeneration(using: model, availability: .verified))
        engine.resetConversation()
        XCTAssertFalse(engine.retryNativeGeneration(using: model, availability: .verified,
                                                    artifactDirectoryURL: directory))
        XCTAssertEqual(runtime.requests.count, 2)
    }

    func testNativeFailureNoticeGrowsNaturallyOnSmallScreensAndLargeText() {
        XCTAssertGreaterThanOrEqual(NativeGenerationFailureNotice.minimumActionHeight, 44)
        XCTAssertEqual(NativeGenerationFailureNotice.retryLabel, "在新会话重试")
        XCTAssertTrue(NativeGenerationFailureNotice.retryHint.contains("原会话、部分回答及草稿保留"))
        var actions = 0
        for theme in AppThemeMode.allCases {
            for width: CGFloat in [248, 284, 720] {
                var heights: [CGFloat] = []
                for textSize in [DynamicTypeSize.large, .accessibility5] {
                    let content = NativeGenerationFailureNotice(
                        message: StreamingInferenceError.emptyResponse.localizedDescription,
                        canRetry: true, retry: { actions += 1 }
                    )
                        .environment(\.appTheme, AppThemePalette(mode: theme))
                        .environment(\.dynamicTypeSize, textSize)
                        .frame(width: width)
                        .background(AppThemePalette(mode: theme).canvas)
                    let host = UIHostingController(rootView: content)
                    host.loadViewIfNeeded()
                    let natural = host.sizeThatFits(in: CGSize(width: width, height: 600))
                    let tall = host.sizeThatFits(in: CGSize(width: width, height: 1800))
                    XCTAssertTrue(natural.height.isFinite && natural.height > 44)
                    XCTAssertEqual(natural.width, width, accuracy: 1)
                    XCTAssertEqual(natural.height, tall.height, accuracy: 1)
                    heights.append(natural.height)
                    if width == 284 {
                        let renderer = ImageRenderer(content: content.environment(\.colorScheme, theme.colorScheme))
                        renderer.scale = 1
                        if let data = renderer.uiImage?.pngData() {
                            let attachment = XCTAttachment(data: data, uniformTypeIdentifier: "public.png")
                            attachment.name = "native-retry-notice-\(theme.rawValue)-\(textSize == .large ? "large" : "accessibility5")"
                            attachment.lifetime = .keepAlways
                            add(attachment)
                        } else { XCTFail("Could not render the production retry notice") }
                    }
                }
                XCTAssertGreaterThan(heights[1], heights[0])
            }
        }
        XCTAssertEqual(actions, 0, "Layout must not invoke retry")
    }

    func testLinkedNativeRetryRechecksActualFileInsteadOfTrustingUIAvailability() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("NativeRetry-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent(PinnedTextModel.fileName)
        let originalBytes = Data("Untrusted fixture; no model weights".utf8)
        try originalBytes.write(to: file)
        let engine = InferenceEngine(streamingRuntime: VerifiedLlamaRuntime())
        engine.inputText = "Keep this question"
        engine.send(using: PinnedTextModel.model, availability: .verified, artifactDirectoryURL: directory)
        await engine.waitForCurrentGeneration()
        XCTAssertEqual(engine.generationError, LlamaTextRuntimeError.hashMismatch.localizedDescription)
        XCTAssertTrue(engine.lastResultWasSimulated, "No actual native output may be claimed")
        let original = try XCTUnwrap(engine.activeSession)
        engine.inputText = "  Unsent draft  "
        let changedBytes = Data("Different untrusted fixture".utf8)
        try changedBytes.write(to: file)
        XCTAssertTrue(engine.retryNativeGeneration(using: PinnedTextModel.model, availability: .verified,
                                                   artifactDirectoryURL: directory))
        await engine.waitForCurrentGeneration()
        XCTAssertEqual(engine.generationError, LlamaTextRuntimeError.hashMismatch.localizedDescription)
        XCTAssertTrue(engine.lastResultWasSimulated)
        XCTAssertEqual(engine.sessions.first(where: { $0.id == original.id }), original)
        XCTAssertEqual(try Data(contentsOf: file), changedBytes)
        engine.selectSession(original)
        XCTAssertEqual(engine.inputText, "  Unsent draft  ")
        XCTAssertEqual(engine.messages, original.messages)
    }

    func testEmptyNativeCompletionPreservesQuestionAndCannotClaimAnAnswer() async {
        let entered = expectation(description: "empty native response requested")
        let runtime = ControlledStreamingRuntime(onRequest: { _ in entered.fulfill() })
        let engine = InferenceEngine(streamingRuntime: runtime)
        engine.inputText = "Keep the unanswered question"
        engine.send(using: PinnedTextModel.model, availability: .verified,
                    artifactDirectoryURL: URL(fileURLWithPath: "/unused"))
        let result = await XCTWaiter.fulfillment(of: [entered], timeout: 3)
        XCTAssertEqual(result, .completed)
        guard result == .completed else { engine.stop(); return }
        runtime.emit(.completed(InferenceStreamMetrics(promptTokens: 8, outputTokens: 0,
                                                      tokensPerSecond: 0, reachedOutputLimit: false)), request: 0)
        runtime.finish(request: 0)
        await engine.waitForCurrentGeneration()
        XCTAssertFalse(engine.isGenerating)
        XCTAssertTrue(engine.lastResultWasSimulated)
        XCTAssertEqual(engine.generationError, StreamingInferenceError.emptyResponse.localizedDescription)
        XCTAssertEqual(engine.messages.first?.text, "Keep the unanswered question")
        XCTAssertFalse(engine.messages.contains { $0.role == .assistant })
        XCTAssertEqual(engine.messages.last?.isRuntimeStatus, true)
    }

    func testNativeRequestRejectsUntrustedAndUnboundedInputsWithoutTruncation() throws {
        let request = LlamaTextRequest(
            modelURL: URL(fileURLWithPath: "/unused/model.gguf"),
            expectedSHA256: String(repeating: "a", count: 64),
            messages: [LlamaTextMessage(role: "user", content: "Original question")],
            contextLength: 4096, maximumOutputTokens: 512
        )
        XCTAssertNoThrow(try request.validate())
        for hash in ["manual-import-required", "", String(repeating: "g", count: 64)] {
            let invalid = LlamaTextRequest(modelURL: request.modelURL, expectedSHA256: hash, messages: request.messages)
            XCTAssertThrowsError(try invalid.validate())
        }
        for messages in [
            [], [LlamaTextMessage(role: "assistant", content: "No current question")],
            [LlamaTextMessage(role: "tool", content: "Unsupported role")],
            [LlamaTextMessage(role: "user", content: " \n")],
            [LlamaTextMessage(role: "user", content: "NUL\0content")],
            [LlamaTextMessage(role: "user", content: String(repeating: "x", count: 1_048_577))]
        ] {
            let invalid = LlamaTextRequest(modelURL: request.modelURL, expectedSHA256: request.expectedSHA256, messages: messages)
            XCTAssertThrowsError(try invalid.validate())
        }
        for (context, output) in [(127, 1), (4097, 512), (2048, 0), (2048, 513), (128, 128)] {
            let invalid = LlamaTextRequest(modelURL: request.modelURL, expectedSHA256: request.expectedSHA256,
                                          messages: request.messages, contextLength: context, maximumOutputTokens: output)
            XCTAssertThrowsError(try invalid.validate())
        }
        XCTAssertEqual(request.messages.first?.content, "Original question")
    }

    func testCompletedNativeResultCannotFollowAnotherModelOrSession() async {
        let entered = expectation(description: "native result requested")
        let runtime = ControlledStreamingRuntime(onRequest: { _ in entered.fulfill() })
        let engine = InferenceEngine(streamingRuntime: runtime)
        engine.inputText = "Question"
        engine.send(using: PinnedTextModel.model, availability: .verified,
                    artifactDirectoryURL: URL(fileURLWithPath: "/unused"))
        let result = await XCTWaiter.fulfillment(of: [entered], timeout: 3)
        XCTAssertEqual(result, .completed)
        guard result == .completed else { engine.stop(); return }
        runtime.emit(.text("Native fixture result"), request: 0)
        runtime.emit(.completed(InferenceStreamMetrics(promptTokens: 3, outputTokens: 2,
                                                      tokensPerSecond: 10, reachedOutputLimit: false)), request: 0)
        runtime.finish(request: 0)
        await engine.waitForCurrentGeneration()
        XCTAssertFalse(engine.lastResultWasSimulated)
        engine.stop()
        XCTAssertEqual(engine.cpuLoad, 0, "Stopping native work cannot invent a simulated CPU measurement")
        engine.stopNativeGeneration(ifModelChangedTo: ModelCatalog.defaultModels[0].id)
        XCTAssertTrue(engine.lastResultWasSimulated)
        XCTAssertNil(engine.lastPreparationReport)
        XCTAssertEqual(engine.currentTokensPerSecond, 0)
        engine.inputText = "Keep draft"
        engine.send(using: PinnedTextModel.model, availability: .missing)
        XCTAssertNotNil(engine.generationError)
        engine.createSession()
        XCTAssertNil(engine.generationError)
        XCTAssertEqual(engine.inputText, "")
    }

    func testRuntimeStatusMarkerIsBackwardCompatibleAndMetricsKeepUnknownExplicit() throws {
        let original = ChatMessage(role: .user, text: "Exact original text\n")
        let oldData = try JSONEncoder().encode(original)
        let oldJSON = try XCTUnwrap(JSONSerialization.jsonObject(with: oldData) as? [String: Any])
        XCTAssertNil(oldJSON["isRuntimeStatus"])
        XCTAssertEqual(try JSONDecoder().decode(ChatMessage.self, from: oldData), original)
        let status = ChatMessage(role: .system, text: "Local runtime status", isRuntimeStatus: true)
        XCTAssertEqual(try JSONDecoder().decode(ChatMessage.self, from: JSONEncoder().encode(status)), status)
        XCTAssertEqual(ModelCapsuleAccessibilityMetadata.memoryValue(0), "未测量")
        XCTAssertEqual(ModelCapsuleAccessibilityMetadata.memoryValue(-1), "未测量")
        XCTAssertEqual(ModelCapsuleAccessibilityMetadata.speedValue(0), "未测量")
        XCTAssertEqual(ModelCapsuleAccessibilityMetadata.speedValue(.nan), "未测量")
        XCTAssertEqual(ModelCapsuleAccessibilityMetadata.speedValue(12.5), "12.5 tok/s")
        XCTAssertEqual(ModelCapsuleAccessibilityMetadata.memoryValue(1840), "1.8G")
    }

    func testNativeModelImportRequiresExplicitLicenseConfirmation() {
        let model = PinnedTextModel.model
        XCTAssertTrue(ModelImportLicensePolicy.requiresConfirmation(for: model))
        XCTAssertFalse(ModelImportLicensePolicy.permitsFileImporter(for: model, didConfirmLicense: false))
        XCTAssertTrue(ModelImportLicensePolicy.permitsFileImporter(for: model, didConfirmLicense: true))
        for model in ModelCatalog.defaultModels where model.id != PinnedTextModel.id {
            XCTAssertFalse(ModelImportLicensePolicy.requiresConfirmation(for: model))
            XCTAssertTrue(ModelImportLicensePolicy.permitsFileImporter(for: model, didConfirmLicense: false))
        }
        XCTAssertGreaterThanOrEqual(ModelImportLicensePolicy.minimumActionHeight, 44)
        XCTAssertEqual(ModelImportLicensePolicy.tokenizerDescription(for: model.artifactManifest), "GGUF 内嵌词表")
        XCTAssertTrue(ModelImportLicensePolicy.notice.contains("不会自动下载"))
        XCTAssertTrue(ModelImportLicensePolicy.boundary.contains("不会下载、加载模型或启动推理"))
    }

    func testNativeUTF8BufferPreservesSplitScalarsAndRejectsInvalidBytes() throws {
        let expected = "\u{4e2d}\u{1f642}\n"
        let bytes = Array(expected.utf8)
        for split in 0...bytes.count {
            var buffer = LlamaTextUTF8Buffer()
            var text = try buffer.append(Array(bytes.prefix(split)))
            text += try buffer.append(Array(bytes.dropFirst(split)))
            text += try buffer.finish()
            XCTAssertEqual(text, expected)
        }
        var incomplete = LlamaTextUTF8Buffer()
        XCTAssertEqual(try incomplete.append([0x41, 0xE4, 0xB8]), "A")
        XCTAssertThrowsError(try incomplete.finish())
        let invalidSequences: [[UInt8]] = [[0xFF], [0xC0, 0x80], [0xED, 0xA0], [0xF4, 0x90], [0x80]]
        for invalid in invalidSequences {
            var buffer = LlamaTextUTF8Buffer()
            XCTAssertThrowsError(try buffer.append(invalid))
        }
    }

    func testNativeMemoryAdmissionUsesAvailableHeadroomAndBoundedContext() throws {
        let required = try LlamaTextMemoryPolicy.requiredAvailableBytes(
            modelBytes: UInt64(PinnedTextModel.byteCount), contextLength: 4096
        )
        XCTAssertEqual(required, 1_046_716_992)
        XCTAssertNoThrow(try LlamaTextMemoryPolicy.validate(
            modelBytes: UInt64(PinnedTextModel.byteCount), contextLength: 4096, availableBytes: required
        ))
        XCTAssertThrowsError(try LlamaTextMemoryPolicy.validate(
            modelBytes: UInt64(PinnedTextModel.byteCount), contextLength: 4096, availableBytes: required - 1
        )) { error in
            XCTAssertEqual(error as? LlamaTextRuntimeError,
                           .insufficientMemory(requiredBytes: required, availableBytes: required - 1))
        }
        XCTAssertThrowsError(try LlamaTextMemoryPolicy.requiredAvailableBytes(modelBytes: UInt64.max, contextLength: 4096))
        XCTAssertThrowsError(try LlamaTextMemoryPolicy.requiredAvailableBytes(modelBytes: 1, contextLength: Int.max))
        XCTAssertNoThrow(try LlamaTextMemoryPolicy.validatePhysicalMemory(
            modelBytes: UInt64(PinnedTextModel.byteCount), contextLength: 4096, physicalBytes: required
        ))
        XCTAssertThrowsError(try LlamaTextMemoryPolicy.validatePhysicalMemory(
            modelBytes: UInt64(PinnedTextModel.byteCount), contextLength: 4096, physicalBytes: required - 1
        )) { error in
            XCTAssertEqual(error as? LlamaTextRuntimeError,
                           .insufficientPhysicalMemory(requiredBytes: required, physicalBytes: required - 1))
        }
    }

    func testNativeRateIncludesThePrefillThatComputesTheFirstToken() {
        let single = LlamaTextMetrics(promptTokens: 24, outputTokens: 1, loadSeconds: 10,
            prefillSeconds: 0.02, generationSeconds: 0.0005, finishReason: .outputLimit)
        XCTAssertEqual(single.tokensPerSecond, 1 / 0.0205, accuracy: 0.0001)
        XCTAssertLessThan(single.tokensPerSecond, 50, "Sampling-only time must not inflate short replies")
        let zeroClock = LlamaTextMetrics(promptTokens: 24, outputTokens: 1, loadSeconds: 10,
            prefillSeconds: 0, generationSeconds: 0, finishReason: .endOfGeneration)
        XCTAssertEqual(zeroClock.tokensPerSecond, 0)
    }

    func testLinkedNativeBackendRejectsBadGGUFAndActualHashMismatch() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("NativeFixture-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("invalid.gguf")
        let data = Data("GGUF-not-a-model-or-tokenizer".utf8)
        try data.write(to: file)
        let digest = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        for (hash, expected) in [(String(repeating: "0", count: 64), LlamaTextRuntimeError.hashMismatch),
                                 (digest, LlamaTextRuntimeError.modelLoadFailed)] {
            let request = LlamaTextRequest(modelURL: file, expectedSHA256: hash,
                                          messages: [LlamaTextMessage(role: "user", content: "Local fixture only")])
            do {
                for try await _ in LlamaTextRuntime().stream(request) {
                    XCTFail("Malformed or unverified files must never produce native output")
                }
                XCTFail("The real linked backend must reject this fixture")
            } catch {
                XCTAssertEqual(error as? LlamaTextRuntimeError, expected,
                               "backendUnavailable is not an acceptable substitute for exercising the native loader")
            }
        }
        XCTAssertEqual(try Data(contentsOf: file), data)
    }
}

private final class ControlledStreamingRuntime: LocalStreamingInferenceRuntime, @unchecked Sendable {
    private let lock = NSLock()
    private var storedRequests: [StreamingInferenceRequest] = []
    private var continuations: [AsyncThrowingStream<InferenceStreamEvent, Error>.Continuation] = []
    private let onRequest: @Sendable (Int) -> Void

    init(onRequest: @escaping @Sendable (Int) -> Void = { _ in }) {
        self.onRequest = onRequest
    }

    var requests: [StreamingInferenceRequest] { lock.withLock { storedRequests } }

    func supports(_ model: LocalModel) -> Bool { PinnedTextModel.supports(model) }

    func stream(_ request: StreamingInferenceRequest) -> AsyncThrowingStream<InferenceStreamEvent, Error> {
        AsyncThrowingStream { continuation in
            let index = lock.withLock {
                storedRequests.append(request)
                continuations.append(continuation)
                return storedRequests.count - 1
            }
            onRequest(index)
        }
    }

    func emit(_ event: InferenceStreamEvent, request: Int) {
        let continuation = lock.withLock { continuations.indices.contains(request) ? continuations[request] : nil }
        guard let continuation else { XCTFail("Expected a real streaming request before emitting a fixture event"); return }
        continuation.yield(event)
    }

    func finish(request: Int, error: Error? = nil) {
        let continuation = lock.withLock { continuations.indices.contains(request) ? continuations[request] : nil }
        guard let continuation else { XCTFail("Expected a real streaming request before finishing a fixture event"); return }
        if let error { continuation.finish(throwing: error) } else { continuation.finish() }
    }
}
