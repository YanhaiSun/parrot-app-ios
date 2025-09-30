//
//  CageDetailViewModel.swift
//  parrot
//
//  Created by sunyanhai on 2025/9/29.
//
import Foundation
import Combine

@MainActor
class CageDetailViewModel: ObservableObject {
    let cageId: Int
    @Published var parrots: [Parrot] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var species: [Species] = []
    private var currentCageId: Int // 添加这行声明

    private let dataService = DataService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init(cageId: Int) {
        self.cageId = cageId
        self.currentCageId = cageId // 初始化 currentCageId
    }
    
    func switchToCage(_ cageId: Int) {
        guard cageId != currentCageId else { return }
        currentCageId = cageId
        loadParrots()
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
    
    func loadParrots() {
        isLoading = true
        errorMessage = nil
        
        dataService.fetchParrotsByCage(cageId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    switch completion {
                    case .failure(let error):
                        self?.errorMessage = error.localizedDescription
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] parrots in
                    self?.parrots = parrots
                }
            )
            .store(in: &cancellables)
    }
    
    func addParrot(_ parrot: Parrot) {
        parrots.insert(parrot, at: 0)
    }
    
    // 删除鹦鹉
        func deleteParrot(_ parrot: Parrot) {
            isLoading = true
            errorMessage = nil
            
            dataService.deleteParrot(parrot.id)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { [weak self] completion in
                        self?.isLoading = false
                        switch completion {
                        case .failure(let error):
                            self?.errorMessage = error.localizedDescription
                        case .finished:
                            break
                        }
                    },
                    receiveValue: { [weak self] success in
                        if success {
                            self?.parrots.removeAll { $0.id == parrot.id }
                        } else {
                            self?.errorMessage = "删除鹦鹉失败"
                        }
                    }
                )
                .store(in: &cancellables)
        }
        
        // 更新鹦鹉信息
        func updateParrot(_ parrot: Parrot) {
            isLoading = true
            errorMessage = nil
            
            let request = CreateParrotRequest(
                ringNumber: parrot.ringNumber,
                species: parrot.species,
                gender: parrot.gender,
                age: parrot.age,
                cageId: parrot.cageId
            )
            
            dataService.updateParrot(parrot.id, request: request)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { [weak self] completion in
                        self?.isLoading = false
                        switch completion {
                        case .failure(let error):
                            self?.errorMessage = error.localizedDescription
                        case .finished:
                            break
                        }
                    },
                    receiveValue: { [weak self] success in
                        if success {
                            if let index = self?.parrots.firstIndex(where: { $0.id == parrot.id }) {
                                self?.parrots[index] = parrot
                            }
                        } else {
                            self?.errorMessage = "更新鹦鹉信息失败"
                        }
                    }
                )
                .store(in: &cancellables)
        }
}
