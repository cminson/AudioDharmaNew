//
//  AlbumListView.swift
//
//  Created by Christopher Minson on 9/9/21.
//  Copyright © 2022 Christopher Minson. All rights reserved.
//

import SwiftUI
import UIKit


struct SectionRow: View {
    var title: String

    var body: some View {
        
        VStack(alignment: .leading) {
            HStack() {
                Spacer()
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .background(Color(hex: "555555"))
                    .foregroundColor(.white)
                    .padding(.leading, 0)
                Spacer()
            }
            .frame(height: 35)

        }
        .background(Color(hex: "555555"))
        .frame(maxWidth: .infinity)
     }
}


struct AlbumRow: View {
    
    @ObservedObject var album: AlbumData
    @State var selection: String?  = ""

    var body: some View {
        
        VStack(alignment: .leading) {
            HStack() {
                album.ImageName.toImage()
                    .resizable()
                    .frame(width: LIST_IMAGE_WIDTH, height:LIST_IMAGE_HEIGHT)
                    .background(Color.white)
                    .padding(.leading, -15)
                Text("\(album.Title)")
                    .font(.system(size: 14))
                    .background(Color.white)
                    .padding(.leading, 0)
                Spacer()
                VStack(alignment: .trailing, spacing: 8) {
                    Text(album.totalTalks.displayInCommaFormat())
                        .background(Color.white)
                        .padding(.trailing, -10)
                        .font(.system(size: 10))
                    //Spacer()
                        //frame(height: 8)
                    Text(album.totalSeconds.displayInClockFormat())
                        .background(Color.white)
                        .padding(.trailing, -10)
                        .font(.system(size: 10))
                }
            }
            .onTapGesture {
                if KEYS_TO_ALBUMS.contains(album.Key) {
                    print("RENDER ALBUM")
                    selection = "ALBUMS"
                } else {
                    print("RENDER TALKS")
                    selection = "TALKS"
                }
            }
        }
        .background(NavigationLink(destination: TalkListView(album: album), tag: "TALKS", selection: $selection) { EmptyView() } .hidden())
        .background(NavigationLink(destination: AlbumListView(album: album), tag: "ALBUMS", selection: $selection) { EmptyView() } .hidden())
        .frame(height:40)
        .frame(maxWidth: .infinity)

     }
}


struct AlbumListView: View {
    
    var album: AlbumData
    
    @State var selectedAlbum: AlbumData
    @State var selection: String?  = ""
    @State var searchText: String  = ""
    @State var noCurrentTalk: Bool = false
    
    
    init(album: AlbumData) {
        self.album = album
        self.selectedAlbum = AlbumData(title: "PLACEHOLDER", key: "", section: "", imageName: "", date: "")
    }
    
    
    var body: some View {

        SearchBar(text: $searchText)
           .padding(.top, 0)
        List(album.getFilteredAlbums(filter: searchText)) { album in
           AlbumRow(album: album)
        }
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



