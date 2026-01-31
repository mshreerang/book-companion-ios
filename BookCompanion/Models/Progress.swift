//
//  Progress.swift
//  BookCompanion
//
//  Created by Shree on 18/01/2026.
//

import Foundation

struct Progress:Identifiable {
let id:UUID
let bookId:UUID
let chapter:Int
let createdAt:Date
}
