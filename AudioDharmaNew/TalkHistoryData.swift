//
//  TalkHistoryData.swift
//  AudioDharmaNew
//
//  Created by Christopher on 9/1/21.
//

import Foundation

import UIKit
import os.log


class TalkHistoryData: NSObject, NSCoding {
    
    // MARK: Persistance
    struct PropertyKey {
        static let FileName = "FileName"
        static let DatePlayed = "DatePlayed"
        static let TimePlayed = "TimePlayed"
        static let CityPlayed = "CityPlayed"
        static let StatePlayed = "StatePlayed"
        static let CountryPlayed = "CountryPlayed"
    }
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveTalkHistoryURL = DocumentsDirectory.appendingPathComponent("ArchiveTalkHistory")
    static let ArchiveShareHistoryURL = DocumentsDirectory.appendingPathComponent("ArchiveShareHistory")

    
    // MARK: Properties
    var FileName: String = ""
    var DatePlayed: String = ""
    var TimePlayed: String = ""
    var CityPlayed: String = ""
    var StatePlayed: String = ""
    var CountryPlayed: String = ""
  
    
    // MARK: Init
    init(fileName: String, datePlayed: String, timePlayed: String, cityPlayed: String, statePlayed: String, countryPlayed: String) {
        FileName = fileName
        DatePlayed = datePlayed
        TimePlayed = timePlayed
        CityPlayed = cityPlayed
        StatePlayed = statePlayed
        CountryPlayed = countryPlayed
    }
    
    
    // MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        
        aCoder.encode(FileName, forKey: PropertyKey.FileName)
        aCoder.encode(DatePlayed, forKey: PropertyKey.DatePlayed)
        aCoder.encode(TimePlayed, forKey: PropertyKey.TimePlayed)
        aCoder.encode(CityPlayed, forKey: PropertyKey.CityPlayed)
        aCoder.encode(StatePlayed, forKey: PropertyKey.StatePlayed)
        aCoder.encode(CountryPlayed, forKey: PropertyKey.CountryPlayed)
   }
    
    required convenience init?(coder aDecoder: NSCoder) {
        
        guard let fileName = aDecoder.decodeObject(forKey: PropertyKey.FileName) as? String else {
            return nil
        }
        guard let datePlayed = aDecoder.decodeObject(forKey: PropertyKey.DatePlayed) as? String else {
            return nil
        }
        guard let timePlayed = aDecoder.decodeObject(forKey: PropertyKey.TimePlayed) as? String else {
            return nil
        }
        guard let cityPlayed = aDecoder.decodeObject(forKey: PropertyKey.CityPlayed) as? String else {
            return nil
        }
        guard let statePlayed = aDecoder.decodeObject(forKey: PropertyKey.StatePlayed) as? String else {
            return nil
        }
        guard let countryPlayed = aDecoder.decodeObject(forKey: PropertyKey.CountryPlayed) as? String else {
            return nil
        }
       
        
        self.init(fileName: fileName,
                  datePlayed: datePlayed,
                  timePlayed: timePlayed,
                  cityPlayed: cityPlayed,
                  statePlayed: statePlayed,
                  countryPlayed: countryPlayed
        )
    }
}
