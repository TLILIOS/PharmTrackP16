import SwiftUI

struct AdjustStockView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: MedicineDetailViewModel
    @State private var newQuantity: Int
    @State private var comment: String = ""
    @State private var operation: StockOperation = .set
    
    // Animation
    @State private var sliderOffset: CGFloat = 50
    @State private var sliderOpacity: Double = 0
    @State private var formOffset: CGFloat = 50
    @State private var formOpacity: Double = 0
    
    enum StockOperation: String, CaseIterable, Identifiable {
        case add = "Ajouter"
        case remove = "Retirer"
        case set = "Définir à"
        
        var id: String { self.rawValue }
    }
    
    init(viewModel: MedicineDetailViewModel) {
        self.viewModel = viewModel
        self._newQuantity = State(initialValue: viewModel.medicine.currentQuantity)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundApp.opacity(0.1).ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Info du médicament
                    VStack(spacing: 5) {
                        Text(viewModel.medicine.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Stock actuel: \(viewModel.medicine.currentQuantity) \(viewModel.medicine.unit)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Type d'opération
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Opération")
                            .font(.headline)
                        
                        Picker("Opération", selection: $operation) {
                            ForEach(StockOperation.allCases) { op in
                                Text(op.rawValue).tag(op)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .onChange(of: operation) { oldValue, newValue in
                            if newValue == .set {
                                newQuantity = viewModel.medicine.currentQuantity
                            } else {
                                newQuantity = 0
                            }
                        }
                    }
                    
                    // Ajustement de la quantité
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Quantité")
                            .font(.headline)
                        
                        VStack(spacing: 15) {
                            HStack {
                                Text("\(newQuantity)")
                                    .font(.system(size: 40, weight: .bold))
                                    .frame(minWidth: 80)
                                    .foregroundColor(.accentApp)
                                
                                Text(viewModel.medicine.unit)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 5)
                            }
                            .frame(maxWidth: .infinity)
                            
                            HStack {
                                Button {
                                    decrementValue()
                                } label: {
                                    Image(systemName: "minus")
                                        .font(.headline)
                                        .frame(width: 40, height: 40)
                                        .background(Color(.systemGray5))
                                        .clipShape(Circle())
                                }
                                
                                Slider(
                                    value: Binding(
                                        get: { Double(newQuantity) },
                                        set: { newQuantity = Int($0) }
                                    ),
                                    in: 0...Double(operation == .set ? viewModel.medicine.maxQuantity : viewModel.medicine.maxQuantity - viewModel.medicine.currentQuantity),
                                    step: 1
                                )
                                .tint(.accentApp)
                                .padding(.horizontal)
                                .offset(y: sliderOffset)
                                .opacity(sliderOpacity)
                                
                                Button {
                                    incrementValue()
                                } label: {
                                    Image(systemName: "plus")
                                        .font(.headline)
                                        .frame(width: 40, height: 40)
                                        .background(Color(.systemGray5))
                                        .clipShape(Circle())
                                }
                            }
                            
                            HStack {
                                Spacer()
                                
                                if operation == .set {
                                    Text("Min: 0")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Text("Max: \(viewModel.medicine.maxQuantity)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    let maxDelta = operation == .add ?
                                        viewModel.medicine.maxQuantity - viewModel.medicine.currentQuantity :
                                        viewModel.medicine.currentQuantity
                                    
                                    Text("Min: 0")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Text("Max: \(maxDelta)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                        }
                    }
                    
                    // Commentaire
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Commentaire")
                            .font(.headline)
                        
                        TextEditor(text: $comment)
                            .frame(minHeight: 100)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }
                    .offset(y: formOffset)
                    .opacity(formOpacity)
                    
                    // Résultat estimé
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Résultat")
                            .font(.headline)
                        
                        HStack(spacing: 20) {
                            StockIndicator(
                                value: calculatedFinalQuantity,
                                maxValue: viewModel.medicine.maxQuantity,
                                warningThreshold: viewModel.medicine.warningThreshold,
                                criticalThreshold: viewModel.medicine.criticalThreshold
                            )
                            .frame(width: 80, height: 80)
                            
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Avant: \(viewModel.medicine.currentQuantity) \(viewModel.medicine.unit)")
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    Text("Après:")
                                        .foregroundColor(.secondary)
                                    
                                    Text("\(calculatedFinalQuantity) \(viewModel.medicine.unit)")
                                        .font(.headline)
                                        .foregroundColor(stockColor)
                                }
                                
                                if let stockStatus = stockStatus {
                                    Text(stockStatus.message)
                                        .font(.caption)
                                        .foregroundColor(stockStatus.color)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Boutons d'action
                    PrimaryButton(
                        title: "Valider",
                        icon: "checkmark",
                        isLoading: viewModel.state == .loading,
                        isDisabled: (operation != .set && newQuantity == 0) || calculatedFinalQuantity < 0
                    ) {
                        Task {
                            await saveStockAdjustment()
                        }
                    }
                }
                .padding()
                
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
                    .zIndex(1)
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
            .onAppear {
                startAnimations()
            }
            .onChange(of: viewModel.state) { oldValue, newValue in
                if case .success = newValue {
                    dismiss()
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var calculatedFinalQuantity: Int {
        switch operation {
        case .add:
            return viewModel.medicine.currentQuantity + newQuantity
        case .remove:
            return viewModel.medicine.currentQuantity - newQuantity
        case .set:
            return newQuantity
        }
    }
    
    private var stockStatus: (message: String, color: Color)? {
        let quantity = calculatedFinalQuantity
        
        if quantity <= 0 {
            return ("Stock épuisé!", .red)
        } else if quantity <= viewModel.medicine.criticalThreshold {
            return ("Stock critique", .red)
        } else if quantity <= viewModel.medicine.warningThreshold {
            return ("Stock faible", .orange)
        } else if quantity >= viewModel.medicine.maxQuantity {
            return ("Stock complet", .green)
        } else {
            return ("Stock adéquat", .green)
        }
    }
    
    private var stockColor: Color {
        if calculatedFinalQuantity <= viewModel.medicine.criticalThreshold {
            return .red
        } else if calculatedFinalQuantity <= viewModel.medicine.warningThreshold {
            return .orange
        } else {
            return .green
        }
    }
    
    // MARK: - Methods
    
    private func incrementValue() {
        switch operation {
        case .add:
            let maxDelta = viewModel.medicine.maxQuantity - viewModel.medicine.currentQuantity
            if newQuantity < maxDelta {
                newQuantity += 1
            }
        case .remove:
            if newQuantity < viewModel.medicine.currentQuantity {
                newQuantity += 1
            }
        case .set:
            if newQuantity < viewModel.medicine.maxQuantity {
                newQuantity += 1
            }
        }
    }
    
    private func decrementValue() {
        if newQuantity > 0 {
            newQuantity -= 1
        }
    }
    
    private func saveStockAdjustment() async {
        // Construire un commentaire si l'utilisateur n'en a pas fourni
        var finalComment = comment
        
        if finalComment.isEmpty {
            switch operation {
            case .add:
                finalComment = "Ajout de \(newQuantity) \(viewModel.medicine.unit)"
            case .remove:
                finalComment = "Retrait de \(newQuantity) \(viewModel.medicine.unit)"
            case .set:
                finalComment = "Stock défini à \(newQuantity) \(viewModel.medicine.unit)"
            }
        }
        
        await viewModel.updateStock(newQuantity: calculatedFinalQuantity, comment: finalComment)
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

