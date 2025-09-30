//
//  SearchViewModel.swift
//  parrot
//
//  Created by sunyanhai on 2025/9/29.
//
import Foundation
import Combine

@MainActor
class SearchViewModel: ObservableObject {
    @Published var searchResults: [ParrotWithCage] = []
    @Published var recentSearches: [String] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let dataService = DataService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadRecentSearches()
    }
    
    func searchParrots(ring: String) async {
        isLoading = true
        errorMessage = nil
        
        dataService.searchParrotsWithCage(ring: ring)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    switch completion {
                    case .failure(let error):
                        self?.errorMessage = error.localizedDescription
                        self?.searchResults = []
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] results in
                    self?.searchResults = results
                    self?.saveRecentSearch(ring)
                }
            )
            .store(in: &cancellables)
    }
    
    func clearResults() {
        searchResults = []
        errorMessage = nil
    }
    
    private func saveRecentSearch(_ search: String) {
        var recent = recentSearches
        recent.removeAll { $0 == search }
        recent.insert(search, at: 0)
        
        if recent.count > 5 {
            recent = Array(recent.prefix(5))
        }
        
        recentSearches = recent
        UserDefaults.standard.set(recent, forKey: "recentSearches")
    }
    
    private func loadRecentSearches() {
        recentSearches = UserDefaults.standard.stringArray(forKey: "recentSearches") ?? []
    }
}
