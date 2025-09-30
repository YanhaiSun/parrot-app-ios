//
//  ParrotRowView.swift
//  parrot
//
//  Created by sunyanhai on 2025/9/29.
//

import SwiftUI

struct ParrotRowView: View {
    let parrot: Parrot
    
    var body: some View {
        HStack(spacing: 16) {
            // 鹦鹉头像
            VStack(alignment: .leading, spacing: 4) {
                Text(parrot.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                HStack(spacing: 6) {
                    Image(systemName: "bird")
                        .font(.caption2)
                    Text(parrot.gender)
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}
