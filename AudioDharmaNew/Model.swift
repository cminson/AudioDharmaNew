
//
//  Model.swift
//  AudioDharmaNew
//
//  Created by Christopher on 6/22/17.
//  Copyright © 2017 Christopher Minson. All rights reserved.
//

import UIKit
import Foundation
import SystemConfiguration
import os.log
import ZipArchive



// MARK: Global Constants and Vars
let TheDataModel = Model()
var TheUserLocation = UserLocation()
let DEVICE_ID = UIDevice.current.identifierForVendor!.uuidString
let ModelUpdateSemaphore = DispatchSemaphore(value: 1)  // guards underlying dicts and lists
let ModelLoadedSemaphore = DispatchSemaphore(value: 0)  // guards underlying dicts and lists


// all possible web config points
let HostAccessPoints: [String] = [
    "http://www.virtualdharma.org",
    "http://www.audiodharma.org"
]
var HostAccessPoint: String = HostAccessPoints[0]   // the one we're currently using

// paths for services

//let CONFIG_JSON_NAME = "CONFIG00.JSON"
//let CONFIG_ZIP_NAME = "CONFIG00.ZIP"

let CONFIG_JSON_NAME = "DEV.JSON"
let CONFIG_ZIP_NAME = "DEV.ZIP"


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

struct AlbumStats {         // where stats on each album is kept
    var totalTalks: Int
    var totalSeconds: Int
    var durationDisplay: String
}
struct UserLocation {       // where user geo info is kept
    var city: String = " "
    var state: String = " "
    var country: String = " "
    var zip: String = " "
    var altitude: Double = 0
    var latitude: Double = 0
    var longitude: Double = 0
}
enum ALBUM_SERIES {                   // all possible states of series displays
    case ALL
    case RECOMMENDED
}
enum ACTIVITIES {          // all possible activities that are reported back to cloud
    case SHARE_TALK
    case PLAY_TALK
}

// App Global Constants
// talk and album display states.  these are used throughout the app to key on state
let KEY_HELP = "KEY_HELP"
let KEY_ALBUMROOT = "KEY_ALBUMROOT"
let KEY_TALKS = "KEY_TALKS"

//CJM DEV
//let KEY_ALLTALKS = "KEY_ALLTALKS"
let KEY_ALLTALKS = "EN_ALL_TALKS"

let KEY_SIMILAR_TALKS = "KEY_SIMILARTALKS"
let KEY_SUGGESTED_TALKS = "KEY_SUGGESTEDTALKS"
let KEY_GIL_FRONSDAL = "Gil Fronsdal"
let KEY_ANDREA_FELLA = "Andrea Fella"
let KEY_ALLSPEAKERS = "KEY_ALLSPEAKERS"
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

let BUTTON_SIMILAR_COLOR = UIColor(red:0.80, green:0.12, blue:0.00, alpha:1.0)     //  red #CC1F00
let BUTTON_FAVORITE_COLOR = UIColor(red:1.00, green:0.55, blue:0.00, alpha:1.0)     //  orange #ff8c00
let BUTTON_NOTE_COLOR = UIColor(red:0.00, green:0.34, blue:0.80, alpha:1.0)     //  blue #0057CC
let BUTTON_SHARE_COLOR = UIColor(red:0.38, green:0.73, blue:0.08, alpha:1.0)     //  green #62b914
let BUTTON_DOWNLOAD_COLOR = UIColor(red:0.80, green:0.12, blue:0.00, alpha:1.0)     //  red #CC1F00
let BUTTON_PLAYED_COLOR = UIColor(red:0.38, green:0.73, blue:0.08, alpha:1.0)     //  green #62b914

let APP_ICON_COLOR = UIColor(red:0.38, green:0.73, blue:0.08, alpha:1.0)     //  green #62b914

let SECTION_BACKGROUND = UIColor.darkGray  // #555555ff
let MAIN_FONT_COLOR = UIColor.darkGray      // #555555ff
let SECONDARY_FONT_COLOR = UIColor.gray
let SECTION_TEXT = UIColor.white

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

var HELP_PAGE = "<strong>Help is currently not available. Check your connection or try again later.</strong>"      // where the Help Page data goes


let SCREEN_SIZE = UIScreen.main.bounds.size
let SCREEN_WIDTH = SCREEN_SIZE.width
let SCREEN_HEIGHT = SCREEN_SIZE.height

enum SCREEN_TYPES {
    case SMALL
    case MEDIUM
    case LARGE

}
var SCREEN_TYPE  = SCREEN_TYPES.SMALL

var SIMILAR_MENU_ITEM = "Similar"   // displayed in Talk menus, adjusted at load time based off screen size

class Model {
    
    //MARK: Properties
    var RootAlbums: [AlbumData] = []   //  array of Albums
    var SpeakerAlbums: [AlbumData] = []     // array of Albums for all speakers
    var SeriesAlbums: [AlbumData] = []     // array of Albums for all series
    var RecommendedAlbums: [AlbumData] = []     // array of recommended Albums

    var KeyToTalks : [String: [TalkData]] = [:]  // dictionary keyed by content, value is array of talks
    var KeyToAlbumStats: [String: AlbumStats] = [:] // dictionary keyed by content, value is stat struct for Albums
    var FileNameToTalk: [String: TalkData]   = [String: TalkData] ()  // dictionary keyed by talk filename, value is the talk data (used by userList code to lazily bind)

    var UserTalkHistoryAlbum: [TalkHistoryData] = []    // history of talks for user

    var FileNameToUserTalkHistory: [String: TalkHistoryData]   = [String: TalkHistoryData] ()  //
 
    var UserTalkHistoryStats: AlbumStats!
    var UserShareHistoryAlbum: [TalkHistoryData] = []   // history of shared talks for user
    
    var SangaTalkHistoryAlbum: [TalkHistoryData] = []          // history of talks for sangha
    var SanghaTalkHistoryStats: AlbumStats!
    
    var SangaShareHistoryAlbum: [TalkHistoryData] = []          // history of shares for sangha
    var SanghaShareHistoryStats: AlbumStats!
    
    var AllTalks: [TalkData] = []

    
    var DownloadInProgress = false
    
    let CurrentLanguage = Locale.current.languageCode


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
        
        RootAlbums = []
        SpeakerAlbums = []
        SeriesAlbums = []
        RecommendedAlbums = []
        
        KeyToTalks  = [:]
        
        KeyToAlbumStats = [:]
        FileNameToTalk = [String: TalkData] ()
        UserTalkHistoryAlbum = []
        UserShareHistoryAlbum = []
        
        SangaTalkHistoryAlbum = []
        SangaShareHistoryAlbum = []
        
        AllTalks = []
        
        DownloadInProgress = false
        
        UpdatedTalksJSON = [String: AnyObject] ()
        
        UserAlbums = []
        UserNotes = [:]
        UserFavorites = [:]
        UserDownloads = [:]
        
        for dataContent in DATA_ALBUMS {
            self.KeyToTalks[dataContent] = [TalkData] ()
        }
    }
    
    func loadAllData() {
        
        print("loadAllData")
        
        RootAlbums = []
        SpeakerAlbums = []
        SeriesAlbums = []
        RecommendedAlbums = []
        KeyToTalks  = [:]
        KeyToAlbumStats = [:]
        FileNameToTalk = [String: TalkData] ()
        UserTalkHistoryAlbum = []
        UserShareHistoryAlbum = []
        SangaTalkHistoryAlbum  = []
        SangaShareHistoryAlbum = []

        AllTalks = []
        
        HTTPResultCode = 0
        URL_CONFIGURATION = HostAccessPoint + CONFIG_ACCESS_PATH
        URL_REPORT_ACTIVITY = HostAccessPoint + CONFIG_REPORT_ACTIVITY_PATH
        URL_GET_ACTIVITY = HostAccessPoint + CONFIG_GET_ACTIVITY_PATH
        
        // MUST be done before calling downloadAndConfigure, as that computes
        // stats and that in turn relies on KeyToTalks not being nil (which I do check for, but
        // let's overkill it here just in case
        for dataContent in DATA_ALBUMS {
            self.KeyToTalks[dataContent] = [TalkData] ()
        }

        downloadAndConfigure(path: URL_CONFIGURATION)
        
        // get sangha activity and set up timer for updates
        print("calling downloadSanghaActivity from loadData")
        //CJM DEV - seems wrong
        //downloadSanghaActivity()
        
        // build the data directories on device, if needed
        let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        //print("DocumentPath: ", documentPath)
        MP3_DOWNLOADS_PATH = documentPath + "/DOWNLOADS"
        
        do {
            try FileManager.default.createDirectory(atPath: MP3_DOWNLOADS_PATH, withIntermediateDirectories: false, attributes: nil)
        } catch let error as NSError {
            print(error.localizedDescription);
        }
        
        if SCREEN_WIDTH > 400 {
            SCREEN_TYPE = SCREEN_TYPES.LARGE
            SIMILAR_MENU_ITEM = "similar"
        } else if SCREEN_WIDTH > 350 {
            SCREEN_TYPE = SCREEN_TYPES.MEDIUM
            SIMILAR_MENU_ITEM = "more"
        } else {
            SCREEN_TYPE = SCREEN_TYPES.SMALL
            SIMILAR_MENU_ITEM = "++"

        }
    }
    
    func startBackgroundTimers() {
        
        Timer.scheduledTimer(timeInterval: TimeInterval(UPDATE_SANGHA_INTERVAL), target: self, selector: #selector(getSanghaActivity), userInfo: nil, repeats: true)
    }
    
    
    func downloadSimilarityData(talkFileName: String) {
    
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
                    print(error)
                }
            }
        
            //TheDataModel.refreshAllControllers()
        }
        task.resume()

    }
    
    
    
    func setHelpPage() {
        
        // default help page
        if let asset = NSDataAsset(name: KEY_HELP, bundle: Bundle.main) {
            HELP_PAGE = String(data: asset.data, encoding: .utf8)!
        }

        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        let session = URLSession.init(configuration: config)
        
        let path = URL_GET_HELP
        //let path = "x"

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
                
                
                if let usableData = data {
                    
                    let responseData = String(data: usableData, encoding: String.Encoding.utf8)
                    HELP_PAGE = responseData!
                }
            }
            
            //TheDataModel.refreshAllControllers()
        }
        task.resume()
        
    }
    
    func getFileData(filePath: String) -> [UInt8]? {
        // See if the file exists.
        
        let url = URL(fileURLWithPath: filePath)
        
        do {
            // Get the raw data from the file.
            let rawData: Data = try Data(contentsOf: url)

            // Return the raw data as an array of bytes.
            return [UInt8](rawData)
        } catch {
            // Couldn't read the file.
            return nil
        }
    }
    
    
    // MARK: Configuration
    func downloadAndConfigure(path: String)  {
        
        print("downloadAndConfigure")
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
            
                //print("Storing Zip To: ", configZipPath)
                do {
                    if let responseData = data {
                        try responseData.write(to: URL(fileURLWithPath: configZipPath))
                    }
                }
                catch let error as NSError {
                    print("Failed writing to URL: \(configZipPath), Error: " + error.localizedDescription)  // fatal
                    return
                }
            }
            
            //CJM DEV
            if SSZipArchive.unzipFile(atPath: configZipPath, toDestination: documentPath) != true {
                print("Failed UnZip: \(configZipPath)")
                HTTPResultCode = 404
                let alert = UIAlertController(title: "No Internet Connection", message: "Please check your connection.", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
                //self.RootController?.present(alert, animated: true, completion: nil)
                //self.RootController?.reportModelLoaded()

                return
            }

             

            //let time2 = Date.timeIntervalSinceReferenceDate
            //print("Zip time: ", time2 - time1)

            // get our unzipped json from the local storage and process it
            var jsonData: Data!
            do {
                jsonData = try Data(contentsOf: URL(fileURLWithPath: configJSONPath))
            }
            catch let error as NSError {
                print("Failed getting URL: \(configJSONPath), Error: " + error.localizedDescription)
                HTTPResultCode = 404
                return
            }
                        
            // BEGIN CRITICAL SECTION
            ModelUpdateSemaphore.wait()
            
            do {
                let jsonDict =  try JSONSerialization.jsonObject(with: jsonData) as! [String: AnyObject]
                self.loadConfig(jsonDict: jsonDict)
                self.loadTalks(jsonDict: jsonDict)
                self.loadAlbums(jsonDict: jsonDict)
                //self.downloadSanghaActivity()
            }
            catch {
                print(error)
            }
            
            self.computeRootAlbumsStats()
            self.computeSpeakerStats()
            self.computeSeriesStats()
            self.computeRecommendedStats()
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
            
            // CJM
            for talk in self.UserTalkHistoryAlbum {
                self.PlayedTalks[talk.FileName] = true
            }
             

            self.UserShareHistoryAlbum = TheDataModel.loadShareHistoryData()
            self.computeShareHistoryStats()

            
            print("Model Signaling Loaded")
            ModelUpdateSemaphore.signal()
            ModelLoadedSemaphore.signal()
            // END CRITICAL SECTION
            
            //self.RootController?.reportModelLoaded()
            //TheDataModel.refreshAllControllers()
        }
        task.resume()
    }
    
    
    func loadConfig(jsonDict: [String: AnyObject]) {
        
        if let config = jsonDict["config"] {
            print("URL_MP3_HOST: ", config["URL_MP3_HOST"] as? String )

            URL_MP3_HOST = config["URL_MP3_HOST"] as? String ?? URL_MP3_HOST
            print("URL_MP3_HOST: ", URL_MP3_HOST)

            USE_NATIVE_MP3PATHS = config["USE_NATIVE_MP3PATHS"] as? Bool ?? USE_NATIVE_MP3PATHS
            //print("User Native MP3 Paths: ", USE_NATIVE_MP3PATHS)
        
            URL_REPORT_ACTIVITY = config["URL_REPORT_ACTIVITY"] as? String ?? URL_REPORT_ACTIVITY
            URL_GET_ACTIVITY = config["URL_GET_ACTIVITY"] as? String ?? URL_GET_ACTIVITY
            print("URL_GET_ACTIVITY: ", URL_GET_ACTIVITY)

            URL_DONATE = config["URL_DONATE"] as? String ?? URL_DONATE
        
            MAX_TALKHISTORY_COUNT = config["MAX_TALKHISTORY_COUNT"] as? Int ?? MAX_TALKHISTORY_COUNT
            MAX_SHAREHISTORY_COUNT = config["MAX_SHAREHISTORY_COUNT"] as? Int ?? MAX_SHAREHISTORY_COUNT
            UPDATE_SANGHA_INTERVAL = config["UPDATE_SANGHA_INTERVAL"] as? Int ?? UPDATE_SANGHA_INTERVAL
        }
    }
    
    
    func loadTalks(jsonDict: [String: AnyObject]) {
        
        print("loadTalks")
        var talkCount = 0
        var totalSeconds = 0
        
        // get all talks
        for talk in jsonDict["talks"] as? [AnyObject] ?? [] {
                
                let series = talk["series"] as? String ?? ""
                let title = talk["title"] as? String ?? ""
                let URL = (talk["url"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                let speaker = talk["speaker"] as? String ?? ""
                var date = talk["date"] as? String ?? ""
                date = date.replacingOccurrences(of: "-", with: ".")
                let duration = talk["duration"] as? String ?? ""
                let pdf = talk["pdf"] as? String ?? ""

                let section = ""
                
                let terms = URL.components(separatedBy: "/")
                let fileName = terms.last ?? ""
                
                //print("INSIDE LOAD TALKS")
                //print(title, URL, duration)
                let seconds = self.convertDurationToSeconds(duration: duration)
                totalSeconds += seconds
            
                var talkData =  TalkData(title: title,
                                         url: URL,
                                         fileName: fileName,
                                         date: date,
                                         durationDisplay: duration,
                                         speaker: speaker,
                                         section: section,
                                         durationInSeconds: seconds,
                                         pdf: pdf)
                        
                if doesTalkHaveTranscript(talk: talkData) {
                    talkData.Title = talkData.Title + " [transcript]"
                }
            
                self.FileNameToTalk[fileName] = talkData
                
                // add this talk to  list of all talks
                // Note: there is only one talk section for KEY_ALLTALKS.  all talks are stored in that section
                self.AllTalks.append(talkData)
                
                // add talk to the list of talks for this speaker
                // Note: there is only one talk section for speaker. talks for this speaker are stored in that section
                if self.KeyToTalks[speaker] == nil {
                    self.KeyToTalks[speaker] = [TalkData] ()
                    self.KeyToTalks[speaker]?.append(talkData)
                    
                    // create a Album for this speaker and add to array of speaker Albums
                    // this array will be referenced by SpeakersController
                    let albumData =  AlbumData(title: speaker, content: speaker, section: "", image: speaker, date: date)
                    self.SpeakerAlbums.append(albumData)
                }
                else {
                    self.KeyToTalks[speaker]?.append(talkData)
                }
                
                // if a series is specified, add to a series list
                if series.count > 1 {
                    
                    let seriesKey = "SERIES" + series

                    if self.KeyToTalks[seriesKey] == nil {
                        self.KeyToTalks[seriesKey] = [TalkData] ()
                        self.KeyToTalks[seriesKey]?.append(talkData)
                        
                        // create a Album for this series and add to array of series Albums
                        // this array will be referenced by SeriesController
                        let albumData =  AlbumData(title: series, content: seriesKey, section: "", image: speaker, date: date)
                        self.SeriesAlbums.append(albumData)
                    }
                    else {

                        self.KeyToTalks[seriesKey]?.append(talkData)
                    }
                }
                
                talkCount += 1
        }
        
        let durationDisplay = self.secondsToDurationDisplay(seconds: totalSeconds)

        let stats = AlbumStats(totalTalks: talkCount, totalSeconds: totalSeconds, durationDisplay: durationDisplay)
        self.KeyToAlbumStats[KEY_ALLTALKS] = stats
        
        
        //
        // sort the albums
        //
        self.SpeakerAlbums = self.SpeakerAlbums.sorted(by: { $0.Content < $1.Content })
        self.SeriesAlbums = self.SeriesAlbums.sorted(by: { $0.Date > $1.Date })
        self.AllTalks = self.AllTalks.sorted(by: { $0.Date > $1.Date })
        
        // CJM DEV
        /*
        var count = 0
        for talk in self.AllTalks {
            
            print("DEV", talk.URL)
            count += 1
            if (count > 30) {break}
        }
 */

        // also sort all talks in series albums (note: must take possible sections into account)
        for seriesAlbum in self.SeriesAlbums {
            // dharmettes are already sorted and need to be presented with most current talks on top
            // all other series need further sorting, as the most current talks must be at bottom
            if seriesAlbum.Content == "SERIESDharmettes" {
                continue
            }
            if let talkList = KeyToTalks[seriesAlbum.Content] {
                let sortedTalks  = talkList.sorted(by: { $1.Date > $0.Date })
                KeyToTalks[seriesAlbum.Content]? = sortedTalks
            }
        }
        
        
    }
    
    func loadAlbums(jsonDict: [String: AnyObject]) {
        
        print("loadAlbums")
    
        var prevAlbumSection = ""

        for Album in jsonDict["albums"] as? [AnyObject] ?? [] {
            
                let albumSection = Album["section"] as? String ?? ""
                let title = Album["title"] as? String ?? ""
                let albumContent = Album["content"] as? String ?? ""
                let image = Album["image"] as? String ?? ""
                let talkList = Album["talks"] as? [AnyObject] ?? []
                let albumData =  AlbumData(title: title, content: albumContent, section: albumSection, image: image, date: "")
            
                if ((albumSection != "") && (albumSection != prevAlbumSection)) {
                    let albumSectionHeader = AlbumData(title: SECTION_HEADER, content: albumContent, section: albumSection, image: image, date: "")
                    self.RootAlbums.append(albumSectionHeader)
                    prevAlbumSection = albumSection
                }
            
                self.RootAlbums.append(albumData)
                print("Appending: ", albumData)

    
                // get the optional talk array for this Album
                // if exists, store off all the talks in keyToTalks keyed by 'content' id
                // the value for this key is an array of talks
                var currentSeries = "_"
                var prevTalkSection = ""

                for talk in talkList {
                    
                    var URL = talk["url"] as? String ?? ""

                    let terms = URL.components(separatedBy: "/")
                    let fileName = terms.last ?? ""
                    
                    var talkSection = talk["section"] as? String ?? "_"
                    let series = talk["series"] as? String ?? ""
                    let title = talk["title"] as? String ?? ""
                    var speaker = ""
                    var date = ""
                    var durationDisplay = ""
                    var keys = ""
                    var pdf = ""
                    
                    
                    // DEV NOTE: remove placeholder.  this code might not be necessary long-term
                    if talkSection == "_" || talkSection == "__" {
                        talkSection = ""
                    }
                    
                    // fill in these fields from talk data.  must do this as these fields are not stored in config json (to make things
                    // easier for config reading)
                    if let talkData = self.FileNameToTalk[fileName] {
                        URL = talkData.URL
                        speaker = talkData.Speaker
                        date = talkData.Date
                        pdf = talkData.PDF
                        durationDisplay = talkData.DurationDisplay
                    }
                    
                    let totalSeconds = self.convertDurationToSeconds(duration: durationDisplay)
                    
                    
                    var talkData =  TalkData(title: title,
                                             url: URL,
                                             fileName: fileName,
                                             date: date,
                                             durationDisplay: durationDisplay,
                                             speaker: speaker,
                                             section: talkSection,
                                             durationInSeconds: totalSeconds,
                                             pdf: pdf)
                    
                    if doesTalkHaveTranscript(talk: talkData) {
                        talkData.Title = talkData.Title + " [transcript]"
                    }
                    
                    // if a series is specified create a series album if not already there.  then add talk to it
                    // otherwise, just add the talk directly to the parent album
                    if series.count > 1 {
                        
                        if series != currentSeries {
                            currentSeries = series
                        }
                        let seriesKey = "RECOMMENDED" + series
                        
                        // create the album if not there already
                        if self.KeyToTalks[seriesKey] == nil {
                            
                            self.KeyToTalks[seriesKey] = [TalkData] ()
                            let albumData =  AlbumData(title: series, content: seriesKey, section: "", image: "albumdefault", date: date)
                           //let albumData =  AlbumData(title: series, content: seriesKey, section: "", image: speaker, date: date)

                            self.RecommendedAlbums.append(albumData)
                            self.SeriesAlbums.append(albumData)
                        }
                        
                        if ((talkSection != "") && (talkSection != prevTalkSection)) {
                            let talk = TalkData(title: SECTION_HEADER, url: "", fileName: "", date: "", durationDisplay: "",  speaker: "defaultPhoto", section: talkSection, durationInSeconds: 0, pdf: "")
                            self.KeyToTalks[seriesKey]?.append(talk)
                            prevTalkSection = talkSection
                        }
                        
                        // now add talk to this series album
                        self.KeyToTalks[seriesKey]?.append(talkData)
                        
                        
                    } else {
                        
                        if (self.KeyToTalks[albumContent] == nil) { self.KeyToTalks[albumContent] = [TalkData] () }
                        self.KeyToTalks[albumContent]?.append(talkData)
                    }
                }
        } // end Album loop
    }
    
    
    func downloadSanghaActivity() {
        
        print("downloadSanghaActivity")
        //CJM DEV
        return
        
        
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
                    
                    var fileName = talkJSON["filename"] as? String ?? ""
                    let datePlayed = talkJSON["date"] as? String ?? ""
                    let timePlayed = talkJSON["time"] as? String ?? ""
                    let city = talkJSON["city"] as? String ?? ""
                    let state = talkJSON["state"] as? String ?? ""
                    let country = talkJSON["country"] as? String ?? ""
                   
                    //CJM DEV
                    //fileName = "dsfsdfsd"
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
                print(error)
            }
            
            //self.refreshAllControllers()

        }
        task.resume()
    }
    
    func downloadMP3(talk: TalkData) {
        
        var requestURL: URL
        var localPathMP3: String
        
        DownloadInProgress = true
        
        // remote source path for file
        if USE_NATIVE_MP3PATHS == true {
            requestURL  = URL(string: URL_MP3_HOST + talk.URL)!
        } else {
            requestURL  = URL(string: URL_MP3_HOST + "/" + talk.FileName)!
        }
        print("DISPLAYING  \(requestURL) ")
        
        // local destination path for file
        localPathMP3 = MP3_DOWNLOADS_PATH + "/" + talk.FileName
        
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        let session = URLSession.init(configuration: config)
        
        let urlRequest = URLRequest(url : requestURL)
        
        let task = session.dataTask(with: urlRequest) {
            (data, response, error) -> Void in
            
            //print("Download: response seen")

            var httpResponse: HTTPURLResponse
            if let valid_reponse = response {
                httpResponse = valid_reponse as! HTTPURLResponse
            } else {
                //print("No HTTP Response")
                TheDataModel.unsetTalkAsDownload(talk: talk)
                TheDataModel.DownloadInProgress = false
                return
            }
            //let httpResponse = response as! HTTPURLResponse
            let statusCode = httpResponse.statusCode
            
            if (statusCode != 200) {
                //print("Bad HTTP Response: ", statusCode)
                TheDataModel.unsetTalkAsDownload(talk: talk)
                TheDataModel.DownloadInProgress = false
                return
            }
            
            // make sure we got data
            if let responseData = data {
                if responseData.count < MIN_EXPECTED_RESPONSE_SIZE {
                    //print("Bad HTTP Response. Low Count", responseData.count)
                    TheDataModel.unsetTalkAsDownload(talk: talk)
                    HTTPResultCode = 404
                }
            }
            else {
                TheDataModel.unsetTalkAsDownload(talk: talk)
                HTTPResultCode = 404
            }
            
            // if got a good response, store off file locally
            if HTTPResultCode == 200 {
                
                //print("Storing MP3 To: ", localPathMP3)
                do {
                    if let responseData = data {
                        try responseData.write(to: URL(fileURLWithPath: localPathMP3))
                    }
                }
                catch  {
                    //print("Failed writing to URL: \(localPathMP3), Error: " + error.localizedDescription)  // fatal
                    TheDataModel.unsetTalkAsDownload(talk: talk)
                    TheDataModel.DownloadInProgress = false
                    return
                }
                
                self.UserDownloads[talk.FileName]?.DownloadCompleted = "YES"
                self.saveUserDownloadData()
                TheDataModel.DownloadInProgress = false
            }
            
            //self.refreshAllControllers()
            TheDataModel.DownloadInProgress = false

        }
        task.resume()
    }

    
    // TIMER FUNCTION
    @objc func getSanghaActivity() {
        
        print("getSanghaActivity")
    
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
        
        
        let city = TheUserLocation.city
        let state = TheUserLocation.state
        let country = TheUserLocation.country
        let zip = TheUserLocation.zip
        let altitude = TheUserLocation.altitude
        let latitude = TheUserLocation.latitude
        let longitude = TheUserLocation.longitude
        let shareType = "NA"    // TBD
        let deviceType = "iphone"
        
        let urlPhrases = talk.URL.components(separatedBy: "/")
        var fileName = (urlPhrases[urlPhrases.endIndex - 1]).trimmingCharacters(in: .whitespacesAndNewlines)
        fileName = fileName.trimmingCharacters(in: .whitespacesAndNewlines)

        let parameters = "DEVICETYPE=\(deviceType)&DEVICEID=\(DEVICE_ID)&OPERATION=\(operation)&SHARETYPE=\(shareType)&FILENAME=\(fileName)&CITY=\(city)&STATE=\(state)&COUNTRY=\(country)&ZIP=\(zip)&ALTITUDE=\(altitude)&LATITUDE=\(latitude)&LONGITUDE=\(longitude)"

        let url = URL(string: URL_REPORT_ACTIVITY)!
        //print("Report Talk Activity", URL_REPORT_ACTIVITY)
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
    
    func refreshAllControllers() {
        
/*
        DispatchQueue.main.async {
            if let controller = self.RootController {
                controller.reloadModel()
                controller.tableView.reloadData()
            }
        
            if let controller = self.CommunityController {
                controller.reloadModel()
                controller.tableView.reloadData()
            }

            if let controller = self.TalkController {

                controller.reloadModel()
                controller.tableView.reloadData()
            }
            
            if let controller = self.UserTalkController {
                controller.reloadModel()
                controller.tableView.reloadData()
            }

        }
 */
    }

    
    
    func computeRootAlbumsStats() {
        
        for Album in self.RootAlbums {
            
            let talksInAlbum = self.getTalks(content: Album.Content)
            let talkCount = talksInAlbum.count
            
            var totalSeconds = 0
            for talk in talksInAlbum {
                totalSeconds += talk.DurationInSeconds
            }
            
            let durationDisplay = self.secondsToDurationDisplay(seconds: totalSeconds)
            
            let stats = AlbumStats(totalTalks: talkCount, totalSeconds: totalSeconds, durationDisplay: durationDisplay)
            self.KeyToAlbumStats[Album.Content] = stats
        }
    }
    
    //
    // generate the stats for the user-defined albums.
    //
    func computeUserAlbumStats() {
        
        var totalUserListCount = 0
        var totalUserTalkSecondsCount = 0
        
        for userAlbum in UserAlbums {
            
            var talkCount = 0
            var totalSeconds = 0
            for talkName in userAlbum.TalkFileNames {
                if let talk = FileNameToTalk[talkName] {
                    totalSeconds += talk.DurationInSeconds
                    talkCount += 1
                }
            }
            
            totalUserListCount += 1
            totalUserTalkSecondsCount += totalSeconds
            let durationDisplay = secondsToDurationDisplay(seconds: totalSeconds)
            
            let stats = AlbumStats(totalTalks: talkCount, totalSeconds: totalSeconds, durationDisplay: durationDisplay)
            KeyToAlbumStats[userAlbum.Content] = stats
        }
        
        let durationDisplayAllLists = secondsToDurationDisplay(seconds: totalUserTalkSecondsCount)
        let stats = AlbumStats(totalTalks: totalUserListCount, totalSeconds: totalUserTalkSecondsCount, durationDisplay: durationDisplayAllLists)
        
        KeyToAlbumStats[KEY_USER_ALBUMS] = stats
    }
    
    func computeSpeakerStats() {
        
        var totalSecondsAllLists = 0
        var talkCountAllLists = 0
        
        for album in SpeakerAlbums {
            
            let content = album.Content
            var totalSeconds = 0
            var talkCount = 0
            for talk in (KeyToTalks[content])! {
                totalSeconds += talk.DurationInSeconds
                talkCount += 1
            }
            
            talkCountAllLists += talkCount
            totalSecondsAllLists += totalSeconds
            let durationDisplay = secondsToDurationDisplay(seconds: totalSeconds)
            
            let stats = AlbumStats(totalTalks: talkCount, totalSeconds: totalSeconds, durationDisplay: durationDisplay)
            KeyToAlbumStats[content] = stats
        }
        
        let durationDisplayAllLists = secondsToDurationDisplay(seconds: totalSecondsAllLists)
        
        let stats = AlbumStats(totalTalks: talkCountAllLists, totalSeconds: totalSecondsAllLists, durationDisplay: durationDisplayAllLists)
        KeyToAlbumStats[KEY_ALLSPEAKERS] = stats
    }
    
    func computeSeriesStats() {
        
        var totalSecondsAllLists = 0
        var talkCountAllLists = 0
        
        for album in SeriesAlbums {
            
            let content = album.Content
            var totalSeconds = 0
            var talkCount = 0
            for talk in (KeyToTalks[content])! {
                totalSeconds += talk.DurationInSeconds
                talkCount += 1
            }
            
            talkCountAllLists += talkCount
            totalSecondsAllLists += totalSeconds
            let durationDisplay = secondsToDurationDisplay(seconds: totalSeconds)
            
            let stats = AlbumStats(totalTalks: talkCount, totalSeconds: totalSeconds, durationDisplay: durationDisplay)
            KeyToAlbumStats[content] = stats
        }
        
        let durationDisplayAllLists = secondsToDurationDisplay(seconds: totalSecondsAllLists)
        
        let stats = AlbumStats(totalTalks: talkCountAllLists, totalSeconds: totalSecondsAllLists, durationDisplay: durationDisplayAllLists)
        KeyToAlbumStats[KEY_ALL_SERIES] = stats
    }
    
    func computeRecommendedStats() {
        
        var totalSecondsAllLists = 0
        var talkCountAllLists = 0
        
        for album in RecommendedAlbums {
            
            let content = album.Content
            var totalSeconds = 0
            var talkCount = 0
            if let talkList = KeyToTalks[content] {
                for talk in talkList {
                    if talk.Section == SECTION_HEADER { continue }
                    totalSeconds += talk.DurationInSeconds
                    talkCount += 1
                }
            }
        
            talkCountAllLists += talkCount
            totalSecondsAllLists += totalSeconds
            let durationDisplay = secondsToDurationDisplay(seconds: totalSeconds)
            
            let stats = AlbumStats(totalTalks: talkCount, totalSeconds: totalSeconds, durationDisplay: durationDisplay)
            KeyToAlbumStats[content] = stats
        }
        
        let durationDisplayAllLists = secondsToDurationDisplay(seconds: totalSecondsAllLists)
        
        let stats = AlbumStats(totalTalks: talkCountAllLists, totalSeconds: totalSecondsAllLists, durationDisplay: durationDisplayAllLists)
        KeyToAlbumStats[KEY_RECOMMENDED_TALKS] = stats
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
        let stats = AlbumStats(totalTalks: talkCount, totalSeconds: totalSeconds, durationDisplay: durationDisplay)
        
        KeyToAlbumStats[KEY_NOTES] = stats
    }
    
    func computeTalkHistoryStats() {
        
        var talkCount = 0
        var totalSeconds = 0
        
        for talkHistory in UserTalkHistoryAlbum {
            let fileName = talkHistory.FileName
            if let talk = FileNameToTalk[fileName] {
                totalSeconds += talk.DurationInSeconds
                talkCount += 1
            }
        }
        
        let durationDisplay = secondsToDurationDisplay(seconds: totalSeconds)
        let stats = AlbumStats(totalTalks: talkCount, totalSeconds: totalSeconds, durationDisplay: durationDisplay)
        
        KeyToAlbumStats[KEY_USER_TALKHISTORY] = stats
    }
    
    func computeShareHistoryStats() {
        var talkCount = 0
        var totalSeconds = 0
    
        for talkHistory in UserShareHistoryAlbum {
            let fileName = talkHistory.FileName
            if let talk = FileNameToTalk[fileName] {
                totalSeconds += talk.DurationInSeconds
                talkCount += 1
            }
        }
    
        let durationDisplay = secondsToDurationDisplay(seconds: totalSeconds)
        let stats = AlbumStats(totalTalks: talkCount, totalSeconds: totalSeconds, durationDisplay: durationDisplay)
    
        KeyToAlbumStats[KEY_USER_SHAREHISTORY] = stats
    }

    func computeUserFavoritesStats() {
        var talkCount = 0
        var totalSeconds = 0
        
        for (fileName, _) in UserFavorites {
            
            if let talk = FileNameToTalk[fileName] {
                totalSeconds += talk.DurationInSeconds
                talkCount += 1
            }
        }
        let durationDisplay = secondsToDurationDisplay(seconds: totalSeconds)
        let stats = AlbumStats(totalTalks: talkCount, totalSeconds: totalSeconds, durationDisplay: durationDisplay)
        
        KeyToAlbumStats[KEY_USER_FAVORITES] = stats
    }

    func computeUserDownloadStats() {
        var talkCount = 0
        var totalSeconds = 0
        
        for (fileName, _) in UserDownloads {
            
            if let talk = FileNameToTalk[fileName] {
                totalSeconds += talk.DurationInSeconds
                talkCount += 1
            }
        }
        let durationDisplay = secondsToDurationDisplay(seconds: totalSeconds)
        let stats = AlbumStats(totalTalks: talkCount, totalSeconds: totalSeconds, durationDisplay: durationDisplay)
        
        KeyToAlbumStats[KEY_USER_DOWNLOADS] = stats
    }
    
    func computeDataStats() {
        var talkCount = 0
        var totalSeconds = 0
        
        for dataContent in DATA_ALBUMS {
            
            if KeyToTalks[dataContent] == nil {continue}

            for talk in KeyToTalks[dataContent]! {
                totalSeconds += talk.DurationInSeconds
                talkCount += 1
            }
        
            let durationDisplay = secondsToDurationDisplay(seconds: totalSeconds)
            let stats = AlbumStats(totalTalks: talkCount, totalSeconds: totalSeconds, durationDisplay: durationDisplay)
        
            KeyToAlbumStats[dataContent] = stats
        }
    }


    // MARK: Persistant API
    /*
     archiveRootObject(_:toFile:)' was deprecated in iOS 12.0: Use +archivedDataWithRootObject:requiringSecureCoding:error: and -writeToURL:options:error: instead
     */
    func saveUserAlbumData() {
        
        NSKeyedArchiver.archiveRootObject(TheDataModel.UserAlbums, toFile: UserAlbumData.ArchiveURL.path)
    }
    
    func saveUserNoteData() {
        
        NSKeyedArchiver.archiveRootObject(TheDataModel.UserNotes, toFile: UserNoteData.ArchiveURL.path)
    }
    
    func saveUserFavoritesData() {
        
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
            //print("Removing bad download: ", userDownload.FileName)

            do {
                try FileManager.default.removeItem(atPath: localPathMP3)
            }
            catch let error as NSError {
                print("File remove error: \(error)")
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
                        //print("Removing orphan download: ", fileName)

                        do {
                            try FileManager.default.removeItem(atPath: mp3FileURL.path)
                        }
                        catch let error as NSError {
                            print("File remove error: \(error)")
                        }

                    }
                }
            }
            
        } catch {
            print(error.localizedDescription)
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
            
            //print("Removing incomplete download: ", userDownload.FileName)
            UserDownloads[userDownload.FileName] = nil
            let localPathMP3 = MP3_DOWNLOADS_PATH + "/" + userDownload.FileName
            do {
                try FileManager.default.removeItem(atPath: localPathMP3)
            }
            catch let error as NSError {
                print("File remove error: \(error)")
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
    
 
    
    // MARK: API
    func getTalks(content: String) -> [TalkData] {
        
        var talkList : [TalkData]
        
        switch content {
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
            
        case KEY_ALL_SERIES:
            talkList = KeyToTalks[content] ?? [TalkData]()
 
        case KEY_DHARMETTES:    // Dharmettes are just a Series that we've promoted to top level
            talkList = KeyToTalks["SERIESDharmettes"] ?? [TalkData]()
        
        case KEY_ALLTALKS:
            talkList =  AllTalks
            
        case KEY_SUGGESTED_TALKS:
            var talks = [TalkData] ()
            for (fileName, _) in UserDownloads {
                if let talk = FileNameToTalk[fileName] {
                    talks.append(talk)
                }
            }
            talkList = talks
            
        default:
            talkList =  KeyToTalks[content] ?? [TalkData]()

        }
        return talkList
        
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

    
    func getAlbumStats(content: String) -> AlbumStats {
        
        
        var stats: AlbumStats
        
        switch content {
        
        case KEY_ALLTALKS:
            stats = KeyToAlbumStats[content] ?? AlbumStats(totalTalks: 0, totalSeconds: 0, durationDisplay: "0:0:0")
        
        case KEY_SANGHA_TALKHISTORY:
            stats = SanghaTalkHistoryStats ?? AlbumStats(totalTalks: 0, totalSeconds: 0, durationDisplay: "0:0:0")
            
        case KEY_SANGHA_SHAREHISTORY:
            stats = SanghaShareHistoryStats ?? AlbumStats(totalTalks: 0, totalSeconds: 0, durationDisplay: "0:0:0")
            
        default:
            stats =  KeyToAlbumStats[content] ?? AlbumStats(totalTalks: 0, totalSeconds: 0, durationDisplay: "0:0:0")
            
        }
        
        return stats
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
        computeUserAlbumStats()
        //refreshAllControllers()
    }
    
    func removeUserAlbum(at: Int) {
        
        UserAlbums.remove(at: at)
        
        saveUserAlbumData()
        computeUserAlbumStats()
        //refreshAllControllers()
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
        computeUserAlbumStats()
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
        
        let cityPlayed = TheUserLocation.city
        let statePlayed = TheUserLocation.state
        let countryPlayed = TheUserLocation.country

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
        computeTalkHistoryStats()
        refreshAllControllers()
    }
    
    func addToShareHistory(talk: TalkData) {
        
        
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        let datePlayed = formatter.string(from: date)
        formatter.dateFormat = "HH:mm:ss"
        let timePlayed = formatter.string(from: date)
        
        let cityPlayed = TheUserLocation.city
        let statePlayed = TheUserLocation.state
        let countryPlayed = TheUserLocation.country
        
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
        computeShareHistoryStats()
        refreshAllControllers()
    }
    
    func setTalkAsFavorite(talk: TalkData) {
        
        UserFavorites[talk.FileName] = UserFavoriteData(fileName: talk.FileName)
        saveUserFavoritesData()
        computeUserFavoritesStats()
    }
    
    func unsetTalkAsFavorite(talk: TalkData) {
        
        UserFavorites[talk.FileName] = nil
        saveUserFavoritesData()
        computeUserFavoritesStats()
    }

    func toggleTalkAsFavorite(talk: TalkData, controller: UIViewController) {
        
        if isFavoriteTalk(talk: talk) {
            
            unsetTalkAsFavorite(talk: talk)
            
            let alert = UIAlertController(title: "Favorite Talk - Removed", message: "This talk has been removed from your Favorites Album", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            
            controller.present(alert, animated: true, completion: nil)
            
        } else {
            
            setTalkAsFavorite(talk: talk)
            
            let alert = UIAlertController(title: "Favorite Talk - Added", message: "This talk has been added to your Favorites Album", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            
            controller.present(alert, animated: true, completion: nil)

        }
        refreshAllControllers()
    }

    
    
    func isFavoriteTalk(talk: TalkData) -> Bool {
        
        let isFavorite = UserFavorites[talk.FileName] != nil
        return isFavorite
        
    }
    
    func setTalkAsDownload(talk: TalkData) {
        
        UserDownloads[talk.FileName] = UserDownloadData(fileName: talk.FileName, downloadCompleted: "NO")
        saveUserDownloadData()
        computeUserDownloadStats()
        refreshAllControllers()
    }
    
    func unsetTalkAsDownload(talk: TalkData) {
        
        if let userDownload = UserDownloads[talk.FileName] {
            if userDownload.DownloadCompleted == "NO" {
                DownloadInProgress = false
            }
        }
        UserDownloads[talk.FileName] = nil
        let localPathMP3 = MP3_DOWNLOADS_PATH + "/" + talk.FileName
        do {
            try FileManager.default.removeItem(atPath: localPathMP3)
        }
        catch let error as NSError {
            print("File remove error: \(error)")
        }
        
        saveUserDownloadData()
        computeUserDownloadStats()
        refreshAllControllers()
    }
    
    func isDownloadTalk(talk: TalkData) -> Bool {
        
        let isDownload = UserDownloads[talk.FileName] != nil
        return isDownload
        
    }
    
    func isCompletedDownloadTalk(talk: TalkData) -> Bool {
        
        var downloadCompleted = false
        if let userDownload = UserDownloads[talk.FileName]  {
            downloadCompleted = (userDownload.DownloadCompleted == "YES")
        }
        return downloadCompleted
    }
    
    func isDownloadInProgress(talk: TalkData) -> Bool {
        
        var downloadInProgress = false
        if let userDownload = UserDownloads[talk.FileName]  {
            downloadInProgress = (userDownload.DownloadCompleted == "NO")
        }
        return downloadInProgress
    }
    
    // CJM
    func hasTalkBeenPlayed(talk: TalkData) -> Bool {
    
        if let _ = PlayedTalks[talk.FileName]  {
            return true
        }
        return false
    }

    
    func addNoteToTalk(noteText: String, talkFileName: String) {
        
        //
        // if there is a note text for this talk fileName, then save it in the note dictionary
        // otherwise clear this note dictionary entry

        let charset = CharacterSet.alphanumerics

        if (noteText.count > 0) && noteText.rangeOfCharacter(from: charset) != nil {
            UserNotes[talkFileName] = UserNoteData(notes: noteText)
        } else {
            UserNotes[talkFileName] = nil
        }
        
        // save the data, recompute stats, reload root view to display updated stats
        saveUserNoteData()
        computeNotesStats()
        refreshAllControllers()
    }
    
    func getNoteForTalk(talkFileName: String) -> String {
        
        var noteText = ""
        
        if let userNoteData = TheDataModel.UserNotes[talkFileName]   {
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
                print("Exception to duration: \(durationArray)")
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
    
    
    
}
    

