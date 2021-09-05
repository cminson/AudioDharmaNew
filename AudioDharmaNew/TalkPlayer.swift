//
//  MP3Player.swift
//  AudioDharmaNew
//
//  Created by Christopher on 9/4/21.
//

import Foundation

import UIKit
import AVFoundation
import CoreMedia

let FAST_SEEK : Int64 = 25  // number of seconds to move for each Seek operation


class MP3Player : NSObject {
    
    // MARK: Properties
    //CJM
    //var Delegate: PlayTalkController!
    var Player : AVPlayer = AVPlayer()
    var PlayerItem : AVPlayerItem?
    
    // MARK: Init
    override init(){
        
        super.init()
    }
    
    
    // MARK: Functions
    func startTalk(talkURL: URL, startAtTime: Int){
        
        print("startTalk")
        print(talkURL)
        //let testURL = URL(string: "https://virtualdharma.org/AudioDharmaAppBackend/data/TALKS/20210826-Kim_Allen-IMC-the_depth_of_the_body_3_of_4_the_body_as_a_support_for_concentration.mp3")!
        //PlayerItem  = AVPlayerItem(url: testURL)
        PlayerItem  = AVPlayerItem(url: talkURL)
        Player =  AVPlayer(playerItem : PlayerItem)
        Player.allowsExternalPlayback = true
        
        // get notification once talk ends
        NotificationCenter.default.addObserver(self,selector:
                        #selector(self.talkHasCompleted),
                        name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                        object: PlayerItem)

        print("playing")

        Player.play()
        Player.seek(to: CMTimeMake(value: Int64(startAtTime), timescale: 1))
    
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
    }
    
    func stop() {
        
        Player.pause()
        Player.seek(to: CMTime.zero)
    }
    
    func pause() {
        
        Player.pause()
    }

    @objc func talkHasCompleted() {
        
        //print("Talk Completed")
        //CJM
        //Delegate.talkHasCompleted()     // inform our owner that a talk is done
    }
    
    func seekToTime(seconds: Int64) {
        
        Player.seek(to: CMTimeMake(value: seconds, timescale: 1))
    }
    
    func seekFastForward() {
        
        if let ct = PlayerItem?.currentTime(), let dt = Player.currentItem?.asset.duration {
            let currentTimeInSeconds = Int64(CMTimeGetSeconds(ct))
            let durationTimeInSeconds = Int64(CMTimeGetSeconds(dt))
            
            if currentTimeInSeconds + FAST_SEEK < durationTimeInSeconds {
                Player.seek(to: CMTimeMake(value: currentTimeInSeconds + FAST_SEEK, timescale: 1))

            } else {
                Player.seek(to: CMTimeMake(value: durationTimeInSeconds, timescale: 1))
            }
        }
    }
    
    func seekFastBackward() {
        
        if let ct = PlayerItem?.currentTime() {
            let currentTimeInSeconds = Int64(CMTimeGetSeconds(ct))
            
            if currentTimeInSeconds - FAST_SEEK > Int64(0) {
                Player.seek(to: CMTimeMake(value: currentTimeInSeconds - FAST_SEEK, timescale: 1))
                
            } else {
                Player.seek(to: CMTimeMake(value: 0, timescale: 1))
            }
        }
    }
    
    func currentTime()-> CMTime {
        
        return Player.currentTime()
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

    func getProgress()->Float {
        
        var theCurrentTime = 0.0
        var theCurrentDuration = 0.0
        
        let currentTime = CMTimeGetSeconds(Player.currentTime())
        
        if let ct = Player.currentItem?.asset.duration {
            let duration = CMTimeGetSeconds(ct)
            theCurrentTime = currentTime
            theCurrentDuration = duration
        }
        
        return Float(theCurrentTime / theCurrentDuration)
    }
       
}
