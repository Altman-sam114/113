import Foundation

struct ConversationArchive: Codable, Equatable, Sendable {
    static let currentVersion = 1
    static let maximumBytes = 32 * 1024 * 1024

    var version = currentVersion
    var sessions: [ChatSession]
    var activeSessionID: UUID
    var drafts: [UUID: String]

    func validate() throws {
        guard version == Self.currentVersion else { throw ConversationStoreError.unsupportedVersion }
        let ids = Set(sessions.map(\.id))
        guard !sessions.isEmpty, ids.count == sessions.count, ids.contains(activeSessionID),
              Set(drafts.keys).isSubset(of: ids) else { throw ConversationStoreError.invalidArchive }
        for session in sessions {
            guard Set(session.messages.map(\.id)).count == session.messages.count,
                  session.createdAt.timeIntervalSinceReferenceDate.isFinite,
                  session.updatedAt.timeIntervalSinceReferenceDate.isFinite,
                  session.messages.allSatisfy({ $0.timestamp.timeIntervalSinceReferenceDate.isFinite && $0.tokens >= 0 })
            else { throw ConversationStoreError.invalidArchive }
        }
    }
}

enum ConversationStoreError: Error {
    case unsupportedVersion, invalidArchive, archiveTooLarge, readBeforeWriteRequired
}

enum ConversationPersistenceState: Equatable, Sendable {
    case memoryOnly, loading, saving, saved, readFailed, writeFailed, repairing

    var blocksEditing: Bool { self == .loading || self == .repairing }
}

protocol ConversationStorage: Sendable {
    func load() async throws -> ConversationArchive?
    func save(_ archive: ConversationArchive) async throws
    func repair(with archive: ConversationArchive) async throws
}

actor LocalConversationStore: ConversationStorage {
    typealias AtomicWriter = @Sendable (Data, URL) throws -> Void

    static let shared = LocalConversationStore(fileURL: defaultFileURL())
    private let fileURL: URL
    private let writer: AtomicWriter
    private var writesAllowed = false

    init(fileURL: URL, writer: AtomicWriter? = nil) {
        self.fileURL = fileURL
        self.writer = writer ?? Self.writeAtomically
    }

    static func defaultFileURL() -> URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return support.appendingPathComponent("Conversations", isDirectory: true).appendingPathComponent("history-v1.json")
    }

    func load() throws -> ConversationArchive? {
        writesAllowed = false
        guard let attributes = try attributesIfPresent() else {
            writesAllowed = true
            return nil
        }
        guard attributes[.type] as? FileAttributeType == .typeRegular else {
            throw ConversationStoreError.invalidArchive
        }
        guard let bytes = attributes[.size] as? NSNumber,
              bytes.int64Value <= Int64(ConversationArchive.maximumBytes) else {
            throw ConversationStoreError.archiveTooLarge
        }
        let data = try Data(contentsOf: fileURL)
        guard data.count <= ConversationArchive.maximumBytes else { throw ConversationStoreError.archiveTooLarge }
        let archive = try JSONDecoder().decode(ConversationArchive.self, from: data)
        try archive.validate()
        writesAllowed = true
        return archive
    }

    func save(_ archive: ConversationArchive) throws {
        guard writesAllowed else { throw ConversationStoreError.readBeforeWriteRequired }
        try persist(archive)
    }

    func repair(with archive: ConversationArchive) throws {
        // An unreadable/newer archive is never silently replaced by the seed.
        // Explicit repair first preserves its exact original bytes under a new name.
        _ = try encoded(archive)
        if try attributesIfPresent() != nil {
            let backup = fileURL.deletingLastPathComponent()
                .appendingPathComponent("unreadable-\(UUID().uuidString).json")
            try FileManager.default.copyItem(at: fileURL, to: backup)
        }
        try persist(archive)
        writesAllowed = true
    }

    private func attributesIfPresent() throws -> [FileAttributeKey: Any]? {
        // fileExists also returns false for access failures; those must never
        // authorize replacing a history file that could not actually be read.
        do {
            return try FileManager.default.attributesOfItem(atPath: fileURL.path)
        } catch let error as CocoaError where error.code == .fileNoSuchFile || error.code == .fileReadNoSuchFile {
            return nil
        }
    }

    private func persist(_ archive: ConversationArchive) throws {
        let data = try encoded(archive)
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try writer(data, fileURL)
    }

    private func encoded(_ archive: ConversationArchive) throws -> Data {
        try archive.validate()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(archive)
        guard data.count <= ConversationArchive.maximumBytes else { throw ConversationStoreError.archiveTooLarge }
        return data
    }

    private static func writeAtomically(_ data: Data, _ destination: URL) throws {
        #if os(iOS) && !targetEnvironment(macCatalyst)
        try data.write(to: destination, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        #else
        try data.write(to: destination, options: .atomic)
        #endif
    }
}
