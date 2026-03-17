//
//  BookCard.swift
//  BookCompanion
//
//  Created by Shree on 17/02/2026.
//  Updated: series badge shown between author and progress bar
//           when book.seriesName is present.
//
import SwiftUI

struct BookCard: View {
    let book: Book

    var body: some View {
        HStack(spacing: 16) {
            BookCoverView(book: book)
                .frame(width: 80, height: 120)
                .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)

            VStack(alignment: .leading, spacing: 8) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(2)

                Text(book.author)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                // Series badge — only shown when book has series data.
                // Sits naturally between author and progress bar.
                // e.g. "Harry Potter · Book 4"
                if let seriesName = book.seriesName,
                   let position = book.seriesPosition {
                    HStack(spacing: 4) {
                        Image(systemName: "books.vertical.fill")
                            .font(.system(size: 9, weight: .semibold))
                        Text("\(seriesName) · Book \(position)")
                            .font(.caption2.weight(.semibold))
                            .lineLimit(1)
                    }
                    .foregroundColor(Theme.Colors.primary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Theme.Colors.primary.opacity(0.09))
                    .cornerRadius(Theme.CornerRadius.xs)
                }

                Spacer()

                if let readingProgress = book.readingProgress {
                    progressView(readingProgress: readingProgress)
                } else {
                    notStartedView
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundColor(.secondary)
                .opacity(0.4)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(Theme.CornerRadius.xl)
        .shadow(color: .black.opacity(0.07), radius: 10, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.xl)
                .stroke(Color(.systemGray5), lineWidth: 0.5)
        )
    }

    // MARK: - Progress View

    @ViewBuilder
    private func progressView(readingProgress: ReadingProgress) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.systemGray5))

                    RoundedRectangle(cornerRadius: 3)
                        .fill(Theme.Colors.brandGradient)
                        .frame(width: calculateProgressWidth(
                            geometry: geometry,
                            currentChapter: readingProgress.chapter,
                            totalChapters: book.totalChapters
                        ))
                }
            }
            .frame(height: 6)

            HStack(spacing: 12) {
                Label(
                    "\(readingProgress.chapter)/\(book.totalChapters)",
                    systemImage: "book.pages"
                )
                .font(.caption)
                .foregroundColor(.secondary)

                Spacer()

                Text("\(calculatePercentage(currentChapter: readingProgress.chapter, totalChapters: book.totalChapters))%")
                    .font(.caption.bold())
                    .foregroundColor(Theme.Colors.primary)
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
        let clamped = min(max(Double(currentChapter) / Double(totalChapters), 0), 1.0)
        return geometry.size.width * clamped
    }

    private func calculatePercentage(currentChapter: Int, totalChapters: Int) -> Int {
        guard totalChapters > 0 else { return 0 }
        return Int(min(max((Double(currentChapter) / Double(totalChapters)) * 100, 0), 100))
    }
}

// MARK: - Book Cover View

struct BookCoverView: View {
    let book: Book

    var body: some View {
        ZStack {
            if let coverURL = book.coverImageURL {
                AsyncImage(url: URL(string: coverURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        BookCoverPlaceholder(title: book.title)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
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
                            .foregroundStyle(.white, Color.green)
                            .shadow(color: .black.opacity(0.3), radius: 2)
                            .padding(4)
                    }
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Book Cover Placeholder

struct BookCoverPlaceholder: View {
    let title: String

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hue: stableHue, saturation: 0.55, brightness: 0.72),
                    Color(hue: stableHue, saturation: 0.75, brightness: 0.52)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

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
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
    }

    private var stableHue: Double {
        let byteSum = title.utf8.reduce(0) { $0 &+ Int($1) }
        return Double(abs(byteSum) % 360) / 360.0
    }
}
