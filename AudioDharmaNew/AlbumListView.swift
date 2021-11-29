//
//  AlbumListView.swift
//
//  General album view.
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
        .background(Color(hex: COLOR_HEX_BACKGROUND_SECTION))
        .frame(maxWidth: .infinity)
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
     }
}


struct AlbumRow: View {
    
    @ObservedObject var album: AlbumData
    @State private var selection: String?  = ""

    
    init(album: AlbumData) {
        self.album = album
    }
    
    
    var body: some View {
        
        VStack(alignment: .leading) {
            HStack() {
                album.imageName.toImage()
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: LIST_IMAGE_WIDTH, height:LIST_IMAGE_HEIGHT)
                    .clipShape(Circle())
                    .padding(.leading, LIST_LEFT_MARGIN_OFFSET)
                Text("\(album.title)")
                    .font(.system(size: FONT_SIZE_ROW_TITLE))
                    .padding(.leading, 0)
                Spacer()
                VStack(alignment: .trailing, spacing: 8) {
                    Spacer()
                    Text(album.totalTalks.displayInCommaFormat())
                        .padding(.trailing, -10)
                        .font(.system(size: FONT_SIZE_ROW_ATTRIBUTES))
                    Spacer()
                }
                Spacer().frame(width: 8)

            }
            .contentShape(Rectangle())
            .onTapGesture {

                if KEYS_TO_ALBUMS.contains(album.key) {
                    selection = "ALBUMS"
                }
                else if KEYS_TO_USER_ALBUMS.contains(album.key) {
                    selection = "USERALBUMS"
                } else {
                    selection = "TALKS"
                }

            }
        }
        .background(NavigationLink(destination: TalkListView(album: album), tag: "TALKS", selection: $selection) { EmptyView() } .hidden())
        .background(NavigationLink(destination: AlbumListView(album: album), tag: "ALBUMS", selection: $selection) { EmptyView() } .hidden())
        .background(NavigationLink(destination: UserAlbumListView(album: album), tag: "USERALBUMS", selection: $selection) { EmptyView() } .hidden())

        // Ref for the following line.  Keep for now: (https://forums.swift.org/t/14-5-beta3-navigationlink-unexpected-pop/45279)
        .background(NavigationLink(destination: EmptyView()) {EmptyView()}.hidden())
        .frame(height: LIST_ROW_SIZE_STANDARD)
        .frame(maxWidth: .infinity)
     }
}


struct AlbumListView: View {
    
    @Environment(\.presentationMode) var mode

    var album: AlbumData
    
    @State private var selectedAlbum: AlbumData = AlbumData.empty()
    @State private var selection: String?  = ""
    @State private var searchText: String  = ""
    @State private var noCurrentTalk: Bool = false
    @State private var selectedTalk: TalkData = TalkData.empty()
    @State private var selectedTalkTime: Double = 0
    @State private var displayNoCurrentTalk: Bool = false
    @State private var sharedURL: String = ""

    
    init(album: AlbumData) {
        
        self.album = album
        

     }
    
    
    var body: some View {

        SearchBar(text: $searchText)
           .padding(.top, 0)
        List(album.getFilteredAlbums(filter: searchText)) { album in
           AlbumRow(album: album)
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
        .background(NavigationLink(destination: HelpPageView(), tag: "HELP", selection: $selection) { EmptyView() } .hidden())
        .background(NavigationLink(destination: TalkPlayerView(album: selectedAlbum, talk: selectedTalk, startTime: selectedTalkTime), tag: "RESUME_TALK", selection: $selection){ EmptyView() } .hidden())
        .background(NavigationLink(destination: DonationPageView(), tag: "DONATE", selection: $selection) { EmptyView() } .hidden())

        .navigationBarTitle(album.title, displayMode: .inline)
        .navigationBarHidden(false)
        .listStyle(PlainListStyle())  // ensures fills parent view
        .navigationViewStyle(StackNavigationViewStyle())
        .toolbar {
            // to fix the back button disappeared
            ToolbarItem(placement: .navigationBarLeading) {
                Text("")
            }
        }
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
       } // end toolbar
 

    } // end view

}



