// App/MainTabView.swift
// SlangCheck
//
// The tab bar has been removed. Navigation is now handled by the inline chrome
// overlay inside SwiperView (profile avatar top-left, Practice button bottom-center).
// This file is kept as a thin pass-through so AppRootView requires no changes.

import SwiftUI

// MARK: - MainTabView

/// Root container for the app after onboarding.
/// Renders SwiperView directly — no TabView, no bottom nav bar.
struct MainTabView: View {
    var body: some View {
        SwiperView()
    }
}

// MARK: - Preview

#Preview("MainTabView") {
    MainTabView()
        .environment(\.appEnvironment, .preview())
        .environment(AuthState(
            authService: NoOpAuthenticationService(),
            profileRepository: NoOpUserProfileRepository()
        ))
}
