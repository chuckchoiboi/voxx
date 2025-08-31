import Foundation
import Security

class KeychainHelper {
    static let shared = KeychainHelper()
    private init() {}
    
    private let service = "com.yourapp.voxx"
    private let apiKeyAccount = "openai_api_key"
    
    // MARK: - API Key Management
    
    func storeAPIKey(_ apiKey: String) -> Bool {
        let data = apiKey.data(using: .utf8)!
        
        // First try to update existing key
        let updateQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: apiKeyAccount
        ]
        
        let updateAttributes: [String: Any] = [
            kSecValueData as String: data
        ]
        
        let updateStatus = SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary)
        
        if updateStatus == errSecSuccess {
            return true
        }
        
        // If update failed, try to add new item
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: apiKeyAccount,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        return addStatus == errSecSuccess
    }
    
    func retrieveAPIKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: apiKeyAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let apiKey = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return apiKey
    }
    
    func deleteAPIKey() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: apiKeyAccount
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    func hasAPIKey() -> Bool {
        return retrieveAPIKey() != nil
    }
    
    // MARK: - API Key Validation
    
    func isValidAPIKeyFormat(_ apiKey: String) -> Bool {
        // OpenAI API keys start with "sk-" and are typically 51 characters long
        return apiKey.hasPrefix("sk-") && apiKey.count >= 20
    }
    
    // MARK: - Security Helpers
    
    func clearAllKeychainData() -> Bool {
        let secClasses = [
            kSecClassGenericPassword,
            kSecClassInternetPassword,
            kSecClassCertificate,
            kSecClassKey,
            kSecClassIdentity
        ]
        
        var success = true
        for secClass in secClasses {
            let query: [String: Any] = [
                kSecClass as String: secClass,
                kSecAttrService as String: service
            ]
            let status = SecItemDelete(query as CFDictionary)
            if status != errSecSuccess && status != errSecItemNotFound {
                success = false
            }
        }
        return success
    }
}

// MARK: - Language Preferences Helper

class LanguagePreferences {
    static let shared = LanguagePreferences()
    private init() {}
    
    private let languageKey = "selectedTranscriptionLanguage"
    
    struct Language {
        let code: String
        let name: String
        let flag: String
        
        static let supportedLanguages = [
            Language(code: "auto", name: "Auto-detect", flag: "🌐"),
            Language(code: "en", name: "English", flag: "🇺🇸"),
            Language(code: "es", name: "Spanish", flag: "🇪🇸"),
            Language(code: "fr", name: "French", flag: "🇫🇷"),
            Language(code: "de", name: "German", flag: "🇩🇪"),
            Language(code: "it", name: "Italian", flag: "🇮🇹"),
            Language(code: "pt", name: "Portuguese", flag: "🇵🇹"),
            Language(code: "nl", name: "Dutch", flag: "🇳🇱"),
            Language(code: "pl", name: "Polish", flag: "🇵🇱"),
            Language(code: "ru", name: "Russian", flag: "🇷🇺"),
            Language(code: "ja", name: "Japanese", flag: "🇯🇵"),
            Language(code: "ko", name: "Korean", flag: "🇰🇷"),
            Language(code: "zh", name: "Chinese", flag: "🇨🇳"),
            Language(code: "hi", name: "Hindi", flag: "🇮🇳"),
            Language(code: "ar", name: "Arabic", flag: "🇸🇦"),
            Language(code: "tr", name: "Turkish", flag: "🇹🇷"),
            Language(code: "sv", name: "Swedish", flag: "🇸🇪"),
            Language(code: "da", name: "Danish", flag: "🇩🇰"),
            Language(code: "no", name: "Norwegian", flag: "🇳🇴"),
            Language(code: "fi", name: "Finnish", flag: "🇫🇮")
        ]
    }
    
    func setSelectedLanguage(_ language: Language) {
        UserDefaults.standard.set(language.code, forKey: languageKey)
    }
    
    func getSelectedLanguage() -> Language {
        let savedCode = UserDefaults.standard.string(forKey: languageKey) ?? "auto"
        return Language.supportedLanguages.first { $0.code == savedCode } ?? Language.supportedLanguages[0]
    }
    
    func getSelectedLanguageCode() -> String? {
        let selected = getSelectedLanguage()
        return selected.code == "auto" ? nil : selected.code
    }
}