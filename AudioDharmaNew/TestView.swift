//
//  TalkListView.swift
//
//  General talks view.
//
//  Created by Christopher Minson on 9/9/21.
//  Copyright © 2022 Christopher Minson. All rights reserved.
//

import SwiftUI
import UIKit


struct TestRow: View {

        
    
    
    var body: some View {
                
        VStack(alignment: .leading) {
                Text("here")
            
        }
    }
}


struct TestView: View {
    @ObservedObject var album: AlbumData


    @State var searchText: String  = ""



    init(album: AlbumData) {
        
        self.album = album

    }
    

    var body: some View {

        SearchBar(text: $searchText)
           .padding(.top, 0)
        List(album.getFilteredTalks(filter: searchText), id: \.self) { talk in
            
            TestRow()
 
        }
         .navigationBarTitle(album.Title, displayMode: .inline)
         .navigationBarHidden(false)
         .listStyle(PlainListStyle())  // ensures fills parent view
         .navigationViewStyle(StackNavigationViewStyle())
        
         

    }

}



