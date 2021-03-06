//
//  TalkPlayer.swift
//
//  Lower-level code to drive the audio playback.  Controlled by TalkPlayerView
//
//  Created by Christopher Minson on 9/4/21.
//  Copyright © 2022 Christopher Minson. All rights reserved.
//
import Foundation
import UIKit
import AVFoundation
import CoreMedia


var TalkList : [TalkData]!
var TalkTimer : Timer?
let FAST_SEEK : Int64 = 25  // number of seconds to move for each Seek operation

class TalkPlayer : NSObject {
    
    var talkPlayerView: TalkPlayerView!
    var Player : AVPlayer = AVPlayer()
    var PlayerItem : AVPlayerItem?
    

    func startTalk(talkURL: URL, startAtTime: Double){
        
        PlayerItem  = AVPlayerItem(url: talkURL)
        Player =  AVPlayer(playerItem : PlayerItem)
        Player.allowsExternalPlayback = true
        
        // get notification once talk ends
        NotificationCenter.default.addObserver(self,selector:
                        #selector(self.talkHasCompleted),
                        name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                        object: PlayerItem)

        Player.seek(to: CMTimeMake(value: Int64(startAtTime), timescale: 1))
        self.play()
    }
    
    
    func verifyURL (urlString: String?) -> Bool {
        
        if let urlString = urlString {
            if let url = URL(string: urlString) {
                return UIApplication.shared.canOpenURL(url as URL)
            }
        }
        return false
    }
    
    
    func play() {
        
        Player.play()
        startTalkTimer()
    }
        
    
    func stop() {
        
        Player.pause()
        Player.seek(to: CMTime.zero)
        stopTalkTimer()
    }
    
    
    func pause() {
        
        Player.pause()
        stopTalkTimer()
    }

    
    func startTalkTimer() {

            // stop  previous timer, if any
            stopTalkTimer()

            // start a new timer.  this calls a method to update the views once each second
            TalkTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timerUpdate), userInfo: nil, repeats: true)
    }

    
    func stopTalkTimer(){

        if let timer = TalkTimer {

            timer.invalidate()
            TalkTimer = nil
        }
    }
    
    
    @objc func timerUpdate() {
        
        // invoked every second.  inform parent view
         talkPlayerView.updateView()
    }
    
    
    @objc func talkHasCompleted() {
        
        stopTalkTimer()
        talkPlayerView.talkHasCompleted()
    }
    
    
    func seekToTime(seconds: Int64) {
        
        Player.seek(to: CMTimeMake(value: seconds, timescale: 1))
    }
    
    
    func seekFastForward() -> Double {
        
        var seekEndPoint: Int64 = 0
        
        if let ct = PlayerItem?.currentTime(), let dt = Player.currentItem?.asset.duration {
            let currentTimeInSeconds = Int64(CMTimeGetSeconds(ct))
            let durationTimeInSeconds = Int64(CMTimeGetSeconds(dt))
            
            if currentTimeInSeconds + FAST_SEEK < durationTimeInSeconds {
                seekEndPoint = currentTimeInSeconds + FAST_SEEK

            } else {
                seekEndPoint = durationTimeInSeconds
            }
            
            Player.seek(to: CMTimeMake(value: seekEndPoint, timescale: 1))

        }
        
        if getCurrentTimeInSeconds() >= getDurationInSeconds() {
            talkHasCompleted()
        }
        
        return Double(seekEndPoint)

    }
    
    
    func seekFastBackward() -> Double {
        
        var seekEndPoint: Int64 = 0

        if let ct = PlayerItem?.currentTime() {
            let currentTimeInSeconds = Int64(CMTimeGetSeconds(ct))
            
            if currentTimeInSeconds - FAST_SEEK > Int64(0) {
                seekEndPoint = currentTimeInSeconds - FAST_SEEK
                
            } else {
                seekEndPoint = 0
            }
            
            Player.seek(to: CMTimeMake(value: seekEndPoint, timescale: 1))
        }
        
        return Double(seekEndPoint)
    }
    
     
    func convertSecondsToDisplayString(timeInSeconds: Int) -> String {
        
        let seconds = Int(timeInSeconds) % 60
        let minutes = (Int(timeInSeconds) / 60) % 60
        let hours = (Int(timeInSeconds) / 3600) % 3600

        return String(format: "%0.2d:%0.2d:%0.2d",hours,minutes,seconds)
    }
    
    
    func getCurrentTimeInSeconds() -> Int {
        
        var time : Int = 0

        if let ct = PlayerItem?.currentTime()  {
            time = Int(CMTimeGetSeconds(ct))
        }
        return time
    }
    
    
    func getDurationInSeconds() -> Int {
        
        var time : Int = 0
        
        if let ct = PlayerItem?.duration {
            if CMTIME_IS_INDEFINITE(ct) == false {
                time = Int(CMTimeGetSeconds(ct))
            }
        }
        return time
    }
       
}
