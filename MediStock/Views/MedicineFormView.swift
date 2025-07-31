import SwiftUI

struct MedicineFormView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    let medicine: Medicine?
    @State private var name = ""
    @State private var dosage = ""
    @State private var unit = "comprimé(s)"
    @State private var currentQuantity = ""
    @State private var warningThreshold = ""
    @State private var criticalThreshold = ""
    @State private var maxQuantity = ""
    @State private var reference = ""
    @State private var form = ""
    @State private var description = ""
    @State private var expirationDate = Date()
    @State private var selectedAisleId = ""
    
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var showAdvancedOptions = false
    @State private var showStockDetails = false
    @State private var nameFieldError: String? = nil
    @State private var selectedUnit = "comprimé(s)"
    @FocusState private var focusedField: Field?
    
    private var isEditing: Bool {
        medicine != nil
    }
    
    private enum Field {
        case name, dosage, form, reference, description
        case currentQuantity, maxQuantity, warningThreshold, criticalThreshold
    }
    
    private let units = [
        "comprimé(s)", "gélule(s)", "ampoule(s)",
        "flacon(s)", "tube(s)", "boîte(s)"
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Section principale - Informations essentielles
                        VStack(spacing: 16) {
                            HStack {
                                Label("INFORMATIONS GÉNÉRALES", systemImage: "info.circle.fill")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            
                            // Nom du médicament (obligatoire)
                            ModernTextField(
                                title: "Nom du médicament",
                                text: $name,
                                icon: "pills.fill",
                                error: nameFieldError
                            )
                            .focused($focusedField, equals: .name)
                            .onChange(of: name) { _ in
                                validateName()
                            }
                            .padding(.horizontal, 20)
                            
                            // Dosage et Unité sur la même ligne
                            HStack(spacing: 12) {
                                ModernTextField(
                                    title: "Dosage",
                                    text: $dosage,
                                    icon: "scalemass"
                                )
                                .focused($focusedField, equals: .dosage)
                                
                                ModernUnitPicker(
                                    selectedUnit: $unit,
                                    units: units
                                )
                                .frame(width: 140)
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.top, 20)
                        // Section Stock
                        VStack(spacing: 16) {
                            HStack {
                                Label("STOCK", systemImage: "shippingbox.fill")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            
                            // Quantités principales
                            HStack(spacing: 12) {
                                ModernNumberField(
                                    title: "Quantité actuelle",
                                    value: $currentQuantity,
                                    icon: "number.circle"
                                )
                                .focused($focusedField, equals: .currentQuantity)
                                
                                ModernNumberField(
                                    title: "Quantité maximale",
                                    value: $maxQuantity,
                                    icon: "arrow.up.circle"
                                )
                                .focused($focusedField, equals: .maxQuantity)
                            }
                            .padding(.horizontal, 20)
                            
                            // Bouton pour afficher les seuils
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showStockDetails.toggle()
                                }
                            }) {
                                HStack {
                                    Label("Seuils d'alerte", systemImage: "exclamationmark.triangle")
                                        .font(.system(size: 15, weight: .medium, design: .rounded))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .rotationEffect(.degrees(showStockDetails ? 90 : 0))
                                }
                                .foregroundColor(.primary)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                                )
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 20)
                            
                            if showStockDetails {
                                HStack(spacing: 12) {
                                    ModernNumberField(
                                        title: "Seuil d'alerte",
                                        value: $warningThreshold,
                                        icon: "exclamationmark.circle",
                                        tintColor: .orange
                                    )
                                    .focused($focusedField, equals: .warningThreshold)
                                    
                                    ModernNumberField(
                                        title: "Seuil critique",
                                        value: $criticalThreshold,
                                        icon: "exclamationmark.triangle",
                                        tintColor: .red
                                    )
                                    .focused($focusedField, equals: .criticalThreshold)
                                }
                                .padding(.horizontal, 20)
                                .transition(.asymmetric(
                                    insertion: .push(from: .top).combined(with: .opacity),
                                    removal: .push(from: .bottom).combined(with: .opacity)
                                ))
                            }
                        }
                        // Section Emplacement et expiration
                        VStack(spacing: 16) {
                            HStack {
                                Label("EMPLACEMENT ET EXPIRATION", systemImage: "location.fill")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            
                            // Sélecteur de rayon modernisé
                            ModernAislePicker(
                                selectedAisleId: $selectedAisleId,
                                aisles: appState.aisles
                            )
                            .padding(.horizontal, 20)
                            
                            // Date d'expiration
                            ModernDatePicker(
                                title: "Date d'expiration",
                                date: $expirationDate
                            )
                            .padding(.horizontal, 20)
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
                                    ModernTextField(
                                        title: "Forme",
                                        text: $form,
                                        icon: "capsule"
                                    )
                                    .focused($focusedField, equals: .form)
                                    
                                    ModernTextField(
                                        title: "Référence",
                                        text: $reference,
                                        icon: "barcode"
                                    )
                                    .focused($focusedField, equals: .reference)
                                    
                                    ModernTextEditor(
                                        title: "Description",
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
                        
                        // Spacer pour les boutons flottants
                        Color.clear.frame(height: 100)
                    }
                }
                
                // Boutons flottants
                VStack {
                    Spacer()
                    FloatingActionButtons(
                        cancelAction: { dismiss() },
                        saveAction: saveMedicine,
                        saveTitle: isEditing ? "Enregistrer" : "Ajouter",
                        isDisabled: name.isEmpty || selectedAisleId.isEmpty || isLoading
                    )
                }
            }
            .navigationTitle(isEditing ? "Modifier médicament" : "Nouveau médicament")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                if let medicine = medicine {
                    name = medicine.name
                    dosage = medicine.dosage ?? ""
                    unit = medicine.unit
                    currentQuantity = String(medicine.currentQuantity)
                    warningThreshold = String(medicine.warningThreshold)
                    criticalThreshold = String(medicine.criticalThreshold)
                    maxQuantity = String(medicine.maxQuantity)
                    form = medicine.form ?? ""
                    reference = medicine.reference ?? ""
                    description = medicine.description ?? ""
                    if let expiry = medicine.expiryDate {
                        expirationDate = expiry
                    }
                    selectedAisleId = medicine.aisleId
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
    
    private func saveMedicine() {
        guard let currentQty = Int(currentQuantity),
              let maxQty = Int(maxQuantity),
              let warningThresh = Int(warningThreshold),
              let criticalThresh = Int(criticalThreshold) else {
            errorMessage = "Les quantités doivent être des nombres valides"
            showingError = true
            return
        }
        
        guard currentQty >= 0 && maxQty >= 0 && warningThresh >= 0 && criticalThresh >= 0 else {
            errorMessage = "Les quantités ne peuvent pas être négatives"
            showingError = true
            return
        }
        
        guard criticalThresh < warningThresh else {
            errorMessage = "Le seuil critique doit être inférieur au seuil d'alerte"
            showingError = true
            return
        }
        
        guard maxQty >= currentQty else {
            errorMessage = "La quantité maximale doit être supérieure ou égale à la quantité actuelle"
            showingError = true
            return
        }
        
        isLoading = true
        
        Task {
            do {
                let newMedicine = Medicine(
                    id: medicine?.id ?? "",
                    name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                    description: description.isEmpty ? nil : description.trimmingCharacters(in: .whitespacesAndNewlines),
                    dosage: dosage.isEmpty ? nil : dosage.trimmingCharacters(in: .whitespacesAndNewlines),
                    form: form.isEmpty ? nil : form.trimmingCharacters(in: .whitespacesAndNewlines),
                    reference: reference.isEmpty ? nil : reference.trimmingCharacters(in: .whitespacesAndNewlines),
                    unit: unit,
                    currentQuantity: currentQty,
                    maxQuantity: maxQty,
                    warningThreshold: warningThresh,
                    criticalThreshold: criticalThresh,
                    expiryDate: expirationDate,
                    aisleId: selectedAisleId,
                    createdAt: medicine?.createdAt ?? Date(),
                    updatedAt: Date()
                )
                
                await appState.saveMedicine(newMedicine)
                
                await MainActor.run {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Composants UI modernes pour MedicineForm

struct ModernNumberField: View {
    let title: String
    @Binding var value: String
    let icon: String
    var tintColor: Color = .primary
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(tintColor.opacity(0.8))
                
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                TextField("0", text: $value)
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .frame(height: 40)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )
        }
    }
}

struct ModernUnitPicker: View {
    @Binding var selectedUnit: String
    let units: [String]
    @State private var showingPicker = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("UNITÉ")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
            
            Button(action: {
                showingPicker = true
            }) {
                HStack {
                    Text(selectedUnit)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.tertiarySystemGroupedBackground))
                )
            }
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $showingPicker) {
            NavigationStack {
                List(units, id: \.self) { unit in
                    Button(action: {
                        selectedUnit = unit
                        showingPicker = false
                    }) {
                        HStack {
                            Text(unit)
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedUnit == unit {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
                .navigationTitle("Sélectionner une unité")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Fermer") {
                            showingPicker = false
                        }
                    }
                }
            }
        }
    }
}

struct ModernAislePicker: View {
    @Binding var selectedAisleId: String
    let aisles: [Aisle]
    @State private var showingPicker = false
    @Environment(\.colorScheme) var colorScheme
    
    private var selectedAisle: Aisle? {
        aisles.first { $0.id == selectedAisleId }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: {
                showingPicker = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "location.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(selectedAisle?.color ?? .secondary)
                        .frame(width: 28)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("RAYON")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.secondary)
                        
                        if let aisle = selectedAisle {
                            HStack(spacing: 8) {
                                Image(systemName: aisle.icon)
                                    .font(.system(size: 16))
                                    .foregroundColor(aisle.color)
                                Text(aisle.name)
                                    .font(.system(size: 17, weight: .medium, design: .rounded))
                                    .foregroundColor(.primary)
                            }
                        } else {
                            Text("Sélectionner un rayon")
                                .font(.system(size: 17, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(selectedAisleId.isEmpty ? Color.red.opacity(0.3) : Color.clear, lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
            
            if selectedAisleId.isEmpty {
                Label("Veuillez sélectionner un rayon", systemImage: "exclamationmark.circle.fill")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(.red)
                    .padding(.horizontal, 8)
            }
        }
        .sheet(isPresented: $showingPicker) {
            NavigationStack {
                List(aisles) { aisle in
                    Button(action: {
                        selectedAisleId = aisle.id
                        showingPicker = false
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }) {
                        HStack(spacing: 16) {
                            Image(systemName: aisle.icon)
                                .font(.system(size: 24))
                                .foregroundColor(aisle.color)
                                .frame(width: 32)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(aisle.name)
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundColor(.primary)
                                
                                if let description = aisle.description {
                                    Text(description)
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            
                            Spacer()
                            
                            if selectedAisleId == aisle.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
                .navigationTitle("Sélectionner un rayon")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Fermer") {
                            showingPicker = false
                        }
                    }
                }
            }
        }
    }
}

struct ModernDatePicker: View {
    let title: String
    @Binding var date: Date
    @State private var showingPicker = false
    @Environment(\.colorScheme) var colorScheme
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter
    }
    
    private var isExpiringSoon: Bool {
        date.timeIntervalSinceNow < 30 * 24 * 60 * 60 // 30 jours
    }
    
    private var isExpired: Bool {
        date < Date()
    }
    
    var body: some View {
        Button(action: {
            showingPicker = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isExpired ? .red : (isExpiringSoon ? .orange : .secondary))
                    .frame(width: 28)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title.uppercased())
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    Text(dateFormatter.string(from: date))
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundColor(isExpired ? .red : (isExpiringSoon ? .orange : .primary))
                }
                
                Spacer()
                
                if isExpired {
                    Label("Expiré", systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.red)
                } else if isExpiringSoon {
                    Label("Bientôt", systemImage: "clock.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.orange)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isExpired ? Color.red.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingPicker) {
            NavigationStack {
                DatePicker("Date d'expiration",
                          selection: $date,
                          in: Date()...,
                          displayedComponents: .date)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .padding()
                    .navigationTitle("Date d'expiration")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Fermer") {
                                showingPicker = false
                            }
                        }
                    }
            }
        }
    }
}

//#Preview {
//    MedicineFormView(medicine: nil)
//        .environmentObject(MedicineListViewModel(medicineUseCase: MockGetMedicinesUseCase()))
//        .environmentObject(AisleListViewModel(aisleUseCase: MockGetAislesUseCase()))
//}
//
//// MARK: - Mock Use Cases for Preview
//
//private class MockGetMedicinesUseCase: GetMedicinesUseCase {
//    func execute() async throws -> [Medicine] { [] }
//}
//
//private class MockGetAislesUseCase: GetAislesUseCase {
//    func execute() async throws -> [Aisle] {
//        [
//            Aisle(id: "1", name: "Rayon A", icon: "tray", color: Color.blue, createdAt: Date(), updatedAt: Date()),
//            Aisle(id: "2", name: "Rayon B", icon: "tray.2", color: Color.green, createdAt: Date(), updatedAt: Date())
//        ]
//    }
//}
