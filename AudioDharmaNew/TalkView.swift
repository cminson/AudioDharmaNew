//
//  ListTalksView.swift
//  AudioDharmaNew
//
//  Created by Christopher Minson on 9/8/21.
//

import SwiftUI
import MediaPlayer
import UIKit


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
    @State private var isTalkActive = false
    @State private var elapsedTime: Double = 0
    @State private var displayedElapsedTime: String = "00:00:00"
    @State private var sliderUpdating = false
    
    /*
        @State private var  elapsedTime: Double = 0 {
      willSet {
        print("WILLSET")
        //TheTalkPlayer.seekToTime(seconds: Int64(newValue))
        print(newValue)
      }
    }
 */

    func playTalk() {
        
        //let pathMP3 = URL_MP3_HOST + talk.URL
        let pathMP3 = "https://virtualdharma.org/AudioDharmaAppBackend/data/TALKS/20210826-Kim_Allen-IMC-the_depth_of_the_body_3_of_4_the_body_as_a_support_for_concentration.mp3"
        if let talkURL = URL(string: pathMP3) {
        
            print("URL \(pathMP3)")

            TheTalkPlayer = TalkPlayer()
            TheTalkPlayer.talkPlayerView = self
            TheTalkPlayer.startTalk(talkURL: talkURL, startAtTime: 0)
        }
    }
    
    func pauseTalk () {
        
        TheTalkPlayer.pause()
    }
    
    func talkHasCompleted () {
        
        print("talkHasCompleted")

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

        print("updateView")
        if sliderUpdating == true {
            displayedElapsedTime = TheDataModel.secondsToDurationDisplay(seconds: Int(elapsedTime))
        }
        else {
            CurrentTalkTime = TheTalkPlayer.getCurrentTimeInSeconds()
            if CurrentTalkTime > 0 {
                elapsedTime = Double(CurrentTalkTime)
                displayedElapsedTime = TheDataModel.secondsToDurationDisplay(seconds: Int(elapsedTime))
        }
         
    }
        

            // if talk is  underway, then stop the busy notifier and activate the display (buttons, durations etc)
        /*
            CurrentTalkTime = MP3TalkPlayer.getCurrentTimeInSeconds()
            if CurrentTalkTime > 0 {

                TalkPlayerStatus = .PLAYING

                disableActivityIcons()
                enableScanButtons()

                // show current talk time and actual talk duration
                // note these may be different from what is stated in the (often inaccurate) config!
                let currentTime = MP3TalkPlayer.getCurrentTimeInSeconds()
                let duration = MP3TalkPlayer.getDurationInSeconds()

                let fractionTimeCompleted = Float(currentTime) / Float(duration)
                talkProgressSlider.value = fractionTimeCompleted

                updateTitleDisplay()

                // if play time exceeds reporting threshold and not previously reported, report it
                if CurrentTalkTime > REPORT_TALK_THRESHOLD, TheDataModel.isMostRecentTalk(talk: CurrentTalk) == false {

                    TheDataModel.addToTalkHistory(talk: CurrentTalk)
                    TheDataModel.reportTalkActivity(type: ACTIVITIES.PLAY_TALK, talk: CurrentTalk)
                }
                //MARKPLAYED_TALK_THRESHOLD

                UserDefaults.standard.set(CurrentTalkTime, forKey: "CurrentTalkTime")
                UserDefaults.standard.set(CurrentTalk.FileName, forKey: "TalkName")

            }
 */
    }


    var body: some View {
        
        ZStack {Color(.orange).opacity(0.2).edgesIgnoringSafeArea(.all)
        VStack(alignment: .center, spacing: 10) {

            Group {
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
            Text(displayedElapsedTime)
                .font(.system(size: 20, weight: .heavy))

            Spacer()
                .frame(height: 10)
            Button(action: {
                print("button pressed")
                print(isTalkActive)
                isTalkActive = (isTalkActive ? false : true)
                if isTalkActive {playTalk()} else {pauseTalk()}
            })
            {
                Image(isTalkActive ? "blacksquare" : "tri_right")
                    .resizable()
                    .frame(width: 60, height: 60)
            }
            .buttonStyle(PlainButtonStyle())
            }  //end group 1
            
            Spacer()
                .frame(height: 30)
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
            Spacer()
           
            VolumeSlider()
               .frame(height: 40)
               .padding(.horizontal)
  
        }  // VStack
        .foregroundColor(Color.black.opacity(0.7))
        .padding(.trailing, 0)
        } // ZStack
    }
        //.navigationBarTitle("Play Talk", displayMode: .inline)
        //.navigationBarHidden(false)

    
}
