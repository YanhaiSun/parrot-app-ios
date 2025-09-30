//
//  DashboardView.swift
//  parrot
//
//  Created by sunyanhai on 2025/9/26.
//

import SwiftUI
import Charts

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    
                    // Quick stats in list format
                    statsListSection
                }
                .padding(.horizontal, 16)
                .padding(.top)
                .navigationBarTitle("\(greetingTitle), \(AuthManager.shared.currentUser ?? "管理员")", displayMode: .large)
            }
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.refresh()
            }
        }
        .task {
            await viewModel.loadData()
        }
    }
    
    private var greetingTitle: String {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 6..<12:
            return "上午好"
        case 12..<14:
            return "中午好"
        case 14..<18:
            return "下午好"
        case 18..<24:
            return "晚上好"
        case 0..<6:
            return "深夜好"
        default:
            return "你好"
        }
    }
    
    private var statsListSection: some View {
        VStack(spacing: 12) {
            // 平均占用率 - 带圆形进度条
            OccupancyStatRow(
                title: "笼子占用率",
                value: "\(Int(viewModel.averageOccupancy * 100))%",
                progress: viewModel.averageOccupancy,
                icon: "chart.pie",
                color: .orange,
                isLoading: viewModel.isLoading
            )
            
            // 总笼子数
            StatRow(
                title: "总笼子数",
                value: "\(viewModel.totalCages)",
                icon: "cube",
                color: .blue,
                isLoading: viewModel.isLoading
            )
            
            // 空笼数量
            StatRow(
                title: "空笼数量",
                value: "\(viewModel.emptyCages)",
                icon: "cube.transparent",
                color: .purple,
                isLoading: viewModel.isLoading
            )
            
            // 总鹦鹉数
            StatRow(
                title: "总鹦鹉数",
                value: "\(viewModel.totalParrots)",
                icon: "bird",
                color: .green,
                isLoading: viewModel.isLoading
            )
            
        }
    }
}

struct StatRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let isLoading: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if isLoading {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.gray.opacity(0.3))
                        .frame(width: 60, height: 24)
                } else {
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                        .contentTransition(.numericText())
                }
            }
            
            Spacer()
        }
        .padding()
        .cardEffect()
    }
}

struct OccupancyStatRow: View {
    let title: String
    let value: String
    let progress: Double
    let icon: String
    let color: Color
    let isLoading: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if isLoading {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.gray.opacity(0.3))
                        .frame(width: 60, height: 24)
                } else {
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                        .contentTransition(.numericText())
                }
            }
            
            Spacer()
            
            if !isLoading {
                ZStack {
                    Circle()
                        .stroke(
                            Color.gray.opacity(0.2),
                            lineWidth: 8
                        )
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            color,
                            style: StrokeStyle(
                                lineWidth: 8,
                                lineCap: .round
                            )
                        )
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: 40, height: 40)
            }
        }
        .padding()
        .cardEffect()
    }
}

#Preview {
    DashboardView()
        .environmentObject(AuthManager())
}
