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
            
        )
    ]
}

