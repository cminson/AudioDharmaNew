///
//  RootView.swift
//
//  Displays  splash screen as it downloads data and configures the model.
//  Once completed, it launces the main UI.
//
//  Created by Christopher on 11/21/21.
//
import SwiftUI

var LinkSeenInRoot = false
var LinkURLSeenInRoot = ""


struct RootView: View {
    
    @State private var selection: String?  = ""
    @State private var appIsBooting: Bool = true
    @State private var sharedURL: String = ""
    @State private var sharedTalkActive: Bool = false
    @State var selectedTalk: TalkData = TalkData.empty()

    
    func refreshModel() {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation {
                
                print("Root onAppearx")
                if ConfigUpdateRequired == true {
                    
                    ConfigUpdateRequired = false
                    
                    // create and initialize a new model
                    print("Updating Model")
                    TheDataModel = Model()
                    TheDataModel.downloadConfig()
                    print("Init Waiting")
                    ModelReadySemaphore.wait()
                    print("Config Waiting")
                    TheDataModel.installConfig()
                    ModelReadySemaphore.wait()
                    print("DONE")
                    
                    self.appIsBooting = false

                }
                
                selection = "START_UI"
            }
        } // end dispatch
    }
    
    
    // this bit of hackery is required, as we need to initiate background processing
    // and the usual entry points (onAppear, init, etc), are not always called!
    func refreshHook() -> String {
        print("Rendering RootView")
        refreshModel()
        return "Earth"
    }
    
    
    var body: some View {
        
        NavigationView {
            
            VStack(alignment: .center, spacing: 0) {
                
                NavigationLink(destination: HomePageView().navigationBarBackButtonHidden(true), tag: "START_UI", selection: $selection) {Text("")}.isDetailLink(false)

                ZStack {
                    Color.black
                        .ignoresSafeArea()
                    GeometryReader { metrics in
                        VStack() {
                           Spacer()
                           HStack() {
                               Spacer()
                               Image(self.refreshHook())
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
                // to avoid view conflicts, defer
                //  opening deep link until home page displays
                LinkSeenInRoot = true
                LinkURLSeenInRoot = url.absoluteString
             }
            
        } // end navigation view
        .navigationViewStyle(StackNavigationViewStyle())
    } // end view
}
