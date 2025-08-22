import Foundation

struct Secrets {
    private static var secretsDictionary: [String: Any] = {
        if let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
           let data = try? Data(contentsOf: url),
           let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] {
            return dict
        }
        print("DEBUG: Secrets.plist not found or unreadable in bundle: \(Bundle.main.bundleURL)")
        return [:]
    }()

    static var clientID: String {
        guard let value = secretsDictionary["ClientID"] as? String, !value.isEmpty else {
            print("DEBUG: Missing ClientID in Secrets.plist")
            return ""
        }
        return value
    }

    static var clientSecret: String {
        guard let value = secretsDictionary["ClientSecret"] as? String, !value.isEmpty else {
            print("DEBUG: Missing ClientSecret in Secrets.plist")
            return ""
        }
        return value
    }
}
