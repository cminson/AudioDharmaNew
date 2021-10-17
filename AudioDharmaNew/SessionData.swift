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
    var Title: String
    var Key: String
    var Section: String
    var ImageName: String
    var Date: String
    var totalSeconds: Int
    var albumList: [AlbumData]
    var talkList: [TalkData]
    var albumType: AlbumType
    
    static func ==(lhs: AlbumData, rhs: AlbumData) -> Bool {
        return lhs.Key == rhs.Key && lhs.Title == rhs.Title
    }


    init(title: String, key: String, section: String, imageName: String,  date : String, albumType: AlbumType) {
        
        self.Title = title
        self.Key = key
        self.Section = section
        self.ImageName = imageName
        self.Date = date
        
        self.albumList = []
        self.talkList = []
        
        self.totalTalks = 0
        self.totalSeconds = 0
        self.albumType = albumType
    }
    
    
    static func empty () -> AlbumData {
        return AlbumData(title: "", key: "", section: "", imageName: "albumDefault", date: "", albumType: AlbumType.ACTIVE)
    }

    
    func isEmpty() -> Bool {
        return self.Title.isEmpty
    }

    
    func getAlbumSections(section: String) -> [AlbumData] {

        var sectionAlbumList = [AlbumData] ()

        if section.isEmpty {
            return self.albumList
        } else {
            sectionAlbumList = self.albumList.filter {$0.Section == section}
        }
        return sectionAlbumList
    }
    
    
    func getFilteredAlbums(filter: String) -> [AlbumData] {

        var filteredAlbumList = [AlbumData] ()

        print("getFilteredAlbums:", self.Title)
        if filter.isEmpty {
            return self.albumList
        } else {
            for album in self.albumList {
                let searchedData = album.Title.lowercased()
                if searchedData.contains(filter.lowercased()) {filteredAlbumList.append(album)}
            }
        }
        return filteredAlbumList
    }
    
    
    func getFilteredTalks(filter: String) -> [TalkData] {

        if self.Key == TheDataModel.SanghaShareHistoryAlbum.Key || self.Key == TheDataModel.SanghaTalkHistoryAlbum.Key {
            GuardCommunityAlbumSemaphore.wait()  // obtain critical-section access on talkList
        }
        var filteredTalkList = self.talkList
        if !filter.isEmpty {
            filteredTalkList = []
            for talk in self.talkList {
                let searchedData = talk.Title.lowercased()
                if searchedData.contains(filter.lowercased()) {filteredTalkList.append(talk)}
            }
        }
        if self.Key == TheDataModel.SanghaShareHistoryAlbum.Key || self.Key == TheDataModel.SanghaTalkHistoryAlbum.Key {
            GuardCommunityAlbumSemaphore.signal()  // release critical-section access on talkList
        }
        
        return filteredTalkList
    }

    
    func getFilteredUserTalks(filter: String) -> [TalkData] {

        let talkSet = Set(self.talkList)
        var listAllTalks = TheDataModel.ListAllTalks
        listAllTalks.removeAll(where: { talkSet.contains($0) })
        var allTalks = self.talkList + listAllTalks

        if !filter.isEmpty {
            var filteredTalkList: [TalkData] = []
            for talk in allTalks {
                let searchedData = talk.Title.lowercased()
                if searchedData.contains(filter.lowercased()) {filteredTalkList.append(talk)}
            }
            allTalks = filteredTalkList
        }
        
        return allTalks
    }
}


//
// TalkData describes a talk.
//
class TalkData: Identifiable, Equatable, ObservableObject, NSCopying, Hashable {
    
    let id = UUID()
    var Title: String
    var URL: String
    var FileName: String
    var Date: String
    var Speaker: String
    var PDF: String
    var TotalSeconds: Int
    var SpeakerPhoto: UIImage
    var DatePlayed: String
    var TimePlayed: String
    var City: String
    var Country: String
  
    
    static func ==(lhs: TalkData, rhs: TalkData) -> Bool {
        return lhs.FileName == rhs.FileName && lhs.FileName == rhs.FileName
    }
    
    
    static func empty () -> TalkData {
        return TalkData(title: "", url: "", fileName: "", date: "", speaker: "defaultPhoto", totalSeconds: 0,  pdf: "")
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(FileName)
    }

        
    init(title: String,
         url: String,
         fileName: String,
         date: String,
         speaker: String,
         totalSeconds: Int,
         pdf: String)
    {
        self.Title = title
        self.URL = url
        self.FileName = fileName
        self.Date = date
        self.Speaker = speaker
        self.TotalSeconds = totalSeconds
        self.PDF = pdf
        

        self.SpeakerPhoto = UIImage(named: Speaker) ?? UIImage(named: "defaultPhoto")!
            
        
        self.DatePlayed = ""
        self.TimePlayed = ""
        self.City = ""
        self.Country = ""
     }
    
    
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = TalkData(title: Title,
                            url: URL,
                            fileName: FileName,
                            date: Date,
                            speaker: Speaker,
                            totalSeconds: TotalSeconds,
                            pdf: PDF)
        
        return copy
    }
    
    
    func isEmpty() -> Bool {
        return self.Title.isEmpty
    }
    
     
    func hasTranscript() -> Bool {
        
        if self.PDF.lowercased().range(of:"http:") != nil {
            return true
        }
        else if self.PDF.lowercased().range(of:"https:") != nil {
            return true
        }
        return false
    }
    
    
    func hasBiography() -> Bool {
        
        return true
    }
}

