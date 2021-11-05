//
//  UpdateScreen.swift
//
//  The update screen.  This is brought up via a background timer in Model.
//
//
//  Created by Christopher Minson on 10/7/21.
//  Copyright © 2022 Christopher Minson. All rights reserved.
//
//
import SwiftUI
import UIKit
import AVFoundation

var xSharedRTalkActive = false

struct UpdateScreen : View {

    var album: AlbumData

    @Environment(\.presentationMode) var presentationMode
    
    @State var appIsReady:Bool = false
    @State var sharedURL: String = ""

    
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    // download and configure DataModel.  WAIT on the completion semaphore in the
    // DispatchQueue timer in the body before finishing initialization
    init(album: AlbumData) {

        self.album = album
        if AppUpdateRequested == false {return}
        
        AppUpdateRequested = false
        ModelReadySemaphore = DispatchSemaphore(value: 0)
     }
    
    
    func dismissView() -> Text {
        
        presentationMode.wrappedValue.dismiss()
        return Text("")
    }
    

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            if self.appIsReady {
                dismissView()
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
                    Spacer().frame(height: 40)
                    Text("Checking For New Talks")
                        .font(.system(size: FONT_SIZE_SECTION, weight: .bold))
                        .foregroundColor(.white)

                    Spacer()

                }
                }
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .edgesIgnoringSafeArea(.all)
        .background(Color.black)
        .onAppear {
            
            TheDataModel.initialize()
            TheDataModel.downloadAndConfigure(startingApp: false)

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    ModelReadySemaphore.wait()
                    print("semaphore wait finished")
                    self.appIsReady = true
                }
            }
            
        }
        .onDisappear() {
            
            DispatchQueue.main.async {
                
                // refreshes talkListView and albumListView
                CurrentAlbum.totalTalks = 42
            }

        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
        .edgesIgnoringSafeArea(.all)
        .background(Color.black)

    }
}

