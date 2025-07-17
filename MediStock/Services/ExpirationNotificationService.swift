import Foundation
import UserNotifications

class ExpirationNotificationService: ObservableObject {
    @Published var isNotificationEnabled = false
    
    private let medicineRepository: MedicineRepositoryProtocol
    
    init(medicineRepository: MedicineRepositoryProtocol) {
        self.medicineRepository = medicineRepository
    }
    
    func requestNotificationPermission() async {
        let center = UNUserNotificationCenter.current()
        
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                self.isNotificationEnabled = granted
            }
            
            if granted {
                await setupNotificationActions()
            }
        } catch {
            print("❌ Error requesting notification permission: \(error)")
        }
    }
    
    func setupNotificationActions() async {
        let center = UNUserNotificationCenter.current()
        
        let stockAction = UNNotificationAction(
            identifier: "STOCK_ACTION",
            title: "Ajuster le stock",
            options: [.foreground]
        )
        
        let viewAction = UNNotificationAction(
            identifier: "VIEW_ACTION",
            title: "Voir détails",
            options: [.foreground]
        )
        
        let expirationCategory = UNNotificationCategory(
            identifier: "EXPIRATION_CATEGORY",
            actions: [stockAction, viewAction],
            intentIdentifiers: [],
            options: []
        )
        
        center.setNotificationCategories([expirationCategory])
    }
    
    func checkExpirations() async {
        do {
            let medicines = try await medicineRepository.getMedicines()
            let calendar = Calendar.current
            let today = Date()
            
            // Vérifier les médicaments qui expirent dans 7 jours
            let sevenDaysFromNow = calendar.date(byAdding: .day, value: 7, to: today) ?? today
            
            let expiringMedicines = medicines.filter { medicine in
                guard let expiryDate = medicine.expiryDate else { return false }
                return expiryDate >= today && expiryDate <= sevenDaysFromNow
            }
            
            // Vérifier les stocks critiques
            let criticalStockMedicines = medicines.filter { medicine in
                medicine.criticalThreshold > 0 && medicine.currentQuantity <= medicine.criticalThreshold
            }
            
            await scheduleExpirationNotifications(for: expiringMedicines)
            await scheduleCriticalStockNotifications(for: criticalStockMedicines)
            
        } catch {
            print("❌ Error checking expirations: \(error)")
        }
    }
    
    private func scheduleExpirationNotifications(for medicines: [Medicine]) async {
        let center = UNUserNotificationCenter.current()
        
        for medicine in medicines {
            guard let expiryDate = medicine.expiryDate else { continue }
            
            let content = UNMutableNotificationContent()
            content.title = "⚠️ Médicament expirant"
            content.body = "\(medicine.name) expire le \(DateFormatter.shortDate.string(from: expiryDate))"
            content.sound = .default
            content.categoryIdentifier = "EXPIRATION_CATEGORY"
            content.userInfo = ["medicineId": medicine.id, "type": "expiration"]
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(
                identifier: "expiration_\(medicine.id)",
                content: content,
                trigger: trigger
            )
            
            try? await center.add(request)
        }
    }
    
    private func scheduleCriticalStockNotifications(for medicines: [Medicine]) async {
        let center = UNUserNotificationCenter.current()
        
        for medicine in medicines {
            let content = UNMutableNotificationContent()
            content.title = "🔴 Stock critique"
            content.body = "\(medicine.name) - Stock: \(medicine.currentQuantity)/\(medicine.criticalThreshold)"
            content.sound = .default
            content.categoryIdentifier = "EXPIRATION_CATEGORY"
            content.userInfo = ["medicineId": medicine.id, "type": "critical_stock"]
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(
                identifier: "critical_\(medicine.id)",
                content: content,
                trigger: trigger
            )
            
            try? await center.add(request)
        }
    }
    
    func clearAllNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }
}

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
}