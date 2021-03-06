//
//  Model.swift
//
//  The data model for the app.  Here are all the functions to download and configure the app,
//  as well as all functions necessary for updating app state.
//
//  Created by Christopher Minson on 6/22/17.
//  Copyright © 2022 Christopher Minson. All rights reserved.
//

import UIKit
import Foundation 
import SystemConfiguration
import os.log
import ZipArchive

var DEBUG = false


var TheDataModel: Model = Model() // TheDataModel is the model for all views elsewhere in the program

// Web Config Entry Points
let HostAccessPoints: [String] = [
    "http://www.virtualdharma.org",
    "http://www.audiodharma.org"
]
var HostAccessPoint: String = HostAccessPoints[0]   // the one we're currently using

//
// Paths for Services
//
//let CONFIG_JSON_NAME = "DEV.JSON"
//let CONFIG_ZIP_NAME = "DEV.ZIP"

let CONFIG_JSON_NAME = "CONFIG00.JSON"
let CONFIG_ZIP_NAME = "CONFIG00.ZIP"

var MP3_DOWNLOADS_PATH = ""      // where MP3s are downloaded.  this is set up in loadData()
let CONFIG_ACCESS_PATH = "/AudioDharmaAppBackend/Config/" + CONFIG_ZIP_NAME    // remote web path to config
let CONFIG_REPORT_ACTIVITY_PATH = "/AudioDharmaAppBackend/Access/reportactivity.php"     // where to report user activity (shares, listens)
let CONFIG_GET_ACTIVITY_PATH = "/AudioDharmaAppBackend/Access/XGETACTIVITY.php?"           // where to get sangha activity (shares, listens)

let CONFIG_GET_SIMILAR_TALKS = "/AudioDharmaAppBackend/Access/XGETSIMILARTALKS.php?KEY="           // where to get similar talks\
let DEFAULT_MP3_PATH = "http://www.audiodharma.org"     // where to get talks
let DEFAULT_DONATE_PATH = "http://audiodharma.org/donate/"       // where to donate
let DEFAULT_SHARE_URL_MP3_HOST =  "https://virtualdharma.org/AudioDharmaAppBackend/data/TALKS/"

let MIN_EXPECTED_RESPONSE_SIZE = 300   // to filter for bogus redirect page responses

var USE_NATIVE_MP3PATHS = true    // true = mp3s are in their native paths in audiodharma, false =  mp3s are in one flat directory


// Default Web Access Points
var URL_CONFIGURATION = HostAccessPoint + CONFIG_ACCESS_PATH
var URL_REPORT_ACTIVITY = HostAccessPoint + CONFIG_REPORT_ACTIVITY_PATH
var URL_GET_ACTIVITY = HostAccessPoint + CONFIG_GET_ACTIVITY_PATH
var URL_GET_SIMILAR = HostAccessPoint + CONFIG_GET_SIMILAR_TALKS
var URL_MP3_HOST = DEFAULT_MP3_PATH
var URL_DONATE = DEFAULT_DONATE_PATH
var SHARE_URL_MP3_HOST = DEFAULT_SHARE_URL_MP3_HOST


//
// Ids for Albums.  Used to map JSON
//
let KEY_ALBUMROOT = "KEY_ALBUMROOT"
let KEY_TALKS = "KEY_TALKS"
let KEY_ALL_TALKS = "KEY_ALLTALKS"
let KEY_SIMILAR_TALKS = "KEY_SIMILARTALKS"
let KEY_SUGGESTED_TALKS = "KEY_SUGGESTEDTALKS"
let KEY_GIL_FRONSDAL = "Gil Fronsdal"
let KEY_ANDREA_FELLA = "Andrea Fella"
let KEY_ALL_SPEAKERS = "KEY_ALLSPEAKERS"
let KEY_ALL_SERIES = "KEY_ALL_SERIES"
let KEY_DHARMETTES = "KEY_DHARMETTES"
let KEY_RECOMMENDED_TALKS = "KEY_RECOMMENDED_TALKS"
let KEY_NOTES = "KEY_NOTES"
let KEY_USER_SHAREHISTORY = "KEY_USER_SHAREHISTORY"
let KEY_USER_TALKHISTORY = "KEY_USER_TALKHISTORY"
let KEY_USER_FAVORITES = "KEY_USER_FAVORITES"
let KEY_USER_DOWNLOADS = "KEY_USER_DOWNLOADS"
let KEY_SANGHA_TALKHISTORY = "KEY_SANGHA_TALKHISTORY"
let KEY_SANGHA_SHAREHISTORY = "KEY_SANGHA_SHAREHISTORY"
let KEY_USER_ALBUMS = "KEY_USER_ALBUMS"
let KEY_USEREDIT_ALBUMS = "KEY_USEREDIT_ALBUMS"
let KEY_USER_TALKS = "KEY_USER_TALKS"
let KEY_USEREDIT_TALKS = "KEY_USEREDIT_TALKS"
let KEY_PLAY_TALK = "KEY_PLAY_TALK"
let KEY_TRANCRIPT_TALKS = "KEY_TRANSCRIPT_TALKS"
let KEY_SHORT_TALKS = "KEY_SHORT_TALKS"

let KEY_ALBUMROOT_SPANISH = "KEY_ALBUMROOT_SPANISH"
let KEY_ALL_TALKS_SPANISH = "KEY_ALLTALKS_SPANISH"
let KEY_ALL_SPEAKERS_SPANISH = "KEY_ALLSPEAKERS_SPANISH"
let KEY_RECOMMENDED_TALKS_SPANISH = "KEY_RECOMMENDED_TALKS_SPANISH"
let KEY_ALL_SERIES_SPANISH = "KEY_ALL_SERIES_SPANISH"


let MP3_BYTES_PER_SECOND = 20000    // rough (high) estimate for how many bytes per second of MP3.  Used to estimate size of download files
let REPORT_TALK_THRESHOLD : Double = 90      // how many seconds into a talk before reporting that talk that has been officially played
let SECONDS_TO_NEXT_TALK : Double = 2   // when playing an album, this is the interval between talks
var MAX_TALKHISTORY_COUNT = 3000     // maximum number of played talks showed in sangha history. over-rideable by config
var MAX_SHAREHISTORY_COUNT = 100     // maximum number of shared talks showed in sangha history  over-rideable by config
var MAX_HISTORY_COUNT = 100         // maximum number of user (not sangha) talk history displayed
var UPDATE_SANGHA_INTERVAL = 120   // amount of time (in seconds) between each poll of the cloud for updated sangha info

let KEYS_TO_ALBUMS = [KEY_ALBUMROOT, KEY_RECOMMENDED_TALKS, KEY_ALL_SERIES, KEY_ALL_SPEAKERS, KEY_ALBUMROOT_SPANISH, KEY_ALL_SERIES_SPANISH, KEY_ALL_SPEAKERS_SPANISH, KEY_RECOMMENDED_TALKS_SPANISH]
let KEYS_TO_USER_ALBUMS = [KEY_USER_ALBUMS]

let DEVICE_ID = UIDevice.current.identifierForVendor!.uuidString

enum ACTIVITIES {          // all possible activities that are reported back to cloud
    case SHARE_TALK
    case PLAY_TALK
    case DOWNLOAD_TALK
    case READ_TRANSCRIPT
}
enum INIT_CODES {          // all possible startup results
    case SUCCESS
    case NO_CONNECTION
}

var ModelReadySemaphore = DispatchSemaphore(value: 0)  // signals when data loading is finished.
var GuardUpdateSemaphore = DispatchSemaphore(value: 1) // guards album.talklist a community album is being updated
var ConfigUpdateRequired = false



class Model {
    
    
    var KeyToAlbum : [String: AlbumData] = [:]  //  dictionary keyed by "key" which is a albumd id, value is an album

    var RootAlbum: AlbumData = AlbumData(title: "ROOT", key: KEY_ALBUMROOT, section: "", imageName: "albumdefault", date: "", albumType: AlbumType.ACTIVE)

    var FileNameToTalk: [String: TalkData]   = [String: TalkData] ()  // dictionary keyed by talk filename, value is the talk data (used by userList code to lazily bind)
    
    var AllTalksAlbum =  AlbumData(title: "All Talks", key: KEY_USER_ALBUMS, section: "", imageName: "albumdefault", date: "", albumType: AlbumType.ACTIVE)
    var RecommendedAlbum: AlbumData = AlbumData(title: "RECOMMENDED", key: KEY_ALBUMROOT, section: "", imageName: "albumdefault", date: "", albumType: AlbumType.ACTIVE)
    var UserFavoritesAlbum: AlbumData = AlbumData(title: "USER FAVORITES", key: KEY_USER_FAVORITES, section: "", imageName: "albumdefault", date: "", albumType: AlbumType.ACTIVE)
    var UserNoteAlbum: AlbumData = AlbumData(title: "USER NOTES", key: KEY_NOTES, section: "", imageName: "albumdefault", date: "", albumType: AlbumType.ACTIVE)
    var UserDownloadAlbum: AlbumData = AlbumData(title: "USER DOWNLOADS", key: KEY_USER_DOWNLOADS, section: "", imageName: "albumdefault", date: "", albumType: AlbumType.ACTIVE)
    var SanghaTalkHistoryAlbum =  AlbumData(title: "Today's Talk History", key: KEY_SANGHA_TALKHISTORY, section: "", imageName: "albumdefault", date: "", albumType: AlbumType.HISTORICAL)
    var SanghaShareHistoryAlbum =  AlbumData(title: "Today's Shared Talks", key: KEY_SANGHA_SHAREHISTORY, section: "", imageName: "albumdefault", date: "", albumType: AlbumType.HISTORICAL)
    var UserTalkHistoryAlbum =  AlbumData(title: "Played Talks", key: KEY_USER_TALKHISTORY, section: "", imageName: "albumdefault", date: "", albumType: AlbumType.ACTIVE)
    var UserShareHistoryAlbum =  AlbumData(title: "Shared Talks", key: KEY_USER_SHAREHISTORY, section: "", imageName: "albumdefault", date: "", albumType: AlbumType.ACTIVE)
    var SimilarTalksAlbum =  AlbumData(title: "Similar Talks", key: KEY_SIMILAR_TALKS, section: "", imageName: "albumdefault", date: "", albumType: AlbumType.ACTIVE)
    var CustomUserAlbums =  AlbumData(title: "Custom Albums", key: KEY_USER_ALBUMS, section: "", imageName: "albumdefault", date: "", albumType: AlbumType.ACTIVE)
    var TranscriptsAlbum =  AlbumData(title: "Talks With Transcripts", key: KEY_TRANCRIPT_TALKS, section: "", imageName: "defaultPhoto", date: "", albumType: AlbumType.ACTIVE)
    
    var RootAlbumSpanish: AlbumData = AlbumData(title: "ROOT", key: KEY_ALBUMROOT_SPANISH, section: "", imageName: "albumdefault", date: "", albumType: AlbumType.ACTIVE)
    var AllTalksAlbumSpanish =  AlbumData(title: "All Spanish Talks", key: KEY_USER_ALBUMS, section: "", imageName: "albumdefault", date: "", albumType: AlbumType.ACTIVE)
    var RecommendedAlbumSpanish: AlbumData = AlbumData(title: "RECOMMENDED", key: KEY_ALBUMROOT, section: "", imageName: "albumdefault", date: "", albumType: AlbumType.ACTIVE)


    var ListAllTalks: [TalkData] = []
    var ListSpeakerAlbums: [AlbumData] = []
    var ListSeriesAlbums: [AlbumData] = []
    var ListFavoriteTalls : [TalkData] = []
    var ListTranscriptTalks : [TalkData] = []

    var ListAllTalksSpanish: [TalkData] = []
    var ListSpeakerAlbumsSpanish: [AlbumData] = []
    var ListSeriesAlbumsSpanish: [AlbumData] = []

    var DownloadInProgress = false

    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!

    var UserAlbums: [UserAlbumData] = []      // all the custom user albums defined by this user.
    var UserNotes: [String: UserNoteData] = [:]      // all the  user notes defined by this user, indexed by fileName
    var UserFavorites: [String: UserFavoriteData] = [:]      // all the favorites defined by this user, indexed by fileName
    var UserDownloads: [String: UserDownloadData] = [:]      // all the downloads defined by this user, indexed by fileName
    var PlayedTalks: [String: Bool]   = [:]  // all the talks that have been played by this user, indexed by fileName
    let PlayedTalks_ArchiveURL = DocumentsDirectory.appendingPathComponent("PlayedTalks")
    
    var SystemIsConfigured = false  // set to true if a config file was found and configured
    var CONFIG_UPDATED_TIME_STAMP : Date? = nil

    
    func currentTalkExists() -> Bool {
        
        return CurrentTalk.fileName.isEmpty == false
    }
    
    
    func loadLastAlbumTalkState() {
        
        if let talkName = UserDefaults.standard.string(forKey: "TalkName") {
            if let elapsedTime = UserDefaults.standard.string(forKey: "CurrentTalkTime") {
                if let talk = TheDataModel.getTalkForName(name: talkName) {
                    
                    CurrentTalk = talk
                    CurrentTalkElapsedTime = Double(elapsedTime) ?? 0
                    CurrentAlbum = AlbumData.empty()
                    if let key = UserDefaults.standard.string(forKey: "AlbumKey") {

                        if let album = KeyToAlbum[key] {

                            CurrentAlbum = album
                        }
                    }
                }
            }
        }
    }
    
    
    func saveLastAlbumTalkState(album: AlbumData, talk: TalkData, elapsedTime: Double) {
        
        CurrentTalk = talk
        CurrentAlbum = album
        CurrentTalkElapsedTime = elapsedTime
        UserDefaults.standard.set(CurrentTalkElapsedTime, forKey: "CurrentTalkTime")
        UserDefaults.standard.set(CurrentTalk.fileName, forKey: "TalkName")
        UserDefaults.standard.set(CurrentAlbum.key, forKey: "AlbumKey")
    }
 
    
    //
    // download the zip file at URL_CONFIGURATION endpoint.  store it on the device
    //
    func downloadConfig()  {
        
        // build the data directories on device, if needed
        let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        MP3_DOWNLOADS_PATH = documentPath + "/DOWNLOADS"

        if !FileManager.default.fileExists(atPath: MP3_DOWNLOADS_PATH, isDirectory: nil)
        {
            do {
                try FileManager.default.createDirectory(atPath: MP3_DOWNLOADS_PATH, withIntermediateDirectories: false, attributes: nil)
            } catch let error as NSError {
                errorLog(error: error)
            }
        }

        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        let session = URLSession.init(configuration: config)
        
        let requestURL : URL? = URL(string: URL_CONFIGURATION)
        let urlRequest = URLRequest(url : requestURL!)
        
        
        let task = session.dataTask(with: urlRequest) {
            (data, response, error) -> Void in
            
            let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            let configZipPath = documentPath + "/" + CONFIG_ZIP_NAME

            // get config zip file. error if failed
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                
                ModelReadySemaphore.signal()
                return
            }
            guard let responseData = data, responseData.count > MIN_EXPECTED_RESPONSE_SIZE else {
                
                ModelReadySemaphore.signal()
                return
            }
            
            // write the zip file to local storage
            do {
                if let responseData = data {
                    try responseData.write(to: URL(fileURLWithPath: configZipPath))
                }
            }
            catch let error as NSError {
                self.errorLog(error: error)
                ModelReadySemaphore.signal()
                return
            }
            
            // unzip it
            if SSZipArchive.unzipFile(atPath: configZipPath, toDestination: documentPath) != true {
                
                ModelReadySemaphore.signal()
                return
            }
            
            ModelReadySemaphore.signal()
        }
        task.resume()

        
    }
    
    
    //
    // install all the albums and talks defined in the downloaded JSON config file
    //
    func installConfig() {
    
        
        let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let configJSONPath = documentPath + "/" + CONFIG_JSON_NAME
        
        PlayedTalks = loadPlayedTalksData()
        UserDownloads = loadUserDownloadData()
        validateUserDownloadData()

        
        // get our unzipped json from the local storage and process it
        var jsonData: Data!
        do {
            jsonData = try Data(contentsOf: URL(fileURLWithPath: configJSONPath))
        }

        catch let error as NSError {
            
            self.errorLog(error: error)
            ModelReadySemaphore.signal()
            return
        }
                    
        do {
            

            let jsonDict =  try JSONSerialization.jsonObject(with: jsonData) as! [String: AnyObject]
            self.loadGlobalParameters(jsonDict: jsonDict)
        
            self.loadTalks(jsonDict: jsonDict)
            self.loadAlbums(jsonDict: jsonDict)
            self.loadAlbumsSpanish(jsonDict: jsonDict)
            self.loadLastAlbumTalkState()

            for album in self.RootAlbum.albumList {
                self.computeAlbumStats(album: album)
            }
            for album in self.CustomUserAlbums.albumList {
                self.computeAlbumStats(album: album)
            }
            for album in self.RootAlbumSpanish.albumList {
                self.computeAlbumStats(album: album)
            }
            for album in self.RecommendedAlbum.albumList {
                self.computeAlbumStats(album:album)
            }
        }
        catch {
        }
        

        self.SystemIsConfigured = true
        
        // END CRITICAL SECTION
        print("MODEL SIGNALLING")
        ModelReadySemaphore.signal()
    }
    
    
    func loadGlobalParameters(jsonDict: [String: AnyObject]) {
        
        if let config = jsonDict["config"] {

            URL_MP3_HOST = config["URL_MP3_HOST"] as? String ?? URL_MP3_HOST
            USE_NATIVE_MP3PATHS = config["USE_NATIVE_MP3PATHS"] as? Bool ?? USE_NATIVE_MP3PATHS
            URL_REPORT_ACTIVITY = config["URL_REPORT_ACTIVITY"] as? String ?? URL_REPORT_ACTIVITY
            URL_GET_ACTIVITY = config["URL_GET_ACTIVITY"] as? String ?? URL_GET_ACTIVITY
            SHARE_URL_MP3_HOST = config["SHARE_URL_MP3_HOST"] as? String ?? DEFAULT_SHARE_URL_MP3_HOST

            URL_DONATE = config["URL_DONATE"] as? String ?? URL_DONATE
        
            MAX_TALKHISTORY_COUNT = config["MAX_TALKHISTORY_COUNT"] as? Int ?? MAX_TALKHISTORY_COUNT
            MAX_SHAREHISTORY_COUNT = config["MAX_SHAREHISTORY_COUNT"] as? Int ?? MAX_SHAREHISTORY_COUNT
            UPDATE_SANGHA_INTERVAL = config["UPDATE_SANGHA_INTERVAL"] as? Int ?? UPDATE_SANGHA_INTERVAL
        }
    }
    
    
    func loadTalks(jsonDict: [String: AnyObject]) {
        
        print("loadTalks")
        var talkCount = 0
        
        // get all talks
        for jsonTalk in jsonDict["talks"] as? [AnyObject] ?? [] {
                
                let series = jsonTalk["series"] as? String ?? ""
                let title = jsonTalk["title"] as? String ?? ""
                let URL = (jsonTalk["url"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                let speaker = jsonTalk["speaker"] as? String ?? ""
                let ln = jsonTalk["ln"] as? String ?? "en"
                var date = jsonTalk["date"] as? String ?? ""
                date = date.replacingOccurrences(of: "-", with: ".")
                let duration = jsonTalk["duration"] as? String ?? ""
                let transcript = jsonTalk["pdf"] as? String ?? ""
                
                let terms = URL.components(separatedBy: "/")
                let fileName = terms.last ?? ""
                
                let seconds = duration.convertDurationToSeconds()
            
                let talk =  TalkData(title: title,
                                         url: URL,
                                         fileName: fileName,
                                         date: date,
                                         speaker: speaker,
                                         ln: ln,
                                         totalSeconds: seconds,
                                         transcript: transcript)
               
            
                self.FileNameToTalk[fileName] = talk
                
                // add this talk to  list of all talks
                ListAllTalks.append(talk)
                if talk.ln == "es" {
                    ListAllTalksSpanish.append(talk)
                }

                let speakerAlbum = getAlbumByKey(key: speaker+talk.ln, title: speaker, section: "",  imageName: speaker)
                if ListSpeakerAlbums.contains(speakerAlbum) == false {
                    
                    ListSpeakerAlbums.append(speakerAlbum)
                       if talk.ln == "es" {
                            ListSpeakerAlbumsSpanish.append(speakerAlbum)
                        }
                }
            
                speakerAlbum.talkList.append(talk)

                // if a series is specified,  add it
                if !series.isEmpty {
                    
                    if series == "Dharmettes" {continue}
                    let seriesAlbum = getAlbumByKey(key: "SERIES" + series, title: series, section: "", imageName: speaker)

                    if ListSeriesAlbums.contains(seriesAlbum) == false {
                        
                        ListSeriesAlbums.append(seriesAlbum)
                        if talk.ln == "es" {
                            ListSeriesAlbumsSpanish.append(seriesAlbum)
                        }
                     }
               
                    seriesAlbum.talkList.append(talk)
                 }
                
                talkCount += 1
        }
        
        for album in ListSpeakerAlbums {
            computeAlbumStats(album: album)
        }
        for album in ListSeriesAlbums {
            computeAlbumStats(album: album)
        }
        for album in ListSpeakerAlbumsSpanish {
            computeAlbumStats(album: album)
        }
        for album in ListSeriesAlbumsSpanish {
            computeAlbumStats(album: album)
        }

        
        // sort the albums
        ListSpeakerAlbums = ListSpeakerAlbums.sorted(by: { $0.key < $1.key })
        ListSeriesAlbums = ListSeriesAlbums.sorted(by: { $1.date < $0.date })
        ListAllTalks = ListAllTalks.sorted(by: { $0.date > $1.date })
        ListSpeakerAlbumsSpanish = ListSpeakerAlbumsSpanish.sorted(by: { $0.key < $1.key })
        ListSeriesAlbumsSpanish = ListSeriesAlbumsSpanish.sorted(by: { $1.date < $0.date })
        ListAllTalksSpanish = ListAllTalksSpanish.sorted(by: { $0.date > $1.date })

        
        //  sort all talks in series albums
        for seriesAlbum in ListSeriesAlbums {

 
            let talkList = seriesAlbum.talkList
            seriesAlbum.talkList  = talkList.sorted(by: { $1.date > $0.date })
        }
        for seriesAlbum in ListSeriesAlbumsSpanish {

            let talkList = seriesAlbum.talkList
            seriesAlbum.talkList  = talkList.sorted(by: { $1.date > $0.date })
        }

        computeAlbumStats(album: TranscriptsAlbum)

    }
    

    func loadAlbums(jsonDict: [String: AnyObject]) {

        print("loadAlbums")

        var albumList : [AlbumData] = []
        var talkList : [TalkData] = []
        
        for jsonAlbum in jsonDict["albums"] as? [AnyObject] ?? [] {
            
                let albumSection = jsonAlbum["section2"] as? String ?? ""
                let title = jsonAlbum["title"] as? String ?? ""
                let key = jsonAlbum["content"] as? String ?? ""
                let image = jsonAlbum["image"] as? String ?? ""
                var jsonTalkList = jsonAlbum["talks"] as? [AnyObject] ?? []
            
                let album = getAlbumByKey(key: key, title: title, section: albumSection, imageName: image)
   
                talkList = []
                albumList = []
            
                switch (key) {
                case KEY_ALL_TALKS:
                    AllTalksAlbum = album
                    talkList = ListAllTalks
                case KEY_ALBUMROOT_SPANISH:
                    RootAlbumSpanish = album
                    jsonTalkList = [] // clear this.  bridge old vs new use of this album
                case KEY_ALL_SPEAKERS:
                    albumList = ListSpeakerAlbums
                case KEY_ALL_SERIES:
                    albumList = ListSeriesAlbums
                case KEY_RECOMMENDED_TALKS:
                    RecommendedAlbum = album
                    albumList = []
                    talkList = []
                case KEY_TRANCRIPT_TALKS:
                    TranscriptsAlbum = album
                    talkList = ListTranscriptTalks
                case KEY_USER_FAVORITES:
                    UserFavoritesAlbum = album
                    UserFavorites = TheDataModel.loadUserFavoriteData()
                    for (fileName, _ ) in self.UserFavorites {
                        if let talk = FileNameToTalk[fileName] {
                            talkList.append(talk)
                        }
                    }
                case KEY_NOTES:
                    UserNoteAlbum = album
                    UserNotes = TheDataModel.loadUserNoteData()
                    for (fileName, _ ) in self.UserNotes {
                        if let talk = FileNameToTalk[fileName] {
                            talkList.append(talk)
                        }
                    }
                case KEY_USER_DOWNLOADS:
                    UserDownloadAlbum = album
                    for (fileName, _ ) in self.UserDownloads {
                        if let talk = FileNameToTalk[fileName] {
                            talkList.append(talk)
                        }
                    }
                case KEY_USER_ALBUMS:
                    CustomUserAlbums = album
                    UserAlbums = TheDataModel.loadUserAlbumData()
                    for userAlbumData in self.UserAlbums {
                        let albumKey = self.randomKey()
                        let customAlbum = AlbumData(title: userAlbumData.Title, key: self.randomKey(), section: "", imageName: "personal", date: "", albumType: AlbumType.ACTIVE)
                        KeyToAlbum[albumKey] = customAlbum
                        albumList.append(customAlbum)
                        for fileName in userAlbumData.TalkFileNames {
                            if let talk = FileNameToTalk[fileName] {
                                customAlbum.talkList.append(talk)
                            }
                        }
                        
                    }
                case KEY_USER_TALKHISTORY:
                    UserTalkHistoryAlbum = album
                    talkList = TheDataModel.loadTalkHistoryData()

                case KEY_USER_SHAREHISTORY:
                    album.albumType = AlbumType.HISTORICAL
                    UserShareHistoryAlbum = album
                    talkList = TheDataModel.loadShareHistoryData()

                case KEY_SANGHA_TALKHISTORY:
                    album.albumType = AlbumType.HISTORICAL
                    SanghaTalkHistoryAlbum = album
                case KEY_SANGHA_SHAREHISTORY:
                    album.albumType = AlbumType.HISTORICAL
                    SanghaShareHistoryAlbum = album
    
                default:
                    albumList = []
                    talkList = []
                }
                album.albumList = albumList
                album.talkList = talkList
            
                RootAlbum.albumList.append(album)
                KeyToAlbum[key] = album

                // get the optional talk array for this Album
                for jsonTalk in jsonTalkList {
                    
                    let URL = jsonTalk["url"] as? String ?? ""
                    let series = jsonTalk["series"] as? String ?? ""
                    let title = jsonTalk["title"] as? String ?? ""

                    let fileName = URL.components(separatedBy: "/").last ?? ""
                         
                    if let talk = self.FileNameToTalk[fileName] {
                        
                        // if series specified, these always go into RecommendedAlbum
                        let talkHistory = talk.copy() as! TalkData
                        talkHistory.title = title
                        if !series.isEmpty {

                            let seriesAlbum = getAlbumByKey(key: "RECOMMENDED" + series, title: series, section: "",  imageName: talk.speaker)
                            if RecommendedAlbum.albumList.contains(seriesAlbum) == false {

                                RecommendedAlbum.albumList.append(seriesAlbum)
                            }
                            seriesAlbum.talkList.append(talkHistory)

                        } else {
                            album.talkList.append(talkHistory)
                        }
                    }
                } // end talk loop
        } // end Album loop

    }
    
    
    func loadAlbumsSpanish(jsonDict: [String: AnyObject]) {

        var albumList : [AlbumData] = []
        var talkList : [TalkData] = []
        
        for jsonAlbum in jsonDict["albums_spanish"] as? [AnyObject] ?? [] {
            
                let albumSection = jsonAlbum["albumSection"] as? String ?? ""
                let title = jsonAlbum["title"] as? String ?? ""
                let key = jsonAlbum["content"] as? String ?? ""
                let image = jsonAlbum["image"] as? String ?? ""
                let jsonTalkList = jsonAlbum["talks"] as? [AnyObject] ?? []
            
                let album = getAlbumByKey(key: key, title: title, section: albumSection, imageName: image)
   
                talkList = []
                albumList = []
            
                switch (key) {
                case KEY_ALL_TALKS_SPANISH:
                    AllTalksAlbumSpanish = album
                    talkList = ListAllTalksSpanish
                case KEY_ALL_SPEAKERS_SPANISH:
                    albumList = ListSpeakerAlbumsSpanish
                case KEY_ALL_SERIES_SPANISH:
                    albumList = ListSeriesAlbumsSpanish
                case KEY_RECOMMENDED_TALKS_SPANISH:
                    RecommendedAlbumSpanish = album
              default:
                    albumList = []
                    talkList = []
                }
                album.albumList = albumList
                album.talkList = talkList
            
                RootAlbumSpanish.albumList.append(album)
                KeyToAlbum[key] = album

                // get the optional talk array for this Album
                for jsonTalk in jsonTalkList {
                    
                    let URL = jsonTalk["url"] as? String ?? ""
                    let series = jsonTalk["series"] as? String ?? ""
                    let fileName = URL.components(separatedBy: "/").last ?? ""
                     
                    if let talk = self.FileNameToTalk[fileName] {

                        // if series specified, these always go into RecommendedAlbum
                        var seriesAlbum : AlbumData
                        if !series.isEmpty {
                            let seriesKey = "RECOMMENDED_SPANISH" + series
                            if KeyToAlbum[seriesKey] == nil {
                                
                                seriesAlbum = AlbumData(title: series, key: seriesKey, section: "", imageName: talk.speaker, date : talk.date, albumType: AlbumType.ACTIVE)
                                KeyToAlbum[seriesKey] = seriesAlbum
                                RecommendedAlbumSpanish.albumList.append(seriesAlbum)
                            }
                            seriesAlbum = KeyToAlbum[seriesKey]!
                            seriesAlbum.talkList.append(talk)
                            seriesAlbum.totalSeconds += talk.totalSeconds

                        } else {
                            album.talkList.append(talk)
                        }
                    }
                } // end talk loop
        } // end Album loop
        
   }

    
    func getAlbumByKey(key: String, title: String, section: String, imageName: String) -> AlbumData {
        
        if let album = KeyToAlbum[key] {
            return album
        }
        
        let album =  AlbumData(title: title, key: key, section: section, imageName: imageName, date: "", albumType: AlbumType.ACTIVE)
        KeyToAlbum[key] = album
        
        return album
    }
    
    
    func downloadSimilarityData(talk: TalkData, signalComplete: DispatchSemaphore) {

        
         let config = URLSessionConfiguration.default
         config.requestCachePolicy = .reloadIgnoringLocalCacheData
         config.urlCache = nil
         let session = URLSession.init(configuration: config)

         let similarKeyName = talk.fileName.replacingOccurrences(of: ".mp3", with: "")
         let path = URL_GET_SIMILAR + similarKeyName
        
         let requestURL : URL? = URL(string: path)
         let urlRequest = URLRequest(url : requestURL!)

         var talkList: [TalkData] = []
        print("getsimilar", requestURL)
         let task = session.dataTask(with: urlRequest) {
             (data, response, error) -> Void in

             guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                 signalComplete.signal()

                 return
             }
             
             guard let responseData = data, responseData.count > MIN_EXPECTED_RESPONSE_SIZE else {
                 signalComplete.signal()

                 return
             }
 
                print("getting")
             do {
                 let jsonDict =  try JSONSerialization.jsonObject(with: data!) as! [String: AnyObject]
                 for similarTalk in jsonDict["SIMILAR"] as? [AnyObject] ?? [] {

                     let filename = similarTalk["filename"] as? String ?? ""

                     if let talk = self.FileNameToTalk[filename] {
                         talkList.append(talk)
                     }
                 }
             }
             catch {
                
             }
             
             TheDataModel.SimilarTalksAlbum.talkList = talkList
             print("complete")
             signalComplete.signal()
         }
         task.resume()
     }
    
    
    func checkIfUpdateRequired() -> () {
        
        let requestURL : URL? = URL(string: URL_CONFIGURATION)

        var request = URLRequest(url: requestURL!)
        request.httpMethod = "HEAD"
        print("getConfigLastModifiedDate")
        let task = URLSession.shared.dataTask(with: requestURL!) { (data, response, error) in

            let headers = (response as? HTTPURLResponse)?.allHeaderFields
            var lastModified: String?
            if let headers = headers {
                lastModified = headers["Last-Modified"] as? String
            }

            // cast to Date
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
            if let lastModified = lastModified {
                if let lastModifiedDate = dateFormatter.date(from: lastModified) {
                    
                    print(self.CONFIG_UPDATED_TIME_STAMP, lastModifiedDate)
                    if self.CONFIG_UPDATED_TIME_STAMP == nil {
                        self.CONFIG_UPDATED_TIME_STAMP = lastModifiedDate
                    }
                    if self.CONFIG_UPDATED_TIME_STAMP != lastModifiedDate {
                        self.CONFIG_UPDATED_TIME_STAMP = lastModifiedDate
                        print("CONFIG UPDATE SEEN")
                        ConfigUpdateRequired = true
                    }
                    print(URL_CONFIGURATION, lastModifiedDate)
                }
            }
        }
        task.resume()
    }
    
    func reportLastModified(lastModified: String) {
        
        print(lastModified)
    }

    
    @objc func updateSanghaActivity() {
                
        if isInternetAvailable() == false {
            return
        }
        
        print("updateSanghaActivity")

        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        let session = URLSession.init(configuration: config)
       
        let requestURL : URL? = URL(string: URL_GET_ACTIVITY + "DEVICEID=" + DEVICE_ID)
        let urlRequest = URLRequest(url : requestURL!)
        
        let task = session.dataTask(with: urlRequest) {
            (data, response, error) -> Void in
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                return
            }
            
            // make sure we got data.  including cases where only partial data returned (MIN_EXPECTED_RESPONSE_SIZE is arbitrary)
            guard let responseData = data, responseData.count > MIN_EXPECTED_RESPONSE_SIZE else {
                return
            }
            
            
            do {
                var talkCount = 0
                var talkList: [TalkData] = []

                let json =  try JSONSerialization.jsonObject(with: responseData) as! [String: AnyObject]
                
                // get the community talk history
               for talkJSON in json["sangha_history"] as? [AnyObject] ?? [] {
                   
                   let fileName = talkJSON["filename"] as? String ?? ""
                   let datePlayed = talkJSON["date"] as? String ?? ""
                   var city = talkJSON["city"] as? String ?? ""
                   var country = talkJSON["country"] as? String ?? ""
                   
                   if city.isEmpty {city = " "}
                   if country.isEmpty {country = " "}

                   if let talk = self.FileNameToTalk[fileName] {
                       
                       let talkHistory = talk.copy() as! TalkData
                       talkHistory.datePlayed = datePlayed
                       talkHistory.city  = city
                       talkHistory.country = country

                       talkCount += 1
                       talkList.append(talkHistory)
                       
                       if talkCount >= MAX_TALKHISTORY_COUNT {
                           break
                       }
                   }
                }
                
                GuardUpdateSemaphore.wait()  // obtain critical-section access on talkList
                self.SanghaTalkHistoryAlbum.talkList = talkList
                GuardUpdateSemaphore.signal()  // release critical-section access on talkList

                // get the community share history
                talkCount = 0
                talkList = []
                for talkJSON in json["sangha_shares"] as? [AnyObject] ?? [] {
                    
                    let fileName = talkJSON["filename"] as? String ?? ""
                    let dateShared = talkJSON["date"] as? String ?? ""
                    var city = talkJSON["city"] as? String ?? ""
                    var country = talkJSON["country"] as? String ?? ""
                    
                    if city.isEmpty {city = " "}
                    if country.isEmpty {country = " "}
                    
                    if let talk = self.FileNameToTalk[fileName] {
                        
                        let talkHistory = talk.copy() as! TalkData
                        talkHistory.datePlayed = dateShared
                        talkHistory.city  = city
                        talkHistory.country = country

                        talkList.append(talkHistory)
                        talkCount += 1
                        
                        if talkCount >= MAX_SHAREHISTORY_COUNT {
                            break
                        }
                    }
                 }
                GuardUpdateSemaphore.wait()  // obtain critical-section access on talkList
                self.SanghaShareHistoryAlbum.talkList = talkList
                GuardUpdateSemaphore.signal()  // release critical-section access on talkList
                
                self.checkIfUpdateRequired()
             } catch {
                print("JSON error: \(error.localizedDescription)")
            }
            
            self.computeAlbumStats(album: self.SanghaTalkHistoryAlbum)
            self.computeAlbumStats(album: self.SanghaShareHistoryAlbum)
            
        }
        task.resume()
    }
    
    
    
    func downloadTalk(talk: TalkData, success: @escaping  () -> Void) {

        var requestURL: URL
        var localPathMP3: String
        
        DownloadInProgress = true
        
        // remote source path for file
        if USE_NATIVE_MP3PATHS == true {
            requestURL  = URL(string: URL_MP3_HOST + talk.URL)!
        } else {
            requestURL  = URL(string: URL_MP3_HOST + "/" + talk.fileName)!
        }
        
        // local destination path for file
        localPathMP3 = MP3_DOWNLOADS_PATH + "/" + talk.fileName
                
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        let session = URLSession.init(configuration: config)
        
        let urlRequest = URLRequest(url : requestURL)
        
        let task = session.dataTask(with: urlRequest) {
            (data, response, error) -> Void in
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                
                TheDataModel.unsetTalkAsDownloaded(talk: talk)
                TheDataModel.DownloadInProgress = false
                return
            }
            guard let responseData = data, responseData.count > MIN_EXPECTED_RESPONSE_SIZE else {
                
                TheDataModel.unsetTalkAsDownloaded(talk: talk)
                TheDataModel.DownloadInProgress = false
                return
            }
            
            // if got a good response, store off file locally
            do {
                if let responseData = data {
                    
                    try responseData.write(to: URL(fileURLWithPath: localPathMP3))
                }
            }
            catch  {
                TheDataModel.unsetTalkAsDownloaded(talk: talk)
                TheDataModel.DownloadInProgress = false
                return
            }

            self.reportTalkActivity(type: .DOWNLOAD_TALK, talk: talk)
            TheDataModel.DownloadInProgress = false
            TheDataModel.setTalkAsDownloaded(talk: talk)
            success()
        
            TheDataModel.DownloadInProgress = false
        }
        task.resume()
    }

    
    func reportTalkActivity(type: ACTIVITIES, talk: TalkData) {
       
        var operation : String
        switch (type) {
        
        case ACTIVITIES.SHARE_TALK:
            operation = "SHARETALK"
            
        case ACTIVITIES.PLAY_TALK:
            operation = "PLAYTALK"
            
        case ACTIVITIES.DOWNLOAD_TALK:
            operation = "DOWNLOADTALK"
            
        case ACTIVITIES.READ_TRANSCRIPT:
            operation = "READTRANSCRIPT"
            
        }
        
        let shareType = "NA"    // TBD
        let deviceType = "iphone"
        
        let urlPhrases = talk.URL.components(separatedBy: "/")
        var fileName = (urlPhrases[urlPhrases.endIndex - 1]).trimmingCharacters(in: .whitespacesAndNewlines)
        fileName = fileName.trimmingCharacters(in: .whitespacesAndNewlines)

        let parameters = "DEVICETYPE=\(deviceType)&DEVICEID=\(DEVICE_ID)&OPERATION=\(operation)&SHARETYPE=\(shareType)&FILENAME=\(fileName)"

        let url = URL(string: URL_REPORT_ACTIVITY)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = parameters.data(using: String.Encoding.utf8);

        let task = URLSession.shared.dataTask(with: request) { data, response, error in }
        
        task.resume()

    }
    
    
    func computeAlbumStats(album: AlbumData) {
        
        var totalTalks = 0
        
        for _ in album.talkList {
            totalTalks += 1
        }

        for childAlbum in album.albumList {
             for _ in childAlbum.talkList {
                totalTalks += 1
            }
        }
        
        // album.totalTalks is an observed published var
        // therefore need to update it via a dispatch to the main thread
        DispatchQueue.main.async {
            
            album.totalTalks = totalTalks
            
        }
    }
    
        
    //
    // talk and album functions
    //
    func toggleTalkAsFavorite(talk: TalkData) -> Bool {

        if TheDataModel.isFavoriteTalk(talk: talk) {
            TheDataModel.UserFavorites[talk.fileName] = nil
            if let index = TheDataModel.UserFavoritesAlbum.talkList.firstIndex(of: talk) {
                TheDataModel.UserFavoritesAlbum.talkList.remove(at: index)
            }
        } else {
            TheDataModel.UserFavorites[talk.fileName] = UserFavoriteData(fileName: talk.fileName)
            TheDataModel.UserFavoritesAlbum.talkList.insert(talk, at: 0)
        }

        TheDataModel.saveUserFavoritesData()
        TheDataModel.computeAlbumStats(album: TheDataModel.UserFavoritesAlbum)
        
        let isFavorite = TheDataModel.UserFavorites[talk.fileName] != nil
        return isFavorite
    }
    
    
    func isFavoriteTalk(talk: TalkData) -> Bool {
        
        return TheDataModel.UserFavorites[talk.fileName] != nil
    }
    
 
    
    func isDownloadInProgress(talk: TalkData) -> Bool {
        
        var downloadInProgress = false
        if let userDownload = TheDataModel.UserDownloads[talk.fileName]  {
            downloadInProgress = (userDownload.DownloadCompleted == "NO")
        }
        return downloadInProgress
    }

    
    func setTalkAsDownloaded(talk: TalkData) {
        
        TheDataModel.UserDownloadAlbum.talkList.insert(talk, at: 0)
        TheDataModel.UserDownloads[talk.fileName] = UserDownloadData(fileName: talk.fileName, downloadCompleted: "YES")
        TheDataModel.saveUserDownloadData()

        TheDataModel.computeAlbumStats(album: TheDataModel.UserDownloadAlbum)

    }
    
    
    func unsetTalkAsDownloaded(talk: TalkData) {
        
        if let index = TheDataModel.UserDownloadAlbum.talkList.firstIndex(of: talk) {
            TheDataModel.UserDownloadAlbum.talkList.remove(at: index)
        }
        
        if let userDownload = TheDataModel.UserDownloads[talk.fileName] {
            if userDownload.DownloadCompleted == "NO" {
                TheDataModel.DownloadInProgress = false
            }
        }
        TheDataModel.UserDownloads[talk.fileName] = nil
        let localPathMP3 = MP3_DOWNLOADS_PATH + "/" + talk.fileName
        do {
            try FileManager.default.removeItem(atPath: localPathMP3)
        }
        catch let error as NSError {
            errorLog(error: error)
        }
        
        TheDataModel.saveUserDownloadData()
        TheDataModel.computeAlbumStats(album: TheDataModel.UserDownloadAlbum)
    }
    
    
    func hasBeenDownloaded(talk: TalkData) -> Bool {

        return TheDataModel.UserDownloads[talk.fileName] != nil
    }
    
    
    func addNoteToTalk(talk: TalkData, noteText: String) {

         //
         // if there is a note text for this talk fileName, then save it in the note dictionary
         // otherwise clear this note dictionary entry
         let talkFileName = talk.fileName

         if (noteText.count > 0) && noteText.rangeOfCharacter(from: CharacterSet.alphanumerics) != nil {
             TheDataModel.UserNotes[talkFileName] = UserNoteData(notes: noteText)
             
             if TheDataModel.UserNoteAlbum.talkList.contains(talk) == false {
                 TheDataModel.UserNoteAlbum.talkList.append(talk)
             }
         } else {
             TheDataModel.UserNotes[talkFileName] = nil
             if let index = TheDataModel.UserNoteAlbum.talkList.firstIndex(of: talk) {
                 TheDataModel.UserNoteAlbum.talkList.remove(at: index)
             }

         }
         
         // save the data, recompute stats, reload root view to display updated stats
         TheDataModel.saveUserNoteData()
         TheDataModel.computeAlbumStats(album: TheDataModel.UserNoteAlbum)
     }
     
     
    func getNoteForTalk(talk: TalkData) -> String {

         var noteText = ""

         if let userNoteData = TheDataModel.UserNotes[talk.fileName]   {
             noteText = userNoteData.Notes
         }
         return noteText
     }


    func isNotatedTalk(talk: TalkData) -> Bool {
         
         if let _ = TheDataModel.UserNotes[talk.fileName] {
             return true
         }
         return false
     }
     
     
    func hasTalkBeenPlayed(talk: TalkData) -> Bool {
     
         return TheDataModel.PlayedTalks[talk.fileName] != nil
     }

     
     func isMostRecentTalk(talk: TalkData) -> Bool {
     
         
         if let lastTalk = TheDataModel.UserTalkHistoryAlbum.talkList.first {
             return talk.fileName == lastTalk.fileName
         }
         return false
     }
      
      
    //
    // invoked in background by TalkPlayerView
    //
     func addToTalkHistory(talk: TalkData) {
                  
         self.PlayedTalks[talk.fileName] = true

         let date = Date()
         let formatter = DateFormatter()
         formatter.dateFormat = "yyyy.MM.dd"
         let datePlayed = formatter.string(from: date)
         formatter.dateFormat = "HH:mm:ss"
         let timePlayed = formatter.string(from: date)

         talk.datePlayed = datePlayed
         talk.timePlayed = timePlayed
         
         UserTalkHistoryAlbum.talkList.insert(talk, at: 0)
         
         let excessTalkCount = UserTalkHistoryAlbum.talkList.count - MAX_HISTORY_COUNT
         if excessTalkCount > 0 {
             for _ in 1 ... excessTalkCount {
                 UserTalkHistoryAlbum.talkList.removeLast()
             }
         }

         savePlayedTalksData()
         saveTalkHistoryData()
         computeAlbumStats(album: self.UserTalkHistoryAlbum)
       }
     
    
    func addToShareHistory(talk: TalkData) {
        
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        let datePlayed = formatter.string(from: date)
        formatter.dateFormat = "HH:mm:ss"
        let timePlayed = formatter.string(from: date)
        
        PlayedTalks[talk.fileName] = true
        talk.datePlayed = datePlayed
        talk.timePlayed = timePlayed
       
        UserShareHistoryAlbum.talkList.insert(talk, at: 0)

        let excessTalkCount = UserShareHistoryAlbum.talkList.count - MAX_HISTORY_COUNT
        if excessTalkCount > 0 {
            for _ in 1 ... excessTalkCount {
                UserShareHistoryAlbum.talkList.removeLast()
            }
        }
        
        // save the data, recompute stats, reload root view to display updated stats
        saveShareHistoryData()
        computeAlbumStats(album: UserShareHistoryAlbum)

    }
     
    
    
    //
    // User Album functions
    //
    func saveCustomUserAlbums() {
    
        let image = UIImage(named: "notebar")
        UserAlbums = []
        for album in self.CustomUserAlbums.albumList {
            
            let userAlbum = UserAlbumData(title: album.title, image: image!, content: "", talkFileNames: [])
            
            var talkFileNameList: [String] = []
            for talk in album.talkList {
                
                if let _ = getTalkForName(name: talk.fileName) {
                    talkFileNameList.append(talk.fileName)
                }
            }
            userAlbum.TalkFileNames = talkFileNameList
            UserAlbums.append(userAlbum)
        }
        saveUserAlbumData()
        computeAlbumStats(album: CustomUserAlbums)
        
    }
    
    
    func getUserAlbums() -> [UserAlbumData] {
        
        return UserAlbums
    }
    
    
    func updateUserAlbum(updatedAlbum: UserAlbumData) {
        
        for (index, album) in UserAlbums.enumerated() {
            
            if album.Content == updatedAlbum.Content {
                
                UserAlbums[index] = updatedAlbum
                break
            }
        }
    }
    
    
    func addUserAlbum(album: AlbumData) {
        
        let image = UIImage(named: "tri_right_x")
        let userAlbum = UserAlbumData(title: album.title, image: image!, content: "", talkFileNames: [])
        UserAlbums.append(userAlbum)
        
        CustomUserAlbums.albumList.append(album)
        computeAlbumStats(album: CustomUserAlbums)
        
        saveUserAlbumData()
    }
    
    
    func removeUserAlbum(at: Int) {
        
        UserAlbums.remove(at: at)
        
        saveUserAlbumData()
        //computeUserAlbumStats()
    }
    
    func removeUserAlbum(userAlbum: UserAlbumData) {
        
        for (index, album) in UserAlbums.enumerated() {
            
            if album.Content == userAlbum.Content {
                
                UserAlbums.remove(at: index)
                break
            }
        }
    }
    
    
    func getUserAlbumTalks(userAlbum: UserAlbumData) -> [TalkData]{
        
        var userAlbumTalks = [TalkData] ()
        
        for talkFileName in userAlbum.TalkFileNames {
            if let talk = getTalkForName(name: talkFileName) {
                userAlbumTalks.append(talk)
            }
        }
        
        return userAlbumTalks
    }
    
    
    func saveUserAlbumTalks(userAlbum: UserAlbumData, talks: [TalkData]) {
        
        var userAlbumIndex = 0
        for album in UserAlbums {
            
            if album.Content == userAlbum.Content {
                break
            }
            userAlbumIndex += 1
        }
        
        if userAlbumIndex == UserAlbums.count {
            return
        }
        
        var talkFileNames = [String]()
        for talk in talks {
            talkFileNames.append(talk.fileName)
        }
        
        // save the resulting array into the userlist and then persist into storage
        UserAlbums[userAlbumIndex].TalkFileNames = talkFileNames
        
        saveUserAlbumData()
        //computeUserAlbumStats()
    }
    
    
    func randomKey() -> String {
        
        let KEY_LENGTH = 10
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        
        return String((0...KEY_LENGTH ).map{ _ in letters.randomElement()! })
    }
    
    
    
    
    //
    // Persistent Data Functions
    //
    func saveTalkHistoryData() {
        
        var talkHistoryList: [TalkHistoryData] = []
    
        for talk in UserTalkHistoryAlbum.talkList {
            
            let talkHistory = TalkHistoryData(fileName: talk.fileName, datePlayed: talk.datePlayed, timePlayed: talk.timePlayed, cityPlayed: "", statePlayed: "", countryPlayed: "")
            talkHistoryList.append(talkHistory)
        }

        do {
            if let data = try? NSKeyedArchiver.archivedData(withRootObject: talkHistoryList, requiringSecureCoding: false) {
                try data.write(to: TalkHistoryData.ArchiveTalkHistoryURL)
            }
        }
        catch let error as NSError {
            errorLog(error: error)
        }
    }

    
    func loadTalkHistoryData() -> [TalkData]  {
        
        var talkHistoryList: [TalkHistoryData] = []
        var talkList: [TalkData] = []

        
        if let data = try? Data(contentsOf: TalkHistoryData.ArchiveTalkHistoryURL) {
            if let talkHistory = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [TalkHistoryData] {
                talkHistoryList =  talkHistory
            }
        }
        
        for talkHistory in talkHistoryList {
            if let talk = FileNameToTalk[talkHistory.FileName] {
                talkList.append(talk)
            }
        }

        return talkList
    }

    
    func saveShareHistoryData() {
        
        var talkHistoryList: [TalkHistoryData] = []
        
        for talk in UserShareHistoryAlbum.talkList {
            
            let talkHistory = TalkHistoryData(fileName: talk.fileName, datePlayed: talk.datePlayed, timePlayed: talk.timePlayed, cityPlayed: "", statePlayed: "", countryPlayed: "")
            talkHistoryList.append(talkHistory)
        }

        do {
            if let data = try? NSKeyedArchiver.archivedData(withRootObject: talkHistoryList, requiringSecureCoding: false) {
                try data.write(to: TalkHistoryData.ArchiveShareHistoryURL)
            }
        }
        catch let error as NSError {
            errorLog(error: error)
        }
    }

    
    func loadShareHistoryData() -> [TalkData]  {
        
        var talkHistoryList: [TalkHistoryData] = []
        var talkList: [TalkData] = []

        if let data = try? Data(contentsOf: TalkHistoryData.ArchiveShareHistoryURL) {
            if let talkHistory = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [TalkHistoryData] {

                talkHistoryList =  talkHistory
            }
        }
        
        for talkHistory in talkHistoryList {
            if let talk = FileNameToTalk[talkHistory.FileName] {
                talkList.append(talk)
            }
      }
        return talkList
    }
        
    
    func savePlayedTalksData() {
         
        do {
            if let data = try? NSKeyedArchiver.archivedData(withRootObject: PlayedTalks, requiringSecureCoding: false) {
                try data.write(to: PlayedTalks_ArchiveURL)
            }
        } catch let error as NSError {
            errorLog(error: error)
        }
     }

    
    func loadPlayedTalksData() -> [String: Bool]  {
        
        if let data = try? Data(contentsOf: PlayedTalks_ArchiveURL) {
            if let playedTalks = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [String: Bool] {
                return playedTalks
            } else {
                return [String: Bool] ()
            }
        }
        return [String: Bool] ()
    }


    func saveUserAlbumData() {
        
        do {
            if let data = try? NSKeyedArchiver.archivedData(withRootObject: TheDataModel.UserAlbums, requiringSecureCoding: false) {
                try data.write(to: UserAlbumData.ArchiveURL)
            }
        }
        catch let error as NSError {
            errorLog(error: error)
        }
    }

    
    func loadUserAlbumData() -> [UserAlbumData]  {
        
        if let data = try? Data(contentsOf: UserAlbumData.ArchiveURL) {
            if let userAlbumData = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [UserAlbumData] {
                return userAlbumData
            } else {
                return [UserAlbumData] ()
            }
        }
        return [UserAlbumData] ()
    }

    
    func saveUserNoteData() {
        
        do {
            if let data = try? NSKeyedArchiver.archivedData(withRootObject: TheDataModel.UserNotes, requiringSecureCoding: false) {
                try data.write(to: UserNoteData.ArchiveURL)
            }
        }
        catch let error as NSError {
            errorLog(error: error)
        }
    }

    
    func loadUserNoteData() -> [String: UserNoteData]  {
        
        if let data = try? Data(contentsOf:  UserNoteData.ArchiveURL) {
            if let userNotes = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [String: UserNoteData] {
                return userNotes
            } else {
                return [String: UserNoteData] ()
            }
        }
        return [String: UserNoteData] ()
    }
    
    
    func saveUserFavoritesData() {
        
        do {
            if let data = try? NSKeyedArchiver.archivedData(withRootObject: TheDataModel.UserFavorites, requiringSecureCoding: false) {
                try data.write(to: UserFavoriteData.ArchiveURL)
            }
        }
        catch let error as NSError {
            errorLog(error: error)
        }
    }


    func loadUserFavoriteData() -> [String: UserFavoriteData]  {
        
        if let data = try? Data(contentsOf:  UserFavoriteData.ArchiveURL) {
            if let userFavorites = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [String: UserFavoriteData] {
                return userFavorites
            } else {
                return [String: UserFavoriteData] ()
            }
        }
        return [String: UserFavoriteData] ()
    }
    
    
    func saveUserDownloadData() {
        
        do {
            if let data = try? NSKeyedArchiver.archivedData(withRootObject: TheDataModel.UserDownloads, requiringSecureCoding: false) {
                try data.write(to: UserDownloadData.ArchiveURL)
            }
        }
        catch let error as NSError {
            errorLog(error: error)
        }
    }


    func loadUserDownloadData() -> [String: UserDownloadData]  {
        
        if let data = try? Data(contentsOf: UserDownloadData.ArchiveURL) {
            if let userDownloads = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [String: UserDownloadData] {
                return userDownloads
            } else {
                return [String: UserDownloadData] ()
            }
        }
        return [String: UserDownloadData] ()
    }
       
    
    //
    // Support Functions
    //
    func isInternetAvailable() -> Bool
    {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        
        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
            return false
        }
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        return (isReachable && !needsConnection)
    }
    
        
    // ensure that no download records get persisted that are incomplete in any way
    // I do this because asynchronous downloads might not complete, leaving systen in inconsistent state
    // this boot-time check ensures data remains stable, hopefully
    func validateUserDownloadData()  {
        
        // Prune:
        // 1) Any entry that isn't marked complete
        // 2) Any entry that doesn't have a file associated with it
        var badDownloads: [UserDownloadData] = []
        for ( _ , userDownload) in UserDownloads {
            
            if userDownload.DownloadCompleted != "YES" {
                badDownloads.append(userDownload)
            }
            
            let localPathMP3 = MP3_DOWNLOADS_PATH + "/" + userDownload.FileName
            if FileManager.default.fileExists(atPath: localPathMP3) == false {
                badDownloads.append(userDownload)
 
            }
        }
        
        for userDownload in badDownloads {
            
            UserDownloads[userDownload.FileName] = nil
            let localPathMP3 = MP3_DOWNLOADS_PATH + "/" + userDownload.FileName

            do {
                try FileManager.default.removeItem(atPath: localPathMP3)
            }
            catch let error as NSError {
                errorLog(error: error)
            }
        }
        
        // now remove orphan files. these are mp3s that for whatever reason aren't marked as downloaded
        do {
            // Get the directory contents urls (including subfolders urls)
            let directoryContents = try FileManager.default.contentsOfDirectory(at: URL(string: MP3_DOWNLOADS_PATH)!, includingPropertiesForKeys: nil, options: [])
            //let mp3FileURLS = directoryContents.filter{ $0.pathExtension == "mp3" }
            for mp3FileURL in directoryContents {
                
                if let fileName = mp3FileURL.path.components(separatedBy: "/").last {
                    if UserDownloads[fileName] == nil {     // true if the mp3 is an orphan

                        do {
                            try FileManager.default.removeItem(atPath: mp3FileURL.path)
                        }
                        catch let error as NSError {
                            errorLog(error: error)
                        }

                    }
                }
            }
            
        } catch {
        }
        saveUserDownloadData()
    }
    
    
    func clearIncompleteDownloads()  {
        
        var incompleteDownloads: [UserDownloadData] = []
        for ( _ , userDownload) in UserDownloads {
            
            if userDownload.DownloadCompleted != "YES" {
                incompleteDownloads.append(userDownload)
            }
        }
        
        for userDownload in incompleteDownloads {
            
            UserDownloads[userDownload.FileName] = nil
            let localPathMP3 = MP3_DOWNLOADS_PATH + "/" + userDownload.FileName
            do {
                try FileManager.default.removeItem(atPath: localPathMP3)
            }
            catch let error as NSError {
                errorLog(error: error)
            }
        }
    }

    
    func deviceRemainingFreeSpaceInBytes() -> Int64? {
        let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last!
        guard
            let systemAttributes = try? FileManager.default.attributesOfFileSystem(forPath: documentDirectory),
            let freeSize = systemAttributes[.systemFreeSize] as? NSNumber
            else {
                // something failed
                return nil
        }
        return freeSize.int64Value
    }
    
   
    func isFullURL(url: String) -> Bool {
        
        if url.lowercased().range(of:"http:") != nil {
            return true
        }
        else if url.lowercased().range(of:"https:") != nil {
            return true
        } else {
            return false
        }
        
    }
    

    func remoteURLExists(url: URL, completion:@escaping (Bool, URL)->()){
        
        var request: URLRequest = URLRequest(url: url as URL)
        request.httpMethod = "HEAD"
        
        var exists: Bool = true
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            
            if let httpResponse = response as? HTTPURLResponse {
                
                if httpResponse.statusCode == 200 {
                    exists =  true
                } else {
                    exists  = false
                }
            }
            
            DispatchQueue.main.async {
                completion(exists, url)
            }
        }.resume()
    }
    
    
    func sendRequest (request: URLRequest,completion:@escaping (URLResponse?)->()){
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error != nil{
                return completion(response)
            }else{
                return completion(nil)
            }
            }.resume()
    }
    

    func getTalkForName(name: String) -> TalkData? {
        
        return FileNameToTalk[name]
    }

    
    func errorLog(error: NSError) {
        
        print("ERROR: ", error)
    }
    
    
    /*
    func startBackgroundTimers() {
        
        Timer.scheduledTimer(timeInterval: TimeInterval(UPDATE_SANGHA_INTERVAL), target: self, selector: #selector(updateSanghaActivity), userInfo: nil, repeats: true)
    }
     */
     

    /*
    func getConfigLastModifiedDate(completion: @escaping (_ modificatinDate: String) -> ()) {
        
        let requestURL : URL? = URL(string: URL_CONFIGURATION)

        var request = URLRequest(url: requestURL!)
        request.httpMethod = "HEAD"
        print("getConfigLastModifiedDate")
        let task = URLSession.shared.dataTask(with: requestURL!) { (data, response, error) in

            let headers = (response as? HTTPURLResponse)?.allHeaderFields
            var lastModified: String?
            if let headers = headers {
                lastModified = headers["Last-Modified"] as? String
            }

            // cast to Date
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
            if let lastModified = lastModified {
                if let lastModifiedDate = dateFormatter.date(from: lastModified) {
                    
                    if self.CONFIG_UPDATED_TIME_STAMP.isEmpty {
                        CONFIG_UPDATED_TIME_STAMP = lastModifiedDate as
                    } else {
                        if CONFIG_UPDATED_TIME_STAMP != lastModifiedDate as? String {
                            
                        }
                    }
                    print(URL_CONFIGURATION, lastModifiedDate)
                }
            }
            completion(lastModified!)

        }
        task.resume()
     */

    
}
    

