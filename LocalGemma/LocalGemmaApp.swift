import SwiftUI

@main
struct LocalGemmaApp: App {
    @StateObject private var catalog = ModelCatalog(autoScanLocalArtifacts: true)
    @StateObject private var inferenceEngine = InferenceEngine()
    @StateObject private var optimizer = DeviceOptimizer()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(catalog)
                .environmentObject(inferenceEngine)
                .environmentObject(optimizer)
        }
        .commands {
            WorkspaceCommands()
            SessionCommands()
        }
    }
}

struct WorkspaceCommands: Commands {
    @FocusedValue(\.workspaceTabSelection) private var workspaceTabSelection

    var body: some Commands {
        CommandMenu(WorkspaceTab.commandMenuTitle) {
            ForEach(WorkspaceTab.commandItems) { item in
                Button(item.title) {
                    workspaceTabSelection?.wrappedValue = item.tab
                }
                .keyboardShortcut(KeyEquivalent(item.shortcutKey), modifiers: [.command])
                .disabled(workspaceTabSelection == nil)
            }
        }
    }
}

struct SessionCommands: Commands {
    @FocusedValue(\.sessionCommandActions) private var sessionCommandActions

    var body: some Commands {
        CommandMenu(SessionCommandAction.commandMenuTitle) {
            ForEach(SessionCommandAction.commandItems) { item in
                Button(item.title) {
                    sessionCommandActions?.perform(item.action)
                }
                .keyboardShortcut(
                    KeyEquivalent(item.shortcutKey),
                    modifiers: item.requiresShift ? [.command, .shift] : [.command]
                )
                .disabled(
                    !SessionCommandRoutingPolicy.isEnabled(
                        hasFocusedActions: sessionCommandActions != nil
                    )
                )
            }
        }
    }
}
