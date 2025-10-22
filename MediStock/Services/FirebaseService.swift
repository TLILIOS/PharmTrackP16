import Foundation
import Firebase
import FirebaseAnalytics
import FirebaseCrashlytics
import SwiftUI

// MARK: - Firebase Service pour Analytics et Crashlytics

@MainActor
class FirebaseService: ObservableObject {
    static let shared = FirebaseService()
    
    private init() {}
    
    // MARK: - Configuration

    func configure() {
        // Configuration Firebase sécurisée avec FirebaseConfigLoader
        FirebaseConfigLoader.configure(for: .production)

        // Activer Analytics
        Analytics.setAnalyticsCollectionEnabled(true)

        // Activer Crashlytics
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)

        // Configuration cache Firestore
        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings(sizeBytes: 10 * 1024 * 1024 as NSNumber)
        Firestore.firestore().settings = settings
    }
    
    // MARK: - Analytics Events
    
    func logEvent(_ event: AnalyticsEvent) {
        Analytics.logEvent(event.name, parameters: event.parameters)
    }
    
    func setUserProperty(_ property: UserProperty) {
        Analytics.setUserProperty(property.value, forName: property.name)
    }
    
    func setUserID(_ userID: String?) {
        Analytics.setUserID(userID)
    }
    
    // MARK: - Crashlytics
    
    func logError(_ error: Error, userInfo: [String: Any]? = nil) {
        Crashlytics.crashlytics().record(error: error, userInfo: userInfo)
    }
    
    func log(_ message: String) {
        Crashlytics.crashlytics().log(message)
    }
    
    func setCustomValue(_ value: Any?, forKey key: String) {
        Crashlytics.crashlytics().setCustomValue(value, forKey: key)
    }
    
    // MARK: - Medicine Events
    
    func logMedicineAdded(medicine: Medicine) {
        logEvent(AnalyticsEvent(
            name: "medicine_added",
            parameters: [
                "medicine_id": medicine.id as Any,
                "medicine_name": medicine.name,
                "aisle_id": medicine.aisleId as Any,
                "initial_quantity": medicine.currentQuantity
            ]
        ))
    }
    
    func logMedicineUpdated(medicine: Medicine) {
        logEvent(AnalyticsEvent(
            name: "medicine_updated",
            parameters: [
                "medicine_id": medicine.id as Any,
                "medicine_name": medicine.name,
                "current_quantity": medicine.currentQuantity
            ]
        ))
    }
    
    func logMedicineDeleted(medicineId: String) {
        logEvent(AnalyticsEvent(
            name: "medicine_deleted",
            parameters: [
                "medicine_id": medicineId
            ]
        ))
    }
    
    func logStockAdjusted(medicine: Medicine, adjustment: Int, reason: String) {
        logEvent(AnalyticsEvent(
            name: "stock_adjusted",
            parameters: [
                "medicine_id": medicine.id ?? "unknown",
                "medicine_name": medicine.name,
                "adjustment": adjustment,
                "new_quantity": medicine.currentQuantity + adjustment,
                "reason": reason,
                "stock_status": medicine.stockStatus == .critical ? "critical" :
                              medicine.stockStatus == .warning ? "warning" : "normal"
            ]
        ))
    }
    
    // MARK: - User Events
    
    func logSignIn(method: String) {
        logEvent(AnalyticsEvent(
            name: AnalyticsEventLogin,
            parameters: [
                AnalyticsParameterMethod: method
            ]
        ))
    }
    
    func logSignUp(method: String) {
        logEvent(AnalyticsEvent(
            name: AnalyticsEventSignUp,
            parameters: [
                AnalyticsParameterMethod: method
            ]
        ))
    }
    
    func logSignOut() {
        logEvent(AnalyticsEvent(name: "sign_out", parameters: nil))
    }
    
    // MARK: - Search Events
    
    func logSearch(searchTerm: String, resultCount: Int) {
        logEvent(AnalyticsEvent(
            name: AnalyticsEventSearch,
            parameters: [
                AnalyticsParameterSearchTerm: searchTerm,
                "result_count": resultCount
            ]
        ))
    }
    
    // MARK: - Screen Views
    
    func logScreenView(screenName: String, screenClass: String? = nil) {
        logEvent(AnalyticsEvent(
            name: AnalyticsEventScreenView,
            parameters: [
                AnalyticsParameterScreenName: screenName,
                AnalyticsParameterScreenClass: screenClass ?? screenName
            ]
        ))
    }
    
    // MARK: - Performance Monitoring
    
    func logPerformanceEvent(name: String, duration: TimeInterval, metadata: [String: Any]? = nil) {
        var parameters: [String: Any] = [
            "duration_ms": Int(duration * 1000)
        ]
        
        if let metadata = metadata {
            parameters.merge(metadata) { _, new in new }
        }
        
        logEvent(AnalyticsEvent(
            name: "performance_\(name)",
            parameters: parameters
        ))
    }
}

// MARK: - Analytics Event Model

struct AnalyticsEvent {
    let name: String
    let parameters: [String: Any]?
}

// MARK: - User Property Model

struct UserProperty {
    let name: String
    let value: String?
}

// MARK: - Common User Properties

extension UserProperty {
    static func userRole(_ role: String) -> UserProperty {
        UserProperty(name: "user_role", value: role)
    }
    
    static func appVersion(_ version: String) -> UserProperty {
        UserProperty(name: "app_version", value: version)
    }
    
    static func preferredTheme(_ theme: String) -> UserProperty {
        UserProperty(name: "preferred_theme", value: theme)
    }
}

// MARK: - Analytics Helper

extension View {
    func trackScreen(_ name: String) -> some View {
        self.onAppear {
            FirebaseService.shared.logScreenView(screenName: name)
        }
    }
}
