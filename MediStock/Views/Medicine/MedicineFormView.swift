import SwiftUI

struct MedicineFormView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: MedicineFormViewModel
    @State private var selectedAisle: Aisle?
    @State private var showingDatePicker = false
    
    // Champs du formulaire
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var reference: String = ""
    @State private var dosage: String = ""
    @State private var form: String = "Comprimé"
    @State private var unit: String = "comprimés"
    @State private var currentQuantity: Int = 0
    @State private var maxQuantity: Int = 30
    @State private var warningThreshold: Int = 10
    @State private var criticalThreshold: Int = 5
    @State private var expiryDate: Date?
    
    // Animation properties
    @State private var formOffset = CGFloat(50)
    @State private var formOpacity = Double(0)
    @State private var showingAisleSelector = false
    
    // Constantes de formulaire
    private let medicineFormOptions = MedicineFormOptions()
    
    let medicineId: String?
    private var isEditing: Bool { medicineId != nil }
    
    init(medicineId: String?, viewModel: MedicineFormViewModel) {
        self.medicineId = medicineId
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundApp.opacity(0.1).ignoresSafeArea()
                
                if viewModel.state == .loading {
                    ProgressView("Chargement...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Informations générales du médicament
                            generalInfoSection
                            
                            // Informations de stock
                            stockInfoSection
                            
                            // Informations complémentaires
                            additionalInfoSection
                            
                            // Bouton d'action
                            PrimaryButton(
                                title: isEditing ? "Mettre à jour" : "Ajouter ce médicament",
                                icon: isEditing ? "checkmark" : "plus",
                                isLoading: viewModel.state == .loading,
                                isDisabled: !isFormValid
                            ) {
                                saveMedicine()
                            }
                            .padding(.top, 10)
                            .padding(.bottom, 30)
                        }
                        .padding()
                        .offset(y: formOffset)
                        .opacity(formOpacity)
                    }
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
            .navigationTitle(isEditing ? "Modifier un médicament" : "Ajouter un médicament")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await viewModel.fetchAisles()
            
            if isEditing, let medicineId = medicineId {
                await viewModel.refreshMedicine(id: medicineId)
                populateFormWithMedicine()
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
        .sheet(isPresented: $showingAisleSelector) {
            aisleSelectionSheet
        }
    }
    
    // MARK: - Form Sections
    
    private var generalInfoSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Informations générales")
                .font(.headline)
                .padding(.bottom, -5)
            
            // Nom du médicament
            VStack(alignment: .leading, spacing: 5) {
                Text("Nom du médicament*")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextField("Ex: Doliprane", text: $name)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
            
            // Description
            VStack(alignment: .leading, spacing: 5) {
                Text("Description")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextEditor(text: $description)
                    .frame(minHeight: 80)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
            
            // Rayon
            VStack(alignment: .leading, spacing: 5) {
                Text("Rayon*")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button(action: {
                    showingAisleSelector = true
                }) {
                    HStack {
                        if let aisle = selectedAisle {
                            Circle()
                                .fill(aisle.color)
                                .frame(width: 20, height: 20)
                            
                            Text(aisle.name)
                                .foregroundColor(.primary)
                        } else {
                            Text("Sélectionner un rayon")
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
    }
    
    private var stockInfoSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Informations de stock")
                .font(.headline)
                .padding(.bottom, -5)
            
            // Unité de mesure
            VStack(alignment: .leading, spacing: 5) {
                Text("Unité de mesure*")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Picker("Unité", selection: $unit) {
                    ForEach(medicineFormOptions.units, id: \.self) { unit in
                        Text(unit).tag(unit)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            
            // Quantité actuelle
            VStack(alignment: .leading, spacing: 5) {
                Text("Quantité actuelle*")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("\(currentQuantity)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .frame(width: 60, alignment: .center)
                    
                    Stepper("", value: $currentQuantity, in: 0...1000)
                    
                    Text(unit)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            
            // Quantité maximale
            VStack(alignment: .leading, spacing: 5) {
                Text("Quantité maximale*")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("\(maxQuantity)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .frame(width: 60, alignment: .center)
                    
                    Stepper("", value: $maxQuantity, in: 1...1000)
                        .onChange(of: maxQuantity) { oldValue, newValue in
                            // Ajuster les seuils si nécessaire
                            if warningThreshold > newValue {
                                warningThreshold = max(1, newValue / 3 * 2)
                            }
                            if criticalThreshold > warningThreshold {
                                criticalThreshold = max(1, warningThreshold / 2)
                            }
                        }
                    
                    Text(unit)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            
            // Seuil d'alerte
            VStack(alignment: .leading, spacing: 5) {
                Text("Seuil d'alerte*")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("\(warningThreshold)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .frame(width: 60, alignment: .center)
                    
                    Stepper("", value: $warningThreshold, in: max(1, criticalThreshold)...maxQuantity)
                        .onChange(of: warningThreshold) { oldValue, newValue in
                            if criticalThreshold > newValue {
                                criticalThreshold = max(1, newValue / 2)
                            }
                        }
                    
                    Text(unit)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            
            // Seuil critique
            VStack(alignment: .leading, spacing: 5) {
                Text("Seuil critique*")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("\(criticalThreshold)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .frame(width: 60, alignment: .center)
                    
                    Stepper("", value: $criticalThreshold, in: 1...warningThreshold)
                    
                    Text(unit)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            
            // Résumé visuel
            VStack(alignment: .leading, spacing: 5) {
                Text("Aperçu")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 20) {
                    StockIndicator(
                        value: currentQuantity,
                        maxValue: maxQuantity,
                        warningThreshold: warningThreshold,
                        criticalThreshold: criticalThreshold
                    )
                    .frame(width: 80, height: 80)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 12, height: 12)
                            
                            Text("Stock adéquat: > \(warningThreshold) \(unit)")
                                .font(.caption)
                        }
                        
                        HStack {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 12, height: 12)
                            
                            Text("Stock faible: \(criticalThreshold)-\(warningThreshold) \(unit)")
                                .font(.caption)
                        }
                        
                        HStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 12, height: 12)
                            
                            Text("Stock critique: < \(criticalThreshold) \(unit)")
                                .font(.caption)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
    }
    
    private var additionalInfoSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Informations complémentaires")
                .font(.headline)
                .padding(.bottom, -5)
            
            // Référence
            VStack(alignment: .leading, spacing: 5) {
                Text("Référence")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextField("Ex: DOLI500", text: $reference)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
            
            // Dosage
            VStack(alignment: .leading, spacing: 5) {
                Text("Dosage")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextField("Ex: 500 mg", text: $dosage)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
            
            // Forme galénique
            VStack(alignment: .leading, spacing: 5) {
                Text("Forme galénique")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Picker("Forme", selection: $form) {
                    ForEach(medicineFormOptions.forms, id: \.self) { form in
                        Text(form).tag(form)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            
            // Date d'expiration
            VStack(alignment: .leading, spacing: 5) {
                Text("Date d'expiration")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button(action: {
                    withAnimation {
                        showingDatePicker.toggle()
                    }
                }) {
                    HStack {
                        if let date = expiryDate {
                            Text(formatDate(date))
                                .foregroundColor(.primary)
                        } else {
                            Text("Aucune date d'expiration")
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if expiryDate != nil {
                            Button(action: {
                                expiryDate = nil
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        } else {
                            Image(systemName: "calendar")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                
                if showingDatePicker {
                    DatePicker(
                        "Date d'expiration",
                        selection: Binding(
                            get: { expiryDate ?? Date() },
                            set: { expiryDate = $0 }
                        ),
                        displayedComponents: .date
                    )
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .transition(.opacity)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
    }
    
    private var aisleSelectionSheet: some View {
        NavigationView {
            List {
                ForEach(viewModel.aisles) { aisle in
                    Button(action: {
                        selectedAisle = aisle
                        showingAisleSelector = false
                    }) {
                        HStack(spacing: 15) {
                            Circle()
                                .fill(aisle.color)
                                .frame(width: 30, height: 30)
                                .overlay {
                                    if !aisle.icon.isEmpty {
                                        Image(systemName: aisle.icon)
                                            .font(.system(size: 14))
                                            .foregroundColor(.white)
                                    }
                                }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(aisle.name)
                                    .foregroundColor(.primary)
                                    .font(.body)
                                
                                if let description = aisle.description {
                                    Text(description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            if selectedAisle?.id == aisle.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentApp)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                if viewModel.aisles.isEmpty {
                    ContentUnavailableView("Aucun rayon disponible", systemImage: "folder")
                }
            }
            .navigationTitle("Sélectionner un rayon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annuler") {
                        showingAisleSelector = false
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Properties and Methods
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && 
        selectedAisle != nil && 
        currentQuantity >= 0 && 
        maxQuantity > 0 && 
        warningThreshold >= 0 && 
        criticalThreshold >= 0 &&
        criticalThreshold <= warningThreshold &&
        warningThreshold <= maxQuantity
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: date)
    }
    
    private func populateFormWithMedicine() {
        guard let medicine = viewModel.medicine else { return }
        
        name = medicine.name
        description = medicine.description ?? ""
        reference = medicine.reference ?? ""
        dosage = medicine.dosage ?? ""
        form = medicine.form ?? "Comprimé"
        unit = medicine.unit
        currentQuantity = medicine.currentQuantity
        maxQuantity = medicine.maxQuantity
        warningThreshold = medicine.warningThreshold
        criticalThreshold = medicine.criticalThreshold
        expiryDate = medicine.expiryDate
        
        // Trouver et sélectionner le rayon associé
        selectedAisle = viewModel.aisles.first { $0.id == medicine.aisleId }
    }
    
    private func saveMedicine() {
        guard let aisleId = selectedAisle?.id else { return }
        
        Task {
            let medicine = Medicine(
                id: medicineId ?? UUID().uuidString,
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                description: description.isEmpty ? nil : description,
                dosage: dosage.isEmpty ? nil : dosage,
                form: form.isEmpty ? nil : form,
                reference: reference.isEmpty ? nil : reference,
                unit: unit,
                currentQuantity: currentQuantity,
                maxQuantity: maxQuantity,
                warningThreshold: warningThreshold,
                criticalThreshold: criticalThreshold,
                expiryDate: expiryDate,
                aisleId: aisleId,
                createdAt: isEditing ? viewModel.medicine?.createdAt ?? Date() : Date(),
                updatedAt: Date()
            )
            
            if isEditing {
                await viewModel.updateMedicine(medicine)
            } else {
                await viewModel.addMedicine(medicine)
            }
        }
    }
    
    private func startAnimations() {
        withAnimation(.easeOut(duration: 0.5)) {
            formOffset = 0
            formOpacity = 1
        }
    }
}

// MARK: - Medicine Form Options
struct MedicineFormOptions {
    let units = [
        "comprimés", "gélules", "ampoules", "mL", "doses", "sachets", 
        "patchs", "gouttes", "unités", "suppositoires", "sprays", "mg", "g"
    ]
    
    let forms = [
        "Comprimé", "Gélule", "Sirop", "Solution injectable", "Pommade", 
        "Crème", "Patch", "Suppositoire", "Spray", "Poudre", "Sachet", 
        "Solution buvable", "Gouttes", "Suspension", "Collyre", "Capsule"
    ]
}

#Preview {
    NavigationStack {
        Text("Medicine Form View Preview")
    }
}