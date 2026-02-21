//
//  CharactersViewModel.swift
//  BookCompanion
//
//  Created by Shree on 01/02/2026.
//

import Foundation
import Combine

@MainActor
class CharactersViewModel: ObservableObject {
    @Published var characters: [BookCharacter] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var isCached = false
    @Published var hasMore = false       // ✅ Track if more characters exist
    @Published var currentOffset = 0     // ✅ Track pagination offset
    
    private let limit = 5  // ✅ Load 5 at a time
    
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
    
    // ✅ INITIAL LOAD
    func loadCharacters(chapter: Int, length: SummaryLength) async {
        // Reset pagination state
        currentOffset = 0
        characters = []
        hasMore = false
        
        isLoading = true
        error = nil
        isCached = false
        
        // Check cache first
        if let cachedCharacters = summaryRepository.loadCharacters(
            bookId: book.id,
            chapter: chapter,
            language: language,
            length: length
        ) {
            self.characters = cachedCharacters
            self.isCached = true
            self.isLoading = false
            self.hasMore = false  // Cached = complete set
            return
        }
        
        // Generate first batch
        await fetchCharacters(chapter: chapter, length: length, offset: 0)
    }
    
    // ✅ LOAD MORE (pagination)
    func loadMoreCharacters(chapter: Int, length: SummaryLength) async {
        guard !isLoading && hasMore else { return }
        
        let nextOffset = currentOffset + limit
        await fetchCharacters(chapter: chapter, length: length, offset: nextOffset)
    }
    
    // ✅ FETCH FROM API
    private func fetchCharacters(chapter: Int, length: SummaryLength, offset: Int) async {
        isLoading = true
        
        do {
            // For now, we'll use the existing generator which doesn't support pagination
            // So we'll generate all and then slice them
            let allCharacters = try await generator.generateCharacters(
                book: book,
                chapter: chapter,
                language: language
            )
            
            // Simulate pagination by slicing
            let startIndex = offset
            let endIndex = min(offset + limit, allCharacters.count)
            
            if startIndex < allCharacters.count {
                let batch = Array(allCharacters[startIndex..<endIndex])
                
                if offset == 0 {
                    // First batch - replace
                    self.characters = batch
                } else {
                    // Subsequent batches - append
                    self.characters.append(contentsOf: batch)
                }
                
                // Update pagination state
                self.currentOffset = offset
                self.hasMore = endIndex < allCharacters.count
                
                // Save complete set to cache (only on first load)
                if offset == 0 {
                    saveCharactersToCache(allCharacters, chapter: chapter, length: length)
                }
            } else {
                self.hasMore = false
            }
            
            self.isLoading = false
            self.isCached = false
            
        } catch {
            self.error = error
            self.isLoading = false
            self.hasMore = false
        }
    }
    
    private func saveCharactersToCache(_ characters: [BookCharacter], chapter: Int, length: SummaryLength) {
        summaryRepository.saveCharacters(
            characters,
            bookId: book.id,
            chapter: chapter,
            language: language,
            length: length
        )
    }
}
