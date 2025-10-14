/// Stubs Firebase pour les tests unitaires
/// Ce fichier permet aux tests de compiler même si Firebase n'est pas complètement configuré

#if UNIT_TESTS_ONLY

import Foundation

// Stub minimal pour FirebaseCore
public enum FirebaseApp {
    public static func configure() {}
}

// Stub minimal pour FirebaseAuth  
public class Auth {
    public static func auth() -> Auth { Auth() }
    public func signOut() throws {}
    public func useEmulator(withHost: String, port: Int) {}
}

// Stub minimal pour FirebaseFirestore
public class Firestore {
    public static func firestore() -> Firestore { Firestore() }
    public var settings: FirestoreSettings { get { FirestoreSettings() } set {} }
    public func terminate() async throws {}
}

public class FirestoreSettings {
    public var host: String = ""
    public var cacheSettings: Any? = nil
    public var isSSLEnabled: Bool = true
    public var isPersistenceEnabled: Bool = true
}

// Stub minimal pour AppCheck
public enum AppCheck {
    public static func setAppCheckProviderFactory(_ factory: Any?) {}
}

#endif