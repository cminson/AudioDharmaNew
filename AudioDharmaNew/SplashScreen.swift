//
//  SplashScreen.swift
//  AudioDharmaNew
//
//  Created by Christopher Minson on 9/18/21.
//  Copyright © 2022 Christopher Minson. All rights reserved.
//

import SwiftUI


/*
 
 var Splash : SplashScreen!
 var SplashTimer : Timer?
 
 
 @objc func loadTimer() {
     Splash.update()
 }
 
 
ConfigurationComplete = false
Splash = splashScreen
SplashTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(loadTimer), userInfo: nil, repeats: true)
*/

import UIKit
import AVFoundation


var SplashAppeared = false

struct SplashScreen : View {
    
    @State var appIsReady:Bool = false
    
    // download and configure DataModel.  WAIT on te completion semaphore in the
    // DispatchQueue timer in the body before finishing initialization
    init() {
        
        TheDataModel.initialize()
        TheDataModel.downloadAndConfigure()
    }
    

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            if self.appIsReady {
                HomePageView(parentAlbum: TheDataModel.RootAlbum)
            } else {
                VStack() {
                    Spacer()
                    HStack() {
                        Spacer()
                        Image("Earth")
                            //.frame(minWidth: 100, maxWidth: 300, minHeight: 100, maxHeight: 300, alignment: .center)
                        Spacer()
                    }
                    Spacer()

                }
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .edgesIgnoringSafeArea(.all)
        .background(Color.black)
        .onAppear {
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation {
                    ModelReadySemaphore.wait()
                    print("MODEL LOADED")
                    TheDataModel.downloadSanghaActivity()
                    ModelReadySemaphore.wait()
                    print("SANGHA LOADED")
                    TheDataModel.startBackgroundTimers()

                    self.appIsReady = true
                }
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
        .edgesIgnoringSafeArea(.all)

        .background(Color.black)

    }



    
}
