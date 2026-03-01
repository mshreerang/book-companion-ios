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
            .shimmer() // Uses your existing shimmer modifier
    }
}

// MARK: - Updated Summary Skeleton
// Aligned with the new 3-section prompt (Story, Evolution, Revelations)
struct SummarySkeleton: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                
                // Section 1: 📍 The Story So Far
                VStack(alignment: .leading, spacing: 12) {
                    SkeletonBox(width: 160, height: 24, cornerRadius: 6) // Header
                    VStack(alignment: .leading, spacing: 8) {
                        SkeletonBox(height: 14)
                        SkeletonBox(height: 14)
                        SkeletonBox(width: 250, height: 14)
                    }
                }
                
                // Section 2: 👤 Character Evolution
                VStack(alignment: .leading, spacing: 12) {
                    SkeletonBox(width: 180, height: 24, cornerRadius: 6) // Header
                    VStack(alignment: .leading, spacing: 8) {
                        SkeletonBox(height: 14)
                        SkeletonBox(width: 200, height: 14)
                    }
                }
                
                // Section 3: 🗝️ Key Revelations
                VStack(alignment: .leading, spacing: 12) {
                    SkeletonBox(width: 140, height: 24, cornerRadius: 6) // Header
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 10) {
                            SkeletonBox(width: 10, height: 10, cornerRadius: 5) // Bullet
                            SkeletonBox(height: 14)
                        }
                        HStack(spacing: 10) {
                            SkeletonBox(width: 10, height: 10, cornerRadius: 5) // Bullet
                            SkeletonBox(width: 220, height: 14)
                        }
                    }
                }
            }
            .padding(20)
        }
    }
}

// MARK: - Book Row Skeleton
struct BookRowSkeleton: View {
    var body: some View {
        HStack(spacing: 12) {
            SkeletonBox(width: 60, height: 90, cornerRadius: 6)
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

// MARK: - Character Card Skeleton
struct CharacterCardSkeleton: View {
    var body: some View {
        VStack(spacing: 12) {
            // Avatar Circle
            Circle()
                .fill(Color(UIColor.systemGray5))
                .frame(width: 60, height: 60)
                .shimmer()
            
            // Name and Role
            VStack(spacing: 8) {
                SkeletonBox(width: 100, height: 16)
                SkeletonBox(width: 60, height: 12)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

// MARK: - Search Result Skeleton
struct SearchResultSkeleton: View {
    var body: some View {
        HStack(spacing: 12) {
            SkeletonBox(width: 50, height: 75, cornerRadius: 4)
            VStack(alignment: .leading, spacing: 6) {
                SkeletonBox(width: 200, height: 16)
                SkeletonBox(width: 150, height: 14)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

// MARK: - Previews
#Preview("Summary Skeleton") {
    SummarySkeleton()
}

#Preview("Character Grid Skeleton") {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
        CharacterCardSkeleton()
        CharacterCardSkeleton()
    }
    .padding()
}
