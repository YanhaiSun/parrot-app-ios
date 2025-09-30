import SwiftUI
import Combine

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @StateObject private var cageModel = CageListViewModel()
    
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            Group {
                if searchText.isEmpty {
                    emptySearchState
                } else if viewModel.isLoading {
                    loadingView
                } else if viewModel.searchResults.isEmpty {
                    noResultsView
                } else {
                    searchResultsView
                }
            }
            .navigationTitle("搜索鹦鹉")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "输入脚环号搜索鹦鹉"
            )
            .onSubmit(of: .search) {
                performSearch()
            }
            .onChange(of: searchText) { newValue in
                if newValue.isEmpty {
                    viewModel.clearResults()
                }
            }
            
            // 最近搜索记录
            if !viewModel.recentSearches.isEmpty && searchText.isEmpty {
                List {
                    Section("最近搜索") {
                        ForEach(viewModel.recentSearches, id: \.self) { recent in
                            Button {
                                searchText = recent
                                performSearch()
                            } label: {
                                HStack {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .foregroundColor(.secondary)
                                    Text(recent)
                                    Spacer()
                                }
                            }
                            .foregroundColor(.primary)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
    }
    
    private var emptySearchState: some View {
        VStack {
            Spacer()
            VStack(spacing: 24) {
                // 搜索插图
                ZStack {
                    Circle()
                        .fill(.blue.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    VStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                        
                        Image(systemName: "bird.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.green)
                            .offset(x: 15, y: -10)
                    }
                }
                
                VStack(spacing: 12) {
                    Text("搜索鹦鹉信息")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    VStack(spacing: 8) {
                        Text("输入脚环号快速找到鹦鹉")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Text("支持模糊搜索，会显示笼子信息")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .multilineTextAlignment(.center)
                }
                
                // 搜索提示
                VStack(alignment: .leading, spacing: 12) {
                    Text("搜索提示")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        SearchTipRow(icon: "tag.fill", text: "输入完整脚环号获得精确结果")
                        SearchTipRow(icon: "textformat.abc", text: "支持部分字符模糊搜索")
                        SearchTipRow(icon: "building.2.fill", text: "搜索结果包含笼子位置信息")
                        SearchTipRow(icon: "clock.fill", text: "搜索历史会被自动保存")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
            }
            Spacer()
        }
        .padding(.horizontal, 32)
    }
    
    private var loadingView: some View {
        VStack {
            Spacer()
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                
                Text("搜索中...")
                    .foregroundColor(.secondary)
                
                Text("正在查找 \"\(searchText)\"")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
    }
    
    private var noResultsView: some View {
        VStack {
            Spacer()
            VStack(spacing: 20) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary)
                
                VStack(spacing: 8) {
                    Text("没有找到结果")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("没有找到脚环号包含 \"\(searchText)\" 的鹦鹉")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 8) {
                    Text("建议:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• 检查脚环号是否输入正确")
                        Text("• 尝试输入部分字符")
                        Text("• 确认该鹦鹉已录入系统")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 40)
    }
    
    private var searchResultsView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Results header
                HStack {
                    Text("搜索结果")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text("\(viewModel.searchResults.count) 个结果")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                
                // Results list
                ForEach(viewModel.searchResults, id: \.parrot.id) { result in
                    SearchResultCard(result: result)
                }
            }
            .padding(.vertical)
        }
    }
    
    private func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        Task {
            await viewModel.searchParrots(ring: searchText)
        }
    }
}

struct SearchTipRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.blue)
                .frame(width: 16)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

struct SearchResultCard: View {
    let result: ParrotWithCage
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Parrot info
            HStack(spacing: 16) {
                // Parrot avatar
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.parrot.displayName)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 8) {
                        Label(result.parrot.gender, systemImage: "bird")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Label(result.speciesWithCage, systemImage: "cube")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal, 16)
    }
}

#Preview {
    SearchView()
}
