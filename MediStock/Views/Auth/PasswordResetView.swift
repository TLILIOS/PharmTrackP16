import SwiftUI

struct PasswordResetView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: AuthViewModel
    @State private var email: String = ""
    @State private var resetSent: Bool = false
    
    // Animation properties
    @State private var formOpacity: CGFloat = 0
    @State private var formOffset: CGFloat = 30
    @State private var iconScale: CGFloat = 0.5
    
    private var isEmailValid: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundApp.opacity(0.1).ignoresSafeArea()
                
                VStack(spacing: 25) {
                    // Icon and heading
                    VStack(spacing: 15) {
                        Image(systemName: resetSent ? "checkmark.circle.fill" : "lock.rotation")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 70, height: 70)
                            .foregroundColor(resetSent ? .successColor : .accentApp)
                            .padding()
                            .background(
                                Circle()
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.1), radius: 8)
                            )
                            .scaleEffect(iconScale)
                        
                        Text(resetSent ? "Email envoyé !" : "Réinitialiser le mot de passe")
                            .font(.title2.bold())
                            .foregroundColor(.primary)
                        
                        Text(resetSent ?
                             "Consultez votre boîte mail pour suivre les instructions de réinitialisation" :
                             "Entrez votre adresse email pour recevoir un lien de réinitialisation")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .padding(.top, 40)
                    
                    if !resetSent {
                        // Email input form
                        VStack(spacing: 20) {
                            StyledTextField(
                                title: "Email",
                                placeholder: "votre@email.com",
                                icon: "envelope",
                                keyboardType: .emailAddress,
                                text: $email
                            )
                            
                            if let errorMessage = viewModel.errorMessage {
                                MessageView(message: errorMessage, type: .error) {
                                    viewModel.errorMessage = nil
                                }
                            }
                            
                            if viewModel.resetEmailSent {
                                MessageView(message: "Lien de réinitialisation envoyé à votre email", type: .success) {
                                    viewModel.resetEmailSent = false
                                }
                            }
                            
                            PrimaryButton(
                                title: "Envoyer le lien",
                                icon: "paperplane",
                                isLoading: viewModel.isLoading,
                                isDisabled: !isEmailValid
                            ) {
                                Task {
                                    viewModel.email = email; await viewModel.resetPassword()
                                    if viewModel.resetEmailSent {
                                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                            resetSent = true
                                            iconScale = 1.1
                                        }
                                        
                                        withAnimation(.spring().delay(0.1)) {
                                            iconScale = 1.0
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .opacity(formOpacity)
                        .offset(y: formOffset)
                    } else {
                        // Success view
                        VStack(spacing: 20) {
                            MessageView(
                                message: "Si un compte existe avec cette adresse email, vous recevrez un email de réinitialisation.",
                                type: .success
                            )
                            
                            PrimaryButton(title: "Retour à la connexion") {
                                dismiss()
                            }
                        }
                        .padding(.horizontal, 20)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 10)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .onAppear {
                startAnimations()
            }
        }
    }
    
    private func startAnimations() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
            iconScale = 1.0
        }
        
        withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
            formOpacity = 1
            formOffset = 0
        }
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
    
    PasswordResetView(viewModel: authViewModel)
}
