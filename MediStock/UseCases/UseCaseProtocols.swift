import Foundation

// MARK: - Authentication Use Case Protocols

protocol SignInUseCaseProtocol {
    func execute(email: String, password: String) async throws
}

protocol SignUpUseCaseProtocol {
    func execute(email: String, password: String, name: String) async throws
}

protocol GetUserUseCaseProtocol {
    func execute() async throws -> User
}

protocol SignOutUseCaseProtocol {
    func execute() async throws
}

// MARK: - Medicine Use Case Protocols

protocol GetMedicinesUseCaseProtocol {
    func execute() async throws -> [Medicine]
}

protocol GetMedicineUseCaseProtocol {
    func execute(id: String) async throws -> Medicine
}

protocol AddMedicineUseCaseProtocol {
    func execute(medicine: Medicine) async throws
}

protocol UpdateMedicineUseCaseProtocol {
    func execute(medicine: Medicine) async throws
}

protocol DeleteMedicineUseCaseProtocol {
    func execute(id: String) async throws
}

protocol AdjustStockUseCaseProtocol {
    func execute(medicineId: String, adjustment: Int, reason: String) async throws -> Medicine
}

protocol SearchMedicineUseCaseProtocol {
    func execute(query: String) async throws -> [Medicine]
}

protocol UpdateMedicineStockUseCaseProtocol {
    func execute(medicineId: String, newQuantity: Int, comment: String) async throws -> Medicine
}

// MARK: - Aisle Use Case Protocols

protocol GetAislesUseCaseProtocol {
    func execute() async throws -> [Aisle]
}

protocol AddAisleUseCaseProtocol {
    func execute(aisle: Aisle) async throws
}

protocol UpdateAisleUseCaseProtocol {
    func execute(aisle: Aisle) async throws
}

protocol DeleteAisleUseCaseProtocol {
    func execute(id: String) async throws
}

protocol SearchAisleUseCaseProtocol {
    func execute(query: String) async throws -> [Aisle]
}

protocol GetMedicineCountByAisleUseCaseProtocol {
    func execute(aisleId: String) async throws -> Int
}

// MARK: - History Use Case Protocols

protocol GetHistoryUseCaseProtocol {
    func execute() async throws -> [HistoryEntry]
}

protocol GetHistoryForMedicineUseCaseProtocol {
    func execute(medicineId: String) async throws -> [HistoryEntry]
}

protocol GetRecentHistoryUseCaseProtocol {
    func execute(limit: Int) async throws -> [HistoryEntry]
}