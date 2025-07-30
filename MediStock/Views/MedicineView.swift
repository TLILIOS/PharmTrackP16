import SwiftUI

// MARK: - Vue Médicaments corrigée utilisant AppState

struct MedicineListView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingAddForm = false
    @State private var showingSearchView = false
    
    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Médicaments")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showingAddForm = true }) {
                            Image(systemName: "plus")
                        }
                    }
                }
                .sheet(isPresented: $showingAddForm) {
                    NavigationStack {
                        MedicineFormView(medicine: nil)
                            .environmentObject(appState)
                    }
                }
                .navigationDestination(for: MedicineDestination.self) { destination in
                    switch destination {
                    case .add:
                        MedicineFormView(medicine: nil)
                            .environmentObject(appState)
                    case .detail(let medicine):
                        MedicineDetailView(medicine: medicine)
                            .environmentObject(appState)
                    case .edit(let medicine):
                        MedicineFormView(medicine: medicine)
                            .environmentObject(appState)
                    case .adjustStock(let medicine):
                        StockAdjustmentView(medicine: medicine)
                            .environmentObject(appState)
                    }
                }
                .onAppear {
                    // S'assurer que les données sont chargées
                    if appState.medicines.isEmpty && !appState.isLoading {
                        Task {
                            await appState.loadData()
                        }
                    }
                }
        }
    }
    
    @ViewBuilder
    private var content: some View {
        if appState.isLoading && appState.medicines.isEmpty {
            loadingView
        } else if appState.medicines.isEmpty {
            emptyView
        } else {
            medicinesList
        }
    }
    
    private var loadingView: some View {
        ProgressView("Chargement des médicaments...")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "pills")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("Aucun médicament")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Ajoutez votre premier médicament pour commencer")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button(action: { showingAddForm = true }) {
                Label("Ajouter un médicament", systemImage: "plus.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
        .padding()
    }
    
    private var medicinesList: some View {
        ScrollView {
            VStack(spacing: 0) {
                searchAndFilterBar
                
                // Nombre de résultats
                if !appState.searchText.isEmpty || appState.selectedAisleId != nil {
                    HStack {
                        Text("\(appState.filteredMedicines.count) résultat(s)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal)
                }
                
                // Liste des médicaments
                LazyVStack(spacing: 0) {
                    ForEach(appState.filteredMedicines) { medicine in
                        NavigationLink(value: MedicineDestination.detail(medicine)) {
                            MedicineRow(medicine: medicine)
                        }
                        .buttonStyle(.plain)
                        .onAppear {
                            // Pagination
                            if medicine.id == appState.filteredMedicines.last?.id {
                                Task {
                                    await appState.loadMoreMedicines()
                                }
                            }
                        }
                        
                        Divider()
                    }
                    
                    // Indicateur de chargement pour pagination
                    if appState.isLoadingMore {
                        ProgressView()
                            .padding()
                    }
                }
            }
        }
        .refreshable {
            await appState.loadData()
        }
    }
    
    private var searchAndFilterBar: some View {
        VStack(spacing: 10) {
            // Barre de recherche
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Rechercher...", text: $appState.searchText)
                    .textFieldStyle(.plain)
                
                if !appState.searchText.isEmpty {
                    Button(action: { appState.searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            // Filtre par rayon
            if !appState.aisles.isEmpty {
                Picker("Rayon", selection: $appState.selectedAisleId) {
                    Text("Tous les rayons").tag(String?.none)
                    ForEach(appState.aisles) { aisle in
                        Label(aisle.name, systemImage: aisle.icon)
                            .tag(String?.some(aisle.id))
                    }
                }
                .pickerStyle(.menu)
            }
        }
        .padding()
    }
}