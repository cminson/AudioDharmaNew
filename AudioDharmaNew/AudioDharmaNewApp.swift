//
//  AudioDharmaNewApp.swift
//
//  App entry point. Set globals then bring up RootView.
//  Rootview will load model data and proceed to main U>
//
//  Created by Christopher Minson on 9/1/21.
//  Copyright © 2022 Christopher Minson. All rights reserved.
//

import SwiftUI
import AVFoundation
import BackgroundTasks



@main
struct AudioDharmaNewApp: App {
    
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    init() {
        
        NewTalksAvailable = true    // forces initiali Model load in RootView
        AppColorScheme = colorScheme    //  all other views know how to adapt to dark or light mode
        configureAudioForBackground()   //  audio will continue to play when app isn't current
    }
    
    
    // necessary to allow background playing of audio
    func configureAudioForBackground() {
        
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

            RootView()
         }
    }
}


  
