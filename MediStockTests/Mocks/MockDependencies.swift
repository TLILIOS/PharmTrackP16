import Foundation
import Combine
import Firebase
import FirebaseAuth
import FirebaseFirestore
@testable import MediStock

// MARK: - Mock Firebase Auth Implementation

class MockFirebaseAuth {
    static let shared = MockFirebaseAuth()
    
    var currentUser: MockFirebaseUser?
    var shouldSucceed = true
    var errorToThrow: Error?
    private let authStateSubject = PassthroughSubject<MockFirebaseUser?, Never>()
    
    func reset() {
        currentUser = nil
        shouldSucceed = true
        errorToThrow = nil
    }
    
    func setCurrentUser(_ user: MockFirebaseUser?) {
        currentUser = user
        authStateSubject.send(user)
    }
    
    func signIn(email: String, password: String) async throws -> MockFirebaseUser {
        if !shouldSucceed {
            throw errorToThrow ?? createAuthError(.wrongPassword)
        }
        
        if email.isEmpty { throw createAuthError(.invalidEmail) }
        if password.isEmpty { throw createAuthError(.wrongPassword) }
        
        let user = MockFirebaseUser(uid: "mock-uid", email: email, displayName: nil)
        setCurrentUser(user)
        return user
    }
    
    func createUser(email: String, password: String) async throws -> MockFirebaseUser {
        if !shouldSucceed {
            throw errorToThrow ?? createAuthError(.emailAlreadyInUse)
        }
        
        if email.isEmpty { throw createAuthError(.invalidEmail) }
        if password.count < 6 { throw createAuthError(.weakPassword) }
        
        let user = MockFirebaseUser(uid: "mock-new-uid", email: email, displayName: nil)
        setCurrentUser(user)
        return user
    }
    
    func signOut() throws {
        if !shouldSucceed {
            throw errorToThrow ?? createAuthError(.networkError)
        }
        setCurrentUser(nil)
    }
    
    func sendPasswordReset(email: String) async throws {
        if !shouldSucceed {
            throw errorToThrow ?? createAuthError(.userNotFound)
        }
        if email.isEmpty { throw createAuthError(.invalidEmail) }
    }
    
    var authStateDidChange: AnyPublisher<MockFirebaseUser?, Never> {
        return authStateSubject.eraseToAnyPublisher()
    }
    
    private func createAuthError(_ code: AuthErrorCode) -> NSError {
        return NSError(domain: AuthErrorDomain, code: code.rawValue, userInfo: [
            NSLocalizedDescriptionKey: "Mock Firebase Auth Error"
        ])
    }
}

class MockFirebaseUser {
    let uid: String
    let email: String?
    let displayName: String?
    
    init(uid: String, email: String?, displayName: String?) {
        self.uid = uid
        self.email = email
        self.displayName = displayName
    }
}

// MARK: - Mock Firestore Implementation

class MockFirestore {
    static let shared = MockFirestore()
    
    private var collections: [String: MockCollection] = [:]
    var shouldSucceed = true
    var errorToThrow: Error?
    
    func reset() {
        collections.removeAll()
        shouldSucceed = true
        errorToThrow = nil
        setupInitialData()
    }
    
    private func setupInitialData() {
        // Setup test aisles
        let aislesCollection = MockCollection()
        aislesCollection.addDocument(id: "1", data: [
            "name": "Aisle 1",
            "description": "Test Aisle 1",
            "colorHex": "#FF0000",
            "icon": "pills"
        ])
        aislesCollection.addDocument(id: "2", data: [
            "name": "Aisle 2", 
            "description": "Test Aisle 2",
            "colorHex": "#00FF00",
            "icon": "pills"
        ])
        collections["aisles"] = aislesCollection
        
        // Setup test medicines
        let medicinesCollection = MockCollection()
        medicinesCollection.addDocument(id: "1", data: [
            "name": "Medicine 1",
            "aisleId": "1",
            "expirationDate": Date().addingTimeInterval(86400 * 30).timeIntervalSince1970,
            "quantity": 10,
            "minQuantity": 5,
            "description": "Test Medicine 1"
        ])
        medicinesCollection.addDocument(id: "2", data: [
            "name": "Medicine 2",
            "aisleId": "2", 
            "expirationDate": Date().addingTimeInterval(86400 * 60).timeIntervalSince1970,
            "quantity": 20,
            "minQuantity": 10,
            "description": "Test Medicine 2"
        ])
        collections["medicines"] = medicinesCollection
    }
    
    func collection(_ path: String) -> MockCollection {
        if let existing = collections[path] {
            return existing
        }
        let newCollection = MockCollection()
        collections[path] = newCollection
        return newCollection
    }
    
    private func createFirestoreError() -> NSError {
        return NSError(domain: "FIRFirestoreErrorDomain", code: 14, userInfo: [
            NSLocalizedDescriptionKey: "Mock Firestore Error"
        ])
    }
}

class MockCollection {
    private var documents: [String: [String: Any]] = [:]
    private let documentsSubject = PassthroughSubject<[MockDocumentSnapshot], Never>()
    
    func addDocument(id: String, data: [String: Any]) {
        documents[id] = data
        emitDocuments()
    }
    
    func getDocuments() async throws -> [MockDocumentSnapshot] {
        if !MockFirestore.shared.shouldSucceed {
            throw MockFirestore.shared.errorToThrow ?? createError()
        }
        
        let snapshots = documents.map { (id, data) in
            MockDocumentSnapshot(documentID: id, data: data, exists: true)
        }
        return snapshots
    }
    
    func document(_ id: String) -> MockDocumentReference {
        return MockDocumentReference(documentID: id, collection: self)
    }
    
    func addDocument(data: [String: Any]) async throws -> MockDocumentReference {
        if !MockFirestore.shared.shouldSucceed {
            throw MockFirestore.shared.errorToThrow ?? createError()
        }
        
        let id = UUID().uuidString
        documents[id] = data
        emitDocuments()
        return MockDocumentReference(documentID: id, collection: self)
    }
    
    var snapshotPublisher: AnyPublisher<[MockDocumentSnapshot], Never> {
        return documentsSubject.eraseToAnyPublisher()
    }
    
    private func emitDocuments() {
        let snapshots = documents.map { (id, data) in
            MockDocumentSnapshot(documentID: id, data: data, exists: true)
        }
        documentsSubject.send(snapshots)
    }
    
    private func createError() -> NSError {
        return NSError(domain: "FIRFirestoreErrorDomain", code: 14, userInfo: [
            NSLocalizedDescriptionKey: "Mock Collection Error"
        ])
    }
}

class MockDocumentSnapshot {
    let documentID: String
    private let documentData: [String: Any]
    let exists: Bool
    
    init(documentID: String, data: [String: Any], exists: Bool = true) {
        self.documentID = documentID
        self.documentData = data
        self.exists = exists
    }
    
    func data() -> [String: Any]? {
        return exists ? documentData : nil
    }
}

class MockDocumentReference {
    let documentID: String
    private weak var collection: MockCollection?
    
    init(documentID: String, collection: MockCollection) {
        self.documentID = documentID
        self.collection = collection
    }
    
    func getDocument() async throws -> MockDocumentSnapshot {
        if !MockFirestore.shared.shouldSucceed {
            throw MockFirestore.shared.errorToThrow ?? createError()
        }
        
        guard let collection = collection else {
            return MockDocumentSnapshot(documentID: documentID, data: [:], exists: false)
        }
        
        let data = collection.documents[documentID] ?? [:]
        return MockDocumentSnapshot(documentID: documentID, data: data, exists: !data.isEmpty)
    }
    
    func setData(_ data: [String: Any]) async throws {
        if !MockFirestore.shared.shouldSucceed {
            throw MockFirestore.shared.errorToThrow ?? createError()
        }
        
        collection?.addDocument(id: documentID, data: data)
    }
    
    func updateData(_ data: [String: Any]) async throws {
        if !MockFirestore.shared.shouldSucceed {
            throw MockFirestore.shared.errorToThrow ?? createError()
        }
        
        guard let collection = collection else { return }
        
        var existingData = collection.documents[documentID] ?? [:]
        for (key, value) in data {
            existingData[key] = value
        }
        collection.addDocument(id: documentID, data: existingData)
    }
    
    func delete() async throws {
        if !MockFirestore.shared.shouldSucceed {
            throw MockFirestore.shared.errorToThrow ?? createError()
        }
        
        collection?.documents.removeValue(forKey: documentID)
    }
    
    private func createError() -> NSError {
        return NSError(domain: "FIRFirestoreErrorDomain", code: 14, userInfo: [
            NSLocalizedDescriptionKey: "Mock Document Error"
        ])
    }
}

// MARK: - Test Dependency Container

class TestDependencyContainer {
    static let shared = TestDependencyContainer()
    
    private let mockAuth = MockFirebaseAuth.shared
    private let mockFirestore = MockFirestore.shared
    
    func reset() {
        mockAuth.reset()
        mockFirestore.reset()
    }
    
    func createAuthRepository() -> TestableAuthRepository {
        return TestableAuthRepository(mockAuth: mockAuth)
    }
    
    func createAisleRepository() -> TestableAisleRepository {
        return TestableAisleRepository(mockFirestore: mockFirestore)
    }
    
    func createMedicineRepository() -> TestableMedicineRepository {
        return TestableMedicineRepository(mockFirestore: mockFirestore)
    }
}

// MARK: - Testable Repository Implementations

class TestableAuthRepository: AuthRepositoryProtocol {
    private let mockAuth: MockFirebaseAuth
    
    init(mockAuth: MockFirebaseAuth) {
        self.mockAuth = mockAuth
    }
    
    var currentUser: User? {
        guard let mockUser = mockAuth.currentUser else { return nil }
        return User(id: mockUser.uid, email: mockUser.email, displayName: mockUser.displayName)
    }
    
    var authStateDidChange: AnyPublisher<User?, Never> {
        return mockAuth.authStateDidChange
            .map { mockUser in
                mockUser.map { User(id: $0.uid, email: $0.email, displayName: $0.displayName) }
            }
            .eraseToAnyPublisher()
    }
    
    func signIn(email: String, password: String) async throws -> User {
        let mockUser = try await mockAuth.signIn(email: email, password: password)
        return User(id: mockUser.uid, email: mockUser.email, displayName: mockUser.displayName)
    }
    
    func signUp(email: String, password: String) async throws -> User {
        let mockUser = try await mockAuth.createUser(email: email, password: password)
        return User(id: mockUser.uid, email: mockUser.email, displayName: mockUser.displayName)
    }
    
    func signOut() async throws {
        try mockAuth.signOut()
    }
    
    func resetPassword(email: String) async throws {
        try await mockAuth.sendPasswordReset(email: email)
    }
    
    func updateUserProfile(user: User) async throws {
        // Mock implementation
    }
}

class TestableAisleRepository: AisleRepositoryProtocol {
    private let mockFirestore: MockFirestore
    
    init(mockFirestore: MockFirestore) {
        self.mockFirestore = mockFirestore
    }
    
    func getAisles() async throws -> [Aisle] {
        let collection = mockFirestore.collection("aisles")
        let snapshots = try await collection.getDocuments()
        
        return snapshots.compactMap { snapshot in
            guard let data = snapshot.data() else { return nil }
            
            return Aisle(
                id: snapshot.documentID,
                name: data["name"] as? String ?? "",
                description: data["description"] as? String,
                colorHex: data["colorHex"] as? String ?? "#FF0000",
                icon: data["icon"] as? String ?? "pills"
            )
        }
    }
    
    func addAisle(_ aisle: Aisle) async throws {
        let collection = mockFirestore.collection("aisles")
        let data: [String: Any] = [
            "name": aisle.name,
            "description": aisle.description ?? "",
            "colorHex": aisle.colorHex,
            "icon": aisle.icon
        ]
        
        if aisle.id.isEmpty {
            _ = try await collection.addDocument(data: data)
        } else {
            try await collection.document(aisle.id).setData(data)
        }
    }
    
    func updateAisle(_ aisle: Aisle) async throws {
        let collection = mockFirestore.collection("aisles")
        let data: [String: Any] = [
            "name": aisle.name,
            "description": aisle.description ?? "",
            "colorHex": aisle.colorHex,
            "icon": aisle.icon
        ]
        
        try await collection.document(aisle.id).updateData(data)
    }
    
    func deleteAisle(withId id: String) async throws {
        let collection = mockFirestore.collection("aisles")
        try await collection.document(id).delete()
    }
    
    func observeAisles() -> AnyPublisher<[Aisle], Never> {
        let collection = mockFirestore.collection("aisles")
        
        return collection.snapshotPublisher
            .map { snapshots in
                snapshots.compactMap { snapshot in
                    guard let data = snapshot.data() else { return nil }
                    
                    return Aisle(
                        id: snapshot.documentID,
                        name: data["name"] as? String ?? "",
                        description: data["description"] as? String,
                        colorHex: data["colorHex"] as? String ?? "#FF0000",
                        icon: data["icon"] as? String ?? "pills"
                    )
                }
            }
            .eraseToAnyPublisher()
    }
    
    func searchAisles(query: String) async throws -> [Aisle] {
        let allAisles = try await getAisles()
        if query.isEmpty {
            return allAisles
        }
        
        return allAisles.filter { aisle in
            aisle.name.localizedCaseInsensitiveContains(query) ||
            (aisle.description?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }
    
    func getMedicineCountByAisle(aisleId: String) async throws -> Int {
        // Mock implementation
        return Int.random(in: 0...10)
    }
}

class TestableMedicineRepository: MedicineRepositoryProtocol {
    private let mockFirestore: MockFirestore
    
    init(mockFirestore: MockFirestore) {
        self.mockFirestore = mockFirestore
    }
    
    func getMedicines() async throws -> [Medicine] {
        let collection = mockFirestore.collection("medicines")
        let snapshots = try await collection.getDocuments()
        
        return snapshots.compactMap { snapshot in
            guard let data = snapshot.data() else { return nil }
            
            return Medicine(
                id: snapshot.documentID,
                name: data["name"] as? String ?? "",
                aisleId: data["aisleId"] as? String ?? "",
                expirationDate: Date(timeIntervalSince1970: data["expirationDate"] as? TimeInterval ?? 0),
                quantity: data["quantity"] as? Int ?? 0,
                minQuantity: data["minQuantity"] as? Int ?? 0,
                description: data["description"] as? String
            )
        }
    }
    
    func addMedicine(_ medicine: Medicine) async throws {
        let collection = mockFirestore.collection("medicines")
        let data: [String: Any] = [
            "name": medicine.name,
            "aisleId": medicine.aisleId,
            "expirationDate": medicine.expirationDate.timeIntervalSince1970,
            "quantity": medicine.quantity,
            "minQuantity": medicine.minQuantity,
            "description": medicine.description ?? ""
        ]
        
        if medicine.id.isEmpty {
            _ = try await collection.addDocument(data: data)
        } else {
            try await collection.document(medicine.id).setData(data)
        }
    }
    
    func updateMedicine(_ medicine: Medicine) async throws {
        let collection = mockFirestore.collection("medicines")
        let data: [String: Any] = [
            "name": medicine.name,
            "aisleId": medicine.aisleId,
            "expirationDate": medicine.expirationDate.timeIntervalSince1970,
            "quantity": medicine.quantity,
            "minQuantity": medicine.minQuantity,
            "description": medicine.description ?? ""
        ]
        
        try await collection.document(medicine.id).updateData(data)
    }
    
    func deleteMedicine(withId id: String) async throws {
        let collection = mockFirestore.collection("medicines")
        try await collection.document(id).delete()
    }
    
    func getMedicine(withId id: String) async throws -> Medicine? {
        let collection = mockFirestore.collection("medicines")
        let snapshot = try await collection.document(id).getDocument()
        
        guard snapshot.exists, let data = snapshot.data() else {
            return nil
        }
        
        return Medicine(
            id: snapshot.documentID,
            name: data["name"] as? String ?? "",
            aisleId: data["aisleId"] as? String ?? "",
            expirationDate: Date(timeIntervalSince1970: data["expirationDate"] as? TimeInterval ?? 0),
            quantity: data["quantity"] as? Int ?? 0,
            minQuantity: data["minQuantity"] as? Int ?? 0,
            description: data["description"] as? String
        )
    }
    
    func observeMedicines() -> AnyPublisher<[Medicine], Never> {
        let collection = mockFirestore.collection("medicines")
        
        return collection.snapshotPublisher
            .map { snapshots in
                snapshots.compactMap { snapshot in
                    guard let data = snapshot.data() else { return nil }
                    
                    return Medicine(
                        id: snapshot.documentID,
                        name: data["name"] as? String ?? "",
                        aisleId: data["aisleId"] as? String ?? "",
                        expirationDate: Date(timeIntervalSince1970: data["expirationDate"] as? TimeInterval ?? 0),
                        quantity: data["quantity"] as? Int ?? 0,
                        minQuantity: data["minQuantity"] as? Int ?? 0,
                        description: data["description"] as? String
                    )
                }
            }
            .eraseToAnyPublisher()
    }
    
    func searchMedicines(query: String) async throws -> [Medicine] {
        let allMedicines = try await getMedicines()
        if query.isEmpty {
            return allMedicines
        }
        
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
}