// DesignSystem/Effects.swift
// SlangCheck
//
// Reusable ViewModifiers for Glassmorphism and Neumorphism surface treatments.
// Per DESIGN_SYSTEM.md: these effects are never mixed on the same component.
// Cards and floating elements use Glassmorphism. Input fields and panels use Neumorphism.
// NEVER re-implement these inline. Always compose from these modifiers.

import SwiftUI

// MARK: - Glassmorphism Modifier

/// Applies the SlangCheck Glassmorphism surface treatment.
/// Use on: Flashcards (Swiper), floating panels, modals, Aura Cards.
///
/// Spec:
/// - Background: `.ultraThinMaterial` blur
/// - Border: 0.5pt, white at 30% (light) / 10% (dark) opacity
/// - Shadow: y 8pt, blur 20pt, black at 15% opacity
/// - Corner: 20pt radius
struct GlassCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: SlangCornerRadius.card)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: SlangCornerRadius.card)
                    .strokeBorder(
                        Color.white.opacity(colorScheme == .dark ? 0.10 : 0.30),
                        lineWidth: 0.5
                    )
            )
            .shadow(
                color: Color.black.opacity(0.15),
                radius: 20,
                x: 0,
                y: 8
            )
            .clipShape(RoundedRectangle(cornerRadius: SlangCornerRadius.card))
    }
}

// MARK: - Neumorphism Modifier

/// Applies the SlangCheck Neumorphism surface treatment.
/// Use on: Input fields, quiz option buttons (resting state), settings panels.
///
/// Spec:
/// - Light: white outer shadow (top-left) + blue-gray outer shadow (bottom-right)
/// - Dark: dark-slate outer shadow (top-left) + pure-black outer shadow (bottom-right)
/// - Background matches the `SlangColor.background` token
struct NeumorphicSurfaceModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background(SlangColor.background)
            .cornerRadius(SlangCornerRadius.cell)
            .shadow(
                color: SlangColor.neumorphicShadowLight.opacity(0.80),
                radius: 8,
                x: -4,
                y: -4
            )
            .shadow(
                color: SlangColor.neumorphicShadowDark.opacity(0.60),
                radius: 8,
                x: 4,
                y: 4
            )
    }
}

// MARK: - Pressed / Active State Modifier

/// Applies the standard interactive pressed-state animation.
/// Scale: 0.96×, Duration: 0.12s easeOut
struct PressedStateModifier: ViewModifier {
    let isPressed: Bool

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.12), value: isPressed)
    }
}

// MARK: - Reduce Motion Aware Modifier

/// Wraps any animation-dependent view to respect the system Reduce Motion setting.
/// When Reduce Motion is on, replaces sliding/scaling with a crossfade.
struct ReduceMotionAware<T: Equatable>: ViewModifier {
    let value: T
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if reduceMotion {
            content.animation(.default, value: value)
        } else {
            content.animation(
                .spring(response: 0.35, dampingFraction: 0.7),
                value: value
            )
        }
    }
}

// MARK: - Shake Effect (GeometryEffect)

/// Applies a horizontal shake animation. Drive with a Bool state value:
/// set to `true`, wait for the animation to play, then reset to `false`.
///
/// Usage:
/// ```swift
/// someView.modifier(ShakeEffect(trigger: $shakeTrigger))
/// ```
struct ShakeEffect: GeometryEffect {
    /// The amount to animate. Animate from 0 → 1 to produce the shake.
    var amount: CGFloat = 10
    var shakesPerUnit: CGFloat = 3
    var animatableData: CGFloat

    init(trigger: CGFloat) {
        self.animatableData = trigger
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = amount * sin(animatableData * .pi * shakesPerUnit)
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}

// MARK: - Profile Card Modifier

/// Solid-white card with a subtle border and hard drop shadow.
/// Matches the onboarding option-row aesthetic: systemBackground fill,
/// 1.5pt primary-tinted border, and a crisp 4pt hard shadow (radius 0).
/// Shadow is scoped to the background shape to avoid the double-text artifact
/// that appears when shadow(radius:0) is applied to a view containing text.
///
/// Spec:
/// - Background: `Color(.systemBackground)` (adapts to light/dark)
/// - Border: 1.5pt, `Color.primary` at 12% opacity
/// - Shadow: y 4pt, radius 0, `SlangColor.hardShadow` — adapts to light/dark mode
/// - Corner: `SlangCornerRadius.card` (20pt)
struct ProfileCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: SlangCornerRadius.card)
                    .fill(Color(.systemBackground))
            }
            .background {
                RoundedRectangle(cornerRadius: SlangCornerRadius.card)
                    .fill(SlangColor.hardShadow)
                    .offset(y: 4)
            }
    }
}

// MARK: - View Extension Convenience API

public extension View {

    /// Applies the Glassmorphism surface treatment defined in DESIGN_SYSTEM.md §6.1.
    func glassCard() -> some View {
        modifier(GlassCardModifier())
    }

    /// Applies a solid-white card with hard drop shadow, matching the onboarding aesthetic.
    /// Use on Profile cards, quick-access rows, and any surface that needs the
    /// systemBackground + hard-shadow look instead of frosted glassmorphism.
    func profileCard() -> some View {
        modifier(ProfileCardModifier())
    }

    /// Applies the Neumorphism surface treatment defined in DESIGN_SYSTEM.md §6.2.
    func neumorphicSurface() -> some View {
        modifier(NeumorphicSurfaceModifier())
    }

    /// Applies the interactive pressed-state scale animation defined in DESIGN_SYSTEM.md §6.3.
    func pressedState(_ isPressed: Bool) -> some View {
        modifier(PressedStateModifier(isPressed: isPressed))
    }

    /// Applies a spring animation that degrades to crossfade when Reduce Motion is enabled.
    func springAnimation<T: Equatable>(value: T) -> some View {
        modifier(ReduceMotionAware(value: value))
    }
}
