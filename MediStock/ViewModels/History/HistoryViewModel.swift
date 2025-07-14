import Foundation
import SwiftUI
import Combine

enum HistoryViewState: Equatable {
    case idle
    case loading
    case success
    case error(String)
    case exporting
}

enum HistoryExportFormat {
    case pdf
    case csv
}

@MainActor
class HistoryViewModel: ObservableObject {
    // MARK: - Properties
    
    private let getHistoryUseCase: GetHistoryUseCaseProtocol
    private let getMedicinesUseCase: GetMedicinesUseCaseProtocol
    private let exportHistoryUseCase: ExportHistoryUseCaseProtocol
    
    @Published private(set) var history: [HistoryEntry] = []
    @Published private(set) var medicines: [Medicine] = []
    @Published private(set) var state: HistoryViewState = .idle
    @Published private(set) var isLoading: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(
        getHistoryUseCase: GetHistoryUseCaseProtocol,
        getMedicinesUseCase: GetMedicinesUseCaseProtocol,
        exportHistoryUseCase: ExportHistoryUseCaseProtocol
    ) {
        self.getHistoryUseCase = getHistoryUseCase
        self.getMedicinesUseCase = getMedicinesUseCase
        self.exportHistoryUseCase = exportHistoryUseCase
    }
    
    // MARK: - Public Methods
    
    func resetState() {
        state = .idle
    }
    
    @MainActor
    func fetchHistory() async {
        isLoading = true
        state = .loading
        
        do {
            history = try await getHistoryUseCase.execute()
            
            // Tri par date décroissante (plus récent d'abord)
            history.sort { $0.timestamp > $1.timestamp }
            
            state = .success
        } catch {
            state = .error("Erreur lors du chargement de l'historique: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    @MainActor
    func fetchMedicines() async {
        do {
            medicines = try await getMedicinesUseCase.execute()
        } catch {
            // Ne pas modifier l'état principal en cas d'erreur
            print("Erreur lors du chargement des médicaments: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    func exportHistory(format: HistoryExportFormat, entries: [HistoryEntry]) async {
        state = .exporting
        
        do {
            let _ = createExportData(entries: entries)
            
            let _ = "Historique_MediStock_\(formatDate(Date()))"
            
            switch format {
            case .pdf:
                _ = try await exportHistoryUseCase.execute(format: .pdf)
            case .csv:
                _ = try await exportHistoryUseCase.execute(format: .csv)
            }
            
            state = .success
        } catch {
            state = .error("Erreur lors de l'exportation: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func createExportData(entries: [HistoryEntry]) -> [HistoryExportItem] {
        return entries.map { entry in
            let medicineName = medicines.first(where: { $0.id == entry.medicineId })?.name ?? "Médicament inconnu"
            
            return HistoryExportItem(
                date: formatDate(entry.timestamp),
                time: formatTime(entry.timestamp),
                medicine: medicineName,
                action: entry.action,
                details: entry.details
            )
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd_MM_yyyy"
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

struct HistoryExportItem {
    let date: String
    let time: String
    let medicine: String
    let action: String
    let details: String
}

