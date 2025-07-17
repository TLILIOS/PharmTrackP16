import SwiftUI

struct NewAdjustStockView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.viewModelCreator) private var viewModelCreator
    
    let medicineId: String
    
    @State private var viewModel: AdjustStockViewModel?
    @State private var newQuantity: Int = 0
    @State private var reason: String = ""
    @State private var adjustmentType: AdjustmentType = .add
    @State private var adjustmentAmount: Int = 1
    
    // Animation properties
    @State private var contentOffset = CGFloat(30)
    @State private var contentOpacity = Double(0)
    
    enum AdjustmentType: String, CaseIterable {
        case add = "Ajout"
        case remove = "Retrait"
        case set = "Définir"
        
        var icon: String {
            switch self {
            case .add: return "plus"
            case .remove: return "minus"
            case .set: return "equal"
            }
        }
        
        var color: Color {
            switch self {
            case .add: return .green
            case .remove: return .red
            case .set: return .blue
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundApp.opacity(0.1).ignoresSafeArea()
                
                if let viewModel = viewModel {
                    if viewModel.isLoading {
                        ProgressView("Chargement...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let medicine = viewModel.medicine {
                        ScrollView {
                            VStack(spacing: 20) {
                                // Header avec informations du médicament
                                medicineInfoHeader(medicine: medicine)
                                
                                // Type d'ajustement
                                adjustmentTypeSection
                                
                                // Quantité actuelle et nouvelle
                                quantitySection(medicine: medicine)
                                
                                // Raison de l'ajustement
                                reasonSection
                                
                                // Bouton de confirmation
                                actionButton
                            }
                            .padding()
                            .offset(y: contentOffset)
                            .opacity(contentOpacity)
                        }
                    } else {
                        ContentUnavailableView("Médicament non trouvé", systemImage: "pills")
                    }
                } else {
                    ProgressView("Initialisation...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                // Message d'erreur
                if let viewModel = viewModel, let errorMessage = viewModel.errorMessage {
                    VStack {
                        Spacer()
                        
                        MessageView(message: errorMessage, type: .error) {
                            viewModel.dismissErrorMessage()
                        }
                        .padding()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .animation(.easeInOut, value: viewModel.errorMessage)
                    .zIndex(1)
                }
            }
            .navigationTitle("Ajuster le stock")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = viewModelCreator.createAdjustStockViewModel(medicineId: medicineId)
            }
            
            Task {
                await viewModel?.loadMedicine()
                
                // Initialiser la quantité avec la quantité actuelle
                if let currentQuantity = viewModel?.medicine?.currentQuantity {
                    newQuantity = currentQuantity
                }
            }
            
            startAnimations()
        }
    }
    
    // MARK: - View Components
    
    private func medicineInfoHeader(medicine: Medicine) -> some View {
        VStack(spacing: 15) {
            // Icône du médicament
            ZStack {
                Circle()
                    .fill(Color.accentApp.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Text(String(medicine.name.prefix(1)))
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.accentApp)
            }
            
            // Nom du médicament
            Text(medicine.name)
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            // Stock actuel avec indicateur
            HStack(spacing: 15) {
                VStack(alignment: .leading) {
                    Text("Stock actuel")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(medicine.currentQuantity) \(medicine.unit)")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                StockIndicator(
                    value: medicine.currentQuantity,
                    maxValue: medicine.maxQuantity,
                    warningThreshold: medicine.warningThreshold,
                    criticalThreshold: medicine.criticalThreshold
                )
                .frame(width: 60, height: 60)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
    }
    
    private var adjustmentTypeSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Type d'ajustement")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
                ForEach(AdjustmentType.allCases, id: \.self) { type in
                    Button(action: {
                        adjustmentType = type
                        updateNewQuantity()
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: type.icon)
                                .font(.title2)
                                .foregroundColor(adjustmentType == type ? .white : type.color)
                            
                            Text(type.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(adjustmentType == type ? .white : .primary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 70)
                        .background(adjustmentType == type ? type.color : Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
    }
    
    private func quantitySection(medicine: Medicine) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Ajustement de quantité")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Stepper pour l'ajustement
            if adjustmentType != .set {
                VStack(alignment: .leading, spacing: 10) {
                    Text(adjustmentType == .add ? "Quantité à ajouter" : "Quantité à retirer")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Button(action: {
                            if adjustmentAmount > 1 {
                                adjustmentAmount -= 1
                                updateNewQuantity()
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2)
                                .foregroundColor(adjustmentAmount > 1 ? adjustmentType.color : .gray)
                        }
                        .disabled(adjustmentAmount <= 1)
                        
                        Text("\(adjustmentAmount)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .frame(minWidth: 60)
                        
                        Button(action: {
                            if adjustmentType == .add || adjustmentAmount < medicine.currentQuantity {
                                adjustmentAmount += 1
                                updateNewQuantity()
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(adjustmentType.color)
                        }
                        .disabled(adjustmentType == .remove && adjustmentAmount >= medicine.currentQuantity)
                        
                        Spacer()
                        
                        Text(medicine.unit)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
            } else {
                // Picker pour définir une quantité exacte
                VStack(alignment: .leading, spacing: 10) {
                    Text("Nouvelle quantité")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Button(action: {
                            if newQuantity > 0 {
                                newQuantity -= 1
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2)
                                .foregroundColor(newQuantity > 0 ? .blue : .gray)
                        }
                        .disabled(newQuantity <= 0)
                        
                        Text("\(newQuantity)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .frame(minWidth: 60)
                        
                        Button(action: {
                            if newQuantity < medicine.maxQuantity {
                                newQuantity += 1
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(newQuantity < medicine.maxQuantity ? .blue : .gray)
                        }
                        .disabled(newQuantity >= medicine.maxQuantity)
                        
                        Spacer()
                        
                        Text(medicine.unit)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
            }
            
            // Résumé des changements
            HStack {
                VStack(alignment: .leading) {
                    Text("Avant")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(medicine.currentQuantity) \(medicine.unit)")
                        .font(.title3)
                        .fontWeight(.medium)
                }
                
                Image(systemName: "arrow.right")
                    .foregroundColor(.secondary)
                
                VStack(alignment: .trailing) {
                    Text("Après")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(newQuantity) \(medicine.unit)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(getQuantityColor(newQuantity, medicine: medicine))
                }
                
                Spacer()
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
    }
    
    private var reasonSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Raison de l'ajustement")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            TextEditor(text: $reason)
                .frame(minHeight: 80)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
            
            Text("Décrivez brièvement la raison de cet ajustement (optionnel)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
    }
    
    private var actionButton: some View {
        Button(action: {
            Task {
                let finalReason = reason.isEmpty ? "Ajustement de stock" : reason
                await viewModel?.adjustStock(newQuantity: newQuantity, reason: finalReason)
                
                // Check if the operation was successful based on the state
                if viewModel?.state == .success {
                    dismiss()
                }
            }
        }) {
            HStack {
                if viewModel?.isLoading == true {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white)
                } else {
                    Image(systemName: "checkmark")
                    Text("Confirmer l'ajustement")
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isValidAdjustment ? Color.accentApp : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(!isValidAdjustment || viewModel?.isLoading == true)
    }
    
    // MARK: - Helper Properties and Methods
    
    private var isValidAdjustment: Bool {
        guard let medicine = viewModel?.medicine else { return false }
        
        return newQuantity != medicine.currentQuantity &&
               newQuantity >= 0 &&
               newQuantity <= medicine.maxQuantity
    }
    
    private func getQuantityColor(_ quantity: Int, medicine: Medicine) -> Color {
        if quantity <= medicine.criticalThreshold {
            return .red
        } else if quantity <= medicine.warningThreshold {
            return .orange
        } else {
            return .green
        }
    }
    
    private func updateNewQuantity() {
        guard let medicine = viewModel?.medicine else { return }
        
        switch adjustmentType {
        case .add:
            newQuantity = min(medicine.currentQuantity + adjustmentAmount, medicine.maxQuantity)
        case .remove:
            newQuantity = max(medicine.currentQuantity - adjustmentAmount, 0)
        case .set:
            // La quantité est gérée directement dans l'interface
            break
        }
    }
    
    private func startAnimations() {
        withAnimation(.easeOut(duration: 0.5)) {
            contentOffset = 0
            contentOpacity = 1
        }
    }
}