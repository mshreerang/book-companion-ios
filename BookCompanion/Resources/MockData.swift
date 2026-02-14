import Foundation
enum MockData {

    static let books: [Book] = [
        Book(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            title: "The Shadow Lines",
            author: "Amitav Ghosh",
            language: .english,
            totalChapters: 25,
            coverImageURL: nil,
            createdAt: Date(timeIntervalSince1970: 1_600_000_000),
            
        ),
        Book(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            title: "Midnight's Children",
            author: "Salman Rushdie",
            language: .english,
            totalChapters: 30,
            coverImageURL: nil,
            createdAt:Date(timeIntervalSince1970: 1_600_000_000)
        ),
        Book(
                id: UUID(uuidString: "11111111-1111-1111-1111-111121111111")!,
                title: "The Shadow Lines",
                author: "Amitav Ghosh",
                language: .english,
                totalChapters: 18,
                coverImageURL: nil,
                createdAt: Date(timeIntervalSince1970: 1_600_000_000)
            )
    ]
}

