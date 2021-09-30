//
//  TalkListView.swift
//
//  Created by Christopher Minson on 9/9/21.
//  Copyright © 2022 Christopher Minson. All rights reserved.
//

import SwiftUI
import UIKit

var TEST : TalkData? = nil

struct TalkRow: View {
    var album: AlbumData
    @ObservedObject var talk: TalkData
    
    @State private var display = false
    @State private var displayNoteDialog = false
    @State private var displayDownloadDialog = false
    @State private var displayShareSheet = false

    @State private var noteText = ""
    @State var stateImageFavorite : String
    @State var stateImageNote: String
    @State var stateTalkTitle: String

    
    @State private var textStyle = UIFont.TextStyle.body

    init(album: AlbumData, talk: TalkData) {
        
        self.album = album
        self.talk = talk
        
        if talk.isFavoriteTalk() {
            self.stateImageFavorite = "favoritebar"
        } else {
            self.stateImageFavorite = "whiterect"
        }
        if talk.isNotatedTalk() {
            self.stateImageNote = "notebar"
        } else {
            self.stateImageNote = "whiterect"
        }
        
        stateTalkTitle = talk.Title
         if talk.isDownloadInProgress() {
            self.stateTalkTitle = "DOWNLOADING: " + stateTalkTitle
        }
    }
    
    func downloadCompleted() -> Void {
        print("downloadCompleted")

        stateTalkTitle = self.talk.Title
    }
    
    
    func getImage(named: String) -> Image {
       let uiImage =  (UIImage(named: named) ?? UIImage(named: "defaultPhoto"))!
       return Image(uiImage: uiImage)
    }
    
    var body: some View {
        
        VStack(alignment: .leading) {
            HStack() {
                getImage(named: talk.Speaker)
                    .resizable()
                    .frame(width: SPEAKER_IMAGE_WIDTH, height: SPEAKER_IMAGE_HEIGHT)
                    .clipShape(Circle())
                    .background(Color.white)
                    .padding(.leading, -15)
                Spacer()
                    .frame(width: 6)
                Text("\(stateTalkTitle)")
                    .font(.system(size: 12))
                    .foregroundColor(talk.isDownloaded ? Color.red : Color.black)
                    .background(Color.white)
                Spacer()
                VStack() {
                    Text(String(talk.Date))
                        .background(Color.white)
                        .padding(.trailing, -5)
                        .font(.system(size: 10))
                    Spacer()
                        .frame(height: 8)
                    Text(talk.DurationDisplay)
                        .background(Color.white)
                        .padding(.trailing, -5)
                        .font(.system(size: 10))
                }
                VStack() {
 
                    Image(self.stateImageFavorite)
                        .resizable()
                        .frame(width: 12, height: 12)
                    Image(self.stateImageNote)
                        .resizable()
                        .frame(width: 12, height: 12)

                 }
                .padding(.trailing, -10)
                .contextMenu {
                    Button("Get Similar Talks") {
                    }
                    Button("Favorite Talk") {
                        let isFavorite = talk.toggleTalkAsFavorite()
                        if isFavorite {
                            self.stateImageFavorite = "favoritebar"
                        } else {
                            self.stateImageFavorite = "whiterect"
                        }
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
                        //TheDataModel.download(talk: talk, notifyUI: downloadCompleted)
                        talk.download(notifyUI: downloadCompleted)
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
                    print("Done", noteText)
                    talk.addNoteToTalk(noteText: noteText)
                    displayNoteDialog = false
                    let isNoted = talk.isNotatedTalk()
                    if isNoted {
                        self.stateImageNote = "notebar"
                    } else {
                        self.stateImageNote = "whiterect"
                    }

                }
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
        }
    .frame(height:40)
    }

}

struct TalkListView: View {
    //@Published var counter: Int = 0
    var album: AlbumData

    @State var selection: String?  = nil
    @State var searchText: String  = ""
    
    @State var noCurrentTalk: Bool = false

    init(album: AlbumData) {
        self.album = album


    }
    

    var body: some View {

        SearchBar(text: $searchText)
           .padding(.top, 0)
        List(album.talkList) { talk in
            
            TalkRow(album: album, talk: talk)
                .onTapGesture {
                    print("talk selected")
                    selection = "PLAY_TALK"
                    CurrentTalk = talk
                }
        }
        .background(NavigationLink(destination: TalkPlayerView(talk: CurrentTalk, currentTime: 0), tag: "PLAY_TALK", selection: $selection) { EmptyView() } .hidden())

        //.navigationBarTitle("All Talks", displayMode: .inline)
        .navigationBarHidden(false)
        .listStyle(PlainListStyle())  // ensures fills parent view


        .navigationViewStyle(StackNavigationViewStyle())
        .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Button {
                        // your action here
                    } label: {
                        Image(systemName: "calendar")
                    }
                    Spacer()
                    Button(action: {
                        print(CurrentTalk.Title)
                        if CurrentTalk.Title == "NO TALK" {
                            print("none")
                            noCurrentTalk = true
                        } else {
                            noCurrentTalk = false
                            selection = "PLAY_TALK"
                        }
                    }) {
                        Image(systemName: "note")
                            .renderingMode(.original)

                    }
                    Spacer()
                    Button(action: {
                        print("Edit button was tapped")
                    }) {
                        Image(systemName: "heart.fill")
                            .renderingMode(.original)

                    }
                }
            }

        
    }
}



