//
//  BoxesOverview.swift
//  thousand
//
//  Created by Fatih Sağlam on 18.11.2024.
//

import SwiftUI

struct BoxesOverview: View {
    let boxLabels: [LocalizedStringKey]
    let progress: [Int]
    let buttonAction: () -> Void
    var body: some View {
        VStack {
            Spacer()
            VStack {
                ForEach(progress.indices, id: \.self) { index in
                    VStack(alignment: .leading) {
                        Text(boxLabels[index])
                            .font(.headline)
                        HStack {
                            Text(LocalizedStringKey("\(progress[index]) cards"))
                                .font(.subheadline)
                                    Spacer()
                            ProgressView(value: Float(progress[index]), total: 1000)
                                .frame(width: 200)
                        }
                        .padding(.vertical, 5)
                    }
                }
            }
            .padding()
            
            Spacer()
            
            Button(action: {
                buttonAction()
            }) {
                Image(systemName: "arrow.right")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(Circle().fill(Color.blue))
            }
        }
    }
}

#Preview {
    BoxesOverview(
        boxLabels: ["Box 1", "Box 2", "Box 3", "Box 4", "Box 5"],
        progress: [900, 500, 250, 10, 0],
        buttonAction: { }
    )
}
