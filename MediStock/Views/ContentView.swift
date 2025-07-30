import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                MainView()
            } else {
                AuthView()
            }
        }
        .alert("Erreur", isPresented: .constant(authViewModel.errorMessage != nil)) {
            Button("OK") {
                authViewModel.clearError()
            }
        } message: {
            Text(authViewModel.errorMessage ?? "")
        }
    }
}