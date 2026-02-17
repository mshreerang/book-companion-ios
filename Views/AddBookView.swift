//
//  AddBookView.swift
//  BookCompanion
//
//  Created by Shree on 06/02/2026.
//

import SwiftUI

struct AddBookView: View {
    
    @Environment(\.dismiss) var dismiss
    @ObservedObject var bookManager: BookManager
    
    @State private var title = ""
    @State private var author = ""
    @State private var selectedLanguage: Language = .english
    @State private var totalChapters = 20
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Book Information") {
                    TextField("Book Title", text: $title)
                        .autocapitalization(.words)
                    
                    TextField("Author Name", text: $author)
                        .autocapitalization(.words)
                }
                
                Section("Details") {
                    Picker("Language", selection: $selectedLanguage) {
                        ForEach(Language.allCases) { language in
                            Text(language.displayName).tag(language)
                        }
                    }
                    
                    Stepper("Total Chapters: \(totalChapters)", value: $totalChapters, in: 1...500)
                }
                
                Section {
                    Button {
                        addBook()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Add to Library")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(!isValid)
                }
            }
            .navigationTitle("Add Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !author.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func addBook() {
        guard isValid else {
            errorMessage = "Please fill in all fields"
            showingError = true
            return
        }
        
        bookManager.addBook(
            title: title,
            author: author,
            language: selectedLanguage,
            totalChapters: totalChapters
        )
        
        dismiss()
    }
}

#Preview {
    AddBookView(bookManager: BookManager())
}
