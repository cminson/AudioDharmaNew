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
    
    //MARK: Properties
    let id = UUID()
    var Title: String
    var Key: String
    var Section: String
    var Image: String
    var Date: String
    
    @Published var totalTalks: Int
    var totalSeconds: Int
    var durationDisplay: String
    
    var albumList: [AlbumData]
    var talkList: [TalkData]
    var talkType: TalkType
    

    init(title: String, key: String, section: String, image: String,  date : String) {
        
        Title = title
        Key = key
        Section = section
        Image = image
        Date = date
        
        albumList = []
        talkList = []
        
        totalTalks = 0
        totalSeconds = 0
        durationDisplay = "00:00:00"
        talkType = TalkType.ACTIVE
        
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
    var DurationDisplay: String
    var PDF: String
    var DurationInSeconds: Int
    var SpeakerPhoto: UIImage
    @Published var isDownloaded: Bool
    
    var DatePlayed: String
    var TimePlayed: String
    var City: String
    var Country: String
  
    
    static func ==(lhs: TalkData, rhs: TalkData) -> Bool {
        return lhs.FileName == rhs.FileName && lhs.FileName == rhs.FileName
    }

        
    // MARK: Init
    init(title: String,
         url: String,
         fileName: String,
         date: String,
         durationDisplay: String,
         speaker: String,
         durationInSeconds: Int,
         pdf: String)
    {
        Title = title
        URL = url
        FileName = fileName
        Date = date
        DurationDisplay = durationDisplay
        Speaker = speaker
        DurationInSeconds = durationInSeconds
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
                            durationDisplay: DurationDisplay,
                            speaker: Speaker,
                            durationInSeconds: DurationInSeconds,
                            pdf: PDF)
        
        return copy
    }
    
     
    func toggleTalkAsFavorite() -> Bool {

        if isFavoriteTalk() {
            TheDataModel.UserFavorites[self.FileName] = nil
            if let index = TheDataModel.UserFavoritesAlbum.talkList.firstIndex(of: self) {
                print("toglleTalkAsFavorite removing: ", self.Title)
                TheDataModel.UserFavoritesAlbum.talkList.remove(at: index)
            }
        } else {
            TheDataModel.UserFavorites[self.FileName] = UserFavoriteData(fileName: self.FileName)
            print("toglleTalkAsFavorite adding: ", self.Title)
            TheDataModel.UserFavoritesAlbum.talkList.append(self)
        }

        TheDataModel.saveUserFavoritesData()
        TheDataModel.computeAlbumStats(album: TheDataModel.UserFavoritesAlbum)

        return TheDataModel.UserFavorites[self.FileName] != nil
    }
    
    
    func isFavoriteTalk() -> Bool {
        
        let isFavorite = TheDataModel.UserFavorites[self.FileName] != nil
        return isFavorite
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

        let charset = CharacterSet.alphanumerics

        if (noteText.count > 0) && noteText.rangeOfCharacter(from: charset) != nil {
            TheDataModel.UserNotes[talkFileName] = UserNoteData(notes: noteText)
        } else {
            TheDataModel.UserNotes[talkFileName] = nil
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



}

