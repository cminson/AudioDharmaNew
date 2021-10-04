//
//  Common.swift
//  Common shared code
//
//  Created by Christopher Minson on 9/9/21.
//  Copyright © 2022 Christopher Minson. All rights reserved.
//

import SwiftUI
import PDFKit
import WebKit


//
// Global Vars and Constants
//

let ModelUpdateSemaphore = DispatchSemaphore(value: 1)  // guards underlying dicts and lists
let ModelLoadSemaphore = DispatchSemaphore(value: 0)  // guards underlying dicts and lists

let HOMEPAGE_SECTIONS = ["Main Albums", "Personal Albums", "Community Activity"]

let LIST_IMAGE_HEIGHT : CGFloat = 40.0
let LIST_IMAGE_WIDTH : CGFloat = 40.0
let FONT_SIZE_SECTION : CGFloat = 14.0
let LIST_ROW_SIZE_SECTION : CGFloat = 35.0
let LIST_ROW_SIZE_STANDARD : CGFloat = 40.0

let FONT_SIZE_ROW_TITLE : CGFloat = 14
let FONT_SIZE_ROW_ATTRIBUTES : CGFloat = 10

let COLOR_BACKGROUND_SECTION = "555555"

let MAIN_FONT_COLOR = UIColor.darkGray      // #555555ff
let SECONDARY_FONT_COLOR = UIColor.gray

var HELP_PAGE = "<strong>Help is currently not available. Check your connection or try again later.</strong>"      // where the Help Page data goes


/*
 *********************************************************************************
 * Structs
 *********************************************************************************
 */
struct ItemsToolbar: ToolbarContent {
    let add: () -> Void
    let sort: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button("Add", action: add)
        }
        

        ToolbarItem(placement: .bottomBar) {
            Button("Sort", action: sort)
        }
    }
}


struct ToolBar: ToolbarContent {
 
    var body: some ToolbarContent {
        
        ToolbarItem(placement: .bottomBar) {
            Button(action: {
                print("Edit button was tapped")
                //selection = "PLAY_TALK"

            }) {
                Image(systemName: "note")
                    .renderingMode(.original)

            }        }
        
        ToolbarItem(placement: .bottomBar) {
            Button(action: {
                print("Edit button was tapped")

            }) {
                Image(systemName: "note")
                    .renderingMode(.original)

            }        }

        ToolbarItem(placement: .bottomBar) {
            Button(action: {
                print("Edit button was tapped")

            }) {
                Image(systemName: "note")
                    .renderingMode(.original)

            }
            
        }
    }
}

struct HTMLView: UIViewRepresentable {
  @Binding var text: String
   
  func makeUIView(context: Context) -> WKWebView {
    return WKWebView()
  }
   
  func updateUIView(_ uiView: WKWebView, context: Context) {
    uiView.loadHTMLString(text, baseURL: nil)
  }
}


struct PDFKitRepresentedView: UIViewRepresentable {
    let url: URL

    init(_ url: URL) {
        self.url = url
    }

    func makeUIView(context: UIViewRepresentableContext<PDFKitRepresentedView>) -> PDFKitRepresentedView.UIViewType {
        // Create a `PDFView` and set its `PDFDocument`.
        let pdfView = PDFView()
        pdfView.document = PDFDocument(url: self.url)
        pdfView.autoScales = true
        return pdfView
    }

    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<PDFKitRepresentedView>) {
        // Update the view.
    }
}


struct PDFKitView: View {
    var url: URL

    var body: some View {
        PDFKitRepresentedView(url)
    }
}




struct SearchBar: View {
    @Binding var text: String
 
    @State private var isEditing = false
 
    var body: some View {
        HStack {
 
            TextField("Search ...", text: $text)
                .padding(7)
                .padding(.horizontal, 25)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 8)
                 
                        if isEditing {
                            Button(action: {
                                self.text = ""
                            }) {
                                Image(systemName: "multiply.circle.fill")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 8)
                            }
                        }
                    }
                )
                .padding(.horizontal, 10)
                .onTapGesture {
                    self.isEditing = true
                }
 
            if isEditing {
                Button(action: {
                    self.isEditing = false
                    self.text = ""
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
 
                }) {
                    Text("Cancel")
                }
                .padding(.trailing, 10)
                .transition(.move(edge: .trailing))
                .animation(.default)
            }
        }
    }
}


struct TextView: UIViewRepresentable {
 
    @Binding var text: String
    @Binding var textStyle: UIFont.TextStyle
 
    func makeCoordinator() -> Coordinator {
        Coordinator($text)
    }
     
    class Coordinator: NSObject, UITextViewDelegate {
        var text: Binding<String>
     
        init(_ text: Binding<String>) {
            self.text = text
        }
     
        func textViewDidChange(_ textView: UITextView) {
            self.text.wrappedValue = textView.text
        }
    }
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
 
        textView.font = UIFont.preferredFont(forTextStyle: textStyle)
        textView.autocapitalizationType = .sentences
        textView.isSelectable = true
        textView.isUserInteractionEnabled = true
        textView.delegate = context.coordinator

 
        return textView
    }
 
    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
        uiView.font = UIFont.preferredFont(forTextStyle: textStyle)
    }
}


struct ShareSheet: UIViewControllerRepresentable {
    typealias Callback = (_ activityType: UIActivity.ActivityType?, _ completed: Bool, _ returnedItems: [Any]?, _ error: Error?) -> Void
    
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    let excludedActivityTypes: [UIActivity.ActivityType]? = nil
    let callback: Callback? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities)
        controller.excludedActivityTypes = excludedActivityTypes
        controller.completionWithItemsHandler = callback
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // nothing to do here
    }
}

struct TranscriptView: View {
    var talk: TalkData
    
    init(talk: TalkData) {
        
        self.talk = talk
        print("Talk: ", talk.Title, "  ", talk.PDF)
        
    }
    
    var body: some View {
        
        VStack () {
        if let requestURL = URL(string: talk.PDF) {
            PDFKitView(url: requestURL)
                //.frame(width: 200)

        }
        }
    }
}

struct HelpPageView: View {
    
    @State var text = "<h1>AudioDharma Help</h1><p><br>Press and Hold"

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HTMLView(text: $text)
                  .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        }
    }
}

struct DonationPageView: View {
    
    @State var text = "<h1>Donation Page</h1>"

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HTMLView(text: $text)
                  .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        }
    }
}


/*
 *********************************************************************************
 * Extensions
 *********************************************************************************
 */

extension Int {
    
    func displayInCommaFormat() -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        return numberFormatter.string(from: NSNumber(value:self))!
    }

    
    func displayInClockFormat() -> String {
        
        let hours = self / 3600
        let modHours = self % 3600
        let minutes = modHours / 60
        let seconds = modHours % 60
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = NumberFormatter.Style.decimal
        let hoursStr = numberFormatter.string(from: NSNumber(value:hours)) ?? "0"
        
        let minutesStr = String(format: "%02d", minutes)
        let secondsStr = String(format: "%02d", seconds)
        
        return hoursStr + ":" + minutesStr + ":" + secondsStr
    }
}


extension String {
    
    func convertDurationToSeconds() -> Int {
    
        var totalSeconds: Int = 0
        var hours : Int = 0
        var minutes : Int = 0
        var seconds : Int = 0
        
        if self != "" {
            let durationArray = self.components(separatedBy: ":")
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
    
    
    func toImage() -> Image {
       let uiImage =  (UIImage(named: self) ?? UIImage(named: "defaultPhoto"))!
       return Image(uiImage: uiImage)
    }
}


extension Color {
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}


extension View {
    
  @ViewBuilder func hidden(_ shouldHide: Bool) -> some View {
    switch shouldHide {
      case true: self.hidden()
      case false: self
    }
  }
    
}
