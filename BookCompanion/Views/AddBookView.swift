//
//  AddBookView.swift
//  BookCompanion
//
//  Created by Shree on 06/02/2026.
//  Updated: replaced Stepper for chapter count with a direct number
//           TextField — tapping 40+ times on a stepper is unusable.
//           Stepper kept as a fine-tune ±1 control below the field.
//

import SwiftUI

struct AddBookView: View {

    @Environment(\.dismiss) var dismiss
    @ObservedObject var bookManager: BookManager

    @State private var title            = ""
    @State private var author           = ""
    @State private var selectedLanguage: Language = .english
    @State private var totalChapters    = 20
    @State private var chaptersText     = "20"
    @State private var showingError     = false
    @State private var errorMessage     = ""

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

                    // Chapter count — direct number entry is far faster than
                    // a stepper for books with 30+ chapters.
                    // The stepper below allows fine ±1 adjustment.
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Total Chapters")
                                .foregroundColor(.primary)

                            Spacer()

                            // Number input field
                            TextField("e.g. 38", text: $chaptersText)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 72)
                                .onChange(of: chaptersText) { _, newValue in
                                    // Strip non-digits and clamp to 1–500
                                    let digits = newValue.filter(\.isNumber)
                                    if let n = Int(digits), n > 0 {
                                        totalChapters = min(n, 500)
                                        chaptersText  = "\(totalChapters)"
                                    } else if digits.isEmpty {
                                        chaptersText = ""
                                    }
                                }
                        }

                        // Fine-tune stepper — useful when you just need ±1
                        Stepper(
                            "Adjust: \(totalChapters)",
                            value: $totalChapters,
                            in: 1...500
                        )
                        .onChange(of: totalChapters) { _, newValue in
                            chaptersText = "\(newValue)"
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
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
                    Button("Cancel") { dismiss() }
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
        !author.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        totalChapters > 0
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
