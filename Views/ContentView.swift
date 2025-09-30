//
//  ContentView.swift
//  parrot
//
//  Created by sunyanhai on 2025/9/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authManager = AuthManager()
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MainTabView()
                    .environmentObject(authManager)
            } else {
                LoginView()
                    .environmentObject(authManager)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: authManager.isAuthenticated)
    }
}

#Preview {
    ContentView()
}
