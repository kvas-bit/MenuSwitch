import Foundation
import Security

enum KeychainVault {
    static let serviceName = "MenuSwitch"

    static func save(_ value: String, service: String = serviceName, account: String) throws {
        try delete(service: service, account: account)

        guard let data = value.data(using: .utf8) else {
            throw KeychainError.invalidEncoding
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.osStatus(status) }
    }

    static func load(service: String = serviceName, account: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw KeychainError.osStatus(status) }

        guard let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(service: String = serviceName, account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(query as CFDictionary)
        if status == errSecItemNotFound { return }
        guard status == errSecSuccess else { throw KeychainError.osStatus(status) }
    }
}

enum KeychainError: LocalizedError {
    case invalidEncoding
    case osStatus(OSStatus)

    var errorDescription: String? {
        switch self {
        case .invalidEncoding:
            return "Could not encode the API key."
        case .osStatus(let status):
            return "Keychain error: \(status)"
        }
    }
}
