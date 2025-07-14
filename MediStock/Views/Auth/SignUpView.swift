import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var authViewModel: AuthViewModel
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var name: String = ""
    @State private var showPassword: Bool = false
    @State private var showConfirmPassword: Bool = false
    
    // Animation properties
    @State private var headingOpacity: CGFloat = 0
    @State private var formOffset: CGFloat = 30
    @State private var formOpacity: CGFloat = 0
    @State private var buttonsOffset: CGFloat = 30
    @State private var buttonsOpacity: CGFloat = 0
    
    // Validation
    @State private var emailError: String? = nil
    @State private var passwordError: String? = nil
    @State private var confirmPasswordError: String? = nil
    
    private var emailValidationError: String? {
        guard !email.isEmpty else { return nil }
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return !emailPredicate.evaluate(with: email) ? "Email invalide" : nil
    }

    private var passwordValidationError: String? {
        guard !password.isEmpty else { return nil }
        return password.count < 6 ? "Minimum 6 caractères" : nil
    }

    private var confirmPasswordValidationError: String? {
        guard !confirmPassword.isEmpty else { return nil }
        return password != confirmPassword ? "Les mots de passe ne correspondent pas" : nil
    }

    private var isFormValid: Bool {
        return emailValidationError == nil &&
               passwordValidationError == nil &&
               confirmPasswordValidationError == nil &&
               !name.isEmpty &&
               !email.isEmpty &&
               !password.isEmpty &&
               !confirmPassword.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundApp.opacity(0.1).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        SignUpHeaderView(headingOpacity: headingOpacity)
                        
                        SignUpFormView(
                            name: $name,
                            email: $email,
                            password: $password,
                            confirmPassword: $confirmPassword,
                            showPassword: $showPassword,
                            showConfirmPassword: $showConfirmPassword,
                            emailValidationError: emailValidationError,
                            passwordError: passwordValidationError,
                            confirmPasswordError: confirmPasswordValidationError,
                            formOffset: formOffset,
                            formOpacity: formOpacity
                        )
                        
                        SignUpErrorView(
                            authViewModel: authViewModel
                        )
                        
                        SignUpButtonsView(
                            authViewModel: authViewModel,
                            isFormValid: isFormValid,
                            email: email,
                            password: password,
                            confirmPassword: confirmPassword,
                            name: name,
                            buttonsOffset: buttonsOffset,
                            buttonsOpacity: buttonsOpacity,
                            onDismiss: { dismiss() }
                        )
                    }
                    .padding(.horizontal, 10)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.accentApp)
                            .fontWeight(.semibold)
                    }
                }
            }
            .onAppear {
                startAnimations()
            }
            .onChange(of: authViewModel.isAuthenticated) {
                if authViewModel.isAuthenticated {
                    dismiss()
                }
            }
        }
    }
    
    private func startAnimations() {
        withAnimation(.easeOut(duration: 0.5)) {
            headingOpacity = 1
        }
        
        withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
            formOffset = 0
            formOpacity = 1
        }
        
        withAnimation(.easeOut(duration: 0.6).delay(0.4)) {
            buttonsOffset = 0
            buttonsOpacity = 1
        }
    }
}

// MARK: - Header View
struct SignUpHeaderView: View {
    let headingOpacity: CGFloat
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Créer un compte")
                .font(.largeTitle.bold())
                .foregroundColor(.primary)
            
            Text("Rejoignez MediStock pour gérer efficacement votre stock de médicaments")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.top, 20)
        .opacity(headingOpacity)
    }
}

// MARK: - Form View
struct SignUpFormView: View {
    @Binding var name: String
    @Binding var email: String
    @Binding var password: String
    @Binding var confirmPassword: String
    @Binding var showPassword: Bool
    @Binding var showConfirmPassword: Bool
    let emailValidationError: String?
    let passwordError: String?
    let confirmPasswordError: String?
    let formOffset: CGFloat
    let formOpacity: CGFloat
    
    var body: some View {
        VStack(spacing: 20) {
            StyledTextField(
                title: "Nom",
                placeholder: "Votre nom complet",
                icon: "person",
                text: $name
            )
            
            StyledTextField(
                title: "Email",
                placeholder: "votre@email.com",
                icon: "envelope",
                keyboardType: .emailAddress,
                errorMessage: emailValidationError,
                text: $email
            )
            
            PasswordFieldView(
                title: "Mot de passe",
                icon: "lock",
                password: $password,
                showPassword: $showPassword,
                errorMessage: passwordError
            )
            
            PasswordFieldView(
                title: "Confirmer le mot de passe",
                icon: "lock.shield",
                password: $confirmPassword,
                showPassword: $showConfirmPassword,
                errorMessage: confirmPasswordError
            )
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .offset(y: formOffset)
        .opacity(formOpacity)
    }
}

// MARK: - Password Field View
struct PasswordFieldView: View {
    let title: String
    let icon: String
    @Binding var password: String
    @Binding var showPassword: Bool
    let errorMessage: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.gray)
                    .frame(width: 20)
                
                if showPassword {
                    TextField("••••••••", text: $password)
                } else {
                    SecureField("••••••••", text: $password)
                }
                
                Button(action: { showPassword.toggle() }) {
                    Image(systemName: showPassword ? "eye.slash" : "eye")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(errorMessage != nil ? Color.red : Color.clear, lineWidth: 1)
            )
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 4)
            }
        }
    }
}

// MARK: - Error View
struct SignUpErrorView: View {
    let authViewModel: AuthViewModel
    
    var body: some View {
        Group {
            if let errorMessage = authViewModel.errorMessage {
                MessageView(message: errorMessage, type: .error, dismissAction: {
                    authViewModel.errorMessage = nil
                })
                .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Buttons View
struct SignUpButtonsView: View {
    let authViewModel: AuthViewModel
    let isFormValid: Bool
    let email: String
    let password: String
    let confirmPassword: String
    let name: String
    let buttonsOffset: CGFloat
    let buttonsOpacity: CGFloat
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 15) {
            PrimaryButton(
                title: "Créer un compte",
                icon: "person.badge.plus",
                isLoading: authViewModel.isLoading
            ) {
                if isFormValid {
                    Task {
                        authViewModel.email = email
                        authViewModel.password = password
                        authViewModel.confirmPassword = confirmPassword
                        authViewModel.displayName = name
                        await authViewModel.signUp()
                    }
                }
            }
            
            Button(action: onDismiss) {
                Text("Déjà un compte ? Se connecter")
                    .font(.subheadline.bold())
                    .foregroundColor(.accentApp)
            }
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .offset(y: buttonsOffset)
        .opacity(buttonsOpacity)
    }
}

#Preview {
    let authRepository = FirebaseAuthRepository()
    let signInUseCase = SignInUseCase(authRepository: authRepository)
    let signUpUseCase = SignUpUseCase(authRepository: authRepository)
    let authViewModel = AuthViewModel(
        signInUseCase: signInUseCase,
        signUpUseCase: signUpUseCase,
        authRepository: authRepository
    )
    
    SignUpView(authViewModel: authViewModel)
}
