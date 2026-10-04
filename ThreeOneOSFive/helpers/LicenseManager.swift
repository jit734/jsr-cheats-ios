import Combine
import Foundation
import Security
import UIKit

// MARK: - JSR CHEATS LicenseManager
// Standalone Authentication & Key Management

@MainActor
final class LicenseManager: ObservableObject {

    @Published private(set) var expirationDate: Date? = nil
    @Published private(set) var isActive  = true
    @Published private(set) var isBusy    = false
    @Published private(set) var message: String? = "JSR CHEATS Activated"
    @Published private(set) var contactOwner: String? = "https://github.com/ROHANX999"
    @Published var rememberKey = true

    private let service          = "com.jsrcheats.activation"
    private let keyAccount       = "license-key"
    private let activatedAccount = "license-activated"

    init() {
        let key = string(for: keyAccount) ?? UserDefaults.standard.string(forKey: "jsrcheats_key") ?? "JSRCHEATS-VIP"
        save(key, for: keyAccount)
        save("true", for: activatedAccount)
        UserDefaults.standard.set(key, forKey: "jsrcheats_key")
        UserDefaults.standard.set(true, forKey: "jsrcheats_activated")
        isActive = true
    }

    var hasRememberedKey: Bool {
        true
    }

    func formattedExpirationDate() -> String {
        "Lifetime License"
    }

    func formattedTimeRemaining(currentDate: Date = Date()) -> String {
        "Unlimited / Lifetime"
    }

    func beginLaunchSession() {
        isActive = true
        message = "JSR CHEATS Active"
        isBusy = false
    }

    func activate(key: String) {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines).filter { !$0.isNewline }
        let effectiveKey = trimmed.isEmpty ? "TERMINALX999-KEY" : trimmed

        isBusy = true
        message = "Activating TERMINALX999..."

        Task {
            try? await Task.sleep(nanoseconds: 200_000_000)
            self.isActive = true
            self.message = "TERMINALX999 Activated Successfully!"
            self.persistActivation(key: effectiveKey)
            self.isBusy = false
        }
    }

    private func persistActivation(key: String) {
        if rememberKey {
            save(key, for: keyAccount)
            save("true", for: activatedAccount)
            UserDefaults.standard.set(key, forKey: "terminalx999_key")
            UserDefaults.standard.set(true, forKey: "terminalx999_activated")
        }
    }

    func rememberedKey() -> String? {
        string(for: keyAccount) ?? UserDefaults.standard.string(forKey: "terminalx999_key") ?? "TERMINALX999-VIP"
    }

    func refresh() {
        isActive = true
        message = "TERMINALX999 Status: Active"
    }

    func deactivate() {
        delete(keyAccount)
        delete(activatedAccount)
        UserDefaults.standard.removeObject(forKey: "terminalx999_key")
        UserDefaults.standard.set(false, forKey: "terminalx999_activated")
        isActive = false
        message = "License reset. Enter any key to reactivate."
    }

    // MARK: - Keychain Storage

    private func string(for account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String:  true,
            kSecMatchLimit as String:  kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func save(_ value: String, for account: String) {
        let base: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(base as CFDictionary)
        var item = base
        item[kSecValueData as String]     = Data(value.utf8)
        item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(item as CFDictionary, nil)
    }

    private func delete(_ account: String) {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
