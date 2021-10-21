//
//  TalkListView.swift
//
//  General talks view.
//
//  Created by Christopher Minson on 9/9/21.
//  Copyright © 2022 Christopher Minson. All rights reserved.
//

import SwiftUI
import UIKit

let ICON_TALK_FAVORITE = Image("favoritebar")
let ICON_TALK_NOTATED = Image("notebar")


struct TalkRow: View {
  
    var album: AlbumData
    var talk: TalkData
    
    @State private var display = false
    @State private var displayNoteDialog = false
    @State private var displayDownloadDialog = false
    @State private var displayShareSheet = false
    @State var selection: String?  = nil
    @State private var noteText = ""
    @State private var stateIsFavoriteTalk : Bool
    @State private var stateIsNotatedTalk : Bool
    @State private var stateTalkTitle: String
    @State private var textStyle = UIFont.TextStyle.body
    
    
    init(album: AlbumData, talk: TalkData) {
        
        self.album = album
        self.talk = talk
                
        stateIsFavoriteTalk = TheDataModel.isFavoriteTalk(talk: talk)
        stateIsNotatedTalk = TheDataModel.isNotatedTalk(talk: talk)

        stateTalkTitle = talk.Title
        if TheDataModel.isDownloadInProgress(talk: talk) {
            stateTalkTitle = "DOWNLOADING: " + stateTalkTitle
        }
     
    }
    
    
    func downloadCompleted() {
        print("downloadCompleted")
        stateTalkTitle = self.talk.Title
    }
    
    func debug() -> Bool {
        
        print("ROW DISPLAY")
        return true
    }
     
    
    var body: some View {
                
        VStack(alignment: .leading) {
            HStack() {
                //Text(self.debug() ? stateTalkTitle : stateTalkTitle)
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
                Text(TheDataModel.hasTalkBeenPlayed(talk: talk) ? "* " + stateTalkTitle : stateTalkTitle)
                    .font(.system(size: FONT_SIZE_ROW_TITLE))
                    .foregroundColor(TheDataModel.hasBeenDownloaded(talk: talk) ? Color.red : Color.black)
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
                        .hidden(!stateIsFavoriteTalk)
                    ICON_TALK_NOTATED
                        .resizable()
                        .frame(width: 12, height: 12)
                        .hidden(!stateIsNotatedTalk)
                 }
                .padding(.trailing, -10)
                .contextMenu {
                    Button("Get Similar Talks") {
                        let signalComplete = DispatchSemaphore(value: 0)
                        TheDataModel.downloadSimilarityData(talk: talk, signalComplete: signalComplete)
                        signalComplete.wait()
                        selection = "TALKS"
                    }
                    Button("Favorite | Unfavorite") {
                        self.stateIsFavoriteTalk = TheDataModel.toggleTalkAsFavorite(talk: talk)
                    }
                    Button("Note") {
                        noteText = TheDataModel.getNoteForTalk(talk: talk)
                        self.displayNoteDialog = true
                    }
                    Button("Share Talk") {
                        self.displayShareSheet = true
                    }
                    .frame(width: 300)
                    Button("Download | Remove Download") {
                        if TheDataModel.DownloadInProgress == false {
                            self.displayDownloadDialog = true
                        }
                    }
                }
            }
        
            .alert(isPresented: $displayDownloadDialog) {
                Alert(
                    title: Text(TheDataModel.hasBeenDownloaded(talk: talk) ? "Remove Downloaded Talk" : "Download Talk"),
                    message: Text(TheDataModel.hasBeenDownloaded(talk: talk) ? "Remove Downloaded Talk" : "Download Talk"),
                    primaryButton: .destructive(Text("OK")) {
                        if TheDataModel.hasBeenDownloaded(talk: talk) {
                            TheDataModel.unsetTalkAsDownloaded(talk:talk)
                        } else {
                            if TheDataModel.DownloadInProgress == false {
                                stateTalkTitle = "DOWNLOADING: " + stateTalkTitle
                                TheDataModel.startDownload(talk: talk, success: downloadCompleted)
                            }
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
             .sheet(isPresented: $displayShareSheet) {
                let shareText = "\(talk.Title) by \(talk.Speaker) \nShared from the iPhone AudioDharma app"
                let objectsToShare: URL = URL(string: URL_MP3_HOST + talk.URL)!
                let sharedObjects:[AnyObject] = [objectsToShare as AnyObject, shareText as AnyObject]

                ShareSheet(activityItems: sharedObjects)
            }
            
        }
        .contentShape(Rectangle())
      
        .background(NavigationLink(destination: TalkListView(album: TheDataModel.SimilarTalksAlbum), tag: "TALKS", selection: $selection) { EmptyView() } .hidden())
        .popover(isPresented: $displayNoteDialog) {
            VStack() {
                Text(talk.Title)
                    .padding()
                Spacer()
                    .frame(height:30)
                TextView(text: $noteText, textStyle: $textStyle)
                    .padding(.horizontal)
                    .frame(height: 100)
                    .border(Color.gray)
                Spacer()
                    .frame(height:30)
                Button("Done") {
                    TheDataModel.addNoteToTalk(talk: talk, noteText: noteText)
                    self.stateIsNotatedTalk = TheDataModel.isNotatedTalk(talk: talk)
                    displayNoteDialog = false
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(height: LIST_ROW_SIZE_STANDARD)
    }
}


struct TalkListView: View {
    @ObservedObject var album: AlbumData
    //var album: AlbumData


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
        List(album.getFilteredTalks(filter: searchText), id: \.self) { talk in
            
            TalkRow(album: album, talk: talk)
                .onTapGesture {
                    print("talk selected: ", talk.Title)
                    selectedTalk = talk
                    selectedTalkTime = 0
                    selection = "PLAY_TALK"
                }
        }
        .id(UUID())
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



