// Features/Authentication/AuthGateView.swift
// SlangCheck
//
// The sheet presented when an unauthenticated user taps Quiz or Daily Crossword.
// Explains why an account is needed, then hosts the sign-in / sign-up form.
// On successful auth, `onSuccess` is called so the game can launch immediately.

import AuthenticationServices
import SwiftUI

// MARK: - AuthGateView

/// Entry point for the auth gate sheet. Owns and builds `AuthenticationViewModel`.
struct AuthGateView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.appEnvironment) private var env
    @Environment(AuthState.self) private var authState

    /// Called after a successful sign-in so the caller can present the game.
    let onSuccess: () -> Void

    @State private var viewModel: AuthenticationViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    AuthFormView(viewModel: vm, onSuccess: {
                        dismiss()
                        onSuccess()
                    })
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(SlangColor.background.ignoresSafeArea())
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "auth.cancel", defaultValue: "Cancel")) {
                        dismiss()
                    }
                    .font(.slang(.body))
                }
            }
        }
        .task {
            guard viewModel == nil else { return }
            viewModel = AuthenticationViewModel(
                authService: env.authService,
                authState:   authState
            )
        }
    }
}

// MARK: - AuthFormView

/// The actual sign-in / sign-up form. Separated so it can be reused if needed.
private struct AuthFormView: View {

    @Bindable var viewModel: AuthenticationViewModel
    let onSuccess: () -> Void

    @Environment(AuthState.self) private var authState
    @FocusState private var focusedField: Field?

    private enum Field { case email, password, confirmPassword, displayName }

    var body: some View {
        ScrollView {
            VStack(spacing: SlangSpacing.lg) {
                header
                modeToggle
                appleButton
                divider
                emailForm
                submitButton
                modeSwitch
            }
            .padding(.horizontal, SlangSpacing.md)
            .padding(.top, SlangSpacing.md)
            .padding(.bottom, SlangSpacing.xl)
        }
        .background(SlangColor.background.ignoresSafeArea())
        .navigationTitle(viewModel.mode == .signIn
            ? String(localized: "auth.signIn.title", defaultValue: "Sign In")
            : String(localized: "auth.signUp.title", defaultValue: "Create Account"))
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .onChange(of: authState.isAuthenticated) { _, authenticated in
            if authenticated { onSuccess() }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: SlangSpacing.sm) {
            ZStack {
                Circle()
                    .fill(SlangColor.primary.opacity(0.12))
                    .frame(width: 72, height: 72)
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(SlangColor.primary)
                    .accessibilityHidden(true)
            }
            Text(String(localized: "auth.gate.tagline",
                        defaultValue: "Create a free account to play Quiz & Daily Crossword"))
                .font(.slang(.body))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, SlangSpacing.md)
        }
        .padding(.top, SlangSpacing.sm)
    }

    // MARK: - Mode Toggle

    private var modeToggle: some View {
        Picker("", selection: $viewModel.mode) {
            Text(String(localized: "auth.toggle.signIn", defaultValue: "Sign In"))
                .tag(AuthenticationViewModel.Mode.signIn)
            Text(String(localized: "auth.toggle.signUp", defaultValue: "Sign Up"))
                .tag(AuthenticationViewModel.Mode.signUp)
        }
        .pickerStyle(.segmented)
        .onChange(of: viewModel.mode) { _, _ in
            viewModel.errorMessage = nil
        }
    }

    // MARK: - Sign in with Apple

    private var appleButton: some View {
        SignInWithAppleButton(
            viewModel.mode == .signIn ? .signIn : .signUp
        ) { request in
            viewModel.prepareAppleRequest(request)
        } onCompletion: { result in
            Task { await viewModel.handleAppleResult(result) }
        }
        .signInWithAppleButtonStyle(.black)
        .frame(height: 52)
        .clipShape(RoundedRectangle(cornerRadius: SlangCornerRadius.button))
        .disabled(viewModel.isLoading)
        .accessibilityLabel(
            viewModel.mode == .signIn
                ? String(localized: "auth.apple.signIn", defaultValue: "Sign in with Apple")
                : String(localized: "auth.apple.signUp", defaultValue: "Sign up with Apple")
        )
    }

    // MARK: - Divider

    private var divider: some View {
        HStack(spacing: SlangSpacing.sm) {
            Rectangle().fill(SlangColor.separator).frame(height: 1)
            Text(String(localized: "auth.or", defaultValue: "or"))
                .font(.slang(.caption))
                .foregroundStyle(.secondary)
            Rectangle().fill(SlangColor.separator).frame(height: 1)
        }
    }

    // MARK: - Email Form

    @ViewBuilder
    private var emailForm: some View {
        VStack(spacing: SlangSpacing.sm) {
            // Display name — sign-up only
            if viewModel.mode == .signUp {
                authField(
                    icon:        "person",
                    placeholder: String(localized: "auth.displayName.placeholder",
                                        defaultValue: "Display Name"),
                    text:        $viewModel.displayName,
                    field:       .displayName,
                    contentType: .name
                )
            }

            authField(
                icon:        "envelope",
                placeholder: String(localized: "auth.email.placeholder",
                                    defaultValue: "Email"),
                text:        $viewModel.email,
                field:       .email,
                contentType: .emailAddress
            )

            secureField(
                icon:        "lock",
                placeholder: String(localized: "auth.password.placeholder",
                                    defaultValue: "Password"),
                text:        $viewModel.password,
                field:       .password
            )

            if viewModel.mode == .signUp {
                secureField(
                    icon:        "lock.fill",
                    placeholder: String(localized: "auth.confirmPassword.placeholder",
                                        defaultValue: "Confirm Password"),
                    text:        $viewModel.confirmPassword,
                    field:       .confirmPassword
                )
            }

            // Error message
            if let msg = viewModel.errorMessage {
                HStack(spacing: SlangSpacing.xs) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(SlangColor.errorRed)
                        .accessibilityHidden(true)
                    Text(msg)
                        .font(.slang(.caption))
                        .foregroundStyle(SlangColor.errorRed)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, SlangSpacing.xs)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.mode)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.errorMessage)
    }

    // MARK: - Submit Button

    private var submitButton: some View {
        Button {
            focusedField = nil
            Task { await viewModel.submit() }
        } label: {
            HStack(spacing: SlangSpacing.sm) {
                if viewModel.isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text(viewModel.mode == .signIn
                         ? String(localized: "auth.submit.signIn", defaultValue: "Sign In")
                         : String(localized: "auth.submit.signUp", defaultValue: "Create Account"))
                        .font(.slang(.label))
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, SlangSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: SlangCornerRadius.button)
                    .fill(viewModel.isLoading ? SlangColor.primary.opacity(0.6) : SlangColor.primary)
            )
        }
        .disabled(viewModel.isLoading)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isLoading)
    }

    // MARK: - Mode Switch Link

    private var modeSwitch: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                viewModel.mode = viewModel.mode == .signIn ? .signUp : .signIn
                viewModel.errorMessage = nil
            }
        } label: {
            Text(viewModel.mode == .signIn
                 ? String(localized: "auth.switchToSignUp",
                           defaultValue: "Don't have an account? Sign Up")
                 : String(localized: "auth.switchToSignIn",
                           defaultValue: "Already have an account? Sign In"))
                .font(.slang(.caption))
                .foregroundStyle(SlangColor.primary)
        }
    }

    // MARK: - Field Builders

    private func authField(
        icon: String,
        placeholder: String,
        text: Binding<String>,
        field: Field,
        contentType: UITextContentType
    ) -> some View {
        HStack(spacing: SlangSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(SlangColor.primary)
                .frame(width: 20)
                .accessibilityHidden(true)
            TextField(placeholder, text: text)
                .font(.slang(.body))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textContentType(contentType)
                .keyboardType(contentType == .emailAddress ? .emailAddress : .default)
                .focused($focusedField, equals: field)
                .submitLabel(.next)
                .onSubmit { advanceFocus(from: field) }
        }
        .padding(SlangSpacing.md)
        .neumorphicSurface()
    }

    private func secureField(
        icon: String,
        placeholder: String,
        text: Binding<String>,
        field: Field
    ) -> some View {
        HStack(spacing: SlangSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(SlangColor.primary)
                .frame(width: 20)
                .accessibilityHidden(true)
            SecureField(placeholder, text: text)
                .font(.slang(.body))
                .textContentType(field == .password ? .password : .newPassword)
                .focused($focusedField, equals: field)
                .submitLabel(field == .confirmPassword ? .done : .next)
                .onSubmit { advanceFocus(from: field) }
        }
        .padding(SlangSpacing.md)
        .neumorphicSurface()
    }

    private func advanceFocus(from field: Field) {
        switch (viewModel.mode, field) {
        case (.signUp, .displayName):    focusedField = .email
        case (_, .email):                focusedField = .password
        case (.signUp, .password):       focusedField = .confirmPassword
        default:
            focusedField = nil
            Task { await viewModel.submit() }
        }
    }
}

// MARK: - Preview

#Preview("AuthGateView") {
    AuthGateView(onSuccess: {})
        .environment(\.appEnvironment, .preview())
        .environment(AuthState(
            authService:       NoOpAuthenticationService(),
            profileRepository: NoOpUserProfileRepository()
        ))
}
