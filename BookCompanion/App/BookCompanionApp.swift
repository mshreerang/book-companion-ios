import SwiftUI

@main
struct BookCompanionApp: App {
    private let container = AppContainer()
    
    @State private var showAgeGate = !AgeVerificationService.shared.isAgeConfirmed()
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    
    var body: some Scene {
        WindowGroup {
            if showAgeGate {
                AgeGateView(onContinue: {
                    showAgeGate = false
                })
            } else if showOnboarding {
                OnboardingView(onComplete: {
                    UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                    showOnboarding = false
                })
            } else {
                NavigationStack {
                    BookSearchView(
                        viewModel: container.makeBookSearchViewModel(),
                        settingsManager: container.settingsManager,
                        bookManager: container.bookManager,
                        makeProgressViewModel: { book in
                            container.makeProgressInputViewModel(book: book)
                        },
                        makeSummaryViewModel: { book, language, length in
                            container.makeSummaryViewModel(
                                book: book,
                                language: language,
                                length: length
                            )
                        },
                        makeCharactersViewModel: { book, language in
                            container.makeCharactersViewModel(
                                book: book,
                                language: language
                            )
                        }
                    )
                }
                .environmentObject(container.settingsManager)
                .environmentObject(container.bookManager)
            }
        }
    }
}
