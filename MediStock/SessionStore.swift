import Foundation
import FirebaseAuth

class SessionStore: ObservableObject {
    @Published var session: User?
    var handle: AuthStateDidChangeListenerHandle?

    func listen() {
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            if let user = user {
                self.session = User(id: user.uid, email: user.email, displayName: user.displayName)
            } else {
                self.session = nil
            }
        }
    }

    func signUp(email: String, password: String) {
        Auth.auth().createUser(withEmail: email, password: password) { (result, error) in
            if let error = error {
                print("Error creating user: \(error.localizedDescription) \(error)")
            } else {
                self.session = User(id: result?.user.uid ?? "", email: result?.user.email ?? "", displayName: result?.user.displayName)
            }
        }
    }

    func signIn(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { (result, error) in
            if let error = error {
                print("Error signing in: \(error.localizedDescription)")
            } else {
                self.session = User(id: result?.user.uid ?? "", email: result?.user.email ?? "", displayName: result?.user.displayName)
            }
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            self.session = nil
        } catch let error {
            print("Error signing out: \(error.localizedDescription)")
        }
    }

    func unbind() {
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}

