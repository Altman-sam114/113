import Foundation
import ImageIO
import Vision

// This command is compiled and run only by the cloud screenshot collector.
guard ProcessInfo.processInfo.environment["GITHUB_ACTIONS"] == "true",
      CommandLine.arguments.count == 3 else {
    fatalError("Cloud screenshot validation requires an image path and page marker")
}

func normalized(_ text: String) -> String {
    String(text.uppercased().filter { $0.isLetter || $0.isNumber })
}

do {
    let url = URL(fileURLWithPath: CommandLine.arguments[1])
    let marker = CommandLine.arguments[2]
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.recognitionLanguages = ["en-US", "zh-Hans"]
    request.usesLanguageCorrection = false
    try VNImageRequestHandler(url: url).perform([request])
    let recognized = (request.results ?? [])
        .compactMap { $0.topCandidates(1).first?.string }
        .joined(separator: "\n")
    let matched = normalized(recognized).contains(normalized(marker))
    let document: [String: Any] = [
        "requiredTextMarker": marker,
        "recognizedText": recognized,
        "pageContentValidated": matched
    ]
    let data = try JSONSerialization.data(withJSONObject: document, options: [.sortedKeys])
    print(String(decoding: data, as: UTF8.self))
    if !matched { exit(1) }
} catch {
    fputs("Screenshot content validation failed: \(error)\n", stderr)
    exit(1)
}
