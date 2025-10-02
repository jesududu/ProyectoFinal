import SwiftUI

// Extensión para formatear precios
extension Double {
    var formattedPrice2: String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: self))?.appending(" €") ?? "\(self) €"
    }
}

struct ReservationsView: View {
    @StateObject private var viewModel = ReservationsViewModel()
    @State private var filter: ReservationFilter = .confirmada
    @State private var showCancelConfirmation = false
    @State private var showCancelSuccess = false
    @State private var selectedReservationID: String?
    @EnvironmentObject var authManager: AuthManager
    
    enum ReservationFilter: String, CaseIterable, Identifiable {
        case confirmada
        case cancelada
        
        var id: String { self.rawValue }
        
        var displayName: String {
            switch self {
            case .confirmada: return "Confirmadas"
            case .cancelada: return "Canceladas"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.isLoadingPets {
                    ProgressView()
                        .padding()
                } else if viewModel.pets.isEmpty {
                    Text("No tienes perros registrados")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    Picker("Seleccionar Perro", selection: $viewModel.selectedPetID) {
                        Text("Selecciona un perro").tag(nil as String?)
                        ForEach(viewModel.pets, id: \.id) { pet in
                            Text(pet.name).tag(pet.id as String?)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding()
                    .onChange(of: viewModel.selectedPetID) { oldValue, newValue in
                        print("Selected petID changed from \(String(describing: oldValue)) to \(String(describing: newValue))")
                        viewModel.fetchReservations()
                    }
                    
                    Picker("Filtrar Reservas", selection: $filter) {
                        ForEach(ReservationFilter.allCases) { filter in
                            Text(filter.displayName).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    .onChange(of: filter) { oldValue, newValue in
                        print("Filter changed from \(oldValue.displayName) to \(newValue.displayName)")
                    }
                    
                    if viewModel.isLoadingReservations {
                        ProgressView()
                            .padding()
                    } else if let error = viewModel.error {
                        Text("Error: \(error.localizedDescription)")
                            .foregroundColor(.red)
                            .padding()
                    } else if viewModel.selectedPetID == nil {
                        Text("Por favor, selecciona un perro")
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        let filteredReservations = viewModel.reservations.filter {
                            $0.status.lowercased() == filter.rawValue.lowercased()
                        }
                        
                        Text("")
                            .hidden()
                            .onAppear {
                                print("Rendering \(filteredReservations.count) reservations, filter: \(filter.displayName), all reservations: \(viewModel.reservations.count)")
                            }
                            .onChange(of: viewModel.reservations) { _, _ in
                                print("Reservations updated, rendering \(filteredReservations.count) reservations, filter: \(filter.displayName)")
                            }
                            .onChange(of: filter) { _, _ in
                                print("Filter updated, rendering \(filteredReservations.count) reservations, filter: \(filter.displayName)")
                            }
                        
                        if filteredReservations.isEmpty {
                            Text("No hay reservas \(filter.displayName.lowercased()) para este perro")
                                .foregroundColor(.gray)
                                .padding()
                        } else {
                            List(filteredReservations) { reservation in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Fecha: \(reservation.date, formatter: dateFormatter)")
                                        .font(.headline)
                                    Text("Fin: \(reservation.endDate, formatter: dateFormatter)")
                                    Text("Peluquería ID: \(reservation.groomerID)")
                                    Text("Estado: \(reservation.status)")
                                    Text("Servicios:")
                                    ForEach(reservation.services, id: \.id) { service in
                                        Text("- \(service.name) (\(service.duration) min, \(service.price.formattedPrice))")
                                    }
                                    if reservation.status.lowercased() == "confirmada" {
                                        Button("Cancelar") {
                                            selectedReservationID = reservation.id
                                            showCancelConfirmation = true
                                        }
                                        .padding()
                                        .background(Color.teal)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Reservas")
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
                print("ReservationsView appeared, fetching pets")
                viewModel.fetchPets()
            }
            .alert("¿Quieres cancelar esta reserva?", isPresented: $showCancelConfirmation) {
                Button("Sí") {
                    if let reservationID = selectedReservationID {
                        print("Cancelling reservation: \(reservationID)")
                        viewModel.cancelReservation(reservationID: reservationID) {
                            showCancelSuccess = true
                        }
                    }
                }
                Button("No", role: .cancel) {
                    selectedReservationID = nil
                }
            }
            .alert("Reserva cancelada con éxito", isPresented: $showCancelSuccess) {
                Button("OK") {
                    selectedReservationID = nil
                }
            }
        }
        .environmentObject(authManager)
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}



struct ReservationsView_Previews: PreviewProvider {
    static var previews: some View {
        ReservationsView()
            .environmentObject(AuthManager.shared)
    }
}
