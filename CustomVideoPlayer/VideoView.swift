//
//  VideoView.swift
//  CustomVideoPlayer
//
//  Created by FS on 2024/1/16.
//

import SwiftUI
import AVKit

struct VideoView: View {
    var player: AVPlayer?
    
    @GestureState private var isForcePressing = false
    @State private var showControl = false
    @State private var isPlaying = false
    @State private var isFinishedPlaying = false
    
    @GestureState private var isDragging = false
    @State private var progress: CGFloat = 0
    @State private var lastDraggedProgress: CGFloat = 0
    
    @State private var timeoutTask: DispatchWorkItem?
    
    @State private var playerStatusObserver: NSKeyValueObservation?
    @State private var thunbnailFrames: [UIImage] = []
    @State private var draggingImage: UIImage?
    
    init(videoUrl: String) {
        if let url = URL(string: videoUrl) {
            self.player = AVPlayer(url: url)
        }
    }
    
    var body: some View {
        ZStack {
            if let player = player {
                CustomVideoPlayer(player: player)
                    .ignoresSafeArea()
                    .overlay {
                        control
                    }
                    .overlay(alignment: .bottom) {
                        if isDragging {
                            thumbnailView
                        }
                    }
                    .overlay(alignment: .bottom) {
                        videoSeekerView
                    }
                    .onTapGesture {
                        withAnimation {
                            showControl.toggle()
                            
                            if isPlaying {
                                scheduleControl()
                            }
                        }
                    }
                    .gesture(
                        LongPressGesture(minimumDuration: 1)
                            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .local))
                            .updating($isForcePressing, body: { value, state, _ in
                                switch value {
                                case .second(true, _):
                                    state = true
                                    if isPlaying {
                                        player.rate = 5
                                    }
                                default: break
                                }
                            })
                            .onEnded({ _ in
                                if isPlaying {
                                    player.rate = 1
                                }
                            })
                    )
            }
        
        }
        .onChange(of: progress, { oldValue, newValue in
            if newValue != 1 {
                isFinishedPlaying = false
            }
        })
        .onAppear {
            player?.addPeriodicTimeObserver(forInterval: .init(seconds: 1, preferredTimescale: 600), queue: .main, using: { _ in
                if let currentPlayItem = player?.currentItem {
                    let totalDuration = currentPlayItem.duration.seconds
                    guard let currentDuration = player?.currentTime().seconds else {
                        return
                    }
                    
                    let calculatedProgress = currentDuration / totalDuration
                    
                    if !isDragging {
                        progress = calculatedProgress
                        lastDraggedProgress = progress
                    }
                    
                    if calculatedProgress == 1 {
                        withAnimation(.easeIn(duration: 0.35)) {
                            isFinishedPlaying = true
                            isPlaying = false
                            showControl = true
                        }
                    }
                }
                
            })
            
            playerStatusObserver = player?.observe(\.status, options: .new, changeHandler: { player, _ in
                if player.status == .readyToPlay {
                    generateThumbnailFrames()
                }
            })
        }
        .onDisappear {
            playerStatusObserver?.invalidate()
        }
    }
    
    @ViewBuilder
    var thumbnailView: some View {
        let thumbSize: CGSize = .init(width: 175, height: 235)
        
        ZStack {
            Group {
                if let draggingImage {
                    Image(uiImage: draggingImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: thumbSize.width, height: thumbSize.height)
                        .clipped()
                } else {
                    RoundedRectangle(cornerRadius: 0)
                        .fill(.black)
                }
            }
            .clipShape(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(.white, lineWidth: 2)
            }
            .overlay(alignment: .bottom) {
                if let currentItem = player?.currentItem {
                    Text(CMTime(seconds: progress * currentItem.duration.seconds, preferredTimescale: 600).toString())
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .offset(y: 25)
                }
            }
        }
        .frame(width: thumbSize.width, height: thumbSize.height)
        .offset(y: -60)
    }
    
    var control: some View {
        ZStack {
            if isDragging || showControl {
                Rectangle()
                    .fill(.black.opacity(0.4))
            }
            
            if showControl {
                Button {
                    if isFinishedPlaying {
                        isFinishedPlaying = false
                        player?.seek(to: .zero)
                        progress = .zero
                        lastDraggedProgress = .zero
                        isPlaying = true
                        player?.play()
                        scheduleControl()
                    } else if isPlaying {
                        player?.pause()
                        isPlaying.toggle()
                        timeoutTask?.cancel()
                    } else {
                        player?.play()
                        isPlaying.toggle()
                        scheduleControl()
                    }
                } label: {
                    Image(systemName: isFinishedPlaying ? "arrow.clockwise" : (
                        isPlaying ? "pause.fill" : "play.fill"
                    ))
                        .contentTransition(.symbolEffect(.replace))
                        .font(.title)
                        .foregroundStyle(.white)
                        .padding()
                }
            }
        }
    }
    
    var videoSeekerView: some View {
        ZStack(alignment: .leading) {
            Rectangle()
                .fill(.white.opacity(0.3))
            
            
            Rectangle()
                .fill(.white)
                .frame(width: UIScreen.main.bounds.width * progress)
        }
        .frame(height: 3)
        .overlay(alignment: .leading) {
            Circle()
                .fill(.white.opacity(isDragging || showControl ? 1 : 0))
                .frame(width: 15, height: 15)
                .frame(width: 50, height: 50)
                .contentShape(/*@START_MENU_TOKEN@*/Circle()/*@END_MENU_TOKEN@*/)
                .offset(x: -25)
                .offset(x: UIScreen.main.bounds.width * progress)
                .gesture(
                    DragGesture()
                        .updating($isDragging, body: { _, state, _ in
                            state = true
                        })
                        .onChanged({ value in
                            timeoutTask?.cancel()
                            
                            let calculatedProgress = value.translation.width / UIScreen.main.bounds.width + lastDraggedProgress
                            progress = max(min(1, calculatedProgress), 0)
                            
                            let dragIndex = Int(progress / 0.01)
                            if thunbnailFrames.indices.contains(dragIndex) {
                                draggingImage = thunbnailFrames[dragIndex]
                            }
                        })
                        .onEnded({ value in
                            lastDraggedProgress = progress
                            
                            if let currentPlayItem = player?.currentItem {
                                let totalDuration = currentPlayItem.duration.seconds
                                
                                player?.seek(to: .init(seconds: totalDuration * progress, preferredTimescale: 600))

                            }
                            
                            if isPlaying {
                                scheduleControl()
                            }
                        })
                )
        }
    }
    
    func scheduleControl() {
        if let timeoutTask {
            timeoutTask.cancel()
        }
        
        timeoutTask = .init(block: {
            withAnimation(.easeIn(duration: 0.35)) {
                showControl = false
            }
        })
        
        if let timeoutTask {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: timeoutTask)
        }
    }
    
    func generateThumbnailFrames() {
        Task.detached {
            guard let asset = player?.currentItem?.asset else {
                return
            }
            
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = .init(width: 250, height: 250)

            do {
                let totalDuration = try await asset.load(.duration).seconds
                var frameTimes: [CMTime] = []
                
                for progress in stride(from: 0, to: 1, by: 0.01) {
                    let time = CMTime(seconds: progress * totalDuration, preferredTimescale: 600)
                    frameTimes.append(time)
                }
                
                for await result in generator.images(for: frameTimes) {
                    let cgImage = try result.image
                    await MainActor.run {
                        thunbnailFrames.append(UIImage(cgImage: cgImage))
                    }
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}

#Preview {
    ContentView()
}
