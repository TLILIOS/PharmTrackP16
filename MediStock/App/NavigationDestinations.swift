import Foundation

// MARK: - Navigation Destinations

enum MedicineDestination: Hashable {
    case add
    case detail(Medicine)
    case edit(Medicine)
    case adjustStock(Medicine)
}

enum AisleDestination: Hashable {
    case add
    case detail(Aisle)
    case edit(Aisle)
    case medicines(Aisle)
}

enum HistoryDestination: Hashable {
    case detail(HistoryEntry)
    case medicineHistory(Medicine)
}

enum ProfileDestination: Hashable {
    case settings
    case appearance
    case notifications
    case about
    case help
}