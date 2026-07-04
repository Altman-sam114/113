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
