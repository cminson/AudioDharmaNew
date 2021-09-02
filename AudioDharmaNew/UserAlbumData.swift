//
//  UserAlbumData.swift
//  AudioDharmaNew
//
//  Created by Christopher on 9/1/21.
//

import Foundation

import UIKit
import os.log

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
    
    
    
    
