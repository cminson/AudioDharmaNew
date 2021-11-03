//
//  UserAlbumListView.swift
//
//  Implements the view of custom user albums.
//
//  Created by Christopher on 10/14/21.
//

import Foundation
import SwiftUI
import UIKit



struct UserAlbumRow: View {
    
    @ObservedObject var album: AlbumData
    @State var selection: String?  = ""
    @State var displayEditCustomAlbum = false
    @State var displayDeleteAlbum = false
    @State var albumTitle: String
    
    init(album: AlbumData) {
        self.album = album
        
        albumTitle = album.Title
        print("UserAlbum: ", album.Title)
        for talk in album.talkList {
            print("Talk: ", talk.Title)
        }
    }

    var body: some View {
        
        VStack(alignment: .leading) {
            HStack() {
                album.ImageName.toImage()
                    .resizable()
                    .frame(width: LIST_IMAGE_WIDTH, height:LIST_IMAGE_HEIGHT)
                    .clipShape(Circle())
                    .padding(.leading, LIST_LEFT_MARGIN_OFFSET)
                Text("\(album.Title)")
                    .font(.system(size: FONT_SIZE_ROW_TITLE))
                    .padding(.leading, 0)
                Spacer()
                VStack(alignment: .trailing, spacing: 8) {
                    Text(album.totalTalks.displayInCommaFormat())
                        .padding(.trailing, -10)
                        .font(.system(size: FONT_SIZE_ROW_ATTRIBUTES))
                }
            }
            .contextMenu {
                Button("Edit Album ") {
                    selection = "EDIT_ALBUM"
                }
                Button("Delete Album") {
                    print("delete ablum")
                    displayDeleteAlbum = true
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                selection = "TALKS"
            }
        }
        .background(NavigationLink(destination: TalkListView(album: album), tag: "TALKS", selection: $selection) { EmptyView() } .hidden())
        .background(NavigationLink(destination: AlbumListView(album: album), tag: "ALBUMS", selection: $selection) { EmptyView() } .hidden())
        .background(NavigationLink(destination: UserEditTalkListView(album: album, editing: true), tag: "EDIT_ALBUM", selection: $selection) { EmptyView() } .hidden())
        .background(NavigationLink(destination: UserEditTalkListView(album: album, editing: false), tag: "NEW_ALBUM", selection: $selection) { EmptyView() } .hidden())

        // The Following line is NECESSARY.   (https://forums.swift.org/t/14-5-beta3-navigationlink-unexpected-pop/45279)
        .background(NavigationLink(destination: EmptyView()) {EmptyView()}.hidden())  // don't delete this mofo
        .frame(height: LIST_ROW_SIZE_STANDARD)
        .frame(maxWidth: .infinity)
        .alert(isPresented: $displayDeleteAlbum) {
            Alert(
                title: Text("Remove Custom Album?"),
                message: Text("Press OK to delete this album"),
                primaryButton: .destructive(Text("OK")) {
                    if let index = TheDataModel.CustomUserAlbums.albumList.firstIndex(of: album) {
                        
                        TheDataModel.CustomUserAlbums.albumList.remove(at: index)
                        TheDataModel.saveCustomUserAlbums()
                    }
                },
                secondaryButton: .cancel()
            )
        }

     }
}


struct UserAlbumListView: View {
    
    @ObservedObject var album: AlbumData

    @State var selectedAlbum: AlbumData
    @State var selection: String?  = ""
    @State var searchText: String  = ""
    @State var noCurrentTalk: Bool = false
    
    @State var selectedTalk: TalkData
    @State var selectedTalkTime: Double
    @State var displayNewCustomAlbum = false
    
    @State private var textStyle = UIFont.TextStyle.body
    @State private var albumTitle = ""
    @State var displayNoCurrentTalk: Bool = false

    
    init(album: AlbumData) {
        
        self.album = album
        self.selectedAlbum = AlbumData.empty()
        self.selectedTalk = TalkData.empty()
        self.selectedTalkTime = 0
    }
    
    
    var body: some View {

        SearchBar(text: $searchText)
           .padding(.top, 0)
        List(TheDataModel.CustomUserAlbums.getFilteredAlbums(filter: searchText)) { album in
            UserAlbumRow(album: album)
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
        .background(NavigationLink(destination: UserEditTalkListView(album: selectedAlbum, editing: true), tag: "EDIT_ALBUM", selection: $selection) { EmptyView() } .hidden())
        .background(NavigationLink(destination: UserEditTalkListView(album: selectedAlbum, editing: false), tag: "NEW_ALBUM", selection: $selection) { EmptyView() } .hidden())
        .background(NavigationLink(destination: HelpPageView(), tag: "HELP", selection: $selection) { EmptyView() } .hidden())
        .background(NavigationLink(destination: TalkPlayerView(album: selectedAlbum, talk: selectedTalk, elapsedTime: selectedTalkTime), tag: "RESUME_TALK", selection: $selection) { EmptyView() } .hidden())
        .background(NavigationLink(destination: DonationPageView(), tag: "DONATE", selection: $selection) { EmptyView() } .hidden())

        .navigationBarTitle(album.Title, displayMode: .inline)
        .toolbar {
            Button("New Album") {
                
                selectedAlbum.Title = "New Album"
                selection = "NEW_ALBUM"
            }
        }
        .navigationBarHidden(false)
        .listStyle(PlainListStyle())  // ensures fills parent view
        .navigationViewStyle(StackNavigationViewStyle())

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
               }) {
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
    }
    
}



