//
//  ContentView.swift
//  Base album view
//
//  Created by Christopher Minson on 8/31/21.
//  Copyright © 2022 Christopher Minson. All rights reserved.
//
//

import SwiftUI
import UIKit


/*
 * HomePageView
 * UI for the top-level display of albums.  Invoked by SplashScreen after model is loaded.
 */
struct HomePageView: View {
    var parentAlbum: AlbumData
    
    @State var selectedAlbum: AlbumData
    @State var selection: String?  = ""
    @State var searchText: String  = ""
    @State var noCurrentTalk: Bool = false
    
    
    init(parentAlbum: AlbumData) {
        UINavigationBar.appearance().titleTextAttributes = [.font : UIFont(name: "Georgia-Bold", size: 20)!]
        self.parentAlbum = parentAlbum
        self.selectedAlbum = AlbumData(title: "PLACEHOLDER", key: "", section: "", image: "", date: "")
        
        print("UserFavorite Talks at Album Init", TheDataModel.UserFavoritesAlbum.Title)
        for talk in TheDataModel.UserFavoritesAlbum.talkList {
            print(talk.Title)
        }

    }

      
    var body: some View {

       NavigationView {
        
        //List(TheDataModel.getAlbumData(key: KEY_ALBUMROOT, filter: "")) { album in
           List(parentAlbum.albumList) { album in
              
                 AlbumRow(album: album)
                    .onTapGesture {
                        selectedAlbum = album
                        if KEYS_TO_ALBUMS.contains(selectedAlbum.Key) {
                            print("RENDER ALBUM")
                            selection = "ALBUMS"
                        } else {
                            print("RENDER TALKS")
                            selection = "TALKS"
                        } 
                    }
            }

           .background(NavigationLink(destination: TalkListView(album: selectedAlbum), tag: "TALKS", selection: $selection) { EmptyView() } .hidden())
           .background(NavigationLink(destination: AlbumListView(album: selectedAlbum), tag: "ALBUMS", selection: $selection) { EmptyView() } .hidden())


            .listStyle(PlainListStyle())  // ensures fills parent view

            .environment(\.defaultMinListRowHeight, 20)

            //.background(NavigationLink(destination: AlbumListView(title: title, key: key), tag: "ALBUMS", selection: $selection) { EmptyView() } .hidden())
            .background(NavigationLink(destination: TalkPlayerView(talk: CurrentTalk, currentTime: CurrentTalkTime), tag: "PLAY_TALK", selection: $selection) { EmptyView() } .hidden())
            .background(NavigationLink(destination: HelpPageView(), tag: "HELP", selection: $selection) { EmptyView() } .hidden())
            .background(NavigationLink(destination: DonationPageView(), tag: "DONATE", selection: $selection) { EmptyView() } .hidden())
            //.navigationBarTitle("Audio Dharma")
            .navigationBarTitle("Audio Dharma", displayMode: .inline)


             .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Button {
                        selection = "HELP"

                    } label: {
                        Image(systemName: "questionmark.circle")
                    }
                    Spacer()
                    
                    Button(action: {
                        if CurrentTalk.Title == "NO TALK" {
                            noCurrentTalk = true
                        } else {
                            noCurrentTalk = false
                            selection = "PLAY_TALK"
                        }
                    }) {
                        Image(systemName: "die.face.1")
                            .renderingMode(.original)
                    }
                  
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
       }

       .alert(isPresented: $noCurrentTalk) { () -> Alert in
                   Alert(title: Text("You haven't played a talk yet, so there is no talk to re-start"))
        
        }
       .navigationViewStyle(.stack)  // fix CONSTRAINT warmings
    }
        
}

/*

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        //HomePageView()
        //TalkPlayerView(talk: SelectedTalk)
    }
}
 */





