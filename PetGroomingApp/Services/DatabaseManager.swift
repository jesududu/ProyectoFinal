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
    func createUser(userID: String, name: String, email: String, completion: @escaping (Error?) -> Void) {
        let data: [String: Any] = [
            "id": userID,
            "name": name,
            "email": email
        ]
        db.collection("users").document(userID).setData(data, completion: completion)
    }
    
    // Obtener usuario
    func fetchUser(userID: String, completion: @escaping (Result<User, Error>) -> Void) {
        db.collection("users").document(userID).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = snapshot?.data(),
                  let id = data["id"] as? String,
                  let name = data["name"] as? String,
                  let email = data["email"] as? String else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data found"])))
                return
            }
            let user = User(id: id, name: name, email: email)
            completion(.success(user))
        }
    }
    
    // Crear mascota
    func createPet(pet: Pet, completion: @escaping (Error?) -> Void) {
        let data: [String: Any] = [
            "id": pet.id,
            "breed": pet.breed,
            "name": pet.name,
            "notes": pet.notes as Any, // Puede ser nil
            "photoURL": pet.photoURL
        ]
        db.collection("pets").document(pet.id).setData(data, completion: completion)
    }
    
    // Obtener mascotas
    func fetchPets(completion: @escaping (Result<[Pet], Error>) -> Void) {
        db.collection("pets").getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            let pets = snapshot?.documents.compactMap { document -> Pet? in
                let data = document.data()
                guard let id = data["id"] as? String,
                      let breed = data["breed"] as? String,
                      let name = data["name"] as? String,
                      let photoURL = data["photoURL"] as? String else {
                    return nil
                }
                let notes = data["notes"] as? String
                return Pet(id: id, breed: breed, name: name, notes: notes, photoURL: photoURL)
            } ?? []
            completion(.success(pets))
        }
    }
    
    // Obtener groomers
    func fetchGroomers(completion: @escaping (Result<[Groomer], Error>) -> Void) {
        db.collection("groomers").getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            let groomers = snapshot?.documents.compactMap { document -> Groomer? in
                let data = document.data()
                guard let id = data["id"] as? String,
                      let address = data["address"] as? String,
                      let description = data["description"] as? String,
                      let lat = data["lat"] as? Double,
                      let lng = data["lng"] as? Double,
                      let name = data["name"] as? String else {
                    return nil
                }
                return Groomer(id: id, address: address, description: description, lat: lat, lng: lng, name: name)
            } ?? []
            completion(.success(groomers))
        }
    }
    
    // Crear reserva
    func createReservation(reservation: Reservation, completion: @escaping (Error?) -> Void) {
        let data: [String: Any] = [
            "id": reservation.id,
            "date": Timestamp(date: reservation.date),
            "groomer_ID": reservation.groomerID,
            "pet_ID": reservation.petID,
            "services": reservation.services.map { ["name": $0.name, "number": $0.number, "duration": $0.duration] },
            "status": reservation.status
        ]
        db.collection("my_reservations").document(reservation.id).setData(data, completion: completion)
    }
    
    // Obtener reservas
    func fetchReservations(forPetID petID: String, completion: @escaping (Result<[Reservation], Error>) -> Void) {
        db.collection("my_reservations")
            .whereField("pet_ID", isEqualTo: petID)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                let reservations = snapshot?.documents.compactMap { document -> Reservation? in
                    let data = document.data()
                    guard let id = data["id"] as? String,
                          let date = (data["date"] as? Timestamp)?.dateValue(),
                          let groomerID = data["groomer_ID"] as? String,
                          let petID = data["pet_ID"] as? String,
                          let servicesData = data["services"] as? [[String: Any]],
                          let status = data["status"] as? String else {
                        return nil
                    }
                    let services = servicesData.compactMap { serviceData -> Service? in
                        guard let name = serviceData["name"] as? String,
                              let number = serviceData["number"] as? Int,
                              let duration = serviceData["duration"] as? Int else {
                            return nil
                        }
                        return Service(name: name, number: number, duration: duration)
                    }
                    return Reservation(id: id, date: date, groomerID: groomerID, petID: petID, services: services, status: status)
                } ?? []
                completion(.success(reservations))
            }
    }
}
