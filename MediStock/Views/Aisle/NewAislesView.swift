import SwiftUI
import Combine

struct NewAislesView: View {
    @Environment(\.viewModelCreator) private var viewModelCreator
    @State private var viewModel: ObservableAisleViewModel?
    @State private var showingAddAisle = false
    @State private var searchText = ""
    @State private var editMode: EditMode = .inactive
    @State private var selectedAisleForEdit: Aisle?
    
    // Animation properties
    @State private var listItemsOpacity: [String: Double] = [:]
    @State private var listItemsOffset: [String: CGFloat] = [:]
    
    var body: some View {
        ZStack {
            Color.backgroundApp.opacity(0.1).ignoresSafeArea()
            
            VStack {
                if viewModel?.isLoading == true {
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
        }
        .navigationTitle("Rayons")
        .searchable(text: $searchText, prompt: "Rechercher un rayon...")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingAddAisle = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddAisle) {
            NavigationView {
                SimpleAisleFormView(aisle: nil) { aisle in
                    Task {
                        await viewModel?.addAisle(aisle)
                    }
                }
            }
        }
        .sheet(item: $selectedAisleForEdit) { aisle in
            NavigationView {
                SimpleAisleFormView(aisle: aisle) { updatedAisle in
                    Task {
                        await viewModel?.updateAisle(updatedAisle)
                    }
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = ObservableAisleViewModel(
                    aisleRepository: viewModelCreator.aisleRepository,
                    medicineRepository: viewModelCreator.medicineRepository
                )
            }
        }
        .task {
            await viewModel?.loadAisles()
            startAnimations()
        }
        .refreshable {
            await viewModel?.refreshData()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("AisleAdded"))) { _ in
            Task {
                await viewModel?.loadAisles()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("AisleUpdated"))) { _ in
            Task {
                await viewModel?.loadAisles()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("AisleDeleted"))) { _ in
            Task {
                await viewModel?.loadAisles()
            }
        }
        .alert("Erreur", isPresented: .constant(viewModel?.errorMessage != nil)) {
            Button("OK") {
                viewModel?.resetError()
            }
        } message: {
            Text(viewModel?.errorMessage ?? "")
        }
    }
    
    // MARK: - Computed Properties
    private var filteredAisles: [Aisle] {
        guard let viewModel = viewModel else { return [] }
        
        if searchText.isEmpty {
            return viewModel.sortedAisles
        } else {
            return viewModel.sortedAisles.filter { aisle in
                aisle.name.lowercased().contains(searchText.lowercased()) ||
                (aisle.description ?? "").lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    // MARK: - View Components
    private var aislesList: some View {
        List {
            ForEach(filteredAisles) { aisle in
                NavigationLink(destination: MedicinesByAisleView(aisleId: aisle.id)) {
                    AisleRow(
                        aisle: aisle,
                        medicineCount: viewModel?.getMedicineCountForAisle(aisle.id) ?? 0,
                        stockStatus: viewModel?.getAisleStockStatus(aisle.id) ?? .normal
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .opacity(listItemsOpacity[aisle.id, default: 0])
                .offset(x: listItemsOffset[aisle.id, default: 50])
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        Task {
                            await viewModel?.deleteAisle(aisle)
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
            }
        }
        .listStyle(PlainListStyle())
        .environment(\.editMode, $editMode)
    }
    
    // MARK: - Helper Methods
    private func startAnimations() {
        guard let viewModel = viewModel else { return }
        
        for (index, aisle) in viewModel.sortedAisles.enumerated() {
            withAnimation(.easeOut(duration: 0.5).delay(Double(index) * 0.1)) {
                listItemsOffset[aisle.id] = 0
                listItemsOpacity[aisle.id] = 1.0
            }
        }
    }
}

// MARK: - Aisle Row Component
struct AisleRow: View {
    let aisle: Aisle
    let medicineCount: Int
    let stockStatus: AisleStockStatus
    
    var body: some View {
        HStack(spacing: 15) {
            // Icône du rayon
            ZStack {
                Circle()
                    .fill(aisle.color)
                    .frame(width: 50, height: 50)
                
                if !aisle.icon.isEmpty {
                    Image(systemName: aisle.icon)
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                }
            }
            
            // Informations du rayon
            VStack(alignment: .leading, spacing: 4) {
                Text(aisle.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let description = aisle.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    Text("\(medicineCount) médicament\(medicineCount > 1 ? "s" : "")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Indicateur de statut du stock
                    HStack(spacing: 4) {
                        Image(systemName: stockStatus.icon)
                            .font(.caption)
                            .foregroundColor(stockStatus.color)
                        
                        Text(stockStatusText(stockStatus))
                            .font(.caption)
                            .foregroundColor(stockStatus.color)
                    }
                }
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func stockStatusText(_ status: AisleStockStatus) -> String {
        switch status {
        case .normal:
            return "Normal"
        case .warning:
            return "Attention"
        case .critical:
            return "Critique"
        }
    }
}

// MARK: - Aisle Form View
struct SimpleAisleFormView: View {
    @Environment(\.dismiss) private var dismiss
    
    let aisle: Aisle?
    let onSave: (Aisle) -> Void
    
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var selectedColor: Color = .blue
    @State private var selectedIcon: String = "pills"
    
    private var isEditing: Bool { aisle != nil }
    
    // Couleurs disponibles
    private let availableColors: [Color] = [
        .red, .orange, .yellow, .green, .blue, .indigo, .purple, .pink,
        .brown, .gray, .cyan, .mint, .teal
    ]
    
    // Icônes disponibles
    private let availableIcons: [String] = [
        "pills", "cross", "heart", "eye", "ear", "brain", "lungs",
        "bandage", "thermometer", "stethoscope", "syringe", "capsule"
    ]
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Informations générales")) {
                    TextField("Nom du rayon", text: $name)
                    
                    TextField("Description (optionnel)", text: $description, axis: .vertical)
                        .lineLimit(3)
                }
                
                Section(header: Text("Apparence")) {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Couleur")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                            ForEach(availableColors.indices, id: \.self) { index in
                                let color = availableColors[index]
                                Circle()
                                    .fill(color)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: selectedColor == color ? 2 : 0)
                                    )
                                    .onTapGesture {
                                        selectedColor = color
                                    }
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Icône")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                            ForEach(availableIcons, id: \.self) { icon in
                                Button(action: {
                                    selectedIcon = icon
                                }) {
                                    Image(systemName: icon)
                                        .font(.system(size: 20))
                                        .foregroundColor(selectedIcon == icon ? .white : .primary)
                                        .frame(width: 40, height: 40)
                                        .background(selectedIcon == icon ? selectedColor : Color(.systemGray6))
                                        .clipShape(Circle())
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("Aperçu")) {
                    HStack {
                        Circle()
                            .fill(selectedColor)
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: selectedIcon)
                                    .font(.system(size: 22))
                                    .foregroundColor(.white)
                            )
                        
                        VStack(alignment: .leading) {
                            Text(name.isEmpty ? "Nom du rayon" : name)
                                .font(.headline)
                                .foregroundColor(name.isEmpty ? .secondary : .primary)
                            
                            if !description.isEmpty {
                                Text(description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 5)
                }
            }
            .navigationTitle(isEditing ? "Modifier le rayon" : "Nouveau rayon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") {
                        let newAisle = Aisle(
                            id: aisle?.id ?? UUID().uuidString,
                            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                            description: description.isEmpty ? nil : description,
                            color: selectedColor,
                            icon: selectedIcon
                        )
                        
                        onSave(newAisle)
                        dismiss()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
        .onAppear {
            if let aisle = aisle {
                name = aisle.name
                description = aisle.description ?? ""
                selectedColor = aisle.color
                selectedIcon = aisle.icon
            }
        }
    }
}

#Preview {
    NewAislesView()
}
