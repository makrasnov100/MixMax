import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:mix_max/classes/app/sign_in_result.dart';
import 'package:mix_max/classes/schema/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mix_max/services/firebase/database_service.dart';
import 'package:mix_max/services/firebase/run_cloud_function.dart';
import 'package:google_sign_in/google_sign_in.dart';

enum AcceptedProviders { anonymous, google, apple }

class AuthService extends ChangeNotifier {
  AuthService() {
    listenToLogin();
  }

  bool isLoading = true;

  String? oldUserSecret;
  SchemaUser? _lastNotNullUser; // to be used only for user change tracking in this file

  SchemaUser user = SchemaUser.initial();
  Stream<DocumentSnapshot<SchemaUser>>? userStream;
  StreamController<SchemaUser> userStreamController = StreamController<SchemaUser>();
  StreamSubscription<DocumentSnapshot<SchemaUser>>? userStreamSubscription;

  User? firebaseUser;
  AcceptedProviders? lastProvider;
  StreamSubscription<User?>? firebaseUserStreamSubscription;

  //[STREAMING USER INFO]
  void listenToLogin() async {
    firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      // No automatic anonymous sign-in: a brand-new user stays signed out until
      // they choose how to use the app in the account drawer — only after
      // they've seen the Terms of Service / Privacy Policy line there.
      lastProvider = null;
      isLoading = false;
      notifyListeners();
    } else {
      waitForSignInComplete(timeout: Duration(seconds: 10));
      if (firebaseUser!.isAnonymous) {
        lastProvider = AcceptedProviders.anonymous;
      } else if (firebaseUser!.providerData.isNotEmpty && firebaseUser!.providerData[0].providerId == 'google.com') {
        lastProvider = AcceptedProviders.google;
      } else if (firebaseUser!.providerData.isNotEmpty && firebaseUser!.providerData[0].providerId == 'apple.com') {
        lastProvider = AcceptedProviders.apple;
      } else {
        lastProvider = AcceptedProviders.google; // default fallback
      }
    }

    firebaseUserStreamSubscription = FirebaseAuth.instance.authStateChanges().listen((User? newFirebaseUser) {
      //If the signed in user is null, sing in anonymously
      firebaseUser = newFirebaseUser;
      if (newFirebaseUser != null) {
        subscribeToUserStream(newFirebaseUser);
      } else {
        user = SchemaUser.unknown();
        notifyListeners();
      }
    });
  }

  Future<void> subscribeToUserStream(User user) async {
    //Do not subscribe if already subscribed to the same user
    if (this.user.id == user.uid) {
      return;
    }
    //Unsubscribe from existing stream first if going to be listening to a new user
    if (userStreamSubscription != null) {
      await unsubscribeFromUserStream();
    }

    //Any new user identifier tracked in crashlytics
    await FirebaseCrashlytics.instance.setUserIdentifier(user.uid);

    userStream = await getUserStream(user);
    if (userStream == null) {
      return;
    }

    print("Subscribed to a new user document listener!");
    userStreamSubscription = userStream!.listen((userDocSnap) {
      SchemaUser? currentUser = userDocSnap.data();

      if (currentUser != null) {
        if (_lastNotNullUser != null && _lastNotNullUser!.id != currentUser.id) {
          runCloudFunction(
            functionName: "onAppUserChanged",
            input: {"oldUserID": _lastNotNullUser!.id, "oldUserSecret": oldUserSecret},
            onError: (e, jsonResponse) {
              print("Unable to processes app user change: $e");
            },
            onSuccess: (jsonResponse) {
              print("Successfully processed app user change!");
            },
          );
        }

        this.user = currentUser;
        _lastNotNullUser = currentUser;
      } else {
        this.user = SchemaUser.unknown();
        _lastNotNullUser = null;
      }

      //Convert document info to user object
      print("User Stream Result Received!");
      print(this.user.toJson());

      //Update listeners about user change
      userStreamController.add(this.user);
      notifyListeners();
    });
  }

  Future<void> unsubscribeFromUserStream() async {
    await FirebaseCrashlytics.instance.setUserIdentifier("");
    if (userStreamSubscription != null) {
      userStreamSubscription!.cancel();
    }
    userStreamSubscription = null;
    userStream = null;
    user = SchemaUser.unknown();
    userStreamController.add(user);
  }

  //Get user from users collection with the user id (doc should exist due to auth triggers)
  Future<Stream<DocumentSnapshot<SchemaUser>>> getUserStream(User user) async {
    DocumentReference<SchemaUser> userDoc = DatabaseService.usersRef.doc(user.uid);
    return userDoc.snapshots();
  }

  Future<void> waitForSignInComplete({required Duration timeout}) async {
    isLoading = true;
    String startID = user.id;
    notifyListeners();

    int timeElapsed = 0;
    int interval = 500;
    while (timeElapsed < timeout.inMilliseconds) {
      await Future.delayed(Duration(milliseconds: interval));
      timeElapsed += interval;

      if (startID != user.id) {
        break;
      }

      if (timeElapsed >= timeout.inMilliseconds) {
        break;
      }
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> getUserSecret() async {
    await runCloudFunction(
      functionName: "getUserSecret",
      input: {},
      onError: (e, jsonResponse) {
        print("Unable to get user secret: $e");
      },
      onSuccess: (jsonResponse) {
        oldUserSecret = jsonResponse?["token"] as String?;
      },
    );
  }

  //Custom handle to check if user can use federated sign in (if null then allowed)
  Future<SignInResult?> checkCanSignIn() async {
    return null;
  }

  Future<SignInResult> signInWithGoogle() async {
    GoogleSignInAuthentication? googleAuth;
    try {
      SignInResult? result = await checkCanSignIn();
      if (result != null) {
        return result;
      }

      // The secret is only needed to transfer data off an existing (anonymous)
      // user — and the cloud call would be rejected while signed out anyway.
      if (hasAccount) {
        await getUserSecret();
      }

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // Obtain the auth details from the request
      googleAuth = await googleUser?.authentication;
    } catch (e) {
      return SignInResult(success: false, message: "Sign in failed - ${e.toString()}", userCredential: null);
    }
    waitForSignInComplete(timeout: Duration(seconds: 10));

    if (googleAuth == null || googleAuth.accessToken == null || googleAuth.idToken == null) {
      return SignInResult(success: false, message: "Sign in failed - Auth token is null", userCredential: null);
    }

    // Create a new credential
    final credential = GoogleAuthProvider.credential(accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);

    SignInResult signInResult = await linkOauthCredentialToUser(
      credential: credential,
      provider: AcceptedProviders.google,
    );
    if (signInResult.success != true) {
      signOut();
    }

    notifyListeners();

    // Once signed in, return the UserCredential
    return signInResult;
  }

  Future<SignInResult> signInWithApple() async {
    try {
      SignInResult? result = await checkCanSignIn();
      if (result != null) {
        return result;
      }

      if (hasAccount) {
        await getUserSecret();
      }

      waitForSignInComplete(timeout: Duration(seconds: 10));
      final appleProvider =
          AppleAuthProvider()
            ..addScope('email')
            ..addScope('name');

      SignInResult signInResult = await linkAppleProviderToUser(provider: appleProvider, type: AcceptedProviders.apple);

      if (signInResult.success != true) {
        signOut();
      }

      notifyListeners();

      // Once signed in, return the UserCredential
      return signInResult;
    } catch (e) {
      return SignInResult(success: false, message: "Sign in failed, please try again later.", userCredential: null);
    }
  }

  Future<SignInResult> handleFirebaseAuthErrors({
    required FirebaseAuthException e,
    AuthCredential? credential,
    required AcceptedProviders provider,
  }) async {
    UserCredential? userCredential;

    switch (e.code) {
      case "provider-already-linked":
        print("The provider has already been linked to the user.");
        AuthCredential? newCredential = credential ?? e.credential;
        if (newCredential != null) {
          userCredential = await signInCredentialProvider(credential: newCredential, provider: provider);
        } else {
          return SignInResult(
            success: false,
            message: "A provider has already been linked to the user. Try to restart the app.",
            userCredential: null,
          );
        }
        break;
      case "credential-already-in-use":
        print("The account corresponding to the credential already exists, or is already linked to a Firebase User.");
        AuthCredential? newCredential = credential ?? e.credential;
        if (newCredential != null) {
          userCredential = await signInCredentialProvider(credential: newCredential, provider: provider);
        } else {
          return SignInResult(
            success: false,
            message: "Unexpected error. Please try again later.",
            userCredential: null,
          );
        }
        break;
      case "invalid-credential":
        print("The provider's credential is not valid.");
        return SignInResult(success: false, message: "The provider's credential is not valid.", userCredential: null);
      case "email-already-in-use":
        print("The email corresponding to the credential is already in use by another account.");

        return SignInResult(
          success: false,
          message:
              "The email corresponding to the credential is already in use by another account. Try other sign in options.",
          userCredential: null,
        );
      // See the API reference for the full list of error codes.
      default:
        print("Unknown error - ${e.code}");
        return SignInResult(success: false, message: "Unknown error - ${e.code}", userCredential: null);
    }

    if (userCredential != null) {
      return SignInResult(success: true, message: "", userCredential: userCredential);
    } else {
      return SignInResult(success: false, message: "Unknown error! Please try again later.", userCredential: null);
    }
  }

  Future<SignInResult> linkAppleProviderToUser({
    required AppleAuthProvider provider,
    required AcceptedProviders type,
  }) async {
    UserCredential? userCredential;
    try {
      if (firebaseUser?.isAnonymous == true) {
        userCredential = await FirebaseAuth.instance.currentUser?.linkWithProvider(provider);
        lastProvider = type;
        // userCredential = await signInAppleProvider(provider: provider);
      } else {
        await FirebaseAuth.instance.signOut();
        userCredential = await signInAppleProvider(provider: provider);
      }
    } on FirebaseAuthException catch (e) {
      return handleFirebaseAuthErrors(e: e, provider: AcceptedProviders.apple);
    } catch (e) {
      print("Unknown error - $e");
      return SignInResult(success: false, message: "Unknown error - $e", userCredential: null);
    }

    if (userCredential != null) {
      return SignInResult(success: true, message: "", userCredential: userCredential);
    } else {
      return SignInResult(success: false, message: "Unknown error! Please try again later.", userCredential: null);
    }
  }

  Future<SignInResult> linkOauthCredentialToUser({
    required OAuthCredential credential,
    required AcceptedProviders provider,
  }) async {
    UserCredential? userCredential;
    try {
      if (firebaseUser?.isAnonymous == true) {
        userCredential = await FirebaseAuth.instance.currentUser?.linkWithCredential(credential);
        lastProvider = provider;
        userCredential = await signInCredentialProvider(credential: credential, provider: provider);
      } else {
        await FirebaseAuth.instance.signOut();
        userCredential = await signInCredentialProvider(credential: credential, provider: provider);
      }
    } on FirebaseAuthException catch (e) {
      return handleFirebaseAuthErrors(e: e, provider: provider);
    } catch (e) {
      print("Unknown error - $e");
      return SignInResult(success: false, message: "Unknown error - $e", userCredential: null);
    }

    if (userCredential != null) {
      return SignInResult(success: true, message: "", userCredential: userCredential);
    } else {
      return SignInResult(success: false, message: "Unknown error! Please try again later.", userCredential: null);
    }
  }

  bool isSignedIn() {
    return firebaseUser != null &&
        (lastProvider == AcceptedProviders.google || lastProvider == AcceptedProviders.apple);
  }

  /// True once any account exists — a guest (anonymous) or a federated one.
  /// False only for a brand-new user who hasn't chosen how to use the app yet.
  bool get hasAccount => firebaseUser != null;

  /// True while using the app as a guest (anonymous account).
  bool get isGuest => firebaseUser != null && lastProvider == AcceptedProviders.anonymous;

  bool authUserMatchesFirebaseUser() {
    return firebaseUser != null && firebaseUser!.uid == user.id;
  }

  Future<bool> signInAnonymous() async {
    try {
      waitForSignInComplete(timeout: Duration(seconds: 10));
      await FirebaseAuth.instance.signInAnonymously();
      lastProvider = AcceptedProviders.anonymous;
      return true;
    } catch (e) {
      lastProvider = null;
      notifyListeners();
      return false;
    }
  }

  /// "Continue as guest" — creates the anonymous account. Called only from the
  /// account drawer, after the Terms of Service / Privacy Policy were shown.
  Future<bool> signInAsGuest() async {
    if (hasAccount) {
      return true;
    }
    return signInAnonymous();
  }

  /// Permanently deletes the current account through the `deleteUserAccount`
  /// cloud function (auth record, user docs and every experiment / run), then
  /// clears the local session *without* re-signing-in anonymously — the user
  /// returns to the pre-choice state, so creating an experiment asks how to
  /// use the app again.
  Future<SignInResult> deleteAccount() async {
    String? errorMessage;
    bool success = await runCloudFunction(
      functionName: "deleteUserAccount",
      input: {},
      timeoutSeconds: 300,
      onError: (e, jsonResponse) {
        errorMessage = e;
      },
    );

    if (!success) {
      return SignInResult(
        success: false,
        message: errorMessage ?? "Unable to delete your account. Please try again later.",
        userCredential: null,
      );
    }

    // The auth record is already gone server-side; drop the local session.
    try {
      await GoogleSignIn().signOut();
    } catch (e) {
      print(e);
    }
    await unsubscribeFromUserStream();
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      print(e);
    }
    firebaseUser = null;
    lastProvider = null;
    _lastNotNullUser = null;
    oldUserSecret = null;
    notifyListeners();
    return SignInResult(success: true, message: "", userCredential: null);
  }

  Future<UserCredential?> signInAppleProvider({required AppleAuthProvider provider}) async {
    UserCredential? userCredential;
    try {
      userCredential = await FirebaseAuth.instance.signInWithProvider(provider);
      lastProvider = AcceptedProviders.apple;
    } catch (e) {
      lastProvider = null;
      print(e);
    }
    return userCredential;
  }

  Future<UserCredential?> signInCredentialProvider({
    required AuthCredential credential,
    required AcceptedProviders provider,
  }) async {
    UserCredential? userCredential;
    try {
      userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      lastProvider = provider;
    } catch (e) {
      lastProvider = null;
      print(e);
    }
    return userCredential;
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
    await unsubscribeFromUserStream();
    await signInAnonymous();
    notifyListeners();
  }

  // Generates a cryptographically secure random nonce, to be included in a credential request.
  String generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  /// Returns the sha256 hash of [input] in hex notation.
  String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  @override
  void dispose() {
    userStreamSubscription?.cancel();
    firebaseUserStreamSubscription?.cancel();
    super.dispose();
  }
}
