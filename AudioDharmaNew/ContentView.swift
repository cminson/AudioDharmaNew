//
//  ContentView.swift
//  Test01
//
//  Created by Christopher on 8/31/21.
//
//

import SwiftUI

//CJM DEV
/*
struct AlbumData: Identifiable {
    let id = UUID()
    let Title: String
}
 
 struct TalkData: Identifiable {
     let id = UUID()
     let Title: String
 }

 */

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
    let name: String
    @State var isActive  = false

    
    let albums = [
        AlbumData(title: "All Talks", content:"", section: "", image: "", date: ""),
    ]
    
    func clicked() {
        isActive = true
    }

    var body: some View {


        List(albums) { album in
            AlbumRow(album: album)
                .onTapGesture {
                    print("Tap seen \(isActive)")
                    clicked()
                }
        }
        .background(NavigationLink(destination: AlbumView(name: "dfed"), isActive: $isActive) { EmptyView() } .hidden())

        .navigationBarTitle("All Talks", displayMode: .inline)
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
    @State var selection: String?  = nil

    init() {
        for talk in TheDataModel.AllTalks {
            print(talk.Title)
        }
    }

    var body: some View {

        List(TheDataModel.AllTalks) { talk in
            TalkRow(talk: talk)
                .onTapGesture {
                    print("talk selected")
                    selection = "PLAY_TALK"
                    SelectedTalk = talk
                }
        }
        .background(NavigationLink(destination: TalkPlayer(talk: SelectedTalk), tag: "PLAY_TALK", selection: $selection) { EmptyView() } .hidden())

        .navigationBarTitle("All Talks", displayMode: .inline)
        .navigationBarHidden(false)

        .navigationViewStyle(StackNavigationViewStyle())
    }
}


/*
 * TalkPlayer
 */
struct TalkPlayer: View {
    var talk: TalkData
    @State private var isTalkActive = false

    func playTalk() {
        
        //let pathMP3 = URL_MP3_HOST + talk.URL
        let pathMP3 = "https://virtualdharma.org/AudioDharmaAppBackend/data/TALKS/20210826-Kim_Allen-IMC-the_depth_of_the_body_3_of_4_the_body_as_a_support_for_concentration.mp3"
        if let talkURL = URL(string: pathMP3) {
        
            print("URL \(pathMP3)")

            AudioPlayer = MP3Player()
            AudioPlayer.startTalk(talkURL: talkURL, startAtTime: 0)
        }
        
    }
    
    //CJM TO DO
    //UISlider, UIActivityIndicatorView, MPVolumeView
    var body: some View {
        
        ZStack {Color(.orange).opacity(0.2).edgesIgnoringSafeArea(.all)
        VStack(alignment: .center, spacing: 10) {

            Text(talk.Title)
                .background(Color.blue)
                .padding(.trailing, 0)
                .font(.system(size: 20))
            Spacer()
                .frame(height: 10)
            Text(talk.Speaker)
                .background(Color.blue)
                .padding(.trailing, 0)
                .font(.system(size: 20))
            Spacer()
            Button(action: {
                print("button pressed")
                print(isTalkActive)
                isTalkActive = true
                playTalk()
            }) {
                //Image("tri_right")
                Image(isTalkActive ? "blacksquare" : "tri_right")
                    .resizable()
                    .frame(width: 60, height: 60)
            }
            

 
            Spacer()
            Spacer()
        }  // VStack
        .foregroundColor(Color.black.opacity(0.7))
        .padding(.trailing, 0)
        } // ZStack
    }
        //.navigationBarTitle("Play Talk", displayMode: .inline)
        //.navigationBarHidden(false)

    
}




struct TestRow: View {
    
    var body: some View {
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
}


struct RootView: View {
    @State var selection: String?  = nil
    
    init() {
        UINavigationBar.appearance().titleTextAttributes = [.font : UIFont(name: "Georgia-Bold", size: 20)!]
        
        print("TALKS")
        for talk in TheDataModel.AllTalks {
            print(talk.Title)
        }
    }
    

    let TEST = [
        AlbumData(title: "All Talks", content:"", section: "", image: "", date: ""),
        AlbumData(title: "Talk by Series", content:"", section: "", image: "", date: "")

    ]
    
    
    var body: some View {

        NavigationView {
            List(TheDataModel.RootAlbums) { album in
            
                if album.Title != "Talks by Series" {
                    AlbumRow(album: album)
                    .onTapGesture {
                        selection = "ALL_TALKS"
                }
            }
            else {
                TestRow()
                
            }
    
         }  // end List(albums)
            //.background(NavigationLink(destination: AlbumView(name: "dfed"), isActive: $isActive) { EmptyView() } .hidden())
            .background(NavigationLink(destination: TalksView(), tag: "ALL_TALKS", selection: $selection) { EmptyView() } .hidden())
            .navigationBarTitle("Audio Dharma", displayMode: .inline)
        }

    }
}





struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        //RootView()
        TalkPlayer(talk: SelectedTalk)
    }
}

/*
 let volumeView = MPVolumeView(frame: MPVolumeParentView.bounds)

 volumeView.showsRouteButton = true

 let iconBlack = UIImage(named: "routebuttonblack")
 let iconGreen = UIImage(named: "routebuttongreen")
 
 volumeView.setRouteButtonImage(iconBlack, for: UIControl.State.normal)
 volumeView.setRouteButtonImage(iconBlack, for: UIControl.State.disabled)
 volumeView.setRouteButtonImage(iconGreen, for: UIControl.State.highlighted)
 volumeView.setRouteButtonImage(iconGreen, for: UIControl.State.selected)

 volumeView.tintColor = MAIN_FONT_COLOR
 
 
 
 let point = CGPoint(x: MPVolumeParentView.frame.size.width  / 2,y : (MPVolumeParentView.frame.size.height / 2) + 5)
 volumeView.center = point
 MPVolumeParentView.addSubview(volumeView)
 */
