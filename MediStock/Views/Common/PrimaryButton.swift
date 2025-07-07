import SwiftUI

struct PrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    let isLoading: Bool
    let isDisabled: Bool
    
    init(
        title: String,
        icon: String? = nil,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .padding(.trailing, 8)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.body.bold())
                        .padding(.trailing, 8)
                }
                
                Text(title)
                    .font(.body.bold())
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isDisabled || isLoading ? Color.gray : Color.accentApp)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .disabled(isDisabled || isLoading)
    }
}

#Preview {
    VStack(spacing: 20) {
        PrimaryButton(title: "Bouton Normal", icon: "checkmark") {
            // Action
        }
        
        PrimaryButton(title: "Bouton en Chargement", icon: "arrow.clockwise", isLoading: true) {
            // Action
        }
        
        PrimaryButton(title: "Bouton Désactivé", isDisabled: true) {
            // Action
        }
    }
    .padding()
}
