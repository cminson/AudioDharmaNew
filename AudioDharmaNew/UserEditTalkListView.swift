//
//  UserEditTalkListView.swift
//
//  Implements the editable list of talks that can be added to a custom user album.
//
//  Created by Christopher Minson on 9/9/21.
//  Copyright © 2022 Christopher Minson. All rights reserved.
//

import SwiftUI
import UIKit


var EditTalkList : [TalkData] = []

struct UserTalkRow: View {
  
    var album: AlbumData
    @ObservedObject var talk: TalkData
    var talkSet: Set<TalkData>
    @State var selection: String?  = nil
    @State var stateTalkTitle: String
    @State var talkInAlbum : Bool

    
    init(album: AlbumData, talk: TalkData, talkSet: Set<TalkData>) {
        
        self.album = album
        self.talk = talk
        self.talkSet = talkSet
        self.talkInAlbum = talkSet.contains(talk)
        self.stateTalkTitle = talk.title + " | " + talk.speaker

    }
    
    
    var body: some View {
                
        VStack(alignment: .leading) {
            HStack() {
                 talk.speaker.toImage()
                    .resizable()
                    .frame(width: LIST_IMAGE_WIDTH, height: LIST_IMAGE_HEIGHT)
                    .clipShape(Circle())
                    .padding(.leading, LIST_LEFT_MARGIN_OFFSET)
                Spacer()
                    .frame(width: 6)
                Text(TheDataModel.hasTalkBeenPlayed(talk: talk) ? "* " + self.stateTalkTitle : self.stateTalkTitle)
                    .font(.system(size: FONT_SIZE_ROW_TITLE))
                    .foregroundColor(TheDataModel.hasBeenDownloaded(talk: talk) ? COLOR_DOWNLOADED_TALK : Color(UIColor.label))
                Spacer()
                VStack(alignment: .trailing, spacing: 8) {
                    Text(talk.totalSeconds.displayInClockFormat())
                        .padding(.trailing, -5)
                        .font(.system(size: FONT_SIZE_ROW_ATTRIBUTES))
                    Text(String(talk.date))
                        .padding(.trailing, -5)
                        .font(.system(size: FONT_SIZE_ROW_ATTRIBUTES))
                }
                VStack() {
                    ICON_TALK_FAVORITE
                        .resizable()
                        .frame(width: NOTATE_FAVORITE_ICON_WIDTH, height: NOTATE_FAVORITE_ICON_HEIGHT)
                        .hidden(!TheDataModel.isFavoriteTalk(talk: talk))
                    ICON_TALK_NOTATED
                        .resizable()
                        .frame(width: NOTATE_FAVORITE_ICON_WIDTH, height: NOTATE_FAVORITE_ICON_HEIGHT)
                        .hidden(!TheDataModel.isNotatedTalk(talk: talk))
                 }
                .padding(.trailing, -10)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                talkInAlbum.toggle()
                if talkInAlbum == true {
                    print("Adding: ", talk.title, album.title)
                    EditTalkList.append(self.talk)
                } else {
                    if let index = EditTalkList.firstIndex(of: self.talk) {
                        print("Removing: ", talk.title)
                        EditTalkList.remove(at: index)
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .background(talkInAlbum ? COLOR_HIGHLIGHTED_TALK : Color(UIColor.systemBackground))
        .frame(height: LIST_ROW_SIZE_STANDARD)
    }
}


struct UserEditTalkListView: View {
    var album: AlbumData
    var creatingNewAlbum: Bool


    @State var selection: String?  = nil
    @State var searchText: String  = ""
    @State var selectedAlbum: AlbumData
    var talkSet : Set <TalkData>
    
    init(album: AlbumData, creatingNewAlbum:  Bool) {
        
        self.album = album
        self.creatingNewAlbum = creatingNewAlbum
        
        selectedAlbum = album
 
        self.talkSet = Set(album.talkList)
    }
    
    
    var body: some View {

        VStack(spacing: 0) {

            Spacer().frame(height: 10)
            HStack() {
                Text("Title:")
                Spacer().frame(width:5)
                TextField("", text: $selectedAlbum.title)
                    .padding(.horizontal)
                    .frame(width: 200, height: 30)
                    .border(Color.gray)
            }
            Spacer().frame(height:25)
            Text("Choose Talks in Album")
            Spacer().frame(height:5)

            SearchBar(text: $searchText)
               .padding(.top, 0)
            List(album.getFilteredUserTalks(filter: searchText)) { talk in
                
                UserTalkRow(album: album, talk: talk, talkSet: talkSet)

            }
        }
        .navigationBarTitle(album.title, displayMode: .inline)
        .navigationBarHidden(false)
        .listStyle(PlainListStyle())  // ensures fills parent view
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            EditTalkList = album.talkList
        }
        .onDisappear {
            
            album.talkList = EditTalkList
            if creatingNewAlbum == true {

                  TheDataModel.CustomUserAlbums.albumList.append(album)
            }
            TheDataModel.computeAlbumStats(album: album)
            TheDataModel.saveCustomUserAlbums()

        }
    }
    
}


