import CryptoKit
import Darwin
import Foundation

enum ArtifactImportError: Error, Equatable, LocalizedError {
    case emptySelection
    case missingRequiredFiles([String])
    case ambiguousSelection(String)
    case unsafeFile(String)
    case hashMismatch
    case operationInProgress

    var message: String {
        switch self {
        case .emptySelection:
            return "没有选择任何本地文件。"
        case .missingRequiredFiles(let names):
            return "缺少必需文件：\(names.joined(separator: ", "))。"
        case .ambiguousSelection(let name):
            return "同名文件重复：\(name)。"
        case .unsafeFile(let name):
            return "无法导入此文件：\(name)。"
        case .hashMismatch:
            return "SHA-256 不匹配，原文件未更改。"
        case .operationInProgress:
            return "请等待当前文件操作完成。"
        }
    }

    var errorDescription: String? { message }
}

struct ArtifactImportProgress: Equatable, Sendable {
    enum Phase: Int, Sendable, CaseIterable {
        case preparing, copying, validating, committing

        var title: String {
            switch self {
            case .preparing: return "准备导入"
            case .copying: return "正在复制"
            case .validating: return "正在校验"
            case .committing: return "正在完成"
            }
        }
    }

    var phase: Phase = .preparing
    var completedBytes: Int64 = 0
    var totalBytes: Int64 = 0

    var canCancel: Bool { phase != .committing }

    var fraction: Double? {
        guard totalBytes > 0 else { return nil }
        return min(max(Double(completedBytes) / Double(totalBytes), 0), 1)
    }
}

// Cancellation and the atomic commit share one gate. An accepted cancellation
// can never be followed by a successful replacement.
final class ArtifactImportControl: @unchecked Sendable {
    private enum State: Equatable { case active, cancelled, committing }
    private let lock = NSLock()
    private var state = State.active

    @discardableResult
    func cancel() -> Bool {
        lock.withLock {
            guard state == .active else { return false }
            state = .cancelled
            return true
        }
    }

    func checkCancellation() throws {
        try lock.withLock {
            if state == .cancelled { throw CancellationError() }
        }
    }

    func beginCommit() throws {
        try lock.withLock {
            if state == .cancelled { throw CancellationError() }
            state = .committing
        }
    }
}

enum ModelArtifactHasher {
    static func sha256Hex(for url: URL, fileManager: FileManager = .default) -> String? {
        try? hash(url, fileManager: fileManager, control: ArtifactImportControl())
    }

    static func hash(
        _ url: URL, fileManager: FileManager, control: ArtifactImportControl
    ) throws -> String {
        try control.checkCancellation()
        let values = try url.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey, .isRegularFileKey])
        guard values.isSymbolicLink != true else { throw ArtifactImportError.unsafeFile(url.lastPathComponent) }
        var hasher = SHA256()
        if values.isDirectory == true {
            var files: [URL] = []
            try collectFiles(in: url, fileManager: fileManager, control: control, into: &files)
            let base = url.standardizedFileURL.path + "/"
            for file in files.sorted(by: { $0.standardizedFileURL.path < $1.standardizedFileURL.path }) {
                let relative = String(file.standardizedFileURL.path.dropFirst(base.count))
                hasher.update(data: Data("path:\(relative)\n".utf8))
                try update(&hasher, file: file, control: control)
            }
        } else if values.isRegularFile == true {
            try update(&hasher, file: url, control: control)
        } else {
            throw ArtifactImportError.unsafeFile(url.lastPathComponent)
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }

    private static func collectFiles(
        in directory: URL, fileManager: FileManager, control: ArtifactImportControl, into files: inout [URL]
    ) throws {
        for child in try fileManager.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: [.isDirectoryKey, .isRegularFileKey, .isSymbolicLinkKey],
            options: [.skipsHiddenFiles]
        ) {
            try control.checkCancellation()
            let values = try child.resourceValues(forKeys: [.isDirectoryKey, .isRegularFileKey, .isSymbolicLinkKey])
            guard values.isSymbolicLink != true else { throw ArtifactImportError.unsafeFile(child.lastPathComponent) }
            if values.isDirectory == true {
                try collectFiles(in: child, fileManager: fileManager, control: control, into: &files)
            } else if values.isRegularFile == true {
                files.append(child)
            } else {
                throw ArtifactImportError.unsafeFile(child.lastPathComponent)
            }
        }
    }

    private static func update(
        _ hasher: inout SHA256, file: URL, control: ArtifactImportControl
    ) throws {
        let handle = try FileHandle(forReadingFrom: file)
        defer { try? handle.close() }
        while true {
            try control.checkCancellation()
            let chunk = try handle.read(upToCount: 1024 * 1024) ?? Data()
            if chunk.isEmpty { break }
            hasher.update(data: chunk)
        }
    }
}

struct ModelArtifactStore {
    static let localModelsDirectoryName = "LocalModels"
    private static let lock = NSRecursiveLock()

    static func defaultDirectoryURL(fileManager: FileManager = .default) -> URL {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        return base.appendingPathComponent(localModelsDirectoryName, isDirectory: true)
    }

    static func validate(
        manifest: ModelArtifactManifest, observedSHA256: String? = nil,
        fileManager: FileManager = .default
    ) -> ArtifactValidationResult {
        validate(manifest: manifest, directoryURL: defaultDirectoryURL(fileManager: fileManager),
                 observedSHA256: observedSHA256, fileManager: fileManager)
    }

    static func validate(
        manifest: ModelArtifactManifest, directoryURL: URL, observedSHA256: String? = nil,
        fileManager: FileManager = .default
    ) -> ArtifactValidationResult {
        lock.withLock {
            let statuses = manifest.requiredFiles.map { name in
                let url = directoryURL.appendingPathComponent(name)
                var isDirectory = ObjCBool(false)
                let exists = fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory)
                let attributes = exists ? try? fileManager.attributesOfItem(atPath: url.path) : nil
                return ArtifactFileStatus(fileName: name, exists: exists,
                    byteCount: (attributes?[.size] as? NSNumber)?.int64Value, isDirectory: isDirectory.boolValue)
            }
            let shouldHash = observedSHA256 == nil
                && LocalArtifactValidator.isConcreteSHA256(manifest.expectedSHA256.trimmingCharacters(in: .whitespacesAndNewlines))
                && statuses.allSatisfy(\.exists)
            let computed = shouldHash ? ModelArtifactHasher.sha256Hex(
                for: directoryURL.appendingPathComponent(manifest.modelFileName), fileManager: fileManager
            ) : nil
            return LocalArtifactValidator.validate(manifest: manifest, fileStatuses: statuses,
                                                   observedSHA256: observedSHA256 ?? computed)
        }
    }

    static func importArtifacts(
        manifest: ModelArtifactManifest, sourceURLs: [URL],
        destinationDirectoryURL: URL = defaultDirectoryURL(), fileManager: FileManager = .default,
        control: ArtifactImportControl = ArtifactImportControl(),
        progress: @Sendable (ArtifactImportProgress) -> Void = { _ in }
    ) throws -> ArtifactValidationResult {
        try lock.withLock {
            try checkNames(manifest)
            guard !sourceURLs.isEmpty else { throw ArtifactImportError.emptySelection }
            let sources = Dictionary(grouping: sourceURLs, by: \.lastPathComponent)
            let missing = manifest.requiredFiles.filter { sources[$0]?.first == nil }
            guard missing.isEmpty else { throw ArtifactImportError.missingRequiredFiles(missing) }
            for name in manifest.requiredFiles where sources[name]?.count != 1 {
                throw ArtifactImportError.ambiguousSelection(name)
            }
            let scoped = sourceURLs.filter { $0.startAccessingSecurityScopedResource() }
            defer { scoped.forEach { $0.stopAccessingSecurityScopedResource() } }
            progress(ArtifactImportProgress())
            try control.checkCancellation()
            let selected = manifest.requiredFiles.compactMap { sources[$0]?.first }
            var total: Int64 = 0
            for source in selected {
                total += try byteCount(source, fileManager: fileManager, control: control)
            }
            let stage = try snapshot(destinationDirectoryURL, excluding: Set(manifest.requiredFiles),
                                     fileManager: fileManager, control: control)
            // Only our private candidate/obsolete generation is cleaned up, never a Files source.
            defer { try? fileManager.removeItem(at: stage) }
            var event = ArtifactImportProgress(phase: .copying, totalBytes: total)
            progress(event)
            var lastPercent = -1
            for source in selected {
                try copy(source, to: stage.appendingPathComponent(source.lastPathComponent),
                         fileManager: fileManager, control: control) { count in
                    event.completedBytes += count
                    let percent = Int((event.fraction ?? 0) * 100)
                    if percent != lastPercent {
                        progress(event)
                        lastPercent = percent
                    }
                }
            }
            progress(ArtifactImportProgress(phase: .validating))
            try control.checkCancellation()
            let hash = LocalArtifactValidator.isConcreteSHA256(manifest.expectedSHA256.trimmingCharacters(in: .whitespacesAndNewlines))
                ? try ModelArtifactHasher.hash(stage.appendingPathComponent(manifest.modelFileName),
                                              fileManager: fileManager, control: control) : nil
            let result = validate(manifest: manifest, directoryURL: stage,
                                  observedSHA256: hash, fileManager: fileManager)
            guard result.hasRequiredFiles else { throw ArtifactImportError.missingRequiredFiles(result.missingFiles) }
            if result.hasConcreteExpectedHash && !result.hasVerifiedHash { throw ArtifactImportError.hashMismatch }
            try control.beginCommit()
            progress(ArtifactImportProgress(phase: .committing))
            try commit(stage, to: destinationDirectoryURL, fileManager: fileManager)
            return result
        }
    }

    static func removeArtifacts(
        manifest: ModelArtifactManifest, destinationDirectoryURL: URL = defaultDirectoryURL(),
        fileManager: FileManager = .default
    ) throws -> ArtifactValidationResult {
        try lock.withLock {
            try checkNames(manifest)
            if fileManager.fileExists(atPath: destinationDirectoryURL.path) {
                let stage = try snapshot(destinationDirectoryURL, excluding: Set(manifest.requiredFiles),
                                         fileManager: fileManager, control: ArtifactImportControl())
                defer { try? fileManager.removeItem(at: stage) }
                try commit(stage, to: destinationDirectoryURL, fileManager: fileManager)
            }
            return LocalArtifactValidator.validate(manifest: manifest, presentFiles: [])
        }
    }

    private static func checkNames(_ manifest: ModelArtifactManifest) throws {
        for name in manifest.requiredFiles {
            guard !name.isEmpty, name != ".", name != "..", !name.contains("/"),
                  !name.contains("\\"), !name.contains("\0") else { throw ArtifactImportError.unsafeFile(name) }
        }
        guard Set(manifest.requiredFiles).count == manifest.requiredFiles.count else {
            throw ArtifactImportError.ambiguousSelection(manifest.modelFileName)
        }
    }

    private static func byteCount(
        _ url: URL, fileManager: FileManager, control: ArtifactImportControl
    ) throws -> Int64 {
        try control.checkCancellation()
        let values = try url.resourceValues(forKeys: [.isDirectoryKey, .isRegularFileKey, .isSymbolicLinkKey, .fileSizeKey])
        guard values.isSymbolicLink != true else { throw ArtifactImportError.unsafeFile(url.lastPathComponent) }
        if values.isDirectory == true {
            return try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
                .reduce(Int64(0)) { try $0 + byteCount($1, fileManager: fileManager, control: control) }
        }
        guard values.isRegularFile == true else { throw ArtifactImportError.unsafeFile(url.lastPathComponent) }
        return Int64(values.fileSize ?? 0)
    }

    private static func copy(
        _ source: URL, to destination: URL, fileManager: FileManager, control: ArtifactImportControl,
        copied: (Int64) -> Void
    ) throws {
        try control.checkCancellation()
        let values = try source.resourceValues(forKeys: [.isDirectoryKey, .isRegularFileKey, .isSymbolicLinkKey])
        guard values.isSymbolicLink != true else { throw ArtifactImportError.unsafeFile(source.lastPathComponent) }
        if values.isDirectory == true {
            try fileManager.createDirectory(at: destination, withIntermediateDirectories: false)
            for child in try fileManager.contentsOfDirectory(at: source, includingPropertiesForKeys: nil) {
                try copy(child, to: destination.appendingPathComponent(child.lastPathComponent),
                         fileManager: fileManager, control: control, copied: copied)
            }
        } else if values.isRegularFile == true {
            guard fileManager.createFile(atPath: destination.path, contents: nil) else {
                throw CocoaError(.fileWriteUnknown)
            }
            let input = try FileHandle(forReadingFrom: source)
            defer { try? input.close() }
            let output = try FileHandle(forWritingTo: destination)
            defer { try? output.close() }
            while true {
                try control.checkCancellation()
                let chunk = try input.read(upToCount: 1024 * 1024) ?? Data()
                if chunk.isEmpty { break }
                try output.write(contentsOf: chunk)
                copied(Int64(chunk.count))
            }
            try output.synchronize()
        } else {
            throw ArtifactImportError.unsafeFile(source.lastPathComponent)
        }
    }

    private static func snapshot(
        _ destination: URL, excluding names: Set<String>, fileManager: FileManager,
        control: ArtifactImportControl
    ) throws -> URL {
        let parent = destination.deletingLastPathComponent()
        try fileManager.createDirectory(at: parent, withIntermediateDirectories: true)
        let stage = parent.appendingPathComponent(".\(destination.lastPathComponent)-import-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: stage, withIntermediateDirectories: false)
        do {
            if fileManager.fileExists(atPath: destination.path) {
                let values = try destination.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
                guard values.isDirectory == true, values.isSymbolicLink != true else {
                    throw ArtifactImportError.unsafeFile(destination.lastPathComponent)
                }
                for child in try fileManager.contentsOfDirectory(at: destination, includingPropertiesForKeys: nil)
                    where !names.contains(child.lastPathComponent) {
                    try linkUnchanged(child, to: stage.appendingPathComponent(child.lastPathComponent),
                                      fileManager: fileManager, control: control)
                }
            }
            return stage
        } catch {
            try? fileManager.removeItem(at: stage)
            throw error
        }
    }

    // Unchanged artifacts are immutable during a store operation. Hard links
    // preserve other models without recopying their potentially large weights.
    private static func linkUnchanged(
        _ source: URL, to destination: URL, fileManager: FileManager, control: ArtifactImportControl
    ) throws {
        try control.checkCancellation()
        let values = try source.resourceValues(forKeys: [.isDirectoryKey, .isRegularFileKey, .isSymbolicLinkKey])
        guard values.isSymbolicLink != true else { throw ArtifactImportError.unsafeFile(source.lastPathComponent) }
        if values.isDirectory == true {
            try fileManager.createDirectory(at: destination, withIntermediateDirectories: false)
            for child in try fileManager.contentsOfDirectory(at: source, includingPropertiesForKeys: nil) {
                try linkUnchanged(child, to: destination.appendingPathComponent(child.lastPathComponent),
                                  fileManager: fileManager, control: control)
            }
        } else if values.isRegularFile == true {
            try fileManager.linkItem(at: source, to: destination)
        } else {
            throw ArtifactImportError.unsafeFile(source.lastPathComponent)
        }
    }

    private static func commit(_ candidate: URL, to destination: URL, fileManager: FileManager) throws {
        // Both directories are siblings on the same volume. There is no
        // delete-then-move fallback: an unsupported/failed swap keeps the old set.
        let flags = fileManager.fileExists(atPath: destination.path) ? UInt32(RENAME_SWAP) : UInt32(RENAME_EXCL)
        let result = candidate.path.withCString { sourcePath in
            destination.path.withCString { targetPath in renamex_np(sourcePath, targetPath, flags) }
        }
        if result != 0 { throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }
    }
}

// FileManager is not Sendable in every target SDK. Keep this one instance
// behind a lock; only the worker can borrow it for a complete store operation.
final class ArtifactFileAccess: @unchecked Sendable {
    private let manager: FileManager
    private let lock = NSLock()

    init(_ manager: FileManager) { self.manager = manager }

    fileprivate func perform<T>(_ operation: (FileManager) throws -> T) rethrows -> T {
        try lock.withLock { try operation(manager) }
    }
}

actor ArtifactIOWorker {
    static let shared = ArtifactIOWorker()

    func importArtifacts(
        manifest: ModelArtifactManifest, sources: [URL], destination: URL, fileAccess: ArtifactFileAccess,
        control: ArtifactImportControl, progress: @Sendable (ArtifactImportProgress) -> Void
    ) throws -> ArtifactValidationResult {
        try fileAccess.perform { manager in
            try ModelArtifactStore.importArtifacts(manifest: manifest, sourceURLs: sources,
                destinationDirectoryURL: destination, fileManager: manager, control: control, progress: progress)
        }
    }

    func validate(model: LocalModel, directory: URL, fileAccess: ArtifactFileAccess) -> ArtifactValidationResult {
        fileAccess.perform { manager in
            ModelArtifactStore.validate(manifest: model.artifactManifest, directoryURL: directory, fileManager: manager)
        }
    }

    func remove(model: LocalModel, directory: URL, fileAccess: ArtifactFileAccess) throws -> ArtifactValidationResult {
        try fileAccess.perform { manager in
            try ModelArtifactStore.removeArtifacts(manifest: model.artifactManifest,
                                                   destinationDirectoryURL: directory, fileManager: manager)
        }
    }
}

struct ArtifactOperation: Identifiable, Sendable {
    enum Kind: Equatable, Sendable { case importing, scanning, uninstalling }
    let id = UUID()
    let modelID: UUID
    let modelName: String
    let kind: Kind
    var progress = ArtifactImportProgress()

    var canCancel: Bool { kind == .importing && progress.canCancel }

    var title: String {
        switch kind {
        case .importing:
            if progress.phase == .copying, let fraction = progress.fraction {
                return "正在复制 \(Int(fraction * 100))%"
            }
            return progress.phase.title
        case .scanning: return "正在扫描"
        case .uninstalling: return "正在卸载"
        }
    }
}
