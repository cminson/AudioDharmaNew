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


var CurrentHomePage: HomePageView? = nil

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
    @State var displayNoCurrentTalk: Bool = false
    @State var sharedURL: String = ""
    
    
    init(parentAlbum: AlbumData) {
        
        self.parentAlbum = parentAlbum
        self.selectedAlbum = AlbumData.empty()
        self.selectedTalk = TalkData.empty()
        self.selectedTalkTime = 0
        
        CurrentHomePage = self
        
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
           .alert(isPresented: $displayNoCurrentTalk) {
               Alert(
                   title: Text("No talk available"),
                   message: Text("No talk has been played yet"),
                   dismissButton: .default(Text("OK")) {
                       displayNoCurrentTalk = false
                   }
               )
            }
            .onOpenURL { url in
               sharedURL = url.absoluteString
               if let talkFileName = URL(string: sharedURL)?.lastPathComponent {
                   if let talk = TheDataModel.getTalkForName(name: talkFileName) {
                       selection = "RESUME_TALK"
                       selectedTalk = talk
                       selectedAlbum = TheDataModel.AllTalksAlbum
                       selectedTalkTime = 0
                    }
               }
            }
            .listStyle(PlainListStyle())  // ensures fills parent view
            .environment(\.defaultMinListRowHeight, 15)
            .background(NavigationLink(destination: HelpPageView(), tag: "HELP", selection: $selection) { EmptyView() } .hidden())
            .background(NavigationLink(destination: TalkPlayerView(album: selectedAlbum, talk: selectedTalk, startTime: selectedTalkTime), tag: "RESUME_TALK", selection: $selection) {EmptyView() }.hidden())
            .background(NavigationLink(destination: DonationPageView(), tag: "DONATE", selection: $selection) { EmptyView() } .hidden())
            .navigationBarTitle(TheDataModel.isInternetAvailable() ? "Audio Dharma" : "Audio Dharma [Offline]", displayMode: .inline)
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Button {
                        selection = "HELP"

                    } label: {
                        Image(systemName: "questionmark.circle")
                    }
                    Spacer()
                    Button(action: {
                        if TheDataModel.currentTalkExists() {
                            selection = "RESUME_TALK"
                            selectedTalk = CurrentTalk
                            selectedAlbum = CurrentAlbum
                            selectedTalkTime = CurrentTalkElapsedTime
                        } else {
                            displayNoCurrentTalk = true
                        }
                    })
                    {
                        Text("Resume Talk")
                    }
                     Spacer()
                    Button(action: {
                        selection = "DONATE"

                   }) {
                        Image(systemName: "heart.circle")
                    }
                }
            }
           // end toolbar
       }  // end NavigationView
       .navigationViewStyle(.stack)
    }
        
}

