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

var SharedTalk = TalkData.empty()

struct TalkRow: View {

    var album: AlbumData
    var talk: TalkData
    
    @State private var display = false
    @State private var displayNoteDialog = false
    @State private var displayDownloadDialog = false
    @State private var displayShareSheet = false
    @State private var selection: String?  = nil
    @State private var noteText = ""
    @State private var stateIsFavoriteTalk : Bool
    @State private var stateIsNotatedTalk : Bool
    @State private var stateTalkTitle: String
    @State private var textStyle = UIFont.TextStyle.body
    @State private var displayDownloadInProgress = false
    @State private var sharedURL: String = ""



    init(album: AlbumData, talk: TalkData) {
        
        self.album = album
        self.talk = talk
        
        stateIsFavoriteTalk = TheDataModel.isFavoriteTalk(talk: talk)
        stateIsNotatedTalk = TheDataModel.isNotatedTalk(talk: talk)

        if album.key == KEY_ALL_TALKS {
            stateTalkTitle = talk.title + " | " + talk.speaker

        } else {
            stateTalkTitle = talk.title

        }
        if TheDataModel.isDownloadInProgress(talk: talk) {
            stateTalkTitle = "DOWNLOADING: " + stateTalkTitle
        }
    }
    
       
    func downloadCompleted() {

        stateTalkTitle = self.talk.title
    }
    
    
    var body: some View {
                
        VStack(alignment: .leading) {
            HStack() {
                talk.speaker.toImage()
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: LIST_IMAGE_WIDTH, height: LIST_IMAGE_HEIGHT)
                    .clipShape(Circle())
                    .padding(.leading, LIST_LEFT_MARGIN_OFFSET)
                Spacer().frame(width: 6)
                Text(TheDataModel.hasTalkBeenPlayed(talk: talk) ? "\u{2022} " + stateTalkTitle : stateTalkTitle)
                    .font(.system(size: FONT_SIZE_ROW_TITLE))
                    .foregroundColor(TheDataModel.hasBeenDownloaded(talk: talk) ? COLOR_DOWNLOADED_TALK : Color(UIColor.label))
                Spacer()
                VStack(alignment: .trailing, spacing: 5) {
                    Text(album.albumType == AlbumType.ACTIVE ?  talk.totalSeconds.displayInClockFormat() : talk.city)
                        .padding(.trailing, -5)
                        .font(.system(size: FONT_SIZE_ROW_ATTRIBUTES))
                    Text(String(album.albumType == AlbumType.ACTIVE ?  talk.date : talk.country))
                        .padding(.trailing, -5)
                        .font(.system(size: FONT_SIZE_ROW_ATTRIBUTES))
                }
                .alert(isPresented: $displayDownloadInProgress) {
                    Alert(
                        title: Text("Download  in Progress"),
                        message: Text("Please wait until the other download completes"),
                        dismissButton: .default(Text("OK")) {
                        }
                    )
                }
                VStack(spacing: 5) {
                    ICON_TALK_FAVORITE
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: NOTATE_FAVORITE_ICON_WIDTH, height: NOTATE_FAVORITE_ICON_WIDTH)
                        .foregroundColor(Color.orange)
                        .hidden(!stateIsFavoriteTalk)
                    ICON_TALK_NOTATED
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: NOTATE_FAVORITE_ICON_WIDTH, height: NOTATE_FAVORITE_ICON_WIDTH)
                        .hidden(!stateIsNotatedTalk)
                 }
                .alert(isPresented: $displayDownloadDialog) {
                    Alert(
                        title: Text(TheDataModel.hasBeenDownloaded(talk: talk) ? "Remove Downloaded Talk" : "Download Talk"),
                        //primaryButton: .destructive(Text("OK")) {
                        primaryButton: .default (Text("OK")) {

                            if TheDataModel.hasBeenDownloaded(talk: talk) {
                                TheDataModel.unsetTalkAsDownloaded(talk:talk)
                            } else {
                                if TheDataModel.DownloadInProgress == false {
                                    displayDownloadInProgress = false
                                    stateTalkTitle = "DOWNLOADING: " + stateTalkTitle
                                    TheDataModel.downloadTalk(talk: talk, success: downloadCompleted)
                                }                         }
                        },
                        secondaryButton: .cancel()
                    )
                }
                .padding(.trailing, -10)
                .contextMenu {
                    Button("Show Similar Talks") {
                        let signalComplete = DispatchSemaphore(value: 0)
                        TheDataModel.downloadSimilarityData(talk: talk, signalComplete: signalComplete)
                        signalComplete.wait()
                        selection = "TALKS"
                    }
                    Button("Favorite | Remove Favorite") {
                        self.stateIsFavoriteTalk = TheDataModel.toggleTalkAsFavorite(talk: talk)
                    }
                    Button("Note") {
                        noteText = TheDataModel.getNoteForTalk(talk: talk)
                        self.displayNoteDialog = true
                    }
                    Button("Share Talk") {
                        SharedTalk = self.talk
                        self.displayShareSheet = true
                    }
                    Button("Download | Remove Download") {
                        if TheDataModel.DownloadInProgress == false {
                            self.displayDownloadDialog = true
                        } else {
                            self.displayDownloadInProgress = true
                        }
                    }
                }
            }
             .sheet(isPresented: $displayShareSheet) {
                let shareText = "\(talk.title) by \(talk.speaker) \nShared from the iPhone AudioDharma app"
                 let objectsToShare: URL = URL(string: SHARE_URL_MP3_HOST + talk.fileName)!

                let sharedObjects:[AnyObject] = [objectsToShare as AnyObject, shareText as AnyObject]

                ShareSheet(activityItems: sharedObjects)
            }
        }

        .contentShape(Rectangle())
        .background(NavigationLink(destination: TalkListView(album: TheDataModel.SimilarTalksAlbum), tag: "TALKS", selection: $selection) { EmptyView() } .hidden())
        .popover(isPresented: $displayNoteDialog) {
            VStack() {
                Spacer()
                    .frame(height:20)
                Text("Edit Notes:  " + talk.title)
                Spacer()
                    .frame(height:5)
                TextView(text: $noteText, textStyle: $textStyle)
                    .padding(.horizontal)
                    .frame(height: 100)
                    .border(Color.gray)
                Spacer()
                    .frame(height:20)
   
                HStack() {
                    Button("Delete") {
                        noteText = ""
                        TheDataModel.addNoteToTalk(talk: talk, noteText: noteText)
                        self.stateIsNotatedTalk = TheDataModel.isNotatedTalk(talk: talk)
                        self.displayNoteDialog = false
                    }
                    Spacer()
                        .frame(width: 60)
                    Button("OK") {
                        TheDataModel.addNoteToTalk(talk: talk, noteText: noteText)
                        self.stateIsNotatedTalk = TheDataModel.isNotatedTalk(talk: talk)
                        self.displayNoteDialog = false
                    }
                }
                Spacer()
            }
            .frame(width: 300)
            .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
        }
        .frame(height: LIST_ROW_SIZE_STANDARD)

    }
}


struct TalkListView: View {
    @ObservedObject var album: AlbumData
    //var album: AlbumData

    @State private var selection: String?  = nil
    @State private var searchText: String  = ""
    @State private var selectedTalkTime: Double = 0
    @State private var selectedTalk: TalkData
    @State private var selectedAlbum: AlbumData
    @State private var displayNoCurrentTalk = false
    @State private var sharedURL: String = ""


    init(album: AlbumData) {
        
        self.album = album
        self.selectedTalk = TalkData.empty()
        self.selectedAlbum = AlbumData.empty()
    }
    
    
    var body: some View {

        SearchBar(text: $searchText)
           .padding(.top, 0)
        List(album.getFilteredTalks(filter: searchText)) { talk in
            
            TalkRow(album: album, talk: talk)
                .onTapGesture {
                
                    selectedTalk = talk
                    selectedTalkTime = 0
                    selection = "PLAY_TALK"
                }
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
        .listStyle(PlainListStyle())  // ensures fills parent view
        .navigationBarTitle(album.title, displayMode: .inline)
        .background(NavigationLink(destination: TalkPlayerView(album: album, talk: selectedTalk, startTime: selectedTalkTime), tag: "PLAY_TALK", selection: $selection) { EmptyView() } .hidden())
        .background(NavigationLink(destination: HelpPageView(), tag: "HELP", selection: $selection) { EmptyView() } .hidden())
        .background(NavigationLink(destination: TalkPlayerView(album: selectedAlbum, talk: selectedTalk, startTime: selectedTalkTime), tag: "RESUME_TALK", selection: $selection ) { EmptyView() } .hidden())
        .background(NavigationLink(destination: DonationPageView(), tag: "DONATE", selection: $selection) { EmptyView() } .hidden())


        .navigationBarHidden(false)
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
                       self.displayNoCurrentTalk = true
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



