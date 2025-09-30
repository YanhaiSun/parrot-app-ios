//
//  DataModels.swift
//  parrot
//
//  Created by sunyanhai on 2025/9/26.
//

import Foundation

// MARK: - Auth Models
struct LoginRequest: Codable {
    let username: String
    let password: String
}

struct RegisterRequest: Codable {
    let username: String
    let password: String
    let email: String?
    let phone: String?
    let nickname: String?
}

struct AuthResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let type: String
    let username: String
    let nickname: String
    let expiresIn: Int
}

struct RefreshRequest: Codable {
    let refreshToken: String
}

struct UsernameCheckResponse: Codable {
    let exists: Bool
}

// MARK: - Parrot Models
struct Parrot: Codable, Identifiable {
    var id: Int
    var ringNumber: String
    var species: Int
    var gender: String
    var age: Int?
    var cageId: Int?
    var createdAt: String?
    var speciesName: String?
    
    // 显示名称就是脚环号
    var displayName: String {
        return ringNumber
    }
    
    var ageDisplay: String {
        if let age = age {
            return "\(age)岁"
        }
        return "未知年龄"
    }
    
    var createdAtDisplay: String {
        return createdAt ?? "未知时间"
    }
}

struct CreateParrotRequest: Codable {
    let ringNumber: String  // 只需要脚环号，不再需要name
    let species: Int
    let gender: String
    let age: Int?
    let cageId: Int?
}

struct ParrotWithCage: Codable {
    let parrot: Parrot
    let cage: Cage
    var speciesWithCage: String {
            "\(parrot.speciesName ?? "未知品种")-\(cage.cageCode)"
        }
}

// MARK: - Cage Models
struct Cage: Codable, Identifiable, Hashable {
    let id: Int
    let cageCode: String
    let location: String     // API返回的是字符串，但实际代表品种ID
    let capacity: Int
    let createdAt: String
    let parrotCount: String?  // 可选，因为API可能返回null
    
    // 将location转换为品种ID（因为location实际上是品种ID）
    var speciesId: Int? {
        return Int(location) ?? 0
    }
    
    // 为了兼容现有代码，保持location的访问方式
    var displayLocation: String {
        return "品种\(location)"
    }
    
    var speciesName: String? {
        // 这里需要从外部传入品种列表
        return nil // 实际实现中需要通过品种ID查找名称
    }
    
    var parrotCountInt: Int {
        // 如果parrotCount为null或空字符串，返回0
        return Int(parrotCount ?? "0") ?? 0
    }
    
    var occupancyRate: Double {
        guard capacity > 0 else { return 0 }
        return Double(parrotCountInt) / Double(capacity)
    }
}

struct Species: Identifiable, Codable, Hashable {
    let id: Int
    let name: String
}

struct CreateCageRequest: Codable {
    let cageCode: String
    let location: String    // 这实际上是品种ID，但作为字符串传递
    let capacity: Int
}

struct CreateSpeciesRequest: Codable {
    let name: String
}

// MARK: - Generic Response Models
struct PaginatedResponse<T: Codable>: Codable {
    let records: [T]
    let total: Int
    let size: Int
    let current: Int
    let pages: Int
}

// MARK: - Error Models
struct APIError: Error, LocalizedError {
    let message: String
    
    var errorDescription: String? {
        return message
    }
}
