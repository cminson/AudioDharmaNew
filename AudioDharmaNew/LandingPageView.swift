//
//  LandingPageView.swift
//  AudioDharmaNew
//
//  Created by Christopher on 9/18/21.
//

import SwiftUI

struct LandingPageView: View {
    @State var selection: String?  = ""

    /*
    init() {
 
        print("Landing Init")
        TheDataModel.loadAllData()
        ModelLoadedSemaphore.wait()
        print("Model Loaded")

        selection = "LAUNCH"

 
    }
 */

    var body: some View {
        
        VStack () {
        Button {
            selection = "LAUNCH"
        } label: {
            Image(systemName: "calendar")
        }

        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)

        }
        .background(NavigationLink(destination: RootView(), tag: "LAUNCH", selection: $selection) { EmptyView() } .hidden())
        .onAppear {
            print("onapear")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                /*
                TheDataModel.loadAllData()
                ModelLoadedSemaphore.wait()
                print("Model Loaded")
 */

                selection = "LAUNCH"

            }
        }

    }
    
}

struct LandingPageView_Previews: PreviewProvider {
    static var previews: some View {
        LandingPageView()
    }
}
