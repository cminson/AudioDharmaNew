//
//  UserTalkListView.swift
//
//  Created by Christopher Minson on 9/9/21.
//  Copyright © 2022 Christopher Minson. All rights reserved.
//

import SwiftUI
import UIKit


struct UserTalkRow: View {
  
    //let id = UUID()
    var album: AlbumData
    @ObservedObject var talk: TalkData
    

    @State var selection: String?  = nil

    
    init(album: AlbumData, talk: TalkData) {
        
        //self.id = UUID()
        self.album = album
        self.talk = talk
            
     
    }
    
    var body: some View {
                
        VStack(alignment: .leading) {
            HStack() {
                talk.Speaker.toImage()
                    .resizable()
                    //.aspectRatio(contentMode: .fit)
                    //.frame(width: LIST_IMAGE_HEIGHT)
                    .frame(width: LIST_IMAGE_WIDTH, height: LIST_IMAGE_HEIGHT)
                    .clipShape(Circle())
                    .background(Color.white)
                    .padding(.leading, -15)
                Spacer()
                    .frame(width: 6)
                Text(talk.hasTalkBeenPlayed() ? "* " + talk.Title : talk.Title)
                    .font(.system(size: FONT_SIZE_ROW_TITLE))
                    .foregroundColor(talk.hasBeenDownloaded() ? Color.red : Color.black)
                    .background(Color.white)
                Spacer()
                VStack(alignment: .trailing, spacing: 8) {
                    Text(album.albumType == AlbumType.ACTIVE ?  talk.TotalSeconds.displayInClockFormat() : talk.City)
                        .background(Color.white)
                        .padding(.trailing, -5)
                    
                        .font(.system(size: FONT_SIZE_ROW_ATTRIBUTES))
                    Text(String(album.albumType == AlbumType.ACTIVE ?  talk.Date : talk.Country))
                        .background(Color.white)
                        .padding(.trailing, -5)
                        .font(.system(size: FONT_SIZE_ROW_ATTRIBUTES))
                }
                VStack() {
                    ICON_TALK_FAVORITE
                        .resizable()
                        .frame(width: 12, height: 12)
                        .hidden(!talk.isFavoriteTalk())
                    ICON_TALK_NOTATED
                        .resizable()
                        .frame(width: 12, height: 12)
                        .hidden(!talk.isNotatedTalk())
                 }

                .padding(.trailing, -10)
            }
        }
        .contentShape(Rectangle())
      
        .background(NavigationLink(destination: TalkListView(album: TheDataModel.SimilarTalksAlbum), tag: "TALKS", selection: $selection) { EmptyView() } .hidden())

        .frame(height: LIST_ROW_SIZE_STANDARD)
    }
    

}


struct UserEditTalkListView: View {
    var album: AlbumData

    @State var selection: String?  = nil
    @State var searchText: String  = ""
    @State var selectedTalkTime: Double = 0
    @State var selectedTalk: TalkData
    @State var selectedAlbum: AlbumData

    
    init(album: AlbumData) {
        
        self.album = album
        selectedTalk = TalkData.empty()
        selectedAlbum = AlbumData.empty()
    }
    

    var body: some View {

        SearchBar(text: $searchText)
           .padding(.top, 0)
        List(album.getFilteredUserTalks(filter: searchText)) { talk in
            
            UserTalkRow(album: album, talk: talk)
                .onTapGesture {
                    print("talk selected: ", talk.Title)
                    selectedTalk = talk
                    selectedTalkTime = 0
                    selection = "PLAY_TALK"
                }

        }
        .navigationBarTitle(album.Title, displayMode: .inline)
        .background(NavigationLink(destination: TalkPlayerView(album: album, talk: selectedTalk, elapsedTime: selectedTalkTime), tag: "PLAY_TALK", selection: $selection) { EmptyView() } .hidden())
        .background(NavigationLink(destination: HelpPageView(), tag: "HELP", selection: $selection) { EmptyView() } .hidden())
        .background(NavigationLink(destination: TalkPlayerView(album: selectedAlbum, talk: selectedTalk, elapsedTime: selectedTalkTime), tag: "RESUME_TALK", selection: $selection) { EmptyView() } .hidden())
        .background(NavigationLink(destination: DonationPageView(), tag: "DONATE", selection: $selection) { EmptyView() } .hidden())

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
               .foregroundColor(.black)
               Spacer()
               Button(action: {
                   selection = "RESUME_TALK"
                   selectedTalk = CurrentTalk
                   selectedTalkTime = CurrentTalkElapsedTime
               }) {
                   Text("Resume Talk")
                      
               }
               .foregroundColor(.black)
               .hidden(!TheDataModel.currentTalkExists())
               Spacer()
               Button(action: {
                   selection = "DONATE"

              }) {
                   Image(systemName: "heart.circle")
               }
              .foregroundColor(.black) // to ensure the toolbar icons don't turn blue

           }
       }
    }
}
