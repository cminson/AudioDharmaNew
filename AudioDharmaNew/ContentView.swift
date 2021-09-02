//
//  ContentView.swift
//  Test01
//
//  Created by Christopher on 8/31/21.
//

import SwiftUI

struct AlbumView: View {
    let name: String
    @State var isActive  = false

    
    let albums = [
        Album(name: "All Talks"),
        Album(name: "All Talks"),
        Album(name: "HERE")
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

struct Album: Identifiable {
    let id = UUID()
    let name: String
}

struct AlbumRow: View {
    var album: Album

    var body: some View {
        
        VStack(alignment: .leading) {
        HStack() {
        Image("albumdefault")
            .resizable()
            .frame(width:50, height:50)
            .background(Color.red)
            .padding(.leading, -15)
        Text("\(album.name)")
            .font(.system(size: 20))
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

struct TalkRow: View {
    var album: Album

    var body: some View {
        
        VStack(alignment: .leading) {
        HStack() {
        Image("albumdefault")
            .resizable()
            .frame(width:50, height:50)
            .background(Color.red)
            .padding(.leading, -15)
        Text("\(album.name)")
            .font(.system(size: 20))
            .background(Color.white)
        Spacer()
        }
    }
    .frame(height:40)
    }
}

struct TestRow: View {
    var album: Album
    
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

struct SectionRow: View {
    var album: Album

    var body: some View {
        
        VStack(alignment: .leading) {

        Text("\(album.name)")
            .font(.system(size: 20))
        }
        .frame(height:40)


        }

}


struct ContentView: View {
    @State var isActive  = false
    
    init() {
        UINavigationBar.appearance().titleTextAttributes = [.font : UIFont(name: "Georgia-Bold", size: 20)!]

        TheDataModel.loadAllData()
    }

    let albums = [
        Album(name: "All Talks"),
        Album(name: "Recommended Talks"),
        Album(name: "Talks by Series"),
        Album(name: "Talks by Seriesxx"),
        Album(name: "Talks by Seriesxx")
    ]
    
    func clicked() {
        isActive = true
    }
    
    var body: some View {

        NavigationView {
            List(albums) { album in
            
                if album.name != "Talks by Series" {
                    AlbumRow(album: album)
                    .onTapGesture {
                    print("Tap seen \(isActive)")
                    //isActive.toggle()
                    print("new value \(isActive)")
                    isActive = true
                }
            }
            else {
                TestRow(album: album)
                
            }
    
         }  // end List(albums)
            .background(NavigationLink(destination: AlbumView(name: "dfed"), isActive: $isActive) { EmptyView() } .hidden())
            .navigationBarTitle("Audio Dharma", displayMode: .inline)
        }

    }

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
