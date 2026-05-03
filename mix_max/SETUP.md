<!-- TODO TEMPLATE: follow all instructions, remove as they are completed -->

How to setup a new project with this template:
#### Firebase PROD Initialization:
1. Create general info collection and initial document
  - collection("General").doc("app").set({
    "social": {
      "contactEmail": "support+mix-max@myfortuna.app",
      "privacyPolicy": "https://myfortuna.app/privacy-policy/mix-max/",
      "termsOfService": "https://myfortuna.app/terms-of-service/mix-max/"
    }
  })

1. Finish up with settings from configuration
  - Go through: https://pub.dev/packages/google_sign_in_ios#ios-integration


#### Branding Setup (not required to start MVP):
- App Icon:
1. Branstorm then generate app icon with chatGPT or a similar tool (chatGPT is good at refining images it generates based on feedback)
1. Create the foreground and background versions of the images
1. Remove any background from foreground image that is not transparent (a has problems with this)
1. Place icon variants into `assets/icon/combined.png`, `assets/icon/background.png`, and `assets/icon/foreground.png`
1. Run `dart run flutter_launcher_icons`

- Splash Screeen:
1. Create the app icon first
1. Figure out background color in app_colors
1. Update the app background color under `flutter_native_splash` in `pubspec.yaml`
1. size down the app icon foreground about 70% and place into `assets/icon/foreground_small.png`
1. Run `dart run flutter_native_splash:create`

Screenshots:
1.

- Other:
1. Change color scheme in lib/services/app_colors
2. Change or keep font and text colors "default is roboto and dark and light colors"
  - text inside lib/text
  - font in assets/fonts and pubspec file

#### Production Release
1. 


#### Building The app
1. add folder to debug_info_folder for the right version

GOOGLE PLAY:
1. run the command
`flutter build appbundle --flavor prod --release --obfuscate --split-debug-info=./debug_info/0.0.1`
1. Create google play release
1. Upload merged native libs from "build\app\intermediates\merged_native_libs\prodRelease\out\lib"
https://support.google.com/googleplay/android-developer/answer/9848633?hl=en#zippy=%2Cupload-files-using-play-console
1. If not already add the google play signing SHA1 and SHA256 to the project
1. Upload debug symbols to crashlytics
 - `firebase crashlytics:symbols:upload --app=1:299969433701:android:c8b04d0c3c5a90a84fb68c .\debug_info\0.0.1`
 - if forgot to run can use below to symbolize a stack trace:
 - `flutter symbolize -i ".\stack_traces\3.txt" -d ".\debug_info\3.2.0\app.android-x64.symbols"`


APPLE STORE:
1. TODO

<!-- Do this when the project requires the first major update! -->

### Firebase DEV Environment Setup:
1. Create a new project - `Mix Max Dev` - for the dev environment
1. Convert it to a blaze plan
1. Add ios app id `app.myfortuna.mixMax.dev` to firebase project
1. Add android app id `app.myfortuna.mix_max.dev` to firebase project
1. Add debug mode sha to project
  - generate SHA1 and SHA256 with a terminal command
   - debug: `keytool -list -v -keystore "C:/Users/[USER]/.android/debug.keystore" -alias androiddebugkey -storepass android -keypass android`
   - release: `keytool -list -v -keystore "{keystore_directory}/mix-max-key.jks" -alias upload`
  - https://stackoverflow.com/questions/15727912/sha-1-fingerprint-of-keystore-certificate
1. Perform setup for needed services
      Project Settings:
      - Add business account as additional owner of project 

      Authentication:
      - Anonymous 
      - Google: with business account

      Firestore:
      - Provision from the console
      - Keep (default) name and keep in the US

      Storage (if needed):
      - Provision from the console 
      - Run `firebase deploy --only storage` to deploy rules

      Realtime Database (if needed)
      - TODO

#### Firebase DEV Initialization:
1. Change the dev project name in `.firebaserc` file for dev and default alike 
1. Run `firebase use dev`
1. Delete the firebase properies files (will be regenerated for this project)
1. Delete local firebase.json `platforms` property
1. Run Firebase CLI command to generate new firebase files for dev on a OSX device
    - run the command for ios-build-config: `Debug-dev` and `Release-dev`
    - run `cd ios`, `pod install`
    - test that in Xcode the dev release configuration builds suecessfully

```
flutterfire configure \
--yes \
--project=mix-max-dev \
--platforms=android,ios \
--android-out=android/app/src/dev/google-services.json \
--android-package-name=app.myfortuna.mix_max.dev \
--ios-build-config=Debug-dev \
--ios-out=ios/Runner/GoogleInfoPlist/dev/GoogleService-Info-dev.plist \
--ios-bundle-id=app.myfortuna.mixMax.dev \
--out=lib/flavors/dev/firebase_options.dart
```

1. Configure firestore rules and indexes by deploying them with the cli
- `firebase deploy` (everything)
- `firebase deploy --only firestore` (database rules and indexes)
- `firebase deploy --only storage` (file storage rules)
- `firebase deploy --only functions` (cloud functions)

1. Create general info collection and initial document
  - collection("General").doc("app").set({
    "social": {
      "contactEmail": "support+mix-max@myfortuna.app",
      "privacyPolicy": "https://myfortuna.app/privacy-policy/mix-max/",
      "termsOfService": "https://myfortuna.app/terms-of-service/mix-max/"
    }
  })