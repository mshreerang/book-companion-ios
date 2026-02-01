import Foundation
enum MockData {

    static let books: [Book] = [
        Book(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            title: "The Shadow Lines",
            author: "Amitav Ghosh",
            language: .english,
            createdAt: Date(timeIntervalSince1970: 1_600_000_000),
            
        ),
        Book(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            title: "Midnight's Children",
            author: "Salman Rushdie",
            language: .english,
            createdAt:Date(timeIntervalSince1970: 1_600_000_000)
        ),
        Book(
            id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
            title: "Train to Pakistan",
            author: "Khushwant Singh",
            language: .english,
            createdAt: Date(timeIntervalSince1970: 1_600_000_000)
        )
    ]
}

