import SwiftUI
import Foundation

/// Composant pour ajustement rapide des stocks directement dans les listes
struct QuickStockAdjustment: View {
    let medicine: Medicine
    let onAdjustment: (Medicine, Int, String) -> Void
    
    // Injection via environment
    @Environment(\.viewModelCreator) private var viewModelCreator
    
    @State private var isAdjusting = false
    @State private var showingFullAdjustment = false
    
    var body: some View {
        HStack(spacing: 8) {
            // Bouton diminuer
            Button(action: {
                decreaseStock()
            }) {
                Image(systemName: "minus.circle.fill")
                    .font(.title2)
                    .foregroundColor(medicine.currentQuantity > 0 ? .red : .gray)
            }
            .disabled(medicine.currentQuantity <= 0 || isAdjusting)
            
            // Affichage du stock actuel
            VStack(spacing: 2) {
                Text("\(medicine.currentQuantity)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(stockColor)
                
                Text(medicine.unit)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(minWidth: 50)
            
            // Bouton augmenter
            Button(action: {
                increaseStock()
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(medicine.currentQuantity < medicine.maxQuantity ? .green : .gray)
            }
            .disabled(medicine.currentQuantity >= medicine.maxQuantity || isAdjusting)
        }
        .sheet(isPresented: $showingFullAdjustment) {
            AdjustStockView(
                medicineId: medicine.id,
                viewModel: viewModelCreator.createAdjustStockViewModel(medicineId: medicine.id)
            )
        }
        .contextMenu {
            Button("Ajustement détaillé") {
                showingFullAdjustment = true
            }
            
            Button("Stock vide") {
                setStock(to: 0, reason: "Stock vidé")
            }
            
            Button("Stock critique") {
                setStock(to: medicine.criticalThreshold, reason: "Stock défini au seuil critique")
            }
            
            Button("Stock maximum") {
                setStock(to: medicine.maxQuantity, reason: "Stock défini au maximum")
            }
        }
        .opacity(isAdjusting ? 0.6 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isAdjusting)
    }
    
    // MARK: - Computed Properties
    
    private var stockColor: Color {
        if medicine.currentQuantity <= medicine.criticalThreshold {
            return .red
        } else if medicine.currentQuantity <= medicine.warningThreshold {
            return .orange
        } else {
            return .green
        }
    }
    
    // MARK: - Actions
    
    private func increaseStock() {
        guard medicine.currentQuantity < medicine.maxQuantity else { return }
        
        isAdjusting = true
        
        let newQuantity = medicine.currentQuantity + 1
        let reason = "Ajout d'1 \(medicine.unit)"
        
        onAdjustment(medicine, newQuantity, reason)
        
        // Simule un délai d'ajustement
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isAdjusting = false
        }
    }
    
    private func decreaseStock() {
        guard medicine.currentQuantity > 0 else { return }
        
        isAdjusting = true
        
        let newQuantity = medicine.currentQuantity - 1
        let reason = "Retrait d'1 \(medicine.unit)"
        
        onAdjustment(medicine, newQuantity, reason)
        
        // Simule un délai d'ajustement
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isAdjusting = false
        }
    }
    
    private func setStock(to quantity: Int, reason: String) {
        isAdjusting = true
        
        onAdjustment(medicine, quantity, reason)
        
        // Simule un délai d'ajustement
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isAdjusting = false
        }
    }
}

/// Composant pour affichage compact du stock avec indicateur visuel
struct CompactStockIndicator: View {
    let medicine: Medicine
    let showAdjustment: Bool
    let onAdjustment: ((Medicine, Int, String) -> Void)?
    
    init(medicine: Medicine, showAdjustment: Bool = false, onAdjustment: ((Medicine, Int, String) -> Void)? = nil) {
        self.medicine = medicine
        self.showAdjustment = showAdjustment
        self.onAdjustment = onAdjustment
    }
    
    var body: some View {
        HStack {
            // Indicateur de stock avec barre de progression
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(medicine.currentQuantity)/\(medicine.maxQuantity)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(stockColor)
                    
                    Text(medicine.unit)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // Barre de progression
                ProgressView(value: stockPercentage)
                    .progressViewStyle(LinearProgressViewStyle(tint: stockColor))
                    .frame(height: 4)
                    .scaleEffect(x: 1, y: 0.8)
            }
            
            Spacer()
            
            // Boutons d'ajustement si activés
            if showAdjustment, let onAdjustment = onAdjustment {
                QuickStockAdjustment(medicine: medicine, onAdjustment: onAdjustment)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var stockPercentage: Double {
        guard medicine.maxQuantity > 0 else { return 0 }
        return Double(medicine.currentQuantity) / Double(medicine.maxQuantity)
    }
    
    private var stockColor: Color {
        if medicine.currentQuantity <= medicine.criticalThreshold {
            return .red
        } else if medicine.currentQuantity <= medicine.warningThreshold {
            return .orange
        } else {
            return .green
        }
    }
}

/// Composant pour les actions rapides de stock dans les dashboards
struct StockActionButtons: View {
    let medicine: Medicine
    let onAdjustment: (Medicine, Int, String) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Bouton stock critique
            ActionButton(
                title: "Critique",
                value: medicine.criticalThreshold,
                color: .red,
                isActive: medicine.currentQuantity <= medicine.criticalThreshold
            ) {
                onAdjustment(medicine, medicine.criticalThreshold, "Stock défini au seuil critique")
            }
            
            // Bouton stock d'alerte
            ActionButton(
                title: "Alerte",
                value: medicine.warningThreshold,
                color: .orange,
                isActive: medicine.currentQuantity <= medicine.warningThreshold && medicine.currentQuantity > medicine.criticalThreshold
            ) {
                onAdjustment(medicine, medicine.warningThreshold, "Stock défini au seuil d'alerte")
            }
            
            // Bouton stock optimal
            ActionButton(
                title: "Optimal",
                value: medicine.maxQuantity,
                color: .green,
                isActive: medicine.currentQuantity == medicine.maxQuantity
            ) {
                onAdjustment(medicine, medicine.maxQuantity, "Stock défini au maximum")
            }
        }
    }
    
    // MARK: - Helper Views
    
    private struct ActionButton: View {
        let title: String
        let value: Int
        let color: Color
        let isActive: Bool
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                VStack(spacing: 4) {
                    Text(title)
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Text("\(value)")
                        .font(.caption2)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isActive ? color : color.opacity(0.2))
                .foregroundColor(isActive ? .white : color)
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

/// Composant pour affichage d'alerte de stock
struct StockAlert: View {
    let medicine: Medicine
    let onAdjust: (() -> Void)?
    
    var body: some View {
        if medicine.currentQuantity <= medicine.criticalThreshold {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Stock critique!")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    
                    Text("\(medicine.currentQuantity) \(medicine.unit) restant(s)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let onAdjust = onAdjust {
                    Button("Ajuster") {
                        onAdjust()
                    }
                    .font(.caption)
                    .foregroundColor(.accentApp)
                }
            }
            .padding(8)
            .background(Color.red.opacity(0.1))
            .cornerRadius(8)
        } else if medicine.currentQuantity <= medicine.warningThreshold {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Stock faible")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    
                    Text("\(medicine.currentQuantity) \(medicine.unit) restant(s)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let onAdjust = onAdjust {
                    Button("Ajuster") {
                        onAdjust()
                    }
                    .font(.caption)
                    .foregroundColor(.accentApp)
                }
            }
            .padding(8)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

#Preview {
    let mockMedicine = Medicine(
        id: "1",
        name: "Doliprane",
        description: "Paracétamol",
        dosage: "500mg",
        form: "Comprimé",
        reference: "DOLI500",
        unit: "comprimés",
        currentQuantity: 5,
        maxQuantity: 30,
        warningThreshold: 10,
        criticalThreshold: 5,
        expiryDate: Date().addingTimeInterval(60*60*24*30),
        aisleId: "aisle1",
        createdAt: Date(),
        updatedAt: Date()
    )
    
    VStack(spacing: 20) {
        QuickStockAdjustment(medicine: mockMedicine) { medicine, quantity, reason in
            print("Ajustement: \(medicine.name) -> \(quantity) (\(reason))")
        }
        
        CompactStockIndicator(medicine: mockMedicine, showAdjustment: true) { medicine, quantity, reason in
            print("Ajustement: \(medicine.name) -> \(quantity) (\(reason))")
        }
        
        StockActionButtons(medicine: mockMedicine) { medicine, quantity, reason in
            print("Ajustement: \(medicine.name) -> \(quantity) (\(reason))")
        }
        
        StockAlert(medicine: mockMedicine) {
            print("Ajuster le stock")
        }
    }
    .padding()
}