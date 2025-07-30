import SwiftUI

// MARK: - Extensions pour gérer les erreurs de validation dans les ViewModels

extension ObservableObject where Self: AnyObject {
    /// Convertit une erreur en message utilisateur approprié
    func handleError(_ error: Error) -> String {
        if let validationError = error as? ValidationError {
            // Les erreurs de validation ont déjà des messages localisés
            return validationError.localizedDescription
        } else if let authError = error as? AuthError {
            return authError.localizedDescription
        } else {
            // Erreur générique
            return "Une erreur s'est produite : \(error.localizedDescription)"
        }
    }
}

// MARK: - Alert Helper pour afficher les erreurs de validation

struct ValidationErrorAlert: ViewModifier {
    @Binding var error: ValidationError?
    
    func body(content: Content) -> some View {
        content
            .alert("Erreur de validation", isPresented: .constant(error != nil)) {
                Button("OK") {
                    error = nil
                }
            } message: {
                if let error = error {
                    Text(error.localizedDescription)
                }
            }
    }
}

extension View {
    func validationErrorAlert(error: Binding<ValidationError?>) -> some View {
        modifier(ValidationErrorAlert(error: error))
    }
}

// MARK: - Toast Helper pour afficher les succès/erreurs

struct ToastMessage: Equatable {
    let message: String
    let isError: Bool
}

struct ToastModifier: ViewModifier {
    @Binding var toast: ToastMessage?
    @State private var workItem: DispatchWorkItem?
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let toast = toast {
                    VStack {
                        HStack {
                            Image(systemName: toast.isError ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                                .foregroundColor(.white)
                            
                            Text(toast.message)
                                .foregroundColor(.white)
                                .font(.body)
                            
                            Spacer()
                        }
                        .padding()
                        .background(toast.isError ? Color.red : Color.green)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .padding(.horizontal)
                        .padding(.top, 50)
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.3), value: self.toast)
                    .onTapGesture {
                        dismissToast()
                    }
                }
            }
            .onChange(of: toast) {
                showToast()
            }
    }
    
    private func showToast() {
        guard toast != nil else { return }
        
        workItem?.cancel()
        
        let task = DispatchWorkItem {
            dismissToast()
        }
        
        workItem = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: task)
    }
    
    private func dismissToast() {
        withAnimation {
            toast = nil
        }
        workItem?.cancel()
        workItem = nil
    }
}

extension View {
    func toast(message: Binding<ToastMessage?>) -> some View {
        modifier(ToastModifier(toast: message))
    }
}