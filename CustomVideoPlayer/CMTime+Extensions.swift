//
//  CTTime+Extensions.swift
//  CustomVideoPlayer
//
//  Created by FS on 2024/1/16.
//

import AVKit

extension CMTime {
    func toString() -> String {
        let roundedSeconds = seconds.rounded()
        
        let hours: Int = Int(roundedSeconds / 3600)
        let min: Int = Int(roundedSeconds.truncatingRemainder(dividingBy: 3600) / 60)
        let sec: Int = Int(roundedSeconds.truncatingRemainder(dividingBy: 60))
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, min, sec)
        }
        
        return String(format: "%02d:%02d", min, sec)
    }
}
