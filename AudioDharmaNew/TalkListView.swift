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
    
    @State private var displayNoteDialog = false
    @State private var textInput = ""
    
    @State private var message = ""
    @State private var textStyle = UIFont.TextStyle.body

    
    init(talk: TalkData) {
            
        self.talk = talk
    }

    func getImage(name: String) -> Image {
        
        //print("getimage: ", name)
        return Image(name)
        
    }
    
    func test(talk: TalkData) {
        print(talk)
        print("TEST")
        
    }
    
    func getSimilar(talk: TalkData) {
        print(talk)
    }

    func markFavorite(talk: TalkData) {
        print(talk)
    }

    func makeNote(talk: TalkData) {
        
       
        print("makeNote: ", talk)
    }
    
    func share(talk: TalkData) {
        print(talk)
    }
    
    func download(talk: TalkData) {
        print(talk)
    }

    var body: some View {
        
        VStack(alignment: .leading) {
            HStack() {
                getImage(name: talk.Speaker)
                    .resizable()
                    .frame(width:50, height:50)
                    .clipShape(Circle())
                    //.shadow(radius: 10)
                    //.overlay(Circle().stroke(APP_ICON_COLOR, lineWidth: 2))
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
                    Image("favoritebar")
                        .resizable()
                        .frame(width: 12, height: 12)
                    Image("notebar")
                        .resizable()
                        .frame(width: 12, height: 12)
                 }

                .padding(.trailing, -10)
                .contextMenu {
                    Button("Get Similar Talks") {
                         getSimilar(talk: talk)
                    }
                    Button("Favorite Talk") {
                        markFavorite(talk: talk)
                    }
                    Button("Make Note") {
                        print("Make NOTE")
                        displayNoteDialog = true
                    }
                    Button("Share Talk") {
                        share(talk: talk)
                    }
                    Button("Download Talk") {
                        download(talk: talk)
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
                TextView(text: $message, textStyle: $textStyle)
                    .padding(.horizontal)
                    .frame(height: 100)
                    .border(Color.gray)
                Spacer()
                    .frame(height:30)
                Button("Done") {
                    print("Done", message)
                    displayNoteDialog = false
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



