//
//
//  LoginView.swift
//  parrot
//
//  Created by sunyanhai on 2025/9/26.
//

import SwiftUI
import Combine

struct LoginView: View {
    @EnvironmentObject private var authManager: AuthManager
    @State private var username = ""
    @State private var password = ""
    @State private var showingRegister = false
    @State private var isPasswordVisible = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景图片
                Image("login_background") // 替换为你的图片名称
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea()
                    .overlay(
                        Color.black.opacity(0.3) // 添加遮罩增强文字可读性
                    )
                
                // 原有的毛玻璃效果内容保持不变
                ParticleEffectView()
                
                VStack(spacing: 40) {
                    Spacer()
                    
                    // App logo and title
                    VStack(spacing: 20) {
                        Image(systemName: "bird.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.3), radius: 10)
                            .scaleEffect(1.0)
                            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: true)
                        
                        Text("鹦鹉管理系统")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    // Login form
                    VStack(spacing: 24) {
                        // 原有的表单内容保持不变...
                        GlassTextField(
                            icon: "person.fill",
                            placeholder: "用户名",
                            text: $username
                        )
                        
                        GlassPasswordField(
                            icon: "lock.fill",
                            placeholder: "密码",
                            text: $password,
                            isVisible: $isPasswordVisible
                        )
                        
                        if let errorMessage = authManager.errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding(.horizontal)
                        }
                        
                        Button(action: loginAction) {
                                                    HStack {
                                                        if authManager.isLoading {
                                                            ProgressView()
                                                                .scaleEffect(0.8)
                                                                .tint(.white)
                                                        } else {
                                                            Text("登录")
                                                                .font(.headline)
                                                                .fontWeight(.semibold)
                                                                .foregroundColor(.white)
                                                        }
                                                    }
                                                    .frame(maxWidth: .infinity)
                                                    .frame(height: 50)
                                                }
                                                .disabled(authManager.isLoading || username.isEmpty || password.isEmpty)
                                                .buttonStyle(GlassButtonStyle()) // 应用毛玻璃按钮样式
                                                .opacity((username.isEmpty || password.isEmpty) ? 0.6 : 1.0)
                                            }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                }
            }
        }
        .ignoresSafeArea(.all) // 在外部也忽略安全区域
                .background(Color.clear) // 清除视图本身的背景色
        .sheet(isPresented: $showingRegister) {
            // 注册视图
        }
    }
    
    private func loginAction() {
        hideKeyboard()
        authManager.login(username: username, password: password)
    }
}
struct GlassTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 20)
            
            TextField(placeholder, text: $text)
                .foregroundColor(.white)
                .textFieldStyle(.plain)
                .font(.body)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .glassBackground()
    }
}

struct GlassPasswordField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    @Binding var isVisible: Bool
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 20)
            
            if isVisible {
                TextField(placeholder, text: $text)
                    .foregroundColor(.white)
                    .textFieldStyle(.plain)
                    .font(.body)
            } else {
                SecureField(placeholder, text: $text)
                    .foregroundColor(.white)
                    .textFieldStyle(.plain)
                    .font(.body)
            }
            
            Button(action: { isVisible.toggle() }) {
                Image(systemName: isVisible ? "eye.slash" : "eye")
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .glassBackground()
    }
}

struct ParticleEffectView: View {
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                
            }
        }
        .onAppear {
            animationOffset = 100
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthManager())
}
