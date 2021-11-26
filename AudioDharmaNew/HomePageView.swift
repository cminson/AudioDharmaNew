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
    
    @Environment(\.presentationMode) var mode

    @State var selectedAlbum: AlbumData = AlbumData.empty()
    @State var selectedTalk: TalkData = TalkData.empty()
    @State var selectedTalkTime: Double = 0
    @State var selection: String?  = ""
    @State var searchText: String  = ""
    @State var displayNoCurrentTalk: Bool = false
    @State var sharedURL: String = ""
    
    
    func dismissView() {
            
        self.mode.wrappedValue.dismiss()
    }
    
    
    func executeDeepLink(linkURL: String) {
        
        print("execute link", linkURL)
        if let talkFileName = URL(string: linkURL)?.lastPathComponent {
            if  let talk = TheDataModel.getTalkForName(name: talkFileName) {
                self.selectedTalk = talk
                self.selection = "PLAY_TALK"
                print("HomePageView Open SHare")
            }
        }
    }

     
    var body: some View {

           List() {
               ForEach(HOMEPAGE_SECTIONS, id: \.self) { section in
                   SectionRow(title: section)
                   ForEach(TheDataModel.RootAlbum.getAlbumSections(section: section)) { album in
                       AlbumRow(album: album)
                   }
               }
            }
           .onOpenURL { url in
               
               LinkSeenInRoot = false
               DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                   withAnimation {
                       executeDeepLink(linkURL: url.absoluteString)
                   }
               }
           }
           .onAppear {
               
               if NewTalksAvailable {
                   NewTalksAvailable = false
                   self.dismissView()
               }
               // this code is executed if deep link caused app to
               // launch, displaying a new home page
               if LinkSeenInRoot {
                   LinkSeenInRoot = false
                   DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                       withAnimation {
                           executeDeepLink(linkURL: LinkURLSeenInRoot)
                       }
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
            .listStyle(PlainListStyle())  // ensures fills parent view
            .environment(\.defaultMinListRowHeight, 15)
            .background(NavigationLink(destination: HelpPageView(), tag: "HELP", selection: $selection) { EmptyView() } .hidden())
            .background(NavigationLink(destination: TalkPlayerView(album: selectedAlbum, talk: selectedTalk, startTime: selectedTalkTime), tag: "RESUME_TALK", selection: $selection) {EmptyView() }.hidden())
            .background(NavigationLink(destination: DonationPageView(), tag: "DONATE", selection: $selection) { EmptyView() } .hidden())
            .background(NavigationLink(destination: TalkPlayerView(album: TheDataModel.AllTalksAlbum, talk: selectedTalk, startTime: 0), tag: "PLAY_TALK", selection: $selection) { EmptyView() } .hidden())
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

       .navigationViewStyle(.stack)
    }
     
}



