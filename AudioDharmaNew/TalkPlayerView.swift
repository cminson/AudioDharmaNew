//
//  TalkPlayerView.swift
//
//  Drives the audio recorder UI.
//
//  Created by Christopher Minson on 9/8/21.
//  Copyright © 2022 Christopher Minson. All rights reserved.
//

import SwiftUI
import MediaPlayer
import UIKit

//(https://forums.swift.org/t/14-5-beta3-navigationlink-unexpected-pop/45279)

enum TalkStates {                   // all possible states of the talk player
    case INITIAL
    case LOADING
    case PLAYING
    case PAUSED
    case FINISHED
}


var TalkIsCurrentlyPlaying = false
var TheTalkPlayer: TalkPlayer!
var PlayEntireAlbum: Bool = false
var PlayingDownloadedTalk: Bool = false
var DisplayingBiographyOrTranscript = false


//
// Thes globals indicate whats playing now (or last played)
//
var CurrentTalk : TalkData = TalkData.empty()  // the last talk played or being played
var CurrentTalkElapsedTime : Double = 0                // elapsed time in this talk
var CurrentAlbum : AlbumData = AlbumData.empty()    // the album for this talk being played


/*
 ******************************************************************************
 * TalkPlayer
 * UI for talk player console
 ******************************************************************************
 */

struct TalkPlayerView: View {

    var album: AlbumData
    @State var talk: TalkData
    @State private var elapsedTime: Double

    @State private var selection: String?  = nil
    @State private var elapsedTimeUpdating = false
    @State private var displayTranscriptView: Bool = false
    @State private var displayBiographyView: Bool = false
    @State private var playTalksInSequence: Bool = false
    @State private var playerTitle: String = "Play Talk"
    @State private var displayRemoteFileNotFound = false
    @State private var displayNoInternet = false
    @State private var stateTalkPlayer = TalkStates.INITIAL
    @State private var tappedUrl: String = ""
    

    
    
    init(album: AlbumData, talk: TalkData, startTime: Double) {
        
        self.album = album
        self.talk = talk
        self.elapsedTime = startTime
        

    }
    
    
    func playTalk() {
    
        if TheDataModel.hasBeenDownloaded(talk: self.talk) {
            playDownloadedTalk()
        } else {
            playWebTalk()
        }
    }
    
    
    func playDownloadedTalk() {
  
        if stateTalkPlayer == .PAUSED  {
            TheTalkPlayer.play()
        } else {
            
            let talkURL  = URL(string: "file:////" + MP3_DOWNLOADS_PATH + "/" + self.talk.fileName)!
            
            stateTalkPlayer = .LOADING
            playerTitle = "Loading Talk"

            TheTalkPlayer = TalkPlayer()
            TheTalkPlayer.talkPlayerView = self
            TheTalkPlayer.startTalk(talkURL: talkURL, startAtTime: self.elapsedTime)
        }
        
    }

    
    func playWebTalk() {
        
        if TheDataModel.isInternetAvailable() == false {
            self.displayNoInternet = true
            return
        }
        

        if stateTalkPlayer == .PAUSED {
            TheTalkPlayer.play()
        } else {
        
            var talkURL: URL
            if USE_NATIVE_MP3PATHS == true {
                talkURL  = URL(string: URL_MP3_HOST +  talk.URL)!

            } else {
                talkURL  = URL(string: URL_MP3_HOST + "/" + talk.fileName)!
            }

            TheDataModel.remoteURLExists(url: talkURL, completion: remoteFileCheckCallback)

            stateTalkPlayer = .LOADING
            playerTitle = "Loading Talk"

            print("Startng talk at: ", self.elapsedTime)

            TheTalkPlayer = TalkPlayer()
            TheTalkPlayer.talkPlayerView = self
            TheTalkPlayer.startTalk(talkURL: talkURL, startAtTime: self.elapsedTime)
        }
    
    }
    
    
    // completion all invoked by remoteURLExists() in background.  report if talk not found
    func remoteFileCheckCallback(exists: Bool, url: URL) {
    
        if exists == false {
            DispatchQueue.main.async {
                
                self.terminateTalk()
                self.displayRemoteFileNotFound = true
            }
        }
    }

    
    func pauseTalk () {
        
        stateTalkPlayer = .PAUSED
        TheTalkPlayer.pause()
    }
    
    
    func terminateTalk() {
    
        TheTalkPlayer?.stop()
        stateTalkPlayer = .FINISHED
    }
    
    
    // invoked upon TheTalkPlayer completion
    mutating func talkHasCompleted () {
        
        print("talkHasCompleted")

        TheTalkPlayer.stop()
        
        stateTalkPlayer = .FINISHED
        self.playerTitle = getPlayerTitle()
        self.elapsedTime = 0

        // if option is enabled, play the next talk in the current series
        if self.playTalksInSequence == true {

            if var index = self.album.talkList.firstIndex(of: self.talk) {
            
                index += 1
                if index >= self.album.talkList.count { index = 0}
                
                self.talk = self.album.talkList[index]
                self.elapsedTime = 0
                TheDataModel.saveLastAlbumTalkState(album: self.album, talk: self.talk, elapsedTime: self.elapsedTime)
            }
            playTalk()
        }
    }
    
    
    // invoked every second from background timer in TheTalkPlayer
    mutating func updateView(){
        
        if (TheTalkPlayer.Player.error != nil) {
            print("ERROR")
        }

        if self.elapsedTimeUpdating == false {
            self.elapsedTime += 1
        }
        

        // if talk is  underway, then stop the busy notifier and activate the display (buttons, durations etc)
        if self.elapsedTime > 0 {

             if self.elapsedTime > REPORT_TALK_THRESHOLD, TheDataModel.isMostRecentTalk(talk: talk) == false {
                
                print("REPORTING ACTIVITY")

                TheDataModel.addToTalkHistory(talk: self.talk)
                TheDataModel.reportTalkActivity(type: ACTIVITIES.PLAY_TALK, talk: self.talk)
            }

            // persistent store off the current talk and position in talk
            TheDataModel.saveLastAlbumTalkState(album: album, talk: self.talk, elapsedTime: self.elapsedTime)
            
        }
        if self.elapsedTime > 1 {
            
            stateTalkPlayer = .PLAYING

        }
        
    }
    
    
    func getPlayerTitle() -> String {
        
        var playerTitle: String
        
        switch stateTalkPlayer {
        case .INITIAL:
            playerTitle = ""
        case .LOADING:
            playerTitle = "Loading"
        case .PLAYING:
            if playTalksInSequence {

                playerTitle = Int(self.elapsedTime).displayInClockFormat()
                if var index = self.album.talkList.firstIndex(of: self.talk) {
                    index += 1
                    let count = self.album.talkList.count
                    let position = index.displayInCommaFormat() + "/" + count.displayInCommaFormat() + "  "
                    playerTitle = "Playing " + position + Int(self.elapsedTime).displayInClockFormat()
                }
            } else {
                
                playerTitle = "Playing " + Int(elapsedTime).displayInClockFormat()
            }
        case .PAUSED:
            playerTitle = "Paused " + Int(elapsedTime).displayInClockFormat()
        case .FINISHED:
            playerTitle = "Finished"
            
        }
        return playerTitle
    }
    
            
    var body: some View {

        VStack(alignment: .center, spacing: 0) {
            Group {
            Spacer()
                .frame(height: 40)
           Text(self.talk.title)
                .foregroundColor(TheDataModel.hasBeenDownloaded(talk: talk) ? COLOR_DOWNLOADED_TALK : Color(UIColor.label))
                .padding(.trailing, 15)
                .padding(.leading, 15)
                .font(.system(size: FONT_SIZE_TALK_PLAYER, weight: .regular, design: .default))
            Spacer()
                .frame(height: 20)
            Text(self.talk.speaker)
                .underline()
                .padding(.trailing, 0)
                .font(.system(size: FONT_SIZE_TALK_PLAYER, weight: .regular, design: .default))
                .onTapGesture {
                    selection = "BIOGRAPHY"
                }
            Spacer()
                .frame(height: 30)
                
            // play, pause, fast-forward,  fast-backward buttons
            HStack() {
                Button(action: {
                    self.elapsedTime = TheTalkPlayer.seekFastBackward()
                })
                {
                    Image(systemName: "backward.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height:  20)
                        //.foregroundColor(AppColorScheme == .light ? MEDIA_CONTROLS_COLOR_LIGHT : Color(UIColor.label))
                        .foregroundColor(Color(UIColor.label))
                        .disabled(stateTalkPlayer != .PLAYING)
                }
                .disabled(stateTalkPlayer != .PLAYING)

                Spacer()
                    .frame(width: 45)
                ZStack() {
                    ProgressView()
                        .hidden(self.stateTalkPlayer != .LOADING)
                    Button(action: {
                        self.stateTalkPlayer == .PLAYING ? pauseTalk() : playTalk()
                        })
                        {
                            Image(systemName: self.stateTalkPlayer == .PLAYING ? "pause.fill" : "play.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 35)
                                //.foregroundColor(AppColorScheme == .light ? MEDIA_CONTROLS_COLOR_LIGHT : Color(UIColor.label))
                                .foregroundColor(Color(UIColor.label))


                        }
                        .buttonStyle(PlainButtonStyle())
                        .hidden(self.stateTalkPlayer == .LOADING)

                }  // end ZStack
                .frame(width: 35, height: 35)

                Spacer()
                    .frame(width: 45)
                Button(action: {
                    self.elapsedTime = TheTalkPlayer.seekFastForward()
                })
                {
                    Image(systemName: "forward.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height:  20)
                        //.foregroundColor(AppColorScheme == .light ? MEDIA_CONTROLS_COLOR_LIGHT : Color(UIColor.label))
                        .foregroundColor(Color(UIColor.label))
                        .disabled(stateTalkPlayer != .PLAYING)
                }
                .disabled(stateTalkPlayer != .PLAYING)

            }  // end HStack
            
            }  //end group 1
            .alert(isPresented: $displayRemoteFileNotFound) {
                Alert(
                    title: Text("All Things Are Transient"),
                    message: Text("This talk is currently unreachable. Please try again later. If you suspect the talk is permanently in the Void, please contact support."),
                    dismissButton: .default(Text("OK")) {
                        
                        displayNoInternet = false
                    }
                )
             }
            
            Group {
                
            Spacer()
                .frame(height: 30)
           
                HStack() {
                    Text("00:00:00")
                        .font(.system(size: FONT_SIZE_TALK_PLAYER_SMALL, weight: .regular))
                        .frame(width: 60)
                    Slider(value: $elapsedTime,
                           in: 0...Double(self.talk.totalSeconds),
                           step: 1,
                             onEditingChanged: { editing in
                        
                                if editing == true {
                                    self.elapsedTimeUpdating = true
                                }  else {
                                    if stateTalkPlayer == .PLAYING {
                                        self.playerTitle = getPlayerTitle()
                                        TheTalkPlayer.seekToTime(seconds: Int64(self.elapsedTime))
                                    }
                                    self.elapsedTimeUpdating = false
                                }
                            }  // end onEditingChanged
                    ) // end Slider
                    .frame(height: 30)
                    .disabled(stateTalkPlayer != .PLAYING)
                    Text(self.talk.totalSeconds.displayInClockFormat())
                        .font(.system(size: FONT_SIZE_TALK_PLAYER_SMALL, weight: .regular))
                        .frame(width: 60)

                }
            .padding(.trailing, 20)
            .padding(.leading, 20)
                
            Spacer()
                .frame(height: 25)
            Button(action: {
                self.playTalksInSequence = self.playTalksInSequence ? false : true
            })
            {
                //Image(systemName: "equal.circle.fill")
                Image(playTalksInSequence ? "sequence_active" : "sequence_notactive")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height:  30)
                    .foregroundColor(self.playTalksInSequence == true ? Color(UIColor.label) : Color.gray)
            }
             Spacer()
                .frame(height:  5)
            Text("play talks in sequence")
                .font(.system(size: FONT_SIZE_TALK_PLAYER_SMALL, weight: .regular))
            Spacer()
            VolumeSlider()
                .frame(height: 50)
                .padding(.leading, 80)
                .padding(.trailing, 60)
          
            } // end group 2
            .alert(isPresented: $displayNoInternet) {
                Alert(
                    title: Text("Can Not Connect to AudioDharma"),
                    message: Text("Please check your internet connection or try again in a few minutes"),
                    dismissButton: .default(Text("OK")) {
                        
                        displayNoInternet = false
                    }
                )
            }
        }  // end VStack

        .background(NavigationLink(destination: TranscriptView(talk: talk), tag: "TRANSCRIPT", selection: $selection) { EmptyView() } .hidden())
        .background(NavigationLink(destination: BiographyView(talk: talk), tag: "BIOGRAPHY", selection: $selection) { EmptyView() } .hidden())
        .background(NavigationLink(destination: EmptyView()) {EmptyView()}.hidden())
        .padding(.trailing, 0)
        .onAppear {
            
            DEBUG = true
            TalkIsCurrentlyPlaying = true
            DisplayingBiographyOrTranscript = false
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            if DisplayingBiographyOrTranscript == false {  // don't stop talk if in biography or transcript view
                terminateTalk()
            }
            TalkIsCurrentlyPlaying = false
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .navigationBarTitle(Text(getPlayerTitle()))
        .navigationBarTitle(album.title, displayMode: .inline)
        .toolbar {
            // to fix the back button disappeared
            ToolbarItem(placement: .navigationBarLeading) {
                Text("")
            }
        }
        .toolbar {
            Button(self.talk.hasTranscript() ? "Transcript" : "") {
                selection = "TRANSCRIPT"
            }
            .hidden(!self.talk.hasTranscript())
        }
    }
}


struct VolumeSlider: UIViewRepresentable {
    
    init() {
    }
    
   func makeUIView(context: Context) -> MPVolumeView {
      MPVolumeView(frame: .zero)
   }

   func updateUIView(_ view: MPVolumeView, context: Context) {}
}
