import SwiftUI

// Utilisation des enums de navigation définis dans NavigationDestinations.swift

struct AislesView: View {
    @StateObject private var viewModel: AislesViewModel
    @State private var showingAddAisle = false
    @State private var searchText = ""
    @State private var editMode: EditMode = .inactive
    @State private var selectedAisleForEdit: Aisle?
    
    // Animation properties
    @State private var listItemsOpacity: [String: Double] = [:]
    @State private var listItemsOffset: [String: CGFloat] = [:]
    
    init(aislesViewModel: AislesViewModel) {
        self._viewModel = StateObject(wrappedValue: aislesViewModel)
    }
    
    var body: some View {
        ZStack {
            Color.backgroundApp.opacity(0.1).ignoresSafeArea()
            
            VStack {
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Chargement des rayons...")
                    Spacer()
                } else if filteredAisles.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "tray.full")
                            .font(.system(size: 70))
                            .foregroundColor(.gray.opacity(0.8))
                        
                        Text(searchText.isEmpty ? "Aucun rayon" : "Aucun résultat pour \"\(searchText)\"")
                            .font(.headline)
                        
                        Text(searchText.isEmpty ? "Créez des rayons pour mieux organiser vos médicaments" : "Essayez une recherche différente")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                        
                        PrimaryButton(title: "Ajouter un rayon", icon: "plus") {
                            showingAddAisle = true
                        }
                        .frame(maxWidth: 250)
                        .padding(.top, 20)
                    }
                    .padding()
                } else {
                    aislesList
                }
            }
            .navigationTitle("Rayons")
            .searchable(text: $searchText, prompt: "Rechercher un rayon")
            // Utilisation de modificateurs distincts pour éviter l'ambiguïté
            .navigationBarItems(
                trailing: HStack(spacing: 15) {
                    
                        Button(action: {
                            showingAddAisle = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                        }
                        .disabled(editMode.isEditing)
                        
                        EditButton()
                    }
                )
            .environment(\.editMode, $editMode)
            
            // Message d'erreur
            if case .error(let message) = viewModel.state {
                VStack {
                    Spacer()
                    
                    MessageView(message: message, type: .error) {
                        viewModel.resetState()
                    }
                    .padding()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .animation(.easeInOut, value: viewModel.state)
                .zIndex(1)
            }
        }
        .sheet(isPresented: $showingAddAisle) {
            AisleFormView(viewModel: viewModel)
        }
        .sheet(item: $selectedAisleForEdit) { aisle in
            AisleFormView(viewModel: viewModel, editingAisle: aisle)
        }
        .onAppear {
            Task {
                await viewModel.fetchAisles()
            }
        }
        .navigationDestination(for: AisleDestination.self) { destination in
            switch destination {
            case .medicinesByAisle(let aisleId):
                MedicinesByAisleView(aisleId: aisleId)
            case .aisleDetail(let aisleId):
                Text("Détail du rayon \(aisleId)") // À implémenter si nécessaire
            case .aisleForm(let aisleId):
                if let id = aisleId {
                    // Utiliser l'aisle directement ou une variable temporaire pour éviter getAisle(by:)
                    AisleFormView(viewModel: viewModel)
                } else {
                    AisleFormView(viewModel: viewModel)
                }
            case .medicineDetail(let medicineId):
                // Utilisation d'un médicament fictif temporaire qui sera remplacé
                // par le vrai médicament lors du chargement dans la vue
                let tempMedicine = Medicine(
                    id: medicineId,
                    name: "",
                    description: "",
                    dosage: "",
                    form: "",
                    reference: "",
                    unit: "",
                    currentQuantity: 0,
                    maxQuantity: 0,
                    warningThreshold: 0,
                    criticalThreshold: 0,
                    expiryDate: nil,
                    aisleId: "",
                    createdAt: Date(),
                    updatedAt: Date()
                )
                
                MedicineDetailView(
                    medicineId: medicineId,
                    viewModel: MedicineDetailViewModel(
                        medicine: tempMedicine,
                        getMedicineUseCase: RealGetMedicineUseCase(medicineRepository: FirebaseMedicineRepository()),
                        updateMedicineStockUseCase: RealUpdateMedicineStockUseCase(
                            medicineRepository: FirebaseMedicineRepository(),
                            historyRepository: FirebaseHistoryRepository()
                        ),
                        deleteMedicineUseCase: RealDeleteMedicineUseCase(medicineRepository: FirebaseMedicineRepository()),
                        getHistoryUseCase: RealGetHistoryForMedicineUseCase(historyRepository: FirebaseHistoryRepository())
                    )
                )
            }
        }
    }
    
    // MARK: - View Components
    
    private var aislesList: some View {
        List {
            ForEach(filteredAisles) { aisle in
                Group {
                    if editMode.isEditing {
                        AisleRowView(aisle: aisle, medicineCount: viewModel.getMedicineCountFor(aisleId: aisle.id))
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedAisleForEdit = aisle
                            }
                    } else {
                        NavigationLink(value: AisleDestination.medicinesByAisle(aisle.id)) {
                            AisleRowView(aisle: aisle, medicineCount: viewModel.getMedicineCountFor(aisleId: aisle.id))
                        }
                        .contentShape(Rectangle())
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        Task {
                            await viewModel.deleteAisle(id: aisle.id)
                        }
                    } label: {
                        Label("Supprimer", systemImage: "trash")
                    }
                    
                    Button {
                        selectedAisleForEdit = aisle
                    } label: {
                        Label("Modifier", systemImage: "pencil")
                    }
                    .tint(.accentApp)
                }
                .opacity(listItemsOpacity[aisle.id, default: 0])
                .offset(x: listItemsOffset[aisle.id, default: 20], y: 0)
                .onAppear {
                    withAnimation(.easeOut(duration: 0.3).delay(Double(getIndex(of: aisle)) * 0.05)) {
                        listItemsOpacity[aisle.id] = 1
                        listItemsOffset[aisle.id] = 0
                    }
                }
            }
            .onDelete { indexSet in
                Task {
                    let idsToDelete = indexSet.map { filteredAisles[$0].id }
                    
                    // Supprimer séquentiellement pour éviter les conflits
                    for id in idsToDelete {
                        await viewModel.deleteAisle(id: id)
                    }
                }
            }
        }
        .listStyle(.plain)
        .refreshable {
            await viewModel.fetchAisles()
        }
    }
    
    // MARK: - Helper Properties and Methods
    
    var filteredAisles: [Aisle] {
        if searchText.isEmpty {
            return viewModel.aisles
        } else {
            return viewModel.aisles.filter { aisle in
                aisle.name.lowercased().contains(searchText.lowercased()) ||
                (aisle.description?.lowercased().contains(searchText.lowercased()) ?? false)
            }
        }
    }
    
    private func getIndex(of aisle: Aisle) -> Int {
        filteredAisles.firstIndex(where: { $0.id == aisle.id }) ?? 0
    }
}


struct AisleRowView: View {
    let aisle: Aisle
    let medicineCount: Int
    
    var body: some View {
        HStack(spacing: 15) {
            // Icône avec taille fixe
            Circle()
                .fill(aisle.color)
                .frame(width: 50, height: 50)
                .overlay {
                    if !aisle.icon.isEmpty {
                        Image(systemName: aisle.icon)
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                    }
                }
            
            // Contenu principal avec hauteur fixe
            VStack(alignment: .leading, spacing: 4) {
                // Nom du rayon
                Text(aisle.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Description avec hauteur réservée
                Group {
                    if let description = aisle.description, !description.isEmpty {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    } else {
                        Text(" ") // Texte invisible pour maintenir l'espace
                            .font(.subheadline)
                    }
                }
                .frame(height: 18, alignment: .top) // Hauteur fixe pour la description
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Compteur avec taille fixe
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(medicineCount)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(aisle.color)
                
                Text("médicaments")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 90, alignment: .trailing) // Largeur fixe pour le compteur
        }
        .frame(height: 70) // Hauteur fixe pour toute la row
        .padding(.horizontal)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}
#Preview {
    let mockViewModel = AislesViewModel(
        getAislesUseCase: MockGetAislesUseCase(),
        addAisleUseCase: MockAddAisleUseCase(),
        updateAisleUseCase: MockUpdateAisleUseCase(),
        deleteAisleUseCase: MockDeleteAisleUseCase(),
        getMedicineCountByAisleUseCase: MockGetMedicineCountByAisleUseCase()
    )
    
    NavigationStack {
        AislesView(aislesViewModel: mockViewModel)
    }
}
