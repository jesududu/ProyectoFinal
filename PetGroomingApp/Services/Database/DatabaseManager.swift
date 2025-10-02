import FirebaseFirestore
import FirebaseCore
import FirebaseAuth

class DatabaseManager {
    static let shared = DatabaseManager()
    
    private lazy var db: Firestore = {
        guard FirebaseApp.app() != nil else {
            fatalError("Firebase no está configurado. Asegúrate de llamar a FirebaseApp.configure() antes de usar DatabaseManager.")
        }
        return Firestore.firestore()
    }()
    
    private init() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }
    
    // Crear usuario
    func createUser(user: User, completion: @escaping (Error?) -> Void) {
        let data: [String: Any] = [
            "id": user.id,
            "name": user.name,
            "email": user.email,
            "role": user.role
        ]
        print("Creating user with data: \(data)")
        db.collection("users").document(user.id).setData(data) { error in
            if let error = error {
                print("Error creating user: \(error.localizedDescription)")
            } else {
                print("User created successfully: \(user.id)")
            }
            completion(error)
        }
    }
    
    // Obtener usuario
    func fetchUserData(userID: String, completion: @escaping (Result<User, Error>) -> Void) {
        db.collection("users").document(userID).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching user: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            guard let data = snapshot?.data(),
                  let id = data["id"] as? String,
                  let name = data["name"] as? String,
                  let email = data["email"] as? String,
                  let role = data["role"] as? String else {
                let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User data not found or incomplete"])
                print("Error: \(error.localizedDescription) for userID: \(userID)")
                completion(.failure(error))
                return
            }
            let user = User(id: id, name: name, email: email, role: role)
            print("Fetched user: \(user.id), Role: \(user.role)")
            completion(.success(user))
        }
    }
    
    // Crear peluquería
    func createGroomer(groomer: Groomer, completion: @escaping (Error?) -> Void) {
        let data: [String: Any] = [
            "id": groomer.id,
            "name": groomer.name,
            "address": groomer.address,
            "description": groomer.description,
            "lat": groomer.lat,
            "lng": groomer.lng,
            "photoURL": groomer.photoURL,
            "openingHour": groomer.openingHour,
            "closingHour": groomer.closingHour
        ]
        print("Creating groomer with data: \(data)")
        db.collection("groomers").document(groomer.id).setData(data) { error in
            if let error = error {
                print("Error creating groomer: \(error.localizedDescription)")
                // Verificar si el documento se creó
                self.db.collection("groomers").document(groomer.id).getDocument { snapshot, _ in
                    if snapshot?.exists == true {
                        print("Groomer document exists despite error: \(groomer.id)")
                        completion(nil)
                    } else {
                        completion(error)
                    }
                }
            } else {
                print("Groomer created successfully: \(groomer.id)")
                completion(nil)
            }
        }
    }
    
    // Crear servicio
    func createService(service: Service, completion: @escaping (Error?) -> Void) {
        let data: [String: Any] = [
            "id": service.id,
            "name": service.name,
            "duration": service.duration,
            "price": service.price
        ]
        print("Creating service with data: \(data)")
        db.collection("services").document(service.id).setData(data) { error in
            if let error = error {
                print("Error creating service: \(error.localizedDescription)")
                // Verificar si el documento se creó
                self.db.collection("services").document(service.id).getDocument { snapshot, _ in
                    if snapshot?.exists == true {
                        print("Service document exists despite error: \(service.id)")
                        completion(nil)
                    } else {
                        completion(error)
                    }
                }
            } else {
                print("Service created successfully: \(service.id)")
                completion(nil)
            }
        }
    }
    
    // Crear mascota
    func createPet(pet: Pet, completion: @escaping (Error?) -> Void) {
        guard let userID = AuthManager.shared.getCurrentUser() else {
            let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
            print("Error: \(error.localizedDescription)")
            completion(error)
            return
        }
        let data: [String: Any] = [
            "id": pet.id,
            "breed": pet.breed,
            "name": pet.name,
            "notes": pet.notes as Any,
            "photoURL": pet.photoURL,
            "user_ID": userID
        ]
        print("Creating pet with data: \(data)")
        db.collection("pets").document(pet.id).setData(data) { error in
            if let error = error {
                print("Error creating pet: \(error.localizedDescription)")
                // Verificar si el documento se creó
                self.db.collection("pets").document(pet.id).getDocument { snapshot, _ in
                    if snapshot?.exists == true {
                        print("Pet document exists despite error: \(pet.id)")
                        completion(nil)
                    } else {
                        completion(error)
                    }
                }
            } else {
                print("Pet created successfully: \(pet.id)")
                completion(nil)
            }
        }
    }
    
    // Obtener mascotas
    func fetchPets(completion: @escaping (Result<[Pet], Error>) -> Void) {
        guard let userID = AuthManager.shared.getCurrentUser() else {
            let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
            print("Error: \(error.localizedDescription)")
            completion(.failure(error))
            return
        }
        db.collection("pets")
            .whereField("user_ID", isEqualTo: userID)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching pets: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                let pets = snapshot?.documents.compactMap { document -> Pet? in
                    let data = document.data()
                    guard let id = data["id"] as? String,
                          let breed = data["breed"] as? String,
                          let name = data["name"] as? String,
                          let photoURL = data["photoURL"] as? String,
                          let userID = data["user_ID"] as? String else {
                        print("Invalid pet document: \(document.documentID), data: \(data)")
                        return nil
                    }
                    let notes = data["notes"] as? String
                    return Pet(id: id, breed: breed, name: name, notes: notes, photoURL: photoURL, userID: userID)
                } ?? []
                print("Fetched \(pets.count) pets for userID: \(userID)")
                completion(.success(pets))
            }
    }
    
    // Obtener peluquerías
    func fetchGroomers(completion: @escaping (Result<[Groomer], Error>) -> Void) {
        db.collection("groomers").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching groomers: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            guard let documents = snapshot?.documents else {
                print("No groomer documents found")
                completion(.success([]))
                return
            }
            let groomers = documents.compactMap { document -> Groomer? in
                let data = document.data()
                guard let id = data["id"] as? String,
                      let address = data["address"] as? String,
                      let description = data["description"] as? String,
                      let lat = data["lat"] as? Double,
                      let lng = data["lng"] as? Double,
                      let name = data["name"] as? String,
                      let photoURL = data["photoURL"] as? String,
                      let openingHour = data["openingHour"] as? String,
                      let closingHour = data["closingHour"] as? String else {
                    print("Invalid groomer document: \(document.documentID), data: \(data)")
                    return nil
                }
                return Groomer(id: id, address: address, description: description, lat: lat, lng: lng, name: name, photoURL: photoURL, openingHour: openingHour, closingHour: closingHour)
            }
            print("Fetched \(groomers.count) groomers")
            completion(.success(groomers))
        }
    }
    
    // Obtener servicios predefinidos
    func fetchServices(completion: @escaping (Result<[Service], Error>) -> Void) {
        db.collection("services").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching services: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            let services = snapshot?.documents.compactMap { document -> Service? in
                let data = document.data()
                guard let id = data["id"] as? String,
                      let name = data["name"] as? String,
                      let duration = data["duration"] as? Int,
                      let price = data["price"] as? Double else {
                    print("Invalid service document: \(document.documentID), data: \(data)")
                    return nil
                }
                return Service(id: id, name: name, duration: duration, price: price)
            } ?? []
            print("Fetched \(services.count) services")
            completion(.success(services))
        }
    }
    
    // Obtener reservas para una peluquería en una fecha específica
    func fetchReservationsForGroomer(groomerID: String, date: Date, completion: @escaping (Result<[Reservation], Error>) -> Void) {
        guard let userID = AuthManager.shared.getCurrentUser() else {
            let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
            print("Error: \(error.localizedDescription)")
            completion(.failure(error))
            return
        }
        
        // Verificar si el usuario es admin
        fetchUserData(userID: userID) { result in
            switch result {
            case .success(let user):
                let isAdmin = user.role == "admin"
                print("Fetching reservations for groomerID: \(groomerID), date: \(date), userID: \(userID), isAdmin: \(isAdmin)")
                
                let calendar = Calendar.current
                let startOfDay = calendar.startOfDay(for: date)
                guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
                    let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to calculate end of day"])
                    print("Error: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                var query = self.db.collection("my_reservations")
                    .whereField("groomer_ID", isEqualTo: groomerID)
                    .whereField("status", isEqualTo: "confirmada")
                    .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startOfDay))
                    .whereField("date", isLessThan: Timestamp(date: endOfDay))
                
                if !isAdmin {
                    query = query.whereField("user_ID", isEqualTo: userID)
                }
                
                query.getDocuments { snapshot, error in
                    if let error = error {
                        print("Error fetching reservations for groomer \(groomerID): \(error.localizedDescription)")
                        completion(.failure(error))
                        return
                    }
                    let reservations = snapshot?.documents.compactMap { document -> Reservation? in
                        let data = document.data()
                        guard let id = data["id"] as? String,
                              let date = (data["date"] as? Timestamp)?.dateValue(),
                              let endDate = (data["endDate"] as? Timestamp)?.dateValue(),
                              let groomerID = data["groomer_ID"] as? String,
                              let petID = data["pet_ID"] as? String,
                              let userID = data["user_ID"] as? String,
                              let servicesData = data["services"] as? [[String: Any]],
                              let status = data["status"] as? String else {
                            print("Invalid reservation document: \(document.documentID), data: \(data)")
                            return nil
                        }
                        let services = servicesData.compactMap { serviceData -> Service? in
                            guard let id = serviceData["id"] as? String,
                                  let name = serviceData["name"] as? String,
                                  let duration = serviceData["duration"] as? Int,
                                  let price = serviceData["price"] as? Double else {
                                return nil
                            }
                            return Service(id: id, name: name, duration: duration, price: price)
                        }
                        return Reservation(id: id, date: date, endDate: endDate, groomerID: groomerID, petID: petID, userID: userID, services: services, status: status)
                    } ?? []
                    print("Fetched \(reservations.count) reservations for groomerID: \(groomerID) on date: \(date)")
                    completion(.success(reservations))
                }
            case .failure(let error):
                print("Error fetching user data: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
    
    // Verificar disponibilidad de horario
    func checkAvailability(groomerID: String, startDate: Date, endDate: Date, completion: @escaping (Result<Bool, Error>) -> Void) {
        print("Checking availability for groomerID: \(groomerID), start: \(startDate), end: \(endDate)")
        db.collection("groomers").document(groomerID).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching groomer \(groomerID): \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            guard let data = snapshot?.data(), snapshot?.exists == true else {
                let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Groomer document not found for ID: \(groomerID)"])
                print("Error: \(error.localizedDescription)")
                self.db.collection("groomers").getDocuments { snapshot, _ in
                    let ids = snapshot?.documents.map { $0.documentID } ?? []
                    print("Available groomer IDs: \(ids)")
                }
                completion(.failure(error))
                return
            }
            guard let openingHour = data["openingHour"] as? String,
                  let closingHour = data["closingHour"] as? String else {
                let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Groomer data missing openingHour or closingHour for ID: \(groomerID), data: \(data)"])
                print("Error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            print("Groomer data found: \(data)")
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            guard let openingDate = formatter.date(from: openingHour),
                  let closingDate = formatter.date(from: closingHour) else {
                let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid hour format for groomer \(groomerID): \(openingHour)-\(closingHour)"])
                print("Error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            let calendar = Calendar.current
            let openingComponents = calendar.dateComponents([.hour, .minute], from: openingDate)
            let closingComponents = calendar.dateComponents([.hour, .minute], from: closingDate)
            let startComponents = calendar.dateComponents([.hour, .minute], from: startDate)
            let endComponents = calendar.dateComponents([.hour, .minute], from: endDate)
            
            guard let openingHourValue = openingComponents.hour, let openingMinute = openingComponents.minute,
                  let closingHourValue = closingComponents.hour, let closingMinute = closingComponents.minute,
                  let startHour = startComponents.hour, let startMinute = startComponents.minute,
                  let endHour = endComponents.hour, let endMinute = endComponents.minute else {
                let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to extract time components"])
                print("Error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            let openingMinutes = openingHourValue * 60 + openingMinute
            let closingMinutes = closingHourValue * 60 + closingMinute
            let startMinutes = startHour * 60 + startMinute
            let endMinutes = endHour * 60 + endMinute
            
            guard startMinutes >= openingMinutes && endMinutes <= closingMinutes else {
                let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Reservation outside operating hours (\(openingHour)-\(closingHour)) for groomer \(groomerID)"])
                print("Error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            self.fetchReservationsForGroomer(groomerID: groomerID, date: startDate) { result in
                switch result {
                case .success(let reservations):
                    let isOverlapping = reservations.contains { reservation in
                        let existingStart = reservation.date
                        let existingEnd = reservation.endDate
                        return (startDate < existingEnd && endDate > existingStart)
                    }
                    if isOverlapping {
                        let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Time slot overlaps with another reservation for groomer \(groomerID)"])
                        print("Error: \(error.localizedDescription)")
                        completion(.failure(error))
                    } else {
                        print("Availability check passed for groomer \(groomerID)")
                        completion(.success(true))
                    }
                case .failure(let error):
                    print("Error checking reservations: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }
    }
    
    // Crear reserva
    func createReservation(reservation: Reservation, completion: @escaping (Error?) -> Void) {
        guard let userID = AuthManager.shared.getCurrentUser() else {
            let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
            print("Error: \(error.localizedDescription)")
            completion(error)
            return
        }
        
        print("Attempting to create reservation: \(reservation.id), userID: \(userID)")
        checkAvailability(groomerID: reservation.groomerID, startDate: reservation.date, endDate: reservation.endDate) { result in
            switch result {
            case .success:
                let data: [String: Any] = [
                    "id": reservation.id,
                    "date": Timestamp(date: reservation.date),
                    "endDate": Timestamp(date: reservation.endDate),
                    "groomer_ID": reservation.groomerID,
                    "pet_ID": reservation.petID,
                    "user_ID": userID,
                    "services": reservation.services.map { ["id": $0.id, "name": $0.name, "duration": $0.duration, "price": $0.price] },
                    "status": reservation.status
                ]
                print("Creating reservation with data: \(data)")
                self.db.collection("my_reservations").document(reservation.id).setData(data) { error in
                    if let error = error {
                        print("Error creating reservation: \(error.localizedDescription)")
                        // Verificar si el documento se creó
                        self.db.collection("my_reservations").document(reservation.id).getDocument { snapshot, _ in
                            if snapshot?.exists == true {
                                print("Reservation document exists despite error: \(reservation.id)")
                                completion(nil)
                            } else {
                                completion(error)
                            }
                        }
                    } else {
                        print("Reservation created successfully: \(reservation.id)")
                        completion(nil)
                    }
                }
            case .failure(let error):
                print("Availability check failed: \(error.localizedDescription)")
                completion(error)
            }
        }
    }
    
    // Obtener reservas
    func fetchReservations(forPetID petID: String, completion: @escaping (Result<[Reservation], Error>) -> Void) {
        guard let userID = AuthManager.shared.getCurrentUser() else {
            let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
            print("Error: \(error.localizedDescription)")
            completion(.failure(error))
            return
        }
        var query = self.db.collection("my_reservations").whereField("user_ID", isEqualTo: userID)
        if !petID.isEmpty {
            query = query.whereField("pet_ID", isEqualTo: petID)
        }
        query.getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching reservations: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            let reservations = snapshot?.documents.compactMap { document -> Reservation? in
                let data = document.data()
                guard let id = data["id"] as? String,
                      let date = (data["date"] as? Timestamp)?.dateValue(),
                      let endDate = (data["endDate"] as? Timestamp)?.dateValue(),
                      let groomerID = data["groomer_ID"] as? String,
                      let petID = data["pet_ID"] as? String,
                      let userID = data["user_ID"] as? String,
                      let servicesData = data["services"] as? [[String: Any]],
                      let status = data["status"] as? String else {
                    print("Invalid reservation document: \(document.documentID), data: \(data)")
                    return nil
                }
                let services = servicesData.compactMap { serviceData -> Service? in
                    guard let id = serviceData["id"] as? String,
                          let name = serviceData["name"] as? String,
                          let duration = serviceData["duration"] as? Int,
                          let price = serviceData["price"] as? Double else {
                        return nil
                    }
                    return Service(id: id, name: name, duration: duration, price: price)
                }
                return Reservation(id: id, date: date, endDate: endDate, groomerID: groomerID, petID: petID, userID: userID, services: services, status: status)
            } ?? []
            print("Fetched \(reservations.count) reservations for petID: \(petID.isEmpty ? "all" : petID)")
            completion(.success(reservations))
        }
    }
    
    // Cancelar reserva
    func cancelReservation(reservationID: String, completion: @escaping (Error?) -> Void) {
        print("Attempting to cancel reservation: \(reservationID)")
        let reservationRef = db.collection("my_reservations").document(reservationID)
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let reservationDoc: DocumentSnapshot
            do {
                reservationDoc = try transaction.getDocument(reservationRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }
            guard reservationDoc.exists else {
                errorPointer?.pointee = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Reservation not found: \(reservationID)"])
                return nil
            }
            transaction.updateData(["status": "cancelada"], forDocument: reservationRef)
            return nil
        }) { _, error in
            if let error = error {
                print("Error cancelling reservation: \(error.localizedDescription)")
            } else {
                print("Reservation cancelled successfully: \(reservationID)")
            }
            completion(error)
        }
    }
}
