//
//  HelpPageView.swift
//  AudioDharmaNew
//
//  Created by Christopher on 9/18/21.
//

import SwiftUI

struct HelpPageView: View {
    
    @State var selection: String?  = ""

    
    var body: some View {
        VStack() {
        Text("Help Page")
        }
            .background(NavigationLink(destination: HelpPageView(), tag: "HELP_PAGE", selection: $selection) { EmptyView() } .hidden())
            .background(NavigationLink(destination: DonationPageView(), tag: "DONATION_PAGE", selection: $selection) { EmptyView() } .hidden())
            .background(NavigationLink(destination: LandingPageView(), tag: "LAUNCH_PAGE", selection: $selection) { EmptyView() } .hidden())

   
    .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                Button {
                    print("Help")
                    //selection = "HELP_PAGE"
                } label: {
                    Image(systemName: "calendar")
                }
                Spacer()
                Button(action: {
                    print(CurrentTalk.Title)
                    selection = "LAUNCH_PAGE"
                 }) {
                    Image(systemName: "note")
                        .renderingMode(.original)
                }
                Spacer()
                Button(action: {
                    print("Donate")
                    selection = "DONATION_PAGE"
               }) {
                    Image(systemName: "heart.fill")
                        .renderingMode(.original)

                }
            }
        }
      
    }
}

struct HelpPageView_Previews: PreviewProvider {
    static var previews: some View {
        HelpPageView()
    }
}
