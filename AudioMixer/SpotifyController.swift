import Foundation
import AppKit


class SpotifyController{
    let redirectURI = "audiomixer://callback"
    let scope = "user-read-playback-state user-modify-playback-state"

    var accessToken: String? {
        return UserDefaults.standard.string(forKey: "spotify_access_token")
    }

    var isTokenValid: Bool {
        guard let timestamp = UserDefaults.standard.object(forKey:"spotify_token_timestamp") as? Date,
            let expiresIn = UserDefaults.standard.object(forKey:"spotify_token_expires_in") as? Int else
         else {
            return false
        }

        let expirationTime = timestamp.addingTimeInterval(TimeInterval(expiresIn))
        return Date() < expirationDate
    }
    
    func authorize() {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "accounts.spotify.com"
        components.path = "/authorize"
        
        components.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: Secrets.clientID),
            URLQueryItem(name: "scope", value: scope),
            URLQueryItem(name: "redirect_uri", value: redirectURI)
        ]
        
        guard let url = components.url else {
            print("Could not create URL")
            return
        }
        
        NSWorkspace.shared.open(url)
    }
    
    func getCurrentSongName() -> String? {
        var response = 
    }

    func exchangeCodeForToken(code: String) {
        guard let url = URL(string: "https://accounts.spotify.com/api/token") else {return}

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let bodyString = "grant_type=authorization_code&code=\(code)&redirect_uri=\(redirectURI)&client_id=\(Secrets.clientID)
            &client_secret=\(Secrets.clientSecret)"
        request.httpBody = bodyString.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error)")
                return
            }

            guard let data = data else {
                print("No data received")
                return
            }

            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                if let accessToken = json?["access_token"] as? String {
                    print("Access token: \(accessToken)")

                    UserDefaults.standard.set(accessToken, forKey: "spotify_access_token")

                    UserDefaults.standard.set(Date(), forKey: "spotify_token_timestamp")

                    if let refreshToken = json?["refresh_token"] as? String {
                        UserDefaults.standard.set(refreshToken, forKey: "spotify_refresh_token")
                    }

                    if let expiresIn = json?["expires_in"] as? Int {
                        UserDefaults.standard.set(expiresIn, forKey: "spotify_token_expires_in")
                    }
                }
            } catch {
                print("JSON parsing error: \(error)")
            }
        }.resume()
    }
}
