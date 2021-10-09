//
//  TalkListView.swift
//
//  Created by Christopher Minson on 9/9/21.
//  Copyright © 2022 Christopher Minson. All rights reserved.
//

import SwiftUI
import UIKit

let ICON_TALK_FAVORITE = Image("favoritebar")
let ICON_TALK_NOTATED = Image("notebar")

var TEST : TalkData? = nil

struct TalkRow: View {
    var album: AlbumData
    @ObservedObject var talk: TalkData
    
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
        
        self.stateIsFavoriteTalk = talk.isFavoriteTalk()
        self.stateIsNotatedTalk = talk.isNotatedTalk()

        stateTalkTitle = talk.Title
        if talk.isDownloadInProgress() {
            self.stateTalkTitle = "DOWNLOADING: " + stateTalkTitle
        }
    }
    
    
    func downloadCompleted() -> Void {
        print("downloadCompleted")

        stateTalkTitle = self.talk.Title
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
                Text(talk.hasTalkBeenPlayed() ? "* " + stateTalkTitle : stateTalkTitle)
                    .font(.system(size: FONT_SIZE_ROW_TITLE))
                    .foregroundColor(talk.isDownloaded ? Color.red : Color.black)
                    .background(Color.white)
                Spacer()
                VStack() {
                    Text(talk.TotalSeconds.displayInClockFormat())
                        .background(Color.white)
                        .padding(.trailing, -5)
                        .font(.system(size: FONT_SIZE_ROW_ATTRIBUTES))
                    Spacer()
                        .frame(height: 8)
                    Text(String(talk.Date))
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
                    Button(talk.isFavoriteTalk() ? "Unfavorite Talk" : "Favorite Talk") {
                        self.stateIsFavoriteTalk = talk.toggleTalkAsFavorite()
                    }
                    Button("Make Note") {
                        noteText = talk.getNoteForTalk()
                        displayNoteDialog = true
                    }
                    Button("Share Talk") {
                        self.displayShareSheet = true
                    }
                    Button("Download Talk") {
                        print("download talk")
                        displayDownloadDialog = true
                    }
                }
                
            }
            .alert(isPresented: $displayDownloadDialog) {
                Alert(
                    title: Text("Download Text"),
                    message: Text("Download talk to your device."),
                    primaryButton: .destructive(Text("Download")) {
                        stateTalkTitle = "DOWNLOADING: " + stateTalkTitle
                        talk.startDownload(notifyUI: downloadCompleted)
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
                    talk.addNoteToTalk(noteText: noteText)
                    self.stateIsNotatedTalk = talk.isNotatedTalk()
                    displayNoteDialog = false
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(height: LIST_ROW_SIZE_STANDARD)
    }

}


struct TalkListView: View {
    var album: AlbumData

    @State var selection: String?  = nil
    @State var searchText: String  = ""
    @State var selectedTalkTime: Double = 0
    @State var selectedTalk: TalkData


    init(album: AlbumData) {
        
        self.album = album
        selectedTalk = TalkData.empty()
    }
    

    var body: some View {

        SearchBar(text: $searchText)
           .padding(.top, 0)
        List(album.getFilteredTalks(filter: searchText)) { talk in
            
            TalkRow(album: album, talk: talk)
                .onTapGesture {
                    print("talk selected: ", talk.Title)
                    selectedTalk = talk
                    selectedTalkTime = 0
                    selection = "PLAY_TALK"
                }

        }
        .navigationBarTitle(album.Title, displayMode: .inline)
        .background(NavigationLink(destination: TalkPlayerView(album: album, talk: selectedTalk, elapsedTime: selectedTalkTime), tag: "PLAY_TALK", selection: $selection) { EmptyView() } .hidden())
        .background(NavigationLink(destination: TalkPlayerView(album: album, talk: selectedTalk, elapsedTime: selectedTalkTime), tag: "RESUME_TALK", selection: $selection) { EmptyView() } .hidden())

        .navigationBarHidden(false)
        .listStyle(PlainListStyle())  // ensures fills parent view


        .navigationViewStyle(StackNavigationViewStyle())
        .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Button {
                        // your action here
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
                    .hidden(!TheDataModel.currentTalkExists())
                    Spacer()
                    Button(action: {
                        print("Edit button was tapped")
                    }) {
                        Image(systemName: "heart.circle")
                            .renderingMode(.original)
                    }
                }
            }
    }
}



