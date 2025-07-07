import SwiftUI

struct AislesView: View {
    @StateObject private var viewModel: AislesViewModel
    @State private var showingAddAisle = false
    @State private var searchText = ""
    @State private var isRefreshing = false
    @State private var editMode: EditMode = .inactive
    @State private var selectedAisleForEdit: Aisle?
    
    // Animation properties
    @State private var listItemsOpacity: [String: Double] = [:]
    @State private var listItemsOffset: [String: CGFloat] = [:]
    @Namespace private var aisleAnimation
    
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
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddAisle = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                    
                    EditButton()
                }
            }
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
    }
    
    // MARK: - View Components
    
    private var aislesList: some View {
        List {
            ForEach(filteredAisles) { aisle in
                AisleRowView(aisle: aisle, medicineCount: viewModel.getMedicineCountFor(aisleId: aisle.id))
                    .contentShape(Rectangle())
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
                    .onTapGesture {
                        if editMode.isEditing {
                            selectedAisleForEdit = aisle
                        }
                    }
            }
            .onDelete { indexSet in
                // Récupérer les IDs des rayons à supprimer
                let idsToDelete = indexSet.map { filteredAisles[$0].id }
                
                // Supprimer chaque rayon
                for id in idsToDelete {
                    Task {
                        await viewModel.deleteAisle(id: id)
                    }
                }
            }
        }
        .listStyle(.plain)
        .refreshable {
            isRefreshing = true
            await viewModel.fetchAisles()
            isRefreshing = false
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
    @EnvironmentObject var appCoordinator: AppCoordinator
    
    var body: some View {
        Button(action: {
            appCoordinator.navigateTo(.medicinesByAisle(aisle.id))
        }) {
            HStack(spacing: 15) {
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
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(aisle.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let description = aisle.description, !description.isEmpty {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(medicineCount)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(aisle.color)
                    
                    Text("médicaments")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
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
    
    AislesView(aislesViewModel: mockViewModel)
}
