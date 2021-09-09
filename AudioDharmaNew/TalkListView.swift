//
//  TalkListView.swift
//  AudioDharmaNew
//
//  Created by Christopher on 9/9/21.
//

import SwiftUI
import UIKit

struct TalkRow: View {
    var talk: TalkData

    func getImage(name: String) -> Image {
        
        print("getimage: ", name)
        return Image(name)
    }
     
    var body: some View {
        
        VStack(alignment: .leading) {
        HStack() {
            getImage(name: talk.Speaker)
            .resizable()
            .frame(width:50, height:50)
            .background(Color.red)
            .padding(.leading, -15)
        Text("\(talk.Title)")
            .font(.system(size: 14))
            .background(Color.white)
        Spacer()
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


