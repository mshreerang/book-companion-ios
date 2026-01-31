//
//  ProgressViewModel.swift
//  BookCompanion
//
//  Created by Shree on 31/01/2026.
//

import Combine

final class ProgressViewModel: ObservableObject {
    @Published var selectedLanguage: Language = .english
    @Published var selectedChapter: Int = 1
}
