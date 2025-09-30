//
//  DataService.swift
//  parrot
//
//  Created by sunyanhai on 2025/9/26.
//

import Foundation
import Combine

class DataService: ObservableObject {
    static let shared = DataService()
    private let networkManager = NetworkManager.shared
    
    private init() {}
    
    // MARK: - Parrot Services
    func fetchParrots(pageNum: Int = 1, all: Bool = false) -> AnyPublisher<PaginatedResponse<Parrot>, APIError> {
        var endpoint = "/parrots?pageNum=\(pageNum)"
        if all {
            endpoint += "&all=true"
        }
        let publisher: AnyPublisher<PaginatedResponse<Parrot>, APIError> = networkManager.performRequest(endpoint: endpoint)
        return publisher
    }
    
    func fetchAllParrots() -> AnyPublisher<PaginatedResponse<Parrot>, APIError> {
        return fetchParrots(all: true)
    }
    
    func searchParrots(ring: String) -> AnyPublisher<[Parrot], APIError> {
        let publisher: AnyPublisher<[Parrot], APIError> = networkManager.performRequest(endpoint: "/parrots/search/like?ring=\(ring)")
        return publisher
    }
    
    func searchParrotsWithCage(ring: String) -> AnyPublisher<[ParrotWithCage], APIError> {
        let publisher: AnyPublisher<[ParrotWithCage], APIError> = networkManager.performRequest(endpoint: "/parrots/with-cage?ring=\(ring)")
        return publisher
    }
    
    func fetchParrotsByCage(_ cageId: Int) -> AnyPublisher<[Parrot], APIError> {
        let publisher: AnyPublisher<[Parrot], APIError> = networkManager.performRequest(endpoint: "/parrots/by-cage/\(cageId)")
        return publisher
    }
    
    func createParrot(_ request: CreateParrotRequest) -> AnyPublisher<Bool, APIError> {
        guard let requestData = try? JSONEncoder().encode(request) else {
            return Fail(error: APIError(message: "数据编码失败")).eraseToAnyPublisher()
        }
        let publisher: AnyPublisher<Bool, APIError> = networkManager.performRequest(endpoint: "/parrots", method: .POST, body: requestData)
        return publisher
    }
    
    func updateParrot(_ id: Int, request: CreateParrotRequest) -> AnyPublisher<Bool, APIError> {
        guard let requestData = try? JSONEncoder().encode(request) else {
            return Fail(error: APIError(message: "数据编码失败")).eraseToAnyPublisher()
        }
        let publisher: AnyPublisher<Bool, APIError> = networkManager.performRequest(endpoint: "/parrots/\(id)", method: .PUT, body: requestData)
        return publisher
    }
    
    func deleteParrot(_ id: Int) -> AnyPublisher<Bool, APIError> {
        let publisher: AnyPublisher<Bool, APIError> = networkManager.performRequest(endpoint: "/parrots/\(id)", method: .DELETE)
        return publisher
    }
    
//    func fetchCages(pageNum: Int = 1, pageSize: Int = 50) -> AnyPublisher<PaginatedResponse<Cage>, APIError> {
//        // 修正参数名
//        let endpoint = "/cages/with-parrot-count?pageNum=\(pageNum)&pageSize=\(pageSize)"
//        let publisher: AnyPublisher<PaginatedResponse<Cage>, APIError> = networkManager.performRequest(endpoint: endpoint)
//        return publisher
//    }
    func fetchCages(pageNum: Int = 1, pageSize: Int = 50) -> AnyPublisher<PaginatedResponse<Cage>, APIError> {
            let endpoint = "/cages/with-parrot-count?pageNum=\(pageNum)&pageSize=\(pageSize)"
            let publisher: AnyPublisher<PaginatedResponse<Cage>, APIError> = networkManager.performRequest(endpoint: endpoint)
            return publisher
        }
    
    func fetchAllCages() -> AnyPublisher<[Cage], APIError> {
        let publisher: AnyPublisher<[Cage], APIError> = networkManager.performRequest(endpoint: "/cages/all")
        return publisher
    }
    
    func searchCages(keyword: String) -> AnyPublisher<[Cage], APIError> {
        let publisher: AnyPublisher<[Cage], APIError> = networkManager.performRequest(endpoint: "/cages/search?keyword=\(keyword)")
        return publisher
    }
    
    func fetchCagesByLocation(_ location: String) -> AnyPublisher<[Cage], APIError> {
        let publisher: AnyPublisher<[Cage], APIError> = networkManager.performRequest(endpoint: "/cages/by-location/\(location)")
        return publisher
    }
    
    func fetchCageDetail(_ id: Int) -> AnyPublisher<Cage, APIError> {
        let publisher: AnyPublisher<Cage, APIError> = networkManager.performRequest(endpoint: "/cages/\(id)")
        return publisher
    }
    
    func createCage(_ request: CreateCageRequest) -> AnyPublisher<Bool, APIError> {
        guard let requestData = try? JSONEncoder().encode(request) else {
            return Fail(error: APIError(message: "数据编码失败")).eraseToAnyPublisher()
        }
        let publisher: AnyPublisher<Bool, APIError> = networkManager.performRequest(endpoint: "/cages", method: .POST, body: requestData)
        return publisher
    }
    
    func deleteCage(_ id: Int) -> AnyPublisher<Bool, APIError> {
        let publisher: AnyPublisher<Bool, APIError> = networkManager.performRequest(endpoint: "/cages/\(id)", method: .DELETE)
        return publisher
    }
    
    // MARK: - Species Services
    func fetchSpecies() -> AnyPublisher<[Species], APIError> {
        let publisher: AnyPublisher<[Species], APIError> = networkManager.performRequest(endpoint: "/species")
        return publisher
    }
    
    func createSpecies(_ request: CreateSpeciesRequest) -> AnyPublisher<Bool, APIError> {
        guard let requestData = try? JSONEncoder().encode(request) else {
            return Fail(error: APIError(message: "数据编码失败")).eraseToAnyPublisher()
        }
        let publisher: AnyPublisher<Bool, APIError> = networkManager.performRequest(endpoint: "/species", method: .POST, body: requestData)
        return publisher
    }
    
    func updateSpecies(_ id: Int, request: CreateSpeciesRequest) -> AnyPublisher<Bool, APIError> {
        guard let requestData = try? JSONEncoder().encode(request) else {
            return Fail(error: APIError(message: "数据编码失败")).eraseToAnyPublisher()
        }
        let publisher: AnyPublisher<Bool, APIError> = networkManager.performRequest(endpoint: "/species/\(id)", method: .PUT, body: requestData)
        return publisher
    }
    
    func deleteSpecies(_ id: Int) -> AnyPublisher<Bool, APIError> {
        let publisher: AnyPublisher<Bool, APIError> = networkManager.performRequest(endpoint: "/species/\(id)", method: .DELETE)
        return publisher
    }

}
