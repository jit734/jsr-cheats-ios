import SwiftUI

struct LicenseActivationView: View {
    @ObservedObject var manager: LicenseManager
    @State private var key = ""
    @FocusState private var keyFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedHyperBackdrop()
                    .ignoresSafeArea()

                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            Spacer(minLength: 42)

                            Text("TERMINALX999")
                                .font(.system(size: 30, weight: .black, design: .rounded))
                                .tracking(1.4)
                                .foregroundStyle(AppTheme.textPrimary)

                            Text("Version: 1.0.0")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)
                                .padding(.top, 5)

                            Text("Package: TERMINALX999")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.accent)
                                .padding(.top, 8)

                            VStack(spacing: 16) {
                                HStack(spacing: 10) {
                                    Image(systemName: manager.isBusy ? "arrow.triangle.2.circlepath" : "key.fill")
                                        .foregroundStyle(AppTheme.accent)
                                        .font(.system(size: 16, weight: .bold))
                                    Text(manager.isBusy ? "Activating TERMINALX999..." : "TERMINALX999 Access")
                                        .font(.system(size: 16, weight: .black, design: .rounded))
                                        .foregroundStyle(AppTheme.textPrimary)
                                    Spacer()
                                }

                                Text("Enter any license key to activate TERMINALX999")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                TextField("License key (any key)", text: $key)
                                    .focused($keyFocused)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .submitLabel(.done)
                                    .onSubmit { activate() }
                                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                                    .foregroundStyle(AppTheme.textPrimary)
                                    .padding(.horizontal, 16)
                                    .frame(height: 54)
                                    .background(Color(red: 0.93, green: 0.96, blue: 1.0), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
                                    .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).stroke(AppTheme.accent.opacity(0.35), lineWidth: 1.2))
                                    .id("license-field")

                                Toggle("Remember key on this device", isOn: $manager.rememberKey)
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .tint(AppTheme.accent)

                                Button(action: activate) {
                                    HStack(spacing: 9) {
                                        Image(systemName: manager.isBusy ? "hourglass" : "checkmark.shield.fill")
                                        Text(manager.isBusy ? "ACTIVATING..." : "ENTER TERMINALX999")
                                    }
                                    .font(.system(size: 14, weight: .black, design: .rounded))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity, minHeight: 54)
                                    .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
                                    .shadow(color: AppTheme.accent.opacity(0.35), radius: 14, y: 6)
                                }
                                .buttonStyle(.plain)

                                if let message = manager.message {
                                    Text(message)
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundStyle(manager.isActive ? Color.green : Color.red.opacity(0.95))
                                        .multilineTextAlignment(.center)
                                        .frame(maxWidth: .infinity)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .background(AppTheme.lightBlue.opacity(0.5), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                }

                                if let contactOwner = manager.contactOwner,
                                   let contactURL = URL(string: contactOwner) {
                                    Button("Developer: TERMINALX999") {
                                        UIApplication.shared.open(contactURL)
                                    }
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppTheme.accent)
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(20)
                            .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 25, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 25, style: .continuous).stroke(AppTheme.cardBorder, lineWidth: 1.2))
                            .shadow(color: AppTheme.cardShadow, radius: 16, y: 6)
                            .padding(.horizontal, 22)
                            .padding(.top, 26)
                            .id("activation-card")

                            Spacer(minLength: 42)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 28)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onAppear {
                        if let saved = manager.rememberedKey(), !saved.isEmpty {
                            key = saved
                        }
                    }
                    .onChange(of: keyFocused) { focused in
                        guard focused else { return }
                        withAnimation(.easeOut(duration: 0.25)) { proxy.scrollTo("activation-card", anchor: .center) }
                    }
                }
            }
        }
        .preferredColorScheme(.light)
    }

    private func activate() {
        keyFocused = false
        manager.activate(key: key)
    }
}
