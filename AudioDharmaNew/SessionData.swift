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


enum AlbumType {
    case ACTIVE
    case HISTORICAL
}


class AlbumData: Identifiable, ObservableObject {
    
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

        var filteredTalkList = TheDataModel.ListAllTalks
        if !filter.isEmpty {
            filteredTalkList = []
            for talk in self.talkList {
                let searchedData = talk.Title.lowercased()
                if searchedData.contains(filter.lowercased()) {filteredTalkList.append(talk)}
            }
        }
        
        return filteredTalkList
    }

    
}


class TalkData: Identifiable, Equatable, ObservableObject, NSCopying {
    
    // MARK: Properties
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
    
     
    func toggleTalkAsFavorite() -> Bool {

        if isFavoriteTalk() {
            TheDataModel.UserFavorites[self.FileName] = nil
            if let index = TheDataModel.UserFavoritesAlbum.talkList.firstIndex(of: self) {
                print("toggleTalkAsFavorite removing: ", self.Title)
                TheDataModel.UserFavoritesAlbum.talkList.remove(at: index)
            }
        } else {
            TheDataModel.UserFavorites[self.FileName] = UserFavoriteData(fileName: self.FileName)
            print("toggleTalkAsFavorite adding: ", self.Title)
            TheDataModel.UserFavoritesAlbum.talkList.insert(self, at: 0)
            //CJM Append?
        }

        TheDataModel.saveUserFavoritesData()
        TheDataModel.computeAlbumStats(album: TheDataModel.UserFavoritesAlbum)
        
        let isFavorite = TheDataModel.UserFavorites[self.FileName] != nil
        print("ToggleTalkAsFavorite New Value: ", isFavorite)
        return isFavorite
    }
    
    
    func isFavoriteTalk() -> Bool {
        
        //let isFavorite =  TheDataModel.UserFavorites[self.FileName] != nil
        //print("Favorite Talk: ", isFavorite)
        return TheDataModel.UserFavorites[self.FileName] != nil
    }
    
    
    func startDownload(success: @escaping  () -> Void) {
        
        TheDataModel.startDownload(talk: self, success: success)
    }
    
       
    func isDownloadInProgress() -> Bool {
        
        var downloadInProgress = false
        if let userDownload = TheDataModel.UserDownloads[self.FileName]  {
            downloadInProgress = (userDownload.DownloadCompleted == "NO")
        }
        return downloadInProgress
    }

    
    func setTalkAsDownloaded() {
        
        TheDataModel.UserDownloadAlbum.talkList.insert(self, at: 0)
        TheDataModel.UserDownloads[self.FileName] = UserDownloadData(fileName: self.FileName, downloadCompleted: "YES")
        TheDataModel.saveUserDownloadData()

        TheDataModel.computeAlbumStats(album: TheDataModel.UserDownloadAlbum)

    }
    
    
    func unsetTalkAsDownloaded() {
        
        if let index = TheDataModel.UserDownloadAlbum.talkList.firstIndex(of: self) {
            print("download removing: ", self.Title)
            TheDataModel.UserDownloadAlbum.talkList.remove(at: index)
        }
        
        if let userDownload = TheDataModel.UserDownloads[self.FileName] {
            if userDownload.DownloadCompleted == "NO" {
                TheDataModel.DownloadInProgress = false
            }
        }
        TheDataModel.UserDownloads[self.FileName] = nil
        let localPathMP3 = MP3_DOWNLOADS_PATH + "/" + FileName
        do {
            try FileManager.default.removeItem(atPath: localPathMP3)
        }
        catch let error as NSError {
        }
        
        TheDataModel.saveUserDownloadData()
        TheDataModel.computeAlbumStats(album: TheDataModel.UserDownloadAlbum)
        
    }

    
    func addNoteToTalk(noteText: String) {

        //
        // if there is a note text for this talk fileName, then save it in the note dictionary
        // otherwise clear this note dictionary entry
        let talkFileName = self.FileName

        if (noteText.count > 0) && noteText.rangeOfCharacter(from: CharacterSet.alphanumerics) != nil {
            print("adding note on talk: ", self.Title)
            TheDataModel.UserNotes[talkFileName] = UserNoteData(notes: noteText)
            TheDataModel.UserNoteAlbum.talkList.append(self)
        } else {
            print("remove note on talk: ", self.Title)
            TheDataModel.UserNotes[talkFileName] = nil
            if let index = TheDataModel.UserNoteAlbum.talkList.firstIndex(of: self) {
                TheDataModel.UserNoteAlbum.talkList.remove(at: index)
            }

        }
        
        // save the data, recompute stats, reload root view to display updated stats
        TheDataModel.saveUserNoteData()
        TheDataModel.computeAlbumStats(album: TheDataModel.UserNoteAlbum)
    }
    
    
    func getNoteForTalk() -> String {

        var noteText = ""

        if let userNoteData = TheDataModel.UserNotes[self.FileName]   {
            noteText = userNoteData.Notes
        }
        return noteText
    }


    func isNotatedTalk() -> Bool {
        
        if let _ = TheDataModel.UserNotes[self.FileName] {
            return true
        }
        return false
    }
    
    
    func hasTalkBeenPlayed() -> Bool {
    
        return TheDataModel.PlayedTalks[self.FileName] != nil

    }

    
    func isMostRecentTalk() -> Bool {
    
        if let talk = TheDataModel.UserTalkHistoryAlbum.talkList.last {
            return talk.FileName == self.FileName
        }
        return false
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
    
    
    func hasBeenDownloaded() -> Bool {

        return TheDataModel.UserDownloads[self.FileName] != nil

    }
    
    
    func hasBiography() -> Bool {
        
        return true
    }



}

