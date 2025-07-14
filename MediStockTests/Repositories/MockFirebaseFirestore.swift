import Foundation
import Firebase
import FirebaseFirestore
import Combine
@testable import MediStock

// MARK: - Mock Firestore Components

class MockFirestoreCollection {
    private var documents: [String: [String: Any]] = [:]
    private var shouldSucceed = true
    private var errorToThrow: Error?
    
    func setDocuments(_ documents: [String: [String: Any]]) {
        self.documents = documents
    }
    
    func setShouldSucceed(_ shouldSucceed: Bool) {
        self.shouldSucceed = shouldSucceed
    }
    
    func setErrorToThrow(_ error: Error?) {
        self.errorToThrow = error
    }
    
    func reset() {
        documents.removeAll()
        shouldSucceed = true
        errorToThrow = nil
    }
    
    func getDocuments() async throws -> [MockDocumentSnapshot] {
        if !shouldSucceed {
            throw errorToThrow ?? createFirestoreError()
        }
        
        return documents.map { (id, data) in
            MockDocumentSnapshot(documentID: id, data: data)
        }
    }
    
    func document(_ documentID: String) -> MockDocumentReference {
        return MockDocumentReference(documentID: documentID, collection: self)
    }
    
    func addDocument(data: [String: Any]) async throws -> MockDocumentReference {
        if !shouldSucceed {
            throw errorToThrow ?? createFirestoreError()
        }
        
        let documentID = UUID().uuidString
        documents[documentID] = data
        return MockDocumentReference(documentID: documentID, collection: self)
    }
    
    private func createFirestoreError() -> NSError {
        return NSError(domain: "FIRFirestoreErrorDomain", code: 14, userInfo: [
            NSLocalizedDescriptionKey: "Mock Firestore Error"
        ])
    }
}

class MockDocumentSnapshot {
    let documentID: String
    private let documentData: [String: Any]
    
    init(documentID: String, data: [String: Any]) {
        self.documentID = documentID
        self.documentData = data
    }
    
    func data() -> [String: Any]? {
        return documentData
    }
    
    var exists: Bool {
        return !documentData.isEmpty
    }
}

class MockDocumentReference {
    let documentID: String
    private weak var collection: MockFirestoreCollection?
    
    init(documentID: String, collection: MockFirestoreCollection) {
        self.documentID = documentID
        self.collection = collection
    }
    
    func getDocument() async throws -> MockDocumentSnapshot {
        guard let collection = collection else {
            throw NSError(domain: "FIRFirestoreErrorDomain", code: 14, userInfo: nil)
        }
        
        if !collection.shouldSucceed {
            throw collection.errorToThrow ?? NSError(domain: "FIRFirestoreErrorDomain", code: 14, userInfo: nil)
        }
        
        let data = collection.documents[documentID] ?? [:]
        return MockDocumentSnapshot(documentID: documentID, data: data)
    }
    
    func setData(_ data: [String: Any]) async throws {
        guard let collection = collection else {
            throw NSError(domain: "FIRFirestoreErrorDomain", code: 14, userInfo: nil)
        }
        
        if !collection.shouldSucceed {
            throw collection.errorToThrow ?? NSError(domain: "FIRFirestoreErrorDomain", code: 14, userInfo: nil)
        }
        
        collection.documents[documentID] = data
    }
    
    func updateData(_ data: [String: Any]) async throws {
        guard let collection = collection else {
            throw NSError(domain: "FIRFirestoreErrorDomain", code: 14, userInfo: nil)
        }
        
        if !collection.shouldSucceed {
            throw collection.errorToThrow ?? NSError(domain: "FIRFirestoreErrorDomain", code: 14, userInfo: nil)
        }
        
        if var existingData = collection.documents[documentID] {
            for (key, value) in data {
                existingData[key] = value
            }
            collection.documents[documentID] = existingData
        } else {
            collection.documents[documentID] = data
        }
    }
    
    func delete() async throws {
        guard let collection = collection else {
            throw NSError(domain: "FIRFirestoreErrorDomain", code: 14, userInfo: nil)
        }
        
        if !collection.shouldSucceed {
            throw collection.errorToThrow ?? NSError(domain: "FIRFirestoreErrorDomain", code: 14, userInfo: nil)
        }
        
        collection.documents.removeValue(forKey: documentID)
    }
}

// MARK: - Mock Firebase Aisle Repository

class MockFirebaseAisleRepository: AisleRepositoryProtocol {
    private let aislesCollection = MockFirestoreCollection()
    private let aislesSubject = PassthroughSubject<[Aisle], Never>()
    
    private var cachedAisles: [Aisle] = []
    
    init() {
        setupInitialData()
    }
    
    private func setupInitialData() {
        let testAisles = [
            createTestAisleDTO(id: "1", name: "Aisle 1"),
            createTestAisleDTO(id: "2", name: "Aisle 2")
        ]
        
        let documentsData = testAisles.reduce(into: [String: [String: Any]]()) { result, aisle in
            result[aisle.id] = [
                "name": aisle.name,
                "description": aisle.description ?? "",
                "colorHex": aisle.colorHex,
                "icon": aisle.icon
            ]
        }
        
        aislesCollection.setDocuments(documentsData)
        cachedAisles = testAisles.map { $0.toDomain() }
    }
    
    func getAisles() async throws -> [Aisle] {
        let snapshots = try await aislesCollection.getDocuments()
        let aisles = snapshots.compactMap { snapshot -> Aisle? in
            guard let data = snapshot.data() else { return nil }
            
            let dto = AisleDTO(
                id: snapshot.documentID,
                name: data["name"] as? String ?? "",
                description: data["description"] as? String,
                colorHex: data["colorHex"] as? String ?? "#FF0000",
                icon: data["icon"] as? String ?? "pills"
            )
            return dto.toDomain()
        }
        
        cachedAisles = aisles
        aislesSubject.send(aisles)
        return aisles
    }
    
    func addAisle(_ aisle: Aisle) async throws {
        let dto = AisleDTO.fromDomain(aisle)
        let data: [String: Any] = [
            "name": dto.name,
            "description": dto.description ?? "",
            "colorHex": dto.colorHex,
            "icon": dto.icon
        ]
        
        _ = try await aislesCollection.addDocument(data: data)
        cachedAisles.append(aisle)
        aislesSubject.send(cachedAisles)
    }
    
    func updateAisle(_ aisle: Aisle) async throws {
        let dto = AisleDTO.fromDomain(aisle)
        let data: [String: Any] = [
            "name": dto.name,
            "description": dto.description ?? "",
            "colorHex": dto.colorHex,
            "icon": dto.icon
        ]
        
        let docRef = aislesCollection.document(aisle.id)
        try await docRef.updateData(data)
        
        if let index = cachedAisles.firstIndex(where: { $0.id == aisle.id }) {
            cachedAisles[index] = aisle
        }
        aislesSubject.send(cachedAisles)
    }
    
    func deleteAisle(withId id: String) async throws {
        let docRef = aislesCollection.document(id)
        try await docRef.delete()
        
        cachedAisles.removeAll { $0.id == id }
        aislesSubject.send(cachedAisles)
    }
    
    func observeAisles() -> AnyPublisher<[Aisle], Never> {
        return aislesSubject.eraseToAnyPublisher()
    }
    
    func searchAisles(query: String) async throws -> [Aisle] {
        let allAisles = try await getAisles()
        return allAisles.filter { aisle in
            aisle.name.localizedCaseInsensitiveContains(query) ||
            (aisle.description?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }
    
    func getMedicineCountByAisle(aisleId: String) async throws -> Int {
        // Mock implementation - return random count for testing
        return Int.random(in: 0...20)
    }
    
    // MARK: - Test Configuration Methods
    
    func setShouldSucceed(_ shouldSucceed: Bool) {
        aislesCollection.setShouldSucceed(shouldSucceed)
    }
    
    func setErrorToThrow(_ error: Error) {
        aislesCollection.setErrorToThrow(error)
    }
    
    func setMockAisles(_ aisles: [Aisle]) {
        cachedAisles = aisles
        
        let documentsData = aisles.reduce(into: [String: [String: Any]]()) { result, aisle in
            result[aisle.id] = [
                "name": aisle.name,
                "description": aisle.description ?? "",
                "colorHex": aisle.colorHex,
                "icon": aisle.icon
            ]
        }
        
        aislesCollection.setDocuments(documentsData)
        aislesSubject.send(aisles)
    }
    
    func reset() {
        aislesCollection.reset()
        cachedAisles.removeAll()
        setupInitialData()
    }
    
    // MARK: - Helper Methods
    
    private func createTestAisleDTO(id: String, name: String) -> AisleDTO {
        return AisleDTO(
            id: id,
            name: name,
            description: "Test Description",
            colorHex: "#FF0000",
            icon: "pills"
        )
    }
}

// MARK: - Mock Firebase Medicine Repository

class MockFirebaseMedicineRepository: MedicineRepositoryProtocol {
    private let medicinesCollection = MockFirestoreCollection()
    private let medicinesSubject = PassthroughSubject<[Medicine], Never>()
    
    private var cachedMedicines: [Medicine] = []
    
    init() {
        setupInitialData()
    }
    
    private func setupInitialData() {
        let testMedicines = [
            createTestMedicineDTO(id: "1", name: "Medicine 1"),
            createTestMedicineDTO(id: "2", name: "Medicine 2")
        ]
        
        let documentsData = testMedicines.reduce(into: [String: [String: Any]]()) { result, medicine in
            result[medicine.id] = [
                "name": medicine.name,
                "aisleId": medicine.aisleId,
                "expirationDate": medicine.expirationDate.timeIntervalSince1970,
                "quantity": medicine.quantity,
                "minQuantity": medicine.minQuantity,
                "description": medicine.description ?? ""
            ]
        }
        
        medicinesCollection.setDocuments(documentsData)
        cachedMedicines = testMedicines.map { $0.toDomain() }
    }
    
    func getMedicines() async throws -> [Medicine] {
        let snapshots = try await medicinesCollection.getDocuments()
        let medicines = snapshots.compactMap { snapshot -> Medicine? in
            guard let data = snapshot.data() else { return nil }
            
            let dto = MedicineDTO(
                id: snapshot.documentID,
                name: data["name"] as? String ?? "",
                aisleId: data["aisleId"] as? String ?? "",
                expirationDate: Date(timeIntervalSince1970: data["expirationDate"] as? TimeInterval ?? 0),
                quantity: data["quantity"] as? Int ?? 0,
                minQuantity: data["minQuantity"] as? Int ?? 0,
                description: data["description"] as? String
            )
            return dto.toDomain()
        }
        
        cachedMedicines = medicines
        medicinesSubject.send(medicines)
        return medicines
    }
    
    func addMedicine(_ medicine: Medicine) async throws {
        let dto = MedicineDTO.fromDomain(medicine)
        let data: [String: Any] = [
            "name": dto.name,
            "aisleId": dto.aisleId,
            "expirationDate": dto.expirationDate.timeIntervalSince1970,
            "quantity": dto.quantity,
            "minQuantity": dto.minQuantity,
            "description": dto.description ?? ""
        ]
        
        _ = try await medicinesCollection.addDocument(data: data)
        cachedMedicines.append(medicine)
        medicinesSubject.send(cachedMedicines)
    }
    
    func updateMedicine(_ medicine: Medicine) async throws {
        let dto = MedicineDTO.fromDomain(medicine)
        let data: [String: Any] = [
            "name": dto.name,
            "aisleId": dto.aisleId,
            "expirationDate": dto.expirationDate.timeIntervalSince1970,
            "quantity": dto.quantity,
            "minQuantity": dto.minQuantity,
            "description": dto.description ?? ""
        ]
        
        let docRef = medicinesCollection.document(medicine.id)
        try await docRef.updateData(data)
        
        if let index = cachedMedicines.firstIndex(where: { $0.id == medicine.id }) {
            cachedMedicines[index] = medicine
        }
        medicinesSubject.send(cachedMedicines)
    }
    
    func deleteMedicine(withId id: String) async throws {
        let docRef = medicinesCollection.document(id)
        try await docRef.delete()
        
        cachedMedicines.removeAll { $0.id == id }
        medicinesSubject.send(cachedMedicines)
    }
    
    func getMedicine(withId id: String) async throws -> Medicine? {
        let docRef = medicinesCollection.document(id)
        let snapshot = try await docRef.getDocument()
        
        guard snapshot.exists, let data = snapshot.data() else {
            return nil
        }
        
        let dto = MedicineDTO(
            id: snapshot.documentID,
            name: data["name"] as? String ?? "",
            aisleId: data["aisleId"] as? String ?? "",
            expirationDate: Date(timeIntervalSince1970: data["expirationDate"] as? TimeInterval ?? 0),
            quantity: data["quantity"] as? Int ?? 0,
            minQuantity: data["minQuantity"] as? Int ?? 0,
            description: data["description"] as? String
        )
        
        return dto.toDomain()
    }
    
    func observeMedicines() -> AnyPublisher<[Medicine], Never> {
        return medicinesSubject.eraseToAnyPublisher()
    }
    
    func searchMedicines(query: String) async throws -> [Medicine] {
        let allMedicines = try await getMedicines()
        return allMedicines.filter { medicine in
            medicine.name.localizedCaseInsensitiveContains(query) ||
            (medicine.description?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }
    
    func updateMedicineStock(medicineId: String, newQuantity: Int) async throws {
        guard let medicine = try await getMedicine(withId: medicineId) else {
            throw NSError(domain: "Medicine not found", code: 404, userInfo: nil)
        }
        
        let updatedMedicine = Medicine(
            id: medicine.id,
            name: medicine.name,
            aisleId: medicine.aisleId,
            expirationDate: medicine.expirationDate,
            quantity: newQuantity,
            minQuantity: medicine.minQuantity,
            description: medicine.description
        )
        
        try await updateMedicine(updatedMedicine)
    }
    
    // MARK: - Test Configuration Methods
    
    func setShouldSucceed(_ shouldSucceed: Bool) {
        medicinesCollection.setShouldSucceed(shouldSucceed)
    }
    
    func setErrorToThrow(_ error: Error) {
        medicinesCollection.setErrorToThrow(error)
    }
    
    func setMockMedicines(_ medicines: [Medicine]) {
        cachedMedicines = medicines
        
        let documentsData = medicines.reduce(into: [String: [String: Any]]()) { result, medicine in
            result[medicine.id] = [
                "name": medicine.name,
                "aisleId": medicine.aisleId,
                "expirationDate": medicine.expirationDate.timeIntervalSince1970,
                "quantity": medicine.quantity,
                "minQuantity": medicine.minQuantity,
                "description": medicine.description ?? ""
            ]
        }
        
        medicinesCollection.setDocuments(documentsData)
        medicinesSubject.send(medicines)
    }
    
    func reset() {
        medicinesCollection.reset()
        cachedMedicines.removeAll()
        setupInitialData()
    }
    
    // MARK: - Helper Methods
    
    private func createTestMedicineDTO(id: String, name: String) -> MedicineDTO {
        return MedicineDTO(
            id: id,
            name: name,
            aisleId: "aisle-1",
            expirationDate: Date().addingTimeInterval(86400 * 30), // 30 days from now
            quantity: 10,
            minQuantity: 5,
            description: "Test Description"
        )
    }
}