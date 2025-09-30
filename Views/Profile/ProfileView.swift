//
//  ProfileView.swift
//  parrot
//
//  Created by sunyanhai on 2025/9/26.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var authManager: AuthManager
    @State private var showingLogoutAlert = false
    @State private var showingAbout = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile header
                    profileHeader
                    
                    
                    // Menu sections
                    menuSections
                    
                    // App info
                    appInfoSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
//            .navigationTitle("个人中心")
            .navigationBarTitleDisplayMode(.large)
        }
        .alert("确认退出", isPresented: $showingLogoutAlert) {
            Button("取消", role: .cancel) { }
            Button("退出", role: .destructive) {
                withAnimation {
                    authManager.logout()
                }
            }
        } message: {
            Text("确定要退出登录吗？")
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
    }
    
    private var profileHeader: some View {
        HStack(spacing: 16) {
            // 头像部分 (左边)
            ZStack {
                Circle()
                    .fill(.blue.gradient)
                    .frame(width: 80, height: 80)
                
                Text(String(authManager.currentUser?.prefix(1).uppercased() ?? "U"))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            // 用户信息部分 (右边，垂直排列)
            VStack(alignment: .leading, spacing: 8) {
                // 用户名
                Text(authManager.currentUser ?? "未知用户")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                // 角色
                Text("管理员")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // 状态
                HStack(spacing: 6) {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                    
                    Text("在线")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer() // 将内容推到左边
        }
        .padding(.vertical, 16)
    }
    
    
    private var menuSections: some View {
        VStack(spacing: 20) {
            // Management section
            MenuSection(title: "管理") {
                MenuRow(
                    title: "品种管理",
                    subtitle: "管理鹦鹉品种信息",
                    icon: "list.bullet.circle.fill",
                    color: .purple
                ) {
                    // Navigate to species management
                }
                
                MenuRow(
                    title: "数据统计",
                    subtitle: "查看详细统计报告",
                    icon: "chart.bar.doc.horizontal.fill",
                    color: .blue
                ) {
                    // Navigate to detailed stats
                }
                
                MenuRow(
                    title: "导入导出",
                    subtitle: "数据导入和导出功能",
                    icon: "arrow.up.arrow.down.circle.fill",
                    color: .green
                ) {
                    // Navigate to import/export
                }
            }
            
            // Settings section
            MenuSection(title: "设置") {
                MenuRow(
                    title: "通知设置",
                    subtitle: "管理消息和提醒",
                    icon: "bell.fill",
                    color: .orange
                ) {
                    // Navigate to notifications
                }
                
                MenuRow(
                    title: "数据同步",
                    subtitle: "云端数据同步设置",
                    icon: "icloud.fill",
                    color: .cyan
                ) {
                    // Navigate to sync settings
                }
                
                MenuRow(
                    title: "隐私设置",
                    subtitle: "隐私和安全选项",
                    icon: "lock.shield.fill",
                    color: .indigo
                ) {
                    // Navigate to privacy settings
                }
            }
            
            // Support section
            MenuSection(title: "支持") {
                MenuRow(
                    title: "帮助中心",
                    subtitle: "使用指南和常见问题",
                    icon: "questionmark.circle.fill",
                    color: .blue
                ) {
                    // Navigate to help
                }
                
                MenuRow(
                    title: "反馈建议",
                    subtitle: "意见反馈和功能建议",
                    icon: "envelope.fill",
                    color: .green
                ) {
                    // Navigate to feedback
                }
                
                MenuRow(
                    title: "关于应用",
                    subtitle: "版本信息和开发团队",
                    icon: "info.circle.fill",
                    color: .gray
                ) {
                    showingAbout = true
                }
            }
        }
    }
    
    private var appInfoSection: some View {
        VStack(spacing: 16) {
            // Logout button
            Button {
                showingLogoutAlert = true
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.title3)
                    Text("退出登录")
                        .font(.headline)
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .foregroundColor(.red)
            }
            
            // Version info
            VStack(spacing: 4) {
                Text("鹦鹉管理系统")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("版本 1.0.0")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct QuickStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color.gradient)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 80)
        .frame(maxWidth: .infinity)
    }
}

struct MenuSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, 4)
            
            VStack(spacing: 1) {
                content
            }
            .cardEffect()

        }
    }
}

struct MenuRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.gradient)
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // App icon and info
                    VStack(spacing: 16) {
                        Image(systemName: "bird.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(.blue.gradient)
                        
                        Text("鹦鹉管理系统")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("版本 1.0.0")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Description
                    VStack(alignment: .leading, spacing: 16) {
                        Text("关于应用")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("这是一款专业的鹦鹉管理应用，帮助您轻松管理鹦鹉信息、笼子分配和日常统计。应用采用现代化设计，操作简单直观，是鹦鹉养殖场和宠物店的理想选择。")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .cardEffect()

                    
                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        Text("主要功能")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            FeatureRow(icon: "building.2.fill", title: "笼子管理", description: "创建和管理笼子信息")
                            FeatureRow(icon: "bird.fill", title: "鹦鹉档案", description: "详细记录每只鹦鹉信息")
                            FeatureRow(icon: "magnifyingglass", title: "快速搜索", description: "根据脚环号快速查找")
                            FeatureRow(icon: "chart.bar.fill", title: "数据统计", description: "直观的统计图表")
                        }
                    }
                    .padding()
                    .cardEffect()

                    
                    // Contact info
                    VStack(alignment: .leading, spacing: 16) {
                        Text("联系我们")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("如有问题或建议，请联系：")
                                .font(.body)
                                .foregroundColor(.secondary)
                            
                            Text("开发团队")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                    .padding()
                    .cardEffect()
                }
                .padding(.horizontal, 16)
            }
            .navigationTitle("关于")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthManager())
}
