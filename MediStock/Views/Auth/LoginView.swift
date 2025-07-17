import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel: AuthViewModel
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isShowingSignUp = false
    @State private var showPassword: Bool = false
    
    // Animation properties
    @State private var logoScale: CGFloat = 0.8
    @State private var formOpacity: CGFloat = 0
    @State private var formOffset: CGFloat = 50
    
    init(authViewModel: AuthViewModel) {
        self._viewModel = StateObject(wrappedValue: authViewModel)
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.accentApp.opacity(0.8), Color.backgroundApp]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Main content
            VStack(spacing: 20) {
                // Logo
                VStack(spacing: 5) {
                    Image(systemName: "cross.case")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            Circle()
                                .fill(Color.accentApp)
                                .shadow(color: .black.opacity(0.3), radius: 10)
                        )
                        .scaleEffect(logoScale)
                    
                    Text("MediStock")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .padding(.top, 8)
                    
                    Text("Gestion de stock pharmaceutique")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 20)
                }
                .padding(.top, 40)
                
                // Form
                VStack(spacing: 25) {
                    StyledTextField(
                        title: "Email",
                        placeholder: "votre@email.com",
                        icon: "envelope",
                        keyboardType: .emailAddress,
                        errorMessage: viewModel.errorMessage,
                        text: $email
                    )
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Mot de passe")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack {
                            Image(systemName: "lock")
                                .foregroundColor(.gray)
                                .frame(width: 20)
                            
                            if showPassword {
                                TextField("Entrez votre mot de passe", text: $password)
                                    .textContentType(.password)
                            } else {
                                SecureField("Entrez votre mot de passe", text: $password)
                                    .textContentType(.password)
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
                                .stroke(viewModel.errorMessage != nil ? Color.red : Color.clear, lineWidth: 1)
                        )
                        
                        if viewModel.errorMessage != nil {
                            Text("Mot de passe incorrect")
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal, 4)
                        }
                    }
                    
                    // Error message
                    if let errorMessage = viewModel.errorMessage {
                        MessageView(message: errorMessage, type: .error) {
                            viewModel.errorMessage = nil
                        }
                    }
                    
                    // Login Button
                    PrimaryButton(
                        title: "Se connecter",
                        icon: "arrow.right",
                        isLoading: viewModel.isLoading,
                        isDisabled: email.isEmpty || password.isEmpty
                    ) {
                        Task {
                            viewModel.email = email; viewModel.password = password; await viewModel.signIn()
                        }
                    }
                    .padding(.top, 10)
                    // Registration link
                    Button(action: {
                        print("🔄 Button tapped - Setting isShowingSignUp to true")
                        isShowingSignUp = true
                    }) {
                        HStack(spacing: 5) {
                            Text("Vous n'avez pas de compte ?")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("S'inscrire")
                                .font(.subheadline.bold())
                                .foregroundColor(Color.accentApp)
                        }
                    }
                    .padding(.top, 20)

                }
                .padding(.horizontal, 30)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.1), radius: 10)
                )
                .padding(.horizontal, 20)
                .opacity(formOpacity)
                .offset(y: formOffset)
                
                Spacer()
            }
        }
        .sheet(isPresented: $isShowingSignUp) {
            SignUpView(authViewModel: viewModel)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
                logoScale = 1.0
            }
            
            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                formOpacity = 1
                formOffset = 0
            }
        }
        .onChange(of: isShowingSignUp) {
            print("🔍 isShowingSignUp changed to: \(isShowingSignUp)")
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
    
    LoginView(authViewModel: authViewModel)
}

