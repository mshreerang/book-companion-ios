//
//  CharactersView.swift
//  BookCompanion
//
//  Created by Shree on 01/02/2026.
//

import SwiftUI

struct CharactersView: View {
    
    let characters: [BookCharacter]
    @State private var searchText = ""
    
    private var filteredCharacters: [BookCharacter] {
        guard !searchText.isEmpty else {
            return characters
        }
        
        return characters.filter { character in
            character.name.localizedCaseInsensitiveContains(searchText) ||
            character.description.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        Group {
            if characters.isEmpty {
                EmptyCharactersView()
            } else if filteredCharacters.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                List {
                    ForEach(filteredCharacters) { character in
                        HStack(alignment: .top, spacing: 16) {
                            CharacterAvatar(name: character.name, size: 60)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text(character.name)
                                    .font(.headline)
                                
                                Text(character.description)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                
                                if let relationships = character.relationships,
                                   !relationships.isEmpty,
                                   relationships.lowercased() != "null" {
                                    HStack(spacing: 4) {
                                        Image(systemName: "person.2")
                                            .font(.caption)
                                            .foregroundColor(Theme.Colors.secondary)
                                        Text(relationships)
                                            .font(.caption)
                                            .foregroundColor(Theme.Colors.secondary)
                                    }
                                    .padding(.top, 4)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Characters")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search characters")
    }
}

#Preview {
    NavigationStack {
        CharactersView(characters: [
            BookCharacter(
                id: UUID(),
                bookId: UUID(),
                progressId: UUID(),
                name: "Nick Carraway",
                description: "The narrator who moves to West Egg",
                relationships: "Cousin of Daisy Buchanan",
                language: .english,
                generatedAt: Date()
            ),
            BookCharacter(
                id: UUID(),
                bookId: UUID(),
                progressId: UUID(),
                name: "Jay Gatsby",
                description: "Mysterious wealthy neighbor who throws lavish parties",
                relationships: "In love with Daisy",
                language: .english,
                generatedAt: Date()
            ),
            BookCharacter(
                id: UUID(),
                bookId: UUID(),
                progressId: UUID(),
                name: "Daisy Buchanan",
                description: "Nick's cousin, married to Tom",
                relationships: "Wife of Tom Buchanan",
                language: .english,
                generatedAt: Date()
            )
        ])
    }
}
