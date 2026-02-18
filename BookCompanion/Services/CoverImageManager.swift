//
//  CoverImageManager.swift
//  BookCompanion
//
//  Created on 15/02/2026.
//
import UIKit
import SwiftUI

actor CoverImageManager {
    
    static let shared = CoverImageManager()
    
    private let fileManager = FileManager.default
    private let maxStorageSize: Int = 100_000_000 // 100 MB
    
    // MARK: - Directory Setup
    
    private var coversDirectory: URL {
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsURL.appendingPathComponent("Covers")
    }
    
    private init() {
        Task {
            await createCoversDirectoryIfNeeded()
        }
    }
    
    private func createCoversDirectoryIfNeeded() async {
        if !fileManager.fileExists(atPath: coversDirectory.path) {
            try? fileManager.createDirectory(at: coversDirectory, withIntermediateDirectories: true)
            print("📁 Created Covers directory at: \(coversDirectory.path)")
        }
    }
    
    // MARK: - Public Methods
    
    /// Get cover image for a book (returns nil if not cached)
    func getCover(for bookId: UUID) -> UIImage? {
        let fileURL = coverURL(for: bookId)
        
        guard fileManager.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }
        
        // Update access time for LRU
        try? fileManager.setAttributes([.modificationDate: Date()], ofItemAtPath: fileURL.path)
        
        return image
    }
    
    /// Download and cache cover image
    func downloadAndCacheCover(from urlString: String?, for bookId: UUID) async -> UIImage? {
        guard let urlString = urlString,
              let url = URL(string: urlString) else {
            return nil
        }
        
        // Check if already cached
        if let cached = getCover(for: bookId) {
            print("✅ Cover already cached for book: \(bookId)")
            return cached
        }
        
        print("⬇️ Downloading cover from: \(urlString)")
        
        do {
            // Download image
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let image = UIImage(data: data) else {
                print("❌ Failed to download or decode image")
                return nil
            }
            
            // Compress and save
            if let compressed = compressImage(image) {
                saveCover(compressed, for: bookId)
                print("✅ Cover cached for book: \(bookId)")
                return image
            }
            
            return image
            
        } catch {
            print("❌ Error downloading cover: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Delete cover for a specific book
    func deleteCover(for bookId: UUID) {
        let fileURL = coverURL(for: bookId)
        try? fileManager.removeItem(at: fileURL)
        print("🗑️ Deleted cover for book: \(bookId)")
    }
    
    /// Get total storage used by covers
    func getTotalStorageUsed() -> Int {
        guard let contents = try? fileManager.contentsOfDirectory(at: coversDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        
        return contents.reduce(0) { total, url in
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            return total + size
        }
    }
    
    /// Clear all covers
    func clearAllCovers() {
        guard let contents = try? fileManager.contentsOfDirectory(at: coversDirectory, includingPropertiesForKeys: nil) else {
            return
        }
        
        for url in contents {
            try? fileManager.removeItem(at: url)
        }
        
        print("🗑️ Cleared all covers")
    }
    
    /// Clean up old covers if storage exceeds limit
    func cleanupIfNeeded() {
        let totalSize = getTotalStorageUsed()
        
        guard totalSize > maxStorageSize else {
            return
        }
        
        print("⚠️ Storage limit exceeded (\(totalSize / 1_000_000) MB), cleaning up...")
        
        // Get all cover files sorted by last access time (oldest first)
        guard let contents = try? fileManager.contentsOfDirectory(
            at: coversDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey]
        ) else {
            return
        }
        
        let sortedFiles = contents.sorted { url1, url2 in
            let date1 = (try? url1.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast
            let date2 = (try? url2.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast
            return date1 < date2
        }
        
        // Delete oldest files until we're under 80% of limit
        var currentSize = totalSize
        let targetSize = Int(Double(maxStorageSize) * 0.8)
        
        for fileURL in sortedFiles {
            guard currentSize > targetSize else { break }
            
            let fileSize = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            try? fileManager.removeItem(at: fileURL)
            currentSize -= fileSize
            
            print("🗑️ Deleted old cover: \(fileURL.lastPathComponent)")
        }
        
        print("✅ Cleanup complete. New size: \(currentSize / 1_000_000) MB")
    }
    
    // MARK: - Private Helpers
    
    private func coverURL(for bookId: UUID) -> URL {
        coversDirectory.appendingPathComponent("\(bookId.uuidString).jpg")
    }
    
    private func saveCover(_ image: UIImage, for bookId: UUID) {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            return
        }
        
        let fileURL = coverURL(for: bookId)
        try? data.write(to: fileURL)
        
        // Check storage and cleanup if needed
        cleanupIfNeeded()
    }
    
    private func compressImage(_ image: UIImage) -> UIImage? {
        // Target: ~100 KB per image
        let maxSize: CGFloat = 400 // Max width/height in pixels
        
        // Calculate new size maintaining aspect ratio
        let size = image.size
        let ratio = min(maxSize / size.width, maxSize / size.height)
        
        if ratio >= 1 {
            // Image is already small enough
            return image
        }
        
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        // Resize
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage
    }
}

// MARK: - SwiftUI Integration

struct CachedCoverImage: View {
    let bookId: UUID
    let coverURL: String?
    
    @State private var image: UIImage?
    @State private var isLoading = false
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if isLoading {
                placeholderWithShimmer
            } else {
                placeholderCover
            }
        }
        .task {
            await loadCover()
        }
    }
    
    private var placeholderCover: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            Image(systemName: "book.closed.fill")
                .font(.title2)
                .foregroundColor(.white.opacity(0.8))
        }
    }
    
    private var placeholderWithShimmer: some View {
        ZStack {
            Color(UIColor.systemGray5)
            
            ProgressView()
                .tint(.white)
        }
        .shimmer()
    }
    
    private func loadCover() async {
        // Check cache first
        if let cached = await CoverImageManager.shared.getCover(for: bookId) {
            self.image = cached
            return
        }
        
        // Download if needed
        guard let coverURL = coverURL else {
            return
        }
        
        isLoading = true
        
        if let downloaded = await CoverImageManager.shared.downloadAndCacheCover(from: coverURL, for: bookId) {
            self.image = downloaded
        }
        
        isLoading = false
    }
}
