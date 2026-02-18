import SwiftUI

struct EmptyLibraryView: View {
    let onAddBook: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Illustration
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "books.vertical")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            // Text
            VStack(spacing: 8) {
                Text("Your Library is Empty")
                    .font(.title2.bold())
                
                Text("Add your first book to start tracking your reading journey")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            // Add Button
            Button(action: onAddBook) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Your First Book")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
