import Foundation
import FirebaseFirestore
@MainActor
class MedicineStockViewModel: ObservableObject {
    @Published var medicines: [Medicine] = []
    @Published var aisles: [String] = []
    @Published var aisleObjects: [Aisle] = []
    @Published var history: [HistoryEntry] = []
    private var db = Firestore.firestore()
    @Published var isLoading = false
    func fetchMedicines() async {
        do {
            let querySnapshot = try await db.collection("medicines").getDocuments()
            await MainActor.run {
                self.medicines = querySnapshot.documents.compactMap { document in
                    try? document.data(as: Medicine.self)
                }
            }
        } catch {
            print("Error getting documents: \(error)")
        }
    }
    
    func fetchAisles() async {
        do {
            let querySnapshot = try await db.collection("medicines").getDocuments()
            let allMedicines = querySnapshot.documents.compactMap { document in
                try? document.data(as: Medicine.self)
            }
            await MainActor.run {
                self.aisles = Array(Set(allMedicines.map { $0.aisleId })).sorted()
            }
        } catch {
            print("Error getting documents: \(error)")
        }
    }
    
    func addRandomMedicine(user: String) {
        let medicine = Medicine(
            id: UUID().uuidString,
            name: "Medicine \(Int.random(in: 1...100))",
            description: "Randomly generated medicine",
            dosage: "500mg",
            form: "Tablet",
            reference: "RND-\(Int.random(in: 1000...9999))",
            unit: "tablet",
            currentQuantity: Int.random(in: 1...100),
            maxQuantity: 100,
            warningThreshold: 20,
            criticalThreshold: 10,
            expiryDate: Calendar.current.date(byAdding: .month, value: Int.random(in: 1...12), to: Date()),
            aisleId: "aisle-\(Int.random(in: 1...10))",
            createdAt: Date(),
            updatedAt: Date()
        )
        do {
            try db.collection("medicines").document(medicine.id).setData(from: medicine)
            addHistory(action: "Added \(medicine.name)", user: user, medicineId: medicine.id, details: "Added new medicine")
        } catch let error {
            print("Error adding document: \(error)")
        }
    }
    
    func deleteMedicines(at offsets: IndexSet) {
        offsets.map { medicines[$0] }.forEach { medicine in
            let id = medicine.id
            db.collection("medicines").document(id).delete { error in
                if let error = error {
                    print("Error removing document: \(error)")
                }
            }
        }
    }
    
    
    func increaseStock(_ medicine: Medicine, user: String) {
        updateStock(medicine, by: 1, user: user)
    }
    
    func decreaseStock(_ medicine: Medicine, user: String) {
        updateStock(medicine, by: -1, user: user)
    }
    
    private func updateStock(_ medicine: Medicine, by amount: Int, user: String) {
        let id = medicine.id
        let newStock = medicine.currentQuantity + amount
        db.collection("medicines").document(id).updateData([
            "currentQuantity": newStock
        ]) { error in
            if let error = error {
                print("Error updating stock: \(error)")
            } else {
                // Medicine struct is immutable, will be updated when Firestore data changes
                self.addHistory(action: "\(amount > 0 ? "Increased" : "Decreased") stock of \(medicine.name) by \(amount)", user: user, medicineId: id, details: "Stock changed from \(medicine.currentQuantity) to \(newStock)")
            }
        }
    }
    
    func updateMedicine(_ medicine: Medicine, user: String) {
        let id = medicine.id
        do {
            try db.collection("medicines").document(id).setData(from: medicine)
            addHistory(action: "Updated \(medicine.name)", user: user, medicineId: id, details: "Updated medicine details")
        } catch let error {
            print("Error updating document: \(error)")
        }
    }
    
    private func addHistory(action: String, user: String, medicineId: String, details: String) {
        let history = HistoryEntry(id: UUID().uuidString, medicineId: medicineId, userId: user, action: action, details: details, timestamp: Date())
        do {
            try db.collection("history").document(history.id).setData(from: history)
        } catch let error {
            print("Error adding history: \(error)")
        }
    }
    
    func fetchHistory(for medicine: Medicine) {
        let medicineId = medicine.id
        db.collection("history").whereField("medicineId", isEqualTo: medicineId).addSnapshotListener { (querySnapshot, error) in
            if let error = error {
                print("Error getting history: \(error)")
            } else {
                self.history = querySnapshot?.documents.compactMap { document in
                    try? document.data(as: HistoryEntry.self)
                } ?? []
            }
        }
    }
}
