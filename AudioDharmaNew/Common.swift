//
//  Common.swift
//
//  Common shared code and extensions
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
let HOMEPAGE_SECTIONS = ["Talks", "Albums", "Personal Albums", "Community Activity"]

let LIST_IMAGE_HEIGHT : CGFloat = 40.0
let LIST_IMAGE_WIDTH : CGFloat = 40.0
let LIST_ROW_SIZE_SECTION : CGFloat = 35.0
let LIST_ROW_SIZE_STANDARD : CGFloat = 40.0

let FONT_SIZE_ROW_TITLE : CGFloat = 16
let FONT_SIZE_ROW_ATTRIBUTES : CGFloat = 10
let FONT_SIZE_SECTION : CGFloat = 16
let FONT_SIZE_BIOGRAPHY_TEXT : CGFloat = 16
let FONT_SIZE_HELP_TEXT : CGFloat = 16
let FONT_SIZE_DONATION_TEXT : CGFloat = 16
let FONT_SIZE_DONATION_LINK : CGFloat = 20
let FONT_SIZE_TALK_PLAYER : CGFloat = 16
let FONT_SIZE_TALK_PLAYER_SMALL : CGFloat = 12
let FONT_SIZE_UPDATE_SCREEN : CGFloat = 14

let LIST_LEFT_MARGIN_OFFSET : CGFloat = -10

let NOTATE_FAVORITE_ICON_WIDTH : CGFloat = 12
let NOTATE_FAVORITE_ICON_HEIGHT : CGFloat = 12
let BIO_IMAGE_HEIGHT : CGFloat = 200
let BIO_TEXT_MAX_WIDTH : CGFloat = 600

let COLOR_HEX_BACKGROUND_SECTION = "555555"
let COLOR_DOWNLOADED_TALK = Color.orange
let COLOR_HIGHLIGHTED_TALK = Color.gray

let MAIN_FONT_COLOR = UIColor.darkGray      // #555555ff
let SECONDARY_FONT_COLOR = UIColor.gray
let MEDIA_CONTROLS_COLOR_LIGHT = Color(hex: "#555555")
let DEFAULT_LINK_COLOR = Color(hex: "#0077ed")


var AppColorScheme: ColorScheme = .light

/*
 *********************************************************************************
 * Structs
 *********************************************************************************
 */


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
        controller.completionWithItemsHandler = shareCompleted
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // nothing to do here
    }
    
    func shareCompleted(activityType: UIActivity.ActivityType?, successfulShare: Bool, thing: [Any]?, error: Error?) {
    
        if successfulShare {
            
            print("successful share")
            TheDataModel.addToShareHistory(talk: SharedTalk)
            TheDataModel.reportTalkActivity(type: .SHARE_TALK, talk: SharedTalk)
        }
    }
}


struct TranscriptView: View {
    var talk: TalkData
    
    init(talk: TalkData) {
        self.talk = talk
    }
    
    var body: some View {
        
        VStack () {

            if let requestURL = URL(string: talk.transcript) {
                PDFKitView(url: requestURL)
            }
          
        }
        .onAppear() {
            DisplayingBiographyOrTranscript = true
            
            TheDataModel.reportTalkActivity(type: .READ_TRANSCRIPT, talk: talk)
        }
        .onDisappear() {
            DisplayingBiographyOrTranscript = false
        }
    }
}


struct BiographyView: View {
    var talk: TalkData

    @State var stateBiographyText: String
    
    init(talk: TalkData)
    {
        var text : String
        
        self.talk = talk
        
        if let filepath = Bundle.main.path(forResource: self.talk.speaker, ofType: "txt") {
            do {
                text = try String(contentsOfFile: filepath)
            } catch {
                text = ""
            }
        } else {
            text = ""
        }
        
        text = text.replacingOccurrences(of: "<p>", with: "\n")
        text = text.replacingOccurrences(of: "<br>", with: "\n")
        
        stateBiographyText = text
    }

    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
          
           ScrollView {
               VStack() {
                Spacer()
                    .frame(height: 20)
                HStack() {
                    Spacer()
                    talk.speaker.toImage()
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: BIO_IMAGE_HEIGHT)
                    Spacer()
                }
                Spacer()
                    .frame(height: 30)
                Text(stateBiographyText)
                    .font(.system(size: FONT_SIZE_BIOGRAPHY_TEXT, weight: .regular))
                    .padding(.leading, 20)
                    .padding(.trailing, 20)
        }
        }
        .frame(maxWidth: BIO_TEXT_MAX_WIDTH)
        .onAppear() {
            DisplayingBiographyOrTranscript = true
        }
        .onDisappear() {
            DisplayingBiographyOrTranscript = false
        }
        .navigationBarTitle(talk.speaker)
    }
    }
}


struct HelpPageView: View {
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
           
            ScrollView {
                VStack() {
                Spacer()
                    .frame(height:30)
                HStack() {
                    Text("General")
                        .font(.system(size: FONT_SIZE_HELP_TEXT, weight: .heavy))
                    Spacer()
                }
                .frame(alignment: .leading)
     

                Spacer().frame(height:25)
                    HStack() {
                        Text("All talks are organized into albums.\n\nTap an album to display all the talks it contains.\n\nLong-press a talk to display its menu. This allows you to notate, download and share the talk.\nAn orange dot marks a favorite talk.\nA blue dot marks a notated talk.\nA bullet point marks a talk that has been previously played.\nDownloaded talks are highlighted in orange.\n\nTo resume playing the last talk at the point you left it, tap the Resume button at the bottom of the screen.\n\nTo view a speaker's biography, tap the speaker's name in the Play Talk screen.")
                            .frame(alignment: .leading)
                            .font(.system(size: FONT_SIZE_HELP_TEXT, weight: .regular))
                            .multilineTextAlignment(.leading)
                        Spacer()
                    }
                    .frame(alignment: .leading)

                Spacer().frame(height:50)
                HStack() {
                    Text("Custom Albums")
                        .font(.system(size: FONT_SIZE_HELP_TEXT, weight: .heavy))
                    Spacer()
                }
                .frame(alignment: .leading)

                Spacer().frame(height:25)
                HStack() {
                     Text("Tap New Albums in the top right to create a custom album.\n\nLong-press a custom album to display its menu. This menu allows you to add or delete talks in the album.")
                        .frame(alignment: .leading)
                        .font(.system(size: FONT_SIZE_HELP_TEXT, weight: .regular))
                        .multilineTextAlignment(.leading)
                }
                .frame(alignment: .leading)


                Spacer()

            }
            .frame(maxWidth: BIO_TEXT_MAX_WIDTH)
            }
           

        }
        .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
        .navigationBarTitle("Help", displayMode: .inline)
    }
}


struct DonationPageView: View {
    

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
                .frame(height:30)
            Text("Audio Dharma is a free service provided by the Insight Meditation Center in Redwood City, California. IMC is run solely by volunteers and does not require payment for any of its programs.")
                    .font(.system(size: FONT_SIZE_DONATION_TEXT, weight: .regular))
                    .multilineTextAlignment(.leading)
            /*
            Spacer()
                .frame(height:10)
           Text("If you wish to donate please click the link below.")
                .font(.system(size: FONT_SIZE_DONATION_TEXT, weight: .regular))
                .multilineTextAlignment(.leading)
             */
            Spacer()
                .frame(height:30)
            HStack() {
                Spacer()
                Link(destination: URL(string: URL_DONATE)!, label: {
                    Text("Donate")
                        .foregroundColor(DEFAULT_LINK_COLOR)
                        .font(.system(size: FONT_SIZE_DONATION_LINK, weight: .regular))
                })
                Spacer()
            }
            Spacer()
        }
        .frame(maxWidth: BIO_TEXT_MAX_WIDTH)
        .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
        .navigationBarTitle("Donations", displayMode: .inline)

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
        var hoursStr = numberFormatter.string(from: NSNumber(value:hours)) ?? "00"
        
        //hack so that it looks nice
        if hoursStr.count == 1 { hoursStr = "0" + hoursStr}
        
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
    
        var imageName : String
        
        switch self {
        case "personal":
            imageName =  "light_personal"
        case "community":
            imageName = "light_community"
        case "sequence":
            imageName = "light_sequence"
        default:
            imageName = self
        }

        // removed, as there is a bug somewhere and the images display inconsistently in dark mode.
        /*
        switch self {
        case "personal":
            imageName = AppColorScheme == .light ? "light_personal" : "dark_personal"
        case "community":
            imageName = AppColorScheme == .light ? "light_community" : "dark_community"
        case "sequence":
            imageName = AppColorScheme == .light ? "light_sequence"  :  "dark_sequence"
        default:
            imageName = self
        }
         */
        
       let uiImage =  (UIImage(named: imageName) ?? UIImage(named: "defaultPhoto"))!
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
