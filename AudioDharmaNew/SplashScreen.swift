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
    @State var configurationFailed:Bool = false
    
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    // download and configure DataModel.  WAIT on the completion semaphore in the
    // DispatchQueue timer in the body before finishing initialization
    init() {
        
        TheDataModel.initialize()
        TheDataModel.downloadAndConfigure(startingApp: true)
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
            
            AppColorScheme = colorScheme
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    ModelReadySemaphore.wait()
                    
                    if TheDataModel.SystemIsConfigured {
                        // Model now loaded.  So now it's safe to get additional data (Sangha activity)
                        TheDataModel.downloadSanghaActivity()
                        ModelReadySemaphore.wait()
                        
                        // Lastly set up background data refresh threads
                        TheDataModel.startBackgroundTimers()

                        // good to go
                        self.appIsReady = true
                    } else {
                        self.configurationFailed = true
                    }
                }
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
        .edgesIgnoringSafeArea(.all)
        .background(Color.black)
        .alert(isPresented: $configurationFailed) {   
            Alert(
                title: Text("Can Not Connect to AudioDharma"),
                message: Text("Please enable your internet connection and restart the app"),
                dismissButton: .default(Text("OK")) {
                }
            )
        }
    }
}

