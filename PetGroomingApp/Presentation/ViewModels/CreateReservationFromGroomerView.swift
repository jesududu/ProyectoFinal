import SwiftUI
import MapKit
import CoreLocation

// Extensión para formatear precios
extension Double {
    var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: self))?.appending(" €") ?? "\(self) €"
    }
}

// Representable para integrar MKMapView en SwiftUI
struct MapView: UIViewRepresentable {
    let coordinate: CLLocationCoordinate2D
    let viewModel: CreateReservationFromGroomerViewModel
    @Binding var mapType: MKMapType
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.showsUserTrackingButton = true
        mapView.mapType = mapType
        
        // Añadir anotación para la peluquería
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = viewModel.groomerName
        mapView.addAnnotation(annotation)
        
        // Centrar el mapa
        let region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 100000,
            longitudinalMeters: 100000
        )
        mapView.setRegion(region, animated: true)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.mapType = mapType
        // Actualizar la anotación si es necesario
        mapView.removeAnnotations(mapView.annotations)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = viewModel.groomerName
        mapView.addAnnotation(annotation)
        mapView.setRegion(MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 100000,
            longitudinalMeters: 100000
        ), animated: true)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate, CLLocationManagerDelegate {
        var parent: MapView
        var locationManager = CLLocationManager()
        var scenes: [CLLocationCoordinate2D: MKLookAroundScene] = [:]
        
        init(parent: MapView) {
            self.parent = parent
            super.init()
            locationManager.delegate = self
            checkLocationAuthorizationStatus()
        }
        
        func checkLocationAuthorizationStatus() {
            let authorizationStatus = locationManager.authorizationStatus
            switch authorizationStatus {
            case .notDetermined:
                locationManager.requestWhenInUseAuthorization()
            case .restricted, .denied:
                parent.viewModel.showLocationError = true
            case .authorizedAlways, .authorizedWhenInUse:
                locationManager.startUpdatingLocation()
            @unknown default:
                break
            }
        }
        
        func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
            checkLocationAuthorizationStatus()
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard !(annotation is MKUserLocation) else { return nil }
            
            let identifier = "GroomerAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                // Usar imagen personalizada de un perrito
                annotationView?.image = UIImage(named: "dogIcon")?.resize(to: CGSize(width: 40, height: 40))
                annotationView?.canShowCallout = true
                annotationView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
                // Centrar la imagen en el punto de la anotación
                annotationView?.centerOffset = CGPoint(x: 0, y: -20) // Ajustar para que el centro de la imagen esté en la coordenada
            } else {
                annotationView?.annotation = annotation
            }
            return annotationView
        }
        
        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
            guard let coordinate = view.annotation?.coordinate else { return }
            Task { @MainActor in
                if let scene = await getLookAroundSceneFor(coordinate: coordinate) {
                    let lookAroundVC = MKLookAroundViewController(scene: scene)
                    UIApplication.shared.windows.first?.rootViewController?.present(lookAroundVC, animated: true)
                } else {
                    parent.viewModel.showLookAroundError = true
                }
            }
        }
        
        private func getLookAroundSceneFor(coordinate: CLLocationCoordinate2D) async -> MKLookAroundScene? {
            if let scene = scenes[coordinate] {
                return scene
            }
            let request = MKLookAroundSceneRequest(coordinate: coordinate)
            do {
                if let scene = try await request.scene {
                    scenes[coordinate] = scene
                    return scene
                }
                return nil
            } catch {
                return nil
            }
        }
    }
}

// Extensión para redimensionar UIImage
extension UIImage {
    func resize(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

struct CreateReservationFromGroomerView: View {
    let groomer: Groomer
    @StateObject private var viewModel = CreateReservationFromGroomerViewModel()
    @State private var selectedDate = Date()
    @State private var selectedInterval: String?
    @State private var selectedPetID: String?
    @State private var selectedServices: [Service] = []
    @State private var showConfirmationAlert = false
    @State private var showSuccessAlert = false
    @State private var mapType: MKMapType = .standard
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager
    
    // Coordenada de la peluquería
    private var groomerCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: groomer.lat, longitude: groomer.lng)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Fecha")) {
                    DatePicker("Seleccionar fecha", selection: $selectedDate, in: Date()..., displayedComponents: [.date])
                        .datePickerStyle(.compact)
                        .onChange(of: selectedDate) { _ in
                            selectedInterval = nil
                            viewModel.updateAvailableIntervals(date: selectedDate, groomer: groomer, services: selectedServices)
                        }
                }
                Section(header: Text("Intervalo de Tiempo")) {
                    if viewModel.isLoadingIntervals {
                        ProgressView()
                    } else if viewModel.availableIntervals.isEmpty {
                        Text("No hay intervalos disponibles")
                            .foregroundColor(.gray)
                    } else {
                        Picker("Seleccionar intervalo", selection: $selectedInterval) {
                            Text("Selecciona un intervalo").tag(nil as String?)
                            ForEach(viewModel.availableIntervals, id: \.self) { interval in
                                Text(interval).tag(interval as String?)
                            }
                        }
                    }
                }
                Section(header: Text("Peluquería")) {
                    AsyncImage(url: URL(string: groomer.photoURL)) { image in
                        image.resizable().scaledToFit()
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(height: 100)
                    Text(groomer.name)
                        .font(.headline)
                    Text(groomer.address)
                    Text(groomer.description)
                        .foregroundColor(.gray)
                    Text("Horario: \(groomer.openingHour) - \(groomer.closingHour)")
                    Picker("Tipo de Mapa", selection: $mapType) {
                        Text("Estándar").tag(MKMapType.standard)
                        Text("Satélite").tag(MKMapType.satellite)
                        Text("Híbrido").tag(MKMapType.hybrid)
                    }
                    .pickerStyle(.segmented)
                    MapView(coordinate: groomerCoordinate, viewModel: viewModel, mapType: $mapType)
                        .frame(height: 200)
                        .cornerRadius(8)
                }
                Section(header: Text("Seleccionar Perro")) {
                    if viewModel.isLoadingPets {
                        ProgressView()
                    } else if viewModel.pets.isEmpty {
                        Text("No tienes perros registrados")
                            .foregroundColor(.gray)
                    } else {
                        Picker("Perro", selection: $selectedPetID) {
                            Text("Selecciona un perro").tag(nil as String?)
                            ForEach(viewModel.pets, id: \.id) { pet in
                                Text(pet.name).tag(pet.id as String?)
                            }
                        }
                    }
                }
                Section(header: Text("Servicios Disponibles")) {
                    if viewModel.isLoadingServices {
                        ProgressView()
                    } else if viewModel.services.isEmpty {
                        Text("No hay servicios disponibles")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(viewModel.services) { service in
                            Toggle("\(service.name) (\(service.duration) min, \(service.price.formattedPrice))", isOn: Binding<Bool>(
                                get: { selectedServices.contains { $0.id == service.id } },
                                set: { isOn in
                                    if isOn {
                                        selectedServices.append(service)
                                    } else {
                                        selectedServices.removeAll { $0.id == service.id }
                                    }
                                    selectedInterval = nil
                                    viewModel.updateAvailableIntervals(date: selectedDate, groomer: groomer, services: selectedServices)
                                }
                            ))
                        }
                    }
                }
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                Button("Crear Reserva") {
                    showConfirmationAlert = true
                }
                .disabled(selectedPetID == nil || selectedServices.isEmpty || selectedInterval == nil)
                .padding()
                .background(Color.teal)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .navigationTitle("Reservar en \(groomer.name)")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        print("Signing out")
                        authManager.signOut()
                    }) {
                        Image(systemName: "power")
                            .font(.system(size: 24))
                    }
                }
            }
            .onAppear {
                viewModel.groomerName = groomer.name
                viewModel.fetchPets()
                viewModel.fetchServices()
                viewModel.updateAvailableIntervals(date: selectedDate, groomer: groomer, services: selectedServices)
            }
            .alert("¿Quieres reservar a esta hora?", isPresented: $showConfirmationAlert) {
                Button("Sí") {
                    viewModel.createReservation(
                        selectedDate: selectedDate,
                        selectedInterval: selectedInterval,
                        groomer: groomer,
                        selectedPetID: selectedPetID,
                        selectedServices: selectedServices
                    ) { success in
                        if success {
                            showSuccessAlert = true
                        }
                    }
                }
                Button("No", role: .cancel) { }
            }
            .alert("Reserva realizada con éxito", isPresented: $showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            }
            .alert("Ubicación no autorizada", isPresented: $viewModel.showLocationError) {
                Button("OK") { }
            } message: {
                Text("Por favor, habilita los permisos de ubicación en la configuración de la aplicación.")
            }
            .alert("Vista LookAround no disponible", isPresented: $viewModel.showLookAroundError) {
                Button("OK") { }
            } message: {
                Text("No hay vista LookAround disponible para esta ubicación.")
            }
        }
        .environmentObject(authManager)
    }
}

class CreateReservationFromGroomerViewModel: ObservableObject {
    @Published var pets: [Pet] = []
    @Published var services: [Service] = []
    @Published var availableIntervals: [String] = []
    @Published var isLoadingPets = false
    @Published var isLoadingServices = false
    @Published var isLoadingIntervals = false
    @Published var errorMessage: String?
    @Published var showLocationError = false
    @Published var showLookAroundError = false
    @Published var groomerName: String = ""
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    func fetchPets() {
        isLoadingPets = true
        DatabaseManager.shared.fetchPets { result in
            DispatchQueue.main.async {
                self.isLoadingPets = false
                switch result {
                case .success(let pets):
                    self.pets = pets
                    print("Fetched \(pets.count) pets")
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    print("Error fetching pets: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func fetchServices() {
        isLoadingServices = true
        DatabaseManager.shared.fetchServices { result in
            DispatchQueue.main.async {
                self.isLoadingServices = false
                switch result {
                case .success(let services):
                    self.services = services
                    print("Fetched \(services.count) services")
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    print("Error fetching services: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func updateAvailableIntervals(date: Date, groomer: Groomer, services: [Service]) {
        guard !services.isEmpty else {
            DispatchQueue.main.async {
                self.availableIntervals = []
                self.isLoadingIntervals = false
            }
            return
        }
        
        isLoadingIntervals = true
        let totalDuration = services.reduce(0) { $0 + $1.duration }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        guard let openingDate = formatter.date(from: groomer.openingHour),
              let closingDate = formatter.date(from: groomer.closingHour) else {
            DispatchQueue.main.async {
                self.errorMessage = "Formato de horario inválido: \(groomer.openingHour)-\(groomer.closingHour)"
                self.availableIntervals = []
                self.isLoadingIntervals = false
            }
            return
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let openingTime = calendar.date(bySettingHour: calendar.component(.hour, from: openingDate), minute: calendar.component(.minute, from: openingDate), second: 0, of: startOfDay),
              let closingTime = calendar.date(bySettingHour: calendar.component(.hour, from: closingDate), minute: calendar.component(.minute, from: closingDate), second: 0, of: startOfDay) else {
            DispatchQueue.main.async {
                self.errorMessage = "No se pudo calcular el horario de apertura/cierre"
                self.availableIntervals = []
                self.isLoadingIntervals = false
            }
            return
        }
        
        var intervals: [Date] = []
        var currentTime = openingTime
        while currentTime < closingTime {
            intervals.append(currentTime)
            if let nextTime = calendar.date(byAdding: .minute, value: totalDuration, to: currentTime) {
                currentTime = nextTime
            } else {
                break
            }
        }
        
        DatabaseManager.shared.fetchReservationsForGroomer(groomerID: groomer.id, date: date) { result in
            DispatchQueue.main.async {
                self.isLoadingIntervals = false
                switch result {
                case .success(let reservations):
                    let occupiedIntervals = reservations.filter { $0.status == "confirmada" }.map { ($0.date, $0.endDate) }
                    let availableIntervals = intervals.filter { interval in
                        guard let endInterval = calendar.date(byAdding: .minute, value: totalDuration, to: interval) else {
                            return false
                        }
                        return !occupiedIntervals.contains { (start, end) in
                            interval < end && endInterval > start
                        }
                    }
                    
                    self.availableIntervals = availableIntervals.map { start in
                        let end = calendar.date(byAdding: .minute, value: totalDuration, to: start)!
                        return "\(self.dateFormatter.string(from: start)) - \(self.dateFormatter.string(from: end))"
                    }
                    print("Available intervals for \(date): \(self.availableIntervals)")
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    print("Error fetching reservations for intervals: \(error.localizedDescription)")
                    self.availableIntervals = []
                }
            }
        }
    }
    
    func createReservation(selectedDate: Date, selectedInterval: String?, groomer: Groomer, selectedPetID: String?, selectedServices: [Service], completion: @escaping (Bool) -> Void) {
        guard let petID = selectedPetID else {
            self.errorMessage = "Por favor, selecciona un perro"
            print("Error: No pet selected")
            completion(false)
            return
        }
        guard let userID = AuthManager.shared.getCurrentUser() else {
            self.errorMessage = "No hay usuario autenticado"
            print("Error: No authenticated user")
            completion(false)
            return
        }
        guard !selectedServices.isEmpty else {
            self.errorMessage = "Por favor, selecciona al menos un servicio"
            print("Error: No services selected")
            completion(false)
            return
        }
        guard let interval = selectedInterval else {
            self.errorMessage = "Por favor, selecciona un intervalo de tiempo"
            print("Error: No interval selected")
            completion(false)
            return
        }
        
        let components = interval.split(separator: " - ").map { String($0) }
        guard components.count == 2,
              let startDate = dateFormatter.date(from: components[0]),
              let endDate = dateFormatter.date(from: components[1]) else {
            self.errorMessage = "Formato de intervalo inválido"
            print("Error: Invalid interval format: \(interval)")
            completion(false)
            return
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        guard let reservationStart = calendar.date(bySettingHour: calendar.component(.hour, from: startDate), minute: calendar.component(.minute, from: startDate), second: 0, of: startOfDay),
              let reservationEnd = calendar.date(bySettingHour: calendar.component(.hour, from: endDate), minute: calendar.component(.minute, from: endDate), second: 0, of: startOfDay) else {
            self.errorMessage = "No se pudo calcular la fecha de la reserva"
            print("Error: Failed to calculate reservation dates")
            completion(false)
            return
        }
        
        let reservation = Reservation(
            id: UUID().uuidString,
            date: reservationStart,
            endDate: reservationEnd,
            groomerID: groomer.id,
            petID: petID,
            userID: userID,
            services: selectedServices,
            status: "confirmada"
        )
        
        DatabaseManager.shared.createReservation(reservation: reservation) { error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    print("Error creating reservation: \(error.localizedDescription)")
                    completion(false)
                } else {
                    print("Reservation created successfully")
                    completion(true)
                }
            }
        }
    }
}

// Extensión para hacer CLLocationCoordinate2D Hashable
extension CLLocationCoordinate2D: Hashable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(latitude)
        hasher.combine(longitude)
    }
}

struct CreateReservationFromGroomerView_Previews: PreviewProvider {
    static var previews: some View {
        CreateReservationFromGroomerView(groomer: Groomer(id: "test", address: "Test Address", description: "Test Desc", lat: 40.416775, lng: -3.703790, name: "Test Groomer", photoURL: "https://example.com/test.jpg", openingHour: "10:00", closingHour: "14:00"))
            .environmentObject(AuthManager.shared)
    }
}
