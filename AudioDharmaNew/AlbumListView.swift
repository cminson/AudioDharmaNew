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
                    .font(.system(size: FONT_SIZE_SECTION, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
            }
            .frame(height: LIST_ROW_SIZE_SECTION)
        }
        .background(Color(hex: COLOR_BACKGROUND_SECTION))
        .frame(maxWidth: .infinity)
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
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
                    .font(.system(size: FONT_SIZE_ROW_TITLE))
                    .background(Color.white)
                    .padding(.leading, 0)
                Spacer()
                VStack(alignment: .trailing, spacing: 8) {
                    Text(album.totalTalks.displayInCommaFormat())
                        .background(Color.white)
                        .padding(.trailing, -10)
                        .font(.system(size: FONT_SIZE_ROW_ATTRIBUTES))
                    Text(album.totalSeconds.displayInClockFormat())
                        .background(Color.white)
                        .padding(.trailing, -10)
                        .font(.system(size: FONT_SIZE_ROW_ATTRIBUTES))
                }
            }
            .onTapGesture {
                if KEYS_TO_ALBUMS.contains(album.Key) {
                    selection = "ALBUMS"
                } else {
                    selection = "TALKS"
                }
            }
        }
        .background(NavigationLink(destination: TalkListView(album: album), tag: "TALKS", selection: $selection) { EmptyView() } .hidden())
        .background(NavigationLink(destination: AlbumListView(album: album), tag: "ALBUMS", selection: $selection) { EmptyView() } .hidden())
        .background(Color.white)
        .frame(height: LIST_ROW_SIZE_STANDARD)
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
 
                            selection = "PLAY_TALK"
                        
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



