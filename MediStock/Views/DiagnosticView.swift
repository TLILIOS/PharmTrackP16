import SwiftUI

// MARK: - Vue de diagnostic pour débugger le problème d'affichage

struct DiagnosticView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var medicineListViewModel: MedicineListViewModel
    @EnvironmentObject var aisleListViewModel: AisleListViewModel
    
    var body: some View {
        Form {
            Section("AppState") {
                Text("Is authenticated: \(appState.isAuthenticated ? "Yes" : "No")")
                Text("Is loading: \(appState.isLoading ? "Yes" : "No")")
                if let error = appState.errorMessage {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                }
                if let user = appState.currentUser {
                    Text("User: \(user.displayName ?? "No name")")
                }
            }
            
            Section("MedicineListViewModel") {
                Text("Medicines count: \(medicineListViewModel.medicines.count)")
                Text("Filtered count: \(medicineListViewModel.filteredMedicines.count)")
                Text("Is loading: \(medicineListViewModel.isLoading ? "Yes" : "No")")
                if let error = medicineListViewModel.errorMessage {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                }
            }
            
            Section("AisleListViewModel") {
                Text("Aisles count: \(aisleListViewModel.aisles.count)")
                Text("Is loading: \(aisleListViewModel.isLoading ? "Yes" : "No")")
                if let error = aisleListViewModel.errorMessage {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                }
            }
            
            Section("Actions") {
                Button("Load ViewModel Data") {
                    Task {
                        await medicineListViewModel.loadMedicines()
                        await aisleListViewModel.loadAisles()
                    }
                }
            }
        }
        .navigationTitle("Diagnostic")
    }
}