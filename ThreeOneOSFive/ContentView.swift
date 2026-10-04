import SwiftUI
import UIKit
import AVFoundation

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var licenseManager: LicenseManager
    @State private var showSettings = false
    @State private var showCleaner = false
    @StateObject private var patchStore = PatchProjectStore()
    @State private var patchOperationBusy = false
    @State private var patchMessage = "READY — SELECT A PATCH"
    @State private var selectedGame: GameMode = .normal
    @State private var now = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    // FF Normal states
    @State private var normAimDragEnabled = false
    @State private var normAimBodyEnabled = false
    @State private var normMagicEnabled = false
    @State private var normCryptoricAimEnabled = false
    @State private var normModMenuEnabled = false
    @State private var normAimChetsHsEnabled = false
    @State private var normAimNheTamEnabled = false
    // FF MAX states
    @State private var maxAimEspEnabled = false
    @State private var maxCryptoricAimEnabled = false
    @State private var maxModMenuEnabled = false
    @State private var maxAimBodyHsEnabled = false
    @State private var maxAimChetsHsEnabled = false
    @State private var maxAimMagic360Enabled = false
    @State private var maxAimNeckHsEnabled = false
    @State private var maxAimNheTamEnabled = false

    private enum GameMode: String, CaseIterable {
        case normal = "FF NORMAL"
        case max    = "FF MAX"
        var launchScheme: String { self == .normal ? "freefireth" : "freefiremax" }
        var patchPrefix: String { "TERMINAL" }
    }

    var body: some View {
        ZStack {
            AnimatedHyperBackdrop()
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    brandHeader
                    devicePanel
                    patchOptions
                    gameLaunchPanel
                    footerStatus
                    developerCredits
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 32)
            }
        }
        .preferredColorScheme(.light)
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showCleaner) {
            CleanerView()
        }

        .onAppear { syncPatchStates() }
        .onReceive(timer) { input in self.now = input }
        .onChange(of: scenePhase) { phase in
            guard phase == .active, !patchOperationBusy else { return }
            syncPatchStates()
            patchMessage = "READY — SELECT A PATCH"
        }
    }

    // MARK: - Header
    private var brandHeader: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("JSR CHEATS")
                    .font(.system(size: 26, weight: .bold, design: .default))
                    .tracking(1.2)
                    .foregroundStyle(AppTheme.textPrimary)
                Text("PATCH CONTROL CENTER")
                    .font(.system(size: 10, weight: .semibold, design: .default))
                    .tracking(2.0)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()

            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .frame(width: 48, height: 48)
                    .claymorphicCircle(depth: 6)
            }
            .claymorphicButtonPress()
            .accessibilityLabel("Open settings")
        }
    }

    // MARK: - Device Status Wide Card
    private var devicePanel: some View {
        VStack(spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("DEVICE STATUS")
                    .font(.system(size: 11, weight: .bold, design: .default))
                    .tracking(1.4)
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                HStack(spacing: 5) {
                    Circle()
                        .fill(appState.isSupported ? AppTheme.activeGreen : Color.red)
                        .frame(width: 6, height: 6)
                    Text(appState.isSupported ? "VERIFIED" : "UNVERIFIED")
                        .font(.system(size: 9, weight: .bold, design: .default))
                        .foregroundStyle(appState.isSupported ? AppTheme.activeGreen : Color.red)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .claymorphicCapsuleDepression()
            }

            VStack(spacing: 9) {
                deviceDetailRow(label: "iOS", value: AppInfo.osVersion, icon: "apple.logo")
                deviceDetailRow(label: "Device", value: AppInfo.displayMachineName, icon: "iphone")
                deviceDetailRow(
                    label: "Support",
                    value: appState.isSupported ? "SUPPORTED" : "UNSUPPORTED",
                    icon: "checkmark.seal.fill",
                    valueColor: appState.isSupported ? AppTheme.activeGreen : Color.red
                )
                deviceDetailRow(
                    label: "License Key",
                    value: licenseManager.isActive ? licenseManager.formattedTimeRemaining(currentDate: now) : "NOT ACTIVATED",
                    icon: "key.fill",
                    valueColor: licenseManager.isActive ? AppTheme.activeGreen : Color.red
                )
            }
        }
        .padding(18)
        .claymorphicCard(cornerRadius: 28, depth: 8)
    }

    private func deviceDetailRow(label: String, value: String, icon: String, valueColor: Color = AppTheme.textPrimary) -> some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(AppTheme.depressedBackground)
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .frame(width: 28, height: 28)

            Text(label)
                .font(.system(size: 13, weight: .medium, design: .default))
                .foregroundStyle(AppTheme.textSecondary)

            Spacer()

            Text(value)
                .font(.system(size: 13, weight: .bold, design: .default))
                .foregroundStyle(valueColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .claymorphicDepression(cornerRadius: 14)
    }

    // MARK: - Patch Options Section
    private var patchOptions: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 7) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("PATCH OPTIONS")
                        .font(.system(size: 11, weight: .bold, design: .default))
                        .tracking(1.4)
                        .foregroundStyle(AppTheme.textPrimary)
                }
                Spacer()
                Text("SELECT TO TOGGLE")
                    .font(.system(size: 9, weight: .semibold, design: .default))
                    .tracking(0.8)
                    .foregroundStyle(AppTheme.textMuted)
            }

            // Game mode switcher
            gameModeSwitcher

            // Grid of rounded feature cards
            if selectedGame == .normal {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                    patchCard(name: "Aim Drag", target: "FREE FIRE • NORMAL", package: "DRAGM.3105", icon: "scope", state: $normAimDragEnabled)
                    patchCard(name: "Aim Body", target: "FREE FIRE • NORMAL", package: "AIM BODY.3105", icon: "person.fill.viewfinder", state: $normAimBodyEnabled)
                    patchCard(name: "Magic Bullet", target: "FREE FIRE • NORMAL", package: "MAGICM.3105", icon: "wand.and.stars", state: $normMagicEnabled)
                    patchCard(name: "TERMINAL Aim", target: "FREE FIRE • NORMAL", package: "Cryptoric Aim.3105", icon: "scope", state: $normCryptoricAimEnabled)
                    patchCard(name: "Mode Menu", target: "FREE FIRE • NORMAL", package: "MODE MENU.3105", icon: "slider.horizontal.3", state: $normModMenuEnabled)
                    patchCard(name: "Aim Chets HS", target: "FREE FIRE • NORMAL", package: "AIM CHETS HS FFTH.3105", icon: "scope", state: $normAimChetsHsEnabled)
                    patchCard(name: "Aim NheTam", target: "FREE FIRE • NORMAL", package: "AIM NHE TAM FFTH.3105", icon: "viewfinder", state: $normAimNheTamEnabled)
                    lockedPatchCard(name: "3D Weapons", target: "FREE FIRE • NORMAL", icon: "cube.transparent")
                }
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                    patchCard(name: "TERMINAL VIP", target: "FREE FIRE • MAX", package: "AIM+Ashok.3105", icon: "eye.trianglebadge.exclamationmark", state: $maxAimEspEnabled, activeColor: AppTheme.espRed)
                    patchCard(name: "TERMINAL Aim", target: "FREE FIRE • MAX", package: "Cryptoric Aim.3105", icon: "scope", state: $maxCryptoricAimEnabled)
                    patchCard(name: "Mode Menu", target: "FREE FIRE • MAX", package: "MODE MENU FFM.3105", icon: "slider.horizontal.3", state: $maxModMenuEnabled)
                    patchCard(name: "Aim Body HS", target: "FREE FIRE • MAX", package: "AIM BODY HS FFMAX.3105", icon: "person.fill.viewfinder", state: $maxAimBodyHsEnabled)
                    patchCard(name: "Aim Chets HS", target: "FREE FIRE • MAX", package: "AIM CHETS HS FFMAX.3105", icon: "scope", state: $maxAimChetsHsEnabled)
                    patchCard(name: "Aim Magic 360", target: "FREE FIRE • MAX", package: "AIM MAGIC 360- FFMAX.3105", icon: "wand.and.stars", state: $maxAimMagic360Enabled)
                    patchCard(name: "Aim Neck HS", target: "FREE FIRE • MAX", package: "AIM NECK HS FFMAX.3105", icon: "scope", state: $maxAimNeckHsEnabled)
                    patchCard(name: "Aim NheTam", target: "FREE FIRE • MAX", package: "AIM NHE TAM FFMAX.3105", icon: "viewfinder", state: $maxAimNheTamEnabled)
                    lockedPatchCard(name: "3D Weapons", target: "FREE FIRE • MAX", icon: "cube.transparent")
                }
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }

            // Message bar
            patchMessageBar
        }
    }

    private var gameModeSwitcher: some View {
        HStack(spacing: 0) {
            ForEach(GameMode.allCases, id: \.rawValue) { mode in
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.76)) {
                        selectedGame = mode
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: mode == .normal ? "gamecontroller.fill" : "bolt.shield.fill")
                            .font(.system(size: 12, weight: .bold))
                        Text(mode.rawValue)
                            .font(.system(size: 11, weight: .bold, design: .default))
                            .tracking(1)
                    }
                    .foregroundStyle(selectedGame == mode ? AppTheme.textPrimary : AppTheme.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: 38)
                    .background(
                        Group {
                            if selectedGame == mode {
                                RoundedRectangle(cornerRadius: 13, style: .continuous)
                                    .fill(AppTheme.cardBackground)
                                    .shadow(color: AppTheme.clayDarkShadow, radius: 5, x: 2.5, y: 3.5)
                                    .shadow(color: AppTheme.clayLightShadow, radius: 5, x: -2.5, y: -2.5)
                            } else {
                                Color.clear
                            }
                        }
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .claymorphicDepression(cornerRadius: 17)
    }

    private func patchCard(name: String, target: String, package: String, icon: String, state: Binding<Bool>, activeColor: Color = AppTheme.activeGreen) -> some View {
        PatchOptionCard(name: name, target: target, iconName: icon, isEnabled: state, isBusy: patchOperationBusy, isLocked: false, activeColor: activeColor) {
            togglePatch(packageFilename: package, state: state)
        }
    }

    private func lockedPatchCard(name: String, target: String, icon: String) -> some View {
        PatchOptionCard(name: name, target: target, iconName: icon, isEnabled: .constant(false), isBusy: false, isLocked: true) {
            patchMessage = "\(name) — IN DEVELOPMENT FOR NEXT UPDATE"
        }
    }

    private var patchMessageBar: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(patchMessage.localizedCaseInsensitiveContains("successful") ? AppTheme.activeGreen : AppTheme.textSecondary)
                .frame(width: 8, height: 8)

            Text(patchOperationBusy ? "PROCESSING PATCH…" : patchMessage)
                .font(.system(size: 11, weight: .bold, design: .default))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .claymorphicDepression(cornerRadius: 20)
    }

    // MARK: - Game Launch Panel
    private var gameLaunchPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.up.forward.app.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("LAUNCH GAME")
                    .font(.system(size: 11, weight: .bold, design: .default))
                    .tracking(1.4)
                    .foregroundStyle(AppTheme.textPrimary)
            }

            HStack(spacing: 12) {
                clayLaunchButton(title: "FF NORMAL", subtitle: "Free Fire Normal", icon: "gamecontroller.fill", scheme: "freefireth")
                clayLaunchButton(title: "FF MAX", subtitle: "Free Fire MAX", icon: "bolt.shield.fill", scheme: "freefiremax")
            }

            Button {
                showCleaner = true
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(AppTheme.depressedBackground)
                        Image(systemName: "trash.slash.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                    .frame(width: 32, height: 32)

                    Text("Clean Cache & Temporary Files")
                        .font(.system(size: 12, weight: .bold, design: .default))
                        .foregroundStyle(AppTheme.textPrimary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, minHeight: 52)
                .claymorphicCard(cornerRadius: 20, depth: 6)
            }
            .claymorphicButtonPress()
            .accessibilityLabel("Open cache and temporary files cleaner")
        }
    }

    private func clayLaunchButton(title: String, subtitle: String, icon: String, scheme: String) -> some View {
        Button { openGame(scheme: scheme) } label: {
            VStack(alignment: .leading, spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(AppTheme.depressedBackground)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)
                }
                .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .bold, design: .default))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 10, weight: .medium, design: .default))
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 90, alignment: .leading)
            .padding(14)
            .claymorphicCard(cornerRadius: 22, depth: 7)
        }
        .claymorphicButtonPress()
    }

    // MARK: - Footer Status & Credits
    private var footerStatus: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(AppTheme.activeGreen)
                .frame(width: 8, height: 8)
            Text("SISTEMA PRONTO")
                .font(.system(size: 10, weight: .bold, design: .default))
                .tracking(1.4)
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()
            Text("TERMINALX999 • READY")
                .font(.system(size: 10, weight: .bold, design: .default))
                .tracking(1.0)
                .foregroundStyle(AppTheme.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .claymorphicCapsuleDepression()
    }

    private var developerCredits: some View {
        VStack(spacing: 10) {
            Text("Developed by TERMINALX999")
                .font(.system(size: 11, weight: .semibold, design: .default))
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)

            // Made by TERMINALX999 badge
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("Made by TERMINALX999")
                    .font(.system(size: 11, weight: .bold, design: .default))
                    .tracking(1.2)
                    .foregroundStyle(AppTheme.textPrimary)
                Image(systemName: "star.fill")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(AppTheme.textPrimary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .claymorphicCapsuleDepression()

            Button {
                guard let destination = URL(string: "https://github.com/ROHANX999/IOS-IPA") else { return }
                UIApplication.shared.open(destination)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                        .font(.system(size: 12, weight: .bold))
                    Text("TERMINALX999 Official")
                        .font(.system(size: 11, weight: .bold, design: .default))
                }
                .foregroundStyle(AppTheme.textPrimary)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .claymorphicCard(cornerRadius: 18, depth: 5)
            }
            .claymorphicButtonPress()
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
        .padding(.bottom, 8)
    }

    // MARK: - Logic & Patch Handlers
    private func syncPatchStates() {
        let items = patchStore.items
        DispatchQueue.global(qos: .userInitiated).async {
            let f_aimDrag = self.isPatchActive("DRAGM.3105", forGame: .normal)
            let f_aimBody = self.isPatchActive("AIM BODY.3105", forGame: .normal)
            let f_magic   = self.isPatchActive("MAGICM.3105", forGame: .normal)
            let f_crypt   = self.isPatchActive("Cryptoric Aim.3105", forGame: .normal)
            let f_mod     = self.isPatchActive("MODE MENU.3105", forGame: .normal)
            let f_aimChetsHs = self.isPatchActive("AIM CHETS HS FFTH.3105", forGame: .normal)
            let f_aimNheTam  = self.isPatchActive("AIM NHE TAM FFTH.3105", forGame: .normal)

            let m_aimAshok   = self.isPatchActive("AIM+Ashok.3105", forGame: .max) || self.isPatchActive("AIM+ESP.3105", forGame: .max)
            let m_crypt      = self.isPatchActive("Cryptoric Aim.3105", forGame: .max)
            let m_mod        = self.isPatchActive("MODE MENU FFM.3105", forGame: .max)
            let m_aimBodyHs  = self.isPatchActive("AIM BODY HS FFMAX.3105", forGame: .max)
            let m_aimChetsHs = self.isPatchActive("AIM CHETS HS FFMAX.3105", forGame: .max)
            let m_aimMagic360 = self.isPatchActive("AIM MAGIC 360- FFMAX.3105", forGame: .max)
            let m_aimNeckHs  = self.isPatchActive("AIM NECK HS FFMAX.3105", forGame: .max)
            let m_aimNheTam  = self.isPatchActive("AIM NHE TAM FFMAX.3105", forGame: .max)

            DispatchQueue.main.async {
                self.normAimDragEnabled = f_aimDrag
                self.normAimBodyEnabled = f_aimBody
                self.normMagicEnabled   = f_magic
                self.normCryptoricAimEnabled = f_crypt
                self.normModMenuEnabled = f_mod
                self.normAimChetsHsEnabled = f_aimChetsHs
                self.normAimNheTamEnabled  = f_aimNheTam

                self.maxAimEspEnabled      = m_aimAshok
                self.maxCryptoricAimEnabled = m_crypt
                self.maxModMenuEnabled     = m_mod
                self.maxAimBodyHsEnabled   = m_aimBodyHs
                self.maxAimChetsHsEnabled  = m_aimChetsHs
                self.maxAimMagic360Enabled = m_aimMagic360
                self.maxAimNeckHsEnabled   = m_aimNeckHs
                self.maxAimNheTamEnabled   = m_aimNheTam
            }
        }
    }

    private func findPatchItem(for packageFilename: String) -> PatchLibraryItem? {
        if let found = findPatchItem(in: patchStore.items, filename: packageFilename) {
            return found
        }

        // Fallback: construct directly from embedded Base64 so it can NEVER fail
        let clean = packageFilename
            .replacingOccurrences(of: ".3105", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: ".cryptoric", with: "", options: .caseInsensitive)
            .lowercased()

        let targetFilename: String
        let b64: String
        if clean.contains("aim body hs") {
            targetFilename = "AIM BODY HS FFMAX.3105"
            b64 = PatchProjectLibrary.embeddedAimBodyHsFFMaxBase64
        } else if clean.contains("aim chets hs ffmax") {
            targetFilename = "AIM CHETS HS FFMAX.3105"
            b64 = PatchProjectLibrary.embeddedAimChetsHsFFMaxBase64
        } else if clean.contains("magic 360") {
            targetFilename = "AIM MAGIC 360- FFMAX.3105"
            b64 = PatchProjectLibrary.embeddedAimMagic360FFMaxBase64
        } else if clean.contains("aim neck hs") {
            targetFilename = "AIM NECK HS FFMAX.3105"
            b64 = PatchProjectLibrary.embeddedAimNeckHsFFMaxBase64
        } else if clean.contains("aim nhe tam ffmax") {
            targetFilename = "AIM NHE TAM FFMAX.3105"
            b64 = PatchProjectLibrary.embeddedAimNheTamFFMaxBase64
        } else if clean.contains("aim chets hs ffth") {
            targetFilename = "AIM CHETS HS FFTH.3105"
            b64 = PatchProjectLibrary.embeddedAimChetsHsFFNormBase64
        } else if clean.contains("aim nhe tam ffth") {
            targetFilename = "AIM NHE TAM FFTH.3105"
            b64 = PatchProjectLibrary.embeddedAimNheTamFFNormBase64
        } else if clean.contains("drag") {
            targetFilename = "DRAGM.3105"
            b64 = PatchProjectLibrary.embeddedDragMBase64
        } else if clean.contains("body") || clean.contains("obb") {
            targetFilename = "AIM BODY.3105"
            b64 = PatchProjectLibrary.embeddedAimBodyBase64
        } else if clean.contains("magic") {
            targetFilename = "MAGICM.3105"
            b64 = PatchProjectLibrary.embeddedMagicMBase64
        } else if clean.contains("cryptoric") {
            targetFilename = "Cryptoric Aim.3105"
            b64 = PatchProjectLibrary.embeddedCryptoricAimBase64
        } else if clean.contains("ffm") && (clean.contains("mode") || clean.contains("mod")) {
            targetFilename = "MODE MENU FFM.3105"
            b64 = PatchProjectLibrary.embeddedModeMenuFFMBase64
        } else if clean.contains("mode") || clean.contains("mod") {
            targetFilename = "MODE MENU.3105"
            b64 = PatchProjectLibrary.embeddedModeMenuBase64
        } else {
            targetFilename = "AIM+Ashok.3105"
            b64 = PatchProjectLibrary.embeddedAimAshokBase64
        }

        if let root = try? PatchProjectLibrary.packageRootURL() {
            let fileURL = root.appendingPathComponent(targetFilename)
            if let data = (try? Data(contentsOf: fileURL)) ?? Data(base64Encoded: b64) {
                if let summary = try? PatchPackageCodec.inspect(data) {
                    let decoded = try? PatchPackageCodec.decode(data, password: nil)
                    return PatchLibraryItem(
                        summary: summary,
                        project: decoded?.project ?? PatchProjectLibrary.getDecodedProject(for: packageFilename),
                        contentKey: decoded?.contentKey,
                        packageURL: fileURL
                    )
                }
            }
        }
        return nil
    }

    private func findPatchItem(in items: [PatchLibraryItem], filename: String) -> PatchLibraryItem? {
        let cleanTarget = filename
            .replacingOccurrences(of: ".3105", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: ".cryptoric", with: "", options: .caseInsensitive)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        // 1. Guaranteed Fixed UUID matching
        if cleanTarget.contains("drag") || cleanTarget == "dragm" {
            let targetUUID = UUID(uuidString: "943B9588-B8AF-4DE3-AE97-796787FEAD5C")
            if let found = items.first(where: { $0.id == targetUUID }) {
                return found
            }
        }
        if cleanTarget.contains("body") || cleanTarget == "aim body" || cleanTarget == "obb" {
            let targetUUID = UUID(uuidString: "68FA1E77-AA88-42FE-86D2-1E6D07700F09")
            if let found = items.first(where: { $0.id == targetUUID }) {
                return found
            }
        }
        if cleanTarget.contains("magic") || cleanTarget == "magicm" {
            let targetUUID = UUID(uuidString: "81730787-037F-4603-AB87-32668C8BB188")
            if let found = items.first(where: { $0.id == targetUUID }) {
                return found
            }
        }
        if cleanTarget.contains("ashok") || cleanTarget.contains("esp") || cleanTarget == "aim+ashok" || cleanTarget == "aim+esp" || cleanTarget.contains("cryptoric ashok") || cleanTarget.contains("cryptoric esp") {
            let targetUUID = UUID(uuidString: "F0BEBA88-5C95-4F4C-B804-E825290ADF13")
            if let found = items.first(where: { $0.id == targetUUID }) {
                return found
            }
        }
        if cleanTarget.contains("cryptoric aim") || cleanTarget.contains("cryptoric") {
            let targetUUID = UUID(uuidString: "C60517A3-DBCE-4C28-829F-9E4B9C6D0FC1")
            if let found = items.first(where: { $0.id == targetUUID }) {
                return found
            }
        }
        if cleanTarget.contains("ffm") && (cleanTarget.contains("mode") || cleanTarget.contains("mod")) {
            let targetUUID = UUID(uuidString: "50F75F5F-E17F-4F24-8721-0870E7304A95")
            if let found = items.first(where: { $0.id == targetUUID }) {
                return found
            }
        }
        if cleanTarget.contains("mode menu") || cleanTarget.contains("mod menu") || cleanTarget == "mode menu" {
            let targetUUID = UUID(uuidString: "40F75F5F-E17F-4F24-8721-0870E7304A94")
            if let found = items.first(where: { $0.id == targetUUID }) {
                return found
            }
        }

        // 2. Direct exact filename match
        if let found = items.first(where: {
            $0.packageURL.lastPathComponent.caseInsensitiveCompare(filename) == .orderedSame
        }) {
            return found
        }

        // 3. Direct clean name or display name or project name match
        if let found = items.first(where: {
            let itemFilename = $0.packageURL.deletingPathExtension().lastPathComponent.lowercased()
            let itemDisplay = $0.displayName.lowercased()
            let itemProject = $0.project?.name.lowercased() ?? ""
            return itemFilename == cleanTarget
                || itemDisplay == cleanTarget
                || itemProject == cleanTarget
        }) {
            return found
        }

        // 4. Fuzzy fallback
        if let found = items.first(where: {
            let itemFilename = $0.packageURL.deletingPathExtension().lastPathComponent.lowercased()
            let itemDisplay = $0.displayName.lowercased()
            return itemFilename.contains(cleanTarget) || cleanTarget.contains(itemFilename)
                || itemDisplay.contains(cleanTarget) || cleanTarget.contains(itemDisplay)
        }) {
            return found
        }

        return nil
    }

    private func isPatchActive(_ packageFilename: String, forGame game: GameMode? = nil) -> Bool {
        let mode = game ?? selectedGame
        let gameKey = "patch_active_\(mode.rawValue)_" + packageFilename
        let genericKey = "patch_active_" + packageFilename
        let prefActive = UserDefaults.standard.bool(forKey: gameKey) || (game == nil && UserDefaults.standard.bool(forKey: genericKey))
        guard let item = findPatchItem(for: packageFilename) else {
            return prefActive
        }
        let receiptActive = DevicePatchService.latestReceipt(projectID: item.id) != nil
        return prefActive && receiptActive
    }

    private enum PatchActionResult {
        case applied
        case restored
        case unavailable(String)
    }

    private func setPatchState(for packageFilename: String, game: GameMode, enabled: Bool) {
        let lower = packageFilename.lowercased()
        let gameKey = "patch_active_\(game.rawValue)_" + packageFilename
        UserDefaults.standard.set(enabled, forKey: gameKey)
        UserDefaults.standard.set(enabled, forKey: "patch_active_" + packageFilename)

        if packageFilename == "AIM BODY HS FFMAX.3105" || lower.contains("aim body hs") {
            maxAimBodyHsEnabled = enabled
        } else if packageFilename == "AIM CHETS HS FFMAX.3105" || lower.contains("aim chets hs ffmax") {
            maxAimChetsHsEnabled = enabled
        } else if packageFilename == "AIM MAGIC 360- FFMAX.3105" || lower.contains("magic 360") {
            maxAimMagic360Enabled = enabled
        } else if packageFilename == "AIM NECK HS FFMAX.3105" || lower.contains("aim neck hs") {
            maxAimNeckHsEnabled = enabled
        } else if packageFilename == "AIM NHE TAM FFMAX.3105" || lower.contains("aim nhe tam ffmax") {
            maxAimNheTamEnabled = enabled
        } else if packageFilename == "AIM CHETS HS FFTH.3105" || lower.contains("aim chets hs ffth") {
            normAimChetsHsEnabled = enabled
        } else if packageFilename == "AIM NHE TAM FFTH.3105" || lower.contains("aim nhe tam ffth") {
            normAimNheTamEnabled = enabled
        } else if lower.contains("drag") {
            normAimDragEnabled = enabled
        } else if lower.contains("body") || lower.contains("obb") {
            normAimBodyEnabled = enabled
        } else if lower.contains("magic") {
            normMagicEnabled = enabled
        } else if lower.contains("ashok") || lower.contains("esp") {
            maxAimEspEnabled = enabled
        } else if lower.contains("ffm") && (lower.contains("mode") || lower.contains("mod")) {
            maxModMenuEnabled = enabled
        } else if lower.contains("mode") || lower.contains("mod") {
            if game == .normal {
                normModMenuEnabled = enabled
            } else {
                maxModMenuEnabled = enabled
            }
        } else if lower.contains("cryptoric") {
            if game == .normal {
                normCryptoricAimEnabled = enabled
            } else {
                maxCryptoricAimEnabled = enabled
            }
        }
    }

    private func togglePatch(packageFilename: String, state: Binding<Bool>) {
        guard !patchOperationBusy else { return }
        patchOperationBusy = true
        patchMessage = "PROCESSING..."

        let wasEnabled = state.wrappedValue
        let currentGame = self.selectedGame

        DispatchQueue.global(qos: .userInitiated).async {
            // 1. Resolve library item with auto-recovery
            var resolvedItem = self.findPatchItem(for: packageFilename)
            if resolvedItem == nil {
                PatchProjectLibrary.ensureEmbeddedPatchesInstalled()
                DispatchQueue.main.sync {
                    self.patchStore.reload()
                }
                resolvedItem = self.findPatchItem(for: packageFilename)
            }

            // 2. Resolve project (with direct embedded fallback so it NEVER fails)
            var activeProject = resolvedItem?.project
            if activeProject == nil {
                activeProject = PatchProjectLibrary.getDecodedProject(for: packageFilename)
            }

            guard let projectID = resolvedItem?.id ?? activeProject?.id else {
                DispatchQueue.main.async {
                    self.patchMessage = "ERROR — PACKAGE NOT FOUND"
                    self.patchOperationBusy = false
                }
                return
            }

            let result: PatchActionResult
            do {
                if wasEnabled {
                    // Turn OFF
                    try DevicePatchService.restoreAll(projectID: projectID)
                    result = .restored
                } else {
                    // Turn ON
                    guard let validProject = activeProject else {
                        DispatchQueue.main.async {
                            self.patchMessage = "ERROR — UNABLE TO DECODE PACKAGE"
                            self.patchOperationBusy = false
                        }
                        return
                    }

                    let isMax = currentGame == .max || packageFilename.contains("Ashok") || packageFilename.contains("ESP") || packageFilename.contains("FFM") || packageFilename.contains("FFMAX")
                    let targetBundle = isMax ? "com.dts.freefiremax" : "com.dts.freefireth"
                    _ = try DevicePatchService.apply(project: validProject, targetBundleID: targetBundle)
                    result = .applied
                }
            } catch {
                // A failed restore must stay visible as a failure: the toggle
                // keeps its ON state so the user can retry instead of the app
                // claiming "Restore Successful" while patched files remain.
                result = .unavailable("FAILED — \(error.localizedDescription)")
            }

            DispatchQueue.main.async {
                switch result {
                case .applied:
                    self.setPatchState(for: packageFilename, game: currentGame, enabled: true)
                    self.patchMessage = "Inject Successful — \(packageFilename)"
                    PatchAudioFeedback.bypassActivated()
                case .restored:
                    self.setPatchState(for: packageFilename, game: currentGame, enabled: false)
                    self.patchMessage = "Restore Successful — \(packageFilename)"
                    PatchAudioFeedback.originalRestored()
                case .unavailable(let message):
                    self.patchMessage = message
                }
                self.patchOperationBusy = false
                self.syncPatchStates()
            }
        }
    }

    private func openGame(scheme: String) {
        guard let url = URL(string: "\(scheme)://") else { return }
        UIApplication.shared.open(url, options: [:]) { success in
            log("launch: \(scheme) success=\(success)")
        }
    }
}

// MARK: - Claymorphic Feature Option Card
private struct PatchOptionCard: View {
    let name: String
    let target: String
    let iconName: String
    @Binding var isEnabled: Bool
    let isBusy: Bool
    let isLocked: Bool
    var activeColor: Color = AppTheme.activeGreen
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(isEnabled ? activeColor.opacity(0.18) : AppTheme.cardBackground)

                        Image(systemName: iconName)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(isEnabled ? activeColor : AppTheme.textPrimary)
                    }
                    .frame(width: 38, height: 38)
                    .claymorphicCard(cornerRadius: 14, depth: isEnabled ? 2 : 4)

                    Spacer()

                    // Toggle pill
                    ZStack(alignment: isEnabled ? .trailing : .leading) {
                        Capsule()
                            .fill(isEnabled ? activeColor : AppTheme.depressedBackground)
                            .frame(width: 44, height: 24)

                        Circle()
                            .fill(Color.white)
                            .frame(width: 18, height: 18)
                            .padding(.horizontal, 3)
                            .shadow(color: Color.black.opacity(0.18), radius: 2, x: 0, y: 1.5)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(name)
                        .font(.system(size: 14, weight: .bold, design: .default))
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(1)

                    Text(target)
                        .font(.system(size: 9, weight: .semibold, design: .default))
                        .tracking(0.6)
                        .foregroundStyle(isEnabled ? activeColor : AppTheme.textSecondary)
                        .lineLimit(1)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(AppTheme.cardBackground)
            )
            .claymorphicCard(cornerRadius: 22, depth: isEnabled ? 3 : 6)
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(isEnabled ? activeColor.opacity(0.55) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .disabled(isBusy || isLocked)
        .opacity(isLocked ? 0.45 : 1.0)
    }
}
