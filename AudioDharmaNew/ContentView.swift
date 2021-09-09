//
//  ContentView.swift
//  Test01
//
//  Created by Christopher on 8/31/21.
//
//

import SwiftUI
import MediaPlayer
import UIKit


extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

var SelectedTalk : TalkData = TalkData(title: "The Depth of The Body",
                                       url: "20210826-Kim_Allen-IMC-the_depth_of_the_body_3_of_4_the_body_as_a_support_for_concentration.mp3",
                                       fileName: "20210826-Kim_Allen-IMC-the_depth_of_the_body_3_of_4_the_body_as_a_support_for_concentration.mp3",
                                       date: "2021.09.01",
                                       durationDisplay: "16:47",
                                       speaker: "Kim Allen",
                                       section: "",
                                       durationInSeconds: 1007,
                                       pdf: "")


struct AlbumRow: View {
    var album: AlbumData

    var body: some View {
        
        VStack(alignment: .leading) {
        HStack() {
        Image("albumdefault")
            .resizable()
            .frame(width:50, height:50)
            .background(Color.red)
            .padding(.leading, -15)
        Text("\(album.Title)")
            .font(.system(size: 14))
            .background(Color.white)
        Spacer()
        Text("42")
            .background(Color.white)
            .padding(.trailing, -10)
            .font(.system(size: 10))
        }
    }
    .frame(height:40)
    }
}


struct AlbumView: View {
    var title: String = ""
    var contentKey: String = ""
    @State var selection: String?  = ""
    @State var newTitle: String?  = ""
    @State var newContentKey: String?  = ""



    var body: some View {


        List(TheDataModel.getAlbumData(key: contentKey)) { album in
            AlbumRow(album: album)
                .onTapGesture {
                    if album.Content.contains("ALBUM") {
                        print("HERE", album.Content)
                        selection = "ALBUMS"
                    } else {
                        selection = "TALKS"
                    }
                    
                    newContentKey = album.Content
                    newTitle = album.Title

                }
        }
        .background(NavigationLink(destination: TalksView(title: newTitle!,  contentKey: newContentKey!), tag: "TALKS", selection: $selection) { EmptyView() } .hidden())
        .background(NavigationLink(destination: AlbumView(title: newTitle!, contentKey: newContentKey!), tag: "ALBUMS", selection: $selection) { EmptyView() } .hidden())

        .navigationBarTitle(title, displayMode: .inline)
        .navigationBarHidden(false)

        .navigationViewStyle(StackNavigationViewStyle())
    }
}


struct TalkRow: View {
    var talk: TalkData

    var body: some View {
        
        VStack(alignment: .leading) {
        HStack() {
        Image("albumdefault")
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

struct TalksView: View {
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
    

    let TEST = [
        AlbumData(title: "All Talks", content:"", section: "", image: "", date: ""),
        AlbumData(title: "Talk by Series", content:"", section: "", image: "", date: "")

    ]
    
    let TEST_SECTIONS = [
        TestData(title: "Numbers", items: ["1","2","3"]),
        TestData(title: "Letters", items: ["A","B","C"]),
        TestData(title: "Symbols", items: ["€","%","&"])
    ]

    

    var body: some View {

        NavigationView {
            List(TheDataModel.getAlbumData(key: KEY_ALBUMROOT)) { album in
                AlbumRow(album: album)
                    .onTapGesture {
                        if album.Content.contains("ALBUM") {
                            print("HERE", album.Content)
                            selection = "ALBUMS"
                        } else {
                            selection = "TALKS"
                        }
                        contentKey = album.Content
                        title = album.Title
                    }
         
            }  // end List(albums)
            .environment(\.defaultMinListRowHeight, 20)
            //.background(NavigationLink(destination: AlbumView(name: "dfed"), isActive: $isActive) { EmptyView() } .hidden())
            .background(NavigationLink(destination: TalksView(title: title, contentKey: contentKey), tag: "TALKS", selection: $selection) { EmptyView() } .hidden())
            .background(NavigationLink(destination: AlbumView(title: title, contentKey: contentKey), tag: "ALBUMS", selection: $selection) { EmptyView() } .hidden())
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
    
    /*
    var body: some View {
        List {
                TaskRow()
                TaskRow()
                SectionRow()
                TaskRow()

                TaskRow()
                TaskRow()
                TaskRow()
            
        }.environment(\.defaultMinListRowHeight, 20)
    }
 */

    /*
    var body: some View {
        List {
            Section(header: Text("Important tasks"))
            {
                TaskRow()
                TaskRow()
                TaskRow()
            }
            

            Section(header: Text("Other tasks")) {
                Group {
                TaskRow()
                TaskRow()
                TaskRow()
                TaskRow()
                TaskRow()
                TaskRow()
                }

                TaskRow()
                TaskRow()
                TaskRow()

                TaskRow()
                TaskRow()
                TaskRow()

            }
        }.environment(\.defaultMinListRowHeight, 10)
    }
 
 */
     
}




struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
        //TalkPlayerView(talk: SelectedTalk)
    }
}





