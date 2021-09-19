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
    
    
    @State var selection: String?  = ""
    @State var key: String  = ""
    @State var title: String  = ""
    @State var searchText: String  = ""
    @State var noCurrentTalk: Bool = false
    

    init() {
        print("HomePageView init")
        UINavigationBar.appearance().titleTextAttributes = [.font : UIFont(name: "Georgia-Bold", size: 20)!]
        print("HomePageView ALBUMS")
        for album in TheDataModel.getAlbumData(key: KEY_ROOT_ALBUMS, filter: "") {
            print(album.Title)
            
        }
     }
        
    var body: some View {

       NavigationView {
        
        List(TheDataModel.getAlbumData(key: KEY_ROOT_ALBUMS, filter: "")) { album in
                AlbumRow(album: album)
                    .onTapGesture {
                        if album.Key.contains("ALBUM") {
                            print("HERE", album.Key)
                            selection = "ALBUMS"
                        } else {
                            selection = "TALKS"
                        }
                        key = album.Key
                        title = album.Title
                    }
         
            }  // end List(albums)
            .environment(\.defaultMinListRowHeight, 20)
            .background(NavigationLink(destination: TalkListView(title: title, key: key), tag: "TALKS", selection: $selection) { EmptyView() } .hidden())
            .background(NavigationLink(destination: AlbumListView(title: title, key: key), tag: "ALBUMS", selection: $selection) { EmptyView() } .hidden())
            .background(NavigationLink(destination: TalkPlayerView(talk: CurrentTalk, currentTime: CurrentTalkTime), tag: "PLAY_TALK", selection: $selection) { EmptyView() } .hidden())
            .background(NavigationLink(destination: HelpPageView(), tag: "HELP", selection: $selection) { EmptyView() } .hidden())
            .background(NavigationLink(destination: DonationPageView(), tag: "DONATE", selection: $selection) { EmptyView() } .hidden())



            .navigationBarTitle("Audio Dharma", displayMode: .inline)
 
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Button {
                        print("Display Help")
                        selection = "HELP"

                    } label: {
                        Image(systemName: "questionmark.circle")
                    }
                    Spacer()
                    
                    Button(action: {
                        print(CurrentTalk.Title)
                        if CurrentTalk.Title == "NO TALK" {
                            print("none")
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
            }  // end toolbar
       }
       .alert(isPresented: $noCurrentTalk) { () -> Alert in
                   Alert(title: Text("You haven't played a talk yet, so there is no talk to re-start"))
        
        }
    }
        
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        HelpPageView()
        //TalkPlayerView(talk: SelectedTalk)
    }
}




