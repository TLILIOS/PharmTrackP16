import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var appState: AppState
    @State private var filterType: FilterType = .all
    
    enum FilterType: String, CaseIterable {
        case all = "Tout"
        case adjustments = "Ajustements"
        case additions = "Ajouts"
        case deletions = "Suppressions"
        
        var icon: String {
            switch self {
            case .all: return "clock"
            case .adjustments: return "arrow.up.arrow.down"
            case .additions: return "plus.circle"
            case .deletions: return "trash"
            }
        }
    }
    
    var filteredHistory: [StockHistory] {
        switch filterType {
        case .all:
            return appState.stockHistory
        case .adjustments:
            return appState.stockHistory.filter { $0.type == .adjustment }
        case .additions:
            return appState.stockHistory.filter { $0.type == .addition }
        case .deletions:
            return appState.stockHistory.filter { $0.type == .deletion }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Filtres
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(FilterType.allCases, id: \.self) { type in
                        FilterChip(
                            title: type.rawValue,
                            icon: type.icon,
                            isSelected: filterType == type
                        ) {
                            filterType = type
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 10)
            
            if filteredHistory.isEmpty {
                EmptyStateView(
                    icon: "clock.arrow.circlepath",
                    title: "Aucun historique",
                    message: "L'historique des mouvements de stock apparaîtra ici"
                )
            } else {
                List {
                    ForEach(groupedHistory, id: \.key) { date, entries in
                        Section(header: Text(formatSectionDate(date))) {
                            ForEach(entries) { entry in
                                HistoryRow(entry: entry)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Historique")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await appState.loadHistory()
        }
        .refreshable {
            await appState.loadHistory()
        }
    }
    
    var groupedHistory: [(key: Date, value: [StockHistory])] {
        let grouped = Dictionary(grouping: filteredHistory) { entry in
            Calendar.current.startOfDay(for: entry.date)
        }
        return grouped.sorted { $0.key > $1.key }
    }
    
    func formatSectionDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Aujourd'hui"
        } else if calendar.isDateInYesterday(date) {
            return "Hier"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .full
            formatter.locale = Locale(identifier: "fr_FR")
            return formatter.string(from: date)
        }
    }
}

struct HistoryRow: View {
    let entry: StockHistory
    @EnvironmentObject var appState: AppState
    
    var medicine: Medicine? {
        appState.medicines.first { $0.id == entry.medicineId }
    }
    
    var body: some View {
        HStack {
            // Icône du type
            Image(systemName: entry.type.icon)
                .font(.title2)
                .foregroundColor(entry.type.color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(medicine?.name ?? "Médicament supprimé")
                    .font(.headline)
                
                HStack {
                    Text(entry.type.label)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if entry.type == .adjustment {
                        Text("\(entry.change > 0 ? "+" : "")\(entry.change)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(entry.change > 0 ? .green : .red)
                    }
                }
                
                if let reason = entry.reason {
                    Text(reason)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatTime(entry.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if entry.type == .adjustment {
                    Text("\(entry.previousQuantity) → \(entry.newQuantity)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: date)
    }
}

struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(15)
        }
    }
}

extension StockHistory.HistoryType {
    var icon: String {
        switch self {
        case .adjustment: return "arrow.up.arrow.down.circle.fill"
        case .addition: return "plus.circle.fill"
        case .deletion: return "trash.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .adjustment: return .blue
        case .addition: return .green
        case .deletion: return .red
        }
    }
    
    var label: String {
        switch self {
        case .adjustment: return "Ajustement de stock"
        case .addition: return "Médicament ajouté"
        case .deletion: return "Médicament supprimé"
        }
    }
}