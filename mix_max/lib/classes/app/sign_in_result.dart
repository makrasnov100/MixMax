import 'package:firebase_auth/firebase_auth.dart';

class SignInResult {
  final bool success;
  final String message;
  final UserCredential? userCredential;

  SignInResult({
    required this.success,
    required this.message,
    this.userCredential,
  });
}
