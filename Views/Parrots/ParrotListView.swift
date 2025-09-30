//
//  ParrotListView.swift
//  parrot
//
//  Created by sunyanhai on 2025/9/26.
//

import SwiftUI

struct ParrotListView: View {
    @StateObject private var viewModel = ParrotListViewModel()
    @State private var showingAddParrot = false
    @State private var showingSearchFilter = false
    @State private var searchText = ""
    @State private var selectedSpecies = 0
    @State private var selectedGender = "全部"
    
    private let genders = ["全部", "公", "母", "未知"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Active filter indicator
                if !searchText.isEmpty || selectedGender != "全部" || selectedSpecies != 0 {
                    activeFilterBanner
                }
                
                // Content
                if viewModel.isLoading && viewModel.parrots.isEmpty {
                    loadingView
                } else if viewModel.parrots.isEmpty {
                    emptyStateView
                } else {
                    parrotListContent
                }
            }
//            .navigationTitle("鹦鹉管理")
//            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        // Search and filter button
                        Button {
                            showingSearchFilter = true
                        } label: {
                            Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                                .font(.title2)
                                .foregroundColor(hasActiveFilters ? .blue : .primary)
                        }
                        
                        // Add button
                        Button {
                            showingAddParrot = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddParrot) {
//                AddParrotView { newParrot in
//                    viewModel.addParrot(newParrot)
//                }
            }
            .sheet(isPresented: $showingSearchFilter) {
                SearchFilterView(
                    searchText: $searchText,
                    selectedSpecies: $selectedSpecies,
                    selectedGender: $selectedGender,
                    species: viewModel.species,
                    genders: genders,
                    onApply: {
                        viewModel.searchParrots(keyword: searchText)
                        showingSearchFilter = false
                    },
                    onReset: {
                        searchText = ""
                        selectedSpecies = 0
                        selectedGender = "全部"
                        viewModel.searchParrots(keyword: "")
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await viewModel.loadParrots()
                await viewModel.loadSpecies()
            }
            .alert("错误", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("确定") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
    
    private var hasActiveFilters: Bool {
        !searchText.isEmpty || selectedGender != "全部" || selectedSpecies != 0
    }
    
    private var activeFilterBanner: some View {
        HStack {
            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                .foregroundColor(.blue)
            
            Text("筛选已启用")
                .font(.subheadline)
                .foregroundColor(.blue)
            
            Spacer()
            
            Button("清除") {
                searchText = ""
                selectedSpecies = 0
                selectedGender = "全部"
                viewModel.searchParrots(keyword: "")
            }
            .font(.subheadline)
            .foregroundColor(.blue)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.blue.opacity(0.1))
    }
    
    private var loadingView: some View {
        VStack {
            Spacer()
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                
                Text("加载中...")
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
    }
    
    private var emptyStateView: some View {
        VStack {
            Spacer()
            VStack(spacing: 20) {
                Image(systemName: "bird")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary)
                
                VStack(spacing: 8) {
                    Text("没有找到鹦鹉")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("点击右上角的 + 按钮添加新鹦鹉")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Button("添加鹦鹉") {
                    showingAddParrot = true
                }
                .buttonStyle(.borderedProminent)
            }
            Spacer()
        }
        .padding(.horizontal, 40)
    }
    
    private var parrotListContent: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(viewModel.filteredParrots) { parrot in
                    ParrotCardView(
                        parrot: parrot,
                        species: viewModel.species.first { $0.id == parrot.species }?.name ?? "未知品种"
                    ) { action in
                        handleParrotAction(action, for: parrot)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 100)
            
            if viewModel.hasMorePages && !viewModel.isLoading {
                Button("加载更多") {
                    Task {
                        await viewModel.loadMoreParrots()
                    }
                }
                .buttonStyle(.bordered)
                .padding()
            }
            
            if viewModel.isLoading && !viewModel.parrots.isEmpty {
                ProgressView()
                    .padding()
            }
        }
    }
    
    private func handleParrotAction(_ action: ParrotCardAction, for parrot: Parrot) {
        switch action {
        case .viewDetails:
            // Navigate to parrot details
            break
        case .edit:
            // Navigate to edit parrot
            break
        case .delete:
            Task {
                await viewModel.deleteParrot(parrot.id)
            }
        }
    }
}

// MARK: - Search Filter View
struct SearchFilterView: View {
    @Binding var searchText: String
    @Binding var selectedSpecies: Int
    @Binding var selectedGender: String
    let species: [Species]
    let genders: [String]
    let onApply: () -> Void
    let onReset: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("搜索脚环号、名称...", text: $searchText)
                        
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("搜索")
                }
                
                Section {
                    Picker("品种", selection: $selectedSpecies) {
                        Text("全部品种").tag(0)
                        ForEach(species) { spec in
                            Text(spec.name).tag(spec.id)
                        }
                    }
                    
                    Picker("性别", selection: $selectedGender) {
                        ForEach(genders, id: \.self) { gender in
                            Text(gender).tag(gender)
                        }
                    }
                } header: {
                    Text("筛选条件")
                }
            }
            .navigationTitle("搜索与筛选")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("重置") {
                        onReset()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("应用") {
                        onApply()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Parrot Card View
struct ParrotCardView: View {
    let parrot: Parrot
    let species: String
    let onAction: (ParrotCardAction) -> Void
    
    @State private var showingActionSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(parrot.displayName)
                        .font(.headline)
                        .fontWeight(.bold)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Button {
                    showingActionSheet = true
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
            
            // Species and gender
            HStack(spacing: 12) {
                Label(species, systemImage: "bird.fill")
                    .font(.caption)
                    .foregroundColor(.green)
                
                Label(parrot.gender, systemImage: genderIcon(for: parrot.gender))
                    .font(.caption)
                    .foregroundColor(genderColor(for: parrot.gender))
            }
            
            // Age and cage info
            VStack(alignment: .leading, spacing: 4) {
                
                if let cageId = parrot.cageId {
                    HStack {
                        Image(systemName: "building.2")
                            .foregroundColor(.secondary)
                        Text("笼子 \(cageId)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        Text("未分配笼子")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            // Action buttons
            HStack(spacing: 8) {
                Button {
                    onAction(.viewDetails)
                } label: {
                    Label("详情", systemImage: "info.circle")
                        .font(.caption2)
                        .lineLimit(1)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button {
                    onAction(.edit)
                } label: {
                    Label("编辑", systemImage: "pencil")
                        .font(.caption2)
                        .lineLimit(1)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding()
        .cardEffect()

        .confirmationDialog("鹦鹉操作", isPresented: $showingActionSheet) {
            Button("查看详情") { onAction(.viewDetails) }
            Button("编辑信息") { onAction(.edit) }
            Button("删除", role: .destructive) { onAction(.delete) }
            Button("取消", role: .cancel) { }
        }
    }
    
    private func genderIcon(for gender: String) -> String {
        switch gender {
        case "公":
            return "arrow.up.circle"
        case "母":
            return "arrow.down.circle"
        default:
            return "questionmark.circle"
        }
    }
    
    private func genderColor(for gender: String) -> Color {
        switch gender {
        case "公":
            return .blue
        case "母":
            return .pink
        default:
            return .gray
        }
    }
}

enum ParrotCardAction {
    case viewDetails
    case edit
    case delete
}

#Preview {
    ParrotListView()
}
