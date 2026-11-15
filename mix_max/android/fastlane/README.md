fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## Android

### android check

```sh
[bundle exec] fastlane android check
```

Show the build numbers on the internal testing track (also checks Play access)

### android internal

```sh
[bundle exec] fastlane android internal
```

Build the prod app bundle and release it to the internal testing track. Anything waiting in Play Console's Publishing overview is sent for review with it. build:false uploads the bundle already built. Release notes come from fastlane/metadata/android/<language>/changelogs/<build number>.txt where it exists

### android symbols

```sh
[bundle exec] fastlane android symbols
```

Upload the Dart debug symbols of the current pubspec version to Crashlytics

### android listing_pull

```sh
[bundle exec] fastlane android listing_pull
```

Download the live store listing (text, images, release notes) into fastlane/metadata/android. The folder must not exist yet

### android listing

```sh
[bundle exec] fastlane android listing
```

Save the store listing (text, images, screenshots) from fastlane/metadata/android to Play Console as changes not yet sent for review. validate_only:true checks it with Google without saving

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
