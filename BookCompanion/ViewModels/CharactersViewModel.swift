//
//  CharactersViewModel.swift
//  BookCompanion
//
//  Created by Shree on 06/02/2026.
//

import Foundation
import Combine

@MainActor
final class CharactersViewModel: ObservableObject {
    
    @Published private(set) var characters: [BookCharacter] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error? = nil
    @Published private(set) var isCached = false
    
    private let book: Book
    private let language: Language
    private let generator: SummaryGenerator
    private let summaryRepository: SummaryRepository
    
    init(
        book: Book,
        language: Language,
        generator: SummaryGenerator,
        summaryRepository: SummaryRepository
    ) {
        self.book = book
        self.language = language
        self.generator = generator
        self.summaryRepository = summaryRepository
    }
    
    func loadCharacters(chapter: Int, length: SummaryLength) async {
        isLoading = true
        error = nil
        isCached = false
        defer { isLoading = false }
        
        // Try cache first
        if let cached = summaryRepository.loadCharacters(
            bookId: book.id,
            chapter: chapter,
            language: language,
            length: length
        ) {
            self.characters = cached
            self.isCached = true
            return
        }
        
        // Generate new
        do {
            let generated = try await generator.generateCharacters(
                book: book,
                chapter: chapter,
                language: language
            )
            
            // Save to cache
            summaryRepository.saveCharacters(
                generated,
                bookId: book.id,
                chapter: chapter,
                language: language,
                length: length
            )
            
            self.characters = generated
            self.error = nil
            
        } catch {
            self.characters = []
            self.error = error
        }
    }
    
    func regenerate(chapter: Int, length: SummaryLength) async {
        isLoading = true
        error = nil
        isCached = false
        defer { isLoading = false }
        
        do {
            let generated = try await generator.generateCharacters(
                book: book,
                chapter: chapter,
                language: language
            )
            
            summaryRepository.saveCharacters(
                generated,
                bookId: book.id,
                chapter: chapter,
                language: language,
                length: length
            )
            
            self.characters = generated
            self.error = nil
            
        } catch {
            self.characters = []
            self.error = error
        }
    }
}
