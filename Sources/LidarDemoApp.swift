import SwiftUI

@main
struct LidarDemoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                // Grænsefladen følger selv systemets lyse eller mørke indstilling
                // gennem CSS, så appen skal ikke tvinge nogen af delene.
                .persistentSystemOverlays(.hidden)
        }
    }
}
