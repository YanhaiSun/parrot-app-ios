import SwiftUI
import Combine

struct AddParrotView: View {
    let cage: Cage
    let speciesName: String
    let onComplete: (Parrot) -> Void
    
    @State private var ringNumber = ""
    @State private var gender = "公"
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    @State private var cancellables = Set<AnyCancellable>()  // 关键修改：添加 @State
    
    @Environment(\.dismiss) private var dismiss
    
    public init(cage: Cage, speciesName: String, onComplete: @escaping (Parrot) -> Void) {
        self.cage = cage
        self.speciesName = speciesName
        self.onComplete = onComplete
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本信息")) {
                    // 笼子信息行
                    HStack {
                        Text("笼子")
                        Spacer()
                        Text("\(speciesName)-\(cage.cageCode)")
                            .foregroundColor(.secondary)
                    }
                    
                    // 品种信息行
                    HStack {
                        Text("品种")
                        Spacer()
                        Text(speciesName)
                            .foregroundColor(.secondary)
                    }
                    
                    // 脚环号输入行
                    HStack {
                        Text("脚环号")
                        Spacer()
                        TextField("输入脚环号", text: $ringNumber)
                            .multilineTextAlignment(.trailing) // 右对齐文本
                            .frame(maxWidth: 150) // 限制宽度避免过长
                    }
                    
                    // 性别选择行
                    HStack {
                        Text("性别")
                        Spacer()
                        Picker("", selection: $gender) {
                            Text("公").tag("公")
                            Text("母").tag("母")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(maxWidth: 150) // 限制选择器宽度
                    }
                }
                
                
                // 错误信息显示
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("添加鹦鹉")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Button("保存") {
                            createParrot()
                        }
                        .disabled(ringNumber.isEmpty)
                    }
                }
            }
        }
    }
    
    private func createParrot() {
        isLoading = true
        errorMessage = nil
        
        let request = CreateParrotRequest(
            ringNumber: ringNumber,
            species: cage.speciesId ?? 0,
            gender: gender,
            age: nil,
            cageId: cage.id
        )
        
        DataService.shared.createParrot(request)
                    .receive(on: DispatchQueue.main)
                    .sink(
                        receiveCompletion: { completion in
                            self.isLoading = false
                            switch completion {
                            case .failure(let error):
                                self.errorMessage = error.localizedDescription
                            case .finished:
                                break
                            }
                        },
                        receiveValue: { success in
                            if success {
                                let newParrot = Parrot(
                                    id: 0,
                                    ringNumber: self.ringNumber,
                                    species: self.cage.speciesId ?? 0,
                                    gender: self.gender,
                                    age: nil,
                                    cageId: self.cage.id,
                                    createdAt: ISO8601DateFormatter().string(from: Date())
                                )
                                self.onComplete(newParrot)
                                self.dismiss()
                            } else {
                                self.errorMessage = "创建鹦鹉失败"
                            }
                        }
                    )
                    .store(in: &cancellables)
            }
}
