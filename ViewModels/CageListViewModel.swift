//
//  CageListViewModel.swift
//  parrot
//
//  Created by sunyanhai on 2025/9/26.
//

import Foundation
import Combine
import KeychainAccess

@MainActor
class CageListViewModel: ObservableObject {
    @Published var cages: [Cage] = []
        @Published var filteredCages: [Cage] = []
        @Published var isLoading = false
        @Published var errorMessage: String?
        @Published var hasMorePages = false
        @Published var species: [Species] = []
        
        private let dataService = DataService.shared
        private var cancellables = Set<AnyCancellable>()
        private var currentPage = 1
        private let pageSize = 50 // 每页大小
        private var searchKeyword = ""
        private var selectedLocation: String?
        private var currentSpeciesId: Int? = nil

        
        // 加载笼子数据（分页）
        func loadCages() async {
            isLoading = true
            errorMessage = nil
            currentPage = 1
            
            print("🔍 Starting to load cages, page: \(currentPage)")
            
            // 先加载品种数据
            await loadSpecies()
            
            // 检查认证令牌
            if let token = KeychainAccess.Keychain(service: "com.parrot.app")["accessToken"] {
                print("🔑 Auth token available: \(token.prefix(20))...")
            } else {
                print("⚠️ No auth token found!")
            }
            
            dataService.fetchCages(pageNum: currentPage, pageSize: pageSize)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { [weak self] completion in
                        self?.isLoading = false
                        switch completion {
                        case .failure(let error):
                            print("❌ Failed to load cages: \(error)")
                            self?.errorMessage = error.localizedDescription
                        case .finished:
                            print("✅ Successfully loaded cages")
                        }
                    },
                    receiveValue: { [weak self] response in
                        print("📦 Received \(response.records.count) records, total: \(response.total)")
                        self?.cages = response.records
                        self?.hasMorePages = (self?.currentPage ?? 1) < response.pages
                        self?.applyFilters()
                    }
                )
                .store(in: &cancellables)
        }
    
    // 加载所有笼子（不分页）
    func loadAllCages() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // 使用 asyncValues 扩展获取第一个值（即完整的笼子数组）
            let cages = try await dataService.fetchAllCages()
                .asyncValues
                .first { _ in true } ?? []  // 这里修正了错误
            
            self.cages = cages
            self.filteredCages = cages
            print("✅ Loaded all \(cages.count) cages")
        } catch {
            print("❌ Failed to load all cages: \(error)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // 加载更多笼子（分页）
        func loadMoreCages() async {
            guard hasMorePages && !isLoading else { return }
            
            isLoading = true
            currentPage += 1
            
            dataService.fetchCages(pageNum: currentPage, pageSize: pageSize)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { [weak self] completion in
                        self?.isLoading = false
                        switch completion {
                        case .failure(let error):
                            print("❌ Failed to load more cages: \(error)")
                            self?.errorMessage = error.localizedDescription
                            self?.currentPage -= 1
                        case .finished:
                            print("✅ Successfully loaded more cages")
                        }
                    },
                    receiveValue: { [weak self] response in
                        print("📦 Loaded additional \(response.records.count) records")
                        self?.cages.append(contentsOf: response.records)
                        self?.hasMorePages = (self?.currentPage ?? 1) < response.pages
                        self?.applyFilters()
                    }
                )
                .store(in: &cancellables)
        }
    // 加载指定品种的笼子
        func loadCagesForSpecies(_ speciesId: Int?) {
            isLoading = true
            errorMessage = nil
            currentSpeciesId = speciesId
            
            if let speciesId = speciesId {
                // 加载指定品种的笼子（不分页）
                dataService.fetchCagesByLocation(String(speciesId))
                    .receive(on: DispatchQueue.main)
                    .sink(
                        receiveCompletion: { [weak self] completion in
                            self?.isLoading = false
                            switch completion {
                            case .failure(let error):
                                print("❌ Failed to load cages: \(error)")
                                self?.errorMessage = error.localizedDescription
                            case .finished:
                                print("✅ Successfully loaded cages for species \(speciesId)")
                            }
                        },
                        receiveValue: { [weak self] cages in
                            print("📦 Received \(cages.count) cages for species \(speciesId)")
                            self?.filteredCages = cages
                        }
                    )
                    .store(in: &cancellables)
            } else {
                // 加载所有笼子（分页）
                dataService.fetchCages(pageNum: 1, pageSize: 100) // 加载第一页，每页100条
                    .receive(on: DispatchQueue.main)
                    .sink(
                        receiveCompletion: { [weak self] completion in
                            self?.isLoading = false
                            switch completion {
                            case .failure(let error):
                                print("❌ Failed to load cages: \(error)")
                                self?.errorMessage = error.localizedDescription
                            case .finished:
                                print("✅ Successfully loaded all cages")
                            }
                        },
                        receiveValue: { [weak self] response in
                            print("📦 Received \(response.records.count) records")
                            self?.filteredCages = response.records
                        }
                    )
                    .store(in: &cancellables)
            }
        }
        
    // 加载品种数据（使用async/await）
        func loadSpecies() async {
            do {
                let species = try await dataService.fetchSpecies()
                    .asyncValues
                    .first { _ in true } ?? []
                
                self.species = species
                print("✅ Successfully loaded \(species.count) species")
            } catch {
                print("❌ Failed to load species: \(error)")
                errorMessage = "加载品种数据失败"
            }
        }
    // 搜索笼子
    func searchCages(keyword: String) {
        searchKeyword = keyword
        
        if keyword.isEmpty {
            applyFilters()
        } else {
            dataService.searchCages(keyword: keyword)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { [weak self] completion in
                        switch completion {
                        case .failure(let error):
                            print("❌ Failed to search cages: \(error)")
                            self?.errorMessage = error.localizedDescription
                        case .finished:
                            print("✅ Search completed")
                        }
                    },
                    receiveValue: { [weak self] searchResults in
                        print("🔍 Found \(searchResults.count) cages matching '\(keyword)'")
                        self?.cages = searchResults
                        self?.applyFilters()
                    }
                )
                .store(in: &cancellables)
        }
    }
    
    // 按位置筛选
    func filterByLocation(_ location: String?) {
        selectedLocation = location
        applyFilters()
    }
    
    // 添加笼子
    func addCage(_ cage: Cage) {
        cages.insert(cage, at: 0)
        applyFilters()
        print("➕ Added new cage: \(cage.cageCode)")
    }
    
    // 删除笼子
    func deleteCage(_ cageId: Int) async {
        dataService.deleteCage(cageId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .failure(let error):
                        print("❌ Failed to delete cage: \(error)")
                        self?.errorMessage = error.localizedDescription
                    case .finished:
                        print("✅ Cage deletion completed")
                    }
                },
                receiveValue: { [weak self] success in
                    if success {
                        print("🗑️ Deleted cage with ID: \(cageId)")
                        self?.cages.removeAll { $0.id == cageId }
                        self?.applyFilters()
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // 刷新数据
    func refresh() async {
        await loadCages()
    }
    
    // 应用筛选条件
    private func applyFilters() {
        var filtered = cages
        
        // 按位置筛选
        if let location = selectedLocation, location != "全部" {
            filtered = filtered.filter { $0.location == location }
        }
        
        // 按笼子编码排序
        filtered.sort { $0.cageCode < $1.cageCode }
        
        filteredCages = filtered
        print("🔧 Applied filters, now showing \(filteredCages.count) cages")
    }
}

// 将 Publisher 转换为 async/await 的扩展
extension Publisher {
    var asyncValues: AsyncThrowingStream<Output, Error> {
        AsyncThrowingStream { continuation in
            let cancellable = sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        continuation.finish()
                    case .failure(let error):
                        continuation.finish(throwing: error)
                    }
                },
                receiveValue: { value in
                    continuation.yield(value)
                }
            )
            
            continuation.onTermination = { @Sendable _ in
                cancellable.cancel()
            }
        }
    }
}
