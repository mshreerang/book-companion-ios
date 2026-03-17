import SwiftUI

struct EmptyLibraryView: View {
    let onAddBook: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Illustration — icon tint and circle background
            // updated from hardcoded blue/purple to Theme brand colours
            ZStack {
                Circle()
                    .fill(Theme.Colors.gradientStart.opacity(0.10))
                    .frame(width: 120, height: 120)

                Image(systemName: "books.vertical")
                    .font(.system(size: 60))
                    .foregroundStyle(Theme.Colors.brandGradientDiagonal)
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

            // Add Button — uses BrandGradientButtonStyle for consistency
            // with every other primary CTA in the app
            Button(action: onAddBook) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Your First Book")
                }
            }
            .buttonStyle(BrandGradientButtonStyle())
            .padding(.horizontal, 32)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
