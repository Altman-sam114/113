import Foundation
import ImageIO
import Vision

// This command is compiled and run only by the cloud screenshot collector.
guard ProcessInfo.processInfo.environment["GITHUB_ACTIONS"] == "true",
      CommandLine.arguments.count == 3 else {
    fatalError("Cloud screenshot validation requires an image path and page marker")
}

func normalized(_ text: String) -> String {
    let canonical = text.replacingOccurrences(of: "點", with: "点")
        .replacingOccurrences(of: "麼", with: "么")
        .replacingOccurrences(of: "導", with: "导")
        .replacingOccurrences(of: "觀", with: "观")
    return String(canonical.uppercased().filter { $0.isLetter || $0.isNumber })
}

do {
    let url = URL(fileURLWithPath: CommandLine.arguments[1])
    let marker = CommandLine.arguments[2]
    let needsChinese = marker.contains { !$0.isASCII }
    let languageSets = needsChinese ? [["zh-Hans"], ["en-US"]] : [["en-US"]]
    var passes: [[String: Any]] = []
    var texts: [String] = []
    for languages in languageSets {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = languages
        request.usesLanguageCorrection = languages.contains("zh-Hans")
        try VNImageRequestHandler(url: url).perform([request])
        let text = (request.results ?? [])
            .compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: "\n")
        passes.append(["languages": languages, "recognizedText": text])
        texts.append(text)
        if normalized(text).contains(normalized(marker)) { break }
    }
    let recognized = texts.joined(separator: "\n")
    let matched = normalized(recognized).contains(normalized(marker))
    let document: [String: Any] = [
        "requiredTextMarker": marker,
        "recognizedText": recognized,
        "recognitionPasses": passes,
        "pageContentValidated": matched
    ]
    let data = try JSONSerialization.data(withJSONObject: document, options: [.sortedKeys])
    print(String(decoding: data, as: UTF8.self))
    if !matched { exit(1) }
} catch {
    fputs("Screenshot content validation failed: \(error)\n", stderr)
    exit(1)
}
