//
//  MainTabView.swift
//  parrot
//
//  Created by sunyanhai on 2025/9/26.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard
            DashboardView()
                .tabItem {
                    Image(systemName: "chart.pie")
                    Text("概况")
                }
                .tag(0)
            
            // Cages
            CageListView()
                .tabItem {
                    Image(systemName: "cube")
                    Text("笼子")
                }
                .tag(1)
            
//            // Parrots
//            ParrotListView()
//                .tabItem {
//                    Image(systemName: "bird.fill")
//                    Text("鹦鹉")
//                }
//                .tag(2)
            
            // Search
            SearchView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("搜索")
                }
                .tag(3)
            
            // Profile
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("个人")
                }
                .tag(4)
        }
        .tint(.blue)
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthManager())
}
