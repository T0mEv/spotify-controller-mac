import Foundation

struct Secrets {
    private static var secretsDictionary: [String: Any]? {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist") else {
            fatalError("Could not find Secrets.plist file.")
        }
        return NSDictionary(contentsOfFile: path) as? [String: Any]
    }

    static var clientID: String {
        guard let value = secretsDictionary?["ClientID"] as? String else {
            fatalError("Could not find 'ClientID' in Secrets.plist.")
        }
        return value
    }

    static var clientSecret: String {
        guard let value = secretsDictionary?["ClientSecret"] as? String else {
            fatalError("Could not find 'ClientSecret' in Secrets.plist.")
        }
        return value
    }
}
