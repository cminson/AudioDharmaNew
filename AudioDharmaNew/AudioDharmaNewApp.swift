//
//  AudioDharmaNewApp.swift
//
//  Created by Christopher Minson on 9/1/21.
//  Copyright © 2022 Christopher Minson. All rights reserved.
//

import SwiftUI


@main
struct AudioDharmaNewApp: App {
    
    init() {

        
        TheDataModel.loadAllData()
        print("Model Loading")
        ModelLoadedSemaphore.wait()
        print("Model Loaded")
 
        for album in TheDataModel.getAlbumData(key: KEY_ROOT_ALBUMS, filter: "") {
           //print("ALBUM: ", album)
        }

    }

    var body: some Scene {
        WindowGroup {
            //TalkPlayerView(talk: SelectedTalk)
            RootView()
        }
    }
}
