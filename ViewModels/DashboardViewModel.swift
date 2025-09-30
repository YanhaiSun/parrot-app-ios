//
//  DashboardViewModel.swift
//  parrot
//
//  Created by sunyanhai on 2025/9/26.
//

import Foundation
import SwiftUI
import Combine

struct DashboardActivity: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let time: String
}

struct OccupancyData {
    let location: String
    let occupancyRate: Double
}

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var totalCages = 0
    @Published var totalParrots = 0
    @Published var averageOccupancy = 0.0
    @Published var emptyCages = 0
    @Published var occupancyData: [OccupancyData] = []
    @Published var recentActivities: [DashboardActivity] = []
    @Published var isLoading = false
    
    private let dataService = DataService.shared
    private var cancellables = Set<AnyCancellable>()
    
    func loadData() async {
        isLoading = true
        
        // Load data concurrently
        let cagesPublisher = dataService.fetchAllCages()
        let parrotsPublisher = dataService.fetchAllParrots()
        
        // Handle cages data
        cagesPublisher
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        print("[loadData()]Failed to load cages data: \(error)")
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] cages in
                    self?.processCagesData(cages)
                }
            )
            .store(in: &cancellables)
        
        // Handle parrots data
        parrotsPublisher
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        print("Failed to load parrots data: \(error)")
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] parrotsResponse in
                    self?.totalParrots = parrotsResponse.total
                }
            )
            .store(in: &cancellables)
        
        
        // Set loading to false after a short delay to allow network requests to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isLoading = false
        }
    }
    
    func refresh() async {
        await loadData()
    }
    
    private func processCagesData(_ cages: [Cage]) {
        totalCages = cages.count
        emptyCages = cages.filter { $0.parrotCountInt == 0 }.count
        
        // Calculate average occupancy
        let totalCapacity = cages.reduce(0) { $0 + $1.capacity }
        let totalParrotsInCages = cages.reduce(0) { $0 + $1.parrotCountInt }
        
        if totalCapacity > 0 {
            averageOccupancy = Double(totalParrotsInCages) / Double(totalCapacity)
        }
        
        // Group by location for chart
        let groupedCages = Dictionary(grouping: cages) { $0.location }
        
        occupancyData = groupedCages.map { location, cages in
            let locationCapacity = cages.reduce(0) { $0 + $1.capacity }
            let locationParrots = cages.reduce(0) { $0 + $1.parrotCountInt }
            let occupancyRate = locationCapacity > 0 ? Double(locationParrots) / Double(locationCapacity) : 0.0
            
            return OccupancyData(location: "区域\(location)", occupancyRate: occupancyRate)
        }
        .sorted { $0.location < $1.location }
    }
    
}
