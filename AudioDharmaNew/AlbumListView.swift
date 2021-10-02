//
//  AlbumListView.swift
//
//  Created by Christopher Minson on 9/9/21.
//  Copyright © 2022 Christopher Minson. All rights reserved.
//

import SwiftUI
import UIKit



struct AlbumRow: View {
    @ObservedObject var album: AlbumData
    

    func getImage(named: String) -> Image {
       let uiImage =  (UIImage(named: named) ?? UIImage(named: "defaultPhoto"))!
       return Image(uiImage: uiImage)
    } 

    var body: some View {
        
        VStack(alignment: .leading) {
            HStack() {
                getImage(named: album.Image)
                    .resizable()
                    .frame(width: SPEAKER_IMAGE_WIDTH, height:SPEAKER_IMAGE_HEIGHT)
                    .background(Color.white)
                    .padding(.leading, -15)
                Text("\(album.Title)")
                    .font(.system(size: 14))
                    .background(Color.white)
                    .padding(.leading, 0)
                Spacer()
                VStack() {
                    //Text(String(album.totalTalks))
                    Text(album.totalTalks.withCommas())
                        .background(Color.white)
                        .padding(.trailing, -10)
                        .font(.system(size: 10))
                    Spacer()
                        .frame(height: 8)
                    Text(album.durationDisplay)
                        .background(Color.white)
                        .padding(.trailing, -10)
                        .font(.system(size: 10))
                }
            }
        }
        .frame(height:40)
        .frame(maxWidth: .infinity)

     }
}

/*
 
 NavigationLink(destination: AlbumListView(album: album)) {
     AlbumRow(album: album)

 NavigationLink(destination: AlbumListView(album: selectedAlbum), tag: "ALBUMS", selection: $selection) { EmptyView() } .hidden()

 */


struct AlbumListView: View {
    var album: AlbumData
    
    @State var selectedAlbum: AlbumData

    @State var selection: String?  = ""
    @State var searchText: String  = ""

    @State var noCurrentTalk: Bool = false
    
    
    init(album: AlbumData) {
        self.album = album
        self.selectedAlbum = AlbumData(title: "PLACEHOLDER", key: "", section: "", image: "", date: "")

        
        print("AlbumListView: ", album.Title)
        
        print("Album List")
        /*
        for album in album.albumList {
            print(album.Title)
        }
         */

    }
    
    func getKey (album: AlbumData) -> Bool {
        print("ALBUM BODY RENDERING")
        
        return album.Key.contains("ALBUM")
    
    }

    var body: some View {

        SearchBar(text: $searchText)
           .padding(.top, 0)

        //List(TheDataModel.getAlbumData(key: key, filter: searchText)) { album in
        List(album.albumList) { album in
           AlbumRow(album: album)
                .onTapGesture {
                    selectedAlbum = album
                    //if album.Key.contains("ALBUM") {
                    if getKey(album: album) {
                        selection = "ALBUMS"
                    } else {
                        selection = "TALKS"
                    }
                }
        }

        .background(NavigationLink(destination: TalkListView(album: selectedAlbum), tag: "TALKS", selection: $selection) { EmptyView() } .hidden())
        .background(NavigationLink(destination: AlbumListView(album: selectedAlbum), tag: "ALBUMS", selection: $selection) { EmptyView() } .hidden())

        .navigationBarTitle(album.Title, displayMode: .inline)
        .navigationBarHidden(false)
        
        .listStyle(PlainListStyle())  // ensures fills parent view


        .navigationViewStyle(StackNavigationViewStyle())
        .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Button {
                        // your action here
                    } label: {
                        Image(systemName: "calendar")
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
                        Image(systemName: "note")
                            .renderingMode(.original)

                    }
                    Spacer()
                    Button(action: {
                    }) {
                        Image(systemName: "heart.fill")
                            .renderingMode(.original)

                    }
                }
            }
    }
}



