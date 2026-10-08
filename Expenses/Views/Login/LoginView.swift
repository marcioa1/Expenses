//
//  LoginView.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 05/10/26.
//

import SwiftUI

struct LoginView: View {
    private enum Field {
        case email, password
    }

    @State private var viewModel: LoginViewModel
    @FocusState private var focusedField: Field?

    private let onLoginSuccess: (AuthSession) -> Void

    init(
        authService: any AuthService,
        onLoginSuccess: @escaping (AuthSession) -> Void = { _ in }
    ) {
        _viewModel = State(initialValue: LoginViewModel(authService: authService))
        self.onLoginSuccess = onLoginSuccess
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 8) {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(.orange)
                        Text("Expenses")
                            .font(.largeTitle.bold())
                        Text("Sign in to continue")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                    .listRowBackground(Color.clear)
                }

                Section {
                    TextField("Email", text: $viewModel.email)
                        .textContentType(.username)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .email)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .password }

                    SecureField("Password", text: $viewModel.password)
                        .textContentType(.password)
                        .focused($focusedField, equals: .password)
                        .submitLabel(.go)
                        .onSubmit { submit() }
                } footer: {
                    if let error = viewModel.emailError ?? viewModel.errorMessage {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Button {
                        submit()
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Sign In")
                                .bold()
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(!viewModel.canSubmit)
                }
            }
            .tint(.orange)
        }
    }

    private func submit() {
        focusedField = nil
        Task {
            if let session = await viewModel.login() {
                onLoginSuccess(session)
            }
        }
    }
}

#Preview("Success") {
    LoginView(authService: MockAuthService(delay: .seconds(1)))
}

#Preview("Invalid Credentials") {
    LoginView(authService: MockAuthService(error: .invalidCredentials, delay: .seconds(1)))
}
