import SwiftUI
import Shimmer

struct CageListView: View {
    @StateObject private var viewModel = CageListViewModel()
    @State private var showingAddCage = false
    @State private var searchText = ""
    @State private var selectedSpecies: Species? = nil
    @State private var navigationPath = NavigationPath()
    @State private var initialLoadCompleted = false // 新增：跟踪初始加载状态

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                // 内容区域
                if !initialLoadCompleted {
                    loadingView // 初始加载时显示加载视图
                } else {
                    cageContent // 加载完成后显示内容
                }
            }
//            .onAppear {
//                        // 重置加载状态
//                        if !initialLoadCompleted {
//                            Task {
//                                await viewModel.loadSpecies()
//                                if !viewModel.species.isEmpty {
//                                    selectedSpecies = viewModel.species.first
//                                    viewModel.loadCagesForSpecies(viewModel.species.first!.id)
//                                }
//                                initialLoadCompleted = true
//                            }
//                        }
//                    }
//            
            .navigationDestination(for: Cage.self) { cage in
                CageDetailView(
                    cage: cage,
                    speciesName: viewModel.species.first { $0.id == cage.speciesId }?.name,
                    allCages: viewModel.filteredCages,
                    navigationPath: $navigationPath
                )
            }
            .toolbar {
//                 左上角的品种选择器
                ToolbarItem(placement: .navigationBarLeading) {
                    speciesPicker
                }
                
                // 右上角的按钮
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddCage = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddCage) {
                AddCageView { newCage in
                    viewModel.addCage(newCage)
                }
            }
//            .refreshable {
//                await viewModel.refresh()
//            }
            .task {
                await viewModel.loadSpecies()
                if !viewModel.species.isEmpty {
                    selectedSpecies = viewModel.species.first
                    viewModel.loadCagesForSpecies(viewModel.species.first!.id)
                }
                initialLoadCompleted = true // 标记初始加载完成
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
    
    // 品种选择器
    private var speciesPicker: some View {
        Group {
            // 实际的品种选择器
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.species) { species in
                        Button {
                            selectedSpecies = species
                            Task {
                                viewModel.loadCagesForSpecies(species.id)
                            }
                        } label: {
                            Text(species.name)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedSpecies?.id == species.id ? Color.blue : Color.gray.opacity(0.2))
                                .foregroundColor(selectedSpecies?.id == species.id ? .white : .primary)
                                .cornerRadius(20)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
    }
    
    // 内容区域
    private var cageContent: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if viewModel.filteredCages.isEmpty {
                emptyStateView
            } else {
                cageGrid
            }
        }
    }
    
    private var loadingView: some View {
        ScrollView {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4),
                spacing: 12
            ) {
                // 模拟 12 个加载中的笼子卡片（3 行 x 4 列）
                ForEach(0..<50) { _ in
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 90)
                        .shimmering() // 添加闪烁动画
                }
            }
            .padding()
        }
    }
    
    private var emptyStateView: some View {
        VStack {
            Spacer()
            VStack(spacing: 20) {
                Image(systemName: "building.2")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary)
                
                VStack(spacing: 8) {
                    Text(selectedSpecies == nil ? "请先选择品种" : "该品种暂无笼子")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("点击右上角的 + 按钮添加新笼子")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Button("添加笼子") {
                    showingAddCage = true
                }
                .buttonStyle(.borderedProminent)
            }
            Spacer()
        }
        .padding(.horizontal, 40)
    }
    
    private var cageGrid: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                ForEach(viewModel.filteredCages) { cage in
                    Button {
                        navigationPath.append(cage)
                    } label: {
                        CageCardView(
                            cage: cage,
                            speciesList: viewModel.species
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
        }
    }
}

struct CageCardView: View {
    let cage: Cage
    let speciesName: String
    
    init(cage: Cage, speciesList: [Species]) {
        self.cage = cage
        self.speciesName = speciesList.first(where: { $0.id == cage.speciesId })?.name ?? "未知品种"
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text(speciesName)
                .font(.caption)
                .fontWeight(.semibold)
                .lineLimit(1)
                .foregroundColor(.primary)
            
            Text(cage.cageCode)
                .font(.subheadline)
                .fontWeight(.bold)
                .lineLimit(1)
                .foregroundColor(.primary)
            
            HStack(spacing: 4) {
                Image(systemName: "bird")
                    .font(.caption2)
                Text("\(cage.parrotCountInt)只")
                    .font(.caption2)
                    .fontWeight(.semibold)
            }
            .foregroundColor(cage.parrotCountInt > 0 ? .green : .secondary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .frame(height: 90)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct CageListView_Previews: PreviewProvider {
    static var previews: some View {
        CageListView()
    }
}
