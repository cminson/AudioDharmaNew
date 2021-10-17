//
//  StoredData.swift
//
//  Class definitions for persistent storage.
//
//
//  Created by Christopher Minson on 9/4/21.
//  Copyright © 2022 Christopher Minson. All rights reserved.
//

import Foundation
import UIKit


class UserNoteData: NSObject, NSCoding {
    
    // MARK: Persistance
    struct PropertyKey {
        static let Notes = "Notes"
    }
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("UserNoteData")
    
    
    // MARK: Properties
    var Notes: String = ""
    
    
    // MARK: Init
    init(notes: String) {
        Notes = notes
    }
    
    
    // MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        
        aCoder.encode(Notes, forKey: PropertyKey.Notes)
     }
    
    required convenience init?(coder aDecoder: NSCoder) {
        
        //print("UserNoteData: Decode")
        guard let notes = aDecoder.decodeObject(forKey: PropertyKey.Notes) as? String else {
            return nil
        }
        
        self.init(notes: notes)
    }
    
}

class UserDownloadData: NSObject, NSCoding {
    
    // MARK: Persistance
    struct PropertyKey {
        static let FileName = "FileName"
        static let DownloadCompleted = "DownloadCompleted"
    }
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("UserDownloadData")
    
    
    // MARK: Properties
    var FileName: String = ""
    var DownloadCompleted: String = ""
    
    
    // MARK: Init
    init(fileName: String, downloadCompleted: String) {
        
        FileName = fileName
        DownloadCompleted = downloadCompleted
    }
    
    
    // MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        
        aCoder.encode(FileName, forKey: PropertyKey.FileName)
        aCoder.encode(DownloadCompleted, forKey: PropertyKey.DownloadCompleted)

    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        
        guard let fileName = aDecoder.decodeObject(forKey: PropertyKey.FileName) as? String else {
            return nil
        }
        guard let downloadCompleted = aDecoder.decodeObject(forKey: PropertyKey.DownloadCompleted) as? String else {
            return nil
        }

        self.init(fileName: fileName, downloadCompleted: downloadCompleted)
    }
    
}

class UserFavoriteData: NSObject, NSCoding {
    
    // MARK: Persistance
    struct PropertyKey {
        static let FileName = "FileName"
    }
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("UserFavoriteData")
    
    
    // MARK: Properties
    var FileName: String = ""
    
    
    // MARK: Init
    init(fileName: String) {
        FileName = fileName
    }
    
    
    // MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        
        aCoder.encode(FileName, forKey: PropertyKey.FileName)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        
        //print("UserNoteData: Decode")
        guard let fileName = aDecoder.decodeObject(forKey: PropertyKey.FileName) as? String else {
            return nil
        }
        
        self.init(fileName: fileName)
    }
    
}

class UserAlbumData: NSObject, NSCoding {
    
    // MARK: Persistance
    struct PropertyKey {
        static let Title = "Title"
        static let TalkFileNames = "TalkFileNames"
        static let Image = "Image"
        static let Content = "Content"
    }
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("UserAlbumData")

    
    // MARK: Properties
    var Title: String = ""
    var TalkFileNames:  [String] = [String] ()
    var Image: UIImage
    var Content: String = "0"

    
    // MARK: Init
    init(title: String, image: UIImage) {
        Title = title
        Image = image
        
        Content = String(arc4random_uniform(10000000))
    }


    init(title: String,  image: UIImage,  content: String, talkFileNames: [String]) {
        Title = title
        Image = image
        Content = content
        
        TalkFileNames = talkFileNames
    }
    
    
    // MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        
        aCoder.encode(Title, forKey: PropertyKey.Title)
        aCoder.encode(Image, forKey: PropertyKey.Image)
        aCoder.encode(Content, forKey: PropertyKey.Content)
        aCoder.encode(TalkFileNames, forKey: PropertyKey.TalkFileNames)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        
        guard let title = aDecoder.decodeObject(forKey: PropertyKey.Title) as? String else {
            return nil
        }
        
        guard let image = aDecoder.decodeObject(forKey: PropertyKey.Image) as? UIImage else {
            return nil
        }
        
        guard let content = aDecoder.decodeObject(forKey: PropertyKey.Content) as? String else {
            return nil
        }

       
        guard let talkFileNames = aDecoder.decodeObject(forKey: PropertyKey.TalkFileNames) as? [String] else {
            return nil
        }
        
        self.init(title: title, image: image, content: content, talkFileNames: talkFileNames)
    }
}
    
    


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
