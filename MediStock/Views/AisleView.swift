import SwiftUI

// MARK: - Vue Rayons corrigée utilisant uniquement les ViewModels

struct AisleListView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingAddForm = false
    
    var body: some View {
        Group {
            if appState.isLoading && appState.aisles.isEmpty {
                // Chargement initial
                ProgressView("Chargement des rayons...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if appState.aisles.isEmpty {
                // État vide
                VStack(spacing: 20) {
                    Spacer()
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("Aucun rayon")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Créez votre premier rayon pour organiser vos médicaments")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Button(action: { showingAddForm = true }) {
                        Label("Créer un rayon", systemImage: "plus.circle.fill")
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                    Spacer()
                }
                .padding()
            } else {
                // Liste des rayons
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(appState.aisles) { aisle in
                            NavigationLink {
                                AisleDetailView(aisle: aisle)
                                    .environmentObject(appState)
                            } label: {
                                AisleRow(aisle: aisle)
                            }
                            .buttonStyle(.plain)
                            .onAppear {
                                // Pagination
                                if aisle.id == appState.aisles.last?.id {
                                    Task {
                                        await appState.loadMoreAisles()
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
                .refreshable {
                    await appState.loadData()
                }
            }
        }
        .navigationTitle("Rayons")
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
                AisleFormView(aisle: nil)
                    .environmentObject(appState)
            }
        }
        .onAppear {
            // S'assurer que les données sont chargées
            if appState.aisles.isEmpty && !appState.isLoading {
                Task {
                    await appState.loadData()
                }
            }
        }
    }
}

// MARK: - Ligne de rayon

struct AisleRow: View {
    let aisle: Aisle
    @EnvironmentObject var appState: AppState
    
    private var medicineCount: Int {
        appState.medicines.filter { $0.aisleId == aisle.id }.count
    }
    
    private var criticalCount: Int {
        appState.medicines
            .filter { $0.aisleId == aisle.id && $0.stockStatus == .critical }
            .count
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Icône du rayon
            Image(systemName: aisle.icon)
                .font(.title2)
                .foregroundColor(aisle.color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(aisle.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack(spacing: 8) {
                    Text("\(medicineCount) médicament\(medicineCount > 1 ? "s" : "")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if criticalCount > 0 {
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Label("\(criticalCount) critique\(criticalCount > 1 ? "s" : "")", 
                              systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                            .labelStyle(.titleOnly)
                    }
                }
                
                if let description = aisle.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .contentShape(Rectangle())
    }
}

// MARK: - Détail d'un rayon

struct AisleDetailView: View {
    let aisle: Aisle
    @EnvironmentObject var appState: AppState
    @State private var showingEditForm = false
    @State private var showingDeleteAlert = false
    @Environment(\.dismiss) var dismiss
    
    private var medicines: [Medicine] {
        appState.medicines.filter { $0.aisleId == aisle.id }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // En-tête
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: aisle.icon)
                            .font(.largeTitle)
                            .foregroundColor(aisle.color)
                        
                        VStack(alignment: .leading) {
                            Text(aisle.name)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text("\(medicines.count) médicament\(medicines.count > 1 ? "s" : "")")
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    if let description = aisle.description {
                        Text(description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(aisle.color.opacity(0.1))
                .cornerRadius(15)
                
                // Statistiques
                HStack(spacing: 15) {
                    StatCard(
                        title: "Total",
                        value: "\(medicines.count)",
                        icon: "pills",
                        color: aisle.color
                    )
                    
                    StatCard(
                        title: "Critique",
                        value: "\(medicines.filter { $0.stockStatus == .critical }.count)",
                        icon: "exclamationmark.triangle",
                        color: .red
                    )
                    
                    StatCard(
                        title: "Expirant",
                        value: "\(medicines.filter { $0.isExpiringSoon }.count)",
                        icon: "clock",
                        color: .orange
                    )
                }
                
                // Liste des médicaments
                if !medicines.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Médicaments")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        LazyVStack(spacing: 0) {
                            ForEach(medicines) { medicine in
                                NavigationLink(value: MedicineDestination.detail(medicine)) {
                                    MedicineRow(medicine: medicine)
                                }
                                .buttonStyle(.plain)
                                
                                if medicine.id != medicines.last?.id {
                                    Divider()
                                        .padding(.leading)
                                }
                            }
                        }
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingEditForm = true }) {
                        Label("Modifier", systemImage: "pencil")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive, action: { showingDeleteAlert = true }) {
                        Label("Supprimer", systemImage: "trash")
                    }
                    .disabled(!medicines.isEmpty)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditForm) {
            NavigationStack {
                AisleFormView(aisle: aisle)
                    .environmentObject(appState)
            }
        }
        .alert("Supprimer ce rayon ?", isPresented: $showingDeleteAlert) {
            Button("Annuler", role: .cancel) {}
            Button("Supprimer", role: .destructive) {
                Task {
                    await appState.deleteAisle(aisle)
                    dismiss()
                }
            }
        } message: {
            Text("Cette action est irréversible. Assurez-vous qu'aucun médicament n'est associé à ce rayon.")
        }
        .navigationDestination(for: MedicineDestination.self) { destination in
            switch destination {
            case .detail(let medicine):
                MedicineDetailView(medicine: medicine)
                    .environmentObject(appState)
            case .edit(let medicine):
                MedicineFormView(medicine: medicine)
                    .environmentObject(appState)
            case .adjustStock(let medicine):
                StockAdjustmentView(medicine: medicine)
                    .environmentObject(appState)
            case .add:
                MedicineFormView(medicine: nil)
                    .environmentObject(appState)
            }
        }
    }
}

// MARK: - Carte de statistique

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}
