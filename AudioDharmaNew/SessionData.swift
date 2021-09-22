//
//  Data.swift
//
//  Created by Christopher Minson on 9/3/21.
//  Copyright © 2022 Christopher Minson. All rights reserved.
//

import Foundation

import Foundation
import UIKit
import os.log


class AlbumData: Identifiable {
    
    //MARK: Properties
    let id = UUID()
    var Title: String
    var Key: String
    var Section: String
    var Image: String
    var Date: String

    init(title: String, key: String, section: String, image: String,  date : String) {
        
        Title = title
        Key = key
        Section = section
        Image = image
        Date = date
    }
}


class TalkData: Identifiable {
    
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

