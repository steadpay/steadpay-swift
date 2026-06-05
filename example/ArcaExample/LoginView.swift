import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var navigateToHome = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            Text("arcta")
                .font(.system(size: 40, weight: .black))
                .foregroundStyle(Color(red: 0.10, green: 0.10, blue: 0.18))
                .kerning(-1)

            Text("Analytics for modern teams")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .padding(.top, 4)
                .padding(.bottom, 40)

            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)

            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)
                .padding(.top, 12)

            NavigationLink(destination: HomeView(), isActive: $navigateToHome) {
                EmptyView()
            }

            Button {
                navigateToHome = true
            } label: {
                Text("Sign in")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(red: 0.10, green: 0.10, blue: 0.18))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(.top, 20)

            Spacer()
        }
        .padding(.horizontal, 32)
        .navigationBarHidden(true)
    }
}
