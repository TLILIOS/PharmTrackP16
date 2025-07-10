import SwiftUI

struct CriticalStockView: View {
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
                    ProgressView("Chargement des stocks critiques...")
                    Spacer()
                } else if dashboardViewModel.criticalStockMedicines.isEmpty {
                    CriticalStockEmptyView()
                } else {
                    criticalStockList
                }
            }
            .navigationTitle("Stocks critiques")
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
    
    private var criticalStockList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(dashboardViewModel.criticalStockMedicines, id: \.id) { medicine in
                    CriticalStockMedicineRow(medicine: medicine) {
                        appCoordinator.navigateFromDashboard(.adjustStock(medicine.id))
                    } onAdjustStock: {
                        appCoordinator.navigateFromDashboard(.adjustStock(medicine.id))
                    }
                    .opacity(listItemsOpacity[medicine.id] ?? 0)
                    .offset(y: listItemsOffset[medicine.id] ?? 50)
                    .animation(.easeOut(duration: 0.6).delay(Double(dashboardViewModel.criticalStockMedicines.firstIndex(where: { $0.id == medicine.id }) ?? 0) * 0.1), value: listItemsOpacity[medicine.id])
                }
            }
            .padding()
        }
    }
    
    private func animateListItems() {
        for (index, medicine) in dashboardViewModel.criticalStockMedicines.enumerated() {
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

struct CriticalStockMedicineRow: View {
    let medicine: Medicine
    let onTap: () -> Void
    let onAdjustStock: () -> Void
    
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
                    Text("\(medicine.currentQuantity)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    
                    Text("/ \(medicine.maxQuantity)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Barre de progression
            ProgressView(value: Double(medicine.currentQuantity), total: Double(medicine.maxQuantity))
                .progressViewStyle(LinearProgressViewStyle(tint: .red))
                .scaleEffect(x: 1, y: 2, anchor: .center)
            
            HStack {
                Text("Seuil critique: \(medicine.criticalThreshold)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: onAdjustStock) {
                    Label("Ajuster", systemImage: "plus.circle.fill")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.accentApp)
                        .cornerRadius(15)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .onTapGesture {
            onTap()
        }
    }
}

struct CriticalStockEmptyView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("Aucun stock critique")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Tous vos médicaments ont des stocks suffisants.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}


#Preview {
    NavigationView {
        CriticalStockView(dashboardViewModel: DashboardViewModel(
            getUserUseCase: MockGetUserUseCase(),
            getMedicinesUseCase: MockGetMedicinesUseCase(),
            getAislesUseCase: MockGetAislesUseCase(),
            getRecentHistoryUseCase: MockGetRecentHistoryUseCase()
        ))
    }
}