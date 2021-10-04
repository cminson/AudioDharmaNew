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


enum TalkType {
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
    var talkType: TalkType
    

    init(title: String, key: String, section: String, imageName: String,  date : String) {
        
        Title = title
        Key = key
        Section = section
        ImageName = imageName
        Date = date
        
        albumList = []
        talkList = []
        
        totalTalks = 0
        totalSeconds = 0
        talkType = TalkType.ACTIVE
    }
    
    
    func getAlbumSections(section: String) -> [AlbumData] {

        var sectionAlbumList = [AlbumData] ()

        if section.isEmpty {
            return self.albumList
        } else {
            sectionAlbumList = self.albumList.filter {$0.Section == section}
            /*
            for album in self.albumList {
                if album.Section == section {sectionAlbumList.append(album)}
            }
             */
        }
        return sectionAlbumList
    }
    
    
    func getFilteredAlbums(filter: String) -> [AlbumData] {

        var filteredAlbumList = [AlbumData] ()

        if filter == "TEST" {
            let test = AlbumData(title: "test", key: "test", section: "", imageName: "speaker", date: "01-01-01")
            var testa = [test]
            for _ in 1 ... 100 {
                testa.append(test)
            }
            return testa
        }
  
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

        var filteredTalkList = [TalkData] ()

        if filter.isEmpty {
            return self.talkList
        } else {

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
    @Published var isDownloaded: Bool
    
    var DatePlayed: String
    var TimePlayed: String
    var City: String
    var Country: String
  
    
    static func ==(lhs: TalkData, rhs: TalkData) -> Bool {
        return lhs.FileName == rhs.FileName && lhs.FileName == rhs.FileName
    }

        
    init(title: String,
         url: String,
         fileName: String,
         date: String,
         speaker: String,
         totalSeconds: Int,
         pdf: String)
    {
        Title = title
        URL = url
        FileName = fileName
        Date = date
        Speaker = speaker
        TotalSeconds = totalSeconds
        PDF = pdf
        
        SpeakerPhoto = UIImage(named: Speaker) ?? UIImage(named: "defaultPhoto")!
        isDownloaded = false
        
        DatePlayed = ""
        TimePlayed = ""
        City = ""
        Country = ""
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

        return TheDataModel.UserFavorites[self.FileName] != nil
    }
    
    
    func isFavoriteTalk() -> Bool {
        
        return TheDataModel.UserFavorites[self.FileName] != nil
    }
    
    
    func download(notifyUI: @escaping  () -> Void) {
        
        TheDataModel.download(talk: self, notifyUI: notifyUI)
    }
    
       
    func isDownloadInProgress() -> Bool {
        
        var downloadInProgress = false
        if let userDownload = TheDataModel.UserDownloads[self.FileName]  {
            downloadInProgress = (userDownload.DownloadCompleted == "NO")
        }
        return downloadInProgress
    }

    
    func setTalkAsDownloaded() {
        
        TheDataModel.UserDownloadAlbum.talkList.append(self)
        TheDataModel.UserDownloads[self.FileName] = UserDownloadData(fileName: self.FileName, downloadCompleted: "YES")
        TheDataModel.saveUserDownloadData()
        TheDataModel.computeAlbumStats(album: TheDataModel.UserDownloadAlbum)
        
        // CJM DEV - Must be moved into main UI thread  receive: on:
        self.isDownloaded = true
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
        
        self.isDownloaded = false
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
     



}

