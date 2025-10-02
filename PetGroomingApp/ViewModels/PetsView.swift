import SwiftUI

struct PetsView: View {
    @StateObject private var viewModel = PetsViewModel()
    @State private var showAddPetModal = false
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.isLoading {
                    ProgressView()
                } else if let error = viewModel.error {
                    Text("Error: \(error.localizedDescription)")
                        .foregroundColor(.red)
                } else if viewModel.pets.isEmpty {
                    Text("No tienes perros registrados")
                        .foregroundColor(.gray)
                } else {
                    List(viewModel.pets) { pet in
                        VStack(alignment: .leading) {
                            Text(pet.name)
                                .font(.headline)
                            Text("Raza: \(pet.breed)")
                            if let notes = pet.notes {
                                Text("Notas: \(notes)")
                            }
                            AsyncImage(url: URL(string: pet.photoURL)) { image in
                                image.resizable().scaledToFit()
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(width: 100, height: 100)
                        }
                    }
                }
                Button("Añadir Perro") {
                    print("Tapped Añadir Perro")
                    showAddPetModal = true
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.teal)
                .foregroundColor(.white)
                .cornerRadius(8)
                .padding(.horizontal)
                .sheet(isPresented: $showAddPetModal) {
                    AddPetModalView(viewModel: viewModel)
                }
            }
            .navigationTitle("Mis Perros")
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
                print("PetsView appeared, fetching pets")
                viewModel.fetchPets()
            }
        }
        .environmentObject(authManager)
    }
}

struct AddPetModalView: View {
    let viewModel: PetsViewModel
    @State private var breed = ""
    @State private var name = ""
    @State private var notes = ""
    @State private var photoURL = ""
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case name
        case breed
        case notes
        case photoURL
    }
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Nombre", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.name)
                    .focused($focusedField, equals: .name)
                    .onTapGesture {
                        print("Tapped Nombre field")
                        focusedField = .name
                    }
                TextField("Raza", text: $breed)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.none)
                    .focused($focusedField, equals: .breed)
                    .onTapGesture {
                        print("Tapped Raza field")
                        focusedField = .breed
                    }
                TextField("Notas", text: $notes)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.none)
                    .focused($focusedField, equals: .notes)
                    .onTapGesture {
                        print("Tapped Notas field")
                        focusedField = .notes
                    }
                TextField("URL Foto", text: $photoURL)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.URL)
                    .textContentType(.URL)
                    .focused($focusedField, equals: .photoURL)
                    .onTapGesture {
                        print("Tapped URL Foto field")
                        focusedField = .photoURL
                    }
                HStack(spacing: 10) {
                    Button("Guardar") {
                        print("Tapped Guardar")
                        let pet = Pet(id: UUID().uuidString, breed: breed, name: name, notes: notes, photoURL: photoURL, userID: AuthManager.shared.getCurrentUser() ?? "")
                        viewModel.createPet(pet: pet)
                        dismiss()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.teal)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .disabled(name.isEmpty || breed.isEmpty)
                    
                    Button("Cancelar") {
                        print("Tapped Cancelar")
                        dismiss()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.teal)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding(.horizontal)
            }
            .navigationTitle("Añadir Perro")
            .scrollDismissesKeyboard(.interactively)
        }
    }
}

class PetsViewModel: ObservableObject {
    @Published var pets: [Pet] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    func fetchPets() {
        isLoading = true
        print("Fetching pets")
        DatabaseManager.shared.fetchPets { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let pets):
                    self.pets = pets
                    print("Fetched \(pets.count) pets: \(pets.map { $0.id })")
                case .failure(let error):
                    self.error = error
                    print("Error fetching pets: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func createPet(pet: Pet) {
        DatabaseManager.shared.createPet(pet: pet) { error in
            DispatchQueue.main.async {
                if let error = error {
                    self.error = error
                    print("Error adding pet: \(error.localizedDescription)")
                } else {
                    self.fetchPets()
                    print("Pet added: \(pet.id), \(pet.name)")
                }
            }
        }
    }
}

struct PetsView_Previews: PreviewProvider {
    static var previews: some View {
        PetsView()
            .environmentObject(AuthManager.shared)
    }
}
