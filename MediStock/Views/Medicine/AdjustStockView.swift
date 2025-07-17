import SwiftUI


struct AdjustStockView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AdjustStockViewModel
    @State private var newQuantity: Int = 0
    @State private var comment: String = ""
    @State private var operation: StockOperation = .set
    @State private var hasUserSavedStock: Bool = false
    
    // Animation properties
    @State private var sliderOffset: CGFloat = 50
    @State private var sliderOpacity: Double = 0
    @State private var formOffset: CGFloat = 50
    @State private var formOpacity: Double = 0
    
    enum StockOperation: String, CaseIterable, Identifiable {
        case add = "Ajouter"
        case remove = "Retirer"
        case set = "Définir à"
        
        var id: String { self.rawValue }
        
        var icon: String {
            switch self {
            case .add: return "plus"
            case .remove: return "minus"
            case .set: return "equal"
            }
        }
    }
    
    let medicineId: String
    
    init(medicineId: String, viewModel: AdjustStockViewModel) {
        self.medicineId = medicineId
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ZStack {
            Color.backgroundApp.opacity(0.1).ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView("Chargement...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let medicine = viewModel.medicine {
                ScrollView {
                    VStack(spacing: 30) {
                        // Info du médicament
                        medicineInfoSection(medicine: medicine)
                        
                        // Type d'opération
                        operationSection
                        
                        // Ajustement de la quantité
                        quantityAdjustmentSection(medicine: medicine)
                        
                        // Commentaire
                        commentSection
                        
                        // Résultat estimé
                        resultSection(medicine: medicine)
                        
                        // Boutons d'action rapide
                        quickActionsSection(medicine: medicine)
                        
                        // Espace pour le bouton flottant
                        Color.clear.frame(height: 80)
                    }
                    .padding()
                }
            } else {
                ContentUnavailableView("Médicament non trouvé", systemImage: "pills")
            }
            
            // Bouton flottant en bas
            VStack {
                Spacer()
                
                PrimaryButton(
                    title: "Valider l'ajustement",
                    icon: "checkmark",
                    isLoading: viewModel.state == .loading,
                    isDisabled: !isValidAdjustment
                ) {
                    Task {
                        await saveStockAdjustment()
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
            }
            
            // Overlay du message d'erreur
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
                .zIndex(2)
            }
        }
        .navigationTitle("Ajuster le stock")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Annuler") {
                    dismiss()
                }
            }
        }
        .task {
            await viewModel.loadMedicine()
            if let medicine = viewModel.medicine {
                newQuantity = medicine.currentQuantity
            }
        }
        .onChange(of: viewModel.state) { oldValue, newValue in
            if case .success = newValue, hasUserSavedStock {
                dismiss()
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: - View Components
    
    private func medicineInfoSection(medicine: Medicine) -> some View {
        VStack(spacing: 15) {
            // Icône du médicament
            ZStack {
                Circle()
                    .fill(Color.accentApp.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Text(String(medicine.name.prefix(1)))
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.accentApp)
            }
            
            VStack(spacing: 5) {
                Text(medicine.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Stock actuel: \(medicine.currentQuantity) \(medicine.unit)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
    }
    
    private var operationSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Type d'opération")
                .font(.headline)
            
            Picker("Opération", selection: $operation) {
                ForEach(StockOperation.allCases) { op in
                    Label(op.rawValue, systemImage: op.icon).tag(op)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: operation) { oldValue, newValue in
                guard let medicine = viewModel.medicine else { return }
                
                switch newValue {
                case .set:
                    newQuantity = medicine.currentQuantity
                case .add, .remove:
                    newQuantity = 0
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
    }
    
    private func quantityAdjustmentSection(medicine: Medicine) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Quantité à \(operation.rawValue.lowercased())")
                .font(.headline)
            
            VStack(spacing: 15) {
                // Affichage de la quantité
                HStack {
                    Text("\(newQuantity)")
                        .font(.system(size: 40, weight: .bold))
                        .frame(minWidth: 80)
                        .foregroundColor(.accentApp)
                    
                    Text(medicine.unit)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.leading, 5)
                }
                .frame(maxWidth: .infinity)
                
                // Contrôles de quantité
                HStack {
                    Button {
                        decrementValue()
                    } label: {
                        Image(systemName: "minus")
                            .font(.headline)
                            .frame(width: 40, height: 40)
                            .background(Color(.systemGray5))
                            .foregroundColor(.primary)
                            .clipShape(Circle())
                    }
                    .disabled(newQuantity <= 0)
                    
                    Slider(
                        value: Binding(
                            get: { Double(newQuantity) },
                            set: { newQuantity = Int($0) }
                        ),
                        in: 0...Double(sliderMaxValue(medicine: medicine)),
                        step: 1
                    )
                    .tint(.accentApp)
                    .padding(.horizontal)
                    .offset(y: sliderOffset)
                    .opacity(sliderOpacity)
                    
                    Button {
                        incrementValue(medicine: medicine)
                    } label: {
                        Image(systemName: "plus")
                            .font(.headline)
                            .frame(width: 40, height: 40)
                            .background(Color(.systemGray5))
                            .foregroundColor(.primary)
                            .clipShape(Circle())
                    }
                    .disabled(newQuantity >= sliderMaxValue(medicine: medicine))
                }
                
                // Limites
                HStack {
                    Text("Min: 0")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("Max: \(sliderMaxValue(medicine: medicine))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
    }
    
    private var commentSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Commentaire")
                .font(.headline)
            
            TextEditor(text: $comment)
                .frame(minHeight: 100)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .offset(y: formOffset)
        .opacity(formOpacity)
    }
    
    private func resultSection(medicine: Medicine) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Résultat de l'ajustement")
                .font(.headline)
            
            HStack(spacing: 20) {
                StockIndicator(
                    value: calculatedFinalQuantity(medicine: medicine),
                    maxValue: medicine.maxQuantity,
                    warningThreshold: medicine.warningThreshold,
                    criticalThreshold: medicine.criticalThreshold
                )
                .frame(width: 80, height: 80)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Avant:")
                            .foregroundColor(.secondary)
                        Text("\(medicine.currentQuantity) \(medicine.unit)")
                            .font(.body)
                    }
                    
                    HStack {
                        Text("Après:")
                            .foregroundColor(.secondary)
                        Text("\(calculatedFinalQuantity(medicine: medicine)) \(medicine.unit)")
                            .font(.headline)
                            .foregroundColor(stockColor(medicine: medicine))
                    }
                    
                    if let status = stockStatus(medicine: medicine) {
                        HStack {
                            Circle()
                                .fill(status.color)
                                .frame(width: 8, height: 8)
                            
                            Text(status.message)
                                .font(.caption)
                                .foregroundColor(status.color)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
    }
    
    private func quickActionsSection(medicine: Medicine) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Actions rapides")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                QuickActionButton(
                    title: "Stock vide",
                    value: "0",
                    color: .red
                ) {
                    operation = .set
                    newQuantity = 0
                }
                
                QuickActionButton(
                    title: "Stock critique",
                    value: "\(medicine.criticalThreshold)",
                    color: .red
                ) {
                    operation = .set
                    newQuantity = medicine.criticalThreshold
                }
                
                QuickActionButton(
                    title: "Stock d'alerte",
                    value: "\(medicine.warningThreshold)",
                    color: .orange
                ) {
                    operation = .set
                    newQuantity = medicine.warningThreshold
                }
                
                QuickActionButton(
                    title: "Stock complet",
                    value: "\(medicine.maxQuantity)",
                    color: .green
                ) {
                    operation = .set
                    newQuantity = medicine.maxQuantity
                }
                
                QuickActionButton(
                    title: "+10",
                    value: "",
                    color: .blue
                ) {
                    operation = .add
                    newQuantity = min(10, medicine.maxQuantity - medicine.currentQuantity)
                }
                
                QuickActionButton(
                    title: "-10",
                    value: "",
                    color: .blue
                ) {
                    operation = .remove
                    newQuantity = min(10, medicine.currentQuantity)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
    }
    
    // MARK: - Helper Views
    
    private struct QuickActionButton: View {
        let title: String
        let value: String
        let color: Color
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                VStack(spacing: 4) {
                    Text(title)
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    if !value.isEmpty {
                        Text(value)
                            .font(.caption2)
                            .fontWeight(.bold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(color.opacity(0.1))
                .foregroundColor(color)
                .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private func calculatedFinalQuantity(medicine: Medicine) -> Int {
        switch operation {
        case .add:
            return medicine.currentQuantity + newQuantity
        case .remove:
            return medicine.currentQuantity - newQuantity
        case .set:
            return newQuantity
        }
    }
    
    private func stockStatus(medicine: Medicine) -> (message: String, color: Color)? {
        let quantity = calculatedFinalQuantity(medicine: medicine)
        
        if quantity < 0 {
            return ("Stock négatif impossible!", .red)
        } else if quantity == 0 {
            return ("Stock épuisé", .red)
        } else if quantity <= medicine.criticalThreshold {
            return ("Stock critique", .red)
        } else if quantity <= medicine.warningThreshold {
            return ("Stock faible", .orange)
        } else if quantity >= medicine.maxQuantity {
            return ("Stock au maximum", .green)
        } else {
            return ("Stock adéquat", .green)
        }
    }
    
    private func stockColor(medicine: Medicine) -> Color {
        let quantity = calculatedFinalQuantity(medicine: medicine)
        
        if quantity <= medicine.criticalThreshold {
            return .red
        } else if quantity <= medicine.warningThreshold {
            return .orange
        } else {
            return .green
        }
    }
    
    private func sliderMaxValue(medicine: Medicine) -> Int {
        switch operation {
        case .set:
            return medicine.maxQuantity
        case .add:
            return medicine.maxQuantity - medicine.currentQuantity
        case .remove:
            return medicine.currentQuantity
        }
    }
    
    private var isValidAdjustment: Bool {
        guard let medicine = viewModel.medicine else { return false }
        
        let finalQuantity = calculatedFinalQuantity(medicine: medicine)
        return finalQuantity >= 0 && finalQuantity <= medicine.maxQuantity && 
               (operation != .set || newQuantity >= 0) &&
               (operation == .set || newQuantity > 0)
    }
    
    // MARK: - Methods
    
    private func incrementValue(medicine: Medicine) {
        let maxValue = sliderMaxValue(medicine: medicine)
        if newQuantity < maxValue {
            newQuantity += 1
        }
    }
    
    private func decrementValue() {
        if newQuantity > 0 {
            newQuantity -= 1
        }
    }
    
    private func saveStockAdjustment() async {
        guard let medicine = viewModel.medicine else { return }
        
        hasUserSavedStock = true
        
        // Construire un commentaire automatique si l'utilisateur n'en a pas fourni
        var finalComment = comment.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if finalComment.isEmpty {
            switch operation {
            case .add:
                finalComment = "Ajout de \(newQuantity) \(medicine.unit)"
            case .remove:
                finalComment = "Retrait de \(newQuantity) \(medicine.unit)"
            case .set:
                finalComment = "Stock défini à \(newQuantity) \(medicine.unit)"
            }
        }
        
        let finalQuantity = calculatedFinalQuantity(medicine: medicine)
        await viewModel.adjustStock(
            newQuantity: finalQuantity,
            reason: finalComment
        )
    }
    
    private func startAnimations() {
        withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
            sliderOffset = 0
            sliderOpacity = 1
        }
        
        withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
            formOffset = 0
            formOpacity = 1
        }
    }
}

// RealAdjustStockUseCase is imported from UseCases/Medicine/RealAdjustStockUseCase.swift

#Preview {
    let mockMedicine = Medicine(
        id: "1",
        name: "Doliprane",
        description: "Paracétamol",
        dosage: "500mg",
        form: "Comprimé",
        reference: "DOL500",
        unit: "comprimés",
        currentQuantity: 15,
        maxQuantity: 30,
        warningThreshold: 10,
        criticalThreshold: 5,
        expiryDate: Date().addingTimeInterval(60*60*24*60),
        aisleId: "aisle1",
        createdAt: Date(),
        updatedAt: Date()
    )
    
    NavigationStack {
        AdjustStockView(medicineId: "1", viewModel: AdjustStockViewModel(
            getMedicineUseCase: MockGetMedicineUseCase(),
            adjustStockUseCase: MockAdjustStockUseCase(),
            medicine: mockMedicine,
            medicineId: "1"
        ))
    }
}