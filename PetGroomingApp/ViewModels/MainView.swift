import SwiftUI

struct MainView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        if let user = authManager.currentUser {
            if user.role == "admin" {
                AdminView()
                    .environmentObject(authManager)
            } else {
                TabView {
                    GroomersView()
                        .tabItem {
                            Label("Peluquerías", systemImage: "scissors")
                        }
                    PetsView()
                        .tabItem {
                            Label("Mis Perros", systemImage: "pawprint")
                        }
                    ReservationsView()
                        .tabItem {
                            Label("Reservas", systemImage: "calendar")
                        }
                }
                .environmentObject(authManager)
            }
        } else {
            LoginView()
                .environmentObject(authManager)
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
            .environmentObject(AuthManager.shared)
    }
}
