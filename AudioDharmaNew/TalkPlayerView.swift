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
    var elapsedTime: Double
    var resumeLastTalk: Bool

    @State var selection: String?  = nil
    @State private var displayedElapsedTime: String
    @State private var sliderUpdating = false
    @State private var silderElapsedTime: Double = 0
    @State var displayTranscriptView: Bool = false
    @State var displayBiographyView: Bool = false
    @State var playTalksInSequence: Bool = false
    @State private var playerTitle: String = "Play Talk"
    @State private var displayNoInternet = false
    @State private var stateTalkPlayer = TalkStates.INITIAL

    
    init(album: AlbumData, talk: TalkData, elapsedTime: Double,  resumeLastTalk: Bool) {
        
        self.album = album
        self.talk = talk
        self.elapsedTime = elapsedTime
        self.resumeLastTalk = resumeLastTalk
        
        self.silderElapsedTime = elapsedTime
        self.displayedElapsedTime = Int(elapsedTime).displayInClockFormat()
        
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
            
            let talkURL  = URL(string: "file:////" + MP3_DOWNLOADS_PATH + "/" + self.talk.FileName)!
            
            print("Will play talk: ", talk.Title)
            stateTalkPlayer = .LOADING
            playerTitle = "Loading Talk"

            TheTalkPlayer = TalkPlayer()
            TheTalkPlayer.talkPlayerView = self
            TheTalkPlayer.startTalk(talkURL: talkURL, startAtTime: self.elapsedTime)
        }
        
        stateTalkPlayer = .PLAYING

    }

    
    func playWebTalk() {
        
        if TheDataModel.isInternetAvailable() == false {
            self.displayNoInternet = true
            return
        }

        if stateTalkPlayer == .PAUSED {
            TheTalkPlayer.play()
        } else {
        
            let talkURL = URL(string: URL_MP3_HOST + self.talk.URL)!
            print("Will play talk: ", talk.Title)
            stateTalkPlayer = .LOADING
            playerTitle = "Loading Talk"

            TheTalkPlayer = TalkPlayer()
            TheTalkPlayer.talkPlayerView = self
            TheTalkPlayer.startTalk(talkURL: talkURL, startAtTime: self.elapsedTime)
        }
    
        stateTalkPlayer = .PLAYING
    }
    
    
    func pauseTalk () {
        
        stateTalkPlayer = .PAUSED
        TheTalkPlayer.pause()
    }
    
    
    func finishTalk() {
    
        print("TalkPlayerView finishTalk")
        TheTalkPlayer?.stop()
        stateTalkPlayer = .FINISHED

    }
    
    
    // invoked upon TheTalkPlayer completion
    mutating func talkHasCompleted () {
        
        TheTalkPlayer.stop()

        // if option is enabled, play the next talk in the current series
        if self.playTalksInSequence == true {


            if var index = self.album.talkList.firstIndex(of: self.talk) {
            
                index += 1
                if index >= self.album.talkList.count { index = 0}
                
                self.silderElapsedTime = 0
                self.talk = self.album.talkList[index]
                self.elapsedTime = 0
                TheDataModel.saveLastAlbumTalkState(album: self.album, talk: self.talk, elapsedTime: self.elapsedTime)
            }
            playTalk()
        }
    }
    
    
    // invoked every second from background timer in TheTalkPlayer
    mutating func updateView(){

        if self.sliderUpdating == true {
            self.displayedElapsedTime = Int(self.silderElapsedTime).displayInClockFormat()
            self.elapsedTime = self.silderElapsedTime
        }
        else {
            self.elapsedTime = Double(TheTalkPlayer.getCurrentTimeInSeconds())
            self.silderElapsedTime = self.elapsedTime
            self.displayedElapsedTime = Int(self.elapsedTime).displayInClockFormat()
        }

        // if talk is  underway, then stop the busy notifier and activate the display (buttons, durations etc)
        if self.elapsedTime > 0 {


            // if play time exceeds reporting threshold and not previously reported, report it
            if self.elapsedTime > REPORT_TALK_THRESHOLD, TheDataModel.isMostRecentTalk(talk: talk) == false {

                TheDataModel.addToTalkHistory(talk: self.talk)
                TheDataModel.reportTalkActivity(type: ACTIVITIES.PLAY_TALK, talk: self.talk)
            }

            // persistent store off the current talk and position in talk
            TheDataModel.saveLastAlbumTalkState(album: album, talk: self.talk, elapsedTime: self.elapsedTime)

            if playTalksInSequence {
                
                playerTitle = Int(self.elapsedTime).displayInClockFormat()
                if var index = self.album.talkList.firstIndex(of: self.talk) {
                    index += 1
                    let count = self.album.talkList.count
                    let position = String(index) + "/" + String(count) + "  "
                    playerTitle = position + Int(self.elapsedTime).displayInClockFormat()
                }
            } else {
                //playerTitle = Int(self.elapsedTime).displayInClockFormat() + " | " + Int(self.talk.TotalSeconds).displayInClockFormat()
                playerTitle = Int(self.elapsedTime).displayInClockFormat()
            }
        }
    }
    
       
    var body: some View {

        VStack(alignment: .center, spacing: 0) {
            Group {
            Spacer()
                .frame(height: 30)
                
           Text(self.talk.Title)
                .foregroundColor(TheDataModel.hasBeenDownloaded(talk: talk) ? COLOR_DOWNLOADED_TALK : Color(UIColor.label))
                .padding(.trailing, 15)
                .padding(.leading, 15)
                .font(.system(size: FONT_SIZE_TALK_PLAYER, weight: .regular, design: .default))
            Spacer()
                .frame(height: 20)
            Text(self.talk.Speaker)
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
                    TheTalkPlayer.seekFastBackward()
                })
                {
                    Image(systemName: "backward.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height:  20)
                        .foregroundColor(Color(UIColor.label))
                }
                Spacer()
                    .frame(width: 20)
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
                                .frame(height: 60)
                                .foregroundColor(Color(UIColor.label))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .hidden(self.stateTalkPlayer == .LOADING)

                }  // end ZStack
                Spacer()
                    .frame(width: 20)
                Button(action: {
                    TheTalkPlayer.seekFastForward()
                })
                {
                    Image(systemName: "forward.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height:  20)
                        //.foregroundColor(self.stateTalkPlayer == .PLAYING ? Color.black : Color.gray)
                        .foregroundColor(Color(UIColor.label))
                }
            }  // end HStack
            
            }  //end group 1
            
            Group {
                
            Spacer()
                .frame(height: 30)
                      
            // talk current position control
            Slider(value: $silderElapsedTime,
                   in: 0...Double(self.talk.TotalSeconds),
                   onEditingChanged: { editing in
                        sliderUpdating = editing
                    if sliderUpdating == false {
                        TheTalkPlayer.seekToTime(seconds: Int64(silderElapsedTime))
                    }
            })
            .padding(.trailing, 20)
            .padding(.leading, 20)
            .frame(height: 30)
            Spacer()
                .frame(height: 25)
            Button(action: {
                self.playTalksInSequence = self.playTalksInSequence ? false : true
            })
            {
                Image(systemName: "equal.circle.fill")
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
                .padding(.horizontal)
          
            } // end group 2
 
        }  // end VStack
      
        .background(NavigationLink(destination: TranscriptView(talk: talk), tag: "TRANSCRIPT", selection: $selection) { EmptyView() } .hidden())
        .background(NavigationLink(destination: BiographyView(talk: talk), tag: "BIOGRAPHY", selection: $selection) { EmptyView() } .hidden())
        .background(NavigationLink(destination: EmptyView()) {EmptyView()}.hidden())
        .padding(.trailing, 0)
        .onAppear {
            TalkIsCurrentlyPlaying = true
            DisplayingBiographyOrTranscript = false
            
        }
        .onDisappear {
            if DisplayingBiographyOrTranscript == false {  // don't stop talk if in biography or transcript view
                finishTalk()
            }
            TalkIsCurrentlyPlaying = false

        }
        .navigationBarTitle(Text(playerTitle))
        .navigationBarTitle(album.Title, displayMode: .inline)
        .toolbar {
            Button(self.talk.hasTranscript() ? "Transcript" : "") {
                selection = "TRANSCRIPT"
            }
            .hidden(!self.talk.hasTranscript())
        }
        .alert(isPresented: $displayNoInternet) {
            Alert(
                title: Text("Can Not Connect to AudioDharma"),
                message: Text("Please check your internet connection or try again in a few minutes"),
                dismissButton: .default(Text("OK")) {
                    
                    displayNoInternet = false
                }
            )
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
