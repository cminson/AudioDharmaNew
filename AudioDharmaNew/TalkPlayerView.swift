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

struct VolumeSlider: UIViewRepresentable {
    
   func makeUIView(context: Context) -> MPVolumeView {
      MPVolumeView(frame: .zero)
   }

   func updateUIView(_ view: MPVolumeView, context: Context) {}
}

struct TalkPlayerView: View {
    var album: AlbumData
    @State var talk: TalkData
    var elapsedTime: Double

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



    init(album: AlbumData, talk: TalkData, elapsedTime: Double) {
        
        self.album = album
        self.talk = talk
        self.elapsedTime = elapsedTime
        
        self.silderElapsedTime = elapsedTime
        self.displayedElapsedTime = Int(elapsedTime).displayInClockFormat()
        
    }

    
    func playTalk() {
        
        if TheDataModel.isInternetAvailable() == false {
            
            self.displayNoInternet = true
            return
        }
        
        if stateTalkPlayer == .PAUSED {
            
            TheTalkPlayer.play()
            return
    
        }
        stateTalkPlayer = .LOADING
        playerTitle = "Loading Talk"
        
        print("Will play talk: ", talk.Title)

        var talkURL : URL
        if TheDataModel.hasBeenDownloaded(talk: self.talk) {
            print("playing download edtalk")
            talkURL  = URL(string: "file:////" + MP3_DOWNLOADS_PATH + "/" + self.talk.FileName)!
        }
        else {
            talkURL = URL(string: URL_MP3_HOST + self.talk.URL)!
        }
        TheTalkPlayer = TalkPlayer()
        TheTalkPlayer.talkPlayerView = self
        TheTalkPlayer.startTalk(talkURL: talkURL, startAtTime: self.elapsedTime)
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
    
    
    func resetTalkDisplay() {
        
        print("resetTalkDisplay")
    }
    
      
    func updateTitleDisplay() {
        print("updateTitleDisplay")
        
    }
    
    
    // invoked upon TheTalkPlayer completion
    mutating func talkHasCompleted () {
        
        stateTalkPlayer = .FINISHED
        TheTalkPlayer.stop()
        resetTalkDisplay()

        // if option is enabled, play the next talk in the current series
        if self.playTalksInSequence == true {


            if var index = self.album.talkList.firstIndex(of: self.talk) {
            
                index += 1
                if index >= self.album.talkList.count { index = 0}
                
                self.silderElapsedTime = 0
                self.talk = self.album.talkList[index]
                self.elapsedTime = 0
                TheDataModel.saveLastTalkState(talk: self.talk, elapsedTime: self.elapsedTime)
            }
            playTalk()
        }
        updateTitleDisplay()
    }
    
    
    // invoked from background timer in TheTalkPlayer
    mutating func updateView(){

        stateTalkPlayer = .PLAYING

        if self.sliderUpdating == true {
            self.displayedElapsedTime = Int(self.silderElapsedTime).displayInClockFormat()
            self.elapsedTime = self.silderElapsedTime
        }
        else {
            self.elapsedTime = Double(TheTalkPlayer.getCurrentTimeInSeconds())
            self.silderElapsedTime = self.elapsedTime
            self.displayedElapsedTime = Int(self.elapsedTime).displayInClockFormat()
            stateTalkPlayer = .PLAYING
        }

        // if talk is  underway, then stop the busy notifier and activate the display (buttons, durations etc)
        if self.elapsedTime > 0 {

            stateTalkPlayer = .PLAYING

            // if play time exceeds reporting threshold and not previously reported, report it
            if self.elapsedTime > REPORT_TALK_THRESHOLD, TheDataModel.isMostRecentTalk(talk: talk) == false {

                TheDataModel.addToTalkHistory(talk: self.talk)
                TheDataModel.reportTalkActivity(type: ACTIVITIES.PLAY_TALK, talk: self.talk)
            }

            // persistent store off the current talk and position in talk
            TheDataModel.saveLastTalkState(talk: self.talk, elapsedTime: self.elapsedTime)

            if playTalksInSequence {
                
                playerTitle = Int(self.elapsedTime).displayInClockFormat()
                if var index = self.album.talkList.firstIndex(of: self.talk) {
                    index += 1
                    let count = self.album.talkList.count
                    let position = String(index) + "/" + String(count) + "  "
                    playerTitle = position + Int(self.elapsedTime).displayInClockFormat()
                }
            } else {
                playerTitle = Int(self.elapsedTime).displayInClockFormat()

            }
        }
    }
    
    func debug() -> Text {
        print("RENDERING:", self.talk.Title)
            return Text(self.talk.Title)
    }
    
    var body: some View {

        VStack(alignment: .center, spacing: 0) {

            Group {
            Spacer()
                .frame(height: 15)
                
           Text(self.talk.Title)
                .background(Color.white)
                .foregroundColor(TheDataModel.hasBeenDownloaded(talk: talk) ? Color.red : Color.black)
                .padding(.trailing, 15)
                .padding(.leading, 15)
                .font(.system(size: 20, weight: .regular, design: .default))
            Spacer()
                .frame(height: 20)
            Text(self.talk.Speaker)
                .background(Color.white)
                .padding(.trailing, 0)
                .font(.system(size: 20, weight: .regular, design: .default))
            Spacer()
                .frame(height: 20)
                
            // play, pause, fast-forward,  fast-backward buttons
            HStack() {
                Button(action: {
                    TheTalkPlayer.seekFastBackward()
                })
                {
                    Image("tri_left_x")
                        .resizable()
                        .frame(width: 30, height:  30)
                }
                Spacer()
                    .frame(width: 20)
                ZStack() {
                    ProgressView()
                        .hidden(stateTalkPlayer != .LOADING)
                    Button(action: {
                        self.stateTalkPlayer == .PLAYING ? pauseTalk() : playTalk()
                        })
                        {
                            Image(self.stateTalkPlayer == .PLAYING ? "buttontalkpause" : "buttontalkplay")
                                .resizable()
                                .frame(width: 60, height: 60)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .hidden(stateTalkPlayer == .LOADING)
                }  // end ZStack
                Spacer()
                    .frame(width: 20)
                Button(action: {
                    TheTalkPlayer.seekFastForward()
                })
                {
                    Image("tri_right_x")
                        .resizable()
                        .frame(width: 30, height:  30)
                }
            }  // end HStack
            
            }  //end group 1
            
            Group {
                
            // current time and total time display
            Spacer()
                .frame(height: 30)
            HStack() {
                Spacer()
                Text(self.displayedElapsedTime)
                    .font(.system(size: 12, weight: .regular))
                Spacer()
                    .frame(width: 20)
                Text("|")
                    .font(.system(size: 12, weight: .regular))
                Spacer()
                    .frame(width: 20)
                Text(self.talk.TotalSeconds.displayInClockFormat())
                    .font(.system(size: 12, weight: .regular))
                Spacer()
            }
           
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
                
            // optional biograph and transcript buttons
            Spacer()
                .frame(height: 20)
            HStack() {
                 Button("About This Speaker") {
                     DisplayingBiographyOrTranscript = true
                     selection = "BIOGRAPHY"
                }
                .font(.system(size: 12, weight: .regular))
                .padding(.leading, 15)
                .hidden(!self.talk.hasBiography())

                Spacer()
                
                VStack(spacing: 5) {
                    Button(action: {
                        self.playTalksInSequence = self.playTalksInSequence ? false : true
                    })
                    {
                        Image(self.playTalksInSequence ? "playTalkSequenceOn" : "playTalkSequenceOff")
                            .resizable()
                            .frame(width: 30, height:  30)
                    }
                    Text("play talk sequence")
                        .font(.system(size: 12, weight: .regular))

                }
                
                Spacer()
                Button("transcript") {
                    DisplayingBiographyOrTranscript = true
                    selection = "TRANSCRIPT"
                }
                .font(.system(size: 12, weight: .regular))
                .padding(.trailing, 15)
                .hidden(!self.talk.hasTranscript())
            }
                
            // Standard volume and output device control
            Spacer()
            VolumeSlider()
               .frame(height: 40)
               .padding(.horizontal)
            } // end group 2
  
        }  // end VStack
        .onAppear {
            TalkIsCurrentlyPlaying = true
        }
        .onDisappear {
            TalkIsCurrentlyPlaying = false
        }

        .background(NavigationLink(destination: TranscriptView(talk: talk), tag: "TRANSCRIPT", selection: $selection) { EmptyView() } .hidden())
        .background(NavigationLink(destination: BiographyView(talk: talk), tag: "BIOGRAPHY", selection: $selection) { EmptyView() } .hidden())
        .foregroundColor(Color.black.opacity(0.7))
        .padding(.trailing, 0)
        .onAppear {
            print("TalkPlayerView appeared")
            DisplayingBiographyOrTranscript = false
        }
        .onDisappear {
            print("TalkPlayerView disappearing")
            if DisplayingBiographyOrTranscript == false {
                finishTalk()
            }
        }
        .navigationBarTitle(Text(playerTitle))
        .alert(isPresented: $displayNoInternet) {
            Alert(
                title: Text("Can Not Connect to AudioDharma"),
                message: Text("Please check your internet connection or try again in a few minutes"),
                primaryButton: .destructive(Text("OK")) {
                    
                    displayNoInternet = false

                },
                secondaryButton: .cancel()
            )
        }
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

    /*
     
     .navigationBarBackButtonHidden(true)
    .toolbar(content: {
          ToolbarItem (placement: .navigation)  {
             Image(systemName: "arrow.left")
             .foregroundColor(.white)
             .onTapGesture {
                 //self.presentation.wrappedValue.dismiss()
             }
          }
    })
     */
