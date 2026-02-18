//
//  BookCard.swift
//  BookCompanion
//
//  Created by Shree on 17/02/2026.
//
import SwiftUI

struct BookCard: View {
    let book: Book
    
    var body: some View {
        HStack(spacing: 16) {
            // Book Cover
            BookCoverView(book: book)
                .frame(width: 80, height: 120)
                .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
            
            // Book Info
            VStack(alignment: .leading, spacing: 8) {
                // Title
                Text(book.title)
                    .font(.headline)
                    .lineLimit(2)
                
                // Author
                Text(book.author)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Spacer()
                
                // Progress Info
                if let readingProgress = book.readingProgress {
                    progressView(readingProgress: readingProgress)
                } else {
                    notStartedView
                }
            }
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundColor(.secondary)
                .opacity(0.5)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray5), lineWidth: 0.5)
        )
    }
    
    // MARK: - Progress View
    
    @ViewBuilder
    private func progressView(readingProgress: ReadingProgress) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.systemGray5))
                    
                    // Progress - with safe calculation
                    let progressWidth = calculateProgressWidth(
                        geometry: geometry,
                        currentChapter: readingProgress.chapter,
                        totalChapters: book.totalChapters
                    )
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: progressWidth)
                }
            }
            .frame(height: 6)
            
            // Chapter Info
            HStack(spacing: 12) {
                Label("\(readingProgress.chapter)/\(book.totalChapters)", systemImage: "book.pages")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                let percentage = calculatePercentage(
                    currentChapter: readingProgress.chapter,
                    totalChapters: book.totalChapters
                )
                
                Text("\(percentage)%")
                    .font(.caption.bold())
                    .foregroundColor(.blue)
            }
        }
    }
    
    // MARK: - Not Started View
    
    private var notStartedView: some View {
        HStack {
            Image(systemName: "book.closed")
                .font(.caption)
            Text("Not started")
                .font(.caption)
            
            Spacer()
            
            Text("\(book.totalChapters) chapters")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .foregroundColor(.secondary)
    }
    
    // MARK: - Safe Calculations
    
    private func calculateProgressWidth(geometry: GeometryProxy, currentChapter: Int, totalChapters: Int) -> CGFloat {
        guard totalChapters > 0 else { return 0 }
        let percentage = Double(currentChapter) / Double(totalChapters)
        let clamped = min(max(percentage, 0), 1.0) // Clamp between 0 and 1
        return geometry.size.width * clamped
    }
    
    private func calculatePercentage(currentChapter: Int, totalChapters: Int) -> Int {
        guard totalChapters > 0 else { return 0 }
        let percentage = (Double(currentChapter) / Double(totalChapters)) * 100
        return Int(min(max(percentage, 0), 100)) // Clamp between 0 and 100
    }
}

// MARK: - Book Cover View

struct BookCoverView: View {
    let book: Book
    
    var body: some View {
        ZStack {
            if let coverURL = book.coverImageURL {
                // Use AsyncImage
                AsyncImage(url: URL(string: coverURL)) { phase in
                    switch phase {
                    case .empty:
                        BookCoverPlaceholder(title: book.title)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure(_):
                        BookCoverPlaceholder(title: book.title)
                    @unknown default:
                        BookCoverPlaceholder(title: book.title)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                BookCoverPlaceholder(title: book.title)
            }
            
            // Completion badge
            if let readingProgress = book.readingProgress,
               readingProgress.chapter >= book.totalChapters {
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.white, .green)
                            .shadow(color: .black.opacity(0.3), radius: 2)
                            .padding(4)
                    }
                    Spacer()
                }
            }
        }
    }
}

struct BookCoverPlaceholder: View {
    let title: String
    
    var body: some View {
        ZStack {
            // Gradient background (unique color per book)
            LinearGradient(
                colors: [
                    Color(hue: Double(abs(title.hashValue) % 360) / 360, saturation: 0.6, brightness: 0.7),
                    Color(hue: Double(abs(title.hashValue) % 360) / 360, saturation: 0.8, brightness: 0.5)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Book icon and title
            VStack(spacing: 8) {
                Image(systemName: "book.fill")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.9))
                
                Text(title)
                    .font(.caption2.bold())
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, 4)
            }
            .padding(8)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
