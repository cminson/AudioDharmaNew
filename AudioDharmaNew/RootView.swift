//
//  RootView.swift
//
//  Displays  splash screen as it downloads data and configures the model.
//  Once completed, it launces the main UI.
//
//  Created by Christopher on 11/21/21.
//

import SwiftUI

struct RootView: View {
    
    @State private var selection: String?  = ""
    @State private var appIsBooting: Bool = true

    
    var body: some View {
        
        NavigationView {
            
            VStack(alignment: .center, spacing: 0) {
                
                ZStack {
                    Color.black
                        .ignoresSafeArea()
                    GeometryReader { metrics in
                        VStack() {
                           Spacer()
                           HStack() {
                                Spacer()
                                Image("Earth")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: metrics.size.width * 0.4, height: metrics.size.width * 0.4)
                               Spacer()
                            }
                            Spacer().frame(height:20)
                            Text(self.appIsBooting ? "" : "updating talks")
                                .font(.system(size: FONT_SIZE_UPDATE_SCREEN))
                                .foregroundColor(Color.white)
                            Spacer()
                        }

                    } // end geometry reader
                } // end zstack
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            .edgesIgnoringSafeArea(.all)
            .background(Color.black)
            .background(NavigationLink(destination: HomePageView().navigationBarBackButtonHidden(true), tag: "START_UI", selection: $selection) {EmptyView() }.hidden())

            .onAppear {
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation {
                        print("root dispatch")
                        
                        if NewTalksAvailable == true {
                            
                            NewTalksAvailable = false
                            
                            // create and initialize a new model
                            print("Updating Model")
                            TheDataModel = Model()
                            TheDataModel.downloadConfig()
                            print("Init Waiting")
                            ModelReadySemaphore.wait()
                            TheDataModel.installConfig()
                            ModelReadySemaphore.wait()
                            
                            TheDataModel.updateSanghaActivity()
                            
                            // Lastly set up background data refresh threads
                            TheDataModel.startBackgroundTimers()
                            self.appIsBooting = false

                        }
                        
                        selection = "START_UI"

                    }
                } // end dispatch
            } // end on appear
        } // end navigation view

    } // end view

}


