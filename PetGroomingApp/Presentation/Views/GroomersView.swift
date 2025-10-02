import SwiftUI
import UIKit

// Representable para integrar UISearchBar en SwiftUI
struct SearchBar: UIViewRepresentable {
    @Binding var text: String
    
    class Coordinator: NSObject, UISearchBarDelegate {
        @Binding var text: String
        
        init(text: Binding<String>) {
            _text = text
        }
        
        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            text = searchText
        }
        
        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            searchBar.resignFirstResponder()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(text: $text)
    }
    
    func makeUIView(context: Context) -> UISearchBar {
        let searchBar = UISearchBar()
        searchBar.delegate = context.coordinator
        searchBar.placeholder = "Buscar peluquería"
        return searchBar
    }
    
    func updateUIView(_ uiView: UISearchBar, context: Context) {
        uiView.text = text
    }
}

struct GroomersView: View {
    @StateObject private var viewModel = GroomersViewModel()
    @State private var searchText = ""
    @EnvironmentObject var authManager: AuthManager
    
    var filteredGroomers: [Groomer] {
        if searchText.isEmpty {
            return viewModel.groomers
        } else {
            return viewModel.groomers.filter {
                $0.name.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                } else if viewModel.groomers.isEmpty {
                    Text("No hay peluquerías disponibles")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List(filteredGroomers) { groomer in
                        NavigationLink(destination: CreateReservationFromGroomerView(groomer: groomer)) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(groomer.name)
                                    .font(.headline)
                                AsyncImage(url: URL(string: groomer.photoURL)) { image in
                                    image.resizable().scaledToFit()
                                } placeholder: {
                                    ProgressView()
                                }
                                .frame(height: 150)
                                .cornerRadius(8)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Peluquerías")
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
                print("GroomersView appeared, fetching groomers")
                viewModel.fetchGroomers()
            }
        }
        .environmentObject(authManager)
    }
}

class GroomersViewModel: ObservableObject {
    @Published var groomers: [Groomer] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    func fetchGroomers() {
        isLoading = true
        print("Fetching groomers")
        DatabaseManager.shared.fetchGroomers { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let groomers):
                    self.groomers = groomers
                    print("Fetched \(groomers.count) groomers: \(groomers.map { $0.id })")
                case .failure(let error):
                    self.error = error
                    print("Error fetching groomers: \(error.localizedDescription)")
                }
            }
        }
    }
}

struct GroomersView_Previews: PreviewProvider {
    static var previews: some View {
        GroomersView()
            .environmentObject(AuthManager.shared)
    }
}
