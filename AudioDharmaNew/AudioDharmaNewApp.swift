//
//  AudioDharmaNewApp.swift
//  AudioDharmaNew
//
//  Created by Christopher on 9/1/21.
//

import SwiftUI


@main
struct AudioDharmaNewApp: App {
    
    init() {
/*
        TheDataModel.loadAllData()
        print("Model Loading")
        ModelLoadedSemaphore.wait()
        print("Model Loaded")
 */

    }

    var body: some Scene {
        WindowGroup {
            TalkPlayerView(talk: SelectedTalk)
        }
    }
}
