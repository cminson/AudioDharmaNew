//
//  AlbumData.swift
//  AudioDharmaNew
//
//  Created by Christopher on 9/1/21.
//

import Foundation
import UIKit
import os.log

/*
class AlbumData: NSObject {
    
    //MARK: Properties
    var Title: String
    var Content: String
    var Section: String
    var Image: String
    var Date: String
    
    
    init(title: String, content: String, section: String, image: String, date: String) {
        
        Title = title
        Content = content
        Section = section
        Image = image
        Date = date
    }
    
}
 */

struct AlbumData: Identifiable {
    
    //MARK: Properties
    let id = UUID()
    var Title: String
    var Content: String
    var Section: String
    var Image: String
    var Date: String
    
    
    init(title: String, content: String, section: String, image: String, date: String) {
        
        Title = title
        Content = content
        Section = section
        Image = image
        Date = date
    }
    
}

