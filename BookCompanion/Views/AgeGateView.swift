import SwiftUI

struct AgeGateView: View {
    @State private var isAgeConfirmed = false
    @State private var showingError = false
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon
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
                
                Image(systemName: "book.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            // Title
            VStack(spacing: 12) {
                Text("Before We Begin...")
                    .font(.title.bold())
                
                Text("We need to confirm your age")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Age confirmation checkbox
            Button(action: {
                isAgeConfirmed.toggle()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: isAgeConfirmed ? "checkmark.square.fill" : "square")
                        .font(.title2)
                        .foregroundColor(isAgeConfirmed ? .blue : .secondary)
                    
                    Text("I am 13 years of age or older")
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            
            // Continue button
            Button(action: handleContinue) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        isAgeConfirmed ?
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(
                            colors: [.gray, .gray],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: isAgeConfirmed ? .blue.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
            }
            .disabled(!isAgeConfirmed)
            
            // Legal links
            HStack(spacing: 16) {
                Link("Privacy Policy", destination: URL(string: "https://mshreerang.github.io/book-companion-ios/privacy-policy")!)
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Text("•")
                    .foregroundColor(.secondary)
                
                Link("Terms of Service", destination: URL(string: "https://mshreerang.github.io/book-companion-ios/terms-of-service")!)
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            Spacer()
        }
        .padding(.horizontal, 32)
        .alert("Age Requirement", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("You must confirm that you are 13 years or older to continue.")
        }
    }
    
    private func handleContinue() {
        if isAgeConfirmed {
            AgeVerificationService.shared.confirmAge()
            onContinue()
        } else {
            showingError = true
        }
    }
}
