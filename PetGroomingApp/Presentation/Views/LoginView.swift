import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @EnvironmentObject var authManager: AuthManager
    @FocusState private var focusedField: Field? 
    
    enum Field: Hashable {
        case email
        case password
        case name
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image("backgraund")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .edgesIgnoringSafeArea(.all)
                    .opacity(0.8)
                
                ScrollView {
                    VStack(spacing: 20) {
                        Image("logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: min(geometry.size.width * 0.4, 150))
                        
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .padding()
                                .frame(maxWidth: min(geometry.size.width * 0.8, 400))
                        }
                        
                        TextField("Email", text: $viewModel.email)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .focused($focusedField, equals: .email)
                            .padding(.horizontal)
                            .frame(maxWidth: min(geometry.size.width * 0.8, 400))
                            .onTapGesture {
                                print("Tapped Email field")
                                focusedField = .email
                            }
                        
                        SecureField("Contraseña", text: $viewModel.password)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.password)
                            .focused($focusedField, equals: .password)
                            .padding(.horizontal)
                            .frame(maxWidth: min(geometry.size.width * 0.8, 400))
                            .onTapGesture {
                                print("Tapped Password field")
                                focusedField = .password
                            }
                        
                        if viewModel.isSignUp {
                            TextField("Nombre", text: $viewModel.name)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.default)
                                .textContentType(.name)
                                .focused($focusedField, equals: .name)
                                .padding(.horizontal)
                                .frame(maxWidth: min(geometry.size.width * 0.8, 400))
                                .onTapGesture {
                                    print("Tapped Name field")
                                    focusedField = .name
                                }
                        }
                        
                        Button(viewModel.isSignUp ? "Registrarse" : "Iniciar sesión") {
                            print("Tapped \(viewModel.isSignUp ? "Registrarse" : "Iniciar sesión")")
                            viewModel.performAction()
                            focusedField = nil
                        }
                        .padding()
                        .frame(maxWidth: min(geometry.size.width * 0.8, 400))
                        .background(Color.teal)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .disabled(viewModel.isLoading)
                        
                        if !viewModel.isSignUp {
                            Button("Olvidé mi contraseña") {
                                print("Tapped Olvidé mi contraseña")
                                viewModel.forgotPassword()
                                focusedField = nil
                            }
                            .padding()
                            .frame(maxWidth: min(geometry.size.width * 0.8, 400))
                            .background(Color.teal)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        
                        Button(viewModel.isSignUp ? "Ya tengo cuenta" : "Crear cuenta") {
                            print("Tapped \(viewModel.isSignUp ? "Ya tengo cuenta" : "Crear cuenta")")
                            viewModel.isSignUp.toggle()
                            focusedField = nil
                        }
                        .padding()
                        .frame(maxWidth: min(geometry.size.width * 0.8, 400))
                        .background(Color.teal)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding()
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .navigationTitle(viewModel.isSignUp ? "Registro" : "Login")
        .alert("Email enviado", isPresented: $viewModel.showForgotPasswordAlert) {
            Button("OK") { }
        } message: {
            Text("Revisa tu email para restablecer la contraseña.")
        }
    }
}

class LoginViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var name = ""
    @Published var isSignUp = false
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var showForgotPasswordAlert = false
    
    func performAction() {
        isLoading = true
        errorMessage = nil
        if isSignUp {
            AuthManager.shared.signUp(email: email, password: password, name: name) { result in
                DispatchQueue.main.async {
                    self.isLoading = false
                    switch result {
                    case .success:
                        print("Sign-up successful")
                    case .failure(let error):
                        self.errorMessage = error.localizedDescription
                        print("Sign-up error: \(error.localizedDescription)")
                    }
                }
            }
        } else {
            AuthManager.shared.signIn(email: email, password: password) { result in
                DispatchQueue.main.async {
                    self.isLoading = false
                    switch result {
                    case .success:
                        print("Sign-in successful")
                    case .failure(let error):
                        self.errorMessage = error.localizedDescription
                        print("Sign-in error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    func forgotPassword() {
        if email.isEmpty {
            errorMessage = "Ingresa tu email para restablecer la contraseña."
            print("Forgot password error: Email is empty")
            return
        }
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    print("Forgot password error: \(error.localizedDescription)")
                } else {
                    self.showForgotPasswordAlert = true
                    print("Password reset email sent")
                }
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AuthManager.shared)
    }
}
