//
//  ContentView.swift
//  Home album view
//
//  Created by Christopher Minson on 8/31/21.
//  Copyright © 2022 Christopher Minson. All rights reserved.
//
//

import SwiftUI
import UIKit


/*
 * HomePageView
 * UI for the top-level display of albums.  Invoked by SplashScreen after data model is loaded.
 */
struct HomePageView: View {
    var parentAlbum: AlbumData
    
    @State var selectedAlbum: AlbumData
    @State var selection: String?  = ""
    @State var searchText: String  = ""
    @State var noCurrentTalk: Bool = true
    
    init(parentAlbum: AlbumData) {
        
        UINavigationBar.appearance().titleTextAttributes = [.font : UIFont(name: "Georgia-Bold", size: 20)!]
        self.parentAlbum = parentAlbum
        self.selectedAlbum = AlbumData(title: "PLACEHOLDER", key: "", section: "", imageName: "", date: "")
    }

    
    var body: some View {

       NavigationView {
           List() {
               ForEach(HOMEPAGE_SECTIONS, id: \.self) { section in
                   SectionRow(title: section)
                   ForEach(parentAlbum.getAlbumSections(section: section)) { album in
                       AlbumRow(album: album)
                   }
               }
            }
            .listStyle(PlainListStyle())  // ensures fills parent view
            .environment(\.defaultMinListRowHeight, 15)
            .background(NavigationLink(destination: HelpPageView(), tag: "HELP", selection: $selection) { EmptyView() } .hidden())
            //.background(NavigationLink(destination: TalkPlayerView(talk: CurrentTalk!, currentTime: 0), tag: "PLAY_TALK", selection: $selection) { EmptyView() } .hidden())
            .background(NavigationLink(destination: DonationPageView(), tag: "DONATE", selection: $selection) { EmptyView() } .hidden())
            .navigationBarTitle("Audio Dharma", displayMode: .inline)
             .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Button {
                        selection = "HELP"

                    } label: {
                        Image(systemName: "questionmark.circle")
                    }
                    Spacer()
                    /*
                    Button(action: {
                        if CurrentTalk?.Title != "NO TALK" {
                            noCurrentTalk = false
                            selection = "PLAY_TALK"
                            print(CurrentTalk?.Title)
                        } else {
                            noCurrentTalk = true
                        }
                    }) {
                        Text("Resume Talk")
                    }
                    .hidden(noCurrentTalk)
                  */
                    Spacer()
                    Button(action: {
                        selection = "DONATE"

                   }) {
                        Image(systemName: "suit.heart")
                            .renderingMode(.original)

                    }
                }
            }
           // end toolbar
       }  // end NavigationView

       .navigationViewStyle(.stack)
    }
        
}

/*
 .alert(isPresented: $noCurrentTalk) { () -> Alert in
             Alert(title: Text("You haven't played a talk yet, so there is no talk to re-start"))
  
  }
 */
