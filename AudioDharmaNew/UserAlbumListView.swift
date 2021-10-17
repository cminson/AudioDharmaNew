//
//  UserAlbumListView.swift
//
//  Implements the view of custom user albums.
//
//  Created by Christopher on 10/14/21.
//

import Foundation
import SwiftUI
import UIKit



struct UserAlbumRow: View {
    
    @ObservedObject var album: AlbumData
    @State var selection: String?  = ""
    @State var displayEditCustomAlbum = false
    @State var displayDeleteAlbum = false
    @State var albumTitle: String
    
    init(album: AlbumData) {
        self.album = album
        
        albumTitle = album.Title
        print("UserAlbum: ", album.Title)
        for talk in album.talkList {
            print("Talk: ", talk.Title)
        }

    }

    var body: some View {
        
        VStack(alignment: .leading) {
            HStack() {
                album.ImageName.toImage()
                    .resizable()
                    .frame(width: LIST_IMAGE_WIDTH, height:LIST_IMAGE_HEIGHT)
                    .clipShape(Circle())
                    .background(Color.white)
                    .padding(.leading, -15)
                Text("\(album.Title)")
                    .font(.system(size: FONT_SIZE_ROW_TITLE))
                    .background(Color.white)
                    .padding(.leading, 0)
                Spacer()
                VStack(alignment: .trailing, spacing: 8) {
                    Text(album.totalTalks.displayInCommaFormat())
                        .background(Color.white)
                        .padding(.trailing, -10)
                        .font(.system(size: FONT_SIZE_ROW_ATTRIBUTES))
                    Text(album.totalSeconds.displayInClockFormat())
                        .background(Color.white)
                        .padding(.trailing, -10)
                        .font(.system(size: FONT_SIZE_ROW_ATTRIBUTES))
                }
            }
            .contextMenu {
                Button("Edit Album Talks") {
                    selection = "EDIT_TALKS_IN__ALBUM"
                }
                Button("Edit Album Title") {
                    displayEditCustomAlbum = true
                }
                Button("Delete Album") {
                    print("delete ablum")
                    displayDeleteAlbum = true
                }

            }
            .contentShape(Rectangle())
            .onTapGesture {
                selection = "TALKS"
                
            }
        }
        .background(NavigationLink(destination: TalkListView(album: album), tag: "TALKS", selection: $selection) { EmptyView() } .hidden())
        .background(NavigationLink(destination: AlbumListView(album: album), tag: "ALBUMS", selection: $selection) { EmptyView() } .hidden())
        .background(NavigationLink(destination: UserEditTalkListView(album: album), tag: "EDIT_TALKS_IN__ALBUM", selection: $selection) { EmptyView() } .hidden())
        // The Following line is NECESSARY.   (https://forums.swift.org/t/14-5-beta3-navigationlink-unexpected-pop/45279)
        .background(NavigationLink(destination: EmptyView()) {EmptyView()}.hidden())  // don't delete this mofo
        .background(Color.white)
        .frame(height: LIST_ROW_SIZE_STANDARD)
        .frame(maxWidth: .infinity)
        .alert(isPresented: $displayDeleteAlbum) {
            Alert(
                title: Text("Remove Custom Album?"),
                message: Text("Press OK to delete this album"),
                primaryButton: .destructive(Text("OK")) {
                    if let index = TheDataModel.CustomUserAlbums.albumList.firstIndex(of: album) {
                        
                        TheDataModel.CustomUserAlbums.albumList.remove(at: index)
                        TheDataModel.saveCustomUserAlbums()
                    }

                },
                secondaryButton: .cancel()
            )
        }

        .popover(isPresented: $displayEditCustomAlbum) {
            VStack() {
                Text("Edit Album Title")
                    .padding()
                Spacer()
                    .frame(height:30)
                TextField("", text: $albumTitle)
                    .padding(.horizontal)
                    .frame(height: 40)
                    .border(Color.gray)
                Spacer()
                    .frame(height:30)
                HStack() {
                    Button("Cancel") {
                        displayEditCustomAlbum = false
                    }
                    Spacer()
                        .frame(width: 30)
                    Button("Done") {
                        displayEditCustomAlbum = false
                        album.Title = albumTitle
                        TheDataModel.saveCustomUserAlbums()
                    }
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
        }

     }
}


struct UserAlbumListView: View {
    
    @ObservedObject var album: AlbumData

    @State var selectedAlbum: AlbumData
    @State var selection: String?  = ""
    @State var searchText: String  = ""
    @State var noCurrentTalk: Bool = false
    
    @State var selectedTalk: TalkData
    @State var selectedTalkTime: Double
    @State var displayNewCustomAlbum = false
    
    @State private var textStyle = UIFont.TextStyle.body
    @State private var customAlbum = "Custom Album"

    
    init(album: AlbumData) {
        self.album = album
        self.selectedAlbum = AlbumData.empty()
        
        self.selectedTalk = TalkData.empty()
        self.selectedTalkTime = 0
        
        /*
        print("LIsting custome albums")
        for album in TheDataModel.CustomUserAlbums.albumList {
            print("CUSTOM ALBUM: ", album)
        }
         */

    }
    
    
    var body: some View {

        SearchBar(text: $searchText)
           .padding(.top, 0)
        List(TheDataModel.CustomUserAlbums.getFilteredAlbums(filter: searchText)) { album in
            UserAlbumRow(album: album)
        }
        .background(NavigationLink(destination: HelpPageView(), tag: "HELP", selection: $selection) { EmptyView() } .hidden())
        .background(NavigationLink(destination: TalkPlayerView(album: selectedAlbum, talk: selectedTalk, elapsedTime: selectedTalkTime), tag: "RESUME_TALK", selection: $selection) { EmptyView() } .hidden())
        .background(NavigationLink(destination: DonationPageView(), tag: "DONATE", selection: $selection) { EmptyView() } .hidden())

        .navigationBarTitle(album.Title, displayMode: .inline)
        .toolbar {
            Button(action: {
                displayNewCustomAlbum = true
           }) {
               Image(systemName: "plus.circle")
            }
        }
        
        .navigationBarHidden(false)
        .listStyle(PlainListStyle())  // ensures fills parent view
        .navigationViewStyle(StackNavigationViewStyle())

        .toolbar {
           ToolbarItemGroup(placement: .bottomBar) {
               Button {
                   selection = "HELP"

               } label: {
                   Image(systemName: "questionmark.circle")
               }
               .foregroundColor(.black)  // ensure icons don't turn blue
               Spacer()
               Button(action: {
                   selection = "RESUME_TALK"
                   selectedTalk = CurrentTalk
                   selectedTalkTime = CurrentTalkElapsedTime
               }) {
                   Text("Resume Talk")
                      
               }
               .foregroundColor(.black)
               .hidden(!TheDataModel.currentTalkExists())
               Spacer()
               Button(action: {
                   selection = "DONATE"

              }) {
                   Image(systemName: "heart.circle")
               }
              .foregroundColor(.black)

           }
       }
        .popover(isPresented: $displayNewCustomAlbum) {
            VStack() {
                Text("New Custom Album")
                    .padding()
                Spacer()
                    .frame(height:30)
                TextField("", text: $customAlbum)
                    .padding(.horizontal)
                    .frame(height: 40)
                    .border(Color.gray)
                Spacer()
                    .frame(height:30)
                Button("Done") {
                    displayNewCustomAlbum = false
                    let newAlbum = AlbumData(title: customAlbum, key: "KEY_CUSTOM_ALBUM", section: "", imageName: "albumdefault", date: "", albumType: AlbumType.ACTIVE)
                    TheDataModel.CustomUserAlbums.albumList.append(newAlbum)
                    TheDataModel.saveCustomUserAlbums()
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
        }

    }
    
       

    
}



