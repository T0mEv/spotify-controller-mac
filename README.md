# Mac Spotify Controller

## Overview
This project serves as a spotify controller as a menu bar extra application. Originally this is developed to better control spotify while fullscreened on other applications, I do intend on adding much more functionality however for the meantime I'll leave main as this basic working implementation.
<div align="center">
  <img width="428" height="211" alt="image" src="https://github.com/user-attachments/assets/9e318842-4411-46f2-84a2-33cd78916e9b" />
</div>

## Setup
As this project is yet to be published officially, it does require the following setup. Hopefully in future it will be published but I intend on keeping all of the code here.

1. Firstly go to <https://developer.spotify.com/documentation/web-api> and register an app as you'll need a ClientID and ClientSecret to use this tool.
2. Next clone this project and open it through Xcode, note you will need to open the .xcodeproj file. Then in the top bar got to File -> New -> File from template, then scroll under Resource and create a new property list called "Secrets" and add two columns one for the ClientID and one for the ClientSecret.
3. Lastly run the project and if the steps above were done correctly it should open a new music note symbol in the top right bar, click this and a button should allow you to connect your spotify account.

Note: This was designed for Spotify Premium users so I don't think free users will get full functionality if any. This project is still very early in development however any feedback would be appreciated.
