//
//  UserDefaultsSummaryRepository.swift
//  BookCompanion
//
//  Created by Shree on 01/02/2026.
//
import Foundation

final class UserDefaultsSummaryRepository: SummaryRepository {

    private let defaults = UserDefaults.standard
    private let keyPrefix = "book_summary_"
    private let charactersKeyPrefix = "book_characters_"

    func loadSummary(
        bookId: UUID,
        chapter: Int,
        language: Language,
        length: SummaryLength
    ) -> BookSummary? {

        let key = makeKey(
            bookId: bookId,
            chapter: chapter,
            language: language,
            length: length  // ✅ Include in key
        )

        guard
            let data = defaults.data(forKey: key),
            let summary = try? JSONDecoder().decode(BookSummary.self, from: data)
        else {
            return nil
        }

        return summary
    }

    func saveSummary(_ summary: BookSummary) {
        let key = makeKey(
            bookId: summary.bookId,
            chapter: summary.chapter,
            language: summary.language,
            length: summary.length  // ✅ Include in key
        )

        guard let data = try? JSONEncoder().encode(summary) else {
            return
        }

        defaults.set(data, forKey: key)
    }
    
    func loadCharacters(
        bookId: UUID,
        chapter: Int,
        language: Language,
        length: SummaryLength
    ) -> [BookCharacter]? {
        let key = makeCharactersKey(
            bookId: bookId,
            chapter: chapter,
            language: language,
            length: length  // ✅ Include in key
        )
        
        guard
            let data = defaults.data(forKey: key),
            let characters = try? JSONDecoder().decode([BookCharacter].self, from: data)
        else {
            return nil
        }
        
        return characters
    }
    
    func saveCharacters(
        _ characters: [BookCharacter],
        bookId: UUID,
        chapter: Int,
        language: Language,
        length: SummaryLength
    ) {
        let key = makeCharactersKey(
            bookId: bookId,
            chapter: chapter,
            language: language,
            length: length  // ✅ Include in key
        )
        
        guard let data = try? JSONEncoder().encode(characters) else {
            return
        }
        
        defaults.set(data, forKey: key)
    }

    // MARK: - Helpers
    
    private func makeKey(
        bookId: UUID,
        chapter: Int,
        language: Language,
        length: SummaryLength
    ) -> String {
        "\(keyPrefix)\(bookId.uuidString)_\(chapter)_\(language.rawValue)_\(length.rawValue)"  // ✅ Include length
    }
    
    private func makeCharactersKey(
        bookId: UUID,
        chapter: Int,
        language: Language,
        length: SummaryLength  
    ) -> String {
        "\(charactersKeyPrefix)\(bookId.uuidString)_\(chapter)_\(language.rawValue)_\(length.rawValue)"  // ✅ Include length
    }
}
