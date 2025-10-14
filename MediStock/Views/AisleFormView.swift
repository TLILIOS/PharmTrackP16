import SwiftUI

struct AisleFormView: View {
    @EnvironmentObject var viewModel: AisleListViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    let aisle: Aisle?
    @State private var name = ""
    @State private var description = ""
    @State private var colorHex = "#0080FF"
    @State private var icon = "pills"
    @State private var selectedColor = Color.blue
    
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var showAdvancedOptions = false
    @State private var selectedColorIndex = 0
    @State private var nameFieldError: String? = nil
    @FocusState private var focusedField: Field?
    
    private var isEditing: Bool {
        aisle != nil
    }
    
    private enum Field {
        case name, description
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
            ZStack {
                // Background
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Section principale
                        VStack(spacing: 16) {
                            // Titre de section
                            HStack {
                                Label("INFORMATIONS GÉNÉRALES", systemImage: "info.circle.fill")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            
                            // Card pour le nom
                            VStack(alignment: .leading, spacing: 8) {
                                ModernTextField(
                                    title: "Nom du rayon",
                                    text: $name,
                                    icon: "textformat",
                                    error: nameFieldError
                                )
                                .focused($focusedField, equals: .name)
                                .onChange(of: name) {
                                    validateName()
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.top, 20)
                        // Section Couleur
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Label("COULEUR", systemImage: "paintpalette.fill")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(Array(predefinedColors.enumerated()), id: \.offset) { index, colorItem in
                                        ColorPill(
                                            color: colorItem.color,
                                            isSelected: colorHex == colorItem.hex,
                                            action: {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                    colorHex = colorItem.hex
                                                    selectedColor = colorItem.color
                                                    selectedColorIndex = index
                                                }
                                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        // Section Icône
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Label("ICÔNE", systemImage: "star.square.fill")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            
                            ScrollView {
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 16) {
                                    ForEach(availableIcons, id: \.self) { iconName in
                                        IconSelector(
                                            iconName: iconName,
                                            isSelected: icon == iconName,
                                            selectedColor: selectedColor,
                                            action: {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                    icon = iconName
                                                }
                                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                            .frame(maxHeight: 250)
                        }
                        // Options avancées
                        VStack(spacing: 0) {
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showAdvancedOptions.toggle()
                                }
                            }) {
                                HStack {
                                    Label("Plus d'options", systemImage: "slider.horizontal.3")
                                        .font(.system(size: 15, weight: .medium, design: .rounded))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .rotationEffect(.degrees(showAdvancedOptions ? 90 : 0))
                                }
                                .foregroundColor(.primary)
                                .padding(20)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                                )
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 20)
                            
                            if showAdvancedOptions {
                                VStack(spacing: 16) {
                                    ModernTextEditor(
                                        title: "Description (optionnel)",
                                        text: $description,
                                        icon: "text.alignleft"
                                    )
                                    .focused($focusedField, equals: .description)
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 16)
                                .transition(.asymmetric(
                                    insertion: .push(from: .top).combined(with: .opacity),
                                    removal: .push(from: .bottom).combined(with: .opacity)
                                ))
                            }
                        }
                        
                        // Aperçu
                        if isEditing || !name.isEmpty {
                            VStack(spacing: 16) {
                                HStack {
                                    Label("APERÇU", systemImage: "eye.fill")
                                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                
                                PreviewCard(
                                    name: name.isEmpty ? "Nom du rayon" : name,
                                    icon: icon,
                                    color: selectedColor
                                )
                                .padding(.horizontal, 20)
                            }
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .scale.combined(with: .opacity)
                            ))
                        }
                        
                        // Spacer pour les boutons flottants
                        Color.clear.frame(height: 100)
                    }
                }
                
                // Boutons flottants
                VStack {
                    Spacer()
                    FloatingActionButtons(
                        cancelAction: { dismiss() },
                        saveAction: saveAisle,
                        saveTitle: isEditing ? "Enregistrer" : "Ajouter",
                        isDisabled: name.isEmpty || isLoading
                    )
                }
            }
            .navigationTitle(isEditing ? "Modifier rayon" : "Nouveau rayon")
            .navigationBarTitleDisplayMode(.large)
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
    
    private func validateName() {
        if name.isEmpty {
            nameFieldError = nil
        } else if name.count < 2 {
            nameFieldError = "Le nom doit contenir au moins 2 caractères"
        } else {
            nameFieldError = nil
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

            await viewModel.saveAisle(newAisle)

            if let error = viewModel.errorMessage {
                await MainActor.run {
                    errorMessage = error
                    showingError = true
                    isLoading = false
                    viewModel.clearError()
                }
            } else {
                await MainActor.run {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Composants UI modernes

struct ModernTextField: View {
    let title: String
    @Binding var text: String
    let icon: String
    var error: String? = nil
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title.uppercased())
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    TextField("", text: $text)
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundColor(.primary)
                        .textInputAutocapitalization(.words)
                }
                
                if !text.isEmpty {
                    Button(action: { text = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary.opacity(0.5))
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(error != nil ? Color.red.opacity(0.5) : Color.clear, lineWidth: 1)
                    )
            )
            
            if let error = error {
                Label(error, systemImage: "exclamationmark.circle.fill")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(.red)
                    .padding(.horizontal, 8)
                    .transition(.asymmetric(
                        insertion: .push(from: .top).combined(with: .opacity),
                        removal: .push(from: .bottom).combined(with: .opacity)
                    ))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: error)
    }
}

struct ModernTextEditor: View {
    let title: String
    @Binding var text: String
    let icon: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 24, alignment: .top)
                    .padding(.top, 16)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(title.uppercased())
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                        .padding(.top, 16)
                    
                    TextEditor(text: $text)
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(.primary)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 80, maxHeight: 120)
                }
                .padding(.trailing, 16)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )
        }
    }
}

struct ColorPill: View {
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 52, height: 52)
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 3)
                    .opacity(isSelected ? 1 : 0)
                    .scaleEffect(isSelected ? 1 : 0.8)
            )
            .overlay(
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .opacity(isSelected ? 1 : 0)
                    .scaleEffect(isSelected ? 1 : 0.5)
            )
            .scaleEffect(isPressed ? 0.85 : 1)
            .shadow(color: color.opacity(isSelected ? 0.4 : 0), radius: 8, x: 0, y: 4)
            .onTapGesture {
                action()
            }
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isPressed = true
                }
            } onPressingChanged: { pressing in
                if !pressing {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isPressed = false
                    }
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

struct IconSelector: View {
    let iconName: String
    let isSelected: Bool
    let selectedColor: Color
    let action: () -> Void
    @State private var isPressed = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: iconName)
                .font(.system(size: 26, weight: .medium))
                .foregroundColor(isSelected ? selectedColor : .primary)
                .frame(width: 70, height: 70)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? selectedColor.opacity(0.15) : Color(UIColor.secondarySystemGroupedBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(isSelected ? selectedColor : Color.clear, lineWidth: 2)
                        )
                )
                .scaleEffect(isPressed ? 0.9 : 1)
                .shadow(color: isSelected ? selectedColor.opacity(0.2) : Color.black.opacity(0.05), 
                       radius: isSelected ? 6 : 3, 
                       x: 0, 
                       y: isSelected ? 3 : 2)
        }
        .onTapGesture {
            action()
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = true
            }
        } onPressingChanged: { pressing in
            if !pressing {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isPressed = false
                }
            }
        }
    }
}

struct PreviewCard: View {
    let name: String
    let icon: String
    let color: Color
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(color.opacity(0.15))
                    .frame(width: 56, height: 56)
                
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(color)
                    .symbolRenderingMode(.hierarchical)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("Aperçu du rayon")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
}

struct FloatingActionButtons: View {
    let cancelAction: () -> Void
    let saveAction: () -> Void
    let saveTitle: String
    let isDisabled: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: cancelAction) {
                Text("Annuler")
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(UIColor.secondarySystemGroupedBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color(UIColor.separator), lineWidth: 0.5)
                            )
                    )
            }
            .buttonStyle(.plain)
            
            Button(action: saveAction) {
                Label(saveTitle, systemImage: "checkmark.circle.fill")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isDisabled ? Color.gray : Color.accentColor)
                            .shadow(color: (isDisabled ? Color.gray : Color.accentColor).opacity(0.3), 
                                   radius: 8, x: 0, y: 4)
                    )
            }
            .buttonStyle(.plain)
            .disabled(isDisabled)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(UIColor.systemGroupedBackground).opacity(0),
                    Color(UIColor.systemGroupedBackground),
                    Color(UIColor.systemGroupedBackground)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
}