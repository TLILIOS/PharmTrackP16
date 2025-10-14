import SwiftUI

struct StockAdjustmentView: View {
    @EnvironmentObject var medicineViewModel: MedicineListViewModel
    @Environment(\.dismiss) var dismiss

    let medicine: Medicine
    var onStockUpdated: (() -> Void)?
    
    @State private var adjustmentType = AdjustmentType.add
    @State private var quantity = ""
    @State private var reason = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    enum AdjustmentType: String, CaseIterable {
        case add = "Ajouter"
        case remove = "Retirer"
        case set = "Définir"
        
        var icon: String {
            switch self {
            case .add: return "plus.circle.fill"
            case .remove: return "minus.circle.fill"
            case .set: return "equal.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .add: return .green
            case .remove: return .orange
            case .set: return .blue
            }
        }
    }
    
    private var finalQuantity: Int {
        guard let qty = Int(quantity) else { return medicine.currentQuantity }
        
        switch adjustmentType {
        case .add:
            return medicine.currentQuantity + qty
        case .remove:
            return max(0, medicine.currentQuantity - qty)
        case .set:
            return qty
        }
    }
    
    private var stockWarningThreshold: Int {
        medicine.warningThreshold
    }
    
    private var stockCriticalThreshold: Int {
        medicine.criticalThreshold
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Médicament") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(medicine.name)
                            .font(.headline)
                        if let dosage = medicine.dosage {
                            Text(dosage)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Stock actuel:")
                                .foregroundColor(.secondary)
                            Text("\(medicine.currentQuantity) \(medicine.unit)")
                                .fontWeight(.semibold)
                                .foregroundColor(medicine.stockStatus.statusColor)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Type d'ajustement") {
                    Picker("Type", selection: $adjustmentType) {
                        ForEach(AdjustmentType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Quantité") {
                    HStack {
                        TextField(adjustmentType == .set ? "Nouvelle quantité" : "Quantité", text: $quantity)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                        
                        Text(medicine.unit)
                            .foregroundColor(.secondary)
                    }
                    
                    if !quantity.isEmpty && Int(quantity) != nil {
                        HStack {
                            Text("Nouveau stock:")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(finalQuantity) \(medicine.unit)")
                                .fontWeight(.semibold)
                                .foregroundColor(finalQuantity < medicine.criticalThreshold ? .red : .primary)
                        }
                        
                        if finalQuantity < medicine.criticalThreshold {
                            Label("Le stock sera en dessous du seuil critique", systemImage: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                        } else if finalQuantity < medicine.warningThreshold {
                            Label("Le stock sera en dessous du seuil d'alerte", systemImage: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                Section("Raison (optionnel)") {
                    TextField("Ex: Réception de commande, Péremption, Inventaire...", text: $reason, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section {
                    // Boutons d'ajustement rapide
                    if adjustmentType != .set {
                        VStack(spacing: 12) {
                            Text("Ajustements rapides")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack(spacing: 10) {
                                ForEach([1, 5, 10, 20], id: \.self) { value in
                                    Button(action: { quantity = String(value) }) {
                                        Text("+\(value)")
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 8)
                                            .background(Color(.systemGray5))
                                            .cornerRadius(8)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
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
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Valider") {
                        adjustStock()
                    }
                    .disabled(quantity.isEmpty || Int(quantity) == nil || isLoading)
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
    
    private func adjustStock() {
        guard let qty = Int(quantity), qty >= 0 else {
            errorMessage = "Veuillez entrer une quantité valide"
            showingError = true
            return
        }
        
        if adjustmentType == .remove && qty > medicine.currentQuantity {
            errorMessage = "Impossible de retirer plus que le stock actuel"
            showingError = true
            return
        }
        
        isLoading = true

        Task {
            // Calculer l'ajustement (la différence entre le stock final et le stock actuel)
            let adjustment = finalQuantity - medicine.currentQuantity
            let adjustmentReason = reason.isEmpty ? "Ajustement manuel" : reason

            // Utiliser la méthode adjustStock du ViewModel
            await medicineViewModel.adjustStock(
                medicine: medicine,
                adjustment: adjustment,
                reason: adjustmentReason
            )

            await MainActor.run {
                isLoading = false
                if medicineViewModel.errorMessage == nil {
                    onStockUpdated?()
                    dismiss()
                } else {
                    errorMessage = medicineViewModel.errorMessage ?? "Erreur inconnue"
                    showingError = true
                    medicineViewModel.clearError()
                }
            }
        }
    }
}
//
//#Preview {
//    NavigationStack {
//        StockAdjustmentView(medicine: Medicine(
//            id: "1",
//            name: "Paracétamol",
//            dosage: "500mg",
//            unit: "comprimé(s)",
//            currentQuantity: 50,
//            minQuantity: 20,
//            expirationDate: Date().addingTimeInterval(86400 * 60),
//            aisleId: "1",
//            notes: nil,
//            createdAt: Date(),
//            updatedAt: Date()
//        ))
//        .environmentObject(MedicineListViewModel(medicineUseCase: MockGetMedicinesUseCase()))
//    }
//}
//
//// MARK: - Mock Use Case for Preview
//
//private class MockGetMedicinesUseCase: GetMedicinesUseCase {
//    func execute() async throws -> [Medicine] { [] }
//}
