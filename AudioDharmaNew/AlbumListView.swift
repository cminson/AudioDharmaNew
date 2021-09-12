//
//  AlbumListView.swift
//  AudioDharmaNew
//
//  Created by Christopher Minson on 9/9/21.
//

import SwiftUI
import UIKit



struct AlbumRow: View {
    var album: AlbumData
    
    init(album: AlbumData) {
            
        self.album = album
        print("ALBUM: ", album)
    }

    
    func getImage(name: String) -> Image {
        
        print("getimage: ", name)
        return Image(name)
    }


    var body: some View {
        
        VStack(alignment: .leading) {
            HStack() {
                getImage(name: album.Image)
                    .resizable()
                    .frame(width:50, height:50)
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
    }
}


struct AlbumListView: View {
    var title: String = ""
    var contentKey: String = ""
    @State var selection: String?  = ""
    @State var newTitle: String?  = ""
    @State var newContentKey: String?  = ""


    var body: some View {


        List(TheDataModel.getAlbumData(key: contentKey)) { album in
            AlbumRow(album: album)
                .onTapGesture {
                    if album.Key.contains("ALBUM") {
                        print("HERE", album.Key)
                        selection = "ALBUMS"
                    } else {
                        selection = "TALKS"
                    }
                    
                    newContentKey = album.Key
                    newTitle = album.Title

                }
        }
        .background(NavigationLink(destination: TalkListView(title: newTitle!,  contentKey: newContentKey!), tag: "TALKS", selection: $selection) { EmptyView() } .hidden())
        .background(NavigationLink(destination: AlbumListView(title: newTitle!, contentKey: newContentKey!), tag: "ALBUMS", selection: $selection) { EmptyView() } .hidden())

        .navigationBarTitle(title, displayMode: .inline)
        .navigationBarHidden(false)

        .navigationViewStyle(StackNavigationViewStyle())
    }
}



