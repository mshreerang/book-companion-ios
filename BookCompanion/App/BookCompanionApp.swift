//
//  BookCompanionApp.swift
//  BookCompanion
//
//  Created by Shree on 18/01/2026.
//

import SwiftUI

@main
struct BookCompanionApp: App {

    private let container = AppContainer()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                BookSearchView(
                    viewModel: container.makeBookSearchViewModel(),
                    settingsManager: container.settingsManager,
                    bookManager: container.bookManager,  // ✅ Pass bookManager
                    makeProgressViewModel: container.makeProgressInputViewModel,
                    makeSummaryViewModel: container.makeSummaryViewModel,
                    makeCharactersViewModel: container.makeCharactersViewModel
                )
            }
        }
    }
}
