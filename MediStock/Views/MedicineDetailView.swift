import SwiftUI

struct MedicineDetailView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    let medicineId: String
    @State private var showingEditForm = false
    @State private var showingDeleteAlert = false
    @State private var showingStockAdjustment = false
    
    // Récupérer le médicament depuis appState pour avoir toujours la version à jour
    private var medicine: Medicine? {
        appState.medicines.first { $0.id == medicineId }
    }
    
    private var stockStatusLabel: String {
        guard let medicine = medicine else { return "" }
        switch medicine.stockStatus {
        case .normal: return "Stock normal"
        case .warning: return "Stock faible"
        case .critical: return "Stock critique"
        }
    }
    
    private var aisle: Aisle? {
        guard let medicine = medicine else { return nil }
        return appState.aisles.first { $0.id == medicine.aisleId }
    }
    
    private var daysUntilExpiration: Int? {
        guard let medicine = medicine,
              let expiryDate = medicine.expiryDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: expiryDate).day
    }
    
    var body: some View {
        if let medicine = medicine {
            ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // En-tête avec statut
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(medicine.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        // Badge de statut
                        Text(stockStatusLabel)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(medicine.stockStatus.statusColor.opacity(0.2))
                            .foregroundColor(medicine.stockStatus.statusColor)
                            .cornerRadius(20)
                    }
                    
                    if let dosage = medicine.dosage {
                        Text(dosage)
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                
                // Informations principales
                VStack(spacing: 16) {
                    // Stock actuel
                    HStack {
                        Label("Stock actuel", systemImage: "shippingbox")
                            .font(.headline)
                        Spacer()
                        Text("\(medicine.currentQuantity) \(medicine.unit)")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(medicine.stockStatus.statusColor)
                    }
                    
                    Divider()
                    
                    // Seuils de stock
                    HStack {
                        Label("Seuil d'alerte", systemImage: "exclamationmark.triangle")
                            .font(.headline)
                        Spacer()
                        Text("\(medicine.warningThreshold) \(medicine.unit)")
                            .foregroundColor(.orange)
                    }
                    
                    Divider()
                    
                    HStack {
                        Label("Seuil critique", systemImage: "exclamationmark.octagon")
                            .font(.headline)
                        Spacer()
                        Text("\(medicine.criticalThreshold) \(medicine.unit)")
                            .foregroundColor(.red)
                    }
                    
                    Divider()
                    
                    // Emplacement
                    if let aisle = aisle {
                        HStack {
                            Label("Emplacement", systemImage: "location")
                                .font(.headline)
                            Spacer()
                            Label(aisle.name, systemImage: aisle.icon)
                                .foregroundColor(aisle.color)
                        }
                        
                        Divider()
                    }
                    
                    // Date d'expiration
                    if let expiryDate = medicine.expiryDate {
                        HStack {
                            Label("Expiration", systemImage: "calendar")
                                .font(.headline)
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text(expiryDate, style: .date)
                                if let days = daysUntilExpiration, days <= 30 {
                                    Text("Expire dans \(days) jours")
                                        .font(.caption)
                                        .foregroundColor(days <= 7 ? .red : .orange)
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(15)
                .padding(.horizontal)
                
                // Actions rapides
                VStack(spacing: 12) {
                    Button(action: { showingStockAdjustment = true }) {
                        Label("Ajuster le stock", systemImage: "plus.minus.circle")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    HStack(spacing: 12) {
                        Button(action: { increaseStock(by: 1) }) {
                            Label("+1", systemImage: "plus.circle.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        
                        Button(action: { decreaseStock(by: 1) }) {
                            Label("-1", systemImage: "minus.circle.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .disabled(medicine.currentQuantity == 0)
                    }
                }
                .padding(.horizontal)
                
                // Description
                if let description = medicine.description, !description.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Description", systemImage: "note.text")
                            .font(.headline)
                        
                        Text(description)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
                
                // Métadonnées
                VStack(alignment: .leading, spacing: 8) {
                    Text("Créé le \(medicine.createdAt, style: .date)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Modifié le \(medicine.updatedAt, style: .date)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                Spacer(minLength: 50)
            }
            .padding(.vertical)
        }
        .navigationTitle("Détails")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showingEditForm = true
                    } label: {
                        Label("Modifier", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Supprimer", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditForm) {
            NavigationStack {
                MedicineFormView(medicine: medicine)
                    .environmentObject(appState)
            }
        }
        .sheet(isPresented: $showingStockAdjustment) {
            NavigationStack {
                StockAdjustmentView(medicine: medicine)
                    .environmentObject(appState)
            }
        }
        .alert("Supprimer ce médicament ?", isPresented: $showingDeleteAlert) {
            Button("Annuler", role: .cancel) { }
            Button("Supprimer", role: .destructive) {
                deleteMedicine()
            }
        } message: {
            Text("Cette action est irréversible.")
        }
        } else {
            // Vue de fallback si le médicament n'existe plus
            ContentUnavailableView(
                "Médicament introuvable",
                systemImage: "pills",
                description: Text("Ce médicament n'existe plus dans la base de données.")
            )
            .onAppear {
                // Retourner automatiquement après un court délai
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    dismiss()
                }
            }
        }
    }
    
    private func increaseStock(by amount: Int) {
        guard let medicine = medicine else { return }
        Task {
            await appState.adjustStock(medicine: medicine, adjustment: amount, reason: "Ajustement rapide +\(amount)")
        }
    }
    
    private func decreaseStock(by amount: Int) {
        guard let medicine = medicine,
              medicine.currentQuantity >= amount else { return }
        
        Task {
            await appState.adjustStock(medicine: medicine, adjustment: -amount, reason: "Ajustement rapide -\(amount)")
        }
    }
    
    private func deleteMedicine() {
        guard let medicine = medicine else { return }
        Task {
            await appState.deleteMedicine(medicine)
            await MainActor.run {
                dismiss()
            }
        }
    }
}
//
//#Preview {
//    NavigationStack {
//        MedicineDetailView(medicine: Medicine(
//            id: "1",
//            name: "Paracétamol",
//            dosage: "500mg",
//            unit: "comprimé(s)",
//            currentQuantity: 50,
//            minQuantity: 20,
//            expirationDate: Date().addingTimeInterval(86400 * 60),
//            aisleId: "1",
//            notes: "À conserver à température ambiante",
//            createdAt: Date().addingTimeInterval(-86400 * 30),
//            updatedAt: Date()
//        ))
//        .environmentObject(MedicineListViewModel(medicineUseCase: MockGetMedicinesUseCase()))
//        .environmentObject(AisleListViewModel(aisleUseCase: MockGetAislesUseCase()))
//    }
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
//            Aisle(id: "1", name: "Rayon A", icon: "tray", color: Color.blue, createdAt: Date(), updatedAt: Date())
//        ]
//    }
//}
