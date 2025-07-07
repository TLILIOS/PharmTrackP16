import SwiftUI

struct MedicinesByAisleViewWrapper: View {
    let aisleId: String
    let appCoordinator: AppCoordinator
    @State private var aisle: Aisle?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Chargement...")
            } else if let aisle = aisle {
                MedicinesByAisleView(aisle: aisle, medicineStockViewModel: appCoordinator.medicineListViewModel)
            } else {
                VStack {
                    Text("Rayon introuvable")
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .task {
            await loadAisle()
        }
    }
    
    private func loadAisle() async {
        do {
            let allAisles = try await appCoordinator.getAislesUseCase.execute()
            aisle = allAisles.first { $0.id == aisleId }
            if aisle == nil {
                errorMessage = "Rayon non trouvé"
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

struct MedicinesByAisleView: View {
    let aisle: Aisle
    @ObservedObject var medicineStockViewModel: MedicineStockViewModel
    @State private var isRefreshing = false
    
    private var medicinesInAisle: [Medicine] {
        medicineStockViewModel.medicines.filter { $0.aisleId == aisle.id }
    }
    
    var body: some View {
        ZStack {
            Color.backgroundApp.opacity(0.1).ignoresSafeArea()
            
            VStack(spacing: 0) {
                if medicinesInAisle.isEmpty {
                    MedicineEmptyStateView(aisle: aisle)
                } else {
                    MedicineGridView(
                        medicines: medicinesInAisle,
                        onRefresh: refreshData
                    )
                }
            }
            .navigationTitle(aisle.name)
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            Task {
                await loadMedicines()
            }
        }
    }
    
    private func loadMedicines() async {
        await medicineStockViewModel.fetchMedicines()
    }
    
    private func refreshData() async {
        isRefreshing = true
        await medicineStockViewModel.fetchMedicines()
        isRefreshing = false
    }
}

struct MedicineEmptyStateView: View {
    let aisle: Aisle
    @EnvironmentObject var appCoordinator: AppCoordinator
    
    var body: some View {
        VStack(spacing: 20) {
            Circle()
                .fill(aisle.color)
                .frame(width: 80, height: 80)
                .overlay {
                    if !aisle.icon.isEmpty {
                        Image(systemName: aisle.icon)
                            .font(.system(size: 35))
                            .foregroundColor(.white)
                    }
                }
            
            Text("Aucun médicament dans ce rayon")
                .font(.headline)
            
            Text("Commencez par ajouter des médicaments au rayon \"\(aisle.name)\"")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            
            PrimaryButton(
                title: "Ajouter un médicament",
                icon: "plus"
            ) {
                appCoordinator.medicineNavigationPath.append(.medicineForm(nil))
            }
            .frame(maxWidth: 250)
            .padding(.top, 10)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    let mockAisle = Aisle(
        id: "aisle-1",
        name: "Analgésiques",
        description: "Médicaments contre la douleur",
        colorHex: "#007AFF",
        icon: "pills"
    )
    
    MedicinesByAisleView(
        aisle: mockAisle,
        medicineStockViewModel: MedicineStockViewModel()
    )
    .environmentObject(AppCoordinator.preview)
}