//
//  SplashScreen.swift
//  AudioDharmaNew
//
//  Created by Christopher Minson on 9/18/21.
//  Copyright © 2022 Christopher Minson. All rights reserved.
//

import SwiftUI

struct SplashScreen : View {
    
    @State var appIsReady:Bool = false
    
    init() {

        TheDataModel.loadAllData()
        ModelLoadedSemaphore.wait()
        print("MODEL LOADED")

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
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation {
                    self.appIsReady = true
                }
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.black)

    }

    
}
