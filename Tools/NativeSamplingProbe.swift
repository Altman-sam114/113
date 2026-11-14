import CryptoKit
import Foundation
@preconcurrency import llama

private struct SamplingFailure: Error, CustomStringConvertible {
    let description: String
}

private func require(_ condition: Bool, _ message: String) throws {
    if !condition { throw SamplingFailure(description: message) }
}

private struct SamplingProfile: Decodable {
    let id: String
    let mode: String
    let seed: UInt32?
    let temperature: Float?
    let topK: Int32?
    let topP: Float?
    let minP: Float?
}

private struct SamplingProfiles: Decodable {
    let profiles: [SamplingProfile]
}

private func selectedProfile() throws -> SamplingProfile {
    let environment = ProcessInfo.processInfo.environment
    guard let path = environment["SAMPLING_PROFILES_PATH"], let id = environment["SAMPLING_PROFILE_ID"] else {
        throw SamplingFailure(description: "The frozen sampling profile is missing")
    }
    let profiles = try JSONDecoder().decode(SamplingProfiles.self, from: Data(contentsOf: URL(fileURLWithPath: path)))
    let matches = profiles.profiles.filter { $0.id == id }
    try require(matches.count == 1, "The sampling profile is missing or ambiguous")
    return matches[0]
}

// Used only by a SHA-checked diagnostic copy; never compiled into the app target.
enum NativeSamplingFactory {
    static func makeSampler() throws -> UnsafeMutablePointer<llama_sampler>? {
        let profile = try selectedProfile()
        if profile.mode == "greedy" { return llama_sampler_init_greedy() }
        guard profile.mode == "sampled", let seed = profile.seed,
              let temperature = profile.temperature, let topK = profile.topK,
              let topP = profile.topP, let minP = profile.minP else {
            throw SamplingFailure(description: "Incomplete experimental sampler")
        }
        guard let chain = llama_sampler_chain_init(llama_sampler_chain_default_params()) else { return nil }
        func append(_ member: UnsafeMutablePointer<llama_sampler>?) throws {
            guard let member else { throw SamplingFailure(description: "Sampler allocation failed") }
            llama_sampler_chain_add(chain, member)
        }
        do {
            try append(llama_sampler_init_top_k(topK))
            try append(llama_sampler_init_top_p(topP, 1))
            try append(llama_sampler_init_min_p(minP, 1))
            try append(llama_sampler_init_temp(temperature))
            try append(llama_sampler_init_dist(seed))
            return chain
        } catch {
            llama_sampler_free(chain)
            throw error
        }
    }
}

private struct SamplingTask: Decodable {
    let id: String
    let templateID: String?
    let input: String
    let expectedTemplatePrompt: String
}

private struct SamplingTasks: Decodable {
    let cases: [SamplingTask]
}

@main
@MainActor
struct NativeSamplingProbe {
    static func main() async {
        let environment = ProcessInfo.processInfo.environment
        var report: [String: Any] = [
            "schemaVersion": 1, "source": "cloud-Catalyst-isolated-sampling-diagnostic",
            "commitSha": environment["GITHUB_SHA"] ?? "", "runId": environment["GITHUB_RUN_ID"] ?? "",
            "runAttempt": environment["GITHUB_RUN_ATTEMPT"] ?? "",
            "profileID": environment["SAMPLING_PROFILE_ID"] ?? "",
            "modelSHA256": "3626e245220ca4a1c5911eb4010b3ecb7bdbf5bc53c79403c21355354d1e2dc6",
            "modelBytes": 241_410_624, "contextLength": 4096, "maximumOutputTokens": 512,
            "productionDefaultChanged": false, "productionStateFlowVerified": false,
            "deviceMemoryOrMetalVerified": false, "generalTaskQualityVerified": false,
            "manualReviewRequired": true
        ]
        let output = URL(fileURLWithPath: environment["SAMPLING_OUTPUT"] ?? "/invalid/sampling.json")
        var records: [[String: Any]] = []
        func save() throws {
            report["cases"] = records
            try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
                .write(to: output, options: .atomic)
        }
        do {
            try require(environment["GITHUB_ACTIONS"] == "true"
                        && environment["RUNNER_ENVIRONMENT"] == "github-hosted"
                        && environment["RUNNER_OS"] == "macOS"
                        && environment["GITHUB_REPOSITORY"] == "Altman-sam114/113",
                        "Execution requires this repository's hosted macOS runner")
            guard let path = environment["NATIVE_FIXTURE_PATH"], let casesPath = environment["SAMPLING_CASES_PATH"],
                  let profilesPath = environment["SAMPLING_PROFILES_PATH"] else {
                throw SamplingFailure(description: "Diagnostic inputs are missing")
            }
            _ = try selectedProfile()
            let data = try Data(contentsOf: URL(fileURLWithPath: casesPath))
            let tasks = try JSONDecoder().decode(SamplingTasks.self, from: data)
            report["casesSHA256"] = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
            report["profilesSHA256"] = SHA256.hash(data: Data(contentsOf: URL(fileURLWithPath: profilesPath)))
                .map { String(format: "%02x", $0) }.joined()
            report["status"] = "running"
            for task in tasks.cases {
                let prompt = task.expectedTemplatePrompt + task.input
                let start = Date()
                var text = ""
                var metrics: LlamaTextMetrics?
                var failure = ""
                do {
                    let request = LlamaTextRequest(modelURL: URL(fileURLWithPath: path),
                        expectedSHA256: report["modelSHA256"] as! String,
                        messages: [LlamaTextMessage(role: "user", content: prompt)],
                        contextLength: 4096, maximumOutputTokens: 512)
                    for try await event in LlamaTextRuntime().stream(request) {
                        switch event {
                        case .text(let delta): text += delta
                        case .completed(let value):
                            try require(metrics == nil, "Duplicate native completion")
                            metrics = value
                        }
                    }
                    try require(metrics != nil, "No native completion was received")
                } catch { failure = String(describing: error) }
                records.append([
                    "id": task.id, "templateID": task.templateID ?? "", "prompt": prompt,
                    "text": text, "error": failure, "runtimeSucceeded": failure.isEmpty && metrics != nil,
                    "backend": "llamaCpp", "simulated": false,
                    "promptTokens": metrics?.promptTokens ?? 0, "outputTokens": metrics?.outputTokens ?? 0,
                    "tokensPerSecond": metrics?.tokensPerSecond ?? 0,
                    "loadSeconds": metrics?.loadSeconds ?? 0, "prefillSeconds": metrics?.prefillSeconds ?? 0,
                    "generationSeconds": metrics?.generationSeconds ?? 0,
                    "elapsedSeconds": Date().timeIntervalSince(start),
                    "finishReason": metrics.map { $0.finishReason == .endOfGeneration ? "endOfGeneration" : "outputLimit" } ?? "error"
                ])
                try save() // Preserve completed tasks even if a subsequent task fails or times out.
                print("Collected \(environment["SAMPLING_PROFILE_ID"] ?? "") / \(task.id)")
            }
            report["status"] = "collected"
        } catch {
            report["status"] = "failure"
            report["error"] = String(describing: error)
        }
        do { try save() } catch { print("Could not persist sampling evidence"); exit(1) }
        if report["status"] as? String != "collected" { exit(1) }
    }
}
