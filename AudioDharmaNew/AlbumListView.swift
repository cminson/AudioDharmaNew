//
//  AlbumListView.swift
//  AudioDharmaNew
//
//  Created by Christopher on 9/9/21.
//

import SwiftUI
import UIKit



struct AlbumRow: View {
    var album: AlbumData
    
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
            .background(Color.red)
            .padding(.leading, -15)
        Text("\(album.Title)")
            .font(.system(size: 14))
            .background(Color.white)
        Spacer()
        Text("42")
            .background(Color.white)
            .padding(.trailing, -10)
            .font(.system(size: 10))
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
                    if album.Content.contains("ALBUM") {
                        print("HERE", album.Content)
                        selection = "ALBUMS"
                    } else {
                        selection = "TALKS"
                    }
                    
                    newContentKey = album.Content
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



