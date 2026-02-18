//
//  SupabaseService.swift
//  BookCompanion
//
//  Supabase backend integration (placeholder)
//
import Foundation
import UIKit  // ✅ Added for UIDevice

// MARK: - Supabase Models

struct User: Codable {
    let id: String
    let deviceId: String
    let createdAt: Date
}

struct UsageTracking: Codable {
    let userId: String
    let summaryCount: Int
    let lastResetDate: Date
}

struct CloudBook: Codable {
    let id: String
    let userId: String
    let title: String
    let author: String
    let totalChapters: Int
    let currentChapter: Int
    let language: String
    let coverImageURL: String?
    let createdAt: Date
    let updatedAt: Date
}

// MARK: - Supabase Service

actor SupabaseService {
    static let shared = SupabaseService()
    
    // Placeholder - implement when Supabase is ready
    private init() {}
    
    // MARK: - User Management
    
    func createUser(deviceId: String) async throws -> User {
        // TODO: Implement Supabase call
        throw SupabaseError.notImplemented
    }
    
    func getUser(deviceId: String) async throws -> User? {
        // TODO: Implement Supabase call
        return nil
    }
    
    // MARK: - Usage Tracking
    
    func getUsage(userId: String) async throws -> UsageTracking {
        // TODO: Implement Supabase call
        throw SupabaseError.notImplemented
    }
    
    func incrementSummaryCount(userId: String) async throws {
        // TODO: Implement Supabase call
        throw SupabaseError.notImplemented
    }
    
    // MARK: - Book Sync
    
    func syncBooks(userId: String, books: [Book]) async throws {
        // TODO: Implement Supabase call
        throw SupabaseError.notImplemented
    }
    
    func saveBook(userId: String, book: Book) async throws {
        // TODO: Implement Supabase call
        
        // Convert Book to CloudBook format
        let cloudBook = CloudBook(
            id: book.id.uuidString,
            userId: userId,
            title: book.title,
            author: book.author,
            totalChapters: book.totalChapters,
            currentChapter: book.readingProgress?.chapter ?? 1,  // ✅ Fixed
            language: book.language.rawValue,
            coverImageURL: book.coverImageURL,
            createdAt: book.createdAt,
            updatedAt: Date()
        )
        
        // TODO: Send to Supabase
        print("Would save book: \(cloudBook)")
    }
    
    // MARK: - Helper
    
    nonisolated func getCurrentDeviceId() -> String {
        // ✅ nonisolated function can access MainActor synchronously
        return MainActor.assumeIsolated {
            UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        }
    }
}

// MARK: - Errors

enum SupabaseError: LocalizedError {
    case notImplemented
    case networkError
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .notImplemented:
            return "Supabase integration not yet implemented"
        case .networkError:
            return "Network error"
        case .unauthorized:
            return "Unauthorized"
        }
    }
}
