//
//  parrotApp.swift
//  parrot
//
//  Created by sunyanhai on 2025/9/26.
//

import SwiftUI

@main
struct parrotApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // 设置 UITableView 的背景色（影响 SwiftUI List）
                    UITableView.appearance().backgroundColor = .systemGroupedBackground
                }
        }
    }
}
