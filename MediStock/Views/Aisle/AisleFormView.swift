import SwiftUI

struct AisleFormView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: AislesViewModel
    
    @State private var name: String
    @State private var description: String
    @State private var selectedColor: Color
    @State private var selectedIcon: String
    @State private var isEditing: Bool
    
    // Animation properties
    @State private var formOpacity: Double = 0
    @State private var formOffset: CGFloat = 30
    @State private var showIconPicker: Bool = false
    @State private var iconSelectionScale: CGFloat = 1.0
    
    // Constantes
    private let predefinedColors: [Color] = [
        .red, .orange, .yellow, .green, .mint,
        .teal, .cyan, .blue, .indigo, .purple,
        .pink, .brown
    ]
    
    private let predefinedIcons: [String] = [
        "pills", "cross.case", "heart", "bandage", "stethoscope", 
        "thermometer", "syringe", "staroflife", "waveform.path.ecg",
        "leaf", "brain", "eye", "ear", "nose", "mouth",
        "allergens", "bed.double", "shield", "drop", "figure.walk",
        "folder", "archivebox", "tray", "cabinet", "rectangle.3.group"
    ]
    
    init(viewModel: AislesViewModel, editingAisle: Aisle? = nil) {
        self.viewModel = viewModel
        self.isEditing = editingAisle != nil
        
        if let aisle = editingAisle {
            self._name = State(initialValue: aisle.name)
            self._description = State(initialValue: aisle.description ?? "")
            self._selectedColor = State(initialValue: aisle.color)
            self._selectedIcon = State(initialValue: aisle.icon)
        } else {
            self._name = State(initialValue: "")
            self._description = State(initialValue: "")
            self._selectedColor = State(initialValue: .blue)
            self._selectedIcon = State(initialValue: "pills")
        }
        
        self._editingAisleId = State(initialValue: editingAisle?.id)
    }
    
    @State private var editingAisleId: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundApp.opacity(0.1).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        aislePreview
                            .padding(.vertical)
                        
                        formFields
                    }
                    .padding()
                    .opacity(formOpacity)
                    .offset(y: formOffset)
                }
                
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
            .navigationTitle(isEditing ? "Modifier un rayon" : "Ajouter un rayon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Mettre à jour" : "Ajouter") {
                        saveAisle()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onChange(of: viewModel.state) { oldValue, newValue in
                if case .success = newValue {
                    dismiss()
                }
            }
            .onAppear {
                startAnimations()
            }
        }
    }
    
    // MARK: - View Components
    
    private var aislePreview: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(selectedColor)
                    .frame(width: 100, height: 100)
                    .shadow(color: selectedColor.opacity(0.5), radius: 8)
                
                if !selectedIcon.isEmpty {
                    Image(systemName: selectedIcon)
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                        .scaleEffect(iconSelectionScale)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                iconSelectionScale = 1.2
                            }
                            
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.1)) {
                                iconSelectionScale = 1.0
                            }
                            
                            showIconPicker.toggle()
                        }
                }
            }
            
            Text(name.isEmpty ? "Nom du rayon" : name)
                .font(.headline)
                .foregroundColor(name.isEmpty ? .gray : .primary)
            
            if !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }
    
    private var formFields: some View {
        VStack(spacing: 20) {
            // Champs de saisie
            VStack(alignment: .leading, spacing: 8) {
                Text("Nom du rayon*")
                    .font(.headline)
                
                TextField("Entrez un nom...", text: $name)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.headline)
                
                TextEditor(text: $description)
                    .frame(height: 100)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
            
            // Sélecteur de couleur
            VStack(alignment: .leading, spacing: 10) {
                Text("Couleur")
                    .font(.headline)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                    ForEach(predefinedColors, id: \.self) { color in
                        Circle()
                            .fill(color)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Circle()
                                    .stroke(Color.primary, lineWidth: selectedColor == color ? 3 : 0)
                            )
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedColor = color
                                }
                            }
                    }
                }
                .padding(.vertical, 5)
            }
            
            // Sélecteur d'icône
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Icône")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            showIconPicker.toggle()
                        }
                    }) {
                        HStack {
                            Text(showIconPicker ? "Masquer les icônes" : "Afficher toutes les icônes")
                                .font(.subheadline)
                            
                            Image(systemName: showIconPicker ? "chevron.up" : "chevron.down")
                        }
                    }
                    .foregroundColor(.accentApp)
                }
                
                if showIconPicker {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 15) {
                        ForEach(predefinedIcons, id: \.self) { icon in
                            ZStack {
                                Circle()
                                    .fill(selectedIcon == icon ? selectedColor : Color(.systemGray5))
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(selectedIcon == icon ? .white : .primary)
                            }
                            .onTapGesture {
                                withAnimation {
                                    selectedIcon = icon
                                }
                            }
                        }
                    }
                    .padding(.vertical, 10)
                }
            }
            
            Spacer()
                .frame(height: 30)
            
            // Bouton d'action
            PrimaryButton(
                title: isEditing ? "Mettre à jour" : "Créer le rayon",
                icon: isEditing ? "checkmark" : "plus",
                isLoading: viewModel.state == .loading,
                isDisabled: name.isEmpty
            ) {
                saveAisle()
            }
            .padding(.top, 10)
        }
    }
    
    // MARK: - Methods
    
    private func saveAisle() {
        Task {
            if isEditing, let id = editingAisleId {
                await viewModel.updateAisle(
                    id: id,
                    name: name,
                    description: description.isEmpty ? nil : description,
                    color: selectedColor,
                    icon: selectedIcon
                )
            } else {
                await viewModel.addAisle(
                    name: name,
                    description: description.isEmpty ? nil : description,
                    color: selectedColor,
                    icon: selectedIcon
                )
            }
        }
    }
    
    private func startAnimations() {
        withAnimation(.easeOut(duration: 0.5)) {
            formOpacity = 1
            formOffset = 0
        }
    }
}

#Preview("Ajouter un rayon") {
    let mockViewModel = AislesViewModel(
        getAislesUseCase: MockGetAislesUseCase(),
        addAisleUseCase: MockAddAisleUseCase(),
        updateAisleUseCase: MockUpdateAisleUseCase(),
        deleteAisleUseCase: MockDeleteAisleUseCase(),
        getMedicineCountByAisleUseCase: MockGetMedicineCountByAisleUseCase()
    )
    
    return AisleFormView(viewModel: mockViewModel)
}

#Preview("Modifier un rayon") {
    let mockViewModel = AislesViewModel(
        getAislesUseCase: MockGetAislesUseCase(),
        addAisleUseCase: MockAddAisleUseCase(),
        updateAisleUseCase: MockUpdateAisleUseCase(),
        deleteAisleUseCase: MockDeleteAisleUseCase(),
        getMedicineCountByAisleUseCase: MockGetMedicineCountByAisleUseCase()
    )
    
    return AisleFormView(
        viewModel: mockViewModel,
        editingAisle: Aisle(
            id: "test",
            name: "Médicaments généraux",
            description: "Antidouleurs et médicaments courants",
            color: .blue,
            icon: "pills"
        )
    )
}
