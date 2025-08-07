//
//  ContentView.swift
//  AudioMixer
//
//  Created by Thomas Evans on 20/07/2025.
//

import SwiftUI

struct ItemRow: View {
    
    @State private var isEditing = false
    @State private var currentKey = ""
    
    private var spotifyController = SpotifyController()
    
    var body: some View {
        VStack(alignment: .leading){
            HStack {
                Image(systemName: "gearshape")
                    .font(.system(size: 25))
                Text("Settings")
                    .frame(minWidth: 0, minHeight: 0)
                    .font(.system(size: 25))
                Spacer()
            }
            .padding(EdgeInsets(top: 10, leading: 4, bottom: 0, trailing: 0))
            Button(action: {
                spotifyController.authorize()
            })  {
                Text("Connect to Spotify")
            }
            .onOpenURL { incomingURL in
                print("App was opened by URL: \(incomingURL)")
                
                // This code extracts the authorization code from the URL
                guard let components = URLComponents(url: incomingURL, resolvingAgainstBaseURL: true),
                      let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
                    print("Error: Could not find authorization code in URL.")
                    return
                }
                
                print("SUCCESS! Authorization Code: \(code)")
                
                // The next step will be to use this code.
                // For example: spotifyController.exchangeCodeForToken(code: code)
            }
            .padding()
        }
    }
}

#Preview {
    ItemRow()
}
