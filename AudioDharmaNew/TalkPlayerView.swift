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
    var startTime: Double
    
    @State private var isTalkActive = false
    @State private var elapsedTime: Double = 0
    @State private var displayedElapsedTime: String = "00:00:00"
    @State private var sliderUpdating = false
    @State private var selection: String?  = ""
    @State var displayTranscriptPage: Bool = false


    init(talk: TalkData, startTime: Double) {
        
        self.talk = talk
        self.startTime = startTime
        self.elapsedTime = 0
        
        CurrentTalk = self.talk
    }

    
    func playTalk() {
        
        print(URL_MP3_HOST + talk.URL)
        
        var startAtTime : Double = 0
        if TalkPlayerStatus == .PAUSED {
            startAtTime = self.elapsedTime
        }
        
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
    
    
    // invoked upon TheTalkPlayer completion
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
    
    // invoked from background timer in TheTalkPlayer
    func updateView(){

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
            if self.elapsedTime > REPORT_TALK_THRESHOLD, talk.isMostRecentTalk() == false {

                TheDataModel.addToTalkHistory(talk: self.talk)
                TheDataModel.reportTalkActivity(type: ACTIVITIES.PLAY_TALK, talk: self.talk)
            }
            //MARKPLAYED_TALK_THRESHOLD

            // persistent store off the current talk and position in talk
            UserDefaults.standard.set(self.elapsedTime, forKey: "CurrentTalkTime")
            UserDefaults.standard.set(self.talk.FileName, forKey: "TalkName")

        }

    }


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
                Text(talk.TotalSeconds.displayInClockFormat())
                    .font(.system(size: 12, weight: .regular))
                Spacer()
            }
           
            // talk current position control
            Slider(value: Double($elapsedTime),
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

