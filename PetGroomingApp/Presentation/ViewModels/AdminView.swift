import SwiftUI

struct AdminView: View {
    @StateObject private var viewModel = AdminViewModel()
    @EnvironmentObject var authManager: AuthManager
    @FocusState private var focusedField: Field?
    @State private var showSuccessModal = false
    @State private var showErrorModal = false
    @State private var showGroomerForm = true // Controla qué formulario se muestra
    
    enum Field: Hashable {
        case groomerName, groomerAddress, groomerDescription, groomerLat, groomerLng, groomerPhotoURL
        case groomerOpeningHour, groomerClosingHour
        case serviceName, serviceDuration, servicePrice
    }
    
    var body: some View {
        NavigationStack {
            Form {
                if showGroomerForm {
                    Section(header: Text("Crear Peluquería")) {
                        TextField("Nombre", text: $viewModel.groomerName)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.name)
                            .focused($focusedField, equals: .groomerName)
                            .onTapGesture { focusedField = .groomerName }
                        TextField("Dirección", text: $viewModel.groomerAddress)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.streetAddressLine1)
                            .focused($focusedField, equals: .groomerAddress)
                            .onTapGesture { focusedField = .groomerAddress }
                        TextField("Descripción", text: $viewModel.groomerDescription)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.none)
                            .focused($focusedField, equals: .groomerDescription)
                            .onTapGesture { focusedField = .groomerDescription }
                        TextField("Latitud", text: $viewModel.groomerLat)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .groomerLat)
                            .onTapGesture { focusedField = .groomerLat }
                        TextField("Longitud", text: $viewModel.groomerLng)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .groomerLng)
                            .onTapGesture { focusedField = .groomerLng }
                        TextField("URL de Foto", text: $viewModel.groomerPhotoURL)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.URL)
                            .textContentType(.URL)
                            .focused($focusedField, equals: .groomerPhotoURL)
                            .onTapGesture { focusedField = .groomerPhotoURL }
                        TextField("Horario de Apertura (HH:mm)", text: $viewModel.groomerOpeningHour)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numbersAndPunctuation)
                            .focused($focusedField, equals: .groomerOpeningHour)
                            .onTapGesture { focusedField = .groomerOpeningHour }
                        TextField("Horario de Cierre (HH:mm)", text: $viewModel.groomerClosingHour)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numbersAndPunctuation)
                            .focused($focusedField, equals: .groomerClosingHour)
                            .onTapGesture { focusedField = .groomerClosingHour }
                        Button("Crear Peluquería") {
                            print("Tapped Crear Peluquería")
                            viewModel.createGroomer()
                            focusedField = nil
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.teal)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .disabled(!viewModel.isGroomerFormValid)
                    }
                } else {
                    Section(header: Text("Crear Servicio")) {
                        TextField("Nombre del Servicio", text: $viewModel.serviceName)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.none)
                            .focused($focusedField, equals: .serviceName)
                            .onTapGesture { focusedField = .serviceName }
                        TextField("Duración (minutos)", text: $viewModel.serviceDuration)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                            .focused($focusedField, equals: .serviceDuration)
                            .onTapGesture { focusedField = .serviceDuration }
                        TextField("Precio (€)", text: $viewModel.servicePrice)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .servicePrice)
                            .onTapGesture { focusedField = .servicePrice }
                        Button("Crear Servicio") {
                            print("Tapped Crear Servicio")
                            viewModel.createService()
                            focusedField = nil
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.teal)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .disabled(!viewModel.isServiceFormValid)
                    }
                }
            }
            .navigationTitle("Panel de Administrador")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Panel de Administrador")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showGroomerForm.toggle()
                        print("Toggled form to: \(showGroomerForm ? "Groomer" : "Service")")
                    }) {
                        Image(systemName: showGroomerForm ? "scissors.circle.fill" : "plus.circle.fill")
                            .foregroundColor(.teal)
                            .font(.system(size: 24))
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: {
                            print("Clearing all forms")
                            viewModel.clearGroomerForm()
                            viewModel.clearServiceForm()
                            focusedField = nil
                        }) {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.gray)
                                .font(.system(size: 24))
                        }
                        Button(action: {
                            print("Signing out")
                            authManager.signOut()
                        }) {
                            Image(systemName: "power")
                                .font(.system(size: 24))
                        }
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .overlay {
                if showSuccessModal {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                        VStack(spacing: 20) {
                            Text("Éxito")
                                .font(.title)
                                .foregroundColor(.primary)
                            Text(viewModel.successMessage ?? "Operación realizada con éxito")
                                .foregroundColor(.primary)
                            Button("OK") {
                                showSuccessModal = false
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.teal)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 10)
                        .frame(maxWidth: 300)
                    }
                }
                if showErrorModal, let errorMessage = viewModel.errorMessage {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                        VStack(spacing: 20) {
                            Text("Error")
                                .font(.title)
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .foregroundColor(.primary)
                            Button("Cerrar") {
                                showErrorModal = false
                                viewModel.errorMessage = nil
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.teal)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 10)
                        .frame(maxWidth: 300)
                    }
                }
            }
        }
    }
}

class AdminViewModel: ObservableObject {
    @Published var groomerName = ""
    @Published var groomerAddress = ""
    @Published var groomerDescription = ""
    @Published var groomerLat = ""
    @Published var groomerLng = ""
    @Published var groomerPhotoURL = ""
    @Published var groomerOpeningHour = ""
    @Published var groomerClosingHour = ""
    @Published var serviceName = ""
    @Published var serviceDuration = ""
    @Published var servicePrice = ""
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    var isGroomerFormValid: Bool {
        !groomerName.isEmpty &&
        !groomerAddress.isEmpty &&
        !groomerDescription.isEmpty &&
        Double(groomerLat) != nil &&
        Double(groomerLng) != nil &&
        !groomerPhotoURL.isEmpty &&
        isValidTimeFormat(groomerOpeningHour) &&
        isValidTimeFormat(groomerClosingHour)
    }
    
    var isServiceFormValid: Bool {
        !serviceName.isEmpty &&
        Int(serviceDuration) != nil &&
        Double(servicePrice) != nil
    }
    
    private func isValidTimeFormat(_ time: String) -> Bool {
        let regex = "^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$"
        return time.range(of: regex, options: .regularExpression) != nil
    }
    
    func createGroomer() {
        guard isGroomerFormValid else {
            errorMessage = "Por favor, completa todos los campos correctamente"
            print("Invalid groomer form")
            return
        }
        guard let lat = Double(groomerLat), let lng = Double(groomerLng) else {
            errorMessage = "Coordenadas inválidas"
            print("Invalid coordinates")
            return
        }
        let groomer = Groomer(
            id: UUID().uuidString,
            address: groomerAddress,
            description: groomerDescription,
            lat: lat,
            lng: lng,
            name: groomerName,
            photoURL: groomerPhotoURL,
            openingHour: groomerOpeningHour,
            closingHour: groomerClosingHour
        )
        DatabaseManager.shared.createGroomer(groomer: groomer) { error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    print("Error creating groomer: \(error.localizedDescription)")
                } else {
                    self.successMessage = "Peluquería creada con éxito"
                    self.clearGroomerForm()
                    print("Groomer created: \(groomer.id)")
                }
            }
        }
    }
    
    func createService() {
        guard isServiceFormValid else {
            errorMessage = "Por favor, completa todos los campos correctamente"
            print("Invalid service form")
            return
        }
        guard let duration = Int(serviceDuration), let price = Double(servicePrice) else {
            errorMessage = "Duración o precio inválidos"
            print("Invalid duration or price")
            return
        }
        let service = Service(
            id: UUID().uuidString,
            name: serviceName,
            duration: duration,
            price: price
        )
        DatabaseManager.shared.createService(service: service) { error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    print("Error creating service: \(error.localizedDescription)")
                } else {
                    self.successMessage = "Servicio creado con éxito"
                    self.clearServiceForm()
                    print("Service created: \(service.id)")
                }
            }
        }
    }
    
    func clearGroomerForm() {
        groomerName = ""
        groomerAddress = ""
        groomerDescription = ""
        groomerLat = ""
        groomerLng = ""
        groomerPhotoURL = ""
        groomerOpeningHour = ""
        groomerClosingHour = ""
    }
    
    func clearServiceForm() {
        serviceName = ""
        serviceDuration = ""
        servicePrice = ""
    }
}

struct AdminView_Previews: PreviewProvider {
    static var previews: some View {
        AdminView()
            .environmentObject(AuthManager.shared)
    }
}
