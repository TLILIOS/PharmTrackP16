import Foundation
import Combine

@MainActor
class MedicineStockViewModel: ObservableObject {
    @Published var medicines: [Medicine] = []
    @Published var aisles: [String] = []
    @Published var aisleObjects: [Aisle] = []
    @Published var history: [HistoryEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var lastFetchTime: Date?
    private let cacheExpirationInterval: TimeInterval = 300
    
    private let medicineRepository: MedicineRepositoryProtocol
    private let aisleRepository: AisleRepositoryProtocol
    private let historyRepository: HistoryRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(
        medicineRepository: MedicineRepositoryProtocol,
        aisleRepository: AisleRepositoryProtocol,
        historyRepository: HistoryRepositoryProtocol
    ) {
        self.medicineRepository = medicineRepository
        self.aisleRepository = aisleRepository
        self.historyRepository = historyRepository
        startListening()
    }
    
    deinit {
        cancellables.removeAll()
    }
    
    private func startListening() {
        startMedicinesListener()
        startAislesListener()
    }
    
    private func startMedicinesListener() {
        medicineRepository.observeMedicines()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] medicines in
                    self?.medicines = medicines
                }
            )
            .store(in: &cancellables)
    }
    
    private func startAislesListener() {
        aisleRepository.observeAisles()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] aisles in
                    self?.aisleObjects = aisles
                    self?.aisles = aisles.map { $0.name }.sorted()
                }
            )
            .store(in: &cancellables)
    }
    
    func fetchMedicines() async {
        if let lastFetch = lastFetchTime,
           Date().timeIntervalSince(lastFetch) < cacheExpirationInterval,
           !medicines.isEmpty {
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            medicines = try await medicineRepository.getMedicines()
            lastFetchTime = Date()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func fetchAisles() async {
        if let lastFetch = lastFetchTime,
           Date().timeIntervalSince(lastFetch) < cacheExpirationInterval,
           !aisleObjects.isEmpty {
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            aisleObjects = try await aisleRepository.getAisles()
            aisles = aisleObjects.map { $0.name }.sorted()
            lastFetchTime = Date()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func addRandomMedicine(user: String) async {
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
            _ = try await medicineRepository.saveMedicine(medicine)
            await addHistory(action: "Added \(medicine.name)", user: user, medicineId: medicine.id, details: "Added new medicine")
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func deleteMedicines(at offsets: IndexSet) async {
        for index in offsets {
            let medicine = medicines[index]
            do {
                try await medicineRepository.deleteMedicine(id: medicine.id)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    
    func increaseStock(_ medicine: Medicine, user: String) async {
        await updateStock(medicine, by: 1, user: user)
    }
    
    func decreaseStock(_ medicine: Medicine, user: String) async {
        await updateStock(medicine, by: -1, user: user)
    }
    
    private func updateStock(_ medicine: Medicine, by amount: Int, user: String) async {
        let newStock = medicine.currentQuantity + amount
        
        do {
            _ = try await medicineRepository.updateMedicineStock(id: medicine.id, newStock: newStock)
            await addHistory(
                action: "\(amount > 0 ? "Increased" : "Decreased") stock of \(medicine.name) by \(abs(amount))",
                user: user,
                medicineId: medicine.id,
                details: "Stock changed from \(medicine.currentQuantity) to \(newStock)"
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func updateMedicine(_ medicine: Medicine, user: String) async {
        do {
            _ = try await medicineRepository.saveMedicine(medicine)
            await addHistory(action: "Updated \(medicine.name)", user: user, medicineId: medicine.id, details: "Updated medicine details")
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func addHistory(action: String, user: String, medicineId: String, details: String) async {
        let historyEntry = HistoryEntry(
            id: UUID().uuidString,
            medicineId: medicineId,
            userId: user,
            action: action,
            details: details,
            timestamp: Date()
        )
        
        do {
            try await historyRepository.addHistoryEntry(historyEntry)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func fetchHistory(for medicine: Medicine) async {
        do {
            history = try await historyRepository.getHistoryForMedicine(medicineId: medicine.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
