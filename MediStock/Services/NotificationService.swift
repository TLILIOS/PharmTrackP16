import Foundation
import UserNotifications

// MARK: - Service de notifications simplifié

class NotificationService {
    
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            return granted
        } catch {
            print("Erreur autorisation notifications: \(error)")
            return false
        }
    }
    
    func checkExpirations(medicines: [Medicine]) async {
        // Supprimer les anciennes notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // Créer des notifications pour les médicaments expirant bientôt
        for medicine in medicines {
            guard let expiryDate = medicine.expiryDate,
                  !medicine.isExpired else { continue }
            
            let daysUntilExpiry = Calendar.current.dateComponents([.day], from: Date(), to: expiryDate).day ?? 0
            
            if daysUntilExpiry <= 30 {
                await scheduleExpirationNotification(for: medicine, daysUntilExpiry: daysUntilExpiry)
            }
        }
    }
    
    private func scheduleExpirationNotification(for medicine: Medicine, daysUntilExpiry: Int) async {
        let content = UNMutableNotificationContent()
        content.title = "Médicament bientôt périmé"
        content.body = "\(medicine.name) expire dans \(daysUntilExpiry) jour(s)"
        content.sound = .default
        
        // Notification le matin à 9h
        var dateComponents = DateComponents()
        dateComponents.hour = 9
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: "expiration-\(medicine.id)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Erreur ajout notification: \(error)")
        }
    }
}