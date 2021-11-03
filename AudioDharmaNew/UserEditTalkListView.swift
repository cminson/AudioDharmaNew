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

var EditingCustomAlbumTalks = false

struct UserTalkRow: View {
  
    var album: AlbumData
    @ObservedObject var talk: TalkData
    var talkSet: Set<TalkData>
    @State var selection: String?  = nil
    @State private var stateIsInCustomAlbum : Bool


    init(album: AlbumData, talk: TalkData, talkSet: Set<TalkData>) {
        
        //self.id = UUID()
        self.album = album
        self.talk = talk
        self.talkSet = talkSet
        self.stateIsInCustomAlbum = talkSet.contains(talk)
    }
    
    
    var body: some View {
                
        VStack(alignment: .leading) {
            HStack() {
                 talk.Speaker.toImage()
                    .resizable()
                    .frame(width: LIST_IMAGE_WIDTH, height: LIST_IMAGE_HEIGHT)
                    .clipShape(Circle())
                    .padding(.leading, LIST_LEFT_MARGIN_OFFSET)
                Spacer()
                    .frame(width: 6)
                Text(TheDataModel.hasTalkBeenPlayed(talk: talk) ? "* " + talk.Title : talk.Title)
                    .font(.system(size: FONT_SIZE_ROW_TITLE))
                    .foregroundColor(TheDataModel.hasBeenDownloaded(talk: talk) ? COLOR_DOWNLOADED_TALK : Color(UIColor.label))
                Spacer()
                VStack(alignment: .trailing, spacing: 8) {
                    Text(talk.TotalSeconds.displayInClockFormat())
                        .padding(.trailing, -5)
                        .font(.system(size: FONT_SIZE_ROW_ATTRIBUTES))
                    Text(String(talk.Date))
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
            .onTapGesture {
                EditingCustomAlbumTalks = true
                stateIsInCustomAlbum.toggle()
                
                if stateIsInCustomAlbum == true {
                    print("Adding: ", talk.Title, album.Title)
                    self.album.talkList.append(self.talk)
                } else {
                    if let index = album.talkList.firstIndex(of: self.talk) {
                        print("Removing: ", talk.Title)

                        self.album.talkList.remove(at: index)
                    }
                }
                TheDataModel.computeAlbumStats(album: album)
            }
        }
        .contentShape(Rectangle())
        .background(stateIsInCustomAlbum ? COLOR_HIGHLIGHTED_TALK : Color(UIColor.systemBackground))
        .background(NavigationLink(destination: TalkListView(album: TheDataModel.SimilarTalksAlbum), tag: "TALKS", selection: $selection) { EmptyView() } .hidden())
        .frame(height: LIST_ROW_SIZE_STANDARD)
    }
}


struct UserEditTalkListView: View {
    var album: AlbumData
    var editing: Bool


    @State var selection: String?  = nil
    @State var searchText: String  = ""
    @State var selectedTalkTime: Double = 0
    @State var selectedTalk: TalkData
    @State var selectedAlbum: AlbumData

    var talkSet : Set <TalkData>
    
    init(album: AlbumData, editing:  Bool) {
        
        self.album = album
        self.editing = editing
        
        selectedAlbum = album
        selectedTalk = TalkData.empty()
 
        self.talkSet = Set(album.talkList)
    }
    
    
    var body: some View {

        VStack(spacing: 0) {
            Spacer().frame(height: 10)
            Text("Album Title")
            Spacer().frame(height:5)
            TextField("", text: $selectedAlbum.Title)
                .padding(.horizontal)
                .frame(width: 200, height: 20)
                .border(Color.gray)
            Spacer().frame(height:15)
            Text("Choose Talks in Album")
            Spacer().frame(height:5)

            SearchBar(text: $searchText)
               .padding(.top, 0)
            List(album.getFilteredUserTalks(filter: searchText, editing: EditingCustomAlbumTalks)) { talk in
                
                UserTalkRow(album: album, talk: talk, talkSet: talkSet)
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
               Spacer()
               Button(action: {
                   selection = "RESUME_TALK"
                   selectedTalk = CurrentTalk
                   selectedTalkTime = CurrentTalkElapsedTime
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
        .onAppear {
            EditingCustomAlbumTalks = false
        }
        .onDisappear {
            EditingCustomAlbumTalks = false
            
            print("disappear",  editing)

            if editing == false {
                print("saving new album")

                  TheDataModel.CustomUserAlbums.albumList.append(album)

            }
            TheDataModel.computeAlbumStats(album: album)
            TheDataModel.saveCustomUserAlbums()
            

        
        }
    }
    
}


