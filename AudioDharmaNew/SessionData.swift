//
//  Data.swift
//  AudioDharmaNew
//
//  Created by Christopher Minson on 9/3/21.
//

import Foundation

import Foundation
import UIKit
import os.log


struct AlbumData: Identifiable {
    
    //MARK: Properties
    let id = UUID()
    var Title: String
    var Key: String
    var Section: String
    var Image: String
    var Duration: Int
    var TalkCount: Int
    var DisplayedDuration: String
    
    init(title: String, key: String, section: String, image: String,  duration: Int, talkCount: Int, displayedDuration: String) {
        
        Title = title
        Key = key
        Section = section
        Image = image
        Duration = duration
        TalkCount = talkCount
        DisplayedDuration = "HERE"
    }
    
    mutating func setDuration(duration: Int) {self.Duration = duration}
    mutating func setDisplayedDuration(displayedDuration: String) {self.DisplayedDuration = displayedDuration}
    mutating func setTalkCount(talkCount: Int) {self.TalkCount = talkCount}

}


struct TalkData: Identifiable {
    
    // MARK: Properties
    let id = UUID()
    var Title: String
    var URL: String
    var FileName: String
    var Date: String
    var Speaker: String
    var Section: String
    var DurationDisplay: String
    var PDF: String
    var DurationInSeconds: Int
    var SpeakerPhoto: UIImage
        
    // MARK: Init
    init(title: String,
         url: String,
         fileName: String,
         date: String,
         durationDisplay: String,
         speaker: String,
         section: String,
         durationInSeconds: Int,
         pdf: String)
    {
        Title = title
        URL = url
        FileName = fileName
        Date = date
        DurationDisplay = durationDisplay
        Speaker = speaker
        Section = section
        DurationInSeconds = durationInSeconds
        PDF = pdf
        
        SpeakerPhoto = UIImage(named: Speaker) ?? UIImage(named: "defaultPhoto")!
     }

}
