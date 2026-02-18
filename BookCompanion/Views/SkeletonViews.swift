//
//  SkeletonViews.swift
//  BookCompanion
//
//  Created on 15/02/2026.
//
import SwiftUI

// MARK: - Basic Skeleton Box

struct SkeletonBox: View {
    let width: CGFloat?
    let height: CGFloat
    let cornerRadius: CGFloat
    
    init(
        width: CGFloat? = nil,
        height: CGFloat = 20,
        cornerRadius: CGFloat = 4
    ) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        Rectangle()
            .fill(Color(UIColor.systemGray5))
            .frame(width: width, height: height)
            .cornerRadius(cornerRadius)
            .shimmer()
    }
}

// MARK: - Book Row Skeleton

struct BookRowSkeleton: View {
    var body: some View {
        HStack(spacing: 12) {
            // Cover skeleton
            SkeletonBox(width: 60, height: 90, cornerRadius: 6)
            
            // Info skeleton
            VStack(alignment: .leading, spacing: 8) {
                SkeletonBox(width: 180, height: 18)
                SkeletonBox(width: 120, height: 14)
                SkeletonBox(width: 90, height: 12)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
    }
}

// MARK: - Summary Skeleton

struct SummarySkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title skeleton
            SkeletonBox(width: 200, height: 24)
            
            Spacer().frame(height: 8)
            
            // Paragraph skeletons
            VStack(alignment: .leading, spacing: 8) {
                SkeletonBox(height: 16)
                SkeletonBox(height: 16)
                SkeletonBox(width: 280, height: 16)
                
                Spacer().frame(height: 12)
                
                SkeletonBox(height: 16)
                SkeletonBox(height: 16)
                SkeletonBox(height: 16)
                SkeletonBox(width: 220, height: 16)
                
                Spacer().frame(height: 12)
                
                SkeletonBox(height: 16)
                SkeletonBox(width: 260, height: 16)
            }
        }
        .padding()
    }
}

// MARK: - Character Card Skeleton

struct CharacterCardSkeleton: View {
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Avatar skeleton
            Circle()
                .fill(Color(UIColor.systemGray5))
                .frame(width: 60, height: 60)
                .shimmer()
            
            // Info skeleton
            VStack(alignment: .leading, spacing: 8) {
                SkeletonBox(width: 140, height: 18)
                SkeletonBox(height: 14)
                SkeletonBox(height: 14)
                SkeletonBox(width: 200, height: 14)
            }
            
            Spacer()
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Search Result Skeleton

struct SearchResultSkeleton: View {
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail skeleton
            SkeletonBox(width: 50, height: 75, cornerRadius: 4)
            
            // Info skeleton
            VStack(alignment: .leading, spacing: 6) {
                SkeletonBox(width: 200, height: 16)
                SkeletonBox(width: 150, height: 14)
                SkeletonBox(width: 100, height: 12)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
