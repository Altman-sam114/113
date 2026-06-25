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
    }
}
