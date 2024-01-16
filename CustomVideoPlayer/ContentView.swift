//
//  ContentView.swift
//  CustomVideoPlayer
//
//  Created by FS on 2024/1/16.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VideoView(videoUrl: "https://ios-demo.oss-cn-shanghai.aliyuncs.com/2024011602.mp4")
    }
}

#Preview {
    ContentView()
}
