//
//  iOS16Extensions.swift
//  parrot
//
//  Created by sunyanhai on 2025/9/26.
//

import SwiftUI

// iOS 16+ Compatible Extensions and Styles

extension View {
    /// iOS 16+ compatible glass effect replacement
    func glassBackground(cornerRadius: CGFloat = 12) -> some View {
            self.background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial) // 超薄材质，毛玻璃效果
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            )
        }
    
    /// Card style with shadow instead of glass effect
    func cardEffect(cornerRadius: CGFloat = 12) -> some View {
            self
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.background) // 使用系统背景色，自动适配暗黑模式
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    func glassTextEffect() -> some View {
            self.foregroundStyle(.white)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
        }
    
    /// Modern Liquid Glass effect for iOS 16+ compatibility
    func glassEffect(_ glass: Glass = .regular, in shape: AnyShape = AnyShape(.capsule), isEnabled: Bool = true) -> some View {
        self.modifier(GlassEffectModifier(glass: glass, shape: shape, isEnabled: isEnabled))
    }
    
    /// Hide keyboard function
    func hideKeyboard() {
        #if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }
}

// Glass configuration structure
struct Glass {
    let tintColor: Color?
    let isInteractive: Bool
    
    static let regular = Glass(tintColor: nil, isInteractive: false)
    
    func tint(_ color: Color) -> Glass {
        Glass(tintColor: color, isInteractive: self.isInteractive)
    }
    
    func interactive(_ isInteractive: Bool = true) -> Glass {
        Glass(tintColor: self.tintColor, isInteractive: isInteractive)
    }
}

// AnyShape for shape flexibility
struct AnyShape: Shape, @unchecked Sendable {
    private let _path: @Sendable (CGRect) -> Path
    
    init<S: Shape>(_ shape: S) {
        _path = { rect in
            shape.path(in: rect)
        }
    }
    
    static let capsule = AnyShape(Capsule())
    static func rect(cornerRadius: CGFloat) -> AnyShape {
        AnyShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
    static let circle = AnyShape(Circle())
    
    func path(in rect: CGRect) -> Path {
        _path(rect)
    }
}

// Glass effect modifier
struct GlassEffectModifier: ViewModifier {
    let glass: Glass
    let shape: AnyShape
    let isEnabled: Bool
    
    func body(content: Content) -> some View {
        content
            .background {
                if isEnabled {
                    shape
                        .fill(.ultraThinMaterial)
                        .overlay {
                            if let tintColor = glass.tintColor {
                                shape
                                    .fill(tintColor)
                            }
                        }
                        .overlay {
                            shape
                                .stroke(.white.opacity(0.2), lineWidth: 1)
                        }
                }
            }
    }
}

struct GlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial) // 按钮毛玻璃背景
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// iOS 16+ Compatible Bordered Prominent Button Style
struct GlassProminentButtonStyle: ButtonStyle {
    let cornerRadius: CGFloat
    let backgroundColor: Color
    
    init(cornerRadius: CGFloat = 12, backgroundColor: Color = .blue) {
        self.cornerRadius = cornerRadius
        self.backgroundColor = backgroundColor
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
//                    .fill(backgroundColor.gradient)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(.white.opacity(0.3), lineWidth: 1)
                    }
            }
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// Color extensions for better gradient support
extension Color {
    static let glassTint = Color.white.opacity(0.1)
    static let glassStroke = Color.white.opacity(0.2)
    static let glassBackground = Color.clear
}

// Button style extensions to support .glass syntax
extension ButtonStyle where Self == GlassButtonStyle {
    static var glass: GlassButtonStyle {
        GlassButtonStyle()
    }
}

extension ButtonStyle where Self == GlassProminentButtonStyle {
    static var glassProminent: GlassProminentButtonStyle {
        GlassProminentButtonStyle()
    }
}
