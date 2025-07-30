import SwiftUI

struct AisleFormView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    let aisle: Aisle?
    @State private var name = ""
    @State private var description = ""
    @State private var colorHex = "#0080FF"
    @State private var icon = "pills"
    @State private var selectedColor = Color.blue
    
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    private var isEditing: Bool {
        aisle != nil
    }
    
    // Couleurs prédéfinies pour la sélection
    private let predefinedColors: [(name: String, color: Color, hex: String)] = [
        ("Bleu", .blue, "#0080FF"),
        ("Vert", .green, "#34C759"),
        ("Orange", .orange, "#FF9500"),
        ("Rouge", .red, "#FF3B30"),
        ("Violet", .purple, "#AF52DE"),
        ("Rose", .pink, "#FF2D55"),
        ("Jaune", .yellow, "#FFCC00"),
        ("Cyan", .cyan, "#00C7BE"),
        ("Indigo", .indigo, "#5856D6"),
        ("Marron", .brown, "#A2845E")
    ]
    
    // Icônes disponibles pour les rayons
    private let availableIcons = [
        "pills", "pills.fill", "pills.circle", "pills.circle.fill",
        "cross.case", "cross.case.fill", "bandage", "bandage.fill",
        "heart", "heart.fill", "stethoscope", "medical.thermometer",
        "syringe", "syringe.fill", "drop", "drop.fill",
        "capsule", "capsule.fill", "cross.vial", "cross.vial.fill"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Informations générales") {
                    TextField("Nom du rayon", text: $name)
                        .textInputAutocapitalization(.words)
                    
                    TextField("Description (optionnel)", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section("Couleur") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(predefinedColors, id: \.hex) { colorItem in
                                Circle()
                                    .fill(colorItem.color)
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Circle()
                                            .stroke(colorHex == colorItem.hex ? Color.primary : Color.clear, lineWidth: 3)
                                    )
                                    .onTapGesture {
                                        colorHex = colorItem.hex
                                        selectedColor = colorItem.color
                                    }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                Section("Icône") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 12) {
                        ForEach(availableIcons, id: \.self) { iconName in
                            VStack {
                                Image(systemName: iconName)
                                    .font(.title2)
                                    .foregroundColor(icon == iconName ? selectedColor : .primary)
                                    .frame(width: 60, height: 60)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(icon == iconName ? selectedColor.opacity(0.2) : Color(.systemGray6))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(icon == iconName ? selectedColor : Color.clear, lineWidth: 2)
                                    )
                                    .onTapGesture {
                                        icon = iconName
                                    }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                if isEditing {
                    Section {
                        Label("Aperçu", systemImage: icon)
                            .foregroundColor(selectedColor)
                            .font(.headline)
                    }
                }
            }
            .navigationTitle(isEditing ? "Modifier rayon" : "Nouveau rayon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Enregistrer" : "Ajouter") {
                        saveAisle()
                    }
                    .disabled(name.isEmpty || isLoading)
                }
            }
            .onAppear {
                if let aisle = aisle {
                    name = aisle.name
                    description = aisle.description ?? ""
                    colorHex = aisle.colorHex
                    icon = aisle.icon
                    selectedColor = Color(hex: colorHex) ?? .blue
                }
            }
            .alert("Erreur", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .disabled(isLoading)
            .overlay {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.3))
                }
            }
        }
    }
    
    private func saveAisle() {
        isLoading = true
        
        Task {
            let newAisle = Aisle(
                id: aisle?.id ?? "",
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                description: description.isEmpty ? nil : description.trimmingCharacters(in: .whitespacesAndNewlines),
                colorHex: colorHex,
                icon: icon
            )
            
            await appState.saveAisle(newAisle)
            
            if let error = appState.errorMessage {
                await MainActor.run {
                    errorMessage = error
                    showingError = true
                    isLoading = false
                    appState.clearError()
                }
            } else {
                await MainActor.run {
                    dismiss()
                }
            }
        }
    }
}