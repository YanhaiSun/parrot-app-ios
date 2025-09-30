import SwiftUI
import Combine

struct EditParrotView: View {
    @State private var editedParrot: Parrot  // 改为可变状态
    let onComplete: (Parrot) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    // 修改初始化方法
    init(parrot: Parrot, onComplete: @escaping (Parrot) -> Void) {
        self._editedParrot = State(initialValue: parrot)
        self.onComplete = onComplete
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    // 脚环号（可编辑）
                    HStack {
                            Text("脚环号")
                            Spacer()
                            TextField("", text: $editedParrot.ringNumber)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing) // 文本右对齐
                                .frame(width: 150) // 限制宽度
                        }
                    
                    // 性别选择
                    Picker("性别", selection: $editedParrot.gender) {
                        Text("公").tag("公")
                        Text("母").tag("母")
                    }
                }
                
                Section {
                    Button("保存更改") {
                        onComplete(editedParrot)
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("编辑鹦鹉信息")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
}
