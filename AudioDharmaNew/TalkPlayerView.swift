//
//  ListTalksView.swift
//
//  Created by Christopher Minson on 9/8/21.
//  Copyright © 2022 Christopher Minson. All rights reserved.
//

import SwiftUI
import MediaPlayer
import UIKit

var TheTalkPlayer: TalkPlayer!


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
    var talk: TalkData
    var currentTime: Int
    
    @State private var isTalkActive = false
    @State private var elapsedTime: Double = 0
    @State private var displayedElapsedTime: String = "00:00:00"
    @State private var sliderUpdating = false
    @State private var selection: String?  = ""
    @State var displayTranscriptPage: Bool = false


    
    /*
    init(talk: TalkData, currentTime: currentTime) {
        
        self.talk = talk
        self.currentTime = currentTime
        
        elapsedTime = currentTime
    }
 */
    
    func playTalk() {
        
        print(URL_MP3_HOST + talk.URL)
        
        var startAtTime = 0
        if TalkPlayerStatus == .PAUSED {
            startAtTime = CurrentTalkTime
        }
        
        startAtTime = currentTime
        elapsedTime = Double(currentTime)
        
        if let talkURL = URL(string: URL_MP3_HOST + talk.URL) {
            TheTalkPlayer = TalkPlayer()
            TheTalkPlayer.talkPlayerView = self
            TheTalkPlayer.startTalk(talkURL: talkURL, startAtTime: startAtTime)
        }
    }
    
    func pauseTalk () {
        
        TheTalkPlayer.pause()
        TalkPlayerStatus = .PAUSED
    }
    
    func finishTalk() {
        
        TheTalkPlayer?.stop()
        TalkPlayerStatus = .FINISHED
    }
    
    func talkHasCompleted () {
        
        print("talkHasCompleted")
        TalkPlayerStatus = .FINISHED


        /*
            TalkPlayerStatus = .FINISHED

            MP3TalkPlayer.stop()
            CurrentTalkTime = 0
            resetTalkDisplay()

            // if option is enabled, play the next talk in the current series
            if PlayEntireAlbum == true {

                // create a new MP3 player.  just to ensure state is fully cleared
                MP3TalkPlayer = MP3Player()
                MP3TalkPlayer.Delegate = self

                // and then play next talk in SECONDS_TO_NEXT_TALK seconds
                Timer.scheduledTimer(timeInterval: SECONDS_TO_NEXT_TALK, target: self, selector: #selector(PlayTalkController.playNextTalk), userInfo: nil, repeats: false)
            }
            updateTitleDisplay()
 */
    }
    
    func updateView(){

        if sliderUpdating == true {
            displayedElapsedTime = TheDataModel.secondsToDurationDisplay(seconds: Int(elapsedTime))
        }
        else {
            CurrentTalkTime = TheTalkPlayer.getCurrentTimeInSeconds()
            if CurrentTalkTime > 0 {
                elapsedTime = Double(CurrentTalkTime)
                displayedElapsedTime = TheDataModel.secondsToDurationDisplay(seconds: Int(elapsedTime))
                
                TalkPlayerStatus = .PLAYING
            }
         
        }
    
        // if talk is  underway, then stop the busy notifier and activate the display (buttons, durations etc)
        CurrentTalkTime = TheTalkPlayer.getCurrentTimeInSeconds()
        if CurrentTalkTime > 0 {

            TalkPlayerStatus = .PLAYING

            /*
            disableActivityIcons()
            enableScanButtons()
             */

           /*
            let currentTime = TheTalkPlayer.getCurrentTimeInSeconds()
            let duration = TheTalkPlayer.getDurationInSeconds()

            let fractionTimeCompleted = Float(currentTime) / Float(duration)
            talkProgressSlider.value = fractionTimeCompleted

            updateTitleDisplay()
            */

            // if play time exceeds reporting threshold and not previously reported, report it
            if CurrentTalkTime > REPORT_TALK_THRESHOLD, TheDataModel.isMostRecentTalk(talk: CurrentTalk) == false {

                TheDataModel.addToTalkHistory(talk: CurrentTalk)
                TheDataModel.reportTalkActivity(type: ACTIVITIES.PLAY_TALK, talk: CurrentTalk)
            }
            //MARKPLAYED_TALK_THRESHOLD

            UserDefaults.standard.set(CurrentTalkTime, forKey: "CurrentTalkTime")
            UserDefaults.standard.set(CurrentTalk.FileName, forKey: "TalkName")

        }

    }

    /*
    if TheDataModel.isDownloaded(talk: talk) {
        .foreground(Color.black)
    } else {
        .foreground(Color.red)
    }
    */

    var body: some View {

        
        //ZStack {Color(.white).opacity(0.2).edgesIgnoringSafeArea(.all)
        VStack(alignment: .center, spacing: 0) {

            Group {
            Spacer()
                .frame(height: 5)
                
           // title of talk and speaker
           Text(talk.Title)
                .background(Color.white)
                .padding(.trailing, 15)
                .padding(.leading, 15)
                .font(.system(size: 20, weight: .regular, design: .default))
            Spacer()
                .frame(height: 20)
            Text(talk.Speaker)
                .background(Color.white)
                .padding(.trailing, 0)
                .font(.system(size: 20, weight: .regular, design: .default))
            Spacer()
                .frame(height: 20)
                
            // play, pause, fast-forward,  fast-backward buttons
            HStack() {
                Button(action: {
                    print("left pressed")
                    TheTalkPlayer.seekFastBackward()
                })
                {
                    Image(systemName: "arrowtriangle.left")
                        .resizable()
                        //.frame(width: isTalkActive ? 30 : 0, height: isTalkActive ? 30 : 0)
                        .frame(width: 30, height:  30)

                        .disabled(!isTalkActive)

                }
                Spacer()
                    .frame(width: 20)
                Button(action: {
                    print("button pressed")
                    print(isTalkActive)
                    isTalkActive = (isTalkActive ? false : true)
                    if isTalkActive {playTalk()} else {pauseTalk()}
                    })
                    {
                    Image(systemName: isTalkActive ? "square" : "arrowtriangle.right.circle")
                            .resizable()
                            .frame(width: 60, height: 60)
                    }
                    .buttonStyle(PlainButtonStyle())
                Spacer()
                    .frame(width: 20)
                Button(action: {
                    print("right pressed")
                    TheTalkPlayer.seekFastForward()
                })
                {
                    Image(systemName: "arrowtriangle.right")
                        .resizable()
                        //.frame(width: isTalkActive ? 30 : 0, height: isTalkActive ? 30 : 0)
                        .frame(width: 30, height:  30)

                        .disabled(!isTalkActive)
                }
            }  // end HStack
            
            }  //end group 1
            
            Group {
                
            // current time and total time display
            Spacer()
                .frame(height: 30)
            HStack() {
                Spacer()
                Text(displayedElapsedTime)
                    .font(.system(size: 12, weight: .regular))
                Spacer()
                    .frame(width: 20)
                Text("|")
                    .font(.system(size: 12, weight: .regular))
                Spacer()
                    .frame(width: 20)
                Text(talk.DurationDisplay)
                    .font(.system(size: 12, weight: .regular))
                Spacer()
            }
           
            // talk current position control
            Slider(value: $elapsedTime,
                   in: 0...Double(talk.DurationInSeconds),
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
                if TheDataModel.doesTalkHaveTranscript(talk: talk) {
                    Button("transcript") {
                        //displayTranscriptPage = true
                        selection = "TRANSCRIPTS"
                    }
                    .font(.system(size: 20, weight: .regular))
                    .padding(.trailing, 15)

                }
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
            print("DetailView disappeared!")
            finishTalk()
        }
        .background(NavigationLink(destination: TranscriptView(talk: talk), tag: "TRANSCRIPTS", selection: $selection) { EmptyView() } .hidden())
        //}
    }
        //.navigationBarTitle("Play Talk", displayMode: .inline)
        //.navigationBarHidden(false)

    
}
