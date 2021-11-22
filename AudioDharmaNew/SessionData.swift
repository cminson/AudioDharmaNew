//
//  SessionData.swift
//
//  Definitions of talks (TalkData) and albums (ALbumData).  These two classes are used
//  throughtout the app.
//
//
//  Created by Christopher Minson on 9/3/21.
//  Copyright © 2022 Christopher Minson. All rights reserved.
//

import Foundation
import UIKit
import os.log


enum AlbumType {
    case ACTIVE
    case HISTORICAL
}


//
// AlbumData describes an album.  Containes either a list of talks
// or a list of albums (never both, by convention)
//
class AlbumData: Identifiable, Equatable, ObservableObject {
    
    @Published var totalTalks: Int
    let id = UUID()
    var title: String
    var key: String
    var section: String
    var imageName: String
    var date: String
    var totalSeconds: Int
    var albumList: [AlbumData]
    var talkList: [TalkData]
    var albumType: AlbumType
    
    static func ==(lhs: AlbumData, rhs: AlbumData) -> Bool {
        return lhs.key == rhs.key && lhs.title == rhs.title
    }


    init(title: String, key: String, section: String, imageName: String,  date : String, albumType: AlbumType) {
        
        self.title = title
        self.key = key
        self.section = section
        self.imageName = imageName
        self.date = date
        
        self.albumList = []
        self.talkList = []
        
        self.totalTalks = 0
        self.totalSeconds = 0
        self.albumType = albumType
    }
    
    
    static func empty () -> AlbumData {
        return AlbumData(title: "New Album", key: "", section: "", imageName: "personal", date: "", albumType: AlbumType.ACTIVE)
    }

    
    func isEmpty() -> Bool {
        return self.title.isEmpty
    }

    
    func getAlbumSections(section: String) -> [AlbumData] {

        var sectionAlbumList = [AlbumData] ()

        if section.isEmpty {
            return self.albumList
        } else {
            sectionAlbumList = self.albumList.filter {$0.section == section}
        }
        return sectionAlbumList
    }
    
    
    func getFilteredAlbums(filter: String) -> [AlbumData] {

        var filteredAlbumList = [AlbumData] ()

        GuardUpdateSemaphore.wait()

        if filter.isEmpty {
            GuardUpdateSemaphore.signal()
            return self.albumList
        } else {
            for album in self.albumList {
                let searchedData = album.title.lowercased()
                if searchedData.contains(filter.lowercased()) {filteredAlbumList.append(album)}
            }
        }

        GuardUpdateSemaphore.signal()
        return filteredAlbumList
    }
    
    
    func getFilteredTalks(filter: String) -> [TalkData] {

           
        GuardUpdateSemaphore.wait()  // obtain critical-section access on talkList

        var filteredTalkList = self.talkList
        if !filter.isEmpty {
            filteredTalkList = []
            for talk in self.talkList {
                let transcript = talk.hasTranscript() ? "transcript" : ""
                let searchedData = talk.title.lowercased() + talk.speaker.lowercased() + transcript + TheDataModel.getNoteForTalk(talk: talk).lowercased()
                if searchedData.contains(filter.lowercased()) {filteredTalkList.append(talk)}
            }
        }

        GuardUpdateSemaphore.signal()
        
        return filteredTalkList
    }

    
    func getFilteredUserTalks(filter: String) -> [TalkData] {

        var allTalks : [TalkData] = []
        
        GuardUpdateSemaphore.wait()

        let talkSet = Set(self.talkList)
        var listAllTalks = TheDataModel.ListAllTalks
        listAllTalks.removeAll(where: { talkSet.contains($0) })
        allTalks = self.talkList + listAllTalks

        if !filter.isEmpty {
            var filteredTalkList: [TalkData] = []
            for talk in allTalks {
                let transcript = talk.hasTranscript() ? "transcript" : ""
                let searchedData = talk.title.lowercased() + talk.speaker.lowercased() + transcript + TheDataModel.getNoteForTalk(talk: talk).lowercased()
                if searchedData.contains(filter.lowercased()) {filteredTalkList.append(talk)}
            }
            allTalks = filteredTalkList
        }
        
        GuardUpdateSemaphore.signal()
        
        return allTalks
    }
}


//
// TalkData describes a talk.
//
class TalkData: Identifiable, Equatable, ObservableObject, NSCopying, Hashable, CustomStringConvertible {
    
    let id = UUID()
    var title: String
    var URL: String
    var fileName: String
    var date: String
    var speaker: String
    var ln: String
    var transcript: String
    var totalSeconds: Int
    var speakerPhoto: UIImage
    var datePlayed: String
    var timePlayed: String
    var city: String
    var country: String
  
    
    static func ==(lhs: TalkData, rhs: TalkData) -> Bool {
        return lhs.fileName == rhs.fileName && lhs.fileName == rhs.fileName
    }
    
    
    static func empty () -> TalkData {
        return TalkData(title: "", url: "", fileName: "", date: "", speaker: "defaultPhoto", ln: "en", totalSeconds: 0,  transcript: "")
    }
    
    var description: String {
            return "\(id) \(title) \(URL) \(fileName) \(date) \(speaker) \(ln) \(transcript) \(totalSeconds) \(datePlayed) \(timePlayed) \(city) \(country)"
    }
    
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(fileName)
    }

        
    init(title: String,
         url: String,
         fileName: String,
         date: String,
         speaker: String,
         ln: String,
         totalSeconds: Int,
         transcript: String)
    {
        self.title = title
        self.URL = url
        self.fileName = fileName
        self.date = date
        self.speaker = speaker
        self.ln = ln
        self.totalSeconds = totalSeconds
        self.transcript = transcript
        
        self.speakerPhoto = UIImage(named: speaker) ?? UIImage(named: "defaultPhoto")!
            
        self.datePlayed = ""
        self.timePlayed = ""
        self.city = ""
        self.country = ""
     }
    
    
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = TalkData(title: title,
                            url: URL,
                            fileName: fileName,
                            date: date,
                            speaker: speaker,
                            ln: ln,
                            totalSeconds: totalSeconds,
                            transcript: transcript)
        
        return copy
    }
    
    
    func isEmpty() -> Bool {
        return self.title.isEmpty
    }
    
     
    func hasTranscript() -> Bool {
        
        if self.transcript.lowercased().range(of:"http:") != nil {
            return true
        }
        else if self.transcript.lowercased().range(of:"https:") != nil {
            return true
        }
        return false
    }
    
    
    func hasBiography() -> Bool {
        
        return true
    }
}

