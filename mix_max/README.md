# mix_max

#### Development Environment

1. Install firebase cli 13.15.1 `npm install -g firebase-tools@13.15.1`
1. Install flutter 3.24.1 (use sdk archive)
1. Install android sdk w/ by installing android studio

# Deployment

## Google Play

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
