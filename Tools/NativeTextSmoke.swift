import Foundation

private struct NativeProbeFailure: Error, CustomStringConvertible {
    let description: String
}

private func require(_ condition: Bool, _ message: String) throws {
    if !condition { throw NativeProbeFailure(description: message) }
}

private struct NativeProbeResult {
    let text: String
    let metrics: LlamaTextMetrics
}

@main
@MainActor
struct NativeTextSmoke {
    static func main() async {
        let environment = ProcessInfo.processInfo.environment
        var report: [String: Any] = [
            "schemaVersion": 2, "source": "cloud-Catalyst-production-state-and-LlamaTextRuntime",
            "commitSha": environment["GITHUB_SHA"] ?? "", "runId": environment["GITHUB_RUN_ID"] ?? "",
            "runAttempt": environment["GITHUB_RUN_ATTEMPT"] ?? "",
            "modelSHA256": "3626e245220ca4a1c5911eb4010b3ecb7bdbf5bc53c79403c21355354d1e2dc6",
            "modelBytes": 241_410_624,
            "fixtureOnly": false, "productionModelVerified": false, "production1BModelVerified": false,
            "deviceMemoryOrMetalVerified": false, "signedDistributionVerified": false
        ]
        let output = URL(fileURLWithPath: environment["NATIVE_PROBE_OUTPUT"] ?? "/invalid/probe.json")
        do {
            try require(environment["GITHUB_ACTIONS"] == "true"
                        && environment["RUNNER_ENVIRONMENT"] == "github-hosted"
                        && environment["GITHUB_REPOSITORY"] == "Altman-sam114/113",
                        "Native execution is restricted to this repository's hosted runner")
            guard let path = environment["NATIVE_FIXTURE_PATH"] else {
                throw NativeProbeFailure(description: "The explicitly supplied local fixture is missing")
            }
            let url = URL(fileURLWithPath: path)
            let digest = report["modelSHA256"] as! String
            let firstMessages = [LlamaTextMessage(role: "user",
                content: "The secret word is ORCHID. Reply with that word only.")]
            let first = try await generate(url, digest: digest, messages: firstMessages)
            report["turns"] = [serialize(first)]
            try require(first.text.uppercased().contains("ORCHID"), "The real first answer did not follow the fixture instruction")
            let secondMessages = firstMessages + [
                LlamaTextMessage(role: "assistant", content: first.text),
                LlamaTextMessage(role: "user", content: "What is the secret word? Reply with the word only.")
            ]
            let second = try await generate(url, digest: digest, messages: secondMessages)
            report["turns"] = [serialize(first), serialize(second)]
            try require(second.text.uppercased().contains("ORCHID"), "The real second answer did not retain the conversation word")
            try require(second.metrics.promptTokens > first.metrics.promptTokens,
                        "The second request must tokenize the complete multi-turn conversation")

            let limited = try await generate(url, digest: digest,
                messages: [LlamaTextMessage(role: "user", content: "List the numbers from 1 to 20, one per line.")],
                maximumOutputTokens: 1)
            try require(limited.metrics.outputTokens == 1 && limited.metrics.finishReason == .outputLimit,
                        "A one-token limit must be reported as a length limit, not EOS")
            report["outputLimit"] = serialize(limited)

            let cancellation = Task<Void, Error> {
                let request = LlamaTextRequest(modelURL: url, expectedSHA256: digest,
                    messages: [LlamaTextMessage(role: "user", content: "Write a long story about a quiet garden.")],
                    contextLength: 1024, maximumOutputTokens: 256)
                for try await event in LlamaTextRuntime().stream(request) {
                    if case .text(let text) = event, !text.isEmpty {
                        withUnsafeCurrentTask { $0?.cancel() }
                        try Task.checkCancellation()
                    }
                }
                throw NativeProbeFailure(description: "Cancellation was never exercised after an actual native token")
            }
            do {
                try await cancellation.value
                throw NativeProbeFailure(description: "Native cancellation unexpectedly succeeded")
            } catch is CancellationError {
                report["cancelledAfterActualText"] = true
            }
            // Every call owns and frees its model/context. This request also waits
            // behind the cancelled worker, proving it releases the shared queue.
            let reloaded = try await generate(url, digest: digest, messages: firstMessages)
            try require(reloaded.text == first.text && reloaded.metrics.outputTokens == first.metrics.outputTokens,
                        "A new native request after cancellation must remain independent and deterministic")
            report["reloadAfterCancellation"] = serialize(reloaded)

            let oversized = LlamaTextRequest(modelURL: url, expectedSHA256: digest,
                messages: [LlamaTextMessage(role: "user", content: String(repeating: "context word ", count: 300))],
                contextLength: 128, maximumOutputTokens: 64)
            do {
                for try await _ in LlamaTextRuntime().stream(oversized) {}
                throw NativeProbeFailure(description: "Oversized context was silently accepted or truncated")
            } catch LlamaTextRuntimeError.contextBudgetExceeded(let input, let reserved, let capacity) {
                try require(input + reserved > capacity, "The actual tokenizer must establish the rejected budget")
                report["contextRejection"] = ["inputTokens": input, "outputReservation": reserved,
                                               "capacity": capacity, "silentlyTruncated": false]
            }
            report["productionFlow"] = try await NativeProductionSmoke.run(
                modelURL: url, directory: url.deletingLastPathComponent().appendingPathComponent("managed-production-models")
            )
            report["productionModelVerified"] = true
            report["status"] = "success"
        } catch {
            report["status"] = "failure"
            report["error"] = String(describing: error)
        }
        do {
            try FileManager.default.createDirectory(at: output.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys]).write(to: output, options: .atomic)
        } catch {
            print("Could not persist native probe evidence: \(error)")
            exit(1)
        }
        print("Native fixture probe: \(report["status"] ?? "failure")")
        if report["status"] as? String != "success" { exit(1) }
    }

    private static func generate(
        _ url: URL, digest: String, messages: [LlamaTextMessage], maximumOutputTokens: Int = 64
    ) async throws -> NativeProbeResult {
        var text = ""
        var completion: LlamaTextMetrics?
        let request = LlamaTextRequest(modelURL: url, expectedSHA256: digest, messages: messages,
                                      contextLength: 1024, maximumOutputTokens: maximumOutputTokens)
        for try await event in LlamaTextRuntime().stream(request) {
            try require(completion == nil, "No event may follow completion")
            switch event {
            case .text(let delta): text += delta
            case .completed(let metrics): completion = metrics
            }
        }
        guard let metrics = completion else { throw NativeProbeFailure(description: "Missing native completion") }
        try require(!text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    && metrics.promptTokens > 0 && metrics.outputTokens > 0
                    && metrics.outputTokens <= maximumOutputTokens && metrics.tokensPerSecond.isFinite
                    && metrics.tokensPerSecond > 0, "Native output and actual tokenizer metrics must be present")
        return NativeProbeResult(text: text, metrics: metrics)
    }

    private static func serialize(_ result: NativeProbeResult) -> [String: Any] {
        ["text": result.text, "promptTokens": result.metrics.promptTokens,
         "outputTokens": result.metrics.outputTokens, "tokensPerSecond": result.metrics.tokensPerSecond,
         "loadSeconds": result.metrics.loadSeconds, "prefillSeconds": result.metrics.prefillSeconds,
         "generationSeconds": result.metrics.generationSeconds,
         "finishReason": result.metrics.finishReason == .outputLimit ? "outputLimit" : "endOfGeneration"]
    }
}
