//
//  AudioDharmaNewApp.swift
//
//  Created by Christopher Minson on 9/1/21.
//  Copyright © 2022 Christopher Minson. All rights reserved.
//

import SwiftUI
import AVFoundation
import BackgroundTasks

@main
struct AudioDharmaNewApp: App {
    
    init() {
        
        configureAudioForBackground()
    }
    
    
    // necessary to allow background playing of audio
    func configureAudioForBackground() {
        
        print("configureAudioForBackground")
        let audioSession = AVAudioSession.sharedInstance()
        do {
          try audioSession.setCategory(.playback, mode: .moviePlayback)
        }
        catch {
          print("Setting category to AVAudioSessionCategoryPlayback failed.")
        }
    }
    

        var body: some Scene {
        WindowGroup {
           SplashScreen()
        }
    }
}


  
