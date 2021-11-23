///
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
    @State private var sharedURL: String = ""
    @State var selectedTalk: TalkData = TalkData.empty()

    
    var body: some View {
        
        NavigationView {
            
            VStack(alignment: .center, spacing: 0) {
                
                NavigationLink(destination: HomePageView().navigationBarBackButtonHidden(true), tag: "START_UI", selection: $selection) {Text("")}.isDetailLink(false)
                NavigationLink(destination: TalkPlayerView(album: TheDataModel.AllTalksAlbum, talk: selectedTalk, startTime: 0).navigationBarBackButtonHidden(true), tag: "PLAY_TALK", selection: $selection) { Text("") }.isDetailLink(false)

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

            .onOpenURL { url in
                sharedURL = url.absoluteString
                SharedTalkActive = true
            }


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
                        
                        if SharedTalkActive == true {
                            if let talkFileName = URL(string: sharedURL)?.lastPathComponent {
                                if  let talk = TheDataModel.getTalkForName(name: talkFileName) {
                                    selectedTalk = talk
                                    selection = "PLAY_TALK"
                                }
                            }
                        } else {
                            selection = "START_UI"
                        }

                    }
                } // end dispatch
            } // end on appear
        } // end navigation view
        .navigationViewStyle(StackNavigationViewStyle())
    } // end view
}
