import SwiftUI

@main
struct RecetarioProApp: App {
    private let repository = SupabaseRecetaRepository()

    var body: some Scene {
        WindowGroup {
            FeedView(repository: repository)
                .tint(AppTheme.coral)
        }
    }
}
