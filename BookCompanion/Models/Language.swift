//
//  Untitled.swift
//  BookCompanion
//
//  Created by Shree on 18/01/2026.
//
enum Language:String,CaseIterable,Identifiable {
case english="en"
case hindi="hi"
case marathi="mr"

var id:String { rawValue }

var displayName:String {
switch self {
case .english:return"English"
case .hindi:return"Hindi"
case .marathi:return"Marathi"
        }
    }
}

