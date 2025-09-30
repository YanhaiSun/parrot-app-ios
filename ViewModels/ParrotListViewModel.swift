//
//  ParrotListViewModel.swift
//  parrot
//
//  Created by sunyanhai on 2025/9/26.
//

import Foundation
import Combine

@MainActor
class ParrotListViewModel: ObservableObject {
    @Published var parrots: [Parrot] = []
    @Published var filteredParrots: [Parrot] = []
    @Published var species: [Species] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasMorePages = false
    
    private let dataService = DataService.shared
    private var cancellables = Set<AnyCancellable>()
    private var currentPage = 1
    private var searchKeyword = ""
    private var selectedSpecies: Int?
    private var selectedGender: String?
    
    func loadParrots() async {
        isLoading = true
        errorMessage = nil
        currentPage = 1
        
        dataService.fetchParrots(pageNum: currentPage)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    switch completion {
                    case .failure(let error):
                        print("Failed to load parrots data: \(error)")
                        self?.errorMessage = error.localizedDescription
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] response in
                    self?.parrots = response.records
                    self?.hasMorePages = (self?.currentPage ?? 1) < response.pages
                    self?.applyFilters()
                }
            )
            .store(in: &cancellables)
    }
    
    func loadMoreParrots() async {
        guard hasMorePages && !isLoading else { return }
        
        isLoading = true
        currentPage += 1
        
        dataService.fetchParrots(pageNum: currentPage)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    switch completion {
                    case .failure(let error):
                        print("Failed to load more parrots: \(error)")
                        self?.errorMessage = error.localizedDescription
                        self?.currentPage -= 1
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] response in
                    self?.parrots.append(contentsOf: response.records)
                    self?.hasMorePages = (self?.currentPage ?? 1) < response.pages
                    self?.applyFilters()
                }
            )
            .store(in: &cancellables)
    }
    
    func loadSpecies() async {
        dataService.fetchSpecies()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        print("Failed to load species: \(error)")
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] speciesResponse in
                    self?.species = speciesResponse
                }
            )
            .store(in: &cancellables)
    }
    
    func searchParrots(keyword: String) {
        searchKeyword = keyword
        
        if keyword.isEmpty {
            applyFilters()
        } else {
            dataService.searchParrots(ring: keyword)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { [weak self] completion in
                        switch completion {
                        case .failure(let error):
                            print("Failed to search parrots: \(error)")
                            self?.errorMessage = error.localizedDescription
                        case .finished:
                            break
                        }
                    },
                    receiveValue: { [weak self] searchResults in
                        self?.parrots = searchResults
                        self?.applyFilters()
                    }
                )
                .store(in: &cancellables)
        }
    }
    
    func filterBySpecies(_ speciesId: Int?) {
        selectedSpecies = speciesId
        applyFilters()
    }
    
    func filterByGender(_ gender: String?) {
        selectedGender = gender
        applyFilters()
    }
    
    func addParrot(_ parrot: Parrot) {
        parrots.insert(parrot, at: 0)
        applyFilters()
    }
    
    func deleteParrot(_ parrotId: Int) async {
        dataService.deleteParrot(parrotId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .failure(let error):
                        print("Failed to delete parrot: \(error)")
                        self?.errorMessage = error.localizedDescription
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] success in
                    if success {
                        self?.parrots.removeAll { $0.id == parrotId }
                        self?.applyFilters()
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func refresh() async {
        await loadParrots()
        await loadSpecies()
    }
    
    private func applyFilters() {
        var filtered = parrots
        
        // Apply species filter
        if let speciesId = selectedSpecies {
            filtered = filtered.filter { $0.species == speciesId }
        }
        
        // Apply gender filter
        if let gender = selectedGender {
            filtered = filtered.filter { $0.gender == gender }
        }
        
        // Sort by displayName (handles optional name)
        filtered.sort { $0.displayName < $1.displayName }
        
        filteredParrots = filtered
    }
}
