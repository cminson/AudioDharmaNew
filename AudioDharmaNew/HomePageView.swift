//
//  HomePageView.swift
//
//  Home page of the app, showing all the top-level albums
//
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
    @ObservedObject  var parentAlbum: AlbumData
    
    @State var selectedAlbum: AlbumData
    @State var selectedTalk: TalkData
    @State var selectedTalkTime: Double
    @State var selection: String?  = ""
    @State var searchText: String  = ""
    @State var noCurrentTalk: Bool = true
    @State var isActive: Bool = false

    
    init(parentAlbum: AlbumData) {
        
        //UINavigationBar.appearance().titleTextAttributes = [.font : UIFont(name: "Georgia-Bold", size: 20)!]
        self.parentAlbum = parentAlbum
        self.selectedAlbum = AlbumData.empty()
        self.selectedTalk = TalkData.empty()
        self.selectedTalkTime = 0
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

            .background(NavigationLink(destination: TalkPlayerView(album: selectedAlbum, talk: selectedTalk, elapsedTime: selectedTalkTime), tag: "RESUME_TALK", selection: $selection) { EmptyView() } .hidden())
            .background(NavigationLink(destination: DonationPageView(), tag: "DONATE", selection: $selection) { EmptyView() } .hidden())
            .navigationBarTitle(TheDataModel.isInternetAvailable() ? "Audio Dharma" : "Audio Dharma [Offline]", displayMode: .inline)
             .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Button {
                        selection = "HELP"

                    } label: {
                        Image(systemName: "questionmark.circle")
                    }
                    .foregroundColor(.black)
                    Spacer()
                    Button(action: {
                        selection = "RESUME_TALK"
                        selectedTalk = CurrentTalk
                        selectedTalkTime = CurrentTalkElapsedTime
                    }) {
                        Text("Resume Talk")
                           
                    }
                    .foregroundColor(.black)
                    .hidden(!TheDataModel.currentTalkExists())
                    Spacer()
                    Button(action: {
                        selection = "DONATE"

                   }) {
                        Image(systemName: "heart.circle")
                    }
                   .foregroundColor(.black)

                }
            }
           // end toolbar
       }  // end NavigationView

       .navigationViewStyle(.stack)
    }
        
}

