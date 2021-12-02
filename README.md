
This app is tied to the website at www.audiodharma.org. 

A single configuration file - CONFIG00.JSON - defines all the talks and albums in the app.  This json file is zipped and kept at known endpoint on the web.

AudioDharmaNewApp is the entry point. This class does some basic device initialization and then brings up RootView.

RootView displays the splash screen (image of the earth) and then creates single instance of Model, named TheDataModel.  DataModel is exactly that - the data model for the app. All data handling is in here.

RootView then calls TheDataModel to asynchronously load CONFIG00.ZIP and unzip it.  Once this is done, it calls DataModel again to install the resulting json.  During this process, TheDataModel creates all the albums and stores the talks inside them.

Once this is done, RootView terminates and launches HomePageView.  HomePageView is the main screen of the app.

The UI from there is straightforward.  AlbumListView displays a list of albums.  TalkListView displays a list of talks.  

TalkPlayerView drives the MP3 audio player.  It gets called from an instance of TalkListView.

TalkPlayer is an abstraction of the underlying MP3 player.  So, the TalkPlayerView displays the UI and an instance of TalkPlayer actually outputs the talk.

UserAlbumListView/UserEditTalkList view are variants of AlbumListView/TalkListView.  They have added functionality allowing users to create and edit custom ablums.

SessionData defines the two basic data classes:  AlbumData and TalkData. AlbumListView and TalkListView references instances of these classes.  

Commmon defines basic classes used throughout the app.  For example, here is where you'll find the DonationView and HelpView.

The app updates itself with new talks on a regular basis.  When the timestamp on CONFIG00.ZIP has changed, the app terminates HomePageView, thus effectively tearing down the UI.  This brings us back into RootView, which then proceeds to create a new TheDataModel and then reload the configuration. This gives us a fresh set of talks and albums.
