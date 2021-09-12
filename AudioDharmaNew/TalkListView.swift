//
//  TalkListView.swift
//  AudioDharmaNew
//
//  Created by Christopher on 9/9/21.
//

import SwiftUI
import UIKit

var TEST : TalkData? = nil

struct TalkRow: View {
    var talk: TalkData
    
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
        print(talk)
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
                    .font(.system(size: 14))
                    .background(Color.white)
                Spacer()
                VStack() {
                    Text(String(talk.Date))
                        .background(Color.white)
                        .padding(.trailing, -10)
                        .font(.system(size: 10))
                    Spacer()
                        .frame(height: 8)
                    Text(talk.DurationDisplay)
                        .background(Color.white)
                        .padding(.trailing, -10)
                        .font(.system(size: 10))
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
                        makeNote(talk: talk)
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
    .frame(height:40)
    }
}

struct TalkListView: View {
    var title: String = ""
    var contentKey: String = ""
    @State var selection: String?  = nil

    /*
    init() {
        for talk in TheDataModel.AllTalks {
            print(talk.Title)
        }
    }
 */
 

    var body: some View {

        List(TheDataModel.getTalkData(key: contentKey)) { talk in
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

