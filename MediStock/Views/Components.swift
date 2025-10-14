import SwiftUI
import UIKit

// MARK: - Ligne de médicament réutilisable

struct MedicineRow: View {
    let medicine: Medicine
    var showExpiry: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(medicine.name)
                        .font(.headline)
                        .dynamicTypeAccessibility()
                    
                    if let dosage = medicine.dosage {
                        Text(dosage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .dynamicTypeAccessibility()
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("\(medicine.currentQuantity)")
                            .fontWeight(.semibold)
                            .dynamicTypeAccessibility()
                        Text("/ \(medicine.maxQuantity)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .dynamicTypeAccessibility()
                    }
                    
                    Circle()
                        .fill(medicine.stockStatus.statusColor)
                        .frame(width: 8, height: 8)
                        .stockStatusAccessibility(medicine.stockStatus)
                }
            }
            
            if showExpiry, let expiryDate = medicine.expiryDate {
                HStack {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.caption)
                        .accessibilityHidden(true)
                    Text(medicine.isExpired ? "Expiré le \(expiryDate.formattedDate)" : "Expire le \(expiryDate.formattedDate)")
                        .font(.caption)
                        .dynamicTypeAccessibility()
                }
                .foregroundColor(medicine.isExpired ? .red : (medicine.isExpiringSoon ? .orange : .secondary))
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Date d'expiration: \(expiryDate.formattedDate), \(medicine.isExpiringSoon ? "expire bientôt" : "expiration normale")")
            }
        }
        .padding(.vertical, 4)
        .medicineAccessibility(medicine)
    }
}

// MARK: - Carte de médicament

struct MedicineCard: View {
    let medicine: Medicine
    var showExpiry: Bool = false
    var aisle: Aisle? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // En-tête
            HStack {
                VStack(alignment: .leading) {
                    Text(medicine.name)
                        .font(.headline)
                        .lineLimit(1)

                    if let dosage = medicine.dosage {
                        Text(dosage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Circle()
                    .fill(medicine.stockStatus.statusColor)
                    .frame(width: 12, height: 12)
            }

            Divider()

            // Stock
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Stock:")
                    Spacer()
                    Text("\(medicine.currentQuantity) / \(medicine.maxQuantity)")
                        .fontWeight(.semibold)
                }
                .font(.caption)

                ProgressView(value: Double(medicine.currentQuantity), total: Double(medicine.maxQuantity))
                    .tint(medicine.stockStatus.statusColor)
            }

            // Expiration si demandée
            if showExpiry, let expiryDate = medicine.expiryDate {
                HStack {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.caption)
                    Text(expiryDate.formatted)
                        .font(.caption)
                    Spacer()
                }
                .foregroundColor(medicine.isExpired ? .red : (medicine.isExpiringSoon ? .orange : .secondary))
                .padding(.top, 4)
            }

            // Rayon
            if let aisle = aisle {
                HStack {
                    Image(systemName: aisle.icon)
                        .font(.caption)
                    Text(aisle.name)
                        .font(.caption)
                }
                .foregroundColor(aisle.color)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - Ligne d'information

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
    }
}

// MARK: - Badge de stock

struct StockBadge: View {
    let status: StockStatus
    
    var body: some View {
        Label {
            Text(status.label)
                .font(.caption)
        } icon: {
            Circle()
                .fill(status.statusColor)
                .frame(width: 8, height: 8)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(status.statusColor.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Vue vide

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var action: (() -> Void)? = nil
    var actionTitle: String = "Commencer"
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .fontWeight(.medium)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding(40)
    }
}

// MARK: - Extensions pour le formatage

extension Date {
    var formatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: self)
    }
}

// Extension StockStatus.label déplacée dans Models.swift
// Extension Color déplacée dans Extensions/Color+Extensions.swift

// MARK: - Stat Card générique pour Dashboard et autres vues

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - ShareSheet pour le partage de documents

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

