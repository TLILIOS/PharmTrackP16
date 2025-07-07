import SwiftUI

struct StyledTextField: View {
    let title: String
    let placeholder: String
    let icon: String?
    let keyboardType: UIKeyboardType
    @Binding var text: String
    var isSecure: Bool = false
    var errorMessage: String? = nil
    
    init(
        title: String,
        placeholder: String,
        icon: String? = nil,
        keyboardType: UIKeyboardType = .default,
        isSecure: Bool = false,
        errorMessage: String? = nil,
        text: Binding<String>
    ) {
        self.title = title
        self.placeholder = placeholder
        self.icon = icon
        self.keyboardType = keyboardType
        self._text = text
        self.isSecure = isSecure
        self.errorMessage = errorMessage
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(.gray)
                        .frame(width: 20)
                }
                
                if isSecure {
                    SecureField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                        .autocapitalization(keyboardType == .emailAddress ? .none : .sentences)
                        .disableAutocorrection(keyboardType == .emailAddress)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                        .autocapitalization(keyboardType == .emailAddress ? .none : .sentences)
                        .disableAutocorrection(keyboardType == .emailAddress)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(errorMessage != nil ? Color.red : Color.clear, lineWidth: 1)
            )
            
            if let errorMessage = errorMessage, !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 4)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        StyledTextField(
            title: "Email",
            placeholder: "votre@email.com",
            icon: "envelope",
            keyboardType: .emailAddress,
            text: .constant("")
        )
        
        StyledTextField(
            title: "Mot de passe",
            placeholder: "••••••••",
            icon: "lock",
            isSecure: true,
            text: .constant("")
        )
        
        StyledTextField(
            title: "Nom d'utilisateur",
            placeholder: "Entrez votre nom",
            icon: "person",
            errorMessage: "Le nom d'utilisateur est requis",
            text: .constant("")
        )
    }
    .padding()
}
