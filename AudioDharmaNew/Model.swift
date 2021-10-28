//
//  Model.swift
//
//  The data model for the app.  Here are all the functions to download and configure the app,
//  as well as all functions necessary for updating app state.
//
//  Created by Christopher on 6/22/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//            self.UserFavorites = TheDataModel.loadUserFavoriteData()

import UIKit
import Foundation
import SystemConfiguration
import os.log
import ZipArchive


let TheDataModel = Model()  // TheDataModel is the model for all views elsewhere in the program

// Web Config Entry Points
let HostAccessPoints: [String] = [
    "http://www.virtualdharma.org",
    "http://www.audiodharma.org"
]
var HostAccessPoint: String = HostAccessPoints[0]   // the one we're currently using

//
// Paths for Services
//
let CONFIG_JSON_NAME = "CONFIG00.JSON"
let CONFIG_ZIP_NAME = "CONFIG00.ZIP"
var MP3_DOWNLOADS_PATH = ""      // where MP3s are downloaded.  this is set up in loadData()
let CONFIG_ACCESS_PATH = "/AudioDharmaAppBackend/Config/" + CONFIG_ZIP_NAME    // remote web path to config
let CONFIG_REPORT_ACTIVITY_PATH = "/AudioDharmaAppBackend/Access/reportactivity.php"     // where to report user activity (shares, listens)
let CONFIG_GET_ACTIVITY_PATH = "/AudioDharmaAppBackend/Access/XGETACTIVITY.php?"           // where to get sangha activity (shares, listens)
let CONFIG_GET_SIMILAR_TALKS = "/AudioDharmaAppBackend/Access/XGETSIMILARTALKS.php?KEY="           // where to get similar talks\
let DEFAULT_MP3_PATH = "http://www.audiodharma.org"     // where to get talks
let DEFAULT_DONATE_PATH = "http://audiodharma.org/donate/"       // where to donate

var HTTPResultCode: Int = 0     // global status of web access
let MIN_EXPECTED_RESPONSE_SIZE = 300   // to filter for bogus redirect page responses

var USE_NATIVE_MP3PATHS = true    // true = mp3s are in their native paths in audiodharma, false =  mp3s are in one flat directory


// Default Web Access Points
var URL_CONFIGURATION = HostAccessPoint + CONFIG_ACCESS_PATH
var URL_REPORT_ACTIVITY = HostAccessPoint + CONFIG_REPORT_ACTIVITY_PATH
var URL_GET_ACTIVITY = HostAccessPoint + CONFIG_GET_ACTIVITY_PATH
var URL_GET_SIMILAR = HostAccessPoint + CONFIG_GET_SIMILAR_TALKS
var URL_MP3_HOST = DEFAULT_MP3_PATH
var URL_DONATE = DEFAULT_DONATE_PATH


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


let MP3_BYTES_PER_SECOND = 20000    // rough (high) estimate for how many bytes per second of MP3.  Used to estimate size of download files
let REPORT_TALK_THRESHOLD : Double = 90      // how many seconds into a talk before reporting that talk that has been officially played
let SECONDS_TO_NEXT_TALK : Double = 2   // when playing an album, this is the interval between talks
var MAX_TALKHISTORY_COUNT = 3000     // maximum number of played talks showed in sangha history. over-rideable by config
var MAX_SHAREHISTORY_COUNT = 1000     // maximum number of shared talks showed in sangha history  over-rideable by config
var MAX_HISTORY_COUNT = 100         // maximum number of user (not sangha) talk history displayed
var UPDATE_SANGHA_INTERVAL = 2 * 60    // amount of time (in seconds) between each poll of the cloud for updated sangha info
var UPDATE_MODEL_INTERVAL =  120 * 60   // amount of time (in seconds) between each poll of the cloud for updated model info

//var UPDATE_MODEL_INTERVAL : TimeInterval = 120 * 60    // interval to next update model
//var LAST_MODEL_UPDATE = NSDate().timeIntervalSince1970  // when we last updated model

let KEYS_TO_ALBUMS = [KEY_ALBUMROOT, KEY_RECOMMENDED_TALKS, KEY_ALL_SERIES, KEY_ALL_SPEAKERS]
let KEYS_TO_USER_ALBUMS = [KEY_USER_ALBUMS]

let DEVICE_ID = UIDevice.current.identifierForVendor!.uuidString

enum ACTIVITIES {          // all possible activities that are reported back to cloud
    case SHARE_TALK
    case PLAY_TALK
}
enum INIT_CODES {          // all possible startup results
    case SUCCESS
    case NO_CONNECTION
}

let ModelReadySemaphore = DispatchSemaphore(value: 0)  // signals when data loading is finished.
let ModelUpdatedSemaphore = DispatchSemaphore(value: 1)  // signals when data updating is finished
let GuardCommunityAlbumSemaphore = DispatchSemaphore(value: 1) // guards album.talklist a community album is being updated

let UpdateInProgress = false

class Model {
    
    var KeyToAlbum : [String: AlbumData] = [:]  //  dictionary keyed by "key" which is a albumd id, value is an album
    var FileNameToTalk: [String: TalkData]   = [String: TalkData] ()  // dictionary keyed by talk filename, value is the talk data (used by userList code to lazily bind)
    
    var RootAlbum: AlbumData = AlbumData(title: "ROOT", key: KEY_ALBUMROOT, section: "", imageName: "albumdefault", date: "", albumType: AlbumType.ACTIVE)
    var AllTalksAlbum =  AlbumData(title: "ALL Talks", key: KEY_USER_ALBUMS, section: "", imageName: "albumdefault", date: "", albumType: AlbumType.ACTIVE)

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

    var UserTalkHistoryList: [TalkHistoryData] = []

    var ListAllTalks: [TalkData] = []
    var ListSpeakerAlbums: [AlbumData] = []
    var ListSeriesAlbums: [AlbumData] = []
    var ListRecommenedAlbums: [AlbumData] = []
    var ListFavoriteTalls : [TalkData] = []

    var DownloadInProgress = false

    var UpdatedTalksJSON: [String: AnyObject] = [String: AnyObject] ()

    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!

    var UserAlbums: [UserAlbumData] = []      // all the custom user albums defined by this user.
    var UserNotes: [String: UserNoteData] = [:]      // all the  user notes defined by this user, indexed by fileName
    var UserFavorites: [String: UserFavoriteData] = [:]      // all the favorites defined by this user, indexed by fileName
    var UserDownloads: [String: UserDownloadData] = [:]      // all the downloads defined by this user, indexed by fileName
    var PlayedTalks: [String: Bool]   = [:]  // all the talks that have been played by this user, indexed by fileName
    let PlayedTalks_ArchiveURL = DocumentsDirectory.appendingPathComponent("PlayedTalks")
    
    var SystemIsConfigured = false  // set to true if a config file was found and configured
    
    
    // MARK:  Initialization and Configuration
        
    func initialize() {
        
        FileNameToTalk = [String: TalkData] ()
        ListAllTalks = []
        
        HTTPResultCode = 0
        URL_CONFIGURATION = HostAccessPoint + CONFIG_ACCESS_PATH
        URL_REPORT_ACTIVITY = HostAccessPoint + CONFIG_REPORT_ACTIVITY_PATH
        URL_GET_ACTIVITY = HostAccessPoint + CONFIG_GET_ACTIVITY_PATH
        
        
        // build the data directories on device, if needed
        let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        MP3_DOWNLOADS_PATH = documentPath + "/DOWNLOADS"
        
        do {
            try FileManager.default.createDirectory(atPath: MP3_DOWNLOADS_PATH, withIntermediateDirectories: false, attributes: nil)
        } catch let error as NSError {
            errorLog(error: error)
        }

        PlayedTalks = loadPlayedTalksData()
        UserDownloads = loadUserDownloadData()
        validateUserDownloadData()
    }
    
    
    func startBackgroundTimers() {
        
        // CJM DEV
        Timer.scheduledTimer(timeInterval: TimeInterval(UPDATE_SANGHA_INTERVAL), target: self, selector: #selector(updateSanghaActivity), userInfo: nil, repeats: true)
        Timer.scheduledTimer(timeInterval: TimeInterval(UPDATE_MODEL_INTERVAL), target: self, selector: #selector(updateDataModel), userInfo: nil, repeats: true)

    }
    

    
    @objc func updateSanghaActivity() {
    
        if isInternetAvailable() == false {
            return
        }

        downloadSanghaActivity()
    }
    
    
    @objc func updateDataModel() {
    
        if isInternetAvailable() == false {
            return
        }
        print("updateDataModel")

        downloadAndConfigure(startingApp: false)
    }

 
    func currentTalkIsEmpty() -> Bool {
        
        return CurrentTalk.TotalSeconds == 0 || CurrentTalk.FileName.isEmpty
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
                            print("LOADING NEW CURRENT ALBUM: ", album.Title)

                            CurrentAlbum = album
                        }
                    }
                    print("LOADING NEW CURRENT TALK: ", CurrentTalk.Title)
                }
            }
        }
    }
    
    
    func saveLastAlbumTalkState(album: AlbumData, talk: TalkData, elapsedTime: Double) {
        
        print("saveLastTalkState", talk.Title, album.Key)

        CurrentTalk = talk
        CurrentAlbum = album
        CurrentTalkElapsedTime = elapsedTime
        UserDefaults.standard.set(CurrentTalkElapsedTime, forKey: "CurrentTalkTime")
        UserDefaults.standard.set(CurrentTalk.FileName, forKey: "TalkName")
        UserDefaults.standard.set(CurrentAlbum.Key, forKey: "AlbumKey")
    }
 
    
    func downloadAndConfigure(startingApp: Bool)  {
        
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
            let configJSONPath = documentPath + "/" + CONFIG_JSON_NAME

            var httpResponse: HTTPURLResponse
            if let valid_reponse = response {
                httpResponse = valid_reponse as! HTTPURLResponse
                HTTPResultCode = httpResponse.statusCode
            } else {
                HTTPResultCode = 404
            }

            if let responseData = data {
                if responseData.count < MIN_EXPECTED_RESPONSE_SIZE {
                    HTTPResultCode = 404
                }
            }
            else {
                HTTPResultCode = 404
            }
            
            // if got a good response, store off the zip file locally
            // if we DIDN'T get a good response, we will try to unzip the previously loaded config
            if HTTPResultCode == 200 {
            
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
            }

            if SSZipArchive.unzipFile(atPath: configZipPath, toDestination: documentPath) != true {
                
                HTTPResultCode = 404
                ModelReadySemaphore.signal()
                return
            }

            // get our unzipped json from the local storage and process it
            var jsonData: Data!
            do {
                jsonData = try Data(contentsOf: URL(fileURLWithPath: configJSONPath))
            }

            catch let error as NSError {
                
                HTTPResultCode = 404
                self.errorLog(error: error)
                ModelReadySemaphore.signal()
                return
            }
                        
            // BEGIN CRITICAL SECTION  CJM DEV

            do {
                let jsonDict =  try JSONSerialization.jsonObject(with: jsonData) as! [String: AnyObject]
                self.loadConfig(jsonDict: jsonDict)
                
                if startingApp == true {
                    self.loadTalks(jsonDict: jsonDict)
                    self.loadAlbums(jsonDict: jsonDict)
                    
                }
                else {
                    ModelUpdatedSemaphore.wait()
                    self.updateWithNewTalks(jsonDict: jsonDict)
                    ModelUpdatedSemaphore.signal()

                }
                for album in self.RootAlbum.albumList {
                    self.computeAlbumStats(album: album)
                }
                for album in self.CustomUserAlbums.albumList {
                    self.computeAlbumStats(album: album)
                }
            }
            catch {
            }
            
            self.SystemIsConfigured = true
            
            // END CRITICAL SECTION
            ModelReadySemaphore.signal()
 
        }
        task.resume()
    }
    
    
    func loadConfig(jsonDict: [String: AnyObject]) {
        
        if let config = jsonDict["config"] {

            URL_MP3_HOST = config["URL_MP3_HOST"] as? String ?? URL_MP3_HOST
            USE_NATIVE_MP3PATHS = config["USE_NATIVE_MP3PATHS"] as? Bool ?? USE_NATIVE_MP3PATHS
            URL_REPORT_ACTIVITY = config["URL_REPORT_ACTIVITY"] as? String ?? URL_REPORT_ACTIVITY
            URL_GET_ACTIVITY = config["URL_GET_ACTIVITY"] as? String ?? URL_GET_ACTIVITY

            URL_DONATE = config["URL_DONATE"] as? String ?? URL_DONATE
        
            MAX_TALKHISTORY_COUNT = config["MAX_TALKHISTORY_COUNT"] as? Int ?? MAX_TALKHISTORY_COUNT
            MAX_SHAREHISTORY_COUNT = config["MAX_SHAREHISTORY_COUNT"] as? Int ?? MAX_SHAREHISTORY_COUNT
            UPDATE_SANGHA_INTERVAL = config["UPDATE_SANGHA_INTERVAL"] as? Int ?? UPDATE_SANGHA_INTERVAL
        }
    }
    
    
    func loadTalks(jsonDict: [String: AnyObject]) {
        
        var talkCount = 0
        var totalSeconds = 0
        
        // get all talks
        for jsonTalk in jsonDict["talks"] as? [AnyObject] ?? [] {
                
                let series = jsonTalk["series"] as? String ?? ""
                let title = jsonTalk["title"] as? String ?? ""
                let URL = (jsonTalk["url"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                let speaker = jsonTalk["speaker"] as? String ?? ""
                var date = jsonTalk["date"] as? String ?? ""
                date = date.replacingOccurrences(of: "-", with: ".")
                let duration = jsonTalk["duration"] as? String ?? ""
                let pdf = jsonTalk["pdf"] as? String ?? ""
                
                let terms = URL.components(separatedBy: "/")
                let fileName = terms.last ?? ""
                
                let seconds = duration.convertDurationToSeconds()
                totalSeconds += seconds
            
                let talk =  TalkData(title: title,
                                         url: URL,
                                         fileName: fileName,
                                         date: date,
                                         speaker: speaker,
                                         totalSeconds: seconds,
                                         pdf: pdf)
                    
           
                if talk.hasTranscript() {
                    //talk.Title = talk.Title + " [transcript]"
                    TranscriptsAlbum.talkList.append(talk)
                }
            
                self.FileNameToTalk[fileName] = talk
                
                // add this talk to  list of all talks
                self.ListAllTalks.append(talk)
            
                var speakerAlbum : AlbumData
                var seriesAlbum : AlbumData

                if self.KeyToAlbum[speaker] == nil {
                    speakerAlbum = AlbumData(title: speaker, key: speaker, section: "", imageName: speaker, date: date, albumType: AlbumType.ACTIVE)
                    self.KeyToAlbum[speaker] = speakerAlbum
                    ListSpeakerAlbums.append(speakerAlbum)
                }
                speakerAlbum = self.KeyToAlbum[speaker]!
                speakerAlbum.talkList.append(talk)
                speakerAlbum.totalTalks += 1
                speakerAlbum.totalSeconds += seconds

                // if a series is specified, create an album if one doesn't exist.  add talk to album
                if !series.isEmpty {
                    
                    let seriesKey = "SERIES" + series
                    if self.KeyToAlbum[seriesKey] == nil {
                        seriesAlbum = AlbumData(title: series, key: seriesKey, section: "", imageName: speaker, date : date, albumType: AlbumType.ACTIVE)
                        self.KeyToAlbum[seriesKey] = seriesAlbum
                        ListSeriesAlbums.append(seriesAlbum)
                    }
                    seriesAlbum = self.KeyToAlbum[seriesKey]!
                    seriesAlbum.talkList.append(talk)
                    seriesAlbum.totalTalks += 1
                    seriesAlbum.totalSeconds += seconds
                 }
                
                talkCount += 1
        }
        

        
        // sort the albums
        ListSpeakerAlbums = ListSpeakerAlbums.sorted(by: { $0.Key < $1.Key })
        ListSeriesAlbums = ListSeriesAlbums.sorted(by: { $1.Date < $0.Date })
        ListAllTalks = ListAllTalks.sorted(by: { $0.Date > $1.Date })
        

        
        //  sort all talks in series albums
        for seriesAlbum in ListSeriesAlbums {
            // dharmettes are already sorted and need to be presented with most current talks on top
            // all other series need further sorting, as the most current talks must be at bottom
            if seriesAlbum.Key == "SERIESDharmettes" {
                continue
            }
            let talkList = seriesAlbum.talkList
            seriesAlbum.talkList  = talkList.sorted(by: { $1.Date > $0.Date })
        }
        
        TranscriptsAlbum.talkList = TranscriptsAlbum.talkList.sorted(by: { $0.Date > $1.Date })
        ListSeriesAlbums.insert(TranscriptsAlbum, at: 0)
        computeAlbumStats(album: TranscriptsAlbum)
    }
    
    
    func updateWithNewTalks(jsonDict: [String: AnyObject]) {
        
        for jsonTalk in jsonDict["talks"] as? [AnyObject] ?? [] {
            
            let title = jsonTalk["title"] as? String ?? ""
            let URL = (jsonTalk["url"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let speaker = jsonTalk["speaker"] as? String ?? ""
            var date = jsonTalk["date"] as? String ?? ""
            date = date.replacingOccurrences(of: "-", with: ".")
            let duration = jsonTalk["duration"] as? String ?? ""
            let pdf = jsonTalk["pdf"] as? String ?? ""
            
            let terms = URL.components(separatedBy: "/")
            let fileName = terms.last ?? ""
            
            if FileNameToTalk[fileName] != nil {continue} // only interested in NEW talks

            let seconds = duration.convertDurationToSeconds()
            let talk =  TalkData(title: title,
                                     url: URL,
                                     fileName: fileName,
                                     date: date,
                                     speaker: speaker,
                                     totalSeconds: seconds,
                                     pdf: pdf)
            FileNameToTalk[fileName] = talk

            // CJM DEV
            /*
            if talk.hasTranscript() {
                talk.Title = talk.Title + " [transcript]"
            }
             */
        
            ListAllTalks.append(talk)
            if let speakerAlbum = self.KeyToAlbum[speaker] {
                speakerAlbum.talkList.insert(talk, at: 0)
                speakerAlbum.totalTalks += 1
                speakerAlbum.totalSeconds += seconds
            }
        }
        
        ListAllTalks = self.ListAllTalks.sorted(by: { $0.Date > $1.Date })
        AllTalksAlbum.talkList = ListAllTalks
    }


    func loadAlbums(jsonDict: [String: AnyObject]) {

        print("load albums")
        var albumList : [AlbumData] = []
        var talkList : [TalkData] = []
        
        for jsonAlbum in jsonDict["albums"] as? [AnyObject] ?? [] {
            
                let albumSection = jsonAlbum["section"] as? String ?? ""
                let title = jsonAlbum["title"] as? String ?? ""
                let key = jsonAlbum["content"] as? String ?? ""
                let image = jsonAlbum["image"] as? String ?? ""
                let jsonTalkList = jsonAlbum["talks"] as? [AnyObject] ?? []
                let album: AlbumData = AlbumData(title: title, key: key, section: albumSection, imageName: image, date: "", albumType: AlbumType.ACTIVE)
   
                talkList = []
                albumList = []
            
                switch (key) {
                case KEY_ALL_TALKS:
                    self.AllTalksAlbum = album
                    talkList = self.ListAllTalks
                    print("ALL TALK COUNT: ", self.ListAllTalks.count)
                case KEY_ALL_SPEAKERS:
                    albumList = self.ListSpeakerAlbums
                case KEY_ALL_SERIES:
                    albumList = self.ListSeriesAlbums
                case KEY_RECOMMENDED_TALKS:
                    self.RecommendedAlbum = album
                    albumList = []
                    talkList = []
                case KEY_USER_FAVORITES:
                    self.UserFavoritesAlbum = album
                    self.UserFavorites = TheDataModel.loadUserFavoriteData()
                    for (fileName, _ ) in self.UserFavorites {
                        print(fileName)
                        if let talk = FileNameToTalk[fileName] {
                            talkList.append(talk)
                        }
                    }
                case KEY_NOTES:
                    self.UserNoteAlbum = album
                    self.UserNotes = TheDataModel.loadUserNoteData()
                    for (fileName, _ ) in self.UserNotes {
                        if let talk = FileNameToTalk[fileName] {
                            talkList.append(talk)
                        }
                    }
                case KEY_USER_DOWNLOADS:
                    self.UserDownloadAlbum = album
                    for (fileName, _ ) in self.UserDownloads {
                        if let talk = FileNameToTalk[fileName] {
                            talkList.append(talk)
                        }
                    }
                case KEY_USER_ALBUMS:
                    self.CustomUserAlbums = album
                    self.UserAlbums = TheDataModel.loadUserAlbumData()
                    for userAlbumData in self.UserAlbums {
                        let albumKey = self.randomKey()
                        let customAlbum = AlbumData(title: userAlbumData.Title, key: self.randomKey(), section: "", imageName: "albumdefault", date: "", albumType: AlbumType.ACTIVE)
                        KeyToAlbum[albumKey] = customAlbum
                        albumList.append(customAlbum)
                        for fileName in userAlbumData.TalkFileNames {
                            if let talk = FileNameToTalk[fileName] {
                                customAlbum.talkList.append(talk)
                            }
                        }
                        
                    }
                case KEY_USER_TALKHISTORY:
                    print("talk History")
                    self.UserTalkHistoryAlbum = album
                    self.UserTalkHistoryList = TheDataModel.loadTalkHistoryData()

                    for talkHistory in self.UserTalkHistoryList {
                        if let talk = FileNameToTalk[talkHistory.FileName] {
                            talkList.append(talk)
                        }
                    }
                case KEY_USER_SHAREHISTORY:
                    album.albumType = AlbumType.HISTORICAL
                    self.UserShareHistoryAlbum = album
                case KEY_SANGHA_TALKHISTORY:
                    album.albumType = AlbumType.HISTORICAL
                    self.SanghaTalkHistoryAlbum = album
                case KEY_SANGHA_SHAREHISTORY:
                    album.albumType = AlbumType.HISTORICAL
                    self.SanghaShareHistoryAlbum = album
              default:
                    albumList = []
                    talkList = []
                }
                album.albumList = albumList
                album.talkList = talkList
                self.RootAlbum.albumList.append(album)
                KeyToAlbum[key] = album
            if key == KEY_SHORT_TALKS {
                print("KEY SHORT TALKS LOADED")
            }

                // get the optional talk array for this Album
                for jsonTalk in jsonTalkList {
                    
                    let URL = jsonTalk["url"] as? String ?? ""
                    let series = jsonTalk["series"] as? String ?? ""
                    let fileName = URL.components(separatedBy: "/").last ?? ""
                                       
                    if let talk = self.FileNameToTalk[fileName] {
                        // if series specified, these always go into RecommendedAlbum
                        var seriesAlbum : AlbumData
                        if !series.isEmpty {
                             let seriesKey = "RECOMMENDED" + series
                            if self.KeyToAlbum[seriesKey] == nil {
                                seriesAlbum = AlbumData(title: series, key: seriesKey, section: "", imageName: talk.Speaker, date : talk.Date, albumType: AlbumType.ACTIVE)
                                self.KeyToAlbum[seriesKey] = seriesAlbum
                                self.RecommendedAlbum.albumList.append(seriesAlbum)
                            }
                            seriesAlbum = self.KeyToAlbum[seriesKey]!
                            seriesAlbum.talkList.append(talk)
                            seriesAlbum.totalTalks += 1
                            seriesAlbum.totalSeconds += talk.TotalSeconds

                        } else {
                            album.talkList.append(talk)
                        }
                    }
                } // end talk loop
        } // end Album loop
        
        self.loadLastAlbumTalkState()

    }
    
    
    func downloadSimilarityData(talk: TalkData, signalComplete: DispatchSemaphore) {

         let config = URLSessionConfiguration.default
         config.requestCachePolicy = .reloadIgnoringLocalCacheData
         config.urlCache = nil
         let session = URLSession.init(configuration: config)

         let similarKeyName = talk.FileName.replacingOccurrences(of: ".mp3", with: "")
         let path = URL_GET_SIMILAR + similarKeyName
         let requestURL : URL? = URL(string: path)
         let urlRequest = URLRequest(url : requestURL!)

         var talkList: [TalkData] = []
         let task = session.dataTask(with: urlRequest) {
             (data, response, error) -> Void in

             var httpResponse: HTTPURLResponse
             if let valid_reponse = response {
                 httpResponse = valid_reponse as! HTTPURLResponse
                 HTTPResultCode = httpResponse.statusCode
             } else {
                 HTTPResultCode = 404
             }

             if let responseData = data {
                 if responseData.count < MIN_EXPECTED_RESPONSE_SIZE {
                     HTTPResultCode = 404
                 }
             }
             else {
                 HTTPResultCode = 404
             }

             if HTTPResultCode == 200 {
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
             }
             signalComplete.signal()
         }
         task.resume()
     }

    
    func downloadSanghaActivity() {
        
        //print("downloadSanghaActivity")
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        let session = URLSession.init(configuration: config)
        
        let requestURL : URL? = URL(string: URL_GET_ACTIVITY + "DEVICEID=" + DEVICE_ID)

        let urlRequest = URLRequest(url : requestURL!)
        
        let task = session.dataTask(with: urlRequest) {
            (data, response, error) -> Void in
            
            
            var httpResponse: HTTPURLResponse
            if let valid_reponse = response {
                httpResponse = valid_reponse as! HTTPURLResponse
            } else {
                ModelReadySemaphore.signal()

                return
            }
            //let httpResponse = response as! HTTPURLResponse
            let statusCode = httpResponse.statusCode
            
            if (statusCode != 200) {
                ModelReadySemaphore.signal()

                return
            }
            
            // make sure we got data.  including cases where only partial data returned (MIN_EXPECTED_RESPONSE_SIZE is arbitrary)
            guard let responseData = data else {
                return
            }
            if responseData.count < MIN_EXPECTED_RESPONSE_SIZE {
                ModelReadySemaphore.signal()

                return
            }
  
            do {
                // get the community talk history
                var talkCount = 0
                var totalSeconds = 0
                var talkList: [TalkData] = []

                let json =  try JSONSerialization.jsonObject(with: responseData) as! [String: AnyObject]
                for talkJSON in json["sangha_history"] as? [AnyObject] ?? [] {
                    
                    let fileName = talkJSON["filename"] as? String ?? ""
                    let datePlayed = talkJSON["date"] as? String ?? ""
                    let city = talkJSON["city"] as? String ?? ""
                    let country = talkJSON["country"] as? String ?? ""
                   
                    if let talk = self.FileNameToTalk[fileName] {
                        
                        let talkHistory = talk.copy() as! TalkData
                        talkHistory.DatePlayed = datePlayed
                        talkHistory.City  = city
                        talkHistory.Country = country

                        talkCount += 1
                        totalSeconds += talk.TotalSeconds
                        talkList.append(talkHistory)
                        
                        if talkCount >= MAX_TALKHISTORY_COUNT {
                            break
                        }
                    }
                }
                GuardCommunityAlbumSemaphore.wait()  // obtain critical-section access on talkList
                self.SanghaTalkHistoryAlbum.talkList = talkList
                GuardCommunityAlbumSemaphore.signal()  // release critical-section access on talkList


                // get the community share history
                talkCount = 0
                totalSeconds = 0
                talkList = []
                for talkJSON in json["sangha_shares"] as? [AnyObject] ?? [] {
                    
                    let fileName = talkJSON["filename"] as? String ?? ""
                    let dateShared = talkJSON["date"] as? String ?? ""
                    let city = talkJSON["city"] as? String ?? ""
                    let country = talkJSON["country"] as? String ?? ""
                    
                    if let talk = self.FileNameToTalk[fileName] {
                        
                        let talkHistory = talk.copy() as! TalkData
                        talkHistory.DatePlayed = dateShared
                        talkHistory.City  = city
                        talkHistory.Country = country

                        talkList.append(talkHistory)
                        
                        talkCount += 1
                        totalSeconds += talk.TotalSeconds

                        if talkCount >= MAX_SHAREHISTORY_COUNT {
                            break
                        }
                    }
                 }
                GuardCommunityAlbumSemaphore.wait()  // obtain critical-section access on talkList
                self.SanghaShareHistoryAlbum.talkList = talkList
                GuardCommunityAlbumSemaphore.signal()  // release critical-section access on talkList

            } catch {   // end do catch
            }
            
            self.computeAlbumStats(album: self.SanghaTalkHistoryAlbum)
            self.computeAlbumStats(album: self.SanghaShareHistoryAlbum)

            // END CRITICAL SECTION FOR LOADING
            ModelReadySemaphore.signal()

            
        }
        task.resume()
    }
    
    
    func startDownload(talk: TalkData, success: @escaping  () -> Void) {

        var requestURL: URL
        var localPathMP3: String
        
        DownloadInProgress = true
        
        // remote source path for file
        if USE_NATIVE_MP3PATHS == true {
            requestURL  = URL(string: URL_MP3_HOST + talk.URL)!
        } else {
            requestURL  = URL(string: URL_MP3_HOST + "/" + talk.FileName)!
        }
        
        // local destination path for file
        localPathMP3 = MP3_DOWNLOADS_PATH + "/" + talk.FileName
        
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        let session = URLSession.init(configuration: config)
        
        let urlRequest = URLRequest(url : requestURL)
        
        let task = session.dataTask(with: urlRequest) {
            (data, response, error) -> Void in
            

            var httpResponse: HTTPURLResponse
            if let valid_reponse = response {
                httpResponse = valid_reponse as! HTTPURLResponse
            } else {
                TheDataModel.unsetTalkAsDownloaded(talk: talk)
                TheDataModel.DownloadInProgress = false
                return
            }
            //let httpResponse = response as! HTTPURLResponse
            let statusCode = httpResponse.statusCode
            
            if (statusCode != 200) {
                TheDataModel.unsetTalkAsDownloaded(talk: talk)
                TheDataModel.DownloadInProgress = false
                return
            }
            
            // make sure we got data
            if let responseData = data {
                if responseData.count < MIN_EXPECTED_RESPONSE_SIZE {
                    TheDataModel.unsetTalkAsDownloaded(talk: talk)
                    HTTPResultCode = 404
                }
            }
            else {
                TheDataModel.unsetTalkAsDownloaded(talk: talk)
                HTTPResultCode = 404
            }
            
            // if got a good response, store off file locally
            if HTTPResultCode == 200 {
                
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
                print("Download background done")
                TheDataModel.DownloadInProgress = false
                TheDataModel.setTalkAsDownloaded(talk: talk)
                success()
            }
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
        
        //print("computeAlbumStats: ", album.Title)
        var totalSeconds = 0
        var totalTalks = 0
        
        for talk in album.talkList {
            totalSeconds += talk.TotalSeconds
            totalTalks += 1
        }

        for childAlbum in album.albumList {
             for talk in childAlbum.talkList {
                totalSeconds += talk.TotalSeconds
                totalTalks += 1
            }
        }
        
        // album.totalTalks is an observed published var
        // therefore need to update it via a dispatch to the main thread
        DispatchQueue.main.async {
            
            if TalkIsCurrentlyPlaying == false {
                album.totalTalks = totalTalks
            }
        }
        album.totalSeconds = totalSeconds
        
        //print("ComputeAlbumStates: ", album.Title, album.totalTalks, album.totalSeconds)

    }
    
        
    //
    // MARK: talk and album functions
    //
    func toggleTalkAsFavorite(talk: TalkData) -> Bool {

        if TheDataModel.isFavoriteTalk(talk: talk) {
            TheDataModel.UserFavorites[talk.FileName] = nil
            if let index = TheDataModel.UserFavoritesAlbum.talkList.firstIndex(of: talk) {
                print("toggleTalkAsFavorite removing: ", talk.Title)
                TheDataModel.UserFavoritesAlbum.talkList.remove(at: index)
            }
        } else {
            TheDataModel.UserFavorites[talk.FileName] = UserFavoriteData(fileName: talk.FileName)
            print("toggleTalkAsFavorite adding: ", talk.Title)
            TheDataModel.UserFavoritesAlbum.talkList.insert(talk, at: 0)
            //CJM Append?
        }

        TheDataModel.saveUserFavoritesData()
        TheDataModel.computeAlbumStats(album: TheDataModel.UserFavoritesAlbum)
        
        let isFavorite = TheDataModel.UserFavorites[talk.FileName] != nil
        print("ToggleTalkAsFavorite New Value: ", isFavorite)
        return isFavorite
    }
    
    
    func isFavoriteTalk(talk: TalkData) -> Bool {
        
        return TheDataModel.UserFavorites[talk.FileName] != nil
    }
    
 
    
    func isDownloadInProgress(talk: TalkData) -> Bool {
        
        var downloadInProgress = false
        if let userDownload = TheDataModel.UserDownloads[talk.FileName]  {
            downloadInProgress = (userDownload.DownloadCompleted == "NO")
        }
        return downloadInProgress
    }

    
    func setTalkAsDownloaded(talk: TalkData) {
        
        TheDataModel.UserDownloadAlbum.talkList.insert(talk, at: 0)
        TheDataModel.UserDownloads[talk.FileName] = UserDownloadData(fileName: talk.FileName, downloadCompleted: "YES")
        TheDataModel.saveUserDownloadData()

        TheDataModel.computeAlbumStats(album: TheDataModel.UserDownloadAlbum)

    }
    
    
    func unsetTalkAsDownloaded(talk: TalkData) {
        
        if let index = TheDataModel.UserDownloadAlbum.talkList.firstIndex(of: talk) {
            print("download removing: ", talk.Title)
            TheDataModel.UserDownloadAlbum.talkList.remove(at: index)
        }
        
        if let userDownload = TheDataModel.UserDownloads[talk.FileName] {
            if userDownload.DownloadCompleted == "NO" {
                TheDataModel.DownloadInProgress = false
            }
        }
        TheDataModel.UserDownloads[talk.FileName] = nil
        let localPathMP3 = MP3_DOWNLOADS_PATH + "/" + talk.FileName
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

        return TheDataModel.UserDownloads[talk.FileName] != nil

    }
    
    
    func addNoteToTalk(talk: TalkData, noteText: String) {

         //
         // if there is a note text for this talk fileName, then save it in the note dictionary
         // otherwise clear this note dictionary entry
         let talkFileName = talk.FileName

         if (noteText.count > 0) && noteText.rangeOfCharacter(from: CharacterSet.alphanumerics) != nil {
             print("adding note on talk: ", talk.Title)
             TheDataModel.UserNotes[talkFileName] = UserNoteData(notes: noteText)
             TheDataModel.UserNoteAlbum.talkList.append(talk)
         } else {
             print("remove note on talk: ", talk.Title)
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

         if let userNoteData = TheDataModel.UserNotes[talk.FileName]   {
             noteText = userNoteData.Notes
         }
         return noteText
     }


    func isNotatedTalk(talk: TalkData) -> Bool {
         
         if let _ = TheDataModel.UserNotes[talk.FileName] {
             return true
         }
         return false
     }
     
     
    func hasTalkBeenPlayed(talk: TalkData) -> Bool {
     
         return TheDataModel.PlayedTalks[talk.FileName] != nil
     }

     
     func isMostRecentTalk(talk: TalkData) -> Bool {
     
         
         if let lastTalk = TheDataModel.UserTalkHistoryAlbum.talkList.first {
             return talk.FileName == lastTalk.FileName
         }
         return false
     }
      
      
    //
    // invoked in background by TalkPlayerView
    //
    func addToTalkHistory(talk: TalkData) {
        
        self.PlayedTalks[talk.FileName] = true

        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        let datePlayed = formatter.string(from: date)
        formatter.dateFormat = "HH:mm:ss"
        let timePlayed = formatter.string(from: date)

        talk.DatePlayed = datePlayed
        talk.TimePlayed = timePlayed

        let talkHistory = TalkHistoryData(fileName: talk.FileName, datePlayed: talk.DatePlayed, timePlayed: talk.TimePlayed, cityPlayed: "", statePlayed: "", countryPlayed: "")

        UserTalkHistoryAlbum.talkList.insert(talk, at: 0)
        UserTalkHistoryList.insert(talkHistory, at: 0)
        let excessTalkCount = UserTalkHistoryList.count - MAX_HISTORY_COUNT
        if excessTalkCount > 0 {
            for _ in 0 ... excessTalkCount {
                UserTalkHistoryList.remove(at: 0)
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
        
        PlayedTalks[talk.FileName] = true
        talk.DatePlayed = datePlayed
        talk.TimePlayed = timePlayed
        UserShareHistoryAlbum.talkList.append(talk)
        
        let excessTalkCount = UserShareHistoryAlbum.talkList.count - MAX_HISTORY_COUNT
        if excessTalkCount > 0 {
            for _ in 0 ... excessTalkCount {
                UserShareHistoryAlbum.talkList.remove(at: 0)
            }
        }
        
        // save the data, recompute stats, reload root view to display updated stats
        saveShareHistoryData()
    }
    
    
    //
    // MARK: User Album functions
    //
    func saveCustomUserAlbums() {
    
        let image = UIImage(named: "notebar")
        UserAlbums = []
        for album in self.CustomUserAlbums.albumList {
            
            print(album.Title)
            let userAlbum = UserAlbumData(title: album.Title, image: image!, content: "", talkFileNames: [])
            
            var talkFileNameList: [String] = []
            for talk in album.talkList {
                
                if let _ = getTalkForName(name: talk.FileName) {
                    talkFileNameList.append(talk.FileName)
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
        let userAlbum = UserAlbumData(title: album.Title, image: image!, content: "", talkFileNames: [])
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
            talkFileNames.append(talk.FileName)
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
    // MARK:  Persistent Data Functions
    //
    func saveTalkHistoryData() {
        
        do {
            if let data = try? NSKeyedArchiver.archivedData(withRootObject: TheDataModel.UserTalkHistoryList, requiringSecureCoding: false) {
                try data.write(to: TalkHistoryData.ArchiveTalkHistoryURL)
            }
        }
        catch let error as NSError {
            errorLog(error: error)
        }
    }

    
    func loadTalkHistoryData() -> [TalkHistoryData]  {
        
        if let data = try? Data(contentsOf: TalkHistoryData.ArchiveTalkHistoryURL) {
            if let talkHistory = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [TalkHistoryData] {
                return talkHistory
            } else {
                return [TalkHistoryData] ()
            }
        }
        return [TalkHistoryData] ()
    }

    
    func saveShareHistoryData() {
        
        do {
            if let data = try? NSKeyedArchiver.archivedData(withRootObject: TheDataModel.UserShareHistoryAlbum, requiringSecureCoding: false) {
                try data.write(to: TalkHistoryData.ArchiveShareHistoryURL)
            }
        }
        catch let error as NSError {
            errorLog(error: error)
        }
    }

    
    func loadShareHistoryData() -> [TalkHistoryData]  {
        
        if let data = try? Data(contentsOf: TalkHistoryData.ArchiveShareHistoryURL) {
            if let talkHistory = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [TalkHistoryData] {
                return talkHistory
            } else {
                return [TalkHistoryData] ()
            }
        }
        return [TalkHistoryData] ()
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
    // MARK: Support Functions
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
            
            print("Reomving bad donwload: ", userDownload.FileName)
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
    
    
    func remoteTalkExists(talk: TalkData, completion:@escaping (Bool, TalkData)->()){
        
        var talkURL: URL    // where the MP3 lives
        
        if isFullURL(url: talk.URL) {
            talkURL  = URL(string: talk.URL)!
        }
        else if USE_NATIVE_MP3PATHS == true {
            talkURL  = URL(string: URL_MP3_HOST +  talk.URL)!
            
        } else {
            talkURL  = URL(string: URL_MP3_HOST + "/" + talk.FileName)!
        }
        
        var request: URLRequest = URLRequest(url: talkURL as URL)
        request.httpMethod = "HEAD"
        
        var exists: Bool = true
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            
            if let httpResponse = response as? HTTPURLResponse {
                
                if httpResponse.statusCode == 404 {
                    
                    exists =  false
                }else{
                    exists  = true
                }
                
            }
            
            DispatchQueue.main.async {
                completion(exists, talk)
            }
            }.resume()
        
    }


    func remoteURLExists(url: URL, completion:@escaping (Bool, URL)->()){
        
        var request: URLRequest = URLRequest(url: url as URL)
        request.httpMethod = "HEAD"
        
        var exists: Bool = true
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            
            if let httpResponse = response as? HTTPURLResponse {
                
                if httpResponse.statusCode == 404 {
                    exists =  false
                }else{
                    exists  = true
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
    

    

    
}
    

