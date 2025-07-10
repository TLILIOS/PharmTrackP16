import SwiftUI

struct ExpiringMedicinesView: View {
    @ObservedObject var dashboardViewModel: DashboardViewModel
    @EnvironmentObject var appCoordinator: AppCoordinator
    @State private var isRefreshing = false
    
    // Animation properties
    @State private var listItemsOpacity: [String: Double] = [:]
    @State private var listItemsOffset: [String: CGFloat] = [:]
    
    init(dashboardViewModel: DashboardViewModel) {
        self.dashboardViewModel = dashboardViewModel
    }
    
    var body: some View {
        ZStack {
            Color.backgroundApp.opacity(0.1).ignoresSafeArea()
            
            VStack {
                if dashboardViewModel.state == .loading {
                    Spacer()
                    ProgressView("Chargement des médicaments expirant...")
                    Spacer()
                } else if dashboardViewModel.expiringMedicines.isEmpty {
                    ExpiringMedicinesEmptyView()
                } else {
                    expiringMedicinesList
                }
            }
            .navigationTitle("Expirations proches")
            .navigationBarTitleDisplayMode(.large)
            
            // Message de succès/erreur
            if case .error(let message) = dashboardViewModel.state {
                VStack {
                    Spacer()
                    
                    MessageView(message: message, type: .error) {
                        dashboardViewModel.resetState()
                    }
                    .padding()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .animation(.easeInOut, value: dashboardViewModel.state)
                .zIndex(1)
            }
        }
        .onAppear {
            Task {
                await dashboardViewModel.fetchData()
                animateListItems()
            }
        }
        .refreshable {
            await performRefresh()
        }
    }
    
    private var expiringMedicinesList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(dashboardViewModel.expiringMedicines, id: \.id) { medicine in
                    ExpiringMedicineRow(medicine: medicine) {
                        appCoordinator.navigateFromDashboard(.medicineDetail(medicine.id))
                    } onViewDetails: {
                        appCoordinator.navigateFromDashboard(.medicineDetail(medicine.id))
                    }
                    .opacity(listItemsOpacity[medicine.id] ?? 0)
                    .offset(y: listItemsOffset[medicine.id] ?? 50)
                    .animation(.easeOut(duration: 0.6).delay(Double(dashboardViewModel.expiringMedicines.firstIndex(where: { $0.id == medicine.id }) ?? 0) * 0.1), value: listItemsOpacity[medicine.id])
                }
            }
            .padding()
        }
    }
    
    private func animateListItems() {
        for (index, medicine) in dashboardViewModel.expiringMedicines.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                listItemsOpacity[medicine.id] = 1.0
                listItemsOffset[medicine.id] = 0
            }
        }
    }
    
    private func performRefresh() async {
        isRefreshing = true
        await dashboardViewModel.fetchData()
        isRefreshing = false
    }
}

struct ExpiringMedicineRow: View {
    let medicine: Medicine
    let onTap: () -> Void
    let onViewDetails: () -> Void
    
    private var daysUntilExpiry: Int {
        guard let expiryDate = medicine.expiryDate else { return 0 }
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: Date(), to: expiryDate).day ?? 0
        return max(0, days)
    }
    
    private var expiryColor: Color {
        let days = daysUntilExpiry
        if days <= 7 {
            return .red
        } else if days <= 14 {
            return .orange
        } else {
            return .yellow
        }
    }
    
    private var expiryText: String {
        let days = daysUntilExpiry
        if days == 0 {
            return "Expire aujourd'hui"
        } else if days == 1 {
            return "Expire demain"
        } else {
            return "Expire dans \(days) jours"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(medicine.name ?? "Nom non spécifié")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(medicine.dosage ?? "Dosage non spécifié")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if let expiryDate = medicine.expiryDate {
                        Text(formatDate(expiryDate))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(expiryColor)
                    }
                    
                    Text("Stock: \(medicine.currentQuantity)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Barre d'urgence selon les jours restants
            HStack {
                Image(systemName: "clock.fill")
                    .font(.caption)
                    .foregroundColor(expiryColor)
                
                Text(expiryText)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(expiryColor)
                
                Spacer()
                
                Button(action: onViewDetails) {
                    Label("Voir détails", systemImage: "info.circle.fill")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.accentApp)
                        .cornerRadius(15)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Barre de progression basée sur l'urgence
            ProgressView(value: max(0, Double(30 - daysUntilExpiry)), total: 30.0)
                .progressViewStyle(LinearProgressViewStyle(tint: expiryColor))
                .scaleEffect(x: 1, y: 2, anchor: .center)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .onTapGesture {
            onTap()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: date)
    }
}

struct ExpiringMedicinesEmptyView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("Aucune expiration proche")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Tous vos médicaments ont des dates d'expiration suffisamment éloignées.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}

struct ExpiringMedicinesViewWrapper: View {
    let dashboardViewModel: DashboardViewModel
    
    var body: some View {
        ExpiringMedicinesView(dashboardViewModel: dashboardViewModel)
    }
}

#Preview {
    NavigationView {
        ExpiringMedicinesView(dashboardViewModel: DashboardViewModel(
            getUserUseCase: MockGetUserUseCase(),
            getMedicinesUseCase: MockGetMedicinesUseCase(),
            getAislesUseCase: MockGetAislesUseCase(),
            getRecentHistoryUseCase: MockGetRecentHistoryUseCase()
        ))
    }
}