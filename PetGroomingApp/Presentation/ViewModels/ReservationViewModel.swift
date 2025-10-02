//
//  ReservationViewModel.swift
//  PetGroomingApp
//
//  Created by Jesus Bueno on 30/9/25.
//

import Foundation

class ReservationsViewModel: ObservableObject {
    @Published var pets: [Pet] = []
    @Published var reservations: [Reservation] = []
    @Published var selectedPetID: String?
    @Published var isLoadingPets = false
    @Published var isLoadingReservations = false
    @Published var error: Error?
    
    func fetchPets() {
        isLoadingPets = true
        print("Fetching pets")
        DatabaseManager.shared.fetchPets { result in
            DispatchQueue.main.async {
                self.isLoadingPets = false
                switch result {
                case .success(let pets):
                    self.pets = pets
                    print("Fetched \(pets.count) pets: \(pets.map { $0.id })")
                    if let firstPet = pets.first {
                        self.selectedPetID = firstPet.id
                        print("Auto-selected petID: \(self.selectedPetID ?? "nil")")
                        self.fetchReservations()
                    } else {
                        print("No pets found, clearing selectedPetID")
                        self.selectedPetID = nil
                    }
                case .failure(let error):
                    self.error = error
                    print("Error fetching pets: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func fetchReservations() {
        guard let petID = selectedPetID else {
            self.reservations = []
            print("No pet selected, clearing reservations")
            return
        }
        isLoadingReservations = true
        print("Fetching reservations for petID: \(petID)")
        DatabaseManager.shared.fetchReservations(forPetID: petID) { result in
            DispatchQueue.main.async {
                self.isLoadingReservations = false
                switch result {
                case .success(let reservations):
                    self.reservations = reservations
                    print("Fetched \(reservations.count) reservations for petID: \(petID), statuses: \(reservations.map { $0.status })")
                case .failure(let error):
                    self.error = error
                    print("Error fetching reservations for petID: \(petID): \(error.localizedDescription)")
                }
            }
        }
    }
    
    func cancelReservation(reservationID: String, completion: @escaping () -> Void) {
        print("Attempting to cancel reservation: \(reservationID)")
        DatabaseManager.shared.cancelReservation(reservationID: reservationID) { error in
            DispatchQueue.main.async {
                if let error = error {
                    self.error = error
                    print("Error cancelling reservation: \(error.localizedDescription)")
                } else {
                    self.fetchReservations()
                    print("Reservation cancelled: \(reservationID)")
                    completion()
                }
            }
        }
    }
}
