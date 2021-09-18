//
//  AlbumListView.swift
//
//  Created by Christopher Minson on 9/9/21.
//  Copyright © 2022 Christopher Minson. All rights reserved.
//

import SwiftUI
import UIKit



struct AlbumRow: View {
    var album: AlbumData
    
    @State var selection: String?  = ""
    @State var noCurrentTalk: Bool = false


    
    init(album: AlbumData) {
            
        self.album = album
        //print("ALBUM: ", album)
    }

    
    func getImage(name: String) -> Image {
        
        //print("getimage: ", name)
        return Image(name)
    }


    var body: some View {
        
        VStack(alignment: .leading) {
            HStack() {
                getImage(name: album.Image)
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
                    Text(String(album.TalkCount))
                        .background(Color.white)
                        .padding(.trailing, -10)
                        .font(.system(size: 10))
                    Spacer()
                        .frame(height: 8)
                    Text(album.DisplayedDuration)
                        .background(Color.white)
                        .padding(.trailing, -10)
                        .font(.system(size: 10))
                }
            }
        }
        .frame(height:40)
        .background(NavigationLink(destination: TalkPlayerView(talk: CurrentTalk, currentTime: CurrentTalkTime), tag: "PLAY_TALK", selection: $selection) { EmptyView() } .hidden())
 

    }
}


struct AlbumListView: View {
    var title: String = ""
    var key: String = ""
    @State var selection: String?  = ""
    @State var newTitle: String?  = ""
    @State var childKey: String?  = ""
    @State var searchText: String  = ""

    @State var noCurrentTalk: Bool = false


    var body: some View {

        SearchBar(text: $searchText)
           .padding(.top, 0)

        List(TheDataModel.getAlbumData(key: key, filter: searchText)) { album in
            AlbumRow(album: album)
                .onTapGesture {
                    if album.Key.contains("ALBUM") {
                        print("HERE", album.Key)
                        selection = "ALBUMS"
                    } else {
                        selection = "TALKS"
                    }
                    
                    childKey = album.Key
                    newTitle = album.Title

                }
        }
        .background(NavigationLink(destination: TalkListView(title: newTitle!,  key: childKey!), tag: "TALKS", selection: $selection) { EmptyView() } .hidden())
        .background(NavigationLink(destination: AlbumListView(title: newTitle!, key: childKey!), tag: "ALBUMS", selection: $selection) { EmptyView() } .hidden())

        .navigationBarTitle(title, displayMode: .inline)
        .navigationBarHidden(false)

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
                        print(CurrentTalk.Title)
                        if CurrentTalk.Title == "NO TALK" {
                            print("none")
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
                        print("Edit button was tapped")
                    }) {
                        Image(systemName: "heart.fill")
                            .renderingMode(.original)

                    }
                }
            }

    }
}



