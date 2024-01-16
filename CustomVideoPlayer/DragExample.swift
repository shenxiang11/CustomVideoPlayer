//
//  DragExample.swift
//  CustomVideoPlayer
//
//  Created by FS on 2024/1/16.
//

import SwiftUI

struct DragExample: View {
    @State private var position: CGSize = .zero
    @State private var lastPosition: CGSize = .zero
    @GestureState private var isDragging = false
    
    var body: some View {
        ZStack {
            Circle()
                .frame(width: 50, height: 50)
                .offset(position)
                .gesture(
                    DragGesture()
                        .updating($isDragging, body: { _, state, _ in
                            state = true
                        })
                        .onChanged { gesture in
                            // 拖拽手势进行中
                            self.position.width = gesture.translation.width + lastPosition.width
                            self.position.height = gesture.translation.height + lastPosition.height
                        }
                        .onEnded { gesture in
                            // 拖拽手势结束
                            self.lastPosition = self.position
                        }
                )
            
            Text("x: \(position.width), y: \(position.height), isDragging: \(isDragging ? "true" : "false")")
                .foregroundStyle(.red)
        }
        
    }
}

#Preview {
    DragExample()
}
