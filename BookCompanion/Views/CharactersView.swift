//
//  CharactersView.swift
//  BookCompanion
//
//  Created by Shree on 18/01/2026.
//
import SwiftUI

struct CharactersView: View {

    let characters: [BookCharacter]
    let chapter: Int

    var body: some View {
        List {
            Section {
                Text("Safe up to Chapter \(chapter)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            ForEach(characters) { character in
                VStack(alignment: .leading, spacing: 4) {
                    Text(character.name)
                        .font(.headline)

                    Text(character.description)
                        .font(.subheadline)

                    if let relationships = character.relationships {
                        Text(relationships)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 6)
            }
        }
        .navigationTitle("Characters")
    }
}

