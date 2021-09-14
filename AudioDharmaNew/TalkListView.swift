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
    var talk: TalkData
    
    @State private var display = false
    @State private var displayNoteDialog = false
    @State private var noteText = ""
    @State var stateImageFavorite : String
    @State var stateImageNote: String
    @State private var textStyle = UIFont.TextStyle.body

    init(talk: TalkData) {
        
        self.talk = talk
        if TheDataModel.isFavoriteTalk(talk: talk) {
            self.stateImageFavorite = "favoritebar"
        } else {
            self.stateImageFavorite = "whiterect"
        }
        if TheDataModel.isNotatedTalk(talk: talk) {
            self.stateImageNote = "notebar"
        } else {
            self.stateImageNote = "whiterect"
        }
    }
    
    var body: some View {
        
        VStack(alignment: .leading) {
            HStack() {
                Image(talk.Speaker)
                    .resizable()
                    .frame(width:50, height:50)
                    .clipShape(Circle())
                    .background(Color.white)
                    .padding(.leading, -15)
                Spacer()
                    .frame(width: 6)
                Text("\(talk.Title)")
                    .font(.system(size: 12))
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
                        let isFavorite = TheDataModel.toggleTalkAsFavorite(talk: talk)
                        if isFavorite {
                            self.stateImageFavorite = "favoritebar"
                        } else {
                            self.stateImageFavorite = "whiterect"
                        }
                    }
                    Button("Make Note") {
                        noteText = TheDataModel.getNoteForTalk(talk: talk)
                        displayNoteDialog = true
                    }
                    Button("Share Talk") {
                    }
                    Button("Download Talk") {
                    }
                }
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
                    TheDataModel.addNoteToTalk(talk: talk, noteText: noteText)
                    displayNoteDialog = false
                    let isNoted = TheDataModel.isNotatedTalk(talk: talk)
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
    var title: String = ""
    var key: String = ""
    @State var selection: String?  = nil
    @State var searchText: String  = ""


    var body: some View {

        SearchBar(text: $searchText)
           .padding(.top, 0)
        List(TheDataModel.getTalkData(key: key, filter: searchText)) { talk in
        
            TalkRow(talk: talk)
                .onTapGesture {
                    print("talk selected")
                    selection = "PLAY_TALK"
                    SelectedTalk = talk
                }
        }
        .background(NavigationLink(destination: TalkPlayerView(talk: SelectedTalk), tag: "PLAY_TALK", selection: $selection) { EmptyView() } .hidden())

        .navigationBarTitle("All Talks", displayMode: .inline)
        .navigationBarHidden(false)

        .navigationViewStyle(StackNavigationViewStyle())
        
    }
}



