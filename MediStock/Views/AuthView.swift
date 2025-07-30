import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var displayName = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Logo
                Image(systemName: "pills.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.accentColor)
                    .padding(.top, 50)
                
                Text("MediStock")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                // Formulaire
                VStack(spacing: 15) {
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .formFieldAccessibility(label: "Adresse email", hint: "Entrez votre adresse email")
                        .accessibilityIdentifier(AccessibilityIdentifiers.emailField)
                        .dynamicTypeAccessibility()
                    
                    SecureField("Mot de passe", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(isSignUp ? .newPassword : .password)
                        .formFieldAccessibility(label: "Mot de passe", hint: isSignUp ? "Créez un mot de passe sécurisé" : "Entrez votre mot de passe")
                        .accessibilityIdentifier(AccessibilityIdentifiers.passwordField)
                        .dynamicTypeAccessibility()
                    
                    if isSignUp {
                        // Indicateur de force du mot de passe
                        if !password.isEmpty {
                            HStack {
                                Text("Force du mot de passe:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(password.passwordStrength.label)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(passwordStrengthColor)
                                Spacer()
                            }
                            
                            ProgressView(value: Double(password.passwordStrength.rawValue + 1), total: 5)
                                .tint(passwordStrengthColor)
                                .scaleEffect(x: 1, y: 0.5)
                        }
                        
                        SecureField("Confirmer le mot de passe", text: $confirmPassword)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.newPassword)
                        
                        TextField("Nom d'affichage", text: $displayName)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                .padding(.horizontal)
                
                // Boutons
                VStack(spacing: 10) {
                    Button(action: authenticate) {
                        if authViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text(isSignUp ? "S'inscrire" : "Se connecter")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(!isFormValid || authViewModel.isLoading)
                    
                    Button(action: { isSignUp.toggle() }) {
                        Text(isSignUp ? "Déjà un compte ? Se connecter" : "Pas de compte ? S'inscrire")
                            .foregroundColor(.accentColor)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationBarHidden(true)
        }
    }
    
    private var isFormValid: Bool {
        email.isValidEmail && 
        password.count >= 6 &&
        (!isSignUp || (password == confirmPassword && !displayName.isEmpty))
    }
    
    private var passwordStrengthColor: Color {
        switch password.passwordStrength {
        case .veryWeak: return .red
        case .weak: return .orange
        case .medium: return .yellow
        case .strong: return .green
        case .veryStrong: return .blue
        }
    }
    
    private func authenticate() {
        Task {
            if isSignUp {
                await authViewModel.signUp(email: email, password: password, displayName: displayName)
            } else {
                await authViewModel.signIn(email: email, password: password)
            }
        }
    }
}