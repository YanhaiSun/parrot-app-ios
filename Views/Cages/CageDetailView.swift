import SwiftUI

struct CageDetailView: View {
    let cage: Cage
    let speciesName: String?
    let allCages: [Cage]
    @Binding var navigationPath: NavigationPath
    
    @StateObject private var viewModel: CageDetailViewModel
    @State private var showingAddParrot = false
    @State private var editingParrot: Parrot?
    @State private var parrotToDelete: Parrot?
    
    init(cage: Cage, speciesName: String?, allCages: [Cage], navigationPath: Binding<NavigationPath>) {
        self.cage = cage
        self.speciesName = speciesName
        self.allCages = allCages
        self._navigationPath = navigationPath
        self._viewModel = StateObject(wrappedValue: CageDetailViewModel(cageId: cage.id))
    }
    
    private var currentIndex: Int? {
        allCages.firstIndex(where: { $0.id == cage.id })
    }
    
    private var previousCage: Cage? {
        guard let index = currentIndex, index > 0 else { return nil }
        return allCages[index - 1]
    }
    
    private var nextCage: Cage? {
        guard let index = currentIndex, index < allCages.count - 1 else { return nil }
        return allCages[index + 1]
    }
    
    // 提取删除确认alert为计算属性
    private var deleteConfirmationAlert: some View {
        EmptyView()
            .alert("确认删除", isPresented: .constant(parrotToDelete != nil)) {
                Button("取消", role: .cancel) {
                    parrotToDelete = nil
                }
                Button("删除", role: .destructive) {
                    if let parrot = parrotToDelete {
                        viewModel.deleteParrot(parrot)
                        parrotToDelete = nil
                    }
                }
            } message: {
                if let parrot = parrotToDelete {
                    Text("确定要删除 \(parrot.ringNumber) 吗？此操作无法撤销。")
                }
            }
    }
    
    var body: some View {
        List {
            Section {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                } else if viewModel.parrots.isEmpty {
                    emptyParrotsView
                } else {
                    ForEach(viewModel.parrots) { parrot in
                        ParrotRowView(parrot: parrot)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    parrotToDelete = parrot
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                                .tint(.red)
                                
                                Button {
                                    editingParrot = parrot
                                } label: {
                                    Label("编辑", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                    }
                }
            } header: {
                HStack {
                    Text("笼内鹦鹉")
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Text("\(viewModel.parrots.count)只")
                }
            }
        }
        .navigationTitle("\(speciesName ?? "未知品种") - \(cage.cageCode)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if let previousCage = previousCage {
                    Button {
                        navigateToCage(previousCage)
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.black)
                    }
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                if let nextCage = nextCage {
                    Button {
                        navigateToCage(nextCage)
                    } label: {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.black)
                    }
                }
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddParrot = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title2)
                }
            }
        }
        .sheet(isPresented: $showingAddParrot) {
            AddParrotView(
                cage: cage,
                speciesName: speciesName ?? "未知品种",
                onComplete: { newParrot in
                    viewModel.addParrot(newParrot)
                }
            )
        }
        .sheet(item: $editingParrot) { parrot in
            EditParrotView(parrot: parrot) { updatedParrot in
                viewModel.updateParrot(updatedParrot)
            }
        }
        .onAppear {
            viewModel.loadParrots()
        }
        .onChange(of: cage) { newCage in
            viewModel.switchToCage(newCage.id)
        }
        .alert("错误", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("确定") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .background(deleteConfirmationAlert) // 添加删除确认alert
    }
    
    private func navigateToCage(_ newCage: Cage) {
        viewModel.switchToCage(newCage.id)
        navigationPath.removeLast()
        navigationPath.append(newCage)
    }
    
    private var emptyParrotsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bird")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("笼子内没有鹦鹉")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("点击右上角的 + 按钮添加鹦鹉")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}
