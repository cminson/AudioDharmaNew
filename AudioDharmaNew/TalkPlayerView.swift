//
//  ListTalksView.swift
//
//  Created by Christopher Minson on 9/8/21.
//  Copyright © 2022 Christopher Minson. All rights reserved.
//

import SwiftUI
import MediaPlayer
import UIKit



enum TalkStates {                   // all possible states of the talk player
    case INITIAL
    case LOADING
    case PLAYING
    case PAUSED
    case STOPPED
    case FINISHED
    case ALBUMFINISHED
}

var TalkPlayerStatus: TalkStates = TalkStates.INITIAL

var TheTalkPlayer: TalkPlayer!
var PlayEntireAlbum: Bool = false
var PlayingDownloadedTalk: Bool = false


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
    var talk: TalkData
    var elapsedTime: Double

    @State private var isTalkActive = false
    @State private var displayedElapsedTime: String
    @State private var sliderUpdating = false
    @State private var silderElapsedTime: Double = 0
    @State var displayTranscriptView: Bool = false
    @State var displayBiographyView: Bool = false
    @State var playTalksInSequence: Bool = false
    @State private var playerTitle: String = "Play Talk"

    
    
    init(album: AlbumData, talk: TalkData, elapsedTime: Double) {
        
        self.album = album
        self.talk = talk
        self.elapsedTime = elapsedTime
        print("TalkPlayerView Init: ", talk.Title)
        
        self.silderElapsedTime = elapsedTime
        self.displayedElapsedTime = Int(elapsedTime).displayInClockFormat()
        
    
    }

    
    func playTalk() {
        
        
        print("Play TalkPlayerView: ", talk.Title)

        if TalkPlayerStatus == .PAUSED {
            
            TheTalkPlayer.play()
            return
        
        }
        TalkPlayerStatus = .LOADING
        playerTitle = "Loading Talk"
        

        var talkURL : URL
        if self.talk.hasBeenDownloaded() {
            print("pyaling download talk")
            talkURL  = URL(string: "file:////" + MP3_DOWNLOADS_PATH + "/" + self.talk.FileName)!
        }
        else {
            talkURL = URL(string: URL_MP3_HOST + self.talk.URL)!
        }
        print(talkURL)
        TheTalkPlayer = TalkPlayer()
        TheTalkPlayer.talkPlayerView = self
        TheTalkPlayer.startTalk(talkURL: talkURL, startAtTime: self.elapsedTime)

      
    }
    
    
    func pauseTalk () {
        
        TalkPlayerStatus = .PAUSED

        TheTalkPlayer.pause()
    }
    
    
    func finishTalk() {
    
        TheTalkPlayer?.stop()
        TalkPlayerStatus = .FINISHED

    }
    
    
    func resetTalkDisplay() {
        
        print("resetTalkDisplay")
    }
    
      
    func updateTitleDisplay() {
        print("updateTitleDisplay")
        
    }
    
    
    // invoked upon TheTalkPlayer completion
    mutating func talkHasCompleted () {
        print("talkHasCompleted")
        
        TalkPlayerStatus = .FINISHED
        TheTalkPlayer.stop()
        self.resetTalkDisplay()

        // if option is enabled, play the next talk in the current series
        if self.playTalksInSequence == true {

            if var index = self.album.talkList.firstIndex(of: self.talk) {
            
                print("Old sequence talk: ", index, self.talk.Title)
                index += 1
                if index >= self.album.talkList.count { index = 0}
                
                self.silderElapsedTime = 0
                self.talk = self.album.talkList[index]
                self.elapsedTime = 0
                TheDataModel.saveLastTalkState(talk: self.talk, elapsedTime: self.elapsedTime)

                print("New sequence talk: ", index, self.talk.Title)
            }
            self.playTalk()
        }
        self.updateTitleDisplay()
    }
    
    
    // invoked from background timer in TheTalkPlayer
    mutating func updateView(){

        //print("Update View Elapsed Time", self.elapsedTime)
        TalkPlayerStatus = .PLAYING

        if self.sliderUpdating == true {
            self.displayedElapsedTime = Int(self.silderElapsedTime).displayInClockFormat()
            self.elapsedTime = self.silderElapsedTime
        }
        else {
            self.elapsedTime = Double(TheTalkPlayer.getCurrentTimeInSeconds())
            self.silderElapsedTime = self.elapsedTime
            self.displayedElapsedTime = Int(self.elapsedTime).displayInClockFormat()
            TalkPlayerStatus = .PLAYING
        }
    
        // if talk is  underway, then stop the busy notifier and activate the display (buttons, durations etc)
        if self.elapsedTime > 0 {

            TalkPlayerStatus = .PLAYING

            // if play time exceeds reporting threshold and not previously reported, report it
            if self.elapsedTime > REPORT_TALK_THRESHOLD, self.talk.isMostRecentTalk() == false {

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
    
    
    var body: some View {

        VStack(alignment: .center, spacing: 0) {

            Group {
            Spacer()
                .frame(height: 15)
                
           // title, speaker
           Text(self.talk.Title)
                .background(Color.white)
                .foregroundColor(self.talk.hasBeenDownloaded() ? Color.red : Color.black)
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
                        //.frame(width: isTalkActive ? 30 : 0, height: isTalkActive ? 30 : 0)
                        .frame(width: 30, height:  30)

                        //.disabled(!isTalkActive)

                }
                Spacer()
                    .frame(width: 20)
                ZStack() {
                    ProgressView()
                        .hidden(TalkPlayerStatus != .LOADING)
                    Button(action: {
                        isTalkActive = (isTalkActive ? false : true)
                        if isTalkActive {playTalk()} else {pauseTalk()}
                        })
                        {
                        Image(isTalkActive ? "buttontalkpause" : "buttontalkplay")
                                .resizable()
                                .frame(width: 60, height: 60)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .hidden(TalkPlayerStatus == .LOADING)
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
                        //.disabled(!isTalkActive)
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
                 Button("biography") {
                     displayBiographyView = true
                }
                .font(.system(size: 12, weight: .regular))
                .padding(.leading, 15)
                .hidden(!self.talk.hasBiography())

                Spacer()
                
                VStack(spacing: 5) {
                    Button(action: {
                        self.playTalksInSequence = playTalksInSequence ? false : true
                    })
                    {
                        Image(playTalksInSequence ? "playTalkSequenceOn" : "playTalkSequenceOff")
                            .resizable()
                            .frame(width: 30, height:  30)
                            //.disabled(!isTalkActive)
                    }
                    Text("play talk sequence")
                        .font(.system(size: 12, weight: .regular))

                }
                
                Spacer()
                Button("transcript") {
                    print("display transcript")
                    displayTranscriptView = true
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
  
        }  // VStack
        .popover(isPresented: $displayTranscriptView) {
            VStack() {
                Spacer()
                    .frame(height: 10)
                Button("Done") {
                    displayTranscriptView = false
                }
                Spacer()
                    .frame(height: 15)
                TranscriptView(talk: self.talk)
            }
        }
        .popover(isPresented: $displayBiographyView) {
            VStack() {
                Spacer()
                    .frame(height: 10)
                Button("Done") {
                    displayBiographyView = false
                }
                Spacer()
                    .frame(height: 15)
                BiographyView(speaker: self.talk.Speaker)
            }
        }
     


        .foregroundColor(Color.black.opacity(0.7))
        .padding(.trailing, 0)
        .onDisappear {
            finishTalk()
        }
        .navigationBarTitle(Text(playerTitle))

      
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
