import Foundation
import AppKit

struct CurrentlyPlaying: Codable {
    let isPlaying: Bool
    let progressMs: Int?
    let item: Track?

    private enum CodingKeys: String, CodingKey {
        case isPlaying = "is_playing"
        case progressMs = "progress_ms"
        case item
    }
}

struct Track: Codable {
    let id: String
    let name: String
    let artists: [Artist]
    let album: Album
    let durationMs: Int

    private enum CodingKeys: String, CodingKey {
        case id, name, artists, album
        case durationMs = "duration_ms"
    }
}

struct Artist: Codable {
    let name: String
}

struct Album: Codable {
    let name: String
    let images: [AlbumImage]
}

struct AlbumImage: Codable {
    let url: String
    let width: Int
    let height: Int
}


class SpotifyController: ObservableObject{
    let redirectURI = "audiomixer://callback"
    let scope = "user-read-playback-state user-modify-playback-state"
    
    @Published var tokenValidationTrigger = false
    @Published var isPlayingNow: Bool = false
    @Published var nowPlaying: Track?
    @Published var currentProgressMs: Int?

    var accessToken: String? {
        return UserDefaults.standard.string(forKey: "spotify_access_token")
    }

    var isTokenValid: Bool {
        let timestamp = UserDefaults.standard.object(forKey:"spotify_token_timestamp") as? Date
        let expiresIn = UserDefaults.standard.object(forKey:"spotify_token_expires_in") as? Int
        let token = UserDefaults.standard.string(forKey: "spotify_access_token")
        
        print("Debug - Token: \(token != nil ? "exists" : "missing")")
        print("Debug - Timestamp: \(timestamp != nil ? "exists" : "missing")")
        print("Debug - ExpiresIn: \(expiresIn != nil ? "exists" : "missing")")
        
        guard let timestamp = timestamp, let expiresIn = expiresIn else {
            print("Debug - Token validation failed: missing timestamp or expiresIn")
            return false
        }

        let expirationTime = timestamp.addingTimeInterval(TimeInterval(expiresIn))
        let isValid = Date() < expirationTime
        print("Date: \(Date())")
        print("Expiration Time: \(expirationTime)")
        print("Debug - Token valid: \(isValid)")
        
        return isValid
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

    func exchangeCodeForToken(code: String) {
        guard let url = URL(string: "https://accounts.spotify.com/api/token") else {return}

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let bodyString = "grant_type=authorization_code&code=\(code)&redirect_uri=\(redirectURI)&client_id=\(Secrets.clientID)&client_secret=\(Secrets.clientSecret)"
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
                        print("Expires in \(expiresIn)")
                    } else {
                        print("expires in not set")
                    }
                    
                    // Trigger UI update on main queue
                    DispatchQueue.main.async {
                        self.tokenValidationTrigger.toggle()
                    }
                }
            } catch {
                print("JSON parsing error: \(error)")
            }
        }.resume()
    }

    func refreshAccessToken() {
        guard let refreshToken = UserDefaults.standard.string(forKey: "spotify_refresh_token") else {
            print("No refresh token available - need to re-authorize")
            return
        }

        guard let url = URL(string: "https://accounts.spotify.com/api/token") else {return}

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let bodyString = "grant_type=refresh_token&refresh_token=\(refreshToken)&client_id=\(Secrets.clientID)&client_secret=\(Secrets.clientSecret)"
        request.httpBody = bodyString.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error)")
                return
            }

            guard let data = data else {
                print("No data")
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                if let accessToken = json?["access_token"] as? String {
                    print("Refreshed access token: \(accessToken)")

                    UserDefaults.standard.set(accessToken, forKey: "spotify_access_token")
                    UserDefaults.standard.set(Date(), forKey: "spotify_token_timestamp")

                    if let refreshToken = json?["refresh_token"] as? String {
                        UserDefaults.standard.set(refreshToken, forKey: "spotify_refresh_token")
                    }

                    if let expiresIn = json?["expires_in"] as? Int {
                        UserDefaults.standard.set(expiresIn, forKey: "spotify_token_expires_in")
                    }
                    
                    // Trigger UI update on main queue
                    DispatchQueue.main.async {
                        self.tokenValidationTrigger.toggle()
                    }
                }
            } catch {
                print("JSON parsing error: \(error)")
            }
        }.resume()
    }
    
    // Return status via completion and update @Published properties
    func getSongStatus(completion: ((Bool, Track?) -> Void)? = nil){
        if !isTokenValid {
            print("Token expired, attempting to refresh...")
            refreshAccessToken()
            completion?(false, nil)
            return
        }
        
        guard let url = URL(string: "https://api.spotify.com/v1/me/player/currently-playing") else {
            completion?(false, nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(UserDefaults.standard.string(forKey: "spotify_access_token") ?? "")", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error)")
                DispatchQueue.main.async {
                    self.isPlayingNow = false
                    self.nowPlaying = nil
                    self.currentProgressMs = nil
                }
                completion?(false, nil)
                return
            }

            if let http = response as? HTTPURLResponse {
                // 204 means nothing is playing
                if http.statusCode == 204 {
                    DispatchQueue.main.async {
                        self.isPlayingNow = false
                        self.nowPlaying = nil
                        self.currentProgressMs = nil
                    }
                    completion?(false, nil)
                    return
                }
                if http.statusCode == 401 {
                    print("Token invalid, refreshing...")
                    DispatchQueue.main.async { self.refreshAccessToken() }
                    completion?(false, nil)
                    return
                }
            }

            guard let data = data, !data.isEmpty else {
                print("No data or empty response")
                DispatchQueue.main.async {
                    self.isPlayingNow = false
                    self.nowPlaying = nil
                    self.currentProgressMs = nil
                }
                completion?(false, nil)
                return
            }

            do {
                let currentlyPlaying = try JSONDecoder().decode(CurrentlyPlaying.self, from: data)
                DispatchQueue.main.async {
                    self.isPlayingNow = currentlyPlaying.isPlaying
                    self.nowPlaying = currentlyPlaying.item
                    self.currentProgressMs = currentlyPlaying.progressMs
                }
                completion?(currentlyPlaying.isPlaying, currentlyPlaying.item)
            } catch {
                print("json error while parsing: \(error)")
                DispatchQueue.main.async {
                    self.isPlayingNow = false
                    self.nowPlaying = nil
                    self.currentProgressMs = nil
                }
                completion?(false, nil)
            }
        }.resume()
    }

    func togglePlayPause(completion: ((Bool) -> Void)? = nil) {
        if !isTokenValid {
            print("Token expired, attempting to refresh...")
            refreshAccessToken()
            completion?(false)
            return
        }

        func performToggle(isPlaying: Bool){
            let urlString = isPlaying
                ? "https://api.spotify.com/v1/me/player/pause"
                : "https://api.spotify.com/v1/me/player/play"

            guard let url = URL(string: urlString) else {
                completion?(false); return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("Bearer \(UserDefaults.standard.string(forKey: "spotify_access_token") ?? "")",
                             forHTTPHeaderField: "Authorization")
            request.httpBody = Data()

            URLSession.shared.dataTask(with: request) { _, response, error in
                if let error = error {
                    print("Toggle Error:,", error)
                    completion?(false)
                    return
                }

                if let http = response as? HTTPURLResponse {
                    // Treat any 2xx as success (Spotify can return 200 or 204)
                    if (200...299).contains(http.statusCode) {
                        DispatchQueue.main.async {
                            // Optimistic local update
                            self.isPlayingNow = !isPlaying
                        }
                        // Refresh full status shortly after to sync track/progress
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            self.getSongStatus()
                        }
                        completion?(true)
                        return
                    }

                    if http.statusCode == 401 {
                        print("Unauthorized toggle")
                        completion?(false)
                        return
                    }
                    if http.statusCode == 404 {
                        print("No current active device")
                        completion?(false)
                        return
                    }
                    if http.statusCode == 403 {
                        print("Forbidden (likely requires Premium)")
                        completion?(false)
                        return
                    }

                    print("Unexpected toggle status:", http.statusCode)
                    completion?(false)
                    return
                }

                completion?(false)
            }.resume()
        }

        if nowPlaying != nil || isPlayingNow {
            performToggle(isPlaying: isPlayingNow)
        } else {
            getSongStatus { isPlaying, _ in
                performToggle(isPlaying: isPlaying)
            }
        }
    }    
    
    private var statusTimer: Timer?

    func startPlaybackMonitor(every interval: TimeInterval = 0.2) {
        stopPlaybackMonitor()
        getSongStatus()
        statusTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.getSongStatus()
        }
    }

    func stopPlaybackMonitor() {
        statusTimer?.invalidate()
        statusTimer = nil
    }

    func skipSong(completion: ((Bool) -> Void)? = nil) {
        if !isTokenValid {
            print("Token expired, attempting to refresh...")
            refreshAccessToken()
            completion?(false)
            return
        }

        var comps = URLComponents(string: "https://api.spotify.com/v1/me/player/next")!

        guard let url = comps.url else { completion?(false); return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(UserDefaults.standard.string(forKey: "spotify_access_token") ?? "")",
                         forHTTPHeaderField: "Authorization")
        request.httpBody = Data()

        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                print("Skip error:", error)
                completion?(false)
                return
            }

            guard let http = response as? HTTPURLResponse else {
                completion?(false)
                return
            }

            if (200...299).contains(http.statusCode) {
                // Success — fetch fresh status so title/artwork update quickly
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.getSongStatus()
                }
                completion?(true)
                return
            }

            if http.statusCode == 401 {
                print("Unauthorized; refreshing token…")
                DispatchQueue.main.async { self.refreshAccessToken() }
            } else if http.statusCode == 404 {
                print("No active device")
            } else if http.statusCode == 403 {
                print("Action forbidden (likely requires Premium)")
            } else {
                print("Unexpected status:", http.statusCode)
            }
            completion?(false)
        }.resume()
    }

    func skipBack(completion: ((Bool) -> Void)? = nil) {
        if !isTokenValid {
            print("Token expired, attempting to refresh...")
            refreshAccessToken()
            completion?(false)
            return
        }

        if currentProgressMs! > 2000 {
            skipToTimestamp(positionMs: 0)
            completion?(true)
            return
        }

        var comps = URLComponents(string: "https://api.spotify.com/v1/me/player/previous")!

        guard let url = comps.url else { completion?(false); return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(UserDefaults.standard.string(forKey: "spotify_access_token") ?? "")",
                         forHTTPHeaderField: "Authorization")
        request.httpBody = Data()

        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                print("Skip error:", error)
                completion?(false)
                return
            }

            guard let http = response as? HTTPURLResponse else {
                completion?(false)
                return
            }

            if (200...299).contains(http.statusCode) {
                // Success — fetch fresh status so title/artwork update quickly
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.getSongStatus()
                }
                completion?(true)
                return
            }

            if http.statusCode == 401 {
                print("Unauthorized; refreshing token…")
                DispatchQueue.main.async { self.refreshAccessToken() }
            } else if http.statusCode == 404 {
                print("No active device")
            } else if http.statusCode == 403 {
                print("Action forbidden (likely requires Premium)")
            } else {
                print("Unexpected status:", http.statusCode)
            }
            completion?(false)
        }.resume()
    }

    func skipToTimestamp(positionMs: Int, completion: ((Bool) -> Void)? = nil) {
        // Validate token first
        if !isTokenValid {
            print("Token expired, attempting to refresh…")
            refreshAccessToken()
            completion?(false)
            return
        }

        // Clamp to [0, trackDuration]
        let clamped: Int = {
            if let duration = nowPlaying?.durationMs {
                return max(0, min(positionMs, duration))
            } else {
                return max(0, positionMs)
            }
        }()

        var comps = URLComponents(string: "https://api.spotify.com/v1/me/player/seek")!
        comps.queryItems = [URLQueryItem(name: "position_ms", value: String(clamped))]

        guard let url = comps.url else { completion?(false); return }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(UserDefaults.standard.string(forKey: "spotify_access_token") ?? "")",
                         forHTTPHeaderField: "Authorization")
        request.httpBody = Data()

        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                print("Seek error:", error)
                completion?(false)
                return
            }
            guard let http = response as? HTTPURLResponse else {
                completion?(false)
                return
            }

            if (200...299).contains(http.statusCode) {
                // Optimistic local update
                DispatchQueue.main.async {
                    self.currentProgressMs = clamped
                }
                completion?(true)
            } else if http.statusCode == 401 {
                print("Unauthorized; refreshing token…")
                DispatchQueue.main.async { self.refreshAccessToken() }
                completion?(false)
            } else if http.statusCode == 404 {
                print("No active device")
                completion?(false)
            } else if http.statusCode == 403 {
                print("Forbidden (likely requires Premium)")
                completion?(false)
            } else {
                print("Seek unexpected status:", http.statusCode)
                completion?(false)
            }
        }.resume()
    }
}
