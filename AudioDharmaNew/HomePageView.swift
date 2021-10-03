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
    @State var noCurrentTalk: Bool = false
    
    
    init(parentAlbum: AlbumData) {
        
        UINavigationBar.appearance().titleTextAttributes = [.font : UIFont(name: "Georgia-Bold", size: 20)!]
        self.parentAlbum = parentAlbum
        self.selectedAlbum = AlbumData(title: "PLACEHOLDER", key: "", section: "", imageName: "", date: "")
    }

    var body: some View {

       NavigationView {
        
           /*
           List(parentAlbum.getFilteredAlbums(filter: searchText)) { parentAlbum in
              AlbumRow(album: parentAlbum)
           }
            */
         
           List() {
               SectionRow(title: "Main Albums")
                   .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
               
      
               ForEach(parentAlbum.albumList) { album in
                   AlbumRow(album: album)

               }


               AlbumRow(album: parentAlbum.albumList[0])
               AlbumRow(album: parentAlbum.albumList[1])
               SectionRow(title: "Personal Albums")
                   .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))

               AlbumRow(album: parentAlbum.albumList[2])


           }
         


           //List(parentAlbum.albumList) { album in
           /*
           List {
               Section(header: HStack {
                   Spacer()
                   Text("Main Albums").font(.system(size: 15.0)).foregroundColor(Color.white)
                       .frame(height: 35)
                   Spacer()
               }
               .background(Color(hex: "555555"))
               .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
               )
               {
                   AlbumRow(album: parentAlbum.albumList[0])
                   AlbumRow(album: parentAlbum.albumList[1])
                   AlbumRow(album: parentAlbum.albumList[2])
                   AlbumRow(album: parentAlbum.albumList[3])
                   AlbumRow(album: parentAlbum.albumList[4])
                   AlbumRow(album: parentAlbum.albumList[5])
               }
               Section(header: HStack {
                   Spacer()
                   Text("Personal Albums").font(.system(size: 15.0)).foregroundColor(Color.white)
                       .frame(height: 35)
                   Spacer()
               }
               .background(Color(hex: "555555"))
               .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
               )
               {
                   AlbumRow(album: parentAlbum.albumList[7])
                   AlbumRow(album: parentAlbum.albumList[8])
                   AlbumRow(album: parentAlbum.albumList[9])
                   AlbumRow(album: parentAlbum.albumList[10])
                   AlbumRow(album: parentAlbum.albumList[11])
                   AlbumRow(album: parentAlbum.albumList[12])
               }
               Section(header: HStack {
                   Spacer()
                   Text("Community Albums").font(.system(size: 15.0)).foregroundColor(Color.white)
                       .frame(height: 35)
                   Spacer()
               }
               .background(Color(hex: "555555"))
               .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
               )
               {
                   AlbumRow(album: parentAlbum.albumList[13])
                   AlbumRow(album: parentAlbum.albumList[14])
                   AlbumRow(album: parentAlbum.albumList[15])
                   AlbumRow(album: parentAlbum.albumList[16])
                   AlbumRow(album: parentAlbum.albumList[17])
               }

            }
            */
            .listStyle(PlainListStyle())  // ensures fills parent view
            .environment(\.defaultMinListRowHeight, 15)
            .background(NavigationLink(destination: HelpPageView(), tag: "HELP", selection: $selection) { EmptyView() } .hidden())
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





