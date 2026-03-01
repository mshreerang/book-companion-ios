//
//  KeychainManager.swift
//  BookCompanion
//
//  Created by Shree on 22/02/2026.
//

import Foundation
import Security

class KeychainManager {
    
    static let shared = KeychainManager()
    
    private let service = "com.ViVa.BookCompanion"
    private let userTokenKey = "userToken"
    private let userIdKey = "userId"
    
    private init() {}
    
    // MARK: - Save Token
    
    func saveUserToken(_ token: String) {
        save(key: userTokenKey, value: token)
    }
    
    func saveUserId(_ userId: String) {
        save(key: userIdKey, value: userId)
    }
    
    // MARK: - Get Token
    
    func getUserToken() -> String? {
        return get(key: userTokenKey)
    }
    
    func getUserId() -> String? {
        return get(key: userIdKey)
    }
    
    // MARK: - Delete Token (Sign Out)
    
    func deleteUserToken() {
        delete(key: userTokenKey)
    }
    
    func deleteUserId() {
        delete(key: userIdKey)
    }
    
    func clearAll() {
        deleteUserToken()
        deleteUserId()
    }
    
    // MARK: - Private Helpers
    
    private func save(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        
        // Delete any existing item
        delete(key: key)
        
        // Create new item
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            print("⚠️ Keychain save failed for \(key): \(status)")
        } else {
            print("✅ Saved to Keychain: \(key)")
        }
    }
    
    private func get(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
    
    private func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}
