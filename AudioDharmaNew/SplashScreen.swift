//
//  SplashScreen.swift
//
//  The initial splash screen.  Initiate download of configuration and show splash screen
//  until app is ready.
//
//
//  Created by Christopher Minson on 9/18/21.
//  Copyright © 2022 Christopher Minson. All rights reserved.
//
//
import SwiftUI
import UIKit
import AVFoundation


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
                GeometryReader { metrics in
                VStack() {
                    Spacer()
                    HStack() {
                        Spacer()
                        Image("Earth")
                            .resizable()
                            .frame(width: metrics.size.width * 0.4, height: metrics.size.width * 0.4)
                        Spacer()
                    }
                    Spacer()

                }
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
