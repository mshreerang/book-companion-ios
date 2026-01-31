import Foundation

struct MockData {
    static let books: [Book] = [
        Book(
            id: UUID(),
            title: "The Shadow Lines",
            author: "Amitav Ghosh",
            language: .english,
            createdAt: Date()
        ),
        Book(
            id: UUID(),
            title: "मृत्युंजय",
            author: "शिवाजी सावंत",
            language: .marathi,
            createdAt: Date()
        ),
        Book(
            id: UUID(),
            title: "राधेय",
            author: "रवींद्रनाथ तागोर",
            language: .hindi,
            createdAt: Date()
        )
    ]
}

