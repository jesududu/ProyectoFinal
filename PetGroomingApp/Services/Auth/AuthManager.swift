import FirebaseAuth

class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var currentUser: User?
    
    private var authListener: AuthStateDidChangeListenerHandle?
    
    private init() {
        authListener = Auth.auth().addStateDidChangeListener { auth, user in
            if let user = user {
                // Cargar datos del usuario desde Firestore
                DatabaseManager.shared.fetchUserData(userID: user.uid) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let appUser):
                            self.currentUser = appUser
                            print("User loaded: \(appUser.id), Role: \(appUser.role)")
                        case .failure(let error):
                            print("Error loading user data: \(error.localizedDescription)")
                            self.currentUser = nil
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.currentUser = nil
                    print("No user signed in")
                }
            }
        }
    }
    
    func signIn(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let user = result?.user else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user found"])))
                return
            }
            DatabaseManager.shared.fetchUserData(userID: user.uid) { result in
                switch result {
                case .success(let appUser):
                    completion(.success(appUser))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    func signUp(email: String, password: String, name: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let user = result?.user else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user found"])))
                return
            }
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = name
            changeRequest.commitChanges { error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                let appUser = User(id: user.uid, name: name, email: user.email ?? "", role: "user") // Rol por defecto: user
                DatabaseManager.shared.createUser(user: appUser) { dbError in
                    if let dbError = dbError {
                        completion(.failure(dbError))
                    } else {
                        completion(.success(appUser))
                    }
                }
            }
        }
    }
    
    func getCurrentUser() -> String? {
        return Auth.auth().currentUser?.uid
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            print("Signed out successfully")
        } catch {
            print("Error al cerrar sesión: \(error.localizedDescription)")
        }
    }
    
    deinit {
        if let listener = authListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
}
