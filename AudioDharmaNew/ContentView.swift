//
//  ContentView.swift
//  Test01
//
//  Created by Christopher Minson on 8/31/21.
//
//

import SwiftUI
import UIKit


var SelectedTalk : TalkData = TalkData(title: "The Depth of The Body",
                                       url: "20210826-Kim_Allen-IMC-the_depth_of_the_body_3_of_4_the_body_as_a_support_for_concentration.mp3",
                                       fileName: "20210826-Kim_Allen-IMC-the_depth_of_the_body_3_of_4_the_body_as_a_support_for_concentration.mp3",
                                       date: "2021.09.01",
                                       durationDisplay: "16:47",
                                       speaker: "Kim Allen",
                                       section: "",
                                       durationInSeconds: 1007,
                                       pdf: "")


struct TestRow: View {
    
    var body: some View {
        Text("Test Row")

        /*
            HStack {
                Spacer()
              Text("Hello SwiftUI!")
                Spacer()
            }
            .background(Color.black)
            .foregroundColor(.white)
            .font(.headline)
            .frame(height:30)
        }
 */
    }
}

struct TaskRow: View {
    var body: some View {
        Text("Task data goes here")
            .frame(height:40)
    }
}

struct SectionRow: View {
    var body: some View {
        VStack(spacing: 0){
        HStack {
            Spacer()
            Text("Section")
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.trailing, 0)
                .font(.system(size: 15))

            Spacer()
    }.frame(height:30)
        //.background(Color.black)
        .background(Color(hex: "333333"))

        
    }
    .padding(.leading, -15)
    .padding(.trailing, -15)
        .background(Color(hex: "ff0000"))

}
}

struct TestData: Identifiable {
    var id = UUID()
    var title: String
    var items: [String]
}

/*
 ******************************************************************************
 * RootView
 * UI for the top-level display of albums
 ******************************************************************************
 */
struct RootView: View {
    @State var selection: String?  = ""
    @State var contentKey: String  = ""
    @State var title: String  = ""

    init() {
        UINavigationBar.appearance().titleTextAttributes = [.font : UIFont(name: "Georgia-Bold", size: 20)!]
        
     }
    
/*
    let TEST = [
        AlbumData(title: "All Talks", content:"", section: "", image: "", date: ""),
        AlbumData(title: "Talk by Series", content:"", section: "", image: "", date: "")

    ]
 */
    
    let TEST_SECTIONS = [
        TestData(title: "Numbers", items: ["1","2","3"]),
        TestData(title: "Letters", items: ["A","B","C"]),
        TestData(title: "Symbols", items: ["€","%","&"])
    ]

    

    var body: some View {

        NavigationView {
            List(TheDataModel.getAlbumData(key: KEY_ROOT_ALBUMS)) { album in
                AlbumRow(album: album)
                    .onTapGesture {
                        if album.Key.contains("ALBUM") {
                            print("HERE", album.Key)
                            selection = "ALBUMS"
                        } else {
                            selection = "TALKS"
                        }
                        contentKey = album.Key
                        title = album.Title
                    }
         
            }  // end List(albums)
            .environment(\.defaultMinListRowHeight, 20)
            //.background(NavigationLink(destination: AlbumView(name: "dfed"), isActive: $isActive) { EmptyView() } .hidden())
            .background(NavigationLink(destination: TalkListView(title: title, contentKey: contentKey), tag: "TALKS", selection: $selection) { EmptyView() } .hidden())
            .background(NavigationLink(destination: AlbumListView(title: title, contentKey: contentKey), tag: "ALBUMS", selection: $selection) { EmptyView() } .hidden())
            .navigationBarTitle("Audio Dharma", displayMode: .inline)
        }

    }
    

/*
        var body: some View {
            List {
                ForEach(TEST_SECTIONS) { section in
                    Section(header: Text(section.title)) {
                        
                        ForEach(TEST) { item in
                            
                            AlbumRow(album: item)
                        }
                         

                    }
                }
                
                ForEach(TEST_SECTIONS) { section in
                    Section(header: Text(section.title)) {
                        
                        ForEach(TEST) { item in
                            
                            AlbumRow(album: item)
                        }
                         

                    }
                }

            }
        }
    */
     
}




struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
        //TalkPlayerView(talk: SelectedTalk)
    }
}





