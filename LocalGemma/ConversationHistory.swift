import SwiftUI
import UIKit

enum ConversationHistoryPolicy {
    static func matches(_ session: ChatSession, query: String) -> Bool {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty || session.title.localizedStandardContains(query) { return true }
        guard let firstUser = session.messages.firstIndex(where: { $0.role == .user }) else { return false }
        return session.messages[firstUser...].contains { $0.role != .system && $0.text.localizedStandardContains(query) }
    }

    static func preview(_ session: ChatSession) -> String? {
        guard let firstUser = session.messages.firstIndex(where: { $0.role == .user }) else { return nil }
        for message in session.messages[firstUser...].reversed() where message.role != .system {
            let text = message.text.split(whereSeparator: \.isWhitespace).joined(separator: " ")
            if !text.isEmpty { return String(text.prefix(80)) }
        }
        return nil
    }
}

struct CompactSessionHistory: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var pendingDeletion: ChatSession?

    let sessions: [ChatSession]
    let activeSessionID: UUID
    var persistenceState: ConversationPersistenceState = .memoryOnly
    let select: (ChatSession) -> Void
    let delete: (ChatSession) -> Void
    let create: () -> Void
    var retrySave: () -> Void = {}
    var repair: () -> Void = {}

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ConversationPersistenceNotice(state: persistenceState, retry: retrySave, repair: repair)
                    .padding(.horizontal, 18)
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18))
                        .foregroundStyle(theme.secondaryText)
                        .accessibilityHidden(true)
                    TextField("搜索对话", text: $query)
                        .font(.body)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .foregroundStyle(theme.primaryText)
                        .accessibilityLabel("搜索对话")
                        .accessibilityHint("仅搜索本机对话标题和正文，不会联网。")
                        .accessibilityIdentifier("conversation-history-search")
                    if !query.isEmpty {
                        Button { query = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .frame(width: 44, height: 44)
                        }
                        .foregroundStyle(theme.secondaryText)
                        .accessibilityLabel("清除搜索")
                    }
                }
                .padding(.leading, 14)
                .padding(.trailing, 4)
                .padding(.vertical, 6)
                .frame(minHeight: 48)
                .background(theme.surface, in: RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 12)

                ScrollView {
                    let filtered = sessions.filter { ConversationHistoryPolicy.matches($0, query: query) }
                    LazyVStack(spacing: 8) {
                        if filtered.isEmpty {
                            Label("没有匹配的对话", systemImage: "text.magnifyingglass")
                                .font(.subheadline)
                                .foregroundStyle(theme.secondaryText)
                                .frame(maxWidth: .infinity, minHeight: 100)
                                .accessibilityIdentifier("conversation-history-no-results")
                        }
                        ForEach(filtered) { session in
                            ConversationHistoryRow(session: session, isActive: session.id == activeSessionID,
                                select: { select(session) }, delete: { pendingDeletion = session })
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 18)
                }
                .scrollDismissesKeyboard(.interactively)
                .disabled(persistenceState.blocksEditing)
            }
            .background(theme.canvas)
            .navigationTitle("会话记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: create) {
                        Image(systemName: "square.and.pencil").frame(width: 44, height: 44)
                    }
                    .disabled(persistenceState.blocksEditing)
                    .accessibilityLabel(SessionBarActionAccessibilityMetadata.label(for: .createSession))
                    .accessibilityHint(SessionBarActionAccessibilityMetadata.hint(for: .createSession))
                    .accessibilityInputLabels(SessionBarActionAccessibilityMetadata.inputLabels(for: .createSession))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("关闭会话记录")
                }
            }
            .confirmationDialog("删除这条对话？", isPresented: Binding(
                get: { pendingDeletion != nil }, set: { if !$0 { pendingDeletion = nil } }
            ), titleVisibility: .visible, presenting: pendingDeletion) { session in
                Button("删除对话", role: .destructive) {
                    delete(session)
                    pendingDeletion = nil
                }
                Button("取消", role: .cancel) { pendingDeletion = nil }
            } message: { session in Text(session.title) }
        }
        .tint(theme.accent)
    }
}

struct ConversationHistoryRow: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let session: ChatSession
    let isActive: Bool
    let select: () -> Void
    let delete: () -> Void

    var body: some View {
        let canDelete = SessionChipActionAccessibilityMetadata.canDelete(session: session, isActive: isActive)
        HStack(spacing: 4) {
            Button(action: select) {
                HStack(alignment: .top, spacing: 12) {
                    if dynamicTypeSize < .xxxLarge {
                        Image(systemName: isActive ? "bubble.left.fill" : "bubble.left")
                            .font(.body.weight(.medium))
                            .foregroundStyle(isActive ? theme.accent : theme.secondaryText)
                            .padding(.top, 2)
                            .accessibilityHidden(true)
                    }
                    VStack(alignment: .leading, spacing: 5) {
                        Text(session.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(theme.primaryText)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                        if let preview = ConversationHistoryPolicy.preview(session) {
                            Text(preview)
                                .font(.footnote)
                                .foregroundStyle(theme.secondaryText)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    if isActive {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(theme.accent)
                            .padding(.top, 3)
                            .accessibilityHidden(true)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                .padding(.leading, 14)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(SessionChipActionAccessibilityMetadata.label(for: .select, session: session))
            .accessibilityValue(SessionChipActionAccessibilityMetadata.value(for: .select, session: session, isActive: isActive, canDelete: canDelete))
            .accessibilityHint(SessionChipActionAccessibilityMetadata.hint(for: .select, session: session, isActive: isActive, canDelete: canDelete))
            .accessibilityInputLabels(SessionChipActionAccessibilityMetadata.inputLabels(for: .select, session: session))
            .accessibilityIdentifier(SessionChipActionAccessibilityMetadata.identifier(for: .select, session: session))
            .accessibilityAddTraits(isActive ? .isSelected : [])

            Button(action: delete) {
                Image(systemName: "trash").font(.system(size: 16)).foregroundStyle(theme.secondaryText)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .disabled(!canDelete)
            .opacity(canDelete ? 1 : 0.3)
            .accessibilityLabel(SessionChipActionAccessibilityMetadata.label(for: .delete, session: session))
            .accessibilityValue(SessionChipActionAccessibilityMetadata.value(for: .delete, session: session, isActive: isActive, canDelete: canDelete))
            .accessibilityHint("打开删除确认。确认后只删除本机对话和草稿，不删除模型文件。")
            .accessibilityInputLabels(SessionChipActionAccessibilityMetadata.inputLabels(for: .delete, session: session))
            .accessibilityIdentifier(SessionChipActionAccessibilityMetadata.identifier(for: .delete, session: session))
        }
        .padding(.trailing, 6)
        .background(isActive ? theme.accent.opacity(theme.isDark ? 0.1 : 0.06) : theme.surface,
                    in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16).stroke(isActive ? theme.accent.opacity(0.25) : theme.subtleBorder, lineWidth: 0.5)
                .allowsHitTesting(false).accessibilityHidden(true)
        }
    }
}

struct ConversationPersistenceNotice: View {
    let state: ConversationPersistenceState
    let retry: () -> Void
    let repair: () -> Void
    @Environment(\.appTheme) private var theme
    @State private var confirmsRepair = false

    var body: some View {
        Group {
            if state.blocksEditing {
                HStack(spacing: 10) {
                    ProgressView().tint(theme.accent)
                    Text(state == .repairing ? "正在修复" : "正在恢复")
                        .font(.footnote).foregroundStyle(theme.secondaryText)
                    Spacer(minLength: 0)
                }
                .frame(minHeight: 44)
            } else if state == .readFailed || state == .writeFailed {
                HStack(spacing: 8) {
                    Label(state == .readFailed ? "记录无法读取" : "记录尚未保存", systemImage: "exclamationmark.circle")
                        .font(.footnote).foregroundStyle(theme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    Button(state == .readFailed ? "修复" : "重试") {
                        if state == .readFailed { confirmsRepair = true } else { retry() }
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(theme.accent)
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityIdentifier("conversation-save-retry")
                }
            }
        }
        .confirmationDialog("修复会话记录？", isPresented: $confirmsRepair, titleVisibility: .visible) {
            Button("保留原件并修复", action: repair)
            Button("取消", role: .cancel) {}
        } message: {
            Text("先保留原文件副本，再保存当前记录。")
        }
    }
}

@MainActor
struct ConversationLifecycleFlush: ViewModifier {
    @Environment(\.scenePhase) private var phase
    let inference: InferenceEngine
    @State private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    @State private var flushTicket: UUID?

    func body(content: Content) -> some View {
        content.onChange(of: phase) { _, phase in
            guard phase != .active else { return }
            if phase == .background { inference.stop() }
            guard flushTicket == nil else { return }
            let ticket = UUID()
            flushTicket = ticket
            backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "Save conversations") {
                Task { @MainActor in finish(ticket) }
            }
            Task { @MainActor in
                await inference.flushConversationHistory()
                finish(ticket)
            }
        }
    }

    private func finish(_ ticket: UUID) {
        guard flushTicket == ticket else { return }
        let identifier = backgroundTask
        backgroundTask = .invalid
        flushTicket = nil
        if identifier != .invalid { UIApplication.shared.endBackgroundTask(identifier) }
    }
}
