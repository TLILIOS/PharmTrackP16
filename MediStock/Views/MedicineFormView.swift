import SwiftUI

struct MedicineFormView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
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
    
    private var isEditing: Bool {
        medicine != nil
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Informations générales") {
                    TextField("Nom du médicament", text: $name)
                        .textInputAutocapitalization(.words)
                    
                    TextField("Dosage (ex: 500mg)", text: $dosage)
                    
                    TextField("Forme (ex: comprimé, gélule)", text: $form)
                    
                    TextField("Référence", text: $reference)
                    
                    Picker("Unité", selection: $unit) {
                        Text("comprimé(s)").tag("comprimé(s)")
                        Text("gélule(s)").tag("gélule(s)")
                        Text("ampoule(s)").tag("ampoule(s)")
                        Text("flacon(s)").tag("flacon(s)")
                        Text("tube(s)").tag("tube(s)")
                        Text("boîte(s)").tag("boîte(s)")
                    }
                }
                
                Section("Stock") {
                    HStack {
                        Text("Quantité actuelle")
                        Spacer()
                        TextField("0", text: $currentQuantity)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    
                    HStack {
                        Text("Quantité maximale")
                        Spacer()
                        TextField("0", text: $maxQuantity)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    
                    HStack {
                        Text("Seuil d'alerte")
                        Spacer()
                        TextField("0", text: $warningThreshold)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    
                    HStack {
                        Text("Seuil critique")
                        Spacer()
                        TextField("0", text: $criticalThreshold)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }
                
                Section("Emplacement et expiration") {
                    Picker("Rayon", selection: $selectedAisleId) {
                        Text("Sélectionner un rayon").tag("")
                        ForEach(appState.aisles) { aisle in
                            Label(aisle.name, systemImage: aisle.icon)
                                .tag(aisle.id)
                        }
                    }
                    
                    DatePicker("Date d'expiration", 
                              selection: $expirationDate,
                              displayedComponents: .date)
                }
                
                Section("Description") {
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle(isEditing ? "Modifier médicament" : "Nouveau médicament")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Enregistrer" : "Ajouter") {
                        saveMedicine()
                    }
                    .disabled(name.isEmpty || selectedAisleId.isEmpty || isLoading)
                }
            }
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
