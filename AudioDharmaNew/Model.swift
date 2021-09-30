//
//  Model.swift
//  AudioDharma
//
//  Created by Christopher on 6/22/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//            self.UserFavorites = TheDataModel.loadUserFavoriteData()

import UIKit
import Foundation
import SystemConfiguration
import os.log
import ZipArchive


// MARK: Global Constants and Vars
let TheDataModel = Model()
//@EnvironmentObject var TheDataModel: Model = Model()
let DEVICE_ID = UIDevice.current.identifierForVendor!.uuidString
let ModelUpdateSemaphore = DispatchSemaphore(value: 1)  // guards underlying dicts and lists
let ModelLoadSemaphore = DispatchSemaphore(value: 0)  // guards underlying dicts and lists


// all possible web config points
let HostAccessPoints: [String] = [
    "http://www.virtualdharma.org",
    "http://www.audiodharma.org"
]
var HostAccessPoint: String = HostAccessPoints[0]   // the one we're currently using

// paths for services

//let CONFIG_JSON_NAME = "CONFIG00.JSON"
//let CONFIG_ZIP_NAME = "CONFIG00.ZIP"

let CONFIG_JSON_NAME = "CONFIG00.JSON"
let CONFIG_ZIP_NAME = "CONFIG00.ZIP"
//let CONFIG_JSON_NAME = "TEST.JSON"
//let CONFIG_ZIP_NAME = "TEST.ZIP"


var MP3_DOWNLOADS_PATH = ""      // where MP3s are downloaded.  this is set up in loadData()

let CONFIG_ACCESS_PATH = "/AudioDharmaAppBackend/Config/" + CONFIG_ZIP_NAME    // remote web path to config
let CONFIG_REPORT_ACTIVITY_PATH = "/AudioDharmaAppBackend/Access/reportactivity.php"     // where to report user activity (shares, listens)
let CONFIG_GET_ACTIVITY_PATH = "/AudioDharmaAppBackend/Access/XGETACTIVITY.php?"           // where to get sangha activity (shares, listens)
//let CONFIG_GET_ACTIVITY_PATH = "/AudioDharmaAppBackend/Access/XTEST.php?"           // where to get sangha activity (shares, listens)

let CONFIG_GET_SIMILAR_TALKS = "/AudioDharmaAppBackend/Access/XGETSIMILARTALKS.php?KEY="           // where to get similar talks
let CONFIG_GET_SUGGESTED_TALKS = "/AudioDharmaAppBackend/Access/XGETSUGGESTEDTALKS.php?KEY="           // where to get suggested talks

let CONFIG_GET_HELP = "/AudioDharmaAppBackend/Access/XGETHELP.php?"           // where to get help page


let DEFAULT_MP3_PATH = "http://www.audiodharma.org"     // where to get talks
let DEFAULT_DONATE_PATH = "http://audiodharma.org/donate/"       // where to donate

var HTTPResultCode: Int = 0     // global status of web access
let MIN_EXPECTED_RESPONSE_SIZE = 300   // to filter for bogus redirect page responses

enum INIT_CODES {          // all possible startup results
    case SUCCESS
    case NO_CONNECTION
}

// set default web access points
var URL_CONFIGURATION = HostAccessPoint + CONFIG_ACCESS_PATH
var URL_REPORT_ACTIVITY = HostAccessPoint + CONFIG_REPORT_ACTIVITY_PATH
var URL_GET_ACTIVITY = HostAccessPoint + CONFIG_GET_ACTIVITY_PATH
var URL_GET_SIMILAR = HostAccessPoint + CONFIG_GET_SIMILAR_TALKS
var URL_GET_SUGGESTED = HostAccessPoint + CONFIG_GET_SUGGESTED_TALKS
var URL_GET_HELP = HostAccessPoint + CONFIG_GET_HELP

var URL_MP3_HOST = DEFAULT_MP3_PATH
var URL_DONATE = DEFAULT_DONATE_PATH


enum ACTIVITIES {          // all possible activities that are reported back to cloud
    case SHARE_TALK
    case PLAY_TALK
}


// App Global Constants
// talk and album display states.  these are used throughout the app to key on state
let KEY_HELP = "KEY_HELP"
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


let MP3_BYTES_PER_SECOND = 20000    // rough (high) estimate for how many bytes per second of MP3.  Used to estimate size of download files

// MARK: Global Config Variables.  Values are defaults.  All these can be overriden at boot time by the config
let REPORT_TALK_THRESHOLD = 90      // how many seconds into a talk before reporting that talk that has been officially played

let SECONDS_TO_NEXT_TALK : Double = 2   // when playing an album, this is the interval between talks

var MAX_TALKHISTORY_COUNT = 3000     // maximum number of played talks showed in sangha history. over-rideable by config
var MAX_SHAREHISTORY_COUNT = 1000     // maximum number of shared talks showed in sangha history  over-rideable by config
var MAX_HISTORY_COUNT = 100         // maximum number of user (not sangha) talk history displayed

var UPDATE_SANGHA_INTERVAL = 60     // amount of time (in seconds) between each poll of the cloud for updated sangha info
var UPDATE_MODEL_INTERVAL : TimeInterval = 120 * 60    // interval to next update model
var LAST_MODEL_UPDATE = NSDate().timeIntervalSince1970  // when we last updated model

var USE_NATIVE_MP3PATHS = true    // true = mp3s are in their native paths in audiodharma, false =  mp3s are in one flat directory

let SECTION_HEADER = "SECTION_HEADER"
let DATA_ALBUMS: [String] = ["DATA00", "DATA01", "DATA02", "DATA03", "DATA04", "DATA05"]    // all possible pluggable data albums we can load

let KEYS_TO_ALBUMS = [KEY_ALBUMROOT, KEY_RECOMMENDED_TALKS, KEY_ALL_SERIES, KEY_ALL_SPEAKERS]


class Model {
    
    var KeyToAlbum : [String: AlbumData] = [:]  //  dictionary keyed by "key" which is a albumd id, value is an album
    var FileNameToTalk: [String: TalkData]   = [String: TalkData] ()  // dictionary keyed by talk filename, value is the talk data (used by userList code to lazily bind)

    var UserTalkHistoryAlbum: [TalkHistoryData] = []    // history of talks for user
    var FileNameToUserTalkHistory: [String: TalkHistoryData]   = [String: TalkHistoryData] ()  //
    var UserShareHistoryAlbum: [TalkHistoryData] = []   // history of shared talks for user
    var SangaTalkHistoryAlbum: [TalkHistoryData] = []          // history of talks for sangha
    var SangaShareHistoryAlbum: [TalkHistoryData] = []          // history of shares for sangha
    
    var RootAlbum: AlbumData = AlbumData(title: "ROOT", key: KEY_ALBUMROOT, section: "", image: "albumdefault", date: "")
    var RecommendedAlbum: AlbumData = AlbumData(title: "RECOMMENDED", key: KEY_ALBUMROOT, section: "", image: "albumdefault", date: "")
    var UserFavoritesAlbum: AlbumData = AlbumData(title: "USER FAVORITES", key: KEY_USER_FAVORITES, section: "", image: "albumdefault", date: "")
    var UserNoteAlbum: AlbumData = AlbumData(title: "USER NOTES", key: KEY_NOTES, section: "", image: "albumdefault", date: "")
    var UserDownloadAlbum: AlbumData = AlbumData(title: "USER DOWNLOADS", key: KEY_USER_DOWNLOADS, section: "", image: "albumdefault", date: "")


    var ListAllTalks: [TalkData] = []
    var ListSpeakerAlbums: [AlbumData] = []
    var ListSeriesAlbums: [AlbumData] = []
    var ListRecommenedAlbums: [AlbumData] = []
    var ListFavoriteTalls : [TalkData] = []

    var DownloadInProgress = false

    var UpdatedTalksJSON: [String: AnyObject] = [String: AnyObject] ()

    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!

    // MARK: Persistant Data
    var UserAlbums: [UserAlbumData] = []      // all the custom user albums defined by this user.
    var UserNotes: [String: UserNoteData] = [:]      // all the  user notes defined by this user, indexed by fileName
    var UserFavorites: [String: UserFavoriteData] = [:]      // all the favorites defined by this user, indexed by fileName
	var UserDownloads: [String: UserDownloadData] = [:]      // all the downloads defined by this user, indexed by fileName
    // CJM
    var PlayedTalks: [String: Bool]   = [:]  // all the talks that have been played by this user, indexed by fileName
    let PlayedTalks_ArchiveURL = DocumentsDirectory.appendingPathComponent("PlayedTalks")
    
    // MARK: Init
    func resetData() {

        FileNameToTalk = [String: TalkData] ()
        UserTalkHistoryAlbum = []
        UserShareHistoryAlbum = []
        SangaTalkHistoryAlbum = []
        SangaShareHistoryAlbum = []
        
        ListAllTalks = []
        
        DownloadInProgress = false
        
        UpdatedTalksJSON = [String: AnyObject] ()
        
        UserAlbums = []
        UserNotes = [:]
        UserFavorites = [:]
        UserDownloads = [:]
        
        /*
        for dataContent in DATA_ALBUMS {
            self.KeyToTalks[dataContent] = [TalkData] ()
        }
 */
    }
    
    func loadData() {
        
        FileNameToTalk = [String: TalkData] ()
        UserTalkHistoryAlbum = []
        UserShareHistoryAlbum = []
        SangaTalkHistoryAlbum  = []
        SangaShareHistoryAlbum = []

        ListAllTalks = []
        
        HTTPResultCode = 0
        URL_CONFIGURATION = HostAccessPoint + CONFIG_ACCESS_PATH
        URL_REPORT_ACTIVITY = HostAccessPoint + CONFIG_REPORT_ACTIVITY_PATH
        URL_GET_ACTIVITY = HostAccessPoint + CONFIG_GET_ACTIVITY_PATH
        
        // MUST be done before calling downloadAndConfigure, as that computes
        // stats and that in turn relies on KeyToTalks not being nil (which I do check for, but
        // let's overkill it here just in case
        //CJM DEV
        /*
        for dataContent in DATA_ALBUMS {
            self.KeyToTalks[dataContent] = [TalkData] ()
        }
 */

        downloadAndConfigure(path: URL_CONFIGURATION)
        
        // get sangha activity and set up timer for updates
        downloadSanghaActivity()
        
        // build the data directories on device, if needed
        let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        MP3_DOWNLOADS_PATH = documentPath + "/DOWNLOADS"
        
        do {
            try FileManager.default.createDirectory(atPath: MP3_DOWNLOADS_PATH, withIntermediateDirectories: false, attributes: nil)
        } catch let error as NSError {
            log(error: error)
        }
        
    }
    
    func startBackgroundTimers() {
        
        Timer.scheduledTimer(timeInterval: TimeInterval(UPDATE_SANGHA_INTERVAL), target: self, selector: #selector(getSanghaActivity), userInfo: nil, repeats: true)
    }
    
    
    func downloadSimilarityData(talkFileName: String) {
    
        /*
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        let session = URLSession.init(configuration: config)
        
        let similarKeyName = talkFileName.replacingOccurrences(of: ".mp3", with: "")
        let path = URL_GET_SIMILAR + similarKeyName
        let requestURL : URL? = URL(string: path)
        let urlRequest = URLRequest(url : requestURL!)
        
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
           
                let content = talkFileName

                var talks = [TalkData] ()

                do {
                    let jsonDict =  try JSONSerialization.jsonObject(with: data!) as! [String: AnyObject]
                    for similarTalk in jsonDict["SIMILAR"] as? [AnyObject] ?? [] {
                        
                        let filename = similarTalk["filename"] as? String ?? ""
                        
                        if let talk = self.FileNameToTalk[filename] {
                            talks.append(talk)
                        }
                    }

                    self.KeyToTalks[content] = talks

                }
                catch {
                }
            }
        
        }
        task.resume()
*/
    }
    
            
    
    // MARK: Configuration
    func downloadAndConfigure(path: String)  {
        
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        let session = URLSession.init(configuration: config)
        
        let requestURL : URL? = URL(string: path)
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
                    self.log(error: error)
                    return
                }
            }

            // unzip zipped config back into json
            //let time1 = Date.timeIntervalSinceReferenceDate
            
            if SSZipArchive.unzipFile(atPath: configZipPath, toDestination: documentPath) != true {
                HTTPResultCode = 404
                
                //CJM DEV
                let alert = UIAlertController(title: "No Internet Connection", message: "Please check your connection.", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))

                return
            }

            // get our unzipped json from the local storage and process it
            var jsonData: Data!
            do {                                                                                                            jsonData = try Data(contentsOf: URL(fileURLWithPath: configJSONPath))
            }
            catch let error as NSError {
                HTTPResultCode = 404
                self.log(error: error)
                return
            }
                        
            // BEGIN CRITICAL SECTION
            ModelUpdateSemaphore.wait()


            do {
                let jsonDict =  try JSONSerialization.jsonObject(with: jsonData) as! [String: AnyObject]
                self.loadConfig(jsonDict: jsonDict)
                self.loadTalks(jsonDict: jsonDict)
                self.loadAlbums(jsonDict: jsonDict)
                self.downloadSanghaActivity()
            }
            catch {
            }
            
/*
            self.computeUserFavoriteStats()
            self.computeNotesStats()
 */

            for album in self.RootAlbum.albumList {
                self.computeAlbumStats(album: album)
            }

            
 
            
            /*
            self.computeUserAlbumStats()
            self.computeNotesStats()
            self.computeUserFavoritesStats()
            self.computeUserDownloadStats()
            self.computeTalkHistoryStats()
            self.computeShareHistoryStats()
            self.computeDataStats()

            self.UserAlbums = TheDataModel.loadUserAlbumData()
            self.computeUserAlbumStats()
            
             
            self.UserNotes = TheDataModel.loadUserNoteData()
            self.computeNotesStats()
            self.UserFavorites = TheDataModel.loadUserFavoriteData()
            self.computeUserFavoritesStats()
            self.UserDownloads = TheDataModel.loadUserDownloadData()
            TheDataModel.validateUserDownloadData()
            self.computeUserDownloadStats()

            self.UserTalkHistoryAlbum = TheDataModel.loadTalkHistoryData()
            self.PlayedTalks = TheDataModel.loadUPlayedTalksData()
            self.computeTalkHistoryStats()

            self.UserShareHistoryAlbum = TheDataModel.loadShareHistoryData()
            self.computeShareHistoryStats()
 */

            
            print("signalling semaphore")
            ModelUpdateSemaphore.signal()
            ModelLoadSemaphore.signal()
            
  

            // END CRITICAL SECTION
 
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
                
                let seconds = self.convertDurationToSeconds(duration: duration)
                totalSeconds += seconds
            
                let talk =  TalkData(title: title,
                                         url: URL,
                                         fileName: fileName,
                                         date: date,
                                         durationDisplay: duration,
                                         speaker: speaker,
                                         durationInSeconds: seconds,
                                         pdf: pdf)
                    
                if doesTalkHaveTranscript(talk: talk) {
                    talk.Title = talk.Title + " [transcript]"
                }
            
                self.FileNameToTalk[fileName] = talk
                
                // add this talk to  list of all talks
                self.ListAllTalks.append(talk)
            
                var speakerAlbum : AlbumData
                var seriesAlbum : AlbumData

                if self.KeyToAlbum[speaker] == nil {
                    speakerAlbum = AlbumData(title: speaker, key: speaker, section: "", image: speaker, date: date)
                    self.KeyToAlbum[speaker] = speakerAlbum
                    ListSpeakerAlbums.append(speakerAlbum)
                }
                speakerAlbum = self.KeyToAlbum[speaker]!
                speakerAlbum.talkList.append(talk)
                speakerAlbum.totalTalks += 1
                speakerAlbum.totalSeconds += seconds
                speakerAlbum.durationDisplay  = self.secondsToDurationDisplay(seconds: speakerAlbum.totalSeconds)

                
                // if a series is specified, create an album if one doesn't exist.  add talk to album
                if !series.isEmpty {
                    
                    let seriesKey = "SERIES" + series
                    if self.KeyToAlbum[seriesKey] == nil {
                        seriesAlbum = AlbumData(title: series, key: seriesKey, section: "", image: speaker, date : date)
                        self.KeyToAlbum[seriesKey] = seriesAlbum
                        ListSeriesAlbums.append(seriesAlbum)
                    }
                    seriesAlbum = self.KeyToAlbum[seriesKey]!
                    seriesAlbum.talkList.append(talk)
                    seriesAlbum.totalTalks += 1
                    seriesAlbum.totalSeconds += seconds
                    seriesAlbum.durationDisplay  = self.secondsToDurationDisplay(seconds: seriesAlbum.totalSeconds)
                 }
                
                talkCount += 1
        }
        
        
        // sort the albums
        self.ListSpeakerAlbums = self.ListSpeakerAlbums.sorted(by: { $0.Key < $1.Key })
        self.ListSeriesAlbums = self.ListSeriesAlbums.sorted(by: { $1.Date < $0.Date })
        self.ListAllTalks = self.ListAllTalks.sorted(by: { $0.Date > $1.Date })
        
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
    }
    
    
    func loadAlbums(jsonDict: [String: AnyObject]) {

        var albumList : [AlbumData] = []
        var talkList : [TalkData] = []
        
        for jsonAlbum in jsonDict["albums"] as? [AnyObject] ?? [] {
            
                let albumSection = jsonAlbum["section"] as? String ?? ""
                let title = jsonAlbum["title"] as? String ?? ""
                let key = jsonAlbum["content"] as? String ?? ""
                let image = jsonAlbum["image"] as? String ?? ""
                let jsonTalkList = jsonAlbum["talks"] as? [AnyObject] ?? []
                let album =  AlbumData(title: title, key: key, section: albumSection, image: image, date: "")

                talkList = []
                albumList = []
            
                switch (key) {
                case KEY_ALL_TALKS:
                    talkList = self.ListAllTalks
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
                    print("KEY_NOTES")
                    for (fileName, _ ) in self.UserNotes {
                        print("testing if legal")
                        if let talk = FileNameToTalk[fileName] {
                            print("adding note", talk.Title)
                            talkList.append(talk)
                        }
                    }
                case KEY_USER_DOWNLOADS:
                    self.UserDownloadAlbum = album
                    self.UserDownloads = TheDataModel.loadUserDownloadData()
                    for (fileName, _ ) in self.UserDownloads {
                        print(fileName)
                        if let talk = FileNameToTalk[fileName] {
                            print("adding download")
                            talkList.append(talk)
                        }
                    }
              default:
                    albumList = []
                    talkList = []
                }
                album.albumList = albumList
                album.talkList = talkList
                self.RootAlbum.albumList.append(album)

                // get the optional talk array for this Album
                for jsonTalk in jsonTalkList {
                    
                    var URL = jsonTalk["url"] as? String ?? ""
                    let terms = URL.components(separatedBy: "/")
                    let fileName = terms.last ?? ""
                    let series = jsonTalk["series"] as? String ?? ""
                    let title = jsonTalk["title"] as? String ?? ""
                    var speaker = ""
                    var date = ""
                    var durationDisplay = ""
                    var pdf = ""
                    
                    if let talk = self.FileNameToTalk[fileName] {
                        URL = talk.URL
                        speaker = talk.Speaker
                        date = talk.Date
                        pdf = talk.PDF
                        durationDisplay = talk.DurationDisplay
                    }
                    
                    let seconds = self.convertDurationToSeconds(duration: durationDisplay)
                    
                    let talk =  TalkData(title: title,
                                     url: URL,
                                     fileName: fileName,
                                     date: date,
                                     durationDisplay: durationDisplay,
                                     speaker: speaker,
                                     durationInSeconds: seconds,
                                     pdf: pdf)
                    
                    if doesTalkHaveTranscript(talk: talk) {
                        talk.Title = talk.Title + " [transcript]"
                    }
                    
                    // if series specified, these always go into RecommendedAlbum
                    var seriesAlbum : AlbumData
                    if !series.isEmpty {
                         let seriesKey = "RECOMMENDED" + series
                        if self.KeyToAlbum[seriesKey] == nil {
                            seriesAlbum = AlbumData(title: series, key: seriesKey, section: "", image: speaker, date : date)
                            self.KeyToAlbum[seriesKey] = seriesAlbum
                            self.RecommendedAlbum.albumList.append(seriesAlbum)
                        }
                        seriesAlbum = self.KeyToAlbum[seriesKey]!
                        seriesAlbum.talkList.append(talk)
                        seriesAlbum.totalTalks += 1
                        seriesAlbum.totalSeconds += seconds
                        seriesAlbum.durationDisplay  = self.secondsToDurationDisplay(seconds: seriesAlbum.totalSeconds)

                    } else {
                        album.talkList.append(talk)
                    }
                } // end talk loop
            
            //print("Setting time: ", album.Title, album.totalSeconds)
        } // end Album loop
    }
    
    
    func downloadSanghaActivity() {
        
        /*
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
                return
            }
            //let httpResponse = response as! HTTPURLResponse
            let statusCode = httpResponse.statusCode
            
            if (statusCode != 200) {
                return
            }
            
            // make sure we got data.  including cases where only partial data returned (MIN_EXPECTED_RESPONSE_SIZE is arbitrary)
            guard let responseData = data else {
                return
            }
            if responseData.count < MIN_EXPECTED_RESPONSE_SIZE {
                return
            }
            
            self.SangaTalkHistoryAlbum = []
            self.SangaShareHistoryAlbum = []

            do {
                // get the community talk history
                var talkCount = 0
                var totalSeconds = 0
                let json =  try JSONSerialization.jsonObject(with: responseData) as! [String: AnyObject]
                for talkJSON in json["sangha_history"] as? [AnyObject] ?? [] {
                    
                    let fileName = talkJSON["filename"] as? String ?? ""
                    let datePlayed = talkJSON["date"] as? String ?? ""
                    let timePlayed = talkJSON["time"] as? String ?? ""
                    let city = talkJSON["city"] as? String ?? ""
                    let state = talkJSON["state"] as? String ?? ""
                    let country = talkJSON["country"] as? String ?? ""
                   
                    if let talk = self.FileNameToTalk[fileName] {
                        
                        let talkHistory = TalkHistoryData(fileName: fileName,
                                                          datePlayed: datePlayed,
                                                          timePlayed: timePlayed,
                                                          cityPlayed: city,
                                                          statePlayed: state,
                                                          countryPlayed: country)
                        talkCount += 1
                        totalSeconds += talk.DurationInSeconds
                        self.SangaTalkHistoryAlbum.append(talkHistory)
                        
                        if talkCount >= MAX_TALKHISTORY_COUNT {
                            break
                        }
                    }
                }
                var durationDisplay = self.secondsToDurationDisplay(seconds: totalSeconds)
                var stats = AlbumStats(totalTalks: talkCount, totalSeconds: totalSeconds, durationDisplay: durationDisplay)
                self.SanghaTalkHistoryStats = stats

                // get the community share history
                talkCount = 0
                totalSeconds = 0
                for talkJSON in json["sangha_shares"] as? [AnyObject] ?? [] {
                    
                    let fileName = talkJSON["filename"] as? String ?? ""
                    let dateShared = talkJSON["date"] as? String ?? ""
                    let timeShared = talkJSON["time"] as? String ?? ""
                    let city = talkJSON["city"] as? String ?? ""
                    let state = talkJSON["state"] as? String ?? ""
                    let country = talkJSON["country"] as? String ?? ""
                    
                    if let talk = self.FileNameToTalk[fileName] {
                        
                        let talkHistory = TalkHistoryData(fileName: fileName,
                                                          datePlayed: dateShared,
                                                          timePlayed: timeShared,
                                                          cityPlayed: city,
                                                          statePlayed: state,
                                                          countryPlayed: country)
                        self.SangaShareHistoryAlbum.append(talkHistory)
                        
                        talkCount += 1
                        totalSeconds += talk.DurationInSeconds

                        if talkCount >= MAX_SHAREHISTORY_COUNT {
                            break
                        }
                    }
                 }
                durationDisplay = self.secondsToDurationDisplay(seconds: totalSeconds)
                stats = AlbumStats(totalTalks: talkCount, totalSeconds: totalSeconds, durationDisplay: durationDisplay)
                self.SanghaShareHistoryStats = stats
                
                // lastly get the pluggable DATA albums.  these are optional
                for dataContent in DATA_ALBUMS {
                    
                    talkCount = 0
                    totalSeconds = 0
                    self.KeyToTalks[dataContent] = [TalkData] ()
                    for talkJSON in json[dataContent] as? [AnyObject] ?? [] {
                    
                        let fileName = talkJSON["filename"] as? String ?? ""
                        if let talk = self.FileNameToTalk[fileName] {
                        
                            self.KeyToTalks[dataContent]?.append(talk)
                            talkCount += 1
                            totalSeconds += talk.DurationInSeconds
                        }
                    }
                
                    durationDisplay = self.secondsToDurationDisplay(seconds: totalSeconds)
                    stats = AlbumStats(totalTalks: talkCount, totalSeconds: totalSeconds, durationDisplay: durationDisplay)
                    self.KeyToAlbumStats[dataContent] = stats
                }
            } catch {   // end do catch
            }
            
        }
        task.resume()
 */
    }
    
    func download(talk: TalkData, notifyUI: @escaping  () -> Void) {

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
                talk.unsetTalkAsDownloaded()
                TheDataModel.DownloadInProgress = false
                return
            }
            //let httpResponse = response as! HTTPURLResponse
            let statusCode = httpResponse.statusCode
            
            if (statusCode != 200) {
                talk.unsetTalkAsDownloaded()
                TheDataModel.DownloadInProgress = false
                return
            }
            
            // make sure we got data
            if let responseData = data {
                if responseData.count < MIN_EXPECTED_RESPONSE_SIZE {
                    talk.unsetTalkAsDownloaded()
                    HTTPResultCode = 404
                }
            }
            else {
                talk.unsetTalkAsDownloaded()
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
                    talk.unsetTalkAsDownloaded()
                    TheDataModel.DownloadInProgress = false
                    return
                }
                TheDataModel.DownloadInProgress = false
                talk.setTalkAsDownloaded()
                notifyUI()

            }
            
            TheDataModel.DownloadInProgress = false

        }
        task.resume()
    }

    
    // TIMER FUNCTION
    @objc func getSanghaActivity() {
    
        if isInternetAvailable() == false {
            return
        }

        downloadSanghaActivity()
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

    
    // MARK: Support Functions
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
    
   
    
    func computeAlbumStats(album: AlbumData) {
        
        
        var totalSeconds = 0
        var totalTalks = 0
        
        for talk in album.talkList {
            totalSeconds += talk.DurationInSeconds
            totalTalks += 1
        }

        for childAlbum in album.albumList {
             for talk in childAlbum.talkList {
                totalSeconds += talk.DurationInSeconds
                totalTalks += 1
            }
        }
        
        let durationDisplay = secondsToDurationDisplay(seconds: totalSeconds)
        album.totalTalks = totalTalks
        album.durationDisplay = durationDisplay
    }
    
    
    func computeUserFavoriteStats() {
        var talkCount = 0
        var totalSeconds = 0
        
        
        for (fileName, _) in UserFavorites {
            
            if let talk = FileNameToTalk[fileName] {
                totalSeconds += talk.DurationInSeconds
                talkCount += 1
            }
        }
        let durationDisplay = secondsToDurationDisplay(seconds: totalSeconds)
        
        print("FAVORITE", talkCount, durationDisplay)
        KeyToAlbum[KEY_USER_FAVORITES]?.totalTalks = talkCount
        KeyToAlbum[KEY_USER_FAVORITES]?.durationDisplay = durationDisplay
    }
 
    func computeNotesStats() {
        
        var talkCount = 0
        var totalSeconds = 0
        
        for (fileName, _) in UserNotes {
            
            if let talk = FileNameToTalk[fileName] {
                totalSeconds += talk.DurationInSeconds
                talkCount += 1
            }
        }
        let durationDisplay = secondsToDurationDisplay(seconds: totalSeconds)
        
        print("NOTES", talkCount, durationDisplay)

        KeyToAlbum[KEY_NOTES]?.totalTalks = talkCount
        KeyToAlbum[KEY_NOTES]?.durationDisplay = durationDisplay
    }


    // MARK: Persistant API
    func saveUserAlbumData() {
        
        NSKeyedArchiver.archiveRootObject(TheDataModel.UserAlbums, toFile: UserAlbumData.ArchiveURL.path)
    }
    
    func saveUserNoteData() {
        print("saveUserNoteData", TheDataModel.UserNotes)
        
        NSKeyedArchiver.archiveRootObject(TheDataModel.UserNotes, toFile: UserNoteData.ArchiveURL.path)
    }
    
    func saveUserFavoritesData() {
        
        print("saveUserFavoritesData", TheDataModel.UserFavorites)

        
        NSKeyedArchiver.archiveRootObject(TheDataModel.UserFavorites, toFile: UserFavoriteData.ArchiveURL.path)
    }
    
    func saveUserDownloadData() {
        
        NSKeyedArchiver.archiveRootObject(TheDataModel.UserDownloads, toFile: UserDownloadData.ArchiveURL.path)
    }

    
    func saveTalkHistoryData() {
        
        NSKeyedArchiver.archiveRootObject(TheDataModel.UserTalkHistoryAlbum, toFile: TalkHistoryData.ArchiveTalkHistoryURL.path)
    }
    
    func saveShareHistoryData() {
        
        NSKeyedArchiver.archiveRootObject(TheDataModel.UserShareHistoryAlbum, toFile: TalkHistoryData.ArchiveShareHistoryURL.path)
    }
    
    // CJM
    func savePlayedTalksData() {
         
         NSKeyedArchiver.archiveRootObject(PlayedTalks, toFile: PlayedTalks_ArchiveURL.path)
     }
    
    func loadUPlayedTalksData() -> [String: Bool]  {
        
        if let playedTalks = NSKeyedUnarchiver.unarchiveObject(withFile: PlayedTalks_ArchiveURL.path)
            as? [String: Bool] {
            
            return playedTalks
        } else {
            
            return [String: Bool] ()
        }
    }

    
    func loadUserAlbumData() -> [UserAlbumData]  {
        
        if let userAlbumData = NSKeyedUnarchiver.unarchiveObject(withFile: UserAlbumData.ArchiveURL.path) as? [UserAlbumData] {
            
            return userAlbumData
        } else {
            
            return [UserAlbumData] ()
        }
    }
    
    func loadUserNoteData() -> [String: UserNoteData]  {
        
        if let userNotes = NSKeyedUnarchiver.unarchiveObject(withFile: UserNoteData.ArchiveURL.path)
            as? [String: UserNoteData] {
            
            return userNotes
        } else {
            
            return [String: UserNoteData] ()
        }
    }
    
    func loadUserFavoriteData() -> [String: UserFavoriteData]  {
        
        if let userFavorites = NSKeyedUnarchiver.unarchiveObject(withFile: UserFavoriteData.ArchiveURL.path)
            as? [String: UserFavoriteData] {
            
            return userFavorites
        } else {
            
            return [String: UserFavoriteData] ()
        }
    }
    
    func loadUserDownloadData() -> [String: UserDownloadData]  {
        
        if let userDownloads = NSKeyedUnarchiver.unarchiveObject(withFile: UserDownloadData.ArchiveURL.path)
            as? [String: UserDownloadData] {
            
            return userDownloads
        } else {
            
            return [String: UserDownloadData] ()
        }
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
            }
        }
    }

    func loadTalkHistoryData() -> [TalkHistoryData]  {
        
        if let talkHistory = NSKeyedUnarchiver.unarchiveObject(withFile: TalkHistoryData.ArchiveTalkHistoryURL.path)
            as? [TalkHistoryData] {
            
            return talkHistory
        } else {
            
            return [TalkHistoryData] ()
        }
        
    }
    
    func loadShareHistoryData() -> [TalkHistoryData]  {
        
        if let talkHistory = NSKeyedUnarchiver.unarchiveObject(withFile: TalkHistoryData.ArchiveShareHistoryURL.path)
            as? [TalkHistoryData] {
            
            return talkHistory
        } else {
            
            return [TalkHistoryData] ()
        }
    }
    
    func getAlbumData(key: String, filter: String) -> [AlbumData] {

        var searchResults = [AlbumData] ()

        
        if filter == "TEST" {
            let test = AlbumData(title: "test", key: "test", section: "", image: "speaker", date: "01-01-01")
            var testa = [test]
            for i in 1 ... 100 {
                testa.append(test)
            }
            return testa
        }
  
        let listAlbums = KeyToAlbum[key]?.albumList ?? []
        
        
        if filter.isEmpty {
            return listAlbums
        } else {

            for album in listAlbums {
                let searchedData = album.Title.lowercased()
                if searchedData.contains(filter.lowercased()) {searchResults.append(album)}
            }
        }
        return searchResults
    }
       
       
    // CJM DEV
    func getTalks(key: String, filter: String = "") -> [TalkData] {

        var talkList : [TalkData]
        var searchResults = [TalkData] ()

        switch key {
        case KEY_NOTES:
            var talks = [TalkData] ()
            for (fileName, _) in UserNotes {
                if let talk = FileNameToTalk[fileName] {
                    talks.append(talk)
                }
            }
            talkList  = talks.sorted(by: { $0.Date < $1.Date }).reversed()

        case KEY_USER_FAVORITES:
            var talks = [TalkData] ()
            for (fileName, _) in UserFavorites {
                if let talk = FileNameToTalk[fileName] {
                    talks.append(talk)
                }
            }
            talkList  = talks.sorted(by: { $0.Date < $1.Date }).reversed()

        case KEY_USER_DOWNLOADS:
            var talks = [TalkData] ()
            for (fileName, _) in UserDownloads {
                if let talk = FileNameToTalk[fileName] {
                    talks.append(talk)
                }
            }
            talkList  = talks.sorted(by: { $0.Date < $1.Date }).reversed()
            
        default:
            talkList = KeyToAlbum[key]?.talkList  ?? []
        }

        if filter.isEmpty {
            return talkList
        } else {
            for talk in talkList {
                let searchedData = talk.Title.lowercased() + " " + talk.Speaker.lowercased()
                if searchedData.contains(filter.lowercased()) {searchResults.append(talk)}
            }
            return searchResults

        }
    }

    
 
    

    
    func getTalkHistory(content: String) -> [TalkHistoryData] {
        
        var talkHistoryList : [TalkHistoryData]
        
        switch content {
            
        case KEY_USER_TALKHISTORY:
            var talkHistories = [TalkHistoryData] ()
            for talkHistory in UserTalkHistoryAlbum {
                if let _ = FileNameToTalk[talkHistory.FileName] {
                    talkHistories.append(talkHistory)
                }
            }
            talkHistoryList =  talkHistories.reversed()
            
        case KEY_USER_SHAREHISTORY:
            var talkHistories = [TalkHistoryData] ()
            for talkHistory in UserShareHistoryAlbum {
                if let _ = FileNameToTalk[talkHistory.FileName] {
                    talkHistories.append(talkHistory)
                }
            }
            talkHistoryList =  talkHistories.reversed()
            
        case KEY_SANGHA_TALKHISTORY:
            var talkHistories = [TalkHistoryData] ()
            for talkHistory in SangaTalkHistoryAlbum {
                if let _ = FileNameToTalk[talkHistory.FileName] {
                    talkHistories.append(talkHistory)
                }
            }
            talkHistoryList =  talkHistories
            
        case KEY_SANGHA_SHAREHISTORY:
            var talkHistories = [TalkHistoryData] ()
            for talkHistory in SangaShareHistoryAlbum {
                if let _ = FileNameToTalk[talkHistory.FileName] {
                    talkHistories.append(talkHistory)
                }
            }
            talkHistoryList =  talkHistories
            
        default:
            fatalError("No such key")
        }
        
        return talkHistoryList
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
    
    func addUserAlbum(album: UserAlbumData) {
        
        UserAlbums.append(album)
        
        saveUserAlbumData()
        //computeUserAlbumStats()
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
    
    
    func getTalkForName(name: String) -> TalkData? {
        
        return FileNameToTalk[name]
    }
    
    func isMostRecentTalk(talk: TalkData) -> Bool {
    
        if let talkHistory = UserTalkHistoryAlbum.last {
            if talkHistory.FileName == talk.FileName {
                return true
            }
        }
        return false
    }
    
    func addToTalkHistory(talk: TalkData) {
        
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        let datePlayed = formatter.string(from: date)
        
        formatter.dateFormat = "HH:mm:ss"
        let timePlayed = formatter.string(from: date)
        
        let cityPlayed = ""
        let statePlayed = ""
        let countryPlayed = ""

        // CJM
        self.PlayedTalks[talk.FileName] = true
        let talkHistory = TalkHistoryData(fileName: talk.FileName,
                                          datePlayed: datePlayed,
                                          timePlayed: timePlayed,
                                          cityPlayed: cityPlayed,
                                          statePlayed: statePlayed,
                                          countryPlayed: countryPlayed )
        
        UserTalkHistoryAlbum.append(talkHistory)
        
        let excessTalkCount = UserTalkHistoryAlbum.count - MAX_HISTORY_COUNT
        if excessTalkCount > 0 {
            for _ in 0 ... excessTalkCount {
                UserTalkHistoryAlbum.remove(at: 0)
            }
        }
        
        // save the data, recompute stats, reload root view to display updated stats
        savePlayedTalksData()   // CJM
        saveTalkHistoryData()
        //computeTalkHistoryStats()
    }
    
    func addToShareHistory(talk: TalkData) {
        
        
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        let datePlayed = formatter.string(from: date)
        formatter.dateFormat = "HH:mm:ss"
        let timePlayed = formatter.string(from: date)
        
        let cityPlayed = ""
        let statePlayed = ""
        let countryPlayed = ""
        
        let talkHistory = TalkHistoryData(fileName: talk.FileName,
                                          datePlayed: datePlayed,
                                          timePlayed: timePlayed,
                                          cityPlayed: cityPlayed,
                                          statePlayed: statePlayed,
                                          countryPlayed: countryPlayed )

        UserShareHistoryAlbum.append(talkHistory)
        
        let excessTalkCount = UserShareHistoryAlbum.count - MAX_HISTORY_COUNT
        if excessTalkCount > 0 {
            for _ in 0 ... excessTalkCount {
                UserShareHistoryAlbum.remove(at: 0)
            }
        }
        
        // save the data, recompute stats, reload root view to display updated stats
        saveShareHistoryData()
        //computeShareHistoryStats()
    }
    
     
     
    // CJM
    func hasTalkBeenPlayed(talk: TalkData) -> Bool {
    
        if let _ = PlayedTalks[talk.FileName]  {
            return true
        }
        return false
    } 

    
        
    
    func secondsToDurationDisplay(seconds: Int) -> String {
        
        let hours = seconds / 3600
        let modHours = seconds % 3600
        let minutes = modHours / 60
        let seconds = modHours % 60
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = NumberFormatter.Style.decimal
        let hoursStr = numberFormatter.string(from: NSNumber(value:hours)) ?? "0"
        
        let minutesStr = String(format: "%02d", minutes)
        let secondsStr = String(format: "%02d", seconds)
        
        return hoursStr + ":" + minutesStr + ":" + secondsStr
    }
    
    func convertDurationToSeconds(duration: String) -> Int {
        
        var totalSeconds: Int = 0
        var hours : Int = 0
        var minutes : Int = 0
        var seconds : Int = 0
        if duration != "" {
            let durationArray = duration.components(separatedBy: ":")
            let count = durationArray.count
            if (count == 3) {
                hours  = Int(durationArray[0])!
                minutes  = Int(durationArray[1])!
                seconds  = Int(durationArray[2])!
            } else if (count == 2) {
                hours  = 0
                minutes  = Int(durationArray[0])!
                seconds  = Int(durationArray[1])!
                
            } else if (count == 1) {
                hours = 0
                minutes  = 0
                seconds  = Int(durationArray[0])!
                
            } else {
            }
        }
        totalSeconds = (hours * 3600) + (minutes * 60) + seconds
        return totalSeconds
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
    
    func doesTalkHaveTranscript(talk: TalkData) -> Bool {
        
        if talk.PDF.lowercased().range(of:"http:") != nil {
            return true
        }
        else if talk.PDF.lowercased().range(of:"https:") != nil {
            return true
        } else {
            return false
        }
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
    
    func log(error: NSError) {
        
    }
    
    
    
}
    

