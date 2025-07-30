import SwiftUI
import Combine

// MARK: - QuantityStepperView avec debounce

struct QuantityStepperView: View {
    @Binding var quantity: Int
    let unit: String
    let range: ClosedRange<Int>
    let onQuantityChanged: ((Int) -> Void)?
    
    @State private var temporaryQuantity: Int = 0
    @State private var debounceTask: Task<Void, Never>?
    @State private var isAdjusting = false
    
    // Configuration
    let stepSize: Int
    let debounceDelay: TimeInterval
    
    init(
        quantity: Binding<Int>,
        unit: String = "unité",
        range: ClosedRange<Int> = 0...9999,
        stepSize: Int = 1,
        debounceDelay: TimeInterval = 0.5,
        onQuantityChanged: ((Int) -> Void)? = nil
    ) {
        self._quantity = quantity
        self.unit = unit
        self.range = range
        self.stepSize = stepSize
        self.debounceDelay = debounceDelay
        self.onQuantityChanged = onQuantityChanged
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Bouton décrémenter
            Button(action: decrementQuantity) {
                Image(systemName: "minus.circle.fill")
                    .font(.title2)
                    .foregroundColor(canDecrement ? .red : .gray)
            }
            .disabled(!canDecrement)
            .buttonAccessibility(
                label: "Diminuer la quantité",
                hint: "Diminue de \(stepSize) \(unit)"
            )
            
            // Affichage de la quantité
            VStack(spacing: 2) {
                Text("\(temporaryQuantity)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .monospacedDigit()
                    .animation(.easeInOut(duration: 0.1), value: temporaryQuantity)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(minWidth: 80)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(temporaryQuantity) \(unit)")
            
            // Bouton incrémenter
            Button(action: incrementQuantity) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(canIncrement ? .green : .gray)
            }
            .disabled(!canIncrement)
            .buttonAccessibility(
                label: "Augmenter la quantité",
                hint: "Augmente de \(stepSize) \(unit)"
            )
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .onAppear {
            temporaryQuantity = quantity
        }
        .onChange(of: quantity) { newValue in
            if !isAdjusting {
                temporaryQuantity = newValue
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var canIncrement: Bool {
        temporaryQuantity + stepSize <= range.upperBound
    }
    
    private var canDecrement: Bool {
        temporaryQuantity - stepSize >= range.lowerBound
    }
    
    // MARK: - Methods
    
    private func incrementQuantity() {
        guard canIncrement else { return }
        
        isAdjusting = true
        temporaryQuantity += stepSize
        debounceQuantityChange()
        
        // Haptic feedback
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    private func decrementQuantity() {
        guard canDecrement else { return }
        
        isAdjusting = true
        temporaryQuantity -= stepSize
        debounceQuantityChange()
        
        // Haptic feedback
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    private func debounceQuantityChange() {
        // Annuler la tâche précédente
        debounceTask?.cancel()
        
        // Créer une nouvelle tâche avec délai
        debounceTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(debounceDelay * 1_000_000_000))
            
            if !Task.isCancelled {
                await MainActor.run {
                    quantity = temporaryQuantity
                    isAdjusting = false
                    onQuantityChanged?(temporaryQuantity)
                }
            }
        }
    }
}

// MARK: - Quick Stock Adjustment View

struct QuickStockAdjustmentView: View {
    let medicine: Medicine
    @EnvironmentObject var medicineListViewModel: MedicineListViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var adjustedQuantity: Int = 0
    @State private var reason = ""
    @State private var isProcessing = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Info médicament
                VStack(alignment: .leading, spacing: 8) {
                    Text(medicine.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack {
                        Label("Stock actuel", systemImage: "shippingbox")
                        Spacer()
                        Text("\(medicine.currentQuantity) \(medicine.unit)")
                            .fontWeight(.semibold)
                    }
                    .font(.callout)
                    
                    StockBadge(status: medicine.stockStatus)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Stepper
                VStack(alignment: .leading, spacing: 12) {
                    Text("Nouveau stock")
                        .font(.headline)
                    
                    QuantityStepperView(
                        quantity: $adjustedQuantity,
                        unit: medicine.unit,
                        range: 0...medicine.maxQuantity,
                        stepSize: 1,
                        debounceDelay: 0.3
                    )
                    
                    // Indicateur de changement
                    if adjustedQuantity != medicine.currentQuantity {
                        HStack {
                            Image(systemName: changeIcon)
                                .foregroundColor(changeColor)
                            Text(changeText)
                                .foregroundColor(changeColor)
                        }
                        .font(.caption)
                        .padding(.horizontal)
                    }
                }
                
                // Raison
                VStack(alignment: .leading, spacing: 8) {
                    Text("Raison de l'ajustement")
                        .font(.headline)
                    
                    TextField("Ex: Dispensation, Inventaire, Péremption...", text: $reason, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(2...4)
                }
                
                Spacer()
                
                // Boutons d'action
                HStack(spacing: 16) {
                    Button("Annuler") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    
                    Button("Confirmer") {
                        confirmAdjustment()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(!canConfirm || isProcessing)
                }
            }
            .padding()
            .navigationTitle("Ajuster le stock")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                adjustedQuantity = medicine.currentQuantity
            }
            .alert("Ajustement du stock", isPresented: $showingAlert) {
                Button("OK") {
                    if !alertMessage.contains("Erreur") {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
            .interactiveDismissDisabled(isProcessing)
        }
    }
    
    // MARK: - Computed Properties
    
    private var canConfirm: Bool {
        adjustedQuantity != medicine.currentQuantity && !reason.isEmpty
    }
    
    private var changeAmount: Int {
        adjustedQuantity - medicine.currentQuantity
    }
    
    private var changeIcon: String {
        changeAmount > 0 ? "arrow.up.circle" : "arrow.down.circle"
    }
    
    private var changeColor: Color {
        changeAmount > 0 ? .green : .orange
    }
    
    private var changeText: String {
        let amount = abs(changeAmount)
        let action = changeAmount > 0 ? "Ajout" : "Retrait"
        return "\(action) de \(amount) \(medicine.unit)"
    }
    
    // MARK: - Methods
    
    private func confirmAdjustment() {
        isProcessing = true
        
        Task {
            do {
                await medicineListViewModel.adjustStock(
                    medicine: medicine,
                    adjustment: changeAmount,
                    reason: reason
                )
                
                await MainActor.run {
                    alertMessage = "Stock mis à jour avec succès"
                    showingAlert = true
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    alertMessage = "Erreur: \(error.localizedDescription)"
                    showingAlert = true
                    isProcessing = false
                }
            }
        }
    }
}

// MARK: - Preview

struct QuantityStepperView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            // Preview basique
            QuantityStepperView(
                quantity: .constant(50),
                unit: "comprimés"
            )
            
            // Preview avec configuration
            QuantityStepperView(
                quantity: .constant(10),
                unit: "boîtes",
                range: 0...20,
                stepSize: 5
            )
            
            // Preview dans QuickStockAdjustmentView
            QuickStockAdjustmentView(
                medicine: Medicine(
                    id: "1",
                    name: "Paracétamol 500mg",
                    description: nil,
                    dosage: "500mg",
                    form: "Comprimé",
                    reference: nil,
                    unit: "comprimés",
                    currentQuantity: 50,
                    maxQuantity: 200,
                    warningThreshold: 30,
                    criticalThreshold: 10,
                    expiryDate: nil,
                    aisleId: "1",
                    createdAt: Date(),
                    updatedAt: Date()
                )
            )
            .environmentObject(MedicineListViewModel())
        }
        .padding()
    }
}