import SwiftUI

enum AppTheme {
    // Claymorphic Warm Neutral Palette
    static let pageBackground = Color(red: 0.945, green: 0.937, blue: 0.922) // Soft creamy off-white / light warm beige (#F1EFE9)
    static let cardBackground = Color(red: 0.952, green: 0.945, blue: 0.932) // Soft clay neutral base (#F3F1EE)
    static let depressedBackground = Color(red: 0.895, green: 0.885, blue: 0.865) // Soft internal button depression (#E4E2DC)

    // Claymorphic Dual Shadows (Tactile 3D Extrusion Effect)
    static let clayDarkShadow = Color(red: 0.70, green: 0.67, blue: 0.62).opacity(0.55) // Dark drop-shadow underneath
    static let clayLightShadow = Color.white.opacity(0.92) // Soft white highlight on top
    static let cardShadow = Color(red: 0.70, green: 0.67, blue: 0.62).opacity(0.35)
    static let cardBorder = Color.clear // Zero harsh lines!

    // Minimalist Sans-Serif Dark Charcoal / Slate Typography
    static let textPrimary = Color(red: 0.16, green: 0.18, blue: 0.22) // Dark charcoal / slate (#292E38)
    static let textSecondary = Color(red: 0.46, green: 0.50, blue: 0.56) // Muted slate (#75808F)
    static let textMuted = Color(red: 0.62, green: 0.65, blue: 0.70) // Soft light slate (#9EA6B2)

    // Tactile Accents
    static let accent = Color(red: 0.18, green: 0.20, blue: 0.24) // Deep charcoal tactile accent
    static let secondaryAccent = Color(red: 0.40, green: 0.44, blue: 0.50) // Slate accent
    static let activeGreen = Color(red: 0.15, green: 0.70, blue: 0.42) // Warm tactile active green
    static let activeGreenBg = Color(red: 0.15, green: 0.70, blue: 0.42).opacity(0.16)
    static let espRed = Color(red: 0.90, green: 0.22, blue: 0.21) // Tactile red theme for TERMINALX999/ESP

    static let lightBlue = Color(red: 0.92, green: 0.94, blue: 0.96)
    static let consoleBackground = Color(red: 0.92, green: 0.91, blue: 0.89)
    static let referenceCard = Color.white.opacity(0.85)

    static let pageInset: CGFloat = 16
    static let rowIconSize: CGFloat = 17
    static let rowIconFrame: CGFloat = 28
    static let fileRowIconSize: CGFloat = 17
    static let fileRowIconFrame: CGFloat = 30
    static let fileRowHeight: CGFloat = 60
    static let appIconSize: CGFloat = 32
    static let emptyIconSize: CGFloat = 30
    static let selectionIconSize: CGFloat = 18
}

// MARK: - Claymorphic Styling Modifiers
struct ClaymorphicCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 26
    var depth: CGFloat = 8

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(AppTheme.cardBackground)
                    .shadow(color: AppTheme.clayDarkShadow, radius: depth, x: depth * 0.55, y: depth * 0.7)
                    .shadow(color: AppTheme.clayLightShadow, radius: depth, x: -depth * 0.55, y: -depth * 0.55)
            )
    }
}

struct ClaymorphicCircleModifier: ViewModifier {
    var depth: CGFloat = 6

    func body(content: Content) -> some View {
        content
            .background(
                Circle()
                    .fill(AppTheme.cardBackground)
                    .shadow(color: AppTheme.clayDarkShadow, radius: depth, x: depth * 0.55, y: depth * 0.7)
                    .shadow(color: AppTheme.clayLightShadow, radius: depth, x: -depth * 0.55, y: -depth * 0.55)
            )
    }
}

struct ClaymorphicDepressionModifier: ViewModifier {
    var cornerRadius: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(AppTheme.depressedBackground)
                    .shadow(color: Color.black.opacity(0.08), radius: 3, x: 1.5, y: 2)
            )
    }
}

struct ClaymorphicCapsuleDepressionModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                Capsule()
                    .fill(AppTheme.depressedBackground)
                    .shadow(color: Color.black.opacity(0.08), radius: 3, x: 1.5, y: 2)
            )
    }
}

struct ClaymorphicButtonPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

extension View {
    func claymorphicCard(cornerRadius: CGFloat = 26, depth: CGFloat = 8) -> some View {
        modifier(ClaymorphicCardModifier(cornerRadius: cornerRadius, depth: depth))
    }

    func claymorphicCircle(depth: CGFloat = 6) -> some View {
        modifier(ClaymorphicCircleModifier(depth: depth))
    }

    func claymorphicDepression(cornerRadius: CGFloat = 16) -> some View {
        modifier(ClaymorphicDepressionModifier(cornerRadius: cornerRadius))
    }

    func claymorphicCapsuleDepression() -> some View {
        modifier(ClaymorphicCapsuleDepressionModifier())
    }

    func claymorphicButtonPress() -> some View {
        buttonStyle(ClaymorphicButtonPressStyle())
    }
}

struct AppRowIcon: View {
    let systemName: String
    var tint: Color = AppTheme.accent
    var symbolSize: CGFloat = AppTheme.rowIconSize
    var frameSize: CGFloat = AppTheme.rowIconFrame

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(AppTheme.depressedBackground)
            Image(systemName: systemName)
                .font(.system(size: symbolSize, weight: .medium))
                .foregroundStyle(tint)
        }
        .frame(width: frameSize, height: frameSize)
        .accessibilityHidden(true)
    }
}

struct AppSearchField: View {
    @Binding var text: String
    let prompt: String
    let clearLabel: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
                .accessibilityHidden(true)

            TextField(prompt, text: $text)
                .font(.body)
                .foregroundStyle(AppTheme.textPrimary)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.textMuted)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(clearLabel)
            }
        }
        .padding(.horizontal, 11)
        .frame(minHeight: 38)
        .claymorphicDepression(cornerRadius: 12)
        .padding(.horizontal, AppTheme.pageInset)
        .padding(.vertical, 8)
    }
}

struct AppLogo: View {
    var size: CGFloat = 44

    var body: some View {
        Group {
            if let icon = UIImage(named: "AppIcon60x60")
                ?? Bundle.main.path(forResource: "AppIcon60x60@2x", ofType: "png").flatMap(UIImage.init(contentsOfFile:))
                ?? UIImage(named: "AppIcon") {
                Image(uiImage: icon)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "slider.horizontal.3")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppTheme.cardBackground)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.24, style: .continuous))
        .claymorphicCard(cornerRadius: size * 0.24, depth: 4)
        .accessibilityHidden(true)
    }
}

// MARK: - App Backdrop
struct AnimatedHyperBackdrop: View {
    var body: some View {
        AppTheme.pageBackground
            .ignoresSafeArea()
    }
}

// MARK: - Audio Feedback
import AudioToolbox

enum PatchAudioFeedback {
    static func bypassActivated() {
        AudioServicesPlaySystemSound(1519)
    }
    static func originalRestored() {
        AudioServicesPlaySystemSound(1520)
    }
}
