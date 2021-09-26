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


var SplashAppeared = false

struct SplashScreen : View {
    
    @State var appIsReady:Bool = false
    
    init() {

        TheDataModel.loadData()
        print("Waiting on Model")

        ModelLoadSemaphore.wait()
        print("MODEL LOADED")

        
       // let timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(fireTimer), userInfo: nil, repeats: true)
    }
    
  
    func update() {
        print("splash fired!")
        /*
        if ConfigurationComplete == true {
            SplashTimer?.invalidate()
            print("SPLASH DONE")
            appIsReady = true
        }
         */
    }

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            if self.appIsReady {
                HomePageView()
            } else {
                Spacer()
                Image("Earth")
                    .frame(minWidth: 100, maxWidth: 300, minHeight: 100, maxHeight: 300, alignment: .center)
                Spacer()
            }
        }
        .background(Color.black)
        .onAppear {
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                withAnimation {
                    self.appIsReady = true
                }
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.black)

    }

    
}
