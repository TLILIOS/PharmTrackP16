import Foundation
import Combine
import FirebaseFirestore
@testable import MediStock

// MARK: - Mock Medicine Repository
/// Repository mock qui délègue vers MockMedicineDataService
/// pour tester la vraie logique de délégation

class MockMedicineRepository: MedicineRepositoryProtocol {
    private let medicineService: MockMedicineDataService
    private var listener: ListenerRegistration?

    // Expose les call counts du service pour vérification
    var fetchMedicinesCallCount: Int { medicineService.getAllMedicinesCallCount }
    var saveMedicineCallCount: Int { medicineService.saveMedicineCallCount }
    var updateStockCallCount: Int { medicineService.updateStockCallCount }
    var deleteMedicineCallCount: Int { medicineService.deleteMedicineCallCount }

    // Raccourcis pour configuration des tests
    var medicines: [Medicine] {
        get { medicineService.medicines }
        set { medicineService.medicines = newValue }
    }

    var shouldThrowError: Bool {
        get { medicineService.shouldFailGetMedicines }
        set {
            medicineService.shouldFailGetMedicines = newValue
            medicineService.shouldFailSaveMedicine = newValue
            medicineService.shouldFailDeleteMedicine = newValue
            medicineService.shouldFailUpdateStock = newValue
        }
    }

    init(medicineService: MockMedicineDataService = MockMedicineDataService()) {
        self.medicineService = medicineService
    }

    func fetchMedicines() async throws -> [Medicine] {
        return try await medicineService.getAllMedicines()
    }

    func fetchMedicinesPaginated(limit: Int, refresh: Bool) async throws -> [Medicine] {
        return try await medicineService.getMedicinesPaginated(limit: limit, refresh: refresh)
    }

    func saveMedicine(_ medicine: Medicine) async throws -> Medicine {
        return try await medicineService.saveMedicine(medicine)
    }

    func updateMedicineStock(id: String, newStock: Int) async throws -> Medicine {
        return try await medicineService.updateMedicineStock(id: id, newStock: newStock)
    }

    func deleteMedicine(id: String) async throws {
        guard let medicine = try await medicineService.getMedicine(by: id) else {
            throw NSError(domain: "MedicineRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "Médicament non trouvé"])
        }
        try await medicineService.deleteMedicine(medicine)
    }

    func updateMultipleMedicines(_ medicines: [Medicine]) async throws {
        try await medicineService.updateMultipleMedicines(medicines)
    }

    func deleteMultipleMedicines(ids: [String]) async throws {
        for id in ids {
            try await deleteMedicine(id: id)
        }
    }

    func startListeningToMedicines(completion: @escaping ([Medicine]) -> Void) {
        listener = medicineService.createMedicinesListener(completion: completion)
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }
}

// MARK: - Mock Aisle Repository
/// Repository mock qui délègue vers MockAisleDataService
/// pour tester la vraie logique de délégation

class MockAisleRepository: AisleRepositoryProtocol {
    private let aisleService: MockAisleDataService
    private var listener: ListenerRegistration?

    // Raccourcis pour configuration des tests
    var aisles: [Aisle] {
        get { aisleService.aisles }
        set { aisleService.aisles = newValue }
    }

    var shouldThrowError: Bool {
        get { aisleService.shouldFailGetAisles }
        set {
            aisleService.shouldFailGetAisles = newValue
            aisleService.shouldFailSaveAisle = newValue
            aisleService.shouldFailDeleteAisle = newValue
        }
    }

    init(aisleService: MockAisleDataService = MockAisleDataService()) {
        self.aisleService = aisleService
    }

    func fetchAisles() async throws -> [Aisle] {
        return try await aisleService.getAllAisles()
    }

    func fetchAislesPaginated(limit: Int, refresh: Bool) async throws -> [Aisle] {
        return try await aisleService.getAislesPaginated(limit: limit, refresh: refresh)
    }

    func saveAisle(_ aisle: Aisle) async throws -> Aisle {
        return try await aisleService.saveAisle(aisle)
    }

    func deleteAisle(id: String) async throws {
        guard let aisle = try await aisleService.getAisle(by: id) else {
            throw NSError(domain: "AisleRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "Rayon non trouvé"])
        }
        try await aisleService.deleteAisle(aisle)
    }

    func startListeningToAisles(completion: @escaping ([Aisle]) -> Void) {
        listener = aisleService.createAislesListener(completion: completion)
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }
}

// MARK: - Mock History Repository
/// Repository mock qui délègue vers MockHistoryDataService
/// pour tester la vraie logique de délégation

class MockHistoryRepository: HistoryRepositoryProtocol {
    private let historyService: MockHistoryDataService

    // Expose les call counts du service pour vérification
    var addHistoryEntryCallCount: Int { historyService.recordMedicineActionCallCount }

    // Raccourcis pour configuration des tests
    var history: [HistoryEntry] {
        get { historyService.history }
        set { historyService.history = newValue }
    }

    var shouldThrowError: Bool {
        get { historyService.shouldFailGetHistory }
        set {
            historyService.shouldFailGetHistory = newValue
            historyService.shouldFailRecordAction = newValue
        }
    }

    init(historyService: MockHistoryDataService = MockHistoryDataService()) {
        self.historyService = historyService
    }

    func fetchHistory() async throws -> [HistoryEntry] {
        return try await historyService.getHistory(medicineId: nil)
    }

    func fetchHistoryForMedicine(_ medicineId: String) async throws -> [HistoryEntry] {
        return try await historyService.getHistory(medicineId: medicineId)
    }

    func addHistoryEntry(_ entry: HistoryEntry) async throws {
        if !entry.medicineId.isEmpty {
            let medicineName = extractMedicineName(from: entry.details)
            try await historyService.recordMedicineAction(
                medicineId: entry.medicineId,
                medicineName: medicineName,
                action: entry.action,
                details: entry.details
            )
        } else {
            try await historyService.recordDeletion(
                itemType: "general",
                itemId: entry.id,
                itemName: "",
                details: entry.details
            )
        }
    }

    private func extractMedicineName(from details: String) -> String {
        if let range = details.range(of: "médicament ") {
            let afterMedicine = String(details[range.upperBound...])
            let name = afterMedicine.split(separator: " ").first ?? ""
            return String(name)
        }
        return ""
    }
}

// MARK: - Mock Auth Repository

@MainActor
class MockAuthRepository: AuthRepositoryProtocol {
    @Published var currentUser: User?
    var signInCallCount = 0
    var signOutCallCount = 0
    var shouldThrowError = false

    var currentUserPublisher: Published<User?>.Publisher {
        $currentUser
    }

    init() {
        self.currentUser = nil
    }

    func signIn(email: String, password: String) async throws {
        signInCallCount += 1
        if shouldThrowError {
            throw NSError(domain: "Test", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid credentials"])
        }

        currentUser = User(
            id: "test-user-id",
            email: email,
            displayName: "Test User"
        )
    }

    func signUp(email: String, password: String, displayName: String) async throws {
        if shouldThrowError {
            throw NSError(domain: "Test", code: 0)
        }

        currentUser = User(
            id: "new-user-id",
            email: email,
            displayName: displayName
        )
    }

    func signOut() async throws {
        signOutCallCount += 1
        if shouldThrowError {
            throw NSError(domain: "Test", code: 0)
        }
        currentUser = nil
    }

    func getCurrentUser() -> User? {
        return currentUser
    }
}

// MARK: - Mock Notification Service

class MockNotificationService: NotificationService {
    var checkExpirationsCallCount = 0

    override func checkExpirations(medicines: [Medicine]) async {
        checkExpirationsCallCount += 1
    }
}

// MARK: - Mock PDF Export Service

class MockPDFExportService: PDFExportServiceProtocol {
    var generateInventoryReportCallCount = 0
    var generateHistoryReportCallCount = 0
    var generateStockHistoryReportCallCount = 0
    var shouldThrowError = false
    var mockPDFData = Data()

    func generateInventoryReport(medicines: [Medicine], aisles: [Aisle], authorName: String) async throws -> Data {
        generateInventoryReportCallCount += 1

        if shouldThrowError {
            throw NSError(domain: "MockPDFExportService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }

        return mockPDFData
    }

    func generateHistoryReport(
        entries: [HistoryEntry],
        statistics: HistoryStatistics?,
        dateRange: String,
        authorName: String
    ) async throws -> Data {
        generateHistoryReportCallCount += 1

        if shouldThrowError {
            throw NSError(domain: "MockPDFExportService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }

        return mockPDFData
    }

    func generateStockHistoryReport(
        entries: [StockHistory],
        medicines: [String: String],
        filterType: String,
        authorName: String
    ) async throws -> Data {
        generateStockHistoryReportCallCount += 1

        if shouldThrowError {
            throw NSError(domain: "MockPDFExportService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }

        return mockPDFData
    }
}

// MARK: - Mock Auth Service (Standalone)

@MainActor
class MockAuthServiceStandalone: ObservableObject {
    @Published var currentUser: User?
    var signInCallCount = 0
    var signUpCallCount = 0
    var signOutCallCount = 0
    var resetPasswordCallCount = 0
    var shouldThrowError = false
    var errorToThrow: Error?

    init() {
        self.currentUser = nil
    }

    func signIn(email: String, password: String) async throws {
        signInCallCount += 1

        if shouldThrowError {
            throw errorToThrow ?? AuthError.unknownError(NSError(domain: "MockAuthService", code: 0))
        }

        // Validation basique pour les tests
        guard !email.isEmpty else {
            throw AuthError.invalidEmail
        }
        guard !password.isEmpty else {
            throw AuthError.wrongPassword
        }
        guard email.contains("@") else {
            throw AuthError.invalidEmail
        }

        currentUser = User(
            id: "mock-user-\(UUID().uuidString)",
            email: email,
            displayName: "Mock User"
        )
    }

    func signUp(email: String, password: String, displayName: String) async throws {
        signUpCallCount += 1

        if shouldThrowError {
            throw errorToThrow ?? AuthError.unknownError(NSError(domain: "MockAuthService", code: 0))
        }

        // Validation basique
        guard !email.isEmpty else {
            throw AuthError.invalidEmail
        }
        guard !password.isEmpty else {
            throw AuthError.weakPassword
        }
        guard password.count >= 6 else {
            throw AuthError.weakPassword
        }

        currentUser = User(
            id: "mock-user-\(UUID().uuidString)",
            email: email,
            displayName: displayName
        )
    }

    func signOut() async throws {
        signOutCallCount += 1

        if shouldThrowError {
            throw errorToThrow ?? AuthError.unknownError(NSError(domain: "MockAuthService", code: 0))
        }

        currentUser = nil
    }

    func resetPassword(email: String) async throws {
        resetPasswordCallCount += 1

        if shouldThrowError {
            throw errorToThrow ?? AuthError.unknownError(NSError(domain: "MockAuthService", code: 0))
        }

        guard !email.isEmpty else {
            throw AuthError.invalidEmail
        }
        guard email.contains("@") else {
            throw AuthError.invalidEmail
        }
    }

    func getCurrentUser() -> User? {
        return currentUser
    }
}

// MARK: - Sample Data for Previews and Tests

extension MockMedicineRepository {
    static func withSampleData() -> MockMedicineRepository {
        let mockService = MockMedicineDataService()
        mockService.medicines = [
            Medicine(
                id: "1",
                name: "Paracétamol",
                description: "Antalgique et antipyrétique",
                dosage: "500mg",
                form: "Comprimé",
                reference: "PAR-500",
                unit: "comprimés",
                currentQuantity: 100,
                maxQuantity: 200,
                warningThreshold: 50,
                criticalThreshold: 20,
                expiryDate: Calendar.current.date(byAdding: .month, value: 6, to: Date()),
                aisleId: "aisle1",
                createdAt: Date(),
                updatedAt: Date()
            ),
            Medicine(
                id: "2",
                name: "Ibuprofène",
                description: "Anti-inflammatoire",
                dosage: "400mg",
                form: "Comprimé",
                reference: "IBU-400",
                unit: "comprimés",
                currentQuantity: 15,
                maxQuantity: 150,
                warningThreshold: 30,
                criticalThreshold: 10,
                expiryDate: Calendar.current.date(byAdding: .day, value: 15, to: Date()),
                aisleId: "aisle1",
                createdAt: Date(),
                updatedAt: Date()
            )
        ]
        return MockMedicineRepository(medicineService: mockService)
    }
}

extension MockAisleRepository {
    static func withSampleData() -> MockAisleRepository {
        let mockService = MockAisleDataService()

        var aisle1 = Aisle(
            name: "Antalgiques",
            description: "Médicaments contre la douleur",
            colorHex: "#FF6B6B",
            icon: "pills.fill"
        )
        aisle1.id = "aisle1"

        var aisle2 = Aisle(
            name: "Antibiotiques",
            description: "Médicaments antibactériens",
            colorHex: "#4ECDC4",
            icon: "cross.case.fill"
        )
        aisle2.id = "aisle2"

        mockService.aisles = [aisle1, aisle2]
        return MockAisleRepository(aisleService: mockService)
    }
}

extension MockHistoryRepository {
    static func withSampleData() -> MockHistoryRepository {
        let mockService = MockHistoryDataService()
        mockService.history = [
            HistoryEntry(
                id: "h1",
                medicineId: "1",
                userId: "user1",
                action: "Ajout stock",
                details: "Ajout de 50 comprimés",
                timestamp: Date()
            ),
            HistoryEntry(
                id: "h2",
                medicineId: "2",
                userId: "user1",
                action: "Modification",
                details: "Mise à jour des seuils d'alerte",
                timestamp: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date()
            )
        ]
        return MockHistoryRepository(historyService: mockService)
    }
}