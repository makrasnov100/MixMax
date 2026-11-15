# mix_max

#### Development Environment

1. Install firebase cli 13.15.1 `npm install -g firebase-tools@13.15.1`
1. Install flutter 3.24.1 (use sdk archive)
1. Install android sdk w/ by installing android studio

# Deployment

## Google Play (fastlane)

Run from `android/`. fastlane only touches the internal testing track and never sends listing changes for review; production releases stay in Play Console. Store images aren't in git (`listing_pull` re-downloads them).

One-time setup: `sudo dnf install -y ruby ruby-devel rubygem-bundler gcc-c++`, then `bundle config set --local path vendor/bundle && bundle install`, `gcloud auth login` (account needs `roles/iam.serviceAccountTokenCreator` on `fastlane-play@my-fortuna-website.iam.gserviceaccount.com`) and `firebase login`.

- `bundle exec fastlane check` - pubspec version and builds on internal testing, changes nothing
- `bundle exec fastlane internal` - bump the build number in `pubspec.yaml` first; builds the prod bundle, uploads it to internal testing, uploads Dart symbols to Crashlytics. Also sends anything waiting in Play Console's Publishing overview for review, so check that first. `build:false` re-uploads the bundle already built. Optional release notes: `fastlane/metadata/android/<language>/changelogs/<build number>.txt`
- `bundle exec fastlane symbols` - re-upload Dart symbols to Crashlytics
- `bundle exec fastlane listing validate_only:true`, then `bundle exec fastlane listing` - saves `fastlane/metadata/android/` to Play Console unsent; press "Send changes for review" in Publishing overview
- `bundle exec fastlane listing_pull` - download the live listing (move `fastlane/metadata` aside first)

Native symbols (step 4 below) are still uploaded by hand.

## Google Play (by hand)

1. Test: `flutter test`
2. Build: `flutter build appbundle --flavor prod --obfuscate --split-debug-info=.\debug_info\1.0.0`
3. Upload Symbols (update the app ids): `firebase crashlytics:symbols:upload --app=1:124263762128:android:e8622bc7d3d243cbf776d5 .\debug_info\1.0.0`
4. Upload Native symbols to Google Play:
   a. Test and Release -> App bundle explorer -> Release Details -> Downloads
   b. Upload only arm and x86_64 from `build\app\intermediates\merged_native_libs\prodRelease\out\lib` in a zip
5. (if forgot use) `flutter symbolize -i ".\stack_traces\3.txt" -d ".\debug_info\0.0.1\app.android-x64.symbols"`

## Cloud Functions

Single Functions: `firebase deploy --only functions:function1,functions:function2`
All Functions: `firebase deploy --only functions`

# Generate Code:

Class Serialization: `flutter pub run build_runner build --delete-conflicting-outputs`
