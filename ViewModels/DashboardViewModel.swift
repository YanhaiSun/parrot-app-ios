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
        
        // 使用 CombineLatest 同时监听两个数据源
        let combinedPublisher = Publishers.CombineLatest(
            dataService.fetchAllCages(),
            dataService.fetchAllParrots()
        )
        
        combinedPublisher
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        print("数据加载失败: \(error)")
                    }
                },
                receiveValue: { [weak self] (cages, parrotsResponse) in
                    self?.processCagesData(cages)
                    self?.totalParrots = parrotsResponse.total
                }
            )
            .store(in: &cancellables)
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
