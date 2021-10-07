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
var ResumableTalk : TalkData!
var ResumableTalkTime : Double = 0
var PlayEntireAlbum: Bool = false
var PlayingDownloadedTalk: Bool = false


var CurrentTalk : TalkData = TalkData.noop()
var CurrentTalkTime : Double = 0

/*
 
 if TheDataModel.isCompletedDownloadTalk(talk: CurrentTalk) {

     PlayingDownloadedTalk = true
     talkURL  = URL(string: "file:////" + MP3_DOWNLOADS_PATH + "/" + CurrentTalk.FileName)!
 }

 */

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
    var startTime: Double
    
    @State private var isTalkActive = false
    @State private var elapsedTime: Double
    @State private var displayedElapsedTime: String
    @State private var sliderUpdating = false
    @State private var selection: String?  = ""
    @State var displayTranscriptPage: Bool = false
    @State var displayBiographyPage: Bool = false
    @State var playTalksInSequence: Bool = false
    @State private var playerTitle: String = "Play Talk"

    
    init(album: AlbumData, talk: TalkData, startTime: Double, displayStartTime: String) {
        
        self.album = album
        self.talk = talk
        self.startTime = startTime
        
        self.elapsedTime = startTime
        self.displayedElapsedTime = displayStartTime
        
        CurrentTalk = self.talk
        CurrentTalkTime = self.startTime
    }

    
    func playTalk() {
        
        
        if TalkPlayerStatus == .PAUSED {
            
            TheTalkPlayer.play()
            return
        
        }
        TalkPlayerStatus = .LOADING
        playerTitle = "Loading Talk"
        
        if talk.isDownloadTalk() {
            print("playing download talk")
            let talkURL  = URL(string: "file:////" + MP3_DOWNLOADS_PATH + "/" + CurrentTalk.FileName)!
            self.elapsedTime = CurrentTalkTime
            TheTalkPlayer = TalkPlayer()
            TheTalkPlayer.talkPlayerView = self
            TheTalkPlayer.startTalk(talkURL: talkURL, startAtTime: self.elapsedTime)
        }
        else if let talkURL = URL(string: URL_MP3_HOST + CurrentTalk.URL)
        {
            self.elapsedTime = CurrentTalkTime
            TheTalkPlayer = TalkPlayer()
            TheTalkPlayer.talkPlayerView = self
            TheTalkPlayer.startTalk(talkURL: talkURL, startAtTime: self.elapsedTime)
        }
      
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
    func talkHasCompleted () {
        print("talkHasCompleted")
        
        TalkPlayerStatus = .FINISHED
        TheTalkPlayer.stop()
        self.resetTalkDisplay()

        // if option is enabled, play the next talk in the current series
        if self.playTalksInSequence == true {

            if var index = self.album.talkList.firstIndex(of: CurrentTalk) {
            
                print("Current sequence talk: ", index, CurrentTalk.Title)
                index += 1
                if index >= self.album.talkList.count { index = 0}
                
                CurrentTalk = self.album.talkList[index]
                CurrentTalkTime = 0
                print("New sequence talk: ", index, CurrentTalk.Title)
            }
            self.playTalk()
        }
        self.updateTitleDisplay()
    }
    
    
    // invoked from background timer in TheTalkPlayer
    func updateView(){

        //print("Update View Elapsed Time", self.elapsedTime)
        TalkPlayerStatus = .PLAYING

        if sliderUpdating == true {
            displayedElapsedTime = Int(self.elapsedTime).displayInClockFormat()

        }
        else {
            self.elapsedTime = Double(TheTalkPlayer.getCurrentTimeInSeconds())
            displayedElapsedTime = Int(self.elapsedTime).displayInClockFormat()
            TalkPlayerStatus = .PLAYING
        }
    
        // if talk is  underway, then stop the busy notifier and activate the display (buttons, durations etc)
        if self.elapsedTime > 0 {

            TalkPlayerStatus = .PLAYING

            // if play time exceeds reporting threshold and not previously reported, report it
            if self.elapsedTime > REPORT_TALK_THRESHOLD, CurrentTalk.isMostRecentTalk() == false {

                TheDataModel.addToTalkHistory(talk: CurrentTalk)
                TheDataModel.reportTalkActivity(type: ACTIVITIES.PLAY_TALK, talk: CurrentTalk)
            }

            // persistent store off the current talk and position in talk
            UserDefaults.standard.set(self.elapsedTime, forKey: "CurrentTalkTime")
            UserDefaults.standard.set(CurrentTalk.FileName, forKey: "TalkName")
            
            if playTalksInSequence {
                
                playerTitle = Int(self.elapsedTime).displayInClockFormat()
                if var index = self.album.talkList.firstIndex(of: CurrentTalk) {
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
           Text(CurrentTalk.Title)
                .background(Color.white)
                .foregroundColor(talk.isDownloaded ? Color.red : Color.black)
                .padding(.trailing, 15)
                .padding(.leading, 15)
                .font(.system(size: 20, weight: .regular, design: .default))
            Spacer()
                .frame(height: 20)
            Text(CurrentTalk.Speaker)
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
                Text(CurrentTalk.TotalSeconds.displayInClockFormat())
                    .font(.system(size: 12, weight: .regular))
                Spacer()
            }
           
            // talk current position control
            Slider(value: $elapsedTime,
                   in: 0...Double(talk.TotalSeconds),
                   onEditingChanged: { editing in
                        sliderUpdating = editing
                    if sliderUpdating == false {
                        TheTalkPlayer.seekToTime(seconds: Int64(elapsedTime))
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
                    selection = "BIOGRAPHY"
                }
                .font(.system(size: 12, weight: .regular))
                .padding(.leading, 15)
                .hidden(!talk.hasBiography())

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
                    //displayTranscriptPage = true
                    selection = "TRANSCRIPTS"
                }
                .font(.system(size: 12, weight: .regular))
                .padding(.trailing, 15)
                .hidden(!talk.hasTranscript())
                
            }
                
            // Standard volume and output device control
            Spacer()
            VolumeSlider()
               .frame(height: 40)
               .padding(.horizontal)
            } // end group 2
  
        }  // VStack
        .popover(isPresented: $displayTranscriptPage) {
            VStack() {
                Spacer()
                    .frame(height: 10)
                Button("Done") {
                    displayTranscriptPage = false
                }
                Spacer()
                    .frame(height: 15)
                TranscriptView(talk: talk)
            }
        }

        .foregroundColor(Color.black.opacity(0.7))
        .padding(.trailing, 0)
        .onDisappear {
            finishTalk()
        }
        .background(NavigationLink(destination: TranscriptView(talk: talk), tag: "TRANSCRIPTS", selection: $selection) { EmptyView() } .hidden())
        .background(NavigationLink(destination: BiographyView(speaker: talk.Speaker), tag: "BIOGRAPHY", selection: $selection) { EmptyView() } .hidden())

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
