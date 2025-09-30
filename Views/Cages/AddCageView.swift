//
//  AddCageView.swift
//  parrot
//
//  Created by sunyanhai on 2025/9/26.
//

import SwiftUI
import Combine

struct AddCageView: View {
    @StateObject private var viewModel = CageListViewModel()

    @Environment(\.presentationMode) var presentationMode
    @State private var cageCode = ""
    @State private var selectedSpecies: Species?
    @State private var capacity = ""
    let onComplete: (Cage) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("笼子信息")) {
                    TextField("笼子编号", text: $cageCode)
                    
                    Picker("品种", selection: $selectedSpecies) {
                        Text("请选择品种").tag(nil as Species?)
                        ForEach(viewModel.species) { species in
                            Text(species.name).tag(species as Species?)
                        }
                    }
                    
                    TextField("容量", text: $capacity)
                        .keyboardType(.numberPad)
                }
                
                Section {
                    Button("添加笼子") {
                        addCage()
                    }
                    .disabled(cageCode.isEmpty || selectedSpecies == nil || capacity.isEmpty)
                }
            }
            .navigationTitle("添加新笼子")
            .navigationBarItems(trailing: Button("取消") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func addCage() {
        guard let species = selectedSpecies,
              let capacityValue = Int(capacity) else {
            return
        }
        
        let newCage = Cage(
            id: 0, // 临时ID，实际由后端生成
            cageCode: cageCode,
            location: "\(species.id)",
            capacity: capacityValue,
            createdAt: Date().ISO8601Format(),
            parrotCount: "0"
        )
        
        onComplete(newCage)
        presentationMode.wrappedValue.dismiss()
    }
}
#Preview {
    AddCageView { cage in
        print("Added cage: \(cage)")
    }
}
