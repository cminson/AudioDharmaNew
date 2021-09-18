//
//  SplashScreen.swift
//  AudioDharmaNew
//
//  Created by Christopher on 9/18/21.
//

import SwiftUI

struct SplashView: View {
    
    // 1.
    @State var isActive:Bool = false
    
    init() {
        print("Audiodharma init")
        TheDataModel.loadAllData()
        print("Model Loading")
        ModelLoadedSemaphore.wait()
        print("MODEL LOADED")
    }

    
    var body: some View {
        VStack {
            // 2.
            if self.isActive {
                // 3.
                RootView()
            } else {
                // 4.
                Text("Splash Screen")
                    .font(Font.largeTitle)
            }
        }
        // 5.
        .onAppear {
            // 6.
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                // 7.
                withAnimation {
                    self.isActive = true
                }
            }
        }
    }
    
}
